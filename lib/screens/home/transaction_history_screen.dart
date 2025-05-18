import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/models/transaction_model.dart';
import 'package:bernie_wallet/repositories/wallet_repository.dart';
import 'package:bernie_wallet/services/transaction_storage_service.dart';
import 'package:bernie_wallet/widgets/shared/loading_indicator.dart';
import 'package:bernie_wallet/widgets/wallet/transaction_list_item.dart';
import 'package:bernie_wallet/config/constants.dart';
import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String address;

  const TransactionHistoryScreen({Key? key, required this.address})
      : super(key: key);

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen>
    with WidgetsBindingObserver {
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isLoading = true;
  bool _isBackgroundRefreshing = false;
  String? _errorMessage;

  // Date range filtering
  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  // Filtering options
  bool _showStarredOnly = false;

  // Transaction storage service for favorites
  late TransactionStorageService _transactionStorageService;

  @override
  void initState() {
    super.initState();
    _transactionStorageService = TransactionStorageService();
    WidgetsBinding.instance.addObserver(this);

    // Set default date range to last 30 days
    _endDate = DateTime.now();
    _startDate = DateTime.now().subtract(const Duration(days: 30));

    _fetchTransactions(forceRefresh: true);

    // Start periodic background refreshes
    _setupPeriodicRefresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app comes back to foreground, refresh transactions
    if (state == AppLifecycleState.resumed) {
      _fetchTransactions(forceRefresh: true, silent: true);
    }
  }

  void _setupPeriodicRefresh() {
    // Check for new transactions every 10 seconds while on this screen
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _fetchTransactions(forceRefresh: true, silent: true);
        _setupPeriodicRefresh(); // Schedule next refresh
      }
    });
  }

  Future<void> _fetchTransactions(
      {bool forceRefresh = false, bool silent = false}) async {
    // Don't show loading indicator for silent refreshes
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      // For silent refreshes, just track we're refreshing but don't show UI indicator
      _isBackgroundRefreshing = true;
    }

    try {
      final walletRepository = context.read<WalletRepository>();
      final walletBloc = context.read<WalletBloc>();
      final isTestnet = walletBloc.state.isTestnet;

      // Force refresh the wallet balance first if requested
      if (forceRefresh && !silent) {
        walletBloc.add(RefreshBalance(forceRefresh: true));
      }

      // Fetch transactions with date range
      final transactions = await walletRepository.getTransactionHistory(
        widget.address,
        startDate: _startDate,
        endDate: _endDate,
      );

      // Apply starred status
      final enhancedTransactions =
          await _transactionStorageService.applyStarredStatus(transactions);

      if (mounted) {
        setState(() {
          _transactions = enhancedTransactions;
          _applyFilters(); // Apply any active filters
          _isLoading = false;
          _isBackgroundRefreshing = false;
        });
      }

      // Cache transactions for offline access
      await _transactionStorageService.cacheTransactions(
          widget.address, transactions);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isBackgroundRefreshing = false;
          if (!silent) {
            _errorMessage =
                "Failed to load transaction history: ${e.toString()}";
          }
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _transactions.where((tx) {
        // Apply starred filter if enabled
        if (_showStarredOnly && !tx.isStarred) {
          return false;
        }
        return true;
      }).toList();
    });
  }

  Future<void> _selectDateRange(BuildContext context) async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2019), // Algorand launch year
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: kPrimaryColor,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      // Refetch transactions with new date range
      await _fetchTransactions();
    }
  }

  // Toggle star/unstar for a transaction
  Future<void> _toggleTransactionStar(TransactionModel transaction) async {
    final bool isCurrentlyStarred = transaction.isStarred;

    // Optimistic UI update
    setState(() {
      final int index =
          _transactions.indexWhere((tx) => tx.id == transaction.id);
      if (index != -1) {
        _transactions[index] =
            transaction.copyWith(isStarred: !isCurrentlyStarred);
        _applyFilters();
      }
    });

    // Persist the change
    bool success;
    if (isCurrentlyStarred) {
      success =
          await _transactionStorageService.unstarTransaction(transaction.id);
    } else {
      success =
          await _transactionStorageService.starTransaction(transaction.id);
    }

    // If operation failed, revert the UI change
    if (!success) {
      setState(() {
        final int index =
            _transactions.indexWhere((tx) => tx.id == transaction.id);
        if (index != -1) {
          _transactions[index] =
              transaction.copyWith(isStarred: isCurrentlyStarred);
          _applyFilters();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update favorite status'),
          backgroundColor: kErrorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction History'),
        actions: [
          // Filter toggle button
          IconButton(
            icon: Icon(
              _showStarredOnly ? Icons.star : Icons.star_border,
              color: _showStarredOnly ? Colors.amber : null,
            ),
            tooltip: _showStarredOnly
                ? 'Show all transactions'
                : 'Show starred only',
            onPressed: () {
              setState(() {
                _showStarredOnly = !_showStarredOnly;
                _applyFilters();
              });
            },
          ),

          // Date range selector
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'Select date range',
            onPressed: () => _selectDateRange(context),
          ),

          // Refresh button with loading indicator
          IconButton(
            icon: _isBackgroundRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
            onPressed: _isLoading
                ? null
                : () => _fetchTransactions(forceRefresh: true),
            tooltip: 'Refresh Transactions',
          ),
        ],
      ),
      body: Column(
        children: [
          // Date range indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: kDefaultPadding,
              vertical: kSmallPadding,
            ),
            color:
                Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Date: ${_startDate != null ? _dateFormat.format(_startDate!) : 'Any'} - '
                    '${_endDate != null ? _dateFormat.format(_endDate!) : 'Any'}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (_showStarredOnly)
                  Chip(
                    label: const Text('Starred only'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _showStarredOnly = false;
                        _applyFilters();
                      });
                    },
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
              ],
            ),
          ),

          // Transaction list
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const LoadingIndicator(message: 'Loading transactions...');
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!, style: const TextStyle(color: kErrorColor)),
              const SizedBox(height: kDefaultPadding),
              ElevatedButton(
                onPressed: () => _fetchTransactions(forceRefresh: true),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final transactionsToDisplay =
        _showStarredOnly ? _filteredTransactions : _transactions;

    if (transactionsToDisplay.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _fetchTransactions(forceRefresh: true),
        child: ListView(
          // Wrap in ListView for RefreshIndicator to work
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height *
                  0.7, // Take most of the screen height
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: kDefaultPadding),
                    Text(
                      _showStarredOnly
                          ? 'No starred transactions found.'
                          : 'No transactions found for this address.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (_showStarredOnly)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showStarredOnly = false;
                            _applyFilters();
                          });
                        },
                        child: const Text('Show all transactions'),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _fetchTransactions(forceRefresh: true),
      child: ListView.separated(
        itemCount: transactionsToDisplay.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final transaction = transactionsToDisplay[index];
          return TransactionListItemWithStar(
            transaction: transaction,
            currentWalletAddress: widget.address,
            onStarToggle: () => _toggleTransactionStar(transaction),
          );
        },
      ),
    );
  }
}

// Extension of TransactionListItem with star button
class TransactionListItemWithStar extends StatelessWidget {
  final TransactionModel transaction;
  final String currentWalletAddress;
  final VoidCallback onStarToggle;

  const TransactionListItemWithStar({
    super.key,
    required this.transaction,
    required this.currentWalletAddress,
    required this.onStarToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Standard transaction list item
        TransactionListItem(
          transaction: transaction,
          currentWalletAddress: currentWalletAddress,
        ),

        // Star button positioned on the right
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: Icon(
              transaction.isStarred ? Icons.star : Icons.star_border,
              color: transaction.isStarred ? Colors.amber : Colors.grey,
              size: 20,
            ),
            onPressed: onStarToggle,
            tooltip: transaction.isStarred
                ? 'Remove from favorites'
                : 'Add to favorites',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }
}
