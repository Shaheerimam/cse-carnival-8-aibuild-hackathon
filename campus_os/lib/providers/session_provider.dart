import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_session.dart';

class SessionProvider extends ChangeNotifier {
  SessionProvider() {
    _authSubscription = _auth.authStateChanges().listen(_handleAuthStateChanged);
    _bootstrap();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;

  UserSession? _currentUser;
  bool _isResolvingAuth = true;

  UserSession? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isResolvingAuth => _isResolvingAuth;

  Future<void> _bootstrap() async {
    await _handleAuthStateChanged(_auth.currentUser);
  }

  Future<void> _handleAuthStateChanged(User? firebaseUser) async {
    _isResolvingAuth = true;
    notifyListeners();

    if (firebaseUser == null) {
      _currentUser = null;
      _isResolvingAuth = false;
      notifyListeners();
      return;
    }

    if (firebaseUser.isAnonymous) {
      _currentUser = null;
      _isResolvingAuth = false;
      notifyListeners();
      await _auth.signOut();
      return;
    }

    final profile = await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (!profile.exists || profile.data() == null) {
      _currentUser = null;
      _isResolvingAuth = false;
      notifyListeners();
      await _auth.signOut();
      return;
    }

    _currentUser = UserSession.fromFirestore(
      profile.data()!,
      uid: firebaseUser.uid,
    );
    _isResolvingAuth = false;
    notifyListeners();
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _handleAuthStateChanged(_auth.currentUser);
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
    required String department,
    required String role,
    String? identifier,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'Unable to create the user account.',
      );
    }

    final session = UserSession(
      uid: firebaseUser.uid,
      email: email,
      name: name,
      department: department,
      role: role,
      identifier: identifier,
    );

    await _firestore.collection('users').doc(firebaseUser.uid).set(session.toFirestore());

    try {
      await firebaseUser.updateDisplayName(session.displayLabel);
    } catch (_) {
      // The app still works if the auth profile sync fails.
    }

    _currentUser = session;
    _isResolvingAuth = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    _currentUser = null;
    _isResolvingAuth = false;
    notifyListeners();
    await _auth.signOut();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}