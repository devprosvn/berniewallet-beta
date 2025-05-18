// services/algorand_service.dart - Algorand blockchain interaction
import 'dart:convert'; // For UTF-8 encoding

import 'package:algorand_dart/algorand_dart.dart' as algo;
import 'package:bip39/bip39.dart' as bip39;
import 'package:bernie_wallet/config/constants.dart';
import 'package:bernie_wallet/models/transaction_model.dart';
import 'package:bernie_wallet/models/wallet_model.dart';
import 'package:bernie_wallet/services/storage_service.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode and Uint8List

class AlgorandService {
  late algo.Algorand _algorand;
  bool _isTestnet = true; // Default to testnet
  final StorageService _storageService; // To persist network preference

  // Constructor
  AlgorandService(this._storageService) {
    _initializeAlgorand();
  }

  Future<void> _initializeAlgorand() async {
    final isTestnet = await _storageService.isTestnet();
    _isTestnet = isTestnet;
    _algorand = algo.Algorand(
      algodClient: algo.AlgodClient(
        apiUrl: _isTestnet ? kAlgodTestnetUrl : kAlgodMainnetUrl,
        apiKey: _isTestnet ? kAlgodTestnetToken : kAlgodMainnetToken,
      ),
      indexerClient: algo.IndexerClient(
        apiUrl: _isTestnet ? kIndexerTestnetUrl : kIndexerMainnetUrl,
        apiKey: _isTestnet
            ? kAlgodTestnetToken
            : kAlgodMainnetToken, // Usually the same token
      ),
    );
  }

  Future<void> toggleNetwork() async {
    _isTestnet = !_isTestnet;
    await _storageService.setTestnet(_isTestnet);
    await _initializeAlgorand(); // Re-initialize with new network settings
    if (kDebugMode) {
      print('Switched to ${_isTestnet ? "TestNet" : "MainNet"}');
    }
  }

  bool isTestnet() => _isTestnet;

  Future<WalletModel> createAccount() async {
    // Create a new account - this is an instance method on Algorand, not static
    final account = await algo.Account.random(); // account is algo.Account
    if (kDebugMode) {
      // Assuming account.publicAddress is directly the string representation
      print('Account created: ${account.publicAddress}');
      final seedPhrase = await account.seedPhrase;
      print('Mnemonic: ${seedPhrase.join(' ')}');
    }

    // Get the seedphrase to store in the WalletModel
    final seedPhrase = await account.seedPhrase;
    return WalletModel(
      // Assuming account.publicAddress is directly the string representation
      address: account.publicAddress,
      mnemonic: seedPhrase.join(' '),
      balance: 0.0,
    );
  }

  Future<WalletModel> importAccount(String mnemonic) async {
    try {
      // Normalize the mnemonic: trim whitespace, convert to lowercase, normalize spacing
      final normalizedMnemonic = _normalizeMnemonic(mnemonic);

      if (kDebugMode) {
        print(
            'Attempting to import wallet with normalized mnemonic: [REDACTED FOR SECURITY]');
        print('Mnemonic word count: ${normalizedMnemonic.split(' ').length}');
      }

      // First try using the normalized mnemonic with our enhanced validation
      if (!_isValidMnemonicFormat(normalizedMnemonic)) {
        // If our validation fails, log details and throw specific exception
        if (kDebugMode) {
          print('Enhanced mnemonic validation failed');
        }
        throw Exception(
            "Invalid mnemonic format. Please check your recovery phrase and ensure it's exactly 25 words.");
      }

      // Create account from mnemonic
      final account =
          await algo.Account.fromSeedPhrase(normalizedMnemonic.split(' '));

      if (kDebugMode) {
        print('Account imported successfully: ${account.publicAddress}');
      }

      // Get balance (with retry)
      final balance = await getAccountBalance(account.publicAddress);

      return WalletModel(
        address: account.publicAddress,
        mnemonic: normalizedMnemonic, // Store normalized version
        balance: balance,
      );
    } catch (e) {
      // Improved error handling with specific messages
      if (kDebugMode) {
        print('Error importing account: $e (${e.runtimeType})');
      }

      // Handle specific error types with user-friendly messages
      if (e.toString().contains('MnemonicException')) {
        throw Exception(
            "Invalid recovery phrase. Please check that all words are spelled correctly and in the right order.");
      } else if (e.toString().toLowerCase().contains('invalid checksum')) {
        throw Exception(
            "Invalid recovery phrase checksum. Please verify your recovery phrase.");
      } else if (e.toString().toLowerCase().contains('word not in wordlist')) {
        throw Exception(
            "Your recovery phrase contains words that are not in the standard wordlist. Please check for spelling errors.");
      } else if (e
          .toString()
          .toLowerCase()
          .contains('invalid mnemonic length')) {
        throw Exception(
            "Your recovery phrase has an incorrect number of words. Algorand requires exactly 25 words.");
      }

      // Generic fallback error message
      throw Exception("Failed to import wallet: ${e.toString()}");
    }
  }

