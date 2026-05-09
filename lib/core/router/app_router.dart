import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';



import 'package:acneia/features/auth/presentation/screens/login_screen.dart';
import 'package:acneia/features/auth/presentation/screens/register_screen.dart';
import 'package:acneia/features/auth/presentation/screens/terms_screen.dart';
import 'package:acneia/features/auth/presentation/screens/welcome_screen.dart';
import 'package:acneia/features/home/presentation/screens/home_screen.dart';
import 'package:acneia/features/detection/presentation/screens/detection_result_screen.dart';
import 'package:acneia/features/recommendation/presentation/screens/recommendation_screen.dart';
import 'package:acneia/features/recommendation/presentation/screens/my_routine_screen.dart';
import 'package:acneia/features/chat/presentation/screens/chat_screen.dart';
import 'package:acneia/features/home/presentation/screens/evolution_screen.dart';
import 'package:acneia/features/prediction/presentation/screens/prediction_screen.dart';
import 'package:acneia/features/profile/presentation/screens/profile_screen.dart';
import 'package:acneia/features/profile/presentation/screens/history_screen.dart';
import 'package:acneia/features/forum/presentation/screens/forum_screen.dart';
import 'package:acneia/features/forum/presentation/screens/forum_detail_screen.dart';
import 'package:acneia/features/forum/presentation/screens/create_post_screen.dart';
import 'package:acneia/features/forum/presentation/cubit/forum_cubit.dart';
import 'package:acneia/features/forum/data/services/forum_service.dart';
import 'package:acneia/features/messaging/presentation/screens/conversations_screen.dart';
import 'package:acneia/features/messaging/presentation/screens/chat_private_screen.dart';
import 'package:acneia/features/questionnaire/presentation/screens/profile_questionnaire_screen.dart';
import 'package:acneia/features/questionnaire/presentation/screens/daily_questionnaire_screen.dart';
import 'package:acneia/features/questionnaire/presentation/screens/weekly_questionnaire_screen.dart';
import 'package:acneia/features/notification/presentation/screens/notification_screen.dart';
import 'package:acneia/features/questionnaire/domain/entities/user_profile.dart';
import 'package:acneia/features/prediction/domain/entities/prediction_result.dart';
import 'package:acneia/core/widgets/main_scaffold.dart';



final _rootKey  = GlobalKey<NavigatorState>();

final _shellKey = GlobalKey<NavigatorState>();



final appRouter = GoRouter(

  navigatorKey: _rootKey,

  initialLocation: '/welcome',

  redirect: (context, state) {

    final authed = FirebaseAuth.instance.currentUser != null;

    final isAuth = state.matchedLocation.startsWith('/welcome') ||

                   state.matchedLocation.startsWith('/login') ||

                   state.matchedLocation.startsWith('/register') ||

                   state.matchedLocation.startsWith('/terms');

    if (!authed && !isAuth) return '/welcome';

    

    // Si déjà connecté et sur une page d'auth, on laisse passer vers home 

    // SAUF si on est dans le flux d'onboarding/questionnaire

    if (authed && isAuth) return '/home';

    

    return null;

  },

  routes: [

    // â”€â”€ Auth (pas de shell) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    GoRoute(path: '/welcome',  builder: (_, __) => const WelcomeScreen()),

    GoRoute(path: '/login',    builder: (_, __) => const LoginScreen()),

    GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

    GoRoute(path: '/terms',    builder: (_, __) => const TermsScreen()),



    // â”€â”€ Shell (bottom nav) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

    ShellRoute(

      navigatorKey: _shellKey,

      builder: (_, __, child) => MainScaffold(child: child),

      routes: [

        GoRoute(path: '/home',       builder: (_, __) => const HomeScreen()),

        GoRoute(path: '/chat',       builder: (_, __) => const ChatScreen()),

        GoRoute(

          path: '/prediction', 

          builder: (_, state) => PredictionScreen(

            initialResult: state.extra as PredictionResult?,

          ),

        ),

        GoRoute(path: '/profile',    builder: (_, __) => const ProfileScreen()),

        GoRoute(path: '/notifications', builder: (_, __) => const NotificationScreen()),

        GoRoute(

          path: '/detection/result',

          builder: (_, state) => DetectionResultScreen(

            detectionData: state.extra as Map<String, dynamic>,

          ),

        ),

        GoRoute(

          path: '/recommendation/:detectionId',

          builder: (_, state) => RecommendationScreen(

            detectionId: state.pathParameters['detectionId']!,

            detectionData: state.extra as Map<String, dynamic>?,

          ),

        ),

        GoRoute(path: '/my-routine', builder: (_, __) => const MyRoutineScreen()),

        GoRoute(path: '/evolution', builder: (_, __) => const EvolutionScreen()),

      ],

    ),



    // ————————————————————————————————————————————————————————

    GoRoute(

      path: '/history', 

      builder: (_, state) {

        final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;

        return HistoryScreen(initialTab: tab);
      }
    ),

    GoRoute(
      path: '/forum', 
      builder: (_, __) => BlocProvider(
        create: (context) => ForumCubit(ForumService())..loadPosts(),
        child: const ForumScreen(),
      ),
    ),

    GoRoute(

      path: '/forum/create',

      builder: (_, __) => const CreatePostScreen(),

    ),

    GoRoute(

      path: '/forum/:id',

      builder: (_, state) => ForumDetailScreen(postId: state.pathParameters['id']!),

    ),

    GoRoute(path: '/messages',      builder: (_, __) => const ConversationsScreen()),

    GoRoute(

      path: '/messages/:convId',

      builder: (_, state) => ChatPrivateScreen(

        conversationId: state.pathParameters['convId']!,

      ),

    ),

    GoRoute(

      path: '/onboarding', 

      builder: (_, state) => ProfileQuestionnaireScreen(

        initialProfile: state.extra as UserProfile?,

      ),

    ),

    GoRoute(path: '/daily-survey',  builder: (_, __) => const DailyQuestionnaireScreen()),

    GoRoute(path: '/weekly-survey', builder: (_, __) => const WeeklyQuestionnaireScreen()),


  ],

);



