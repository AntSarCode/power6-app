import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'feedback/modal.dart';
import '../services/auth_service.dart';
import '../state/app_state.dart';

class Power6TopRightMenu extends StatelessWidget {
  final Future<void> Function(FeedbackReportPayload payload) onSubmitFeedback;
  final bool compact;

  const Power6TopRightMenu({
    super.key,
    required this.onSubmitFeedback,
    this.compact = true,
  });

  Future<void> _doLogout(BuildContext context) async {
    await AuthService().logout();
    await context.read<AppState>().logout();

    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_TopMenuAction>(
      tooltip: 'Open menu',
      color: const Color(0xFF1C1716),
      surfaceTintColor: Colors.transparent,
      elevation: 10,
      offset: const Offset(0, 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      onSelected: (action) async {
        switch (action) {
          case _TopMenuAction.feedback:
            await FeedbackReportDialog.show(
              context,
              onSubmit: onSubmitFeedback,
            );
            break;
          case _TopMenuAction.logout:
            await _doLogout(context);
            break;
        }
      },
      child: compact ? const _CompactMenuPill() : const _ExpandedMenuPill(),
      itemBuilder: (context) => const [
        PopupMenuItem<_TopMenuAction>(
          value: _TopMenuAction.feedback,
          child: _MenuRow(
            icon: Icons.bug_report_outlined,
            label: 'Send feedback',
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem<_TopMenuAction>(
          value: _TopMenuAction.logout,
          child: _MenuRow(
            icon: Icons.logout,
            label: 'Logout',
          ),
        ),
      ],
    );
  }
}

enum _TopMenuAction {
  feedback,
  logout,
}

class _CompactMenuPill extends StatelessWidget {
  const _CompactMenuPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu, color: Color(0xFFF4CDBE), size: 18),
          SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down, color: Color(0xFFF4CDBE), size: 18),
        ],
      ),
    );
  }
}

class _ExpandedMenuPill extends StatelessWidget {
  const _ExpandedMenuPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.08)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu, color: Color(0xFFF4CDBE), size: 18),
          SizedBox(width: 8),
          Text(
            'Menu',
            style: TextStyle(
              color: Color(0xFFF4CDBE),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down, color: Color(0xFFF4CDBE), size: 18),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFFF4CDBE)),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
