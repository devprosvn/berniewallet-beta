// screens/onboarding/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:bernie_wallet/config/constants.dart';
import 'package:bernie_wallet/widgets/shared/app_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to WalletBloc state to navigate away if wallet becomes available
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        if (state.status == WalletStatus.ready ||
            state.status == WalletStatus.pinVerified) {
          Navigator.of(context)
              .pushNamedAndRemoveUntil(kHomeRoute, (route) => false);
        } else if (state.status == WalletStatus.pinProtected) {
          // If a wallet exists but needs PIN, you might want to navigate to a PIN entry screen
          // Or, if WelcomeScreen is only for first-time, this case might not be hit often
          // For now, we assume PIN entry is handled on HomeScreen or a dedicated PIN screen after initial load.
          Navigator.of(context)
              .pushNamedAndRemoveUntil(kHomeRoute, (route) => false);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(kDefaultPadding * 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // App Logo (Placeholder)
                Icon(
                  Icons.account_balance_wallet, // Replace with your app logo
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(height: kDefaultPadding * 2),
                Text(
                  'Welcome to\n$kAppName',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColorDark,
                      ),
                ),
                const SizedBox(height: kDefaultPadding),
                Text(
                  'Your secure and educational Algorand wallet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
                const Spacer(), // Pushes buttons to the bottom
                AppButton(
                  text: 'Create New Wallet',
                  onPressed: () {
                    Navigator.of(context).pushNamed(kCreateWalletRoute);
                  },
                ),
                const SizedBox(height: kMediumPadding),
                AppButton(
                  text: 'Import Existing Wallet',
                  isOutlined: true,
                  onPressed: () {
                    Navigator.of(context).pushNamed(kImportWalletRoute);
                  },
                ),
                const SizedBox(
                    height: kDefaultPadding * 2), // Some spacing at the bottom
              ],
            ),
          ),
        ),
      ),
    );
  }
}
