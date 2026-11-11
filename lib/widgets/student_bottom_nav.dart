import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/design/app_colors.dart';
import '../core/navigation/route_names.dart';

/// Student bottom nav — reference design:
/// البحث | دروسي | الرسائل | حسابي (RTL), active = teal.
class StudentBottomNav extends StatelessWidget {
  const StudentBottomNav({super.key, required this.activeTab});

  final String activeTab;

  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem('search', 'البحث', Icons.search_rounded,
          RouteNames.discover),
      _NavItem('lessons', 'دروسي', Icons.calendar_month_rounded,
          RouteNames.myBookings),
      _NavItem('messages', 'الرسائل',
          Icons.chat_bubble_outline_rounded,
          RouteNames.chatConversations),
      _NavItem('account', 'حسابي', Icons.person_outline_rounded,
          RouteNames.dashboard),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandInk.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (final item in items)
                Expanded(child: _tab(context, item)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, _NavItem item) {
    final active = activeTab == item.id;
    final color =
        active ? AppColors.brandTeal : AppColors.inkMuted;
    return InkWell(
      onTap: active ? null : () => context.go(item.route),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, size: 24, color: color),
          const SizedBox(height: 3),
          Text(
            item.label,
            style: GoogleFonts.readexPro(
              fontSize: 11.5,
              fontWeight:
                  active ? FontWeight.w800 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.id, this.label, this.icon, this.route);
  final String id;
  final String label;
  final IconData icon;
  final String route;
}
