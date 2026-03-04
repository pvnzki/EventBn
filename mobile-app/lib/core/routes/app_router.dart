import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/payment/screens/seat_selection_screen.dart';
import '../../features/payment/screens/ticket_type_selection_screen.dart';
import '../../features/payment/screens/contact_info_screen.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../../features/booking/screens/user_details_screen.dart';
import '../../features/booking/screens/payment_method_screen.dart';
import '../../features/booking/screens/order_summary_screen.dart';
import '../../features/booking/screens/payment_success_screen.dart';
import '../../features/explore/screens/explore_posts_page.dart';
import '../../features/explore/screens/igtv_feed_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/welcome_login_screen.dart';
import '../../features/auth/screens/email_login_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/two_factor_login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/location_setup_screen.dart';
import '../../features/auth/screens/congratulations_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/create_new_password_screen.dart';
import '../../features/auth/screens/signup_verification_screen.dart';
import '../../features/auth/screens/signup_phone_screen.dart';
import '../../features/auth/screens/signup_password_screen.dart';
import '../../features/auth/screens/signup_profile_screen.dart';
import '../../features/auth/screens/signup_success_screen.dart';
import '../../features/events/screens/home_screen.dart';
import '../../features/events/screens/event_details_screen.dart';
import '../../features/events/screens/event_attendees_screen.dart';
import '../../features/events/screens/organization_profile_screen.dart';
import '../../features/events/screens/notifications_screen.dart';
import '../../features/events/screens/all_events_screen.dart';
import '../../features/events/screens/search_screen.dart';
import '../../features/tickets/screens/my_tickets_screen_figma.dart';
import '../../features/tickets/screens/ticket_detail_screen.dart';
import '../../features/payment/screens/checkout_screen.dart';
import '../../features/profile/screens/account_screen.dart';
import '../../features/profile/screens/edit_personal_info_screen.dart';
import '../../features/profile/screens/notifications_preferences_screen.dart';
import '../../features/profile/screens/password_security_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
import '../../features/profile/screens/organizer_profile_screen.dart';
import '../../features/profile/screens/profile_posts_feed_screen.dart';
import '../../features/explore/screens/post_detail_screen.dart';
import '../../features/explore/screens/create_post_screen.dart';
import '../../features/events/widgets/mini_game_overlay.dart';

