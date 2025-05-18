// widgets/transactions/transaction_list_item.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date and number formatting
import 'package:bernie_wallet/models/transaction_model.dart';
import 'package:bernie_wallet/config/constants.dart';
import 'package:bernie_wallet/services/algorand_service.dart';
import 'package:provider/provider.dart';

class TransactionListItem extends StatelessWidget {
  final TransactionModel transaction;
  final String currentWalletAddress; // To determine if outgoing/incoming
  final VoidCallback? onTap;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.currentWalletAddress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isOutgoing = transaction.sender == currentWalletAddress;
    final DateFormat dateFormat =
        DateFormat('MMM d, yyyy hh:mm a'); // e.g., Jan 1, 2023 05:30 PM
    final NumberFormat algoFormat = NumberFormat("#,##0.000000", "en_US");

    IconData typeIconData;
    Color amountColor;
    String amountPrefix;
    String title;
    String peerAddressDisplay;

    // Determine peer address for subtitle
    if (isOutgoing) {
      peerAddressDisplay = transaction.receiver.length > 10
          ? "To: ${transaction.receiver.substring(0, 6)}...${transaction.receiver.substring(transaction.receiver.length - 4)}"
          : "To: ${transaction.receiver}";
    } else {
      peerAddressDisplay = transaction.sender.isNotEmpty &&
              transaction.sender.length > 10
          ? "From: ${transaction.sender.substring(0, 6)}...${transaction.sender.substring(transaction.sender.length - 4)}"
          : (transaction.sender.isEmpty
              ? "From: Network"
              : "From: ${transaction.sender}");
    }

