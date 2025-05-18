// widgets/wallet/balance_display.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:bernie_wallet/config/constants.dart'; // For styling if needed

class BalanceDisplay extends StatelessWidget {
  final double balance; // Assuming balance is in Algos
  final String currencySymbol; // e.g., "ALGO"
  final TextStyle? balanceTextStyle;
  final TextStyle? symbolTextStyle;

  const BalanceDisplay({
    super.key,
    required this.balance,
    this.currencySymbol = 'ALGO',
    this.balanceTextStyle,
    this.symbolTextStyle,
  });

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat('#,##0.000000', 'en_US'); // 6 decimal places for Algos
    final formattedBalance = formatter.format(balance);
    final defaultBalanceStyle = Theme.of(context)
        .textTheme
        .headlineMedium
        ?.copyWith(fontWeight: FontWeight.bold);
    final defaultSymbolStyle = Theme.of(context)
        .textTheme
        .titleMedium
        ?.copyWith(color: Theme.of(context).colorScheme.secondary);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Current Balance',
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: kSmallPadding / 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              formattedBalance,
              style: balanceTextStyle ?? defaultBalanceStyle,
            ),
            const SizedBox(width: kSmallPadding / 2),
            Padding(
              padding: const EdgeInsets.only(
                  bottom: 4.0), // Align with baseline of number
              child: Text(
                currencySymbol,
                style: symbolTextStyle ?? defaultSymbolStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
