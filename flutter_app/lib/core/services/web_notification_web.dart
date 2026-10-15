import 'dart:js_interop';

@JS('storePulseRequestPermission')
external JSPromise<JSString>? _storePulseRequestPermission();

@JS('storePulseShowNotification')
external void _storePulseShowNotification(JSString title, JSString body);

@JS('playChaChingSound')
external void _playChaChingSound();

Future<bool> requestWebNotificationPermission() async {
  try {
    final promise = _storePulseRequestPermission();
    if (promise != null) {
      final res = await promise.toDart;
      return res.toDart == 'granted';
    }
  } catch (e) {
    // ignore
  }
  return false;
}

Future<void> showWebNotification(String title, String body) async {
  try {
    _storePulseShowNotification(title.toJS, body.toJS);
  } catch (e) {
    // ignore
  }
}

void playWebChime() {
  try {
    _playChaChingSound();
  } catch (e) {
    // ignore
  }
}
