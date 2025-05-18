// screens/onboarding/import_wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bernie_wallet/config/constants.dart';
import 'package:bernie_wallet/widgets/shared/app_button.dart';
import 'package:bernie_wallet/widgets/shared/loading_indicator.dart';

class ImportWalletScreen extends StatefulWidget {
  const ImportWalletScreen({super.key});

  @override
  State<ImportWalletScreen> createState() => _ImportWalletScreenState();
}

class _ImportWalletScreenState extends State<ImportWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mnemonicController = TextEditingController();
  bool _isLoading = false;
  // bool _obscureMnemonic = true; // Optional: for obscuring mnemonic input

  // PIN fields
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _setPinIsChecked = false;
  final _pinFormKey = GlobalKey<
      FormState>(); // Separate key for PIN form if needed, or use _formKey

  @override
  void dispose() {
    _mnemonicController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    // _pinController.dispose();
    super.dispose();
  }

  void _importWallet() {
    bool mnemonicValid = _formKey.currentState!.validate();
    bool pinValid = true; // Assume true if PIN is not being set

    if (_setPinIsChecked) {
      // If _pinFormKey is used, validate it. Otherwise, ensure PIN fields are part of _formKey.
      // For simplicity, assume PIN fields will be validated by _formKey if included within it, or a separate check:
      pinValid = (_pinController.text.length >= 4 &&
          _pinController.text.length <= 6 &&
          _pinController.text == _confirmPinController.text);
      if (!pinValid && _pinController.text.isNotEmpty) {
        // Only show specific PIN error if user tried to set one
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs must match and be 4-6 digits.')),
        );
      }
    }

    if (mnemonicValid && pinValid) {
      String? pinToSet;
      if (_setPinIsChecked && _pinController.text.isNotEmpty) {
        pinToSet = _pinController.text;
      }
      context.read<WalletBloc>().add(ImportWallet(
          mnemonic: _mnemonicController.text.trim(), pin: pinToSet));
    } else if (!mnemonicValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please correct the mnemonic phrase errors.')),
      );
    }
  }

  String? _validateMnemonic(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Mnemonic phrase cannot be empty.';
    }
    // Basic validation for 25 words. More thorough validation is in the service/repository.
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.length != 25) {
      return 'Mnemonic must be exactly 25 words.';
    }
    if (!kMnemonicRegex.hasMatch(value.trim())) {
      return 'Invalid mnemonic format. Check for extra spaces or characters.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Wallet')),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state.status == WalletStatus.loading) {
            if (mounted) setState(() => _isLoading = true);
          } else {
            if (mounted) setState(() => _isLoading = false);
          }

          if (state.status == WalletStatus.imported ||
              state.status == WalletStatus.ready ||
              state.status == WalletStatus.pinVerified ||
              state.status == WalletStatus.pinProtected) {
            // Wallet imported successfully and is ready (or needs PIN which home screen will handle)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(kHomeRoute, (route) => false);
              }
            });
          } else if (state.status == WalletStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(state.errorMessage ?? 'Failed to import wallet'),
                  backgroundColor: kErrorColor),
            );
          }
        },
        builder: (context, state) {
          if (_isLoading) {
            return const LoadingIndicator(message: 'Importing your wallet...');
          }

          return Padding(
            padding: const EdgeInsets.all(kDefaultPadding * 1.5),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Enter your 25-word recovery phrase below. Separate each word with a single space.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: kDefaultPadding * 1.5),
                  TextFormField(
                    controller: _mnemonicController,
                    decoration: const InputDecoration(
                      labelText: 'Recovery Phrase (25 words)',
                      hintText: 'Word1 Word2 Word3 ... Word25',
                      border: OutlineInputBorder(),
                      // suffixIcon: IconButton(
                      //   icon: Icon(_obscureMnemonic ? Icons.visibility_off : Icons.visibility),
                      //   onPressed: () => setState(() => _obscureMnemonic = !_obscureMnemonic),
                      // ),
                    ),
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    maxLines: 3,
                    minLines: 3,
                    // obscureText: _obscureMnemonic,
                    validator: _validateMnemonic,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                  ),
                  const SizedBox(height: kDefaultPadding * 2),
                  // PIN Setup Section
                  CheckboxListTile(
                    title: const Text("Set a PIN for this wallet?"),
                    value: _setPinIsChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        _setPinIsChecked = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (_setPinIsChecked)
                    // Use a new Form key if validation is separate, or ensure fields are part of main _formKey
                    // For this example, we'll do basic inline validation in _importWallet for PIN
                    // and rely on the main form for mnemonic.
                    Column(
                      children: [
                        TextFormField(
                          controller: _pinController,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Enter 4-6 digit PIN'),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          validator: (value) {
                            // This validator will be part of the main _formKey if not using _pinFormKey
                            if (_setPinIsChecked &&
                                (value == null || value.isEmpty)) {
                              return 'PIN cannot be empty if checkbox is checked';
                            }
                            if (_setPinIsChecked &&
                                value != null &&
                                (value.length < 4 || value.length > 6)) {
                              return 'PIN must be 4-6 digits';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: kSmallPadding),
                        TextFormField(
                          controller: _confirmPinController,
                          obscureText: true,
                          decoration:
                              const InputDecoration(labelText: 'Confirm PIN'),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          validator: (value) {
                            if (_setPinIsChecked &&
                                (value == null || value.isEmpty)) {
                              return 'Please confirm your PIN if checkbox is checked';
                            }
                            if (_setPinIsChecked &&
                                value != _pinController.text) {
                              return 'PINs do not match';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: kDefaultPadding),
                  const Spacer(),
                  AppButton(
                    text: 'Import Wallet',
                    onPressed: _isLoading ? null : _importWallet,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: kDefaultPadding),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
