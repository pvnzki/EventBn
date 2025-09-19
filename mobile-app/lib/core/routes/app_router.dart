import 'package:go_router/go_router.dart';
import '../../features/payment/screens/seat_selection_screen.dart';
import '../../features/payment/screens/ticket_type_selection_screen.dart';
import '../../features/payment/screens/contact_info_screen.dart';
import '../../features/payment/screens/payment_screen.dart';
import '../../features/booking/screens/user_details_screen.dart';
import '../../features/booking/screens/payment_method_screen.dart';
import '../../features/booking/screens/order_summary_screen.dart';
import '../../features/booking/screens/payment_success_screen.dart';
import '../../features/tickets/screens/e_ticket_screen.dart' as tickets;
import '../../features/explore/screens/explore_posts_page.dart';
import '../../features/explore/screens/igtv_feed_screen.dart';
import '../../features/onboarding/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';
import '../../features/auth/screens/welcome_login_screen.dart';
import '../../features/auth/screens/email_login_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/location_setup_screen.dart';
import '../../features/auth/screens/congratulations_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/otp_verification_screen.dart';
import '../../features/auth/screens/create_new_password_screen.dart';
import '../../features/events/screens/home_screen.dart';
import '../../features/events/screens/event_details_screen.dart';
import '../../features/events/screens/event_attendees_screen.dart';
import '../../features/events/screens/organization_profile_screen.dart';
import '../../features/events/screens/notifications_screen.dart';
import '../../features/events/screens/all_events_screen.dart';
import '../../features/tickets/screens/my_tickets_screen.dart';
import '../../features/payment/screens/checkout_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
import '../../features/explore/screens/post_detail_screen.dart';
import '../../features/explore/screens/create_post_screen.dart';

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
        builder: (context, state) => const AllEventsScreen(),
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
            name: extra['name'] ?? '',
            email: extra['email'] ?? '',
            phone: extra['phone'] ?? '',
          );
        },
      ),

      // New Multi-Step Booking Flow
      // Step 1: Seat Selection
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
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return PaymentSuccessScreen(
            bookingData: extra,
            paymentId: extra['paymentId'] ?? '',
          );
        },
      ),

      // E-Ticket View
      GoRoute(
        path: '/ticket/:ticketId',
        name: 'e-ticket',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId']!;
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final ticket = extra['ticket'];
          
          return tickets.ETicketScreen(
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
            builder: (context, state) => ExplorePostsPage(
              focusSearch: state.extra is Map &&
                  (state.extra as Map)['focusSearch'] == true,
            ),
          ),
          GoRoute(
            path: '/tickets',
            name: 'tickets',
            builder: (context, state) => const MyTicketsScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
