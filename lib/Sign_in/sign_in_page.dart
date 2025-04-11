import 'package:final_year_project/Sign_in/auth/auth.dart';
import 'package:final_year_project/Sign_in/sign_in_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({
    super.key,
    this.isloading = false,
    this.manager,
  });

  final bool isloading;
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
              isloading: isLoading.value,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Material Hub',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
      ),
      body: _buildpage(context),
    );
  }

  Widget _buildpage(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'Images/book_image.jpg',
          fit: BoxFit.cover,
        ),
        Container(
          color: Colors.black.withOpacity(0.4),
        ),
        Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Image.asset('Images/app_logo.png'),
                  const SizedBox(height: 16.0),
                  if (isloading)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  else
                    const Text(
                      'Sign into Material Hub',
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(
                    height: 16.0,
                  ),
                  
                  
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}