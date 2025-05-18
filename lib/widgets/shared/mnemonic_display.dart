// widgets/shared/mnemonic_display.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:bernie_wallet/config/constants.dart'; // For padding and styling

class MnemonicDisplay extends StatelessWidget {
  final String mnemonic;
  final List<String> _mnemonicWords;

  MnemonicDisplay({super.key, required this.mnemonic})
      : _mnemonicWords = mnemonic.trim().split(' ');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(kMediumPadding),
          decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withAlpha((0.5 * 255).round()),
              borderRadius: BorderRadius.circular(kDefaultRadius),
              border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withAlpha((0.5 * 255).round()))),
          child: GridView.builder(
            shrinkWrap: true,
            physics:
                const NeverScrollableScrollPhysics(), // Not scrollable within the column
            itemCount: _mnemonicWords.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.5, // Adjust for better text fitting
              crossAxisSpacing: kSmallPadding,
              mainAxisSpacing: kSmallPadding,
            ),
            itemBuilder: (context, index) {
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: kSmallPadding, vertical: 4),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(kDefaultRadius / 2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha((0.05 * 255).round()),
                          blurRadius: 2,
                          offset: const Offset(0, 1))
                    ]),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${index + 1}. ',
                          style: textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary)),
                      Text(_mnemonicWords[index],
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: kDefaultPadding),
        ElevatedButton.icon(
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copy Mnemonic'),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: mnemonic));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Mnemonic copied to clipboard')),
            );
          },
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: kMediumPadding)),
        ),
        const SizedBox(height: kSmallPadding),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: kSmallPadding),
          child: Text(
            'Important: Write down your recovery phrase and store it in a secure offline location. Do not share it with anyone.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }
}
