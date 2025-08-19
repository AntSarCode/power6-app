import 'package:flutter/material.dart';
import 'HUD_ui_controller.dart';

/// A single, reusable shell for every screen to prevent duplicate AppBars
/// and to keep titles, colors, and padding consistent across the app.
class AppScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;
  final Widget? bottomNavigationBar;
  final bool centerTitle;
  final EdgeInsetsGeometry? padding;

  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottom,
    this.bottomNavigationBar,
    this.centerTitle = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        actions: [
          if (actions != null) ...actions!,
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: HUD()),
          ),
        ],
        bottom: bottom,
      ),
      body: SafeArea(
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}