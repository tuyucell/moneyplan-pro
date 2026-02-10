import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  final g = GoogleSignIn();
  final res = await g.signIn();
  if (res != null) {
    final auth = await res.authentication;
    debugPrint(auth.idToken);
  }
}
