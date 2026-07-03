import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'pluto_note.dart';

class PlutoAuthService {
  PlutoAuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  PlutoAuthService.test() : _firebaseAuth = null, _googleSignIn = null;

  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn? _googleSignIn;

  Stream<PlutoUser?> get authStateChanges {
    final auth = _firebaseAuth;
    if (auth == null) {
      return const Stream<PlutoUser?>.empty();
    }
    return auth.authStateChanges().map(_toPlutoUser);
  }

  PlutoUser? get currentUser => _toPlutoUser(_firebaseAuth?.currentUser);

  Future<PlutoUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw const PlutoAuthException('Sign-in is not available in tests.');
    }

    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return _requirePlutoUser(credential.user);
    } on FirebaseAuthException catch (error) {
      throw PlutoAuthException(_emailSignInMessage(error));
    }
  }

  Future<PlutoUser> createAccountWithEmail({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw const PlutoAuthException(
        'Account creation is not available in tests.',
      );
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw const PlutoAuthException(
          'Account was created but sign-in failed.',
        );
      }

      final trimmedDisplayName = displayName.trim();
      if (trimmedDisplayName.isNotEmpty) {
        await user.updateDisplayName(trimmedDisplayName);
        await user.reload();
      }

      return _requirePlutoUser(auth.currentUser ?? user);
    } on FirebaseAuthException catch (error) {
      throw PlutoAuthException(_accountCreationMessage(error));
    }
  }

  Future<PlutoUser> signInWithGoogle() async {
    final auth = _firebaseAuth;
    final googleSignIn = _googleSignIn;
    if (auth == null || googleSignIn == null) {
      throw const PlutoAuthException(
        'Google sign-in is not available in tests.',
      );
    }

    try {
      await googleSignIn.initialize();
      final googleAccount = await googleSignIn.authenticate();
      final googleAuthentication = googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuthentication.idToken,
      );
      final userCredential = await auth.signInWithCredential(credential);

      return _requirePlutoUser(userCredential.user);
    } on FirebaseAuthException catch (error) {
      throw PlutoAuthException(_oauthMessage(error, 'Google'));
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const PlutoAuthException('Google sign-in was cancelled.');
      }
      throw PlutoAuthException('Google sign-in failed: ${error.description}');
    }
  }

  Future<PlutoUser> signInWithApple() async {
    final auth = _firebaseAuth;
    if (auth == null) {
      throw const PlutoAuthException(
        'Apple sign-in is not available in tests.',
      );
    }

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );
      final userCredential = await auth.signInWithCredential(oauthCredential);

      final user = userCredential.user;
      final appleName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].whereType<String>().join(' ').trim();

      if (user != null && appleName.isNotEmpty && user.displayName == null) {
        await user.updateDisplayName(appleName);
        await user.reload();
      }

      return _requirePlutoUser(auth.currentUser ?? user);
    } on SignInWithAppleAuthorizationException catch (error) {
      if (error.code == AuthorizationErrorCode.canceled) {
        throw const PlutoAuthException('Apple sign-in was cancelled.');
      }
      throw PlutoAuthException('Apple sign-in failed: ${error.message}');
    } on FirebaseAuthException catch (error) {
      throw PlutoAuthException(_oauthMessage(error, 'Apple'));
    }
  }

  Future<void> signOut() async {
    final auth = _firebaseAuth;
    if (auth == null) {
      return;
    }

    try {
      await auth.signOut();
      await _googleSignIn?.signOut();
    } on FirebaseAuthException catch (error) {
      throw PlutoAuthException(_oauthMessage(error, 'Sign out'));
    }
  }

  PlutoUser _requirePlutoUser(User? user) {
    final plutoUser = _toPlutoUser(user);
    if (plutoUser == null) {
      throw const PlutoAuthException(
        'Sign-in finished without a user session.',
      );
    }

    return plutoUser;
  }

  PlutoUser? _toPlutoUser(User? user) {
    if (user == null) {
      return null;
    }

    final now = DateTime.now();
    return PlutoUser(
      id: user.uid,
      displayName: user.displayName ?? '',
      email: user.email ?? '',
      createdAt: user.metadata.creationTime ?? now,
      updatedAt: user.metadata.lastSignInTime ?? now,
    );
  }

  String _emailSignInMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'user-disabled':
        return 'This Pluto account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'network-request-failed':
        return 'No connection. Pluto can still save local notes after sign-in.';
      default:
        return 'Email sign-in failed. ${error.message ?? 'Try again.'}';
    }
  }

  String _accountCreationMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'That email already has a Pluto account.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Use a stronger password for this Pluto account.';
      case 'network-request-failed':
        return 'No connection. Account creation needs internet access.';
      default:
        return 'Could not create the Pluto account. ${error.message ?? 'Try again.'}';
    }
  }

  String _oauthMessage(FirebaseAuthException error, String provider) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'This email is already linked to another sign-in method.';
      case 'invalid-credential':
        return '$provider returned an invalid sign-in token.';
      case 'network-request-failed':
        return 'No connection. $provider sign-in needs internet access.';
      default:
        return '$provider sign-in failed. ${error.message ?? 'Try again.'}';
    }
  }
}

class PlutoAuthException implements Exception {
  const PlutoAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
