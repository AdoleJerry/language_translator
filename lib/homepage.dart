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
          'Language Translator',
          style: TextStyle(color: Colors.black, fontSize: 25),
        ),
        backgroundColor: Colors.blueAccent,
        
        actions: [
          logoutButton(context),
        ],
      ),
      body: _buildpage(context),
    );
  }

  Widget logoutButton(BuildContext context) {
    return ElevatedButton.icon(
        label: const Text('Logout'),
          onPressed: () async{
            final confirmLogout = await showDialog<bool>(context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('No'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Yes'),
                ),
              ],
            ));
            if (confirmLogout == true) {
              final auth = Provider.of<AuthBase>(context, listen: false);
              await auth.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LandingPage()),
                (route) => false, // Remove all previous routes
              );
            }
          },
          icon: const Icon(Icons.logout),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
  }

  Widget _buildpage(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
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
                          builder: (context) { return AudioChatPage(userUid: user!.uid,);}
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
        ),
    );
  }
}
