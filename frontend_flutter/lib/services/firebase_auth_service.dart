import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/app_models.dart';

class FirebaseAuthDiagnosticException implements Exception {
  const FirebaseAuthDiagnosticException({
    required this.operation,
    required this.summary,
    required this.details,
  });

  final String operation;
  final String summary;
  final String details;

  @override
  String toString() => '$summary\n$details';
}

class FirebaseAuthService {
  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<UserProfile> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null || user.email == null) {
        throw const FirebaseAuthDiagnosticException(
          operation: 'signInWithEmail',
          summary: 'Firebase returned an empty authenticated user.',
          details: 'The sign-in request succeeded but no Firebase user object was returned.',
        );
      }
      return UserProfile.fromFirebase(
        id: user.uid,
        email: user.email!,
        displayName: user.displayName ?? user.email!,
      );
    } catch (error, stackTrace) {
      throw _wrapException(
        operation: 'signInWithEmail',
        error: error,
        stackTrace: stackTrace,
        email: email,
      );
    }
  }

  Future<UserProfile> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null || user.email == null) {
        throw const FirebaseAuthDiagnosticException(
          operation: 'registerWithEmail',
          summary: 'Firebase returned an empty registered user.',
          details: 'The registration request succeeded but no Firebase user object was returned.',
        );
      }
      await user.updateDisplayName(displayName);
      await user.reload();
      final refreshed = _auth.currentUser;
      return UserProfile.fromFirebase(
        id: refreshed?.uid ?? user.uid,
        email: refreshed?.email ?? user.email!,
        displayName: refreshed?.displayName ?? displayName,
      );
    } catch (error, stackTrace) {
      throw _wrapException(
        operation: 'registerWithEmail',
        error: error,
        stackTrace: stackTrace,
        email: email,
      );
    }
  }

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (error, stackTrace) {
      throw _wrapException(
        operation: 'sendPasswordResetEmail',
        error: error,
        stackTrace: stackTrace,
        email: email,
      );
    }
  }

  Future<void> updatePassword({
    required String email,
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw const FirebaseAuthDiagnosticException(
          operation: 'updatePassword',
          summary: 'No authenticated Firebase user is available.',
          details: 'Sign in again before changing the password.',
        );
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } catch (error, stackTrace) {
      throw _wrapException(
        operation: 'updatePassword',
        error: error,
        stackTrace: stackTrace,
        email: email,
      );
    }
  }

  Future<void> deleteCurrentAccount({
    required String email,
    required String currentPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw const FirebaseAuthDiagnosticException(
          operation: 'deleteCurrentAccount',
          summary: 'No authenticated Firebase user is available.',
          details: 'Sign in again before deleting the account.',
        );
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.delete();
    } catch (error, stackTrace) {
      throw _wrapException(
        operation: 'deleteCurrentAccount',
        error: error,
        stackTrace: stackTrace,
        email: email,
      );
    }
  }

  Future<String> requestPhoneOtp({
    required String phoneNumber,
    required Future<void> Function(UserProfile profile) onAutoVerified,
  }) async {
    final completer = Completer<String>();
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        try {
          final profile = await _signInWithPhoneCredential(credential);
          await onAutoVerified(profile);
        } catch (_) {}
      },
      verificationFailed: (error) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (!completer.isCompleted) {
          completer.complete(verificationId);
        }
      },
    );
    return completer.future;
  }

  Future<UserProfile> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _signInWithPhoneCredential(credential);
  }

  Future<UserProfile> _signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) async {
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user == null || user.phoneNumber == null) {
      throw const FirebaseAuthDiagnosticException(
        operation: 'signInWithPhoneCredential',
        summary: 'Firebase returned an empty phone-authenticated user.',
        details: 'Phone verification completed but no phone-authenticated user was returned.',
      );
    }
    return UserProfile.fromFirebase(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? user.phoneNumber!,
    );
  }

  FirebaseAuthDiagnosticException _wrapException({
    required String operation,
    required Object error,
    required StackTrace stackTrace,
    required String email,
  }) {
    if (error is FirebaseAuthDiagnosticException) {
      debugPrint('[MedicoHubAuth][$operation] ${error.toString()}');
      debugPrintStack(stackTrace: stackTrace);
      return error;
    }

    final app = Firebase.app();
    final environment = [
      'operation=$operation',
      'platform=${_platformLabel()}',
      'firebaseApp=${app.name}',
      'projectId=${app.options.projectId}',
      'authDomain=${app.options.authDomain ?? '(none)'}',
      'storageBucket=${app.options.storageBucket ?? '(none)'}',
      'email=$email',
    ].join('\n');

    String summary = 'Firebase authentication failed.';
    final detailLines = <String>[environment];

    if (error is FirebaseAuthException) {
      summary = 'Firebase auth error: ${error.code}';
      detailLines.add('message=${error.message ?? '(none)'}');
      detailLines.add('plugin=${error.plugin}');
      detailLines.add('native=${error.toString()}');
    } else if (error is PlatformException) {
      summary = 'Platform exception during Firebase auth.';
      detailLines.add('code=${error.code}');
      detailLines.add('message=${error.message ?? '(none)'}');
      detailLines.add('details=${error.details ?? '(none)'}');
    } else {
      detailLines.add('runtimeType=${error.runtimeType}');
      detailLines.add('message=$error');
    }

    detailLines.add('stack=${stackTrace.toString()}');
    final wrapped = FirebaseAuthDiagnosticException(
      operation: operation,
      summary: summary,
      details: detailLines.join('\n'),
    );
    debugPrint('[MedicoHubAuth][$operation] ${wrapped.toString()}');
    debugPrintStack(stackTrace: stackTrace);
    return wrapped;
  }

  String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isWindows) {
      return 'windows';
    }
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.isLinux) {
      return 'linux';
    }
    if (Platform.isMacOS) {
      return 'macos';
    }
    return 'unknown';
  }
}
