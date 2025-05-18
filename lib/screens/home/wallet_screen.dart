// screens/home/wallet_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bernie_wallet/widgets/wallet/balance_card.dart'; // Assuming this will be used
import 'package:bernie_wallet/widgets/wallet/address_card.dart'; // Assuming this will be used
import 'package:bernie_wallet/config/constants.dart'; // Added for route constants
import 'package:bernie_wallet/widgets/wallet/transaction_list_item.dart'; // Fixed import path for TransactionListItem
// Import other necessary widgets like action buttons, transaction list preview, etc.

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen>
    with WidgetsBindingObserver {
  String _truncateAddress(String address) {
    if (address.length <= 10) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Perform an immediate aggressive refresh when screen is created
    _refreshWallet(forceRefresh: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes to foreground, refresh balance
    if (state == AppLifecycleState.resumed) {
      _refreshWallet(forceRefresh: true);
    }
  }

  void _refreshWallet({bool forceRefresh = false}) {
    final walletBloc = context.read<WalletBloc>();
    walletBloc.add(RefreshBalance(forceRefresh: forceRefresh));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshWallet(forceRefresh: true),
            tooltip: 'Refresh balance and transactions',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshWallet(forceRefresh: true);
          // Wait a moment for the refresh to potentially complete
          await Future.delayed(const Duration(seconds: 2));
        },
        child: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            if (state.status == WalletStatus.loading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state.status == WalletStatus.error) {
              return Center(
                  child:
                      Text('Error: ${state.errorMessage ?? "Unknown error"}'));
            } else if (state.wallet != null &&
                (state.status == WalletStatus.ready ||
                    state.status == WalletStatus.created ||
                    state.status == WalletStatus.imported ||
                    state.status == WalletStatus.pinVerified)) {
              final wallet = state.wallet!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AddressCard(
                      address: wallet.address,
                      truncatedAddress: _truncateAddress(wallet.address),
                    ),
                    const SizedBox(height: 16),
                    BalanceCard(
                        balance: wallet.balance
                            .toDouble()), // Assuming balance is double
                    const SizedBox(height: 24),
                    // Send/Receive Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_upward),
                            label: const Text('Send'),
                            onPressed: () {
                              Navigator.pushNamed(context, kSendRoute);
                            },
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.arrow_downward),
                            label: const Text('Receive'),
                            onPressed: () {
                              Navigator.pushNamed(context, kReceiveRoute);
                            },
                            style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Recent Transactions Preview
                    Text(
                      'Recent Activity',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    BlocBuilder<WalletBloc, WalletState>(
                      builder: (context, state) {
                        if (state.transactions.isEmpty) {
                          return Container(
                            height: 150,
                            decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest
                                    .withAlpha(100),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Theme.of(context).dividerColor)),
                            child: const Center(
                              child: Text('No transactions yet',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          );
                        }

                        // Display the 3 most recent transactions
                        final recentTransactions =
                            state.transactions.take(3).toList();

                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withAlpha(100),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Theme.of(context).dividerColor),
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recentTransactions.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final transaction = recentTransactions[index];
                              return TransactionListItem(
                                transaction: transaction,
                                currentWalletAddress: state.wallet!.address,
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            }
            // Fallback for WalletStatus.initial or other unexpected states
            return const Center(
                child:
                    Text('Wallet is initializing or in an unexpected state.'));
          },
        ),
      ),
    );
  }
}
