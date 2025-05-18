// screens/onboarding/create_wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bernie_wallet/config/constants.dart';
import 'package:bernie_wallet/widgets/shared/app_button.dart';
import 'package:bernie_wallet/widgets/shared/loading_indicator.dart';

class CreateWalletScreen extends StatefulWidget {
  const CreateWalletScreen({super.key});

  @override
  State<CreateWalletScreen> createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  String? _generatedMnemonic;
  String? _walletAddress;
  bool _isLoading = false;
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _setPinIsChecked = false; // To toggle PIN fields
  final _formKey = GlobalKey<FormState>(); // For PIN validation

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  void _createNewWallet() {
    if (_setPinIsChecked) {
      if (_formKey.currentState!.validate()) {
        context.read<WalletBloc>().add(CreateWallet(pin: _pinController.text));
      } else {
        // Validation failed, do not proceed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please correct PIN errors.')),
        );
        return;
      }
    } else {
      context.read<WalletBloc>().add(const CreateWallet());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Wallet')),
      body: BlocConsumer<WalletBloc, WalletState>(
        listener: (context, state) {
          if (state.status == WalletStatus.loading) {
            if (mounted) setState(() => _isLoading = true);
          } else {
            if (mounted) setState(() => _isLoading = false);
          }

          if (state.status == WalletStatus.created ||
              state.status == WalletStatus.pinProtected) {
            // Wallet is created. Mnemonic was shown, now navigate to home or PIN screen.
            // If pinProtected, it means a PIN was set during creation and now needs verification for this session.
            // Or if no PIN was set, go to ready state. (Current logic goes to pinProtected if PIN was set, otherwise created then ready)
            if (state.wallet != null && _generatedMnemonic == null) {
              // This implies wallet was created and we missed the initial mnemonic display phase.
              // This shouldn't typically happen with the current flow, but as a fallback:
              if (mounted) {
                setState(() {
                  _walletAddress = state.wallet!.address;
                });
              }
            }
            // The crucial part is to show mnemonic *before* navigating away or after PIN setup.
            // If PIN is set at creation, Home might be next. If no PIN, show mnemonic then home.
            // For simplicity, let's assume mnemonic is displayed, then user proceeds.
            // If state becomes created or pinProtected, it means the BLoC handled it.
            // The mnemonic should be displayed *within* the BLoC's successful creation handling if it emits WalletCreated with mnemonic.
            // Or, if the service returns it, this screen shows it.
            // Let's adjust: WalletCreated state from BLoC should ideally carry the mnemonic for display.

            // If WalletCreated contains the wallet and mnemonic:
            if (state.status == WalletStatus.created &&
                state.wallet?.mnemonic != null) {
              if (mounted) {
                setState(() {
                  _generatedMnemonic = state.wallet!.mnemonic;
                  _walletAddress = state.wallet!.address;
                  _isLoading = false; // Ensure loading is off
                });
              }
            } else if (state.status == WalletStatus.ready ||
                state.status == WalletStatus.pinVerified ||
                state.status == WalletStatus.pinProtected) {
              // Wallet is set up, navigate to home
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(kHomeRoute, (route) => false);
                }
              });
            }
          } else if (state.status == WalletStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text(state.errorMessage ?? 'Failed to create wallet'),
                  backgroundColor: kErrorColor),
            );
          }
        },
        builder: (context, state) {
          if (_isLoading && _generatedMnemonic == null) {
            return const LoadingIndicator(
                message: 'Creating your secure wallet...');
          }

          if (_generatedMnemonic != null && _walletAddress != null) {
            return _buildMnemonicDisplay();
          }

          // Initial state: Button to create wallet
          return Padding(
            padding: const EdgeInsets.all(kDefaultPadding * 1.5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Icon(Icons.shield_outlined,
                    size: 60, color: kPrimaryColor),
                const SizedBox(height: kMediumPadding),
                Text(
                  'Secure Wallet Generation',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: kSmallPadding),
                const Text(
                  'We will generate a unique 25-word recovery phrase for your new Algorand wallet. Store it securely.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: kDefaultPadding * 1.5),
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
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _pinController,
                          obscureText: true,
                          decoration: const InputDecoration(
                              labelText: 'Enter 4-6 digit PIN'),
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'PIN cannot be empty';
                            }
                            if (value.length < 4 || value.length > 6) {
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
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your PIN';
                            }
                            if (value != _pinController.text) {
                              return 'PINs do not match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: kDefaultPadding),
                      ],
                    ),
                  ),
                const Spacer(),
                AppButton(
                  text: 'Generate My Wallet',
                  onPressed: _isLoading ? null : _createNewWallet,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: kDefaultPadding),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMnemonicDisplay() {
    return Padding(
      padding: const EdgeInsets.all(kDefaultPadding * 1.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Your Recovery Phrase',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor),
          ),
          const SizedBox(height: kSmallPadding),
          Text(
            'Write down these 25 words in order and keep them somewhere safe. This is the only way to recover your wallet.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey[700]),
          ),
          const SizedBox(height: kDefaultPadding),
          Container(
            padding: const EdgeInsets.all(kMediumPadding),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(kDefaultRadius),
              color: Colors.grey[50],
            ),
            child: SelectableText(
              _generatedMnemonic!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  letterSpacing: 0.8,
                  height: 1.5,
                  fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: kSmallPadding),
          Text(
            'Your Address: $_walletAddress',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12, color: Colors.grey[600], fontFamily: 'monospace'),
          ),
          const SizedBox(height: kDefaultPadding * 2),
          AppButton(
            text: 'I Have Secured My Phrase',
            onPressed: () {
              // Navigate to home or a PIN setup screen if that's the next step
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(kHomeRoute, (route) => false);
            },
          ),
        ],
      ),
    );
  }
}
