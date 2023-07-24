import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  final bool barrierDismissable;
  final bool closable;

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
      this.barrierDismissable = true,
      this.closable = true,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (blurRadius != null) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurRadius!, sigmaY: blurRadius!),
        child: _buildDialog(context),
      );
    }
    return _buildDialog(context);
  }

  Widget _buildDialog(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
            onTap: () {
              if (barrierDismissable) {
                Navigator.pop(context);
              }
            },
          ),
          SimpleDialog(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null) title!,
                if (closable)
                  IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(
                        FontAwesomeIcons.xmark,
                        color: Theme.of(context).colorScheme.onBackground,
                      ))
              ],
            ),
            titlePadding: titlePadding,
            titleTextStyle: titleTextStyle,
            children: children,
            contentPadding: contentPadding,
            backgroundColor: backgroundColor,
            elevation: elevation,
            semanticLabel: semanticLabel,
            insetPadding: insetPadding,
            clipBehavior: Clip.hardEdge,
            shape: shape,
            alignment: alignment,
          ),
        ],
      ),
    );
  }
}
