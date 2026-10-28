bool isLoggedInFromAnotherDeviceMessage(String message) {
  final normalized = message.toLowerCase().trim();
  if (normalized.isEmpty) return false;

  const keywords = <String>[
    'another device',
    'other device',
    'logged in from another',
    'logged in elsewhere',
    'session already active',
    'تم تسجيل الدخول من جهاز آخر',
    'تم تسجيل الدخول من جهاز اخر',
    'جهاز آخر',
    'جهاز اخر',
    'جلسة أخرى',
    'جلسة اخرى',
  ];

  return keywords.any((keyword) => normalized.contains(keyword));
}
