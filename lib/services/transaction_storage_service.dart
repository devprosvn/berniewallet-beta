// services/transaction_storage_service.dart - Transaction management and storage
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bernie_wallet/models/transaction_model.dart';
import 'package:flutter/foundation.dart';

/// Service to manage and store transaction data, particularly user preferences like
/// starred (favorited) transactions
class TransactionStorageService {
  static const String _starredTransactionsKey = 'starred_transactions';

  /// Marks a transaction as starred/favorited
  Future<bool> starTransaction(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing starred transactions
      final List<String> starredIds = await getStarredTransactionIds();

      // Add this ID if not already present
      if (!starredIds.contains(transactionId)) {
        starredIds.add(transactionId);
        await prefs.setStringList(_starredTransactionsKey, starredIds);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starring transaction: $e');
      }
      return false;
    }
  }

  /// Removes a transaction from the starred list
  Future<bool> unstarTransaction(String transactionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing starred transactions
      final List<String> starredIds = await getStarredTransactionIds();

      // Remove this ID if present
      if (starredIds.contains(transactionId)) {
        starredIds.remove(transactionId);
        await prefs.setStringList(_starredTransactionsKey, starredIds);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error unstarring transaction: $e');
      }
      return false;
    }
  }

  /// Gets all starred transaction IDs
  Future<List<String>> getStarredTransactionIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_starredTransactionsKey) ?? [];
  }

  /// Checks if a transaction is starred
  Future<bool> isTransactionStarred(String transactionId) async {
    final List<String> starredIds = await getStarredTransactionIds();
    return starredIds.contains(transactionId);
  }

  /// Applies star status to a list of transactions based on stored preferences
  Future<List<TransactionModel>> applyStarredStatus(
      List<TransactionModel> transactions) async {
    final List<String> starredIds = await getStarredTransactionIds();

    return transactions.map((tx) {
      if (starredIds.contains(tx.id)) {
        // If this transaction is starred, create a copy with isStarred = true
        return tx.copyWith(isStarred: true);
      }
      return tx; // Otherwise return unchanged
    }).toList();
  }

  /// Stores cached transaction data for offline access
  Future<bool> cacheTransactions(
      String address, List<TransactionModel> transactions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'tx_cache_$address';

      // Convert transactions to JSON
      final List<Map<String, dynamic>> jsonList =
          transactions.map((tx) => tx.toJson()).toList();

      // Store with timestamp
      final Map<String, dynamic> cacheData = {
        'transactions': jsonList,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error caching transactions: $e');
      }
      return false;
    }
  }

  /// Retrieves cached transactions for an address, with starred status applied
  Future<List<TransactionModel>?> getCachedTransactions(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'tx_cache_$address';

      final String? cacheJson = prefs.getString(cacheKey);
      if (cacheJson == null) return null;

      final Map<String, dynamic> cacheData = jsonDecode(cacheJson);
      final int timestamp = cacheData['timestamp'];

      // Check if cache is not too old (24 hours)
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > 24 * 60 * 60 * 1000) return null;

      final List<dynamic> txJsonList = cacheData['transactions'];
      final List<TransactionModel> transactions = txJsonList.map((json) {
        // Create transaction from cached JSON
        // This is a simplified version - you'll need to properly implement this
        // based on your TransactionModel.fromJson constructor
        return TransactionModel(
          id: json['id'],
          type: TransactionType.values.firstWhere(
            (e) => e.toString() == 'TransactionType.${json['type']}',
            orElse: () => TransactionType.unknown,
          ),
          sender: json['sender'],
          receiver: json['receiver'],
          amount: json['amount'],
          fee: json['fee'],
          dateTime: DateTime.fromMillisecondsSinceEpoch(json['dateTime']),
          note: json['note'],
          roundTime: json['roundTime'],
          assetId: json['assetId'],
          isStarred: json['isStarred'] ?? false,
        );
      }).toList();

      // Apply current starred status
      return applyStarredStatus(transactions);
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving cached transactions: $e');
      }
      return null;
    }
  }

  /// Clears cached transaction data
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('tx_cache_'));

    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
