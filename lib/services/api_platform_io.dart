import 'dart:io';

/// Native platform implementation using dart:io.
String getBaseUrl() {
  if (Platform.isAndroid) {
    return 'http://10.0.2.2:3000/api';
  }
  return 'http://localhost:3000/api';
}