import '../../common_widgets/bottom_nav_bar.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      // Onboarding Routes
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(), // Removed const
      ),

      // Sign-up Flow Routes
      GoRoute(
        path: '/signup/verification',
        name: 'signup-verification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SignUpVerificationScreen(
            verificationType: extra['type'] as String? ?? 'email',
            destination: extra['destination'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/signup/password',
        name: 'signup-password',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SignUpPasswordScreen(
            email: extra['email'] as String? ?? '',
            phone: extra['phone'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/signup/phone',
        name: 'signup-phone',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SignUpPhoneScreen(
            email: extra['email'] as String? ?? '',
            password: extra['password'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/signup/phone-verification',
        name: 'signup-phone-verification',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SignUpVerificationScreen(
            verificationType: 'phone',
            destination: extra['phone'] as String? ?? '',
            email: extra['email'] as String? ?? '',
            password: extra['password'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/signup/profile',
        name: 'signup-profile',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SignUpProfileScreen(
            email: extra['email'] as String? ?? '',
            phone: extra['phone'] as String? ?? '',
            password: extra['password'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: '/signup/success',
        name: 'signup-success',
        builder: (context, state) => const SignUpSuccessScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: '/welcome-login',
        name: 'welcome-login',
        builder: (context, state) => const WelcomeLoginScreen(),
      ),
      GoRoute(
        path: '/email-login',
        name: 'email-login',
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/two-factor-login',
        name: 'two-factor-login',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TwoFactorLoginScreen(
            email: extra['email'] as String,
            password: extra['password'] as String,
            twoFactorMethod: extra['twoFactorMethod'] as String?,
          );
        },
      ),
      
      // Guest Mode Route (no bottom nav)
      GoRoute(
        path: '/guest-home',
        name: 'guest-home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/location-setup',
        name: 'location-setup',
        builder: (context, state) => const LocationSetupScreen(),
      ),
      GoRoute(
        path: '/congratulations',
        name: 'congratulations',
        builder: (context, state) => const CongratulationsScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/otp-verification',
        name: 'otp-verification',
        builder: (context, state) => OtpVerificationScreen(
          extra: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: '/create-new-password',
        name: 'create-new-password',
        builder: (context, state) => const CreateNewPasswordScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/all-events',
        name: 'all-events',
        builder: (context, state) {
          final title = state.uri.queryParameters['title'] ?? 'All Events';
          final initialFilter = state.uri.queryParameters['filter'] ?? 'All';
          return AllEventsScreen(
            screenTitle: title,
            initialFilter: initialFilter,
          );
        },
      ),
      GoRoute(
        path: '/search-screen',
        name: 'search-screen',
        builder: (context, state) => const SearchScreen(),
      ),

      // Event Detail Routes (MUST be before ShellRoute - no bottom nav)
      GoRoute(
        path: '/events/:eventId',
        name: 'event-details',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          print('Router: Building EventDetailsScreen for eventId: $eventId');
          return EventDetailsScreen(eventId: eventId);
        },
      ),
      
      // Guest Event Detail Route
      GoRoute(
        path: '/guest/events/:eventId',
        name: 'guest-event-details',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          print('Router: Building EventDetailsScreen (Guest) for eventId: $eventId');
          return EventDetailsScreen(eventId: eventId, isGuestMode: true);
        },
      ),

      // Event Attendees Route
      GoRoute(
        path: '/event/:eventId/attendees',
        name: 'event-attendees',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          return EventAttendeesScreen(eventId: eventId);
        },
      ),

      // Organizer Profile Route
      GoRoute(
        path: '/organization/:organizationId',
        name: 'organization-profile',
        builder: (context, state) {
          final organizationId = state.pathParameters['organizationId']!;
          return OrganizationProfileScreen(organizationId: organizationId);
        },
      ),

      // Post Detail Route
      GoRoute(
        path: '/explore/post/:postId',
        name: 'post-detail',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          print('🛣️ Router: Building PostDetailScreen for postId: $postId');
          return PostDetailScreen(postId: postId);
        },
      ),

      // IGTV Feed Route
      GoRoute(
        path: '/explore/igtv/:postId',
        name: 'igtv-feed',
        builder: (context, state) {
          final postId = state.pathParameters['postId']!;
          print('🛣️ Router: Building IGTVFeedScreen for postId: $postId');
          return IGTVFeedScreen(postId: postId);
        },
      ),

      // Create Post Route
      GoRoute(
        path: '/create-post',
        name: 'create-post',
        builder: (context, state) => const CreatePostScreen(),
      ),

      // Spinning Wheel Game Route
      GoRoute(
        path: '/games/spinning-wheel',
        name: 'spinning-wheel',
        builder: (context, state) => const SpinningWheelScreen(),
      ),

      // ── Account sub-screens (no bottom nav) ──────────────────────────
      GoRoute(
        path: '/account/edit-profile',
        name: 'edit-personal-info',
        builder: (context, state) => const EditPersonalInfoScreen(),
      ),
      GoRoute(
        path: '/account/notifications',
        name: 'notifications-preferences',
        builder: (context, state) => const NotificationsPreferencesScreen(),
      ),
      GoRoute(
        path: '/account/security',
        name: 'password-security',
        builder: (context, state) => const PasswordSecurityScreen(),
      ),

      // User Profile Route
      GoRoute(
        path: '/user/:userId',
        name: 'user-profile',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          print('🛣️ Router: Building UserProfileScreen for userId: $userId');
          return UserProfileScreen(userId: userId);
        },
      ),

      // Organizer Profile Route
      GoRoute(
        path: '/organizer/:organizerId',
        name: 'organizer-profile',
        builder: (context, state) {
          final organizerId = state.pathParameters['organizerId']!;
          print(
              '🛣️ Router: Building OrganizerProfileScreen for organizerId: $organizerId');
          return OrganizerProfileScreen(organizerId: organizerId);
        },
      ),

      // Fallback route for organizer without ID
      GoRoute(
        path: '/organizer',
        name: 'organizer-fallback',
        builder: (context, state) {
          print(
              '⚠️ Router: Accessed /organizer without ID, redirecting to home');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.orange),
                  SizedBox(height: 16),
                  Text(
                    'Organizer Not Found',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Unable to load organizer profile.'),
                ],
              ),
            ),
          );
        },
      ),

      // Profile Posts Feed Route
      GoRoute(
        path: '/profile/posts/:userId',
        name: 'profile-posts-feed',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final extra = state.extra as Map<String, dynamic>?;
          print(
              '🛣️ Router: Building ProfilePostsFeedScreen for userId: $userId');
          return ProfilePostsFeedScreen(
            userId: userId,
            username: extra?['username'],
          );
        },
      ),

      // Checkout Route
      GoRoute(
        path: '/checkout/:eventId',
        name: 'checkout',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final ticketType = state.uri.queryParameters['ticketType'] ?? '';
          final quantity =
              int.tryParse(state.uri.queryParameters['quantity'] ?? '1') ?? 1;
          return CheckoutScreen(
            eventId: eventId,
            ticketType: ticketType,
            quantity: quantity,
          );
        },
      ),

      // Booking Flow: Seat Selection
      GoRoute(
        path: '/checkout/:eventId/seat-selection',
        name: 'seat-selection',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final ticketType =
              state.uri.queryParameters['ticketType'] ?? 'Economy';
          final initialCount =
              int.tryParse(state.uri.queryParameters['seatCount'] ?? '1') ?? 1;
          return SeatSelectionScreen(
            eventId: eventId,
            ticketType: ticketType,
            initialCount: initialCount,
          );
        },
      ),

      // Ticket Type Selection (for events without custom seat maps)
      GoRoute(
        path: '/ticket-type-selection',
        name: 'ticket-type-selection',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return TicketTypeSelectionScreen(
            eventId: extra['eventId'] as String,
            ticketType: extra['ticketType'] as String,
            initialCount: extra['initialCount'] as int,
          );
        },
      ),

      // Booking Flow: Contact Info
      GoRoute(
        path: '/checkout/:eventId/contact',
        name: 'contact-info',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return ContactInfoScreen(
            eventId: eventId,
            eventName: extra['eventName'] ?? 'Event',
            eventDate: extra['eventDate'] ?? '',
            ticketType: extra['ticketType'] ?? '',
            seatCount: extra['seatCount'] ?? 1,
            selectedSeats:
                (extra['selectedSeats'] as List<String>?) ?? <String>[],
            selectedSeatData:
                (extra['selectedSeatData'] as List<Map<String, dynamic>>?) ??
                    <Map<String, dynamic>>[],
          );
        },
      ),

      // Booking Flow: Payment
      GoRoute(
        path: '/checkout/:eventId/payment',
        name: 'payment',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PaymentScreen(
            eventId: eventId,
            eventName: extra['eventName'] ?? 'Event',
            eventDate: extra['eventDate'] ?? '',
            ticketType: extra['ticketType'] ?? '',
            seatCount: extra['seatCount'] ?? 1,
            selectedSeats:
                (extra['selectedSeats'] as List<String>?) ?? <String>[],
            selectedSeatData:
                (extra['selectedSeatData'] as List<Map<String, dynamic>>?) ??
                    <Map<String, dynamic>>[],
          );
        },
      ),

      // New Multi-Step Booking Flow
      // Step 1: Enhanced Seat Selection
      GoRoute(
        path: '/booking/:eventId/seat-selection',
        name: 'booking-seat-selection',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return SeatSelectionScreen(
            eventId: eventId,
            ticketType: extra['ticketType'] ?? 'General',
            initialCount: extra['seatCount'] ?? 1,
          );
        },
      ),

      // Step 2: User Details
      GoRoute(
        path: '/booking/:eventId/user-details',
        name: 'user-details',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return UserDetailsScreen(
            eventId: eventId,
            eventName: extra['eventName'] ?? 'Event',
            eventDate: extra['eventDate'] ?? '',
            ticketType: extra['ticketType'] ?? '',
            seatCount: extra['seatCount'] ?? 1,
            selectedSeats:
                (extra['selectedSeats'] as List<String>?) ?? <String>[],
            selectedSeatData:
                (extra['selectedSeatData'] as List<Map<String, dynamic>>?) ??
                    <Map<String, dynamic>>[],
          );
        },
      ),

      // Step 3: Payment Method Selection
      GoRoute(
        path: '/booking/:eventId/payment-method',
        name: 'payment-method',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PaymentMethodScreen(
            eventId: eventId,
            bookingData: extra,
          );
        },
      ),

      // Step 4: Order Summary
      GoRoute(
        path: '/booking/:eventId/order-summary',
        name: 'order-summary',
        builder: (context, state) {
          final eventId = state.pathParameters['eventId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OrderSummaryScreen(
            eventId: eventId,
            bookingData: extra,
          );
        },
      ),

      // Step 5: Payment Success
      GoRoute(
        path: '/booking/payment-success',
        name: 'payment-success',
        builder: (context, state) {
          final bookingData = state.extra as Map<String, dynamic>? ?? {};
          print(
              '🔄 [ROUTER] Building PaymentSuccessScreen with data: $bookingData');

          try {
            return PaymentSuccessScreen(
              bookingData: bookingData,
            );
          } catch (e) {
            print('❌ [ROUTER] Error creating PaymentSuccessScreen: $e');
            rethrow;
          }
        },
      ),

      // E-Ticket View (new Figma design)
      GoRoute(
        path: '/ticket/:ticketId',
        name: 'e-ticket',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final ticket = extra['ticket'];

          return TicketDetailScreen(
            ticketId: ticketId,
            initialTicket: ticket,
          );
        },
      ),

      // Main App Routes with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) => BottomNavBar(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/search',
            name: 'search',
            builder: (context, state) => const ExplorePostsPage(),
          ),
          GoRoute(
            path: '/tickets',
            name: 'tickets',
            builder: (context, state) => const MyTicketsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const AccountScreen(),
          ),
        ],
      ),
    ],
  );
}
