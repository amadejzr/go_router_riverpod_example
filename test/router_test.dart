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
    return GoRouterState(
      configuration,
      matchedLocation: location,
      uri: Uri.parse(location),
      pathParameters: const {},
      extra: null,
      name: null,
      fullPath: location,
      pageKey: ValueKey(location),
    );
  }

  group('GoRouterService.redirect', () {
    test('redirects to /login if not logged in and trying to access /page1', () {
      when(authRepository.user).thenAnswer((_) => User(username: '123'));
      final state = buildState('/documents/abc123?highlighted=doc456');
      final result = service.redirect(context, state);
      expect(result, '/document/doc456');
    });

    test('redirects to /login if not logged in and trying to access /page1', () {
      when(authRepository.user).thenAnswer((_) => null);
      final loginState = buildState('/documents/abc123?highlighted=doc456');
      final result = service.redirect(context, loginState);
      expect(result, startsWith('/login?from'));

      when(authRepository.user).thenAnswer((_) => User(username: '123'));

      final afterLoginState = buildState(result!);
      final afterLoginResult = service.redirect(context, afterLoginState);
      expect(afterLoginResult, startsWith('/document'));
    });
  });
}
