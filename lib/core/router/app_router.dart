import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:coin_circle/features/auth/presentation/screens/splash_screen.dart';
import 'package:coin_circle/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:coin_circle/features/auth/presentation/screens/login_screen.dart';
import 'package:coin_circle/features/auth/presentation/screens/register_screen.dart';
import 'package:coin_circle/features/auth/presentation/screens/email_verification_screen.dart';

import 'package:coin_circle/features/dashboard/presentation/screens/main_screen.dart';
import 'package:coin_circle/features/dashboard/presentation/screens/home_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/my_pools_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/wallet_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/profile_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/create_pool_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/pool_details_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/join_pool_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/payment_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/transaction_history_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/notifications_screen.dart';
import 'package:coin_circle/features/profile/presentation/screens/settings_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/winner_selection_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/voting_screen.dart';
import 'package:coin_circle/features/wallet/presentation/screens/payout_screen.dart';
import 'package:coin_circle/features/pools/presentation/screens/special_distribution_request_screen.dart';

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
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/winner-selection',
      builder: (context, state) => const WinnerSelectionScreen(),
    ),
    GoRoute(
      path: '/voting',
      builder: (context, state) => const VotingScreen(),
    ),
    GoRoute(
      path: '/payout',
      builder: (context, state) => const PayoutScreen(),
    ),
    GoRoute(
      path: '/special-distribution-request',
      builder: (context, state) => const SpecialDistributionRequestScreen(),
    ),
  ],
);
