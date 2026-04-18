import 'package:flutter/material.dart';

class ScrollingTitleWidget extends StatelessWidget {
  final String title;
  final TextStyle? style;
  final double maxWidth;

  const ScrollingTitleWidget({
    super.key,
    required this.title,
    this.style,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxWidth,
      child: Text(
        title,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
