import 'dart:ui';

import 'package:flutter/material.dart';

const EdgeInsets _defaultInsetPadding =
    EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0);

class ScaffoldedDialog extends StatelessWidget {
  final Widget? title;
  final EdgeInsetsGeometry titlePadding;
  final TextStyle? titleTextStyle;
  final List<Widget>? children;
  final EdgeInsetsGeometry contentPadding;
  final Color? backgroundColor;
  final double? elevation;
  final String? semanticLabel;
  final EdgeInsets insetPadding;
  final Clip clipBehavior;
  final ShapeBorder? shape;
  final AlignmentGeometry? alignment;
  final double? blurRadius;

  const ScaffoldedDialog(
      {this.title,
      this.titlePadding = const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
      this.titleTextStyle,
      this.children,
      this.contentPadding = const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 16.0),
      this.backgroundColor,
      this.elevation,
      this.semanticLabel,
      this.insetPadding = _defaultInsetPadding,
      this.clipBehavior = Clip.none,
      this.shape,
      this.alignment,
      this.blurRadius,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (blurRadius != null) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurRadius!, sigmaY: blurRadius!),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SimpleDialog(
            title: title,
            titlePadding: titlePadding,
            titleTextStyle: titleTextStyle,
            children: children,
            contentPadding: contentPadding,
            backgroundColor: backgroundColor,
            elevation: elevation,
            semanticLabel: semanticLabel,
            insetPadding: insetPadding,
            clipBehavior: clipBehavior,
            shape: shape,
            alignment: alignment,
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SimpleDialog(
        title: title,
        titlePadding: titlePadding,
        titleTextStyle: titleTextStyle,
        children: children,
        contentPadding: contentPadding,
        backgroundColor: backgroundColor,
        elevation: elevation,
        semanticLabel: semanticLabel,
        insetPadding: insetPadding,
        clipBehavior: clipBehavior,
        shape: shape,
        alignment: alignment,
      ),
    );
  }
}
