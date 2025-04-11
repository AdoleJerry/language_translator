import 'package:final_year_project/custom_widgets/custom_raised_button.dart';
import 'package:flutter/material.dart';

class SignInButton extends CustomRaisedButton {
  SignInButton({
    super.key,
    required String text,
    required Color color,
    required Color textcolor,
    required VoidCallback onpressed,
  }) : super(
          child: Text(
            text,
            style: TextStyle(color: textcolor, fontSize: 15.0),
          ),
          color: color,
          onpressed: onpressed,
        );
}