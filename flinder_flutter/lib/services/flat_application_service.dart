import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/flat_application.dart';
import '../constants/api_constants.dart';
import '../services/auth_service.dart';

class FlatApplicationService {
  static const String baseUrl = ApiConstants.baseUrl;

  // Create a new application for a flat linked to a group chat
  static Future<FlatApplication> applyForFlat({
    required String flatId,
    required String groupChatId,
  }) async {
    try {
      // Get current user's ID
      final String? userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create the application using Supabase client
      final client = Supabase.instance.client;

      // First check if an application already exists for this flat and user
      final existingApps = await client
          .from('flat_applications')
          .select()
          .eq('flat_id', flatId)
          .eq('user_id', userId);

      if (existingApps != null && (existingApps as List).isNotEmpty) {
        throw Exception('You have already applied for this flat');
      }

      // Create the application - let Supabase generate the UUID
      final response =
          await client
              .from('flat_applications')
              .insert({
                'flat_id': flatId,
                'group_chat_id': groupChatId,
                'user_id': userId,
                'status': 'pending',
                'created_at': DateTime.now().toIso8601String(),
              })
              .select()
              .single();

      return FlatApplication.fromJson(response);
    } catch (e) {
      print('Error applying for flat: $e');
      throw Exception('Failed to apply for flat: $e');
    }
  }

  // Get applications for a specific flat
  static Future<List<FlatApplication>> getApplicationsForFlat(
    String flatId,
  ) async {
    try {
      final client = Supabase.instance.client;

      final response = await client
          .from('flat_applications')
          .select()
          .eq('flat_id', flatId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => FlatApplication.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching flat applications: $e');
      throw Exception('Failed to fetch flat applications: $e');
    }
  }

  // Get applications by the current user
  static Future<List<FlatApplication>> getUserApplications() async {
    try {
      final String? userId = await AuthService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final client = Supabase.instance.client;

      final response = await client
          .from('flat_applications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => FlatApplication.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching user applications: $e');
      throw Exception('Failed to fetch user applications: $e');
    }
  }

  // Update application status (for owners or admins)
  static Future<FlatApplication> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    try {
      // Validate status
      if (!['pending', 'approved', 'rejected'].contains(status)) {
        throw Exception('Invalid status value');
      }

      final client = Supabase.instance.client;

      final response =
          await client
              .from('flat_applications')
              .update({
                'status': status,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', applicationId)
              .select()
              .single();

      return FlatApplication.fromJson(response);
    } catch (e) {
      print('Error updating application status: $e');
      throw Exception('Failed to update application status: $e');
    }
  }
}
