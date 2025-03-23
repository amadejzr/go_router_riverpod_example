// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_riverpod_example/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'router.g.dart';

@riverpod
GoRouter goRouter(Ref ref) {
  //  final authRepository = ref.watch(authRepositoryProvider);
  return GoRouterService(ref.watch(authRepositoryProvider)).router;
}

class GoRouterService {
  GoRouterService(this.authRepository);

  final AuthRepository authRepository;

  final initialLocation = '/';

  final List<GoRoute> routes = [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/page1', builder: (context, state) => const Page1Screen()),
    GoRoute(
      path: '/document/:id',
      builder: (context, state) => Page2Screen(highlightedId: state.uri.queryParameters['id']),
    ),
    GoRoute(
      path: '/document/:id',
      builder: (context, state) => Page2Screen(highlightedId: state.uri.queryParameters['id']),
    ),
    GoRoute(path: '/login', builder: (context, state) => LoginPage()),
  ];

  String? redirect(BuildContext context, GoRouterState state) {
    final isLoginPage = state.matchedLocation.startsWith('/login');

    final isLoggedIn = authRepository.user != null;

    final docPath = _extractDocumentPath(state.matchedLocation);

    if (!isLoggedIn) {
      if (!isLoginPage) {
        if (docPath != null) {
          return '/login?from=$docPath';
        }
        return '/login?from=${state.matchedLocation}';
      }
      return null;
    }

    if (isLoginPage) {
      final from = state.uri.queryParameters['from'];
      return from ?? '/';
    }

    if (docPath != null && docPath != state.matchedLocation) {
      return docPath;
    }

    return null;
  }

  GoRouter get router =>
      GoRouter(routes: routes, redirect: redirect, refreshListenable: authRepository.authStateListenable);

  String? _extractDocumentPath(String urlPathAndQuery) {
    final uri = Uri.parse(urlPathAndQuery);

    if (!uri.path.startsWith('/documents/')) return null;

    final highlighted = uri.queryParameters['highlighted'];
    if (highlighted == null || highlighted.isEmpty) return null;

    return '/document/$highlighted';
  }
}

// Dummy screens for demonstration
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Column(
        children: [
          const Center(child: Text('Home')),
          ElevatedButton(
            onPressed: () {
              ref.read(authRepositoryProvider).logOut();
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    ),
  );
}

class Page1Screen extends StatelessWidget {
  const Page1Screen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Page 1')));
}

class Page2Screen extends StatelessWidget {
  const Page2Screen({super.key, this.highlightedId});
  final String? highlightedId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(highlightedId != null ? 'Highlighted Document ID: $highlightedId' : 'No document highlighted'),
      ),
    );
  }
}

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log in')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            ref.read(authRepositoryProvider).logIn(username: 'Test');
          },
          child: const Text('Log in'),
        ),
      ),
    );
  }
}
