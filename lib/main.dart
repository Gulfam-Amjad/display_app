import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DisplayApp());
}

class DisplayApp extends StatelessWidget {
  const DisplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DisplayScreen(),
    );
  }
}

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen> {
  static const String _displayUrl =
      'https://smart-task-manager-tan.vercel.app/display';

  late final bool _supportsWebView;
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    _supportsWebView = !kIsWeb &&
        (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

    if (_supportsWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onNavigationRequest: (request) {
              if (request.url.startsWith(_displayUrl)) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        )
        ..loadRequest(Uri.parse(_displayUrl));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsWebView || _controller == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'This platform does not support in-app WebView for this app. '
                'Run on Android, iOS, or macOS.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: WebViewWidget(controller: _controller!),
      ),
    );
  }
}