    switch (transaction.type) {
      case TransactionType.payment:
        typeIconData = isOutgoing ? Icons.arrow_upward : Icons.arrow_downward;
        amountColor = isOutgoing ? Colors.redAccent : Colors.green;
        amountPrefix = isOutgoing ? '- ' : '+ ';
        title = isOutgoing ? 'Sent ALGO' : 'Received ALGO';
        if (!isOutgoing && transaction.sender.isEmpty) {
          title = 'Network Funding';
        }
        break;
      case TransactionType.assetTransfer:
        typeIconData = isOutgoing
            ? Icons.arrow_upward_outlined
            : Icons.arrow_downward_outlined;
        amountColor = isOutgoing ? Colors.orangeAccent : Colors.blueAccent;
        amountPrefix = isOutgoing ? '- ' : '+ ';
        title = isOutgoing
            ? 'Sent Asset (${transaction.assetId ?? 'N/A'})'
            : 'Received Asset (${transaction.assetId ?? 'N/A'})';
        break;
      case TransactionType.appCall:
        typeIconData = Icons.settings_applications;
        amountColor = Colors.purpleAccent;
        amountPrefix = '';
        title = 'App Call';
        break;
      default:
        typeIconData = Icons.sync_problem;
        amountColor = Colors.grey;
        amountPrefix = '';
        title = 'Unknown Transaction';
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: amountColor.withAlpha((0.1 * 255).round()),
        child: Icon(typeIconData, color: amountColor, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$peerAddressDisplay\n${dateFormat.format(transaction.dateTime)}',
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: transaction.type == TransactionType.payment ||
              transaction.type == TransactionType.assetTransfer
          ? Text(
              '$amountPrefix${algoFormat.format(transaction.amount)} ${transaction.type == TransactionType.payment ? "ALGO" : (transaction.assetId != null ? "ASA" : "")}',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: amountColor, fontWeight: FontWeight.w600),
            )
          : (transaction.fee > 0
              ? Text('Fee: ${algoFormat.format(transaction.fee)} ALGO',
                  style: Theme.of(context).textTheme.bodySmall)
              : null),
      onTap: onTap ??
          () {
            _showTransactionDetailsDialog(context);
          },
      contentPadding: const EdgeInsets.symmetric(
          horizontal: kDefaultPadding, vertical: kSmallPadding),
    );
  }

  void _showTransactionDetailsDialog(BuildContext context) {
    // This checks if the current build context is still valid / mounted.
    if (!context.mounted) return;

    final DateFormat dateFormat = DateFormat('MMM d, yyyy hh:mm a');
    final NumberFormat algoFormat = NumberFormat("#,##0.000000", "en_US");
    final bool isOutgoing = transaction.sender == currentWalletAddress;
    final Color amountColor = isOutgoing ? Colors.redAccent : Colors.green;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String detailTitle = "Transaction Details";
        List<Widget> details = [
          _buildDetailRow(dialogContext, 'ID:', transaction.id,
              selectable: true),
          _buildDetailRow(
              dialogContext, 'Date:', dateFormat.format(transaction.dateTime)),
          _buildDetailRow(dialogContext, 'Type:',
              transaction.type.toString().split('.').last.toUpperCase()),
          _buildDetailRow(
              dialogContext,
              'Sender:',
              transaction.sender.isNotEmpty
                  ? transaction.sender
                  : "Network/Genesis",
              selectable: true),
          _buildDetailRow(dialogContext, 'Receiver:',
              transaction.receiver.isNotEmpty ? transaction.receiver : "N/A",
              selectable: true),
          _buildDetailRow(dialogContext, 'Fee:',
              '${algoFormat.format(transaction.fee)} ALGO'),
          _buildDetailRow(
              dialogContext, 'Round:', transaction.roundTime.toString()),
        ];

        if (transaction.type == TransactionType.payment) {
          detailTitle = isOutgoing ? 'Payment Sent' : 'Payment Received';
          details.insert(
              5,
              _buildDetailRow(dialogContext, 'Amount:',
                  '${isOutgoing ? "-" : "+"}${algoFormat.format(transaction.amount)} ALGO',
                  valueColor: amountColor));
        } else if (transaction.type == TransactionType.assetTransfer) {
          detailTitle = isOutgoing ? 'Asset Sent' : 'Asset Received';
          details.insert(
              3,
              _buildDetailRow(dialogContext, 'Asset ID:',
                  transaction.assetId ?? 'N/A')); // Insert Asset ID earlier
          details.insert(
              6,
              _buildDetailRow(dialogContext, 'Amount:',
                  '${isOutgoing ? "-" : "+"}${transaction.amount} (units)',
                  valueColor: amountColor));
        } else if (transaction.type == TransactionType.appCall) {
          detailTitle = 'Application Call';
          // Add app-specific details if available from rawJson
          if (transaction.rawJson != null &&
              transaction.rawJson!.containsKey('application-transaction')) {
            final appTx = transaction.rawJson!['application-transaction'];
            if (appTx != null && appTx['application-id'] != null) {
              details.add(_buildDetailRow(dialogContext, 'App ID:',
                  appTx['application-id'].toString()));
            }
          }
        }

        if (transaction.note != null && transaction.note!.isNotEmpty) {
          details.add(_buildDetailRow(dialogContext, 'Note:', transaction.note!,
              selectable: true));
        }

        return AlertDialog(
          title: Text(detailTitle,
              style: Theme.of(dialogContext).textTheme.headlineSmall),
          content: SingleChildScrollView(
            child: ListBody(
              children: details,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('Explorer Link'),
              onPressed: () async {
                final algorandService =
                    Provider.of<AlgorandService>(context, listen: false);
                final explorerUrl = await algorandService.getExplorerUrl(
                    'transaction', transaction.id);

                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Explorer URL: $explorerUrl'),
                      action: SnackBarAction(
                        label: 'Copy',
                        onPressed: () {
                          // You could add a library for copying to clipboard later
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            const SnackBar(
                                content: Text('URL copied to clipboard')),
                          );
                        },
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {Color? valueColor, bool selectable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: kSmallPadding / 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2, // Adjusted flex for potentially longer labels
            child: Text(
              '$label ',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 4, // Adjusted flex for value
            child: selectable
                ? SelectableText(
                    value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: valueColor,
                        fontFamily: value.length > 40 ? 'monospace' : null),
                  ) // Use monospace for long strings like addresses/IDs
                : Text(
                    value,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: valueColor),
                  ),
          ),
        ],
      ),
    );
  }
}
