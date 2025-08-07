import 'package:flutter/material.dart';

/// A responsive text widget that automatically handles overflow
/// and adjusts font size based on available space
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;
  final TextAlign textAlign;
  final TextOverflow overflow;
  final bool autoResize;
  final double minFontSize;
  final double maxFontSize;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.overflow = TextOverflow.ellipsis,
    this.autoResize = false,
    this.minFontSize = 10,
    this.maxFontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (autoResize) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return _buildAutoResizeText(constraints);
        },
      );
    }

    return Text(
      text,
      style: style,
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
    );
  }

  Widget _buildAutoResizeText(BoxConstraints constraints) {
    final textStyle = style ?? const TextStyle();
    double fontSize = textStyle.fontSize ?? maxFontSize;

    // Try different font sizes until text fits
    while (fontSize >= minFontSize) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: textStyle.copyWith(fontSize: fontSize),
        ),
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: constraints.maxWidth);

      if (textPainter.didExceedMaxLines == false) {
        break;
      }

      fontSize -= 1;
    }

    return Text(
      text,
      style: textStyle.copyWith(fontSize: fontSize),
      maxLines: maxLines,
      textAlign: textAlign,
      overflow: overflow,
    );
  }
}

/// A flexible row that wraps to multiple lines when needed
class FlexibleRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final WrapAlignment wrapAlignment;
  final WrapCrossAlignment wrapCrossAlignment;
  final double spacing;
  final double runSpacing;
  final bool forceWrap;

  const FlexibleRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.wrapAlignment = WrapAlignment.start,
    this.wrapCrossAlignment = WrapCrossAlignment.center,
    this.spacing = 8.0,
    this.runSpacing = 4.0,
    this.forceWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (forceWrap) {
      return Wrap(
        alignment: wrapAlignment,
        crossAxisAlignment: wrapCrossAlignment,
        spacing: spacing,
        runSpacing: runSpacing,
        children: children,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Try to fit in a single row first
        return IntrinsicHeight(
          child: Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: children.map((child) {
              return Flexible(child: child);
            }).toList(),
          ),
        );
      },
    );
  }
}

/// A container that automatically adjusts its padding based on screen size
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double basePadding;
  final double maxPadding;
  final double minPadding;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.basePadding = 16.0,
    this.maxPadding = 24.0,
    this.minPadding = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Adjust padding based on screen width
    double padding = basePadding;
    if (screenWidth < 360) {
      padding = minPadding;
    } else if (screenWidth > 600) {
      padding = maxPadding;
    }

    return Padding(
      padding: EdgeInsets.all(padding),
      child: child,
    );
  }
}

/// Utility extension for responsive widgets
extension ResponsiveExtensions on Widget {
  /// Wraps the widget with responsive padding
  Widget withResponsivePadding({
    double basePadding = 16.0,
    double maxPadding = 24.0,
    double minPadding = 8.0,
  }) {
    return ResponsivePadding(
      basePadding: basePadding,
      maxPadding: maxPadding,
      minPadding: minPadding,
      child: this,
    );
  }

  /// Makes the widget flexible to prevent overflow
  Widget flexible({int flex = 1}) {
    return Flexible(flex: flex, child: this);
  }

  /// Makes the widget expanded to fill available space
  Widget expanded({int flex = 1}) {
    return Expanded(flex: flex, child: this);
  }
}
