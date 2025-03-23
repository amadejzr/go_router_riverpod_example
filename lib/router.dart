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

  final initialLocation = '/login';

  final List<GoRoute> routes = [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(path: '/page1', builder: (context, state) => const Page1Screen()),
    GoRoute(
      path: '/document/:id',
      builder: (context, state) => DocumentScreen(highlightedId: state.pathParameters['id']),
    ),
    GoRoute(path: '/login', builder: (context, state) => LoginPage()),
  ];

  String? redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = authRepository.user != null;

    final path = state.matchedLocation;
    final isDeeplink = state.uri.hasAuthority;

    if (isLoggedIn) {
      if (path.startsWith('/login')) {
        if (state.uri.queryParameters['from'] != null) {
          return state.uri.queryParameters['from'];
        }
        return '/';
      }

      if (isDeeplink) {
        final a = _extractDocumentPath(state.uri);

        if (a != null) {
          return a;
        }
      }
    } else {
      if (path == '/' || path.startsWith('/document') || path.startsWith('/page1')) {
        if (isDeeplink) {
          final a = _extractDocumentPath(state.uri);

          if (a != null) {
            return '/login?from=$a';
          }

          return '/login?from=${state.matchedLocation}';
        }
        return '/login';
      }
    }

    return null;
  }

  GoRouter get router => GoRouter(
    routes: routes,
    redirect: redirect,
    refreshListenable: authRepository.authStateListenable,
    initialLocation: initialLocation,
    errorBuilder: (context, state) => ErrorScreen(),
  );

  String? _extractDocumentPath(Uri uri) {
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
          Center(
            child: ElevatedButton(
              onPressed: () {
                ref.read(goRouterProvider).go('/document/123421');
              },
              child: const Text('Document screen'),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                ref.read(authRepositoryProvider).logOut();
              },
              child: const Text('Log out'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.push('https://example.com/documents?highlighted=doc1234');
            },
            child: Text('Test'),
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

class DocumentScreen extends ConsumerWidget {
  const DocumentScreen({super.key, this.highlightedId});
  final String? highlightedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('Document screen')),
      body: Center(
        child: Column(
          children: [
            Text(highlightedId != null ? 'Highlighted Document ID: $highlightedId' : 'No document highlighted'),
            ElevatedButton(
              onPressed: () {
                context.go('/');
              },
              child: Text('Go to home'),
            ),
          ],
        ),
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

class ErrorScreen extends StatelessWidget {
  const ErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Page does not exist')),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                context.go('/');
              },
              child: Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
