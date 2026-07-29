import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'services/production_services.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_context.dart';
import 'routes/app_router.dart';

// Global navigator observer for route awareness
final RouteObserver<PageRoute> navigatorObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Auth Service
  await AuthService.initialize();
  unawaited(ProductionServices.initializePush());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(),
          lazy: false, // Initialize it eagerly
        ),
        ChangeNotifierProvider(
          create: (_) {
            final chatContext = ChatContext();
            unawaited(chatContext.initialize());
            return chatContext;
          },
          lazy: false, // Initialize it eagerly
        ),
      ],
      child: MaterialApp(
        title: 'Flinder',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
        initialRoute: AppRouter.splashRoute,
        onGenerateRoute: AppRouter.onGenerateRoute,
        navigatorObservers: [navigatorObserver], // Add the navigator observer
        home:
            const SizedBox(), // This ensures the '/' route doesn't show an error
      ),
    );
  }
}
