import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_facebook_login/flutter_facebook_login.dart';
import 'package:isotope_auth/isotope_auth.dart';

class FacebookAuthService extends AuthServiceAdapter {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<IsotopeIdentity> currentIdentity() async {
    final FirebaseUser user = await _firebaseAuth.currentUser();
    return _identityFromFirebase(user);
  }

  @override
  Stream<IsotopeIdentity> get onAuthStateChanged {
    authStateChangedController.stream;
    return _firebaseAuth.onAuthStateChanged.map(_identityFromFirebase);
  }

  @override
  AuthProvider get provider {
    return AuthProvider.anonymous;
  }

  @override
  Future<IsotopeIdentity> signIn(Map<String, dynamic> _credentials) async {
    final FacebookLogin facebookLogin = FacebookLogin();
    const REQUESTED_SCOPES = 'public_profile';

    // https://github.com/roughike/flutter_facebook_login/issues/210
    facebookLogin.loginBehavior = FacebookLoginBehavior.webViewOnly;
    
    final FacebookLoginResult result = await facebookLogin.logIn(<String>[REQUESTED_SCOPES]);
    
    if (result.accessToken != null) {
      final AuthResult authResult = await _firebaseAuth.signInWithCredential(
        FacebookAuthProvider.getCredential(
          accessToken: result.accessToken.token
        )
      );

      return _identityFromFirebase(authResult.user);
    } 
    else {
      throw PlatformException(
        code: 'ERROR_ABORTED_BY_USER', 
        message: 'Sign in aborted by user'
      );
    }
  }

  @override
  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  IsotopeIdentity _identityFromFirebase(FirebaseUser user) {
    if (user == null) {
      return null;
    }
    return IsotopeIdentity(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoUrl,
    );
  }
}
