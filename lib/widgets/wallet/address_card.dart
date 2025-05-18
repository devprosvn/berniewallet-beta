// widgets/wallet/address_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:bernie_wallet/config/constants.dart';
import 'package:qr_flutter/qr_flutter.dart';

class AddressCard extends StatelessWidget {
  final String address;
  final String truncatedAddress;
  final VoidCallback? onCopy;
  final VoidCallback? onShowQr;

  const AddressCard({
    super.key,
    required this.address,
    required this.truncatedAddress,
    this.onCopy,
    this.onShowQr,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kDefaultRadius)),
      child: Padding(
        padding: const EdgeInsets.all(kDefaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your Wallet Address',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                // Added QR thumbnail in the header for better visibility
                InkWell(
                  onTap: () => _showQrCode(context),
                  child: Container(
                    width: 40,
                    height: 40,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(kSmallPadding),
                    ),
                    child: const Icon(Icons.qr_code_2, color: kPrimaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: kSmallPadding),
            SelectableText(
              address, // Full address is selectable
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontFamily: 'monospace'),
              maxLines: 2,
            ),
            const SizedBox(height: kMediumPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ElevatedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: kMediumPadding,
                      vertical: kSmallPadding,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kDefaultRadius),
                    ),
                  ),
                  onPressed: onCopy ??
                      () {
                        Clipboard.setData(ClipboardData(text: address));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Address copied to clipboard')),
                        );
                      },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  label: const Text('Show QR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColorLight,
                    foregroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: kMediumPadding,
                      vertical: kSmallPadding,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(kDefaultRadius),
                    ),
                  ),
                  onPressed: onShowQr ?? () => _showQrCode(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQrCode(BuildContext context) {
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No valid address to display QR code'),
          backgroundColor: kErrorColor,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext qrContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kDefaultRadius),
          ),
          child: Container(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scan QR Code',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: kMediumPadding),
                // Wrap the QR code in a container with a border
                Container(
                  padding: const EdgeInsets.all(kMediumPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(kSmallPadding),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: QrImageView(
                    data: address,
                    version: QrVersions.auto,
                    size: 220.0,
                    backgroundColor: Colors.white,
                    padding: const EdgeInsets.all(8.0),
                    // Use the logo.png file
                    embeddedImage: const AssetImage('assets/images/logo.png'),
                    embeddedImageStyle: const QrEmbeddedImageStyle(
                      size: Size(50, 50),
                    ),
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: kPrimaryColor,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    errorStateBuilder: (context, error) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: Colors.white,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error,
                                  color: kErrorColor, size: 40),
                              const SizedBox(height: kSmallPadding),
                              Text(
                                'Error: ${error.toString()}',
                                style: const TextStyle(color: kErrorColor),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: kMediumPadding),
                Text(
                  truncatedAddress,
                  style: Theme.of(qrContext).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kMediumPadding),
                Text(
                  'Scan this QR code to send ALGO to this wallet',
                  style: Theme.of(qrContext).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: kDefaultPadding),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(qrContext).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: kMediumPadding,
                          vertical: kSmallPadding,
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: address));
                        ScaffoldMessenger.of(qrContext).showSnackBar(
                          const SnackBar(
                            content: Text('Address copied to clipboard'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: kMediumPadding),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(qrContext).primaryColor,
                        side: BorderSide(
                          color: Theme.of(qrContext).primaryColor,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: kMediumPadding,
                          vertical: kSmallPadding,
                        ),
                      ),
                      onPressed: () => Navigator.of(qrContext).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
