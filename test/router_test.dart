import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:go_router_riverpod_example/auth_repository.dart';
import 'package:go_router_riverpod_example/router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'router_test.mocks.dart';

@GenerateMocks([BuildContext, RouteConfiguration, AuthRepository])
void main() {
  late GoRouterService service;
  late MockBuildContext context;
  late MockRouteConfiguration configuration;
  late MockAuthRepository authRepository;

  setUp(() {
    authRepository = MockAuthRepository();
    service = GoRouterService(authRepository);
    context = MockBuildContext();
    configuration = MockRouteConfiguration();
  });

  GoRouterState buildState(String location) {
    final uri = Uri.parse(location);

    return GoRouterState(
      configuration,
      matchedLocation: uri.path,
      uri: uri,
      pathParameters: const {},
      fullPath: location,
      pageKey: ValueKey(location),
    );
  }

  group('GoRouterService.redirect', () {
    group('When user is logged in', () {
      test('Redirects to parsed link from link', () {
        when(authRepository.user).thenAnswer((_) => User(username: '123'));
        final state = buildState('https://example.com/documents?highlighted=doc1234');
        final result = service.redirect(context, state);
        expect(result, '/document/doc1234');
      });

      test('Does not redirect if route is valid in app', () {
        when(authRepository.user).thenAnswer((_) => User(username: '123'));
        final state = buildState('https://example.com/document/123');
        final result = service.redirect(context, state);
        expect(result, isNull);
      });

      test('Redirects to document from link', () {
        when(authRepository.user).thenAnswer((_) => User(username: '123'));
        final state = buildState('https://example.com/documents?highlighted=doc1234');
        final result = service.redirect(context, state);
        expect(result, '/document/doc1234');
      });

      test('User logs out', () {
        when(authRepository.user).thenAnswer((_) => User(username: '123'));
        var state = buildState('https://example.com/documents?highlighted=doc1234');
        var result = service.redirect(context, state);

        when(authRepository.user).thenAnswer((_) => null);
        state = buildState(result!);
        result = service.redirect(context, state);
        expect(result, '/login');
      });
    });

    group('When user is NOT logged in', () {
      test('Redirects to login screen', () {
        when(authRepository.user).thenAnswer((_) => null);
        final state = buildState('/');
        final result = service.redirect(context, state);
        expect(result, '/login');
      });

      test('Redirects to login with "from" param from link', () {
        when(authRepository.user).thenAnswer((_) => null);
        final state = buildState('https://example.com/documents?highlighted=doc1234');
        final result = service.redirect(context, state);
        expect(result, '/login?from=/document/doc1234');
      });

      test('Redirect chain: not logged in → login → logged in → final route', () {
        when(authRepository.user).thenAnswer((_) => null);
        var state = buildState('https://example.com/documents?highlighted=doc1234');
        var result = service.redirect(context, state);
        expect(result, '/login?from=/document/doc1234');

        // Simulate user logging in
        when(authRepository.user).thenAnswer((_) => User(username: '123'));
        state = buildState(result!);
        result = service.redirect(context, state);
        expect(result, '/document/doc1234');
      });

      test('Redirects unauthenticated user to login and resumes navigation to a valid route after login', () {
        when(authRepository.user).thenAnswer((_) => null);
        var state = buildState('https://example.com/document/123');
        var result = service.redirect(context, state);
        expect(result, '/login?from=/document/123');

        state = buildState(result!);
        result = service.redirect(context, state);
        expect(result, isNull);
      });
    });
  });
}
