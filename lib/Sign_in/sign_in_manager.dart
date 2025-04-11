import 'package:final_year_project/Sign_in/auth/auth.dart';
import 'package:flutter/foundation.dart';

class SignInManager {
  SignInManager({
    required this.auth,
    required this.isLoading,
  });
  final AuthBase auth;
  final ValueNotifier<bool> isLoading;
}