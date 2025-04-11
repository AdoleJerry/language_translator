import 'package:flutter/material.dart';

class CustomRaisedButton extends StatelessWidget {
  const CustomRaisedButton({
    super.key,
    this.child,
    this.color,
    this.borderRadius = 2.0,
    this.onpressed,
    this.height = 50.0,
  });
  final Widget? child;
  final Color? color;
  final double borderRadius;
  final void Function()? onpressed;
  final double height;
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 50.0,
        child: ElevatedButton(
          onPressed: onpressed,
          style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusDirectional.circular(10),
              )),
          child: child,
        ));
  }
}