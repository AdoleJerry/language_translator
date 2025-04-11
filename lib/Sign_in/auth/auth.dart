import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomUser {
  CustomUser({
    this.displayName,
    this.photoUrl,
    required this.uid,
    this.email,
  });

  final String? displayName;
  final String? photoUrl;
  final String uid;
  final String? email;
}

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

abstract class AuthBase {
  Stream<CustomUser?> get onAuthStateChanged;
  Future<CustomUser?> currentUser();
  Future<void> signOut();
  Future<CustomUser?> signInWithGoogle();
}

class Auth implements AuthBase {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  CustomUser? _userFromFirebase(User? user) {
    if (user == null) {
      return null;
    }
    return CustomUser(
      displayName: user.displayName,
      photoUrl: user.photoURL,
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
  Future<void> signOut() async {
    final googleSignIn = GoogleSignIn();
    await googleSignIn.signOut();
    await _auth.signOut();
  }
}