import 'package:flutter/material.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color backgroundColor;
  final List<Widget>? actions;
  final Widget? bottom;
  final bool showBackButton;
  final Widget? customTitle;

  const StandardAppBar({
    super.key,
    required this.title,
    required this.backgroundColor,
    this.actions,
    this.bottom,
    this.showBackButton = true,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: customTitle ?? Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: backgroundColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      bottom: bottom as PreferredSizeWidget?,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom != null ? (bottom as PreferredSizeWidget).preferredSize.height : 0),
  );
}
