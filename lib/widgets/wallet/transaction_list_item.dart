import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date and number formatting
import 'package:bernie_wallet/models/transaction_model.dart';
import 'package:bernie_wallet/config/constants.dart';
import 'package:url_launcher/url_launcher.dart'; // Added for launching URLs
import 'package:flutter_bloc/flutter_bloc.dart'; // Added for WalletBloc access
import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart'; // For WalletState

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
    // Correctly determine if transaction is outgoing based on both sender and receiver
    final bool isOutgoing = transaction.isOutgoing(currentWalletAddress);
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

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: kSmallPadding,
        vertical: kSmallPadding / 2,
      ),
      elevation: 0,
      color: isOutgoing
          ? Colors.transparent
          : Colors.green.withOpacity(0.05), // Highlight incoming transactions
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withAlpha((0.2 * 255).round()),
          child: Icon(typeIconData, color: amountColor, size: 20),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                // Mark recent incoming transactions as bold
                fontStyle: !isOutgoing &&
                        DateTime.now()
                                .difference(transaction.dateTime)
                                .inMinutes <
                            30
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: amountColor,
                      fontWeight: FontWeight.w600,
                      // Make recent incoming transactions stand out
                      fontSize: !isOutgoing &&
                              DateTime.now()
                                      .difference(transaction.dateTime)
                                      .inMinutes <
                                  30
                          ? 16
                          : null,
                    ),
              )
            : (transaction.fee > 0
                ? Text('Fee: ${algoFormat.format(transaction.fee)} ALGO',
                    style: Theme.of(context).textTheme.bodySmall)
                : null),
        onTap: onTap ??
            () {
              _showTransactionDetailsDialog(context, transaction, isOutgoing,
                  dateFormat, algoFormat, amountColor);
            },
        contentPadding: const EdgeInsets.symmetric(
            horizontal: kDefaultPadding, vertical: kSmallPadding),
      ),
    );
  }

  void _showTransactionDetailsDialog(
      BuildContext context,
      TransactionModel tx,
      bool isOutgoing,
      DateFormat dateFormat,
      NumberFormat algoFormat,
      Color amountColor) {
    // This checks if the current build context is still valid / mounted.
    // Important if the dialog is triggered from an async operation that might complete after the widget is disposed.
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        String detailTitle = "Transaction Details";
        List<Widget> details = [
          _buildDetailRow(dialogContext, 'ID:', tx.id, selectable: true),
          _buildDetailRow(
              dialogContext, 'Date:', dateFormat.format(tx.dateTime)),
          _buildDetailRow(dialogContext, 'Type:',
              tx.type.toString().split('.').last.toUpperCase()),
          _buildDetailRow(dialogContext, 'Sender:',
              tx.sender.isNotEmpty ? tx.sender : "Network/Genesis",
              selectable: true),
          _buildDetailRow(dialogContext, 'Receiver:',
              tx.receiver.isNotEmpty ? tx.receiver : "N/A",
              selectable: true),
          _buildDetailRow(
              dialogContext, 'Fee:', '${algoFormat.format(tx.fee)} ALGO'),
          _buildDetailRow(dialogContext, 'Round:', tx.roundTime.toString()),
        ];

        if (tx.type == TransactionType.payment) {
          detailTitle = isOutgoing ? 'Payment Sent' : 'Payment Received';
          details.insert(
              5,
              _buildDetailRow(dialogContext, 'Amount:',
                  '${isOutgoing ? "-" : "+"}${algoFormat.format(tx.amount)} ALGO',
                  valueColor: amountColor));
        } else if (tx.type == TransactionType.assetTransfer) {
          detailTitle = isOutgoing ? 'Asset Sent' : 'Asset Received';
          details.insert(
              3,
              _buildDetailRow(dialogContext, 'Asset ID:',
                  tx.assetId ?? 'N/A')); // Insert Asset ID earlier
          details.insert(
              6,
              _buildDetailRow(dialogContext, 'Amount:',
                  '${isOutgoing ? "-" : "+"}${tx.amount} (units)',
                  valueColor: amountColor));
        } else if (tx.type == TransactionType.appCall) {
          detailTitle = 'Application Call';
          // Add app-specific details if available (e.g., app ID from tx.applicationId)
          if (tx.rawJson?.containsKey('application-transaction') ?? false) {
            final appTx = tx.rawJson!['application-transaction'];
            if (appTx['application-id'] != null) {
              details.add(_buildDetailRow(dialogContext, 'App ID:',
                  appTx['application-id'].toString()));
            }
          }
        }

        if (tx.note != null && tx.note!.isNotEmpty) {
          details.add(_buildDetailRow(dialogContext, 'Note:', tx.note!,
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
            // Send to this address button for Payment transactions (available only for outgoing transactions)
            if (tx.type == TransactionType.payment ||
                tx.type == TransactionType.assetTransfer)
              TextButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Send to this Address'),
                onPressed: () {
                  Navigator.of(dialogContext).pop(); // Close the dialog

                  // Navigate to Send screen with pre-filled recipient
                  Navigator.of(dialogContext).pushNamed(
                    kSendRoute,
                    arguments: {
                      'recipientAddress': isOutgoing ? tx.receiver : tx.sender,
                    },
                  );
                },
              ),
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('View on Explorer'),
              onPressed: () async {
                final bool currentIsTestnet =
                    dialogContext.read<WalletBloc>().state.isTestnet;
                final String explorerBaseUrl = currentIsTestnet
                    ? kTestNetExplorerUrl // Using constant
                    : kMainNetExplorerUrl; // Using constant

                String urlToLaunch = '';
                if (tx.id.isNotEmpty) {
                  urlToLaunch = '$explorerBaseUrl/tx/${tx.id}';
                }

                if (urlToLaunch.isNotEmpty) {
                  final Uri uriToLaunch = Uri.parse(urlToLaunch);
                  try {
                    if (await canLaunchUrl(uriToLaunch)) {
                      if (!await launchUrl(uriToLaunch,
                          mode: LaunchMode.externalApplication)) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(
                                content: Text('Could not launch $urlToLaunch')),
                          );
                        }
                      }
                    } else {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Cannot launch $urlToLaunch: Invalid URL or no handler')),
                        );
                      }
                    }
                  } catch (e) {
                    if (dialogContext.mounted) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                            content:
                                Text('Error launching URL: ${e.toString()}')),
                      );
                    }
                  }
                } else {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Explorer URL could not be determined.')),
                    );
                  }
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
            child: Text('$label ',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            flex: 4, // Adjusted flex for value
            child: selectable
                ? SelectableText(value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: valueColor,
                        fontFamily: value.length > 40
                            ? 'monospace'
                            : null)) // Use monospace for long strings like addresses/IDs
                : Text(value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: valueColor,
                        fontFamily: value.length > 40 ? 'monospace' : null)),
          ),
        ],
      ),
    );
  }
}

// Extension on TransactionModel to hold raw JSON for more details if needed
// This is an alternative to modifying TransactionModel directly if you want to keep it clean
// For now, I will add rawJson to TransactionModel itself for simplicity.
/*
extension TransactionModelRawJson on TransactionModel {
  static final _rawJsonExpando = Expando<Map<String, dynamic>>();
  Map<String, dynamic>? get rawJson => _rawJsonExpando[this];
  set rawJson(Map<String, dynamic>? value) => _rawJsonExpando[this] = value;
}
*/
