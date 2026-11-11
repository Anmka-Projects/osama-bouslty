import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/design/app_colors.dart';
import '../core/navigation/route_names.dart';

/// Tutor top tab bar — reference design: white bar, teal underline on active.
/// Tabs: الرئيسية، الطلبات، الجدول، الرسائل، حسابي.
class TutorTopNav extends StatelessWidget {
  const TutorTopNav({super.key, required this.activeTab});

  final String activeTab;

  @override
  Widget build(BuildContext context) {
    final tabs = <_TutorTab>[
      _TutorTab('home', 'الرئيسية', RouteNames.instructorHome),
      _TutorTab('requests', 'الطلبات', RouteNames.instructorRequests),
      _TutorTab('calendar', 'الجدول', RouteNames.instructorCalendar),
      _TutorTab('messages', 'الرسائل', RouteNames.instructorMessages),
      _TutorTab('account', 'حسابي', RouteNames.instructorProfile),
    ];
    return Container(
      color: AppColors.surfaceRaised,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              for (final tab in tabs)
                Expanded(child: _item(context, tab)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, _TutorTab tab) {
    final active = activeTab == tab.id;
    return GestureDetector(
      onTap: () => context.go(tab.route),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Text(
                tab.label,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight:
                      active ? FontWeight.bold : FontWeight.w500,
                  color: active
                      ? AppColors.brandTeal
                      : AppColors.inkMuted,
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: active ? 44 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.brandTeal,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(3)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorTab {
  const _TutorTab(this.id, this.label, this.route);
  final String id;
  final String label;
  final String route;
}
