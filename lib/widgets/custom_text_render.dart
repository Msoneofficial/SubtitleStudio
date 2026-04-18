import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:provider/provider.dart';
import 'package:subtitle_studio/utils/snackbar_helper.dart';

import '../themes/theme_provider.dart';

class CustomHtmlText extends StatefulWidget {
  final String htmlContent;
  final int? maxLines;
  final TextAlign textAlign;
  final bool expanded;
  final TextStyle? defaultStyle;
  final bool selectable;
  final FocusNode? focusNode;

  const CustomHtmlText({
    super.key,
    required this.htmlContent,
    this.maxLines,
    this.textAlign = TextAlign.start,
    this.expanded = false,
    this.defaultStyle,
    this.selectable = false,
    this.focusNode,
  });

  @override
  State<CustomHtmlText> createState() => _CustomHtmlTextState();
}

class _CustomHtmlTextState extends State<CustomHtmlText> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  // Parses HTML into a TextSpan
  TextSpan _parseHtml(BuildContext context) {
    List<TextSpan> spans = [];
    dom.Document document = html_parser.parse(widget.htmlContent);

    void parseNode(dom.Node node, List<TextSpan> spanList, [TextStyle? parentStyle]) {
      if (node is dom.Text) {
        // Preserve any newline characters already in the text node.
        spanList.add(TextSpan(text: node.text, style: parentStyle));
      } else if (node is dom.Element) {
        // Handle <br> tag explicitly.
        if (node.localName == 'br') {
          spanList.add(TextSpan(text: '\n', style: parentStyle));
          return;
        }
        
        // Get the current style from parent or default
        TextStyle style = parentStyle ?? (widget.defaultStyle ?? const TextStyle());
        
        // Apply formatting based on the current tag
        switch (node.localName) {
          case 'b':
            style = style.merge(const TextStyle(fontWeight: FontWeight.bold));
            break;
          case 'i':
            style = style.merge(const TextStyle(fontStyle: FontStyle.italic));
            break;
          case 'u':
            style = style.merge(const TextStyle(decoration: TextDecoration.underline));
            break;
          case 'h1':
            style = style.merge(const TextStyle(fontSize: 24, fontWeight: FontWeight.bold));
            break;
          case 'a':
            String? href = node.attributes['href'];
            // Tappable link span.
            spanList.add(TextSpan(
              text: node.text,
              style: style.merge(const TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  SnackbarHelper.showInfo(context, "Clicked link: $href");
                },
            ));
            return;
          case 'font':
            String? color = node.attributes['color'];
            try {
              if (color!.startsWith('#')) {
                style = style.merge(TextStyle(color: Color(int.parse(color.substring(1), radix: 16) + 0xFF000000)));
              } else {
                style = style.merge(TextStyle(color: _colorFromName(color)));
              }
            } catch (e) {
              // Ignore invalid colors.
            }
                      break;
          // Handle span with style attribute for highlighting
          case 'span':
          case 'mark': // Also handle <mark> element for highlighting
            String? styleAttr = node.attributes['style'];
            if (styleAttr!.contains('background-color')) {
              // Extract background color
              final bgColorMatch = RegExp(r'background-color:\s*(#[0-9A-Fa-f]{6})').firstMatch(styleAttr);
              if (bgColorMatch != null) {
                final hexColor = bgColorMatch.group(1);
                if (hexColor != null) {
                  style = style.merge(TextStyle(
                    backgroundColor: Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000),
                    color: Colors.black, // Use black text on highlight
                  ));
                }
              }
            }
            break;
          // Optionally, handle <p> by adding a newline after its content.
          case 'p':
            // Parse children normally, then add a newline.
            break;
          // You can add more tag handling here.
        }
        
        List<TextSpan> children = [];
        // Pass the updated style to child nodes
        for (var child in node.nodes) {
          parseNode(child, children, style);
        }
        
        // Add newline for paragraph if needed
        if (node.localName == 'p') {
          children.add(const TextSpan(text: '\n'));
        }
        
        spanList.add(TextSpan(children: children, style: style));
      }
    }

    document.body?.nodes.forEach((node) => parseNode(node, spans));

    // Use defaultStyle if provided; otherwise fallback to theme-based default.
    TextStyle baseStyle = widget.defaultStyle ??
        TextStyle(
          color: Provider.of<ThemeProvider>(context, listen: false).themeMode == ThemeMode.light
              ? Colors.black
              : Colors.white,
          fontSize: 15,
        );
        
    return TextSpan(children: spans, style: baseStyle);
  }

  Color _colorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textSpan = _parseHtml(context);
    
    if (widget.expanded) {
      // When expanded, wrap with a SingleChildScrollView.
      return SingleChildScrollView(
        child: widget.selectable
            ? GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  // Prevent propagation but allow selection operations
                },
                child: SelectableText.rich(
                  textSpan, 
                  textAlign: widget.textAlign,
                  focusNode: _focusNode,
                  onSelectionChanged: (selection, cause) {
                    // Just track selection without storing it
                  },
                  contextMenuBuilder: (context, editableTextState) {
                    // Use default context menu builder with customized positioning
                    return AdaptiveTextSelectionToolbar.editableText(
                      editableTextState: editableTextState,
                    );
                  },
                ),
              )
            : Text.rich(textSpan, textAlign: widget.textAlign),
      );
    } else {
      return widget.selectable
          ? GestureDetector(
              onTap: () {
                // Prevent propagation to parent GestureDetector
              },
              child: SelectableText.rich(
                textSpan,
                textAlign: widget.textAlign,
                maxLines: widget.maxLines,
                focusNode: _focusNode,
                onSelectionChanged: (selection, cause) {
                  // Just track selection without storing it
                },
              ),
            )
          : Text.rich(
              textSpan,
              maxLines: widget.maxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: widget.textAlign,
            );
    }
  }
}
