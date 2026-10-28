import 'dart:async';

enum SessionInvalidationReason {
  loggedInFromAnotherDevice,
}

class SessionInvalidationEvent {
  const SessionInvalidationEvent({
    required this.reason,
    required this.message,
  });

  final SessionInvalidationReason reason;
  final String message;
}

class SessionInvalidationService {
  SessionInvalidationService._();

  static final SessionInvalidationService instance =
      SessionInvalidationService._();

  final StreamController<SessionInvalidationEvent> _controller =
      StreamController<SessionInvalidationEvent>.broadcast();

  Stream<SessionInvalidationEvent> get stream => _controller.stream;

  void notifyLoggedInFromAnotherDevice({String? message}) {
    _controller.add(
      SessionInvalidationEvent(
        reason: SessionInvalidationReason.loggedInFromAnotherDevice,
        message: (message ?? '').trim(),
      ),
    );
  }
}
