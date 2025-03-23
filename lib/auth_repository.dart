import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'auth_repository.g.dart';

class User {
  User({required this.username});
  final String username;
}

class AuthRepository extends ChangeNotifier {
  User? _user;

  User? get user => _user;

  Listenable get authStateListenable => this;

  Future<void> logIn({required String username}) async {
    _setUser(User(username: username));
  }

  Future<void> logOut() async {
    _setUser(null);
  }

  void _setUser(User? user) {
    _user = user;
    notifyListeners();
  }
}

@Riverpod(keepAlive: true)
Raw<AuthRepository> authRepository(Ref ref) {
  debugPrint('Initialized auth repository');
  return AuthRepository();
}
