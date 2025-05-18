import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bernie_wallet/config/constants.dart';
import 'package:bernie_wallet/widgets/shared/app_button.dart';

class SendScreen extends StatefulWidget {
  final String? initialRecipientAddress;

  const SendScreen({
    super.key,
    this.initialRecipientAddress,
  });

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _recipientController;
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Initialize recipient controller with initial value if provided
    _recipientController = TextEditingController(
      text: widget.initialRecipientAddress ?? '',
    );
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _scanQRCode() async {
    // In a real implementation, we would use a QR code scanner plugin
    // For example: mobile_scanner, qr_code_scanner, or flutter_barcode_scanner

    // Mock scan for demonstration
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('QR code scanning would be implemented here'),
        duration: Duration(seconds: 2),
      ),
    );

    // Sample implementation would look like:
    /*
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QRViewExample()),
      );
      if (result != null) {
        setState(() {
          _recipientController.text = result;
        });
      }
    } catch (e) {
      print('Error scanning QR code: $e');
    }
    */
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi ALGO'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: BlocListener<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state.status == WalletStatus.loading) {
            setState(() => _isLoading = true);
          } else {
            setState(() => _isLoading = false);
          }

          if (state.status == WalletStatus.error &&
              state.errorMessage != null) {
            setState(() => _errorMessage = state.errorMessage);

            // Hiển thị lỗi với giao diện tốt hơn
            showErrorSnackbar(context, state.errorMessage!);
          } else if (state.status == WalletStatus.transactionSent) {
            // Force refresh the wallet and transaction history on return to home
            final walletBloc = context.read<WalletBloc>();
            walletBloc.add(RefreshBalance(forceRefresh: true));

            // Hiển thị thông báo thành công
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Giao dịch gửi thành công!'),
                backgroundColor: kSuccessColor,
                duration: Duration(seconds: 3),
              ),
            );
            // Quay lại sau khi giao dịch thành công
            Navigator.of(context).pop();
          }
        },
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(kDefaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: kMediumPadding),
                    child: Text(
                      _errorMessage!,
                      style:
                          TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ),

                // Balance Display
                BlocBuilder<WalletBloc, WalletState>(
                  builder: (context, state) {
                    if (state.wallet != null) {
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(kDefaultRadius),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(kMediumPadding),
                          child: Column(
                            children: [
                              Text(
                                'Available Balance',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: kSmallPadding),
                              Text(
                                '${state.wallet!.balance.toStringAsFixed(6)} ALGO',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: kPrimaryColor,
                                    ),
                              ),
                              Text(
                                state.isTestnet ? 'TestNet' : 'MainNet',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return const SizedBox.shrink();
                    }
                  },
                ),

                const SizedBox(height: kDefaultPadding),

                // Recipient Address Field
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(kMediumPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recipient',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: kSmallPadding),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _recipientController,
                                decoration: const InputDecoration(
                                  labelText: 'Algorand Address',
                                  hintText: 'Enter or scan recipient address',
                                  border: OutlineInputBorder(),
                                  prefixIcon:
                                      Icon(Icons.account_balance_wallet),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a recipient address';
                                  }
                                  if (value.length != 58) {
                                    return 'Please enter a valid Algorand address (58 characters)';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: kSmallPadding),
                            ElevatedButton(
                              onPressed: _scanQRCode,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(kSmallPadding),
                                minimumSize: const Size(58, 58),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(kSmallPadding),
                                ),
                              ),
                              child: const Icon(Icons.qr_code_scanner),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: kMediumPadding),

                // Amount Field
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(kMediumPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: kSmallPadding),
                        TextFormField(
                          controller: _amountController,
                          decoration: const InputDecoration(
                            labelText: 'ALGO',
                            hintText: 'e.g., 1.5',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,6}')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter an amount';
                            }
                            final amount = double.tryParse(value);
                            if (amount == null) {
                              return 'Please enter a valid number';
                            }
                            if (amount <= 0) {
                              return 'Amount must be greater than 0';
                            }

                            // Check if amount is greater than available balance
                            final state = context.read<WalletBloc>().state;
                            if (state.wallet != null &&
                                amount > state.wallet!.balance) {
                              return 'Insufficient balance';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: kMediumPadding),

                // Note Field (Optional)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kDefaultRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(kMediumPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note (Optional)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: kSmallPadding),
                        TextFormField(
                          controller: _noteController,
                          decoration: const InputDecoration(
                            labelText: 'Message',
                            hintText: 'Add a message to this transaction',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLength: 1000, // Algorand note size limit
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: kDefaultPadding),

                // Send Button
                AppButton(
                  text: 'Send Transaction',
                  isLoading: _isLoading,
                  onPressed: _isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            // Clear previous errors
                            setState(() => _errorMessage = null);

                            final recipient = _recipientController.text.trim();
                            final amount =
                                double.parse(_amountController.text.trim());
                            final note = _noteController.text.trim();

                            // Confirmation dialog
                            _showConfirmationDialog(context, recipient, amount,
                                note.isNotEmpty ? note : null);
                          }
                        },
                ),

                const SizedBox(height: kMediumPadding),

                // Cancel Button
                AppButton(
                  text: 'Cancel',
                  isOutlined: true,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context, String recipient, double amount, String? note) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm Transaction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to send:'),
            const SizedBox(height: kSmallPadding),
            Text(
              '${amount.toStringAsFixed(6)} ALGO',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: kSmallPadding),
            Text(
                'To: ${recipient.substring(0, 8)}...${recipient.substring(recipient.length - 8)}'),
            if (note != null) ...[
              const SizedBox(height: kSmallPadding),
              Text(
                  'Note: ${note.length > 50 ? '${note.substring(0, 50)}...' : note}'),
            ],
            const SizedBox(height: kMediumPadding),
            const Text(
              'This transaction cannot be reversed after it is confirmed.',
              style: TextStyle(color: kWarningColor),
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm & Send'),
            onPressed: () {
              Navigator.of(dialogContext).pop();

              // Send transaction through BLoC
              context.read<WalletBloc>().add(
                    SendTransaction(
                      recipientAddress: recipient,
                      amount: amount,
                      note: note,
                    ),
                  );
            },
          ),
        ],
      ),
    );
  }

  // Phương thức mới để hiển thị lỗi với giao diện tốt hơn
  void showErrorSnackbar(BuildContext context, String errorMessage) {
    // Làm sạch thông báo lỗi
    String displayMessage = errorMessage.trim();

    // Hiển thị lỗi đã làm sạch
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(displayMessage)),
          ],
        ),
        backgroundColor: kErrorColor,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(
          label: 'Đóng',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}