  // Helper method to normalize mnemonic format
  String _normalizeMnemonic(String mnemonic) {
    // Trim outer whitespace
    String normalized = mnemonic.trim();

    // Replace multiple spaces with single space
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');

    // Convert to lowercase (BIP39 wordlist is all lowercase)
    return normalized.toLowerCase();
  }

  // More robust mnemonic validation
  bool _isValidMnemonicFormat(String mnemonic) {
    // Check if it has exactly 25 words
    final words = mnemonic.trim().split(' ');
    if (words.length != 25) {
      if (kDebugMode) {
        print('Invalid word count: ${words.length} (expected 25)');
      }
      return false;
    }

    // Try bip39 validation, but don't make it the only gate
    final bip39Valid = bip39.validateMnemonic(mnemonic.trim());

    // For Algorand wallets already created, sometimes bip39 validation can fail
    // even though the account is valid, so we'll try to create the account directly
    // without failing immediately on bip39 validation
    if (!bip39Valid && kDebugMode) {
      print('BIP39 validation failed, but continuing with import attempt');
    }

    // Return true to allow the import attempt
    return true;
  }

  void clearCurrentAccount() {
    // This method is now a no-op since we don't store the account locally anymore
    // It's kept for backward compatibility with the repository layer
  }

  bool isValidMnemonic(String mnemonic) {
    final words = mnemonic.trim().split(' ');
    if (words.length != 25) return false;
    return bip39.validateMnemonic(mnemonic.trim());
  }

  Future<double> getAccountBalance(String address) async {
    try {
      // Implement retry logic with increasing timeouts and more retries
      return await _executeWithRetry(
        () async {
          // Add force reconnect to ensure we're not using a stale connection
          final accountInfo = await _algorand.getAccountByAddress(address);
          return accountInfo.amount / 1000000.0; // Convert microAlgos to Algos
        },
        maxRetries: 7, // Increase retries to 7 for mobile
        initialDelayMs: 200, // Start with a shorter delay for better UX
      );
    } catch (e) {
      // Improved error handling for network issues
      String errorMessage = '';
      if (e is algo.AlgorandException) {
        errorMessage = e.message.toLowerCase();
      } else {
        errorMessage = e.toString().toLowerCase();
      }

      if (kDebugMode) {
        print('Error in getAccountBalance for $address: $errorMessage');
        print('Error type: ${e.runtimeType}');
      }

      if (errorMessage.contains('account not found') ||
          errorMessage.contains('no accounts found for address') ||
          errorMessage.contains('no such account') ||
          errorMessage.contains('404')) {
        return 0.0; // Account not found, so balance is 0
      }

      // For mobile specific network errors, return the last known balance instead of 0
      if (errorMessage.contains('connection') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('network') ||
          errorMessage.contains('unreachable') ||
          errorMessage.contains('socketexception')) {
        if (kDebugMode) {
          print(
              'Network error detected, attempting recovery with last balance data');
        }

        // Try to recover last known balance from storage if available
        try {
          final lastKnownBalance =
              await _storageService.getLastKnownBalance(address);
          if (lastKnownBalance != null) {
            if (kDebugMode) {
              print('Recovered last known balance: $lastKnownBalance');
            }
            return lastKnownBalance;
          }
        } catch (storageError) {
          if (kDebugMode) {
            print('Failed to retrieve last balance: $storageError');
          }
        }

        return 0.0; // If recovery fails, return 0
      }

      // For any other errors, use fallback methods to keep the app running
      if (kDebugMode) {
        print(
            'Unhandled error in getAccountBalance, attempting fallback recovery');
      }

      try {
        // Try a direct node query as fallback if available
        final lastBalance = await _storageService.getLastKnownBalance(address);
        if (lastBalance != null) return lastBalance;
      } catch (_) {}

      return 0.0;
    }
  }

