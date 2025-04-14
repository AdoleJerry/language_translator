import 'package:final_year_project/auth/auth.dart';
import 'package:final_year_project/chat_rooms/audiochatpage.dart';
import 'package:final_year_project/landing_page.dart';
import 'package:final_year_project/chat_rooms/text_chatbox.dart';
import 'package:flutter/material.dart';
import 'package:final_year_project/custom_widgets/image_button.dart';
import 'package:provider/provider.dart';

class Homepage extends StatelessWidget {
  final CustomUser? user;
  const Homepage({super.key, this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Homepage',
          style: TextStyle(color: Colors.black, fontSize: 25),
        ),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: [
          logoutButton(context),
        ],
      ),
      body: _buildpage(context),
    );
  }

  IconButton logoutButton(BuildContext context) {
    return IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async{
           final auth = Provider.of<AuthBase>(context, listen: false);
           await auth.signOut();
           Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LandingPage()),
              (route) => false, // Remove all previous routes
            );
          },
        );
  }

  Widget _buildpage(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white
      ),
      child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ImageButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AudioChatPage(),
                      ));
                },
                imagePath: 'lib/assets/images/IMG-20241213-WA0175.jpg',
                height: 200,
              ),
              const SizedBox(height: 10,),
               const Text(
                  'Audio Translation',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, color: Colors.black),
                ),
              
              const SizedBox(
                height: 30,
              ),
              ImageButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        
                        builder: (context) { 
                          
                          return TextChatbox( userUid: user!.uid,);
                        }
                      ));
                },
                imagePath: 'lib/assets/images/Text to text translation.webp',
                height: 200,
              ),
                            const SizedBox(height: 10,),

              const Text(
                  'Text Translation',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 25, color: Colors.black),
                ),
              
            ],
          ),
      );
  }
}
