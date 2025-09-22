import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ExtraaazWebView extends StatefulWidget {
  const ExtraaazWebView({Key? key}) : super(key: key);

  @override
  State<ExtraaazWebView> createState() => _ExtraaazWebViewState();
}

class _ExtraaazWebViewState extends State<ExtraaazWebView> {
  @override
  void initState() {
    super.initState();
    // For Android, set the platform if needed
    // WebView.platform = SurfaceAndroidWebView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extraaaz')),
      body: WebViewWidget(
        controller: WebViewController()
          ..loadRequest(Uri.parse('https://extraaaz.com'))
          ..setJavaScriptMode(JavaScriptMode.unrestricted),
      ),
    );
  }
}