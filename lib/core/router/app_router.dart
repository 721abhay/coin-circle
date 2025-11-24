import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:coin_circle/features/auth/presentation/screens/splash_screen.dart';
import 'package:coin_circle/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:coin_circle/features/auth/presentation/screens/login_screen.dart';
import 'package:coin_circle/features/auth/presentation/screens/register_screen.dart';
import 'package:coin_circle/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:coin_circle/features/auth/presentation/screens/profile_setup_screen.dart';
import 'package:coin_circle/features/dashboard/presentation/screens/main_screen.dart';
import 'package:coin_circle/features/dashboard/presentation/screens/home_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/my_pools_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/profile_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/create_pool_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/pool_details_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/join_pool_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/pool_search_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/payment_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/transaction_history_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/notifications_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/settings_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/winner_selection_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/voting_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/payout_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/special_distribution_request_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/payment_methods_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/withdraw_funds_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/add_money_screen.dart';
import 'package:coin_circle/features/gamification/presentation/screens/leaderboard_screen.dart';
import 'package:coin_circle/features/gamification/presentation/screens/referral_screen.dart';
import 'package:coin_circle/features/gamification/presentation/screens/friend_list_screen.dart';
import 'package:coin_circle/features/gamification/presentation/screens/review_list_screen.dart';
import 'package:coin_circle/features/gamification/presentation/screens/badge_list_screen.dart';
import 'package:coin_circle/features/admin/presentation/screens/creator_dashboard_screen.dart';
import 'package:coin_circle/features/admin/presentation/screens/member_management_screen.dart';
import 'package:coin_circle/features/admin/presentation/screens/announcements_screen.dart';
import 'package:coin_circle/features/admin/presentation/screens/pool_settings_screen.dart';
import 'package:coin_circle/features/admin/presentation/screens/financial_controls_screen.dart';
import 'package:coin_circle/features/admin/presentation/screens/moderation_dashboard_screen.dart';
import 'package:coin_circle/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:coin_circle/features/admin/presentation/screens/kyc_verification_screen.dart' as admin_kyc;
import 'package:coin_circle/features/profile/presentation/screens/personal_analytics_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/help_center_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/contact_support_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/community_support_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/feedback_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/public_profile_screen.dart';
import 'package:coin_circle/features/gamification/presentation/screens/create_review_screen.dart';
import 'package:coin_circle/features/gamification/presentation/screens/community_feed_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/security_settings_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/kyc_verification_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/kyc_submission_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/privacy_controls_screen.dart';
import 'package:coin_circle/features/disputes/presentation/screens/create_dispute_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/terms_of_service_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/faq_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/tutorial_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/report_problem_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/account_management_screen.dart';
// NEW SCREENS
import 'package:coin_circle/features/pools/presentation/screens/pool_chat_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/auto_pay_setup_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/pool_documents_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/pool_statistics_screen.dart';
// DEBUG
import 'package:coin_circle/features/debug/diagnostic_screen.dart';
// SUPPORT & WALLET
import 'package:coin_circle/features/support/presentation/screens/help_support_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/export_data_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/bank_accounts_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/terms_of_service_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/privacy_settings_screen.dart';
import 'package:coin_circle/features/support/presentation/screens/submit_ticket_screen.dart';
// NEW FEATURES
import 'package:coin_circle/features/savings/presentation/screens/smart_savings_screen.dart';
import 'package:coin_circle/features/expenses/presentation/screens/expense_tracker_screen.dart';
import 'package:coin_circle/features/goals/presentation/screens/financial_goals_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/setup_pin_screen.dart';
import 'package:coin_circle/features/auth/presentation/screens/verify_otp_screen.dart';



