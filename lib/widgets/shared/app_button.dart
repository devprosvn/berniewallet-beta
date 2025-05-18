// widgets/shared/app_button.dart

import 'package:flutter/material.dart';
import 'package:bernie_wallet/config/constants.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? color;
  final Color? textColor;
  final double? width;
  final double height;
  final bool isOutlined;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.color,
    this.textColor,
    this.width,
    this.height = kButtonHeight,
    this.isOutlined = false,
  });

  @override
  Widget build(BuildContext context) {
    // Use theme defaults if specific colors are not provided
    final effectiveButtonColor = color ??
        (isOutlined ? Colors.transparent : Theme.of(context).primaryColor);
    final effectiveTextColor = textColor ??
        (isOutlined ? Theme.of(context).primaryColor : Colors.white);
    final effectiveIndicatorColor =
        isOutlined ? Theme.of(context).primaryColor : Colors.white;

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            foregroundColor: effectiveTextColor,
            backgroundColor:
                effectiveButtonColor, // Usually transparent for outlined
            side: BorderSide(
                color: color ?? Theme.of(context).primaryColor, width: 1.5),
            minimumSize: Size(width ?? double.infinity, height),
            padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding, vertical: kMediumPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultRadius),
            ),
            textStyle: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: effectiveTextColor))
        : ElevatedButton.styleFrom(
            backgroundColor: effectiveButtonColor,
            foregroundColor: effectiveTextColor,
            minimumSize: Size(width ?? double.infinity, height),
            padding: const EdgeInsets.symmetric(
                horizontal: kDefaultPadding, vertical: kMediumPadding),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kDefaultRadius),
            ),
            textStyle: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: effectiveTextColor));

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              style: buttonStyle,
              onPressed: isLoading ? null : onPressed,
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            effectiveIndicatorColor),
                      ),
                    )
                  : Text(text), // Text style is now part of buttonStyle
            )
          : ElevatedButton(
              style: buttonStyle,
              onPressed: isLoading ? null : onPressed,
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            effectiveIndicatorColor),
                      ),
                    )
                  : Text(text), // Text style is now part of buttonStyle
            ),
    );
  }
}
