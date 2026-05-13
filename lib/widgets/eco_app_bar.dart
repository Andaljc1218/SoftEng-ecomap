import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_theme.dart';

/// Shared app bar: centered title, gradient strip, lively title typography.
/// Use [showHomeLeading] for shell tabs where there is no route to pop.
class EcoAppBar extends StatelessWidget implements PreferredSizeWidget {
  const EcoAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showHomeLeading = false,
    this.homeLocation = '/home',
    this.automaticallyImplyLeading = true,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showHomeLeading;
  final String homeLocation;
  final bool automaticallyImplyLeading;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final Widget? resolvedLeading = leading ??
        (showHomeLeading
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back to home',
                onPressed: () => context.go(homeLocation),
              )
            : null);

    return AppBar(
      centerTitle: true,
      leading: resolvedLeading,
      automaticallyImplyLeading: resolvedLeading == null && automaticallyImplyLeading,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: EcoTypography.screenTitle(context),
      ),
      actions: actions,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: EcoGradients.appBar),
      ),
      bottom: bottom,
    );
  }
}
