import 'package:fast_app_base/common/widget/loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:webview_flutter/webview_flutter.dart';

// ignore: depend_on_referenced_packages
import 'package:webview_flutter_android/webview_flutter_android.dart';

// ignore: depend_on_referenced_packages
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class Notice extends StatefulWidget {
  const Notice({
    Key? key,
  }) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _NoticeState createState() => _NoticeState();
}

class _NoticeState extends State<Notice> {
  late final WebViewController _controller;

  double progress = 0;
  bool _isShowLoadingIndicator = true;

  @override
  void initState() {
    super.initState();
    _initializeWebViewController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadRequest(Uri.parse('https://fastcampus.co.kr/info/notices'));
    });
  }

  void _initializeWebViewController() {
    // #docregion platform_features
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller = WebViewController.fromPlatformCreationParams(params);
    // #enddocregion platform_features

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
            setState(() {
              _isShowLoadingIndicator = true;
            });
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');

            setState(() {
              _isShowLoadingIndicator = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('''
Page resource error:
  code: ${error.errorCode}
  description: ${error.description}
  errorType: ${error.errorType}
  isForMainFrame: ${error.isForMainFrame}
          ''');

            setState(() {
              _isShowLoadingIndicator = false;
            });
          },
          onNavigationRequest: _navigationDecision,
        ),
      );

    // #docregion platform_features
    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }
    // #enddocregion platform_features

    _controller = controller;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('공지사항'),
          titleTextStyle: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          leading: const BackButton(
            color: Colors.black87,
          ),
          backgroundColor: Colors.white,
          elevation: 1,
          // This drop down menu demonstrates that Flutter widgets can be shown over the web view.
        ),
        body: Stack(
          children: <Widget>[
            WebViewWidget(controller: _controller),
            if (_isShowLoadingIndicator) LoadingIndicator.small(),
          ],
        ),
      ),
    );
  }

  Future<NavigationDecision> _navigationDecision(NavigationRequest request) async {
    debugPrint('url: ${request.url}, isForMainFrame: ${request.isMainFrame}');

    /// 고객센터 바로가기
    /// 외부 브라우저로 처리
    if (request.url.startsWith('https://day1fastcampussupport.zendesk.com')) {
      launchUrlString(
        request.url,
        mode: LaunchMode.externalApplication,
      );

      return NavigationDecision.prevent;
    }

    return NavigationDecision.navigate;
  }
}
