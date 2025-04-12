import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class CustomUser {
  CustomUser({
    required this.uid,
    this.email,
  });

  final String uid;
  final String? email;
}

abstract class AuthBase {
  Stream<CustomUser?> get onAuthStateChanged;
  Future<CustomUser?> currentUser();
  Future<void> signOut();
  Future<CustomUser?> signInWithGoogle();
  Future<CustomUser?> signInAnonymously();
}

class Auth implements AuthBase {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CustomUser? _userFromFirebase(User? user) {
    if (user == null) {
      return null;
    }
    return CustomUser(
      uid: user.uid,
      email: user.email,
    );
  }

  @override
  Stream<CustomUser?> get onAuthStateChanged {
    return _auth.authStateChanges().map(_userFromFirebase);
  }


  @override
  Future<CustomUser?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleSignInAccount =
        await googleSignIn.signIn();
    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleSignInAccount.authentication;
      if (googleAuth.accessToken != null && googleAuth.idToken != null) {
        final authresult = await _auth.signInWithCredential(
          GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
            accessToken: googleAuth.accessToken,
          ),
        );
        return _userFromFirebase(authresult.user);
      } else {
        throw PlatformException(
            code: 'ERROR_MISSSING_GOOGLE_AUTH_TOKEN',
            message: 'Missing Google Auth Token');
      }
    } else {
      throw PlatformException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }
  }

  @override
  Future<CustomUser?> currentUser() async {
    final user = _auth.currentUser;
    return _userFromFirebase(user);
  }

@override
  Future<CustomUser?> signInAnonymously() async {
    final authResult = await _auth.signInAnonymously();
    return _userFromFirebase(authResult.user);
  }

  @override
  Future<void> signOut() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await _auth.signOut();
  }
}