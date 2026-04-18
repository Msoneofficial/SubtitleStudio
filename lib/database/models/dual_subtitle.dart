import 'package:flutter/material.dart';

class DualSubtitle {
  final String topSubtitle;
  final String bottomSubtitle;

  DualSubtitle({
    required this.topSubtitle,
    required this.bottomSubtitle,
  });
}


  Widget dualSubtitleBuilder(BuildContext context, dynamic subtitle) {
  // If no subtitle is provided, return an empty container.
  if (subtitle == null) return Container();

  // We expect the subtitle to be of type DualSubtitle.
  final DualSubtitle dualSubtitle = subtitle as DualSubtitle;

  return Stack(
    children: [
      // Top subtitle
      Positioned(
        top: 20.0,
        left: 0,
        right: 0,
        child: Center(
          child: Text(
            dualSubtitle.topSubtitle,
          ),
        ),
      ),
      // Bottom subtitle
      Positioned(
        bottom: 20.0,
        left: 0,
        right: 0,
        child: Center(
          child: Text(
            dualSubtitle.bottomSubtitle,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ],
  );
}
