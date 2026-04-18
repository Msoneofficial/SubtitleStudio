import 'package:flutter/material.dart';
import 'package:subtitle_studio/widgets/custom_text_render.dart';

class PositionedSubtitle extends StatelessWidget {
  final String subtitle;

  const PositionedSubtitle({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    String subtitleText = subtitle;
    Alignment alignment = Alignment.bottomCenter; // default alignment

    // Look for an alignment tag like {\an8} using a regular expression.
    final RegExp regExp = RegExp(r"\{\\an([1-9])\}");
    final Match? match = regExp.firstMatch(subtitle);
    if (match != null) {
      final String tag = match.group(0)!; // e.g. "{\an8}"
      switch (tag) {
        case r'{\an1}':
          alignment = Alignment.bottomLeft;
          break;
        case r'{\an2}':
          alignment = Alignment.bottomCenter;
          break;
        case r'{\an3}':
          alignment = Alignment.bottomRight;
          break;
        case r'{\an4}':
          alignment = Alignment.centerLeft;
          break;
        case r'{\an5}':
          alignment = Alignment.center;
          break;
        case r'{\an6}':
          alignment = Alignment.centerRight;
          break;
        case r'{\an7}':
          alignment = Alignment.topLeft;
          break;
        case r'{\an8}':
          alignment = Alignment.topCenter;
          break;
        case r'{\an9}':
          alignment = Alignment.topRight;
          break;
        default:
          alignment = Alignment.bottomCenter;
      }
      // Remove the tag from the subtitle text.
      subtitleText = subtitleText.replaceAll(tag, '');
    }

    // Compute textAlign based on horizontal alignment.
    TextAlign computedTextAlign;
    if (alignment.x < 0) {
      computedTextAlign = TextAlign.left;
    } else if (alignment.x > 0) {
      computedTextAlign = TextAlign.right;
    } else {
      computedTextAlign = TextAlign.center;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth, // full available width
          child: Align(
            alignment: alignment,
            child: Container(
              padding: const EdgeInsets.all(8.0),
              child: CustomHtmlText(
                htmlContent: subtitleText.replaceAll('\n', '<br>'),
                textAlign: computedTextAlign,
                expanded: true,
                defaultStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  // Background paints only behind the text.
                  background: Paint()..color = const Color.fromARGB(156, 0, 0, 0),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
