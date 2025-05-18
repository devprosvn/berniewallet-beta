// widgets/shared/loading_indicator.dart

import 'package:flutter/material.dart';
import 'package:bernie_wallet/config/constants.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? message;

  const LoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 3.0,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).primaryColor;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize
            .min, // So column doesn't take full screen height if not needed
        children: <Widget>[
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
            ),
          ),
          if (message != null && message!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: kDefaultPadding),
              child: Text(
                message!,
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(color: effectiveColor),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// Helper to show a full-screen loading overlay
void showLoadingOverlay(BuildContext context, {String? message}) {
  showDialog(
    context: context,
    barrierDismissible: false, // User must not dismiss it manually
    builder: (BuildContext dialogContext) {
      return PopScope(
        canPop: false, // Prevent back button from dismissing
        child: LoadingIndicator(message: message, size: 50),
      );
    },
  );
}

void hideLoadingOverlay(BuildContext context) {
  Navigator.of(context, rootNavigator: true).pop(); // Dismiss the dialog
}
