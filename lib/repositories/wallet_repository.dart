// repositories/wallet_repository.dart - Repository implementation

import 'package:bernie_wallet/models/transaction_model.dart';
import 'package:bernie_wallet/models/wallet_model.dart';
import 'package:bernie_wallet/services/algorand_service.dart';
import 'package:bernie_wallet/services/storage_service.dart';
import 'package:bernie_wallet/config/constants.dart'; // For kMnemonicRegex
import 'package:flutter/foundation.dart';

class WalletRepository {
  final AlgorandService _algorandService;
  final StorageService _storageService;

  WalletRepository({
    required AlgorandService algorandService,
    required StorageService storageService,
  })  : _algorandService = algorandService,
        _storageService = storageService;

  Future<WalletModel> createWallet() async {
    final account = await _algorandService.createAccount();
    await _storageService.saveMnemonic(account.mnemonic!);
    await _storageService.saveWalletAddress(account.address);
    // Balance will be fetched on load or refresh
    return WalletModel(address: account.address, mnemonic: account.mnemonic!);
  }

  Future<WalletModel> importWallet(String mnemonic) async {
    if (!kMnemonicRegex.hasMatch(mnemonic.trim())) {
      throw ArgumentError(
          'Invalid mnemonic format. Must be 25 words separated by spaces.');
    }
    final account = await _algorandService.importAccount(mnemonic);
    await _storageService.saveMnemonic(mnemonic); // Save the imported mnemonic
    await _storageService.saveWalletAddress(account.address);
    // Balance will be fetched on load or refresh
    return WalletModel(address: account.address, mnemonic: mnemonic);
  }

  Future<WalletModel?> loadWallet() async {
    final mnemonic = await _storageService.getMnemonic();
    final address = await _storageService.getWalletAddress();

    if (mnemonic != null && address != null) {
      // Restore account in algorand_service to ensure it knows about the current wallet
      await _algorandService.importAccount(mnemonic);
      final balance = await _algorandService.getAccountBalance(address);
      return WalletModel(
          address: address,
          balance: balance /*, mnemonic can be null here for security */);
    }
    return null;
  }

  Future<void> deleteWallet() async {
    await _storageService.deleteMnemonic();
    await _storageService.deleteWalletAddress();
    // Optionally clear other wallet-related data
    _algorandService
        .clearCurrentAccount(); // Clear account from algorand_service
  }

  Future<WalletModel> refreshBalance(WalletModel currentWallet) async {
    final balance =
        await _algorandService.getAccountBalance(currentWallet.address);
    return currentWallet.copyWith(balance: balance);
  }

  Future<List<TransactionModel>> getTransactionHistory(
    String address, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = kDefaultTransactionFetchLimit,
  }) async {
    return _algorandService.getTransactionHistory(
      address,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  // PIN Management
  Future<void> setPin(String pin) async {
    // Basic PIN validation (e.g., length)
    if (pin.length < 4) throw ArgumentError('PIN must be at least 4 digits.');
    await _storageService.savePin(pin);
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await _storageService.getPin();
    return storedPin == pin;
  }

  Future<bool> hasPin() async {
    final storedPin = await _storageService.getPin();
    return storedPin != null && storedPin.isNotEmpty;
  }

  Future<void> clearPin() async {
    await _storageService.deletePin();
  }

  // Network Toggle
  Future<bool> toggleNetwork() async {
    final currentIsTestnet = _algorandService.isTestnet();
    await _algorandService.toggleNetwork();
    return !currentIsTestnet;
  }

  Future<bool> isTestnetActive() async {
    return _algorandService.isTestnet();
  }

  // Utility for sending transactions
  Future<String> sendTransaction(
      WalletModel wallet, String recipientAddress, double amount,
      {String? note}) async {
    final mnemonic = await _storageService.getMnemonic();
    if (mnemonic == null) {
      throw Exception('Wallet not loaded or mnemonic unavailable.');
    }

    // Convert amount from ALGO to microALGO (multiply by 1,000,000)
    final microAlgos = (amount * 1000000).round();

    try {
      // Send payment using algorand service - now throws exceptions rather than returning null
      final txId = await _algorandService.sendPayment(
        senderMnemonic: mnemonic,
        recipientAddress: recipientAddress,
        amount: microAlgos,
        note: note,
      );

      // This now should never be null since sendPayment will throw an exception instead
      return txId!;
    } catch (e) {
      // Log the error for debugging
      if (kDebugMode) {
        print('Error in wallet_repository.sendTransaction: ${e.toString()}');
      }
      // Re-throw the exception with clear message
      throw Exception('Failed to send transaction: ${e.toString()}');
    }
  }
}
