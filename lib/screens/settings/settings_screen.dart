// screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart';
// import 'package:bernie_wallet/config/routes.dart'; // No longer needed for kWelcomeRoute
import 'package:bernie_wallet/config/constants.dart'; // For kWelcomeRoute
import 'dart:async'; // For StreamSubscription

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          BlocBuilder<WalletBloc, WalletState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.network_check),
                title: const Text('Network'),
                subtitle: Text(state.isTestnet ? 'TestNet' : 'MainNet'),
                trailing: Switch(
                  value: state.isTestnet,
                  onChanged: (value) {
                    context.read<WalletBloc>().add(const ToggleNetwork());
                  },
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.security),
            title: const Text('Security'),
            subtitle: const Text('Manage PIN, backup phrase'),
            onTap: () {
              // TODO: Navigate to a dedicated security screen or show options
              // For now, can show a dialog with options or navigate to a new placeholder screen
              // Example: Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityManagementScreen()));
              _showSecurityOptions(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.vpn_key),
            title: const Text('Export Wallet / Show Mnemonic'),
            subtitle: const Text('View your recovery phrase'),
            onTap: () async {
              // Made async for potential PIN check
              // TODO: Add PIN protection before showing mnemonic
              // This would involve: context.read<WalletBloc>().add(VerifyPinAndThenShowMnemonic(...))
              // or showing a PIN dialog here first.
              // For simplicity, directly showing if available (NOT SECURE FOR REAL APP)

              final walletState = context.read<WalletBloc>().state;
              // Check if PIN is set and if wallet is currently PIN protected (not verified yet)
              if (walletState.isPinSet &&
                  walletState.status != WalletStatus.pinVerified) {
                _showPinVerificationDialog(context);
                return;
              }

              final mnemonic = walletState.wallet?.mnemonic;
              if (mnemonic != null && mnemonic.isNotEmpty) {
                _showMnemonicDisplay(context, mnemonic);
              } else {
                if (!context.mounted) return; // Guard for async gap
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Mnemonic not available or wallet not fully loaded.')),
                );
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About BernieWallet'), // Changed title
            subtitle: const Text('App version, licenses'), // Changed subtitle
            onTap: () {
              // TODO: Navigate to an About screen or show AboutDialog
              // Example: Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutAppScreen()));
              if (!context.mounted) return;
              showAboutDialog(
                context: context,
                applicationName: kAppName,
                applicationVersion:
                    '1.0.0 (Dev)', // Replace with actual version
                applicationLegalese:
                    '© ${DateTime.now().year} Bernie Wallet Devs',
                children: <Widget>[
                  const Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: Text('Your friendly Algorand wallet.'))
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Delete Wallet',
                style: TextStyle(color: Colors.red)),
            subtitle: const Text('Remove wallet from this device'),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Delete'),
                          content: const Text(
                              'Are you sure you want to delete your wallet? This action cannot be undone. Make sure you have backed up your recovery phrase.'),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                child: const Text('Delete',
                                    style: TextStyle(color: Colors.red)))
                          ]));
              if (confirmed == true) {
                // Guard BuildContext across async gap
                if (!context.mounted) return;
                context.read<WalletBloc>().add(const DeleteWallet());
                // Navigate to welcome screen or appropriate screen after deletion
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(kWelcomeRoute, (route) => false);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showSecurityOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext securityContext) {
        return AlertDialog(
          title: const Text('Security Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.lock),
                title: const Text('Set/Change PIN'),
                onTap: () {
                  Navigator.of(securityContext).pop(); // Close this dialog
                  _showSetPinDialog(context); // Show PIN dialog
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock_open),
                title: const Text('Clear PIN'),
                onTap: () {
                  Navigator.of(securityContext).pop();
                  // Show confirmation dialog
                  showDialog(
                    context: context,
                    builder: (confirmContext) => AlertDialog(
                      title: const Text('Clear PIN?'),
                      content: const Text(
                          'Are you sure you want to remove PIN protection?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(confirmContext).pop(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(confirmContext).pop();
                            context.read<WalletBloc>().add(const ClearPin());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PIN removed')),
                            );
                          },
                          child: const Text('Clear PIN'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(securityContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showSetPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    final confirmPinController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Set PIN'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'New PIN (4-6 digits)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Confirm PIN',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final pin = pinController.text;
                    final confirmPin = confirmPinController.text;

                    if (pin.length < 4) {
                      setState(
                          () => errorMessage = 'PIN must be at least 4 digits');
                      return;
                    }

                    if (pin != confirmPin) {
                      setState(() => errorMessage = 'PINs do not match');
                      return;
                    }

                    Navigator.of(dialogContext).pop();
                    context.read<WalletBloc>().add(SetPin(pin: pin));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PIN set successfully')),
                    );
                  },
                  child: const Text('Set PIN'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      pinController.dispose();
      confirmPinController.dispose();
    });
  }

  void _showPinVerificationDialog(BuildContext context) {
    final pinController = TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter PIN'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: pinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'PIN',
                      errorText: errorMessage,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const Text(
                    'Security Warning: Your mnemonic phrase gives full control of your wallet. Never share it with anyone.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    final pin = pinController.text;
                    if (pin.isEmpty) {
                      setState(() => errorMessage = 'Please enter your PIN');
                      return;
                    }

                    Navigator.of(dialogContext).pop();

                    // Verify PIN through BloC
                    context.read<WalletBloc>().add(VerifyPin(pin: pin));

                    // Set up a listener to respond to PIN verification result
                    late final StreamSubscription<WalletState> subscription;
                    subscription =
                        context.read<WalletBloc>().stream.listen((state) {
                      if (state.status == WalletStatus.pinVerified) {
                        subscription.cancel();
                        final mnemonic = state.wallet?.mnemonic;
                        if (mnemonic != null &&
                            mnemonic.isNotEmpty &&
                            context.mounted) {
                          _showMnemonicDisplay(context, mnemonic);
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Mnemonic not available or wallet not fully loaded.'),
                            ),
                          );
                        }
                      } else if (state.status == WalletStatus.pinProtected &&
                          state.errorMessage?.contains('Invalid PIN') == true) {
                        subscription.cancel();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid PIN'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    });
                  },
                  child: const Text('Verify'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      pinController.dispose();
    });
  }

  void _showMnemonicDisplay(BuildContext context, String mnemonic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recovery Phrase'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'IMPORTANT: Never share these words with anyone. Anyone with this phrase can steal your funds.',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: SelectableText(
                  mnemonic,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Keep this phrase in a secure location. It cannot be recovered if lost.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