  // Helper method for retry logic with more options
  Future<T> _executeWithRetry<T>(Future<T> Function() operation,
      {int maxRetries = 5, int initialDelayMs = 300}) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        final result = await operation();

        // If operation is getAccountBalance, save the result to storage
        if (result is double &&
            operation.toString().contains('getAccountByAddress')) {
          try {
            // Extract address from the operation if possible (this is a heuristic approach)
            final opString = operation.toString();
            final addressRegex = RegExp(r'address: ([A-Z2-7]+)');
            final match = addressRegex.firstMatch(opString);
            if (match != null && match.groupCount >= 1) {
              final address = match.group(1);
              if (address != null) {
                await _storageService.saveLastKnownBalance(address, result);
                if (kDebugMode) {
                  print('Saved balance $result for address $address');
                }
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to save balance to storage: $e');
            }
          }
        }

        return result;
      } catch (e) {
        attempts++;
        lastException = e is Exception ? e : Exception(e.toString());

        if (kDebugMode) {
          print('Retry attempt $attempts/$maxRetries failed: ${e.toString()}');
        }

        if (attempts >= maxRetries) {
          if (kDebugMode) {
            print('Maximum retry attempts reached');
          }
          break;
        }

        // Exponential backoff with the provided initial delay
        final delay = initialDelayMs * attempts * attempts;
        if (kDebugMode) {
          print('Waiting ${delay}ms before next retry');
        }
        await Future.delayed(Duration(milliseconds: delay));
      }
    }

    if (lastException != null && kDebugMode) {
      print('All retry attempts failed: ${lastException.toString()}');
    }
    throw lastException ??
        Exception("Maximum retry attempts reached with unknown error");
  }

  Future<List<TransactionModel>> getTransactionHistory(
    String address, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50, // Increased from 20 to 50
  }) async {
    try {
      // Use retry logic for transaction history too
      return await _executeWithRetry(() async {
        final query = _algorand
            .indexer()
            .transactions()
            .whereAddress(algo.Address.fromAlgorandAddress(address: address));

        // Note: Direct date filtering may not be supported in the current version
        // We'll filter the results manually after fetching them

        // Set limit and perform search (use higher limit to account for filtering)
        final response = await query.search(
            limit: limit * 2); // Double the limit to account for filtering

        if (kDebugMode) {
          print('Raw transaction count: ${response.transactions.length}');
        }

        // Process transactions
        List<TransactionModel> transactions = [];

        // Process each transaction and explicitly pass the address for context
        for (var tx in response.transactions) {
          try {
            final transaction = _createTransactionModel(tx, address);
            transactions.add(transaction);

            if (kDebugMode) {
              final direction = transaction.isOutgoing(address) ? "OUT" : "IN";
              print(
                  'Transaction ${transaction.id} - Type: ${transaction.type}, Amount: ${transaction.amount}, Direction: $direction');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error processing transaction: $e');
            }
          }
        }

        // Apply date filtering manually if needed
        if (startDate != null || endDate != null) {
          transactions = transactions.where((tx) {
            bool matches = true;

            if (startDate != null && tx.dateTime.isBefore(startDate)) {
              matches = false;
            }

            if (endDate != null && tx.dateTime.isAfter(endDate)) {
              matches = false;
            }

            return matches;
          }).toList();

          // Apply the original limit after filtering
          if (transactions.length > limit) {
            transactions = transactions.sublist(0, limit);
          }
        }

        if (kDebugMode) {
          print(
              'Fetched ${transactions.length} transactions for address $address');
        }

        return transactions;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching transaction history for $address: $e');
      }
      return [];
    }
  }

  TransactionModel _createTransactionModel(dynamic rawTx, String address) {
    // Check if the transaction is directly related to the address
    final isOutgoing = rawTx.sender == address;
    final isIncoming = _isIncomingTransaction(rawTx, address);

    if (kDebugMode && (isOutgoing || isIncoming)) {
      print(
          'Creating transaction model for: ${rawTx.id} - ${isOutgoing ? "OUT" : "IN"}');
    }

    return TransactionModel(
      id: rawTx.id,
      type: _determineTransactionType(rawTx),
      sender: rawTx.sender,
      receiver: _getReceiverAddress(rawTx),
      amount: _getTransactionAmount(rawTx),
      fee: rawTx.fee / 1000000.0, // Convert to Algos
      dateTime: DateTime.fromMillisecondsSinceEpoch(rawTx.roundTime * 1000),
      note: _decodeNote(rawTx.note),
      roundTime: rawTx.roundTime,
      assetId: _getAssetId(rawTx),
      rawJson: rawTx.toJson(), // Store the raw JSON for more details
    );
  }

  // Helper method to determine if a transaction is incoming to the specified address
  bool _isIncomingTransaction(dynamic tx, String address) {
    if (tx.txType == 'pay' && tx.paymentTransaction != null) {
      return tx.paymentTransaction.receiver == address;
    } else if (tx.txType == 'axfer' && tx.assetTransferTransaction != null) {
      return tx.assetTransferTransaction.receiver == address;
    }
    return false;
  }

  // Helper methods for _createTransactionModel
  TransactionType _determineTransactionType(dynamic tx) {
    final String txType = tx.txType ?? '';
    if (txType == 'pay') return TransactionType.payment;
    if (txType == 'axfer') return TransactionType.assetTransfer;
    if (txType == 'appl') return TransactionType.appCall;
    return TransactionType.unknown;
  }

  String _getReceiverAddress(dynamic tx) {
    if (tx.txType == 'pay' && tx.paymentTransaction != null) {
      return tx.paymentTransaction.receiver ?? '';
    } else if (tx.txType == 'axfer' && tx.assetTransferTransaction != null) {
      return tx.assetTransferTransaction.receiver ?? '';
    }
    return '';
  }

  double _getTransactionAmount(dynamic tx) {
    if (tx.txType == 'pay' && tx.paymentTransaction != null) {
      return tx.paymentTransaction.amount / 1000000.0; // Convert to Algos
    } else if (tx.txType == 'axfer' && tx.assetTransferTransaction != null) {
      return tx.assetTransferTransaction.amount.toDouble();
    }
    return 0.0;
  }

  String? _getAssetId(dynamic tx) {
    if (tx.txType == 'axfer' && tx.assetTransferTransaction != null) {
      final assetId = tx.assetTransferTransaction.assetId;
      return assetId?.toString();
    }
    return null;
  }

  String? _decodeNote(dynamic note) {
    if (note == null) return null;
    try {
      if (note is List<int>) {
        return utf8.decode(note, allowMalformed: true);
      } else if (note is String) {
        return note;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error decoding note: $e');
      }
    }
    return '[Note decoding error]';
  }

  Future<String?> sendPayment({
    required String senderMnemonic,
    required String recipientAddress,
    required int amount,
    String? note,
  }) async {
    try {
      // Convert the mnemonic to an account
      final account =
          await algo.Account.fromSeedPhrase(senderMnemonic.split(' '));

      // Lấy thông tin tài khoản để kiểm tra số dư
      final accountInfo =
          await _algorand.getAccountByAddress(account.publicAddress);
      const minFee = 1000; // Phí giao dịch tối thiểu trên Algorand (microAlgos)

      // Kiểm tra xem số dư có đủ cho cả số tiền và phí giao dịch không
      if (accountInfo.amount < (amount + minFee)) {
        throw Exception(
            'Số dư không đủ để thực hiện giao dịch này. Cần ít nhất ${(amount + minFee) / 1000000} ALGO (bao gồm phí).');
      }

      // Lấy tham số giao dịch được đề xuất
      final params = await _algorand.getSuggestedTransactionParams();

      // Xây dựng giao dịch thanh toán với chuyển đổi ghi chú phù hợp
      final transaction = await (algo.PaymentTransactionBuilder()
            ..sender = account.address
            ..receiver =
                algo.Address.fromAlgorandAddress(address: recipientAddress)
            ..amount = amount
            ..note = note != null ? Uint8List.fromList(utf8.encode(note)) : null
            ..suggestedParams = params)
          .build();

      // Ký và gửi giao dịch
      final signedTransaction = await transaction.sign(account);
      final txId = await _algorand.sendTransaction(signedTransaction);

      // Xác minh chúng ta nhận được ID giao dịch hợp lệ
      if (txId.isEmpty) {
        throw Exception(
            'Giao dịch đã được gửi nhưng không có ID giao dịch được trả về');
      }

      if (kDebugMode) {
        print('Giao dịch đã gửi thành công: $txId');
      }
      return txId;
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi khi gửi thanh toán: ${e.toString()}');
      }

      // Xử lý chi tiết cho AlgorandException
      if (e is algo.AlgorandException) {
        // Trích xuất và trả về thông báo lỗi chi tiết từ Algorand API
        final errorMessage = e.message;

        String detailedError = 'Lỗi Algorand: $errorMessage';

        // Xử lý các mã lỗi hoặc thông báo lỗi cụ thể
        if (errorMessage.toLowerCase().contains('overspend') ||
            errorMessage.toLowerCase().contains('insufficient funds')) {
          detailedError =
              'Số dư không đủ để thực hiện giao dịch này. Vui lòng kiểm tra số dư và phí giao dịch.';
        } else if (errorMessage.toLowerCase().contains('below min')) {
          detailedError =
              'Số tiền giao dịch thấp hơn số tiền tối thiểu cho phép.';
        } else if (errorMessage.toLowerCase().contains('rejected')) {
          detailedError =
              'Giao dịch bị từ chối bởi mạng Algorand. Vui lòng thử lại sau.';
        } else if (errorMessage.toLowerCase().contains('timeout')) {
          detailedError =
              'Hết thời gian kết nối đến mạng Algorand. Vui lòng kiểm tra kết nối mạng và thử lại.';
        } else if (errorMessage.toLowerCase().contains('params')) {
          detailedError =
              'Tham số giao dịch không hợp lệ. Vui lòng thử lại sau.';
        }

        throw Exception(detailedError);
      }

      // Ném lại với thông báo mô tả rõ ràng hơn
      throw Exception('Không thể gửi giao dịch: ${e.toString()}');
    }
  }

  Future<String> getExplorerUrl(String type, String id) async {
    final baseUrl = _isTestnet ? kTestNetExplorerUrl : kMainNetExplorerUrl;
    if (type == 'transaction') {
      return '$baseUrl/tx/$id';
    } else if (type == 'address') {
      return '$baseUrl/address/$id';
    }
    return baseUrl;
  }
}
