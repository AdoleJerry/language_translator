import 'package:final_year_project/auth/auth.dart';
import 'package:final_year_project/Sign_in/sign_in_button.dart';
import 'package:final_year_project/Sign_in/sign_in_manager.dart';
import 'package:final_year_project/custom_widgets/social_sign_in_buton.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({
    super.key,
    this.manager,
  });

  final SignInManager? manager;

  static Widget create(BuildContext context) {
    final auth = Provider.of<AuthBase>(context, listen: false);
    return ChangeNotifierProvider<ValueNotifier<bool>>(
      create: (_) => ValueNotifier<bool>(false),
      child: Consumer<ValueNotifier<bool>>(
        builder: (_, isLoading, __) => Provider<SignInManager>(
          create: (_) => SignInManager(auth: auth, isLoading: isLoading),
          child: Consumer<SignInManager>(
            builder: (context, manager, _) => SignInPage(
              manager: manager,
            ),
          ),
        ),
      ),
    );
  }

  @override
  SignInPageState createState() => SignInPageState();
}

class SignInPageState extends State<SignInPage> {
  bool isloading = false;

  void _setLoading(bool value) {
    if (mounted){
    setState(() {
      isloading = value;
    });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Language Translator',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: _buildpage(context),
    );
  }

  Widget _buildpage(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Container(
            color: Colors.white, // Replace inner Scaffold with a Container
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Text(
                          'Sign In',
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                  const SizedBox(height: 40),
                  SocialSignInButton(
                    asset: 'lib/assets/images/google_logo.png',
                    text: 'Sign in With google',
                    color: Colors.white,
                    textcolor: Colors.black,
                    onpressed: () async {
                      isloading ? null :
                      _setLoading(true);
                      try {
                        final auth = Provider.of<AuthBase>(context, listen: false);
                        await auth.signInWithGoogle();
                      } on PlatformException catch (e) {
                        if (e.code == 'ERROR_ABORTED_BY_USER') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sign-in canceled by user.')),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Sign-in failed: ${e.message}')),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('An unexpected error occurred: $e')),
                        );
                      } finally {
                        _setLoading(false);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text('or'),
                  const SizedBox(height: 20),
                  SignInButton(
                    text: 'Sign in anonymously',
                    color: Colors.green,
                    textcolor: Colors.white,
                    onpressed: () async {
                       isloading ? null :
                      _setLoading(true);
                      try {
                        final auth = Provider.of<AuthBase>(context, listen: false);
                        await auth.signInAnonymously();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('An unexpected error occurred: $e')),
                        );
                      } finally {
                        _setLoading(false);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        if (isloading)
          const Center(
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}