import 'package:final_year_project/Sign_in/auth/auth.dart';
import 'package:final_year_project/landing_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); 
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Provider<AuthBase>(
      create: (context) => Auth(),
      child: const MaterialApp(
        title: 'Flutter Demo',
        home: LandingPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
