import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _DisplayScreenState extends State<DisplayScreen>
  with WidgetsBindingObserver {
  static const String _displayUrl =
      'https://smart-task-manager-tan.vercel.app/display';
  static const String _hideFullscreenControlsScript = '''
(function () {
  const matches = (value) => /full\\s*screen|fullscreen/i.test(value || '');
  const hide = (element) => {
    if (!element || !element.style) return;
    element.style.setProperty('display', 'none', 'important');
    element.style.setProperty('visibility', 'hidden', 'important');
    element.style.setProperty('pointer-events', 'none', 'important');
  };

  const scan = () => {
    document.querySelectorAll('*').forEach((element) => {
      const label = [
        element.getAttribute('aria-label'),
        element.getAttribute('title'),
        element.id,
        element.className,
        element.textContent,
      ].join(' ');

      if (matches(label)) {
        hide(element);
      }

      const style = window.getComputedStyle(element);
      if (
        (style.position === 'fixed' || style.position === 'absolute') &&
        element.getBoundingClientRect().width < 140 &&
        element.getBoundingClientRect().height < 140
      ) {
        const rect = element.getBoundingClientRect();
        const nearBottomRight =
          rect.right >= window.innerWidth - 24 &&
          rect.bottom >= window.innerHeight - 24;
        if (nearBottomRight && matches(label)) {
          hide(element);
        }
      }
    });
  };

  scan();
  new MutationObserver(scan).observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
  });
})();
''';

  late final bool _supportsWebView;
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enterFullscreenMode();
    _supportsWebView = !kIsWeb &&
        (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

    if (_supportsWebView) {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              _controller?.runJavaScript(_hideFullscreenControlsScript);
            },
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _enterFullscreenMode();
    }
  }

  Future<void> _enterFullscreenMode() async {
    if (kIsWeb) {
      return;
    }

    if (Platform.isAndroid || Platform.isIOS) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
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
      body: WebViewWidget(controller: _controller!),
    );
  }
}
