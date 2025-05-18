import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bernie_wallet/config/constants.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:bernie_wallet/widgets/shared/app_button.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen>
    with WidgetsBindingObserver {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Force refresh when screen appears
    _refreshWallet(forceRefresh: true);

    // Set up a periodic refresh timer for realtime updates
    _setupPeriodicRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back from background, refresh balance
    if (state == AppLifecycleState.resumed) {
      _refreshWallet(forceRefresh: true);
    }
  }

  void _setupPeriodicRefresh() {
    // Check every 5 seconds for new transactions while on this screen
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _refreshWallet(forceRefresh: true, silent: true);
        _setupPeriodicRefresh(); // Schedule next refresh
      }
    });
  }

  void _refreshWallet({bool forceRefresh = false, bool silent = false}) {
    if (_isRefreshing && silent) return; // Don't stack silent refreshes

    setState(() {
      _isRefreshing = true;
    });

    final walletBloc = context.read<WalletBloc>();
    walletBloc
        .add(RefreshBalance(forceRefresh: forceRefresh, silentRefresh: silent));

    // Reset refreshing flag after a delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive ALGO'),
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed:
                _isRefreshing ? null : () => _refreshWallet(forceRefresh: true),
            tooltip: 'Refresh balance',
          ),
        ],
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state.wallet == null) {
            return const Center(
              child: Text('Wallet not available.'),
            );
          }

          final address = state.wallet!.address;

          return RefreshIndicator(
            onRefresh: () async {
              _refreshWallet(forceRefresh: true);
              // Give time for the refresh to complete
              await Future.delayed(const Duration(seconds: 2));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(kDefaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(kMediumPadding),
                      child: Column(
                        children: [
                          Text(
                            'Your ${state.isTestnet ? 'TestNet' : 'MainNet'} Address',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: kDefaultPadding),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(kDefaultRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(kMediumPadding),
                            child: QrImageView(
                              data: address,
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: kDefaultPadding),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: kMediumPadding,
                              vertical: kSmallPadding,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              borderRadius:
                                  BorderRadius.circular(kDefaultRadius),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    address,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontFamily: 'monospace',
                                        ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: address));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Address copied to clipboard'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  tooltip: 'Copy to clipboard',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(kMediumPadding),
                      child: Column(
                        children: [
                          Text(
                            'Current Balance',
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
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: kSmallPadding),
                          Text(
                            'Updates automatically every 5s',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Colors.grey,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: kDefaultPadding),
                    child: Text(
                      'Send only Algorand (ALGO) or Algorand Standard Assets (ASA) to this address. Sending any other cryptocurrency may result in permanent loss.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: kWarningColor),
                    ),
                  ),
                  const SizedBox(height: kDefaultPadding),
                  AppButton(
                    text: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