final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) => const EmailVerificationScreen(),
    ),
    GoRoute(
      path: '/verify-otp',
      builder: (context, state) {
        final email = state.uri.queryParameters['email'] ?? '';
        return VerifyOtpScreen(email: email);
      },
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainScreen(child: child),
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/my-pools',
          builder: (context, state) => const MyPoolsScreen(),
        ),
        GoRoute(
          path: '/wallet',
          builder: (context, state) => const WalletScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/create-pool',
      builder: (context, state) => const CreatePoolScreen(),
    ),
    GoRoute(
      path: '/pool-details/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return PoolDetailsScreen(poolId: id);
      },
    ),
    GoRoute(
      path: '/join-pool',
      builder: (context, state) => const JoinPoolScreen(),
    ),
    GoRoute(
      path: '/payment',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PaymentScreen(
          poolId: extra?['poolId'] ?? '',
          amount: extra?['amount'] ?? 0.0,
        );
      },
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionHistoryScreen(),
    ),
    GoRoute(
      path: '/wallet/payment-methods',
      builder: (context, state) => const PaymentMethodsScreen(),
    ),
    GoRoute(
      path: '/wallet/withdraw',
      builder: (context, state) => const WithdrawFundsScreen(),
    ),
    GoRoute(
      path: '/wallet/add-money',
      builder: (context, state) => const AddMoneyScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/winner-selection/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        return WinnerSelectionScreen(poolId: poolId);
      },
    ),
    GoRoute(
      path: '/voting/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        return VotingScreen(poolId: poolId);
      },
    ),
    GoRoute(
      path: '/payout',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return PayoutScreen(
          amount: extra?['amount'] ?? 0.0,
        );
      },
    ),
    GoRoute(
      path: '/special-distribution/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        return SpecialDistributionRequestScreen(poolId: poolId);
      },
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/referral',
      builder: (context, state) => const ReferralScreen(),
    ),
    GoRoute(
      path: '/friends',
      builder: (context, state) => const FriendListScreen(),
    ),
    GoRoute(
      path: '/reviews',
      builder: (context, state) => const ReviewListScreen(),
    ),
    GoRoute(
      path: '/badges',
      builder: (context, state) => const BadgeListScreen(),
    ),
    GoRoute(
      path: '/creator-dashboard/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        return CreatorDashboardScreen(poolId: poolId);
      },
    ),
    GoRoute(
      path: '/member-management/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        return MemberManagementScreen(poolId: poolId);
      },
    ),
    GoRoute(
      path: '/announcements/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        return AnnouncementsScreen(poolId: poolId);
      },
    ),
    GoRoute(
      path: '/pool-settings/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        return PoolSettingsScreen(poolId: poolId);
      },
    ),
    GoRoute(
      path: '/financial-controls/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        return FinancialControlsScreen(poolId: poolId);
      },
    ),
    GoRoute(
      path: '/moderation/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        return ModerationDashboardScreen(poolId: poolId);
      },
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const PersonalAnalyticsScreen(),
    ),
    GoRoute(
      path: '/help',
      builder: (context, state) => const HelpCenterScreen(),
    ),
    GoRoute(
      path: '/support/contact',
      builder: (context, state) => const ContactSupportScreen(),
    ),
    GoRoute(
      path: '/support/community',
      builder: (context, state) => const CommunitySupportScreen(),
    ),
    GoRoute(
      path: '/feedback',
      builder: (context, state) => const FeedbackScreen(),
    ),
    GoRoute(
      path: '/profile/:userId',
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return PublicProfileScreen(userId: userId);
      },
    ),
    GoRoute(
      path: '/create-review/:poolId',
      builder: (context, state) {
        // final poolId = state.pathParameters['poolId']!;
        return const CreateReviewScreen();
      },
    ),
    GoRoute(
      path: '/community-feed',
      builder: (context, state) => const CommunityFeedScreen(),
    ),
    GoRoute(
      path: '/settings/security',
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/kyc',
      builder: (context, state) => const KycVerificationScreen(),
    ),
    GoRoute(
      path: '/settings/privacy',
      builder: (context, state) => const PrivacyControlsScreen(),
    ),
    GoRoute(
      path: '/disputes/create/:poolId',
      builder: (context, state) {
        // final poolId = state.pathParameters['poolId']!;
        return const CreateDisputeScreen();
      },
    ),
    GoRoute(
      path: '/support/terms',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
    GoRoute(
      path: '/support/faq',
      builder: (context, state) => const FaqScreen(),
    ),
    GoRoute(
      path: '/support/tutorials',
      builder: (context, state) => const TutorialScreen(),
    ),
    GoRoute(
      path: '/support/report-problem',
      builder: (context, state) => const ReportProblemScreen(),
    ),
    GoRoute(
      path: '/settings/account-management',
      builder: (context, state) => const AccountManagementScreen(),
    ),
    // NEW ROUTES
    GoRoute(
      path: '/pool-chat/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        final extra = state.extra as Map<String, dynamic>?;
        return PoolChatScreen(
          poolId: poolId,
          poolName: extra?['poolName'] ?? 'Pool Chat',
        );
      },
    ),
    GoRoute(
      path: '/auto-pay-setup',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return AutoPaySetupScreen(poolId: extra?['poolId']);
      },
    ),
    GoRoute(
      path: '/pool-documents/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        return PoolDocumentsScreen(poolId: poolId);
      },
    ),
    GoRoute(
      path: '/pool-statistics/:poolId',
      builder: (context, state) {
        final poolId = state.pathParameters['poolId']!;
        return PoolStatisticsScreen(poolId: poolId);
      },
    ),
    // DEBUG ROUTE
    GoRoute(
      path: '/diagnostic',
      builder: (context, state) => const DiagnosticScreen(),
    ),
    // NEW ROUTES
    GoRoute(
      path: '/help-support',
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/export-data',
      builder: (context, state) => const ExportDataScreen(),
    ),
    GoRoute(
      path: '/bank-accounts',
      builder: (context, state) => const BankAccountsScreen(),
    ),
    GoRoute(
      path: '/terms',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
    GoRoute(
      path: '/privacy-policy',
      builder: (context, state) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: '/submit-ticket',
      builder: (context, state) => const SubmitTicketScreen(),
    ),
    // NEW FEATURES
    GoRoute(
      path: '/smart-savings',
      builder: (context, state) => const SmartSavingsScreen(),
    ),
    GoRoute(
      path: '/expense-tracker',
      builder: (context, state) => const ExpenseTrackerScreen(),
    ),
    GoRoute(
      path: '/financial-goals',
      builder: (context, state) => const FinancialGoalsScreen(),
    ),
    GoRoute(
      path: '/kyc-submission',
      builder: (context, state) => const KYCSubmissionScreen(),
    ),
    GoRoute(
      path: '/admin/kyc-verification',
      builder: (context, state) => const admin_kyc.KYCVerificationScreen(),
    ),
    GoRoute(
      path: '/setup-pin',
      builder: (context, state) => const SetupPinScreen(),
    ),
  ],
);
