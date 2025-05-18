import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For number formatting
import 'package:bernie_wallet/config/constants.dart';

class BalanceCard extends StatelessWidget {
  final double balance; // Balance in Algos
  final bool isLoading;
  final VoidCallback? onRefresh;
  final bool isTestnet;

  const BalanceCard({
    super.key,
    required this.balance,
    this.isLoading = false,
    this.onRefresh,
    this.isTestnet = false,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat(
        "#,##0.000000", "en_US"); // Format for Algos (up to 6 decimal places)

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
              children: <Widget>[
                Text(
                  'Balance',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (onRefresh != null)
                  IconButton(
                    icon: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh, size: 24),
                    onPressed: isLoading ? null : onRefresh,
                    tooltip: 'Refresh Balance',
                  ),
              ],
            ),
            const SizedBox(height: kSmallPadding),
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.baseline, // Align text baseline
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  isLoading ? '--.--' : currencyFormat.format(balance),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: kSmallPadding),
                Text('ALGO',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Theme.of(context)
                            .primaryColor
                            .withAlpha((0.7 * 255).round()))),
              ],
            ),
            if (isTestnet)
              Padding(
                padding: const EdgeInsets.only(top: kSmallPadding),
                child: Chip(
                  label: Text('TestNet',
                      style: Theme.of(context)
                          .chipTheme
                          .labelStyle
                          ?.copyWith(color: kWarningColor)),
                  backgroundColor: kWarningColor.withAlpha((0.1 * 255).round()),
                  padding: const EdgeInsets.symmetric(
                      horizontal: kSmallPadding, vertical: 2.0),
                  visualDensity: VisualDensity.compact,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
