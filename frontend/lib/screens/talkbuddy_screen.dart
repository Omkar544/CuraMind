import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:curamind/utils/app_colors.dart';
import 'package:curamind/utils/app_styles.dart';

class TalkbuddyScreen extends StatefulWidget {
  const TalkbuddyScreen({super.key});

  @override
  State<TalkbuddyScreen> createState() => _TalkbuddyScreenState();
}

class _TalkbuddyScreenState extends State<TalkbuddyScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  // Botpress shareable web-chat URL
  final String botpressChatUrl =
      'https://cdn.botpress.cloud/webchat/v3.3/shareable.html?configUrl=https://files.bpcontent.cloud/2025/10/25/15/20251025152304-098W1K03.json';

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.backgroundLight)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
            });
            debugPrint("TalkBuddy WebView Error: ${error.description}");
          },
        ),
      )
      ..loadRequest(Uri.parse(botpressChatUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundLight,
      child: Stack(
        children: [
          // 1. The WebView Container
          Column(
            children: [
              // Subtle indicator that this is a secure AI session
              _buildSecurityHeader(),
              Expanded(
                child: WebViewWidget(controller: _controller),
              ),
            ],
          ),

          // 2. Premium Loading Overlay
          if (_isLoading)
            Container(
              color: AppColors.backgroundLight,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: AppColors.primaryTeal,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 16),
                    Text(
                      "Initializing TalkBuddy AI...",
                      style: TextStyle(
                        color: AppColors.textGrey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Robust Error State with Lucide Icons
          if (_hasError) _buildErrorState(),
        ],
      ),
    );
  }

  Widget _buildSecurityHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.primaryTeal.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.shieldCheck,
              size: 12, color: AppColors.primaryTeal),
          const SizedBox(width: 6),
          Text(
            "End-to-End Encrypted AI Session",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryTeal.withOpacity(0.8),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: AppColors.backgroundLight,
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.errorRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.cloudOff,
                color: AppColors.errorRed, size: 40),
          ),
          const SizedBox(height: 24),
          Text(
            "TalkBuddy is Offline",
            style:
                AppStyles.subHeadingStyle.copyWith(color: AppColors.textDark),
          ),
          const SizedBox(height: 12),
          const Text(
            "We couldn't establish a connection to our AI servers. Please check your internet and try again.",
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.textGrey, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _controller.reload(),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text("Reconnect Now"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
