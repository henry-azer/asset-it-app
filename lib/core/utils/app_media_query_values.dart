import 'package:flutter/material.dart';

class AppMediaQuery {
  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;
  
  static EdgeInsets padding(BuildContext context) => MediaQuery.of(context).padding;
  static EdgeInsets viewInsets(BuildContext context) => MediaQuery.of(context).viewInsets;
  
  static bool isPortrait(BuildContext context) => 
      MediaQuery.of(context).orientation == Orientation.portrait;
  
  static bool isLandscape(BuildContext context) => 
      MediaQuery.of(context).orientation == Orientation.landscape;
  
  static bool isSmallScreen(BuildContext context) => width(context) < 600;
  static bool isMediumScreen(BuildContext context) => 
      width(context) >= 600 && width(context) < 1200;
  static bool isLargeScreen(BuildContext context) => width(context) >= 1200;
}
