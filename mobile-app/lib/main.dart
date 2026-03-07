import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/theme_provider.dart';
import 'features/events/providers/event_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/tickets/providers/ticket_provider.dart';
import 'features/notifications/providers/notification_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
    print('✅ Successfully loaded .env file');
    print('🔍 PAYHERE_MERCHANT_ID: ${dotenv.env['PAYHERE_MERCHANT_ID']}');
    print('🔍 PAYHERE_SANDBOX: ${dotenv.env['PAYHERE_SANDBOX']}');
    print('🔍 BASE_URL: ${dotenv.env['BASE_URL']}');
  } catch (e) {
    print('❌ Error loading .env file: $e');
    print('⚠️ Using fallback configurations');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => EventProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => TicketProvider()),
        ChangeNotifierProvider(
          create: (context) => NotificationProvider()..startPolling(),
        ),
      ],
      child: const EventBookingApp(),
    ),
  );
}

class EventBookingApp extends StatelessWidget {
  const EventBookingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp.router(
          title: 'Event Booking App',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          routerConfig: AppRouter.router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
