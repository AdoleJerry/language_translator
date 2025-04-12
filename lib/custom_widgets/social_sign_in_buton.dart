import 'package:final_year_project/custom_widgets/custom_raised_button.dart';
import 'package:flutter/material.dart';

class SocialSignInButton extends CustomRaisedButton {
  SocialSignInButton({
    super.key,
    required String asset,
    required String text,
    required Color color,
    required Color textcolor,
    required VoidCallback onpressed,
  }) : super(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(asset),
              Text(
                text,
                style: TextStyle(color: textcolor, fontSize: 15.0),
              ),
              Opacity(
                opacity: 0.0,
                child: Image.asset(asset),
              ),
            ],
          ),
          color: color,
          onpressed: onpressed,
        );
}