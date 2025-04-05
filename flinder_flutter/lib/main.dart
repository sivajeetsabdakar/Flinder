import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_context.dart';
import 'routes/app_router.dart';
import 'constants/api_constants.dart';

// Global variables for Supabase
SupabaseClient? supabaseClient;
bool isSupabaseAvailable = false;

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

  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: ApiConstants.supabaseUrl,
      anonKey: ApiConstants.supabaseAnonKey,
    );
    supabaseClient = Supabase.instance.client;
    isSupabaseAvailable = true;
    print('Supabase initialized successfully');
  } catch (e) {
    print('Failed to initialize Supabase: $e');
    isSupabaseAvailable = false;
  }

  // Initialize Auth Service
  await AuthService.initialize();

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
            // Initialize the chat context
            Future.delayed(Duration.zero, () {
              try {
                chatContext.initialize();
              } catch (e) {
                print('Error initializing ChatContext: $e');
              }
            });
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
