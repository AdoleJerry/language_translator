
import 'package:final_year_project/Sign_in/auth/auth.dart';
import 'package:final_year_project/Sign_in/sign_in_page.dart';
import 'package:final_year_project/homepage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/database.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthBase>(context, listen: false);
    return StreamBuilder<CustomUser?>(
      stream: auth.onAuthStateChanged,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          CustomUser? user = snapshot.data;
          if (user == null) {
            return const SignInPage();
          } else {
            return Provider<CustomUser>.value(
              value: user,
              child: Provider<Database>(
                create: (_) => FirestoreDatabase(uid: user.uid),
                child: const Homepage(),
              ),
            );
          }
        } else {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
