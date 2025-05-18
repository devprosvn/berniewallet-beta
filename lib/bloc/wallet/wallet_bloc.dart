// bloc/wallet/wallet_bloc.dart - Wallet BLoC

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:bernie_wallet/models/wallet_model.dart';
import 'package:bernie_wallet/repositories/wallet_repository.dart';
import 'package:bernie_wallet/models/transaction_model.dart'; // Added for TransactionModel
// import 'package:bernie_wallet/services/storage_service.dart'; // Unused import
import 'package:flutter/foundation.dart';

part 'wallet_event.dart';
part 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletRepository _walletRepository;

  WalletBloc({required WalletRepository walletRepository})
      : _walletRepository = walletRepository,
        super(const WalletInitial(isPinSet: false)) {
    on<LoadWallet>(_onLoadWallet);
    on<CreateWallet>(_onCreateWallet);
    on<ImportWallet>(_onImportWallet);
    on<DeleteWallet>(_onDeleteWallet);
    on<RefreshBalance>(_onRefreshBalance);
    on<SetPin>(_onSetPin);
    on<VerifyPin>(_onVerifyPin);
    on<ClearPin>(_onClearPin);
    on<ToggleNetwork>(_onToggleNetwork);
    on<SendTransaction>(
        _onSendTransaction); // Added handler for SendTransaction
  }

  Future<void> _onLoadWallet(
      LoadWallet event, Emitter<WalletState> emit) async {
    bool currentlyHasPin = false;
    try {
      currentlyHasPin = await _walletRepository.hasPin();
    } catch (_) {
      // If error checking PIN, assume false for safety, or handle error appropriately.
      // This might happen if storage is unavailable.
    }
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: currentlyHasPin));
    try {
      final isTestnet = await _walletRepository.isTestnetActive();
      final wallet = await _walletRepository.loadWallet();
      if (wallet != null) {
        // Fetch initial transactions
        final transactions =
            await _walletRepository.getTransactionHistory(wallet.address);

        final hasPin = await _walletRepository.hasPin();
        if (hasPin) {
          emit(WalletRequiresPin(
            isTestnet: isTestnet,
            wallet: wallet,
            isPinSet: true,
            transactions: transactions,
          ));
        } else {
          emit(WalletReady(
            wallet: wallet,
            isTestnet: isTestnet,
            isPinSet: false,
            transactions: transactions,
          ));
        }
      } else {
        emit(WalletInitial(isTestnet: isTestnet, isPinSet: false));
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to load wallet: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: currentlyHasPin));
    }
  }

  Future<void> _onCreateWallet(
      CreateWallet event, Emitter<WalletState> emit) async {
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: state.isPinSet));
    try {
      final wallet = await _walletRepository.createWallet();
      if (event.pin != null && event.pin!.isNotEmpty) {
        await _walletRepository.setPin(event.pin!);
      }

      final bool actualPinExists = await _walletRepository.hasPin();

      if (actualPinExists) {
        emit(WalletRequiresPin(
            isTestnet: state.isTestnet, wallet: wallet, isPinSet: true));
      } else {
        emit(WalletCreated(
            wallet: wallet, isTestnet: state.isTestnet, isPinSet: false));
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to create wallet: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: state.isPinSet));
    }
  }

  Future<void> _onImportWallet(
      ImportWallet event, Emitter<WalletState> emit) async {
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: state.isPinSet));
    try {
      final wallet = await _walletRepository.importWallet(event.mnemonic);
      if (event.pin != null && event.pin!.isNotEmpty) {
        await _walletRepository.setPin(event.pin!);
      }

      final bool actualPinExists = await _walletRepository.hasPin();

      if (actualPinExists) {
        emit(WalletRequiresPin(
            isTestnet: state.isTestnet, wallet: wallet, isPinSet: true));
      } else {
        emit(WalletImported(
            wallet: wallet, isTestnet: state.isTestnet, isPinSet: false));
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to import wallet: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: state.isPinSet));
    }
  }

  Future<void> _onDeleteWallet(
      DeleteWallet event, Emitter<WalletState> emit) async {
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: state.isPinSet));
    try {
      await _walletRepository.deleteWallet();
      await _walletRepository.clearPin();
      emit(WalletInitial(isTestnet: state.isTestnet, isPinSet: false));
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to delete wallet: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: state.isPinSet));
    }
  }

  Future<void> _onRefreshBalance(
      RefreshBalance event, Emitter<WalletState> emit) async {
    final WalletModel? currentWallet = state.wallet;
    final bool currentIsTestnet = state.isTestnet;
    final bool currentIsPinSet = state.isPinSet;
    final WalletStatus currentStatus =
        state.status; // Store current status to preserve PIN verification

    if (currentWallet == null) {
      emit(WalletError(
          errorMessage: 'Cannot refresh balance: No wallet loaded.',
          isTestnet: currentIsTestnet,
          isPinSet: currentIsPinSet));
      return;
    }

    // Only show loading if it's not a background refresh
    if (!event.silentRefresh) {
      emit(WalletLoading(
          currentIsTestnet: currentIsTestnet,
          currentIsPinSet: currentIsPinSet));
    }

    try {
      // For aggressive refreshes, we'll use a multi-attempt approach
      late WalletModel refreshedWallet; // Use late to fix the linter error
      List<TransactionModel> transactions = [];

      if (event.forceRefresh) {
        // Implement multiple attempts with delay for aggressive refresh
        int attempt = 0;
        const maxAttempts = 3;
        bool success = false;

        while (attempt < maxAttempts && !success) {
          try {
            if (kDebugMode) {
              print(
                  'Aggressive balance refresh attempt ${attempt + 1}/$maxAttempts');
            }
            refreshedWallet =
                await _walletRepository.refreshBalance(currentWallet);
            transactions = await _walletRepository
                .getTransactionHistory(refreshedWallet.address);
            success = true;
            break;
          } catch (e) {
            attempt++;
            if (kDebugMode) {
              print('Attempt $attempt failed: $e');
            }
            if (attempt < maxAttempts) {
              // Wait before retrying with increasing delays
              await Future.delayed(Duration(milliseconds: 300 * attempt));
            }
          }
        }

        if (!success) {
          // If all aggressive attempts fail, try once more with standard approach
          refreshedWallet =
              await _walletRepository.refreshBalance(currentWallet);
          transactions = await _walletRepository
              .getTransactionHistory(refreshedWallet.address);
        }
      } else {
        // Standard refresh
        refreshedWallet = await _walletRepository.refreshBalance(currentWallet);
        transactions = await _walletRepository
            .getTransactionHistory(refreshedWallet.address);
      }

      final bool appHasPin = await _walletRepository.hasPin();

      // Only show PIN dialog if user hasn't already verified PIN
      // Check both status and event flag to determine if we should prompt for PIN
      if (appHasPin &&
          currentStatus != WalletStatus.pinVerified &&
          !event.silentRefresh) {
        emit(WalletRequiresPin(
          wallet: refreshedWallet,
          isTestnet: currentIsTestnet,
          isPinSet: true,
          transactions: transactions,
        ));
      } else if (currentStatus == WalletStatus.pinVerified) {
        // Preserve pinVerified status after refresh
        emit(WalletPinVerified(
          wallet: refreshedWallet,
          isTestnet: currentIsTestnet,
          isPinSet: appHasPin,
          transactions: transactions,
        ));
      } else {
        emit(WalletReady(
          wallet: refreshedWallet,
          isTestnet: currentIsTestnet,
          isPinSet: appHasPin,
          transactions: transactions,
        ));
      }
    } catch (e) {
      // Only show error if it's not a silent refresh
      if (!event.silentRefresh) {
        emit(WalletError(
          errorMessage: 'Failed to refresh balance: ${e.toString()}',
          isTestnet: currentIsTestnet,
          isPinSet: currentIsPinSet,
        ));
      } else {
        // For silent refresh, maintain current state
        // This makes sure errors don't interrupt user experience
        if (kDebugMode) {
          print(
              'Silent refresh failed, maintaining current state: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _onSetPin(SetPin event, Emitter<WalletState> emit) async {
    final previousWallet = state.wallet;
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: state.isPinSet));
    try {
      await _walletRepository.setPin(event.pin);
      if (previousWallet != null) {
        emit(WalletReady(
            wallet: previousWallet,
            isTestnet: state.isTestnet,
            isPinSet: true));
      } else {
        emit(WalletInitial(isTestnet: state.isTestnet, isPinSet: true));
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to set PIN: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: state.isPinSet));
    }
  }

  Future<void> _onVerifyPin(VerifyPin event, Emitter<WalletState> emit) async {
    try {
      final isValidPin = await _walletRepository.verifyPin(event.pin);
      if (isValidPin) {
        if (state.wallet != null) {
          emit(WalletPinVerified(
              wallet: state.wallet!,
              isTestnet: state.isTestnet,
              isPinSet: true,
              transactions: state.transactions));
        } else {
          emit(WalletError(
              errorMessage: 'PIN verified but no wallet found.',
              isTestnet: state.isTestnet,
              isPinSet: true));
        }
      } else {
        if (state.wallet != null) {
          emit(WalletRequiresPin(
              isTestnet: state.isTestnet,
              wallet: state.wallet,
              errorMessage: 'Invalid PIN.',
              isPinSet: true,
              transactions: state.transactions));
        } else {
          emit(WalletError(
              errorMessage: 'Invalid PIN and no wallet loaded.',
              isTestnet: state.isTestnet,
              isPinSet: await _walletRepository.hasPin()));
        }
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to verify PIN: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: await _walletRepository.hasPin()));
    }
  }

  Future<void> _onClearPin(ClearPin event, Emitter<WalletState> emit) async {
    emit(WalletLoading(
        currentIsTestnet: state.isTestnet, currentIsPinSet: state.isPinSet));
    try {
      await _walletRepository.clearPin();
      if (state.wallet != null) {
        emit(WalletReady(
            wallet: state.wallet!,
            isTestnet: state.isTestnet,
            isPinSet: false));
      } else {
        emit(WalletInitial(isTestnet: state.isTestnet, isPinSet: false));
      }
    } catch (e) {
      emit(WalletError(
          errorMessage: 'Failed to clear PIN: ${e.toString()}',
          isTestnet: state.isTestnet,
          isPinSet: true));
    }
  }

  Future<void> _onToggleNetwork(
      ToggleNetwork event, Emitter<WalletState> emit) async {
    final previousWallet = state.wallet;
    final previousIsPinSet = state.isPinSet;
    final previousNetworkIsTestnet = state.isTestnet;

    // First show loading state
    emit(WalletLoading(
        currentIsTestnet: !state.isTestnet, currentIsPinSet: previousIsPinSet));

    try {
      // Toggle the network in repository
      final newNetworkIsTestnet = await _walletRepository.toggleNetwork();

      if (previousWallet != null) {
        try {
          // Try to refresh wallet balance on new network
          final WalletModel updatedWalletOnNewNetwork =
              await _walletRepository.refreshBalance(previousWallet);

          final hasPin = await _walletRepository.hasPin();

          // Fetch updated transactions for the new network
          List<TransactionModel> transactions = [];
          try {
            transactions = await _walletRepository
                .getTransactionHistory(updatedWalletOnNewNetwork.address);
          } catch (txError) {
            // Don't fail the whole network switch if just transactions failed
            if (kDebugMode) {
              print(
                  'Error fetching transactions after network switch: $txError');
            }
            // Use empty transactions list but continue
          }

          if (hasPin && state.status == WalletStatus.pinProtected) {
            emit(WalletRequiresPin(
              wallet: updatedWalletOnNewNetwork,
              isTestnet: newNetworkIsTestnet,
              isPinSet: true,
              transactions: transactions,
            ));
          } else if (hasPin &&
              (state.status == WalletStatus.ready ||
                  state.status == WalletStatus.pinVerified)) {
            emit(WalletReady(
              wallet: updatedWalletOnNewNetwork,
              isTestnet: newNetworkIsTestnet,
              isPinSet: true,
              transactions: transactions,
            ));
          } else {
            emit(WalletReady(
              wallet: updatedWalletOnNewNetwork,
              isTestnet: newNetworkIsTestnet,
              isPinSet: hasPin,
              transactions: transactions,
            ));
          }
        } catch (balanceError) {
          // If we fail to update the balance, still complete the network switch
          // but show the wallet with a 0 balance and an error message
          if (kDebugMode) {
            print('Error updating balance after network switch: $balanceError');
          }

          final hasPin = await _walletRepository.hasPin();
          // Create an updated wallet with the same address but 0 balance
          final WalletModel walletWithZeroBalance =
              previousWallet.copyWith(balance: 0);

          // Use existing WalletReady constructor but add error message
          final state = WalletReady(
            wallet: walletWithZeroBalance,
            isTestnet: newNetworkIsTestnet,
            isPinSet: hasPin,
            transactions: [], // Empty transactions since we couldn't get them
          );

          // Emit a copy of the state with added error message
          emit(state.copyWith(
              errorMessage:
                  'Network switched to ${newNetworkIsTestnet ? 'TestNet' : 'MainNet'}, but balance could not be fetched. Try refreshing.'));
        }
      } else {
        final hasPin = await _walletRepository.hasPin();
        emit(WalletInitial(isTestnet: newNetworkIsTestnet, isPinSet: hasPin));
      }
    } catch (e) {
      // Keep the previous wallet and testnet status in case of error
      if (previousWallet != null) {
        // If we had a wallet, emit WalletError with the wallet
        emit(WalletError(
          errorMessage: 'Failed to switch network: ${e.toString()}',
          isTestnet:
              previousNetworkIsTestnet, // Return to previous network setting
          isPinSet: previousIsPinSet,
        ));
      } else {
        // No wallet, so use error constructor without wallet
        emit(WalletError(
          errorMessage: 'Failed to switch network: ${e.toString()}',
          isTestnet: previousNetworkIsTestnet,
          isPinSet: previousIsPinSet,
        ));
      }
    }
  }

  Future<void> _onSendTransaction(
      SendTransaction event, Emitter<WalletState> emit) async {
    final currentWallet = state.wallet;
    final bool currentIsTestnet = state.isTestnet;
    final bool currentIsPinSet = state.isPinSet;

    if (currentWallet == null) {
      emit(WalletError(
          errorMessage: 'Không thể gửi giao dịch: Không tìm thấy ví.',
          isTestnet: currentIsTestnet,
          isPinSet: currentIsPinSet));
      return;
    }

    // Cần kiểm tra thêm 0.001 ALGO cho phí giao dịch
    const minTxFee = 0.001; // 1000 microALGOs

    // Kiểm tra số dư có đủ bao gồm phí giao dịch không
    if (event.amount + minTxFee > currentWallet.balance) {
      emit(WalletError(
        errorMessage:
            'Số dư không đủ. Cần có ít nhất ${event.amount + minTxFee} ALGO (bao gồm phí giao dịch).',
        isTestnet: currentIsTestnet,
        isPinSet: currentIsPinSet,
      ));
      return;
    }

    // Kiểm tra số tiền giao dịch (ít nhất 0.1 ALGO)
    if (event.amount < 0.1) {
      emit(WalletError(
        errorMessage: 'Số tiền giao dịch phải ít nhất 0.1 ALGO.',
        isTestnet: currentIsTestnet,
        isPinSet: currentIsPinSet,
      ));
      return;
    }

    emit(WalletLoading(
        currentIsTestnet: currentIsTestnet, currentIsPinSet: currentIsPinSet));

    try {
      // Thực hiện giao dịch
      final txId = await _walletRepository.sendTransaction(
        currentWallet,
        event.recipientAddress,
        event.amount,
        note: event.note,
      );

      if (kDebugMode) {
        print('Giao dịch hoàn tất với ID: $txId');
      }

      // Cập nhật số dư ví sau giao dịch
      final updatedWallet =
          await _walletRepository.refreshBalance(currentWallet);

      // Lấy lịch sử giao dịch đã cập nhật
      final transactions =
          await _walletRepository.getTransactionHistory(updatedWallet.address);

      // Phát trạng thái giao dịch đã gửi
      emit(WalletTransactionSent(
        wallet: updatedWallet,
        isTestnet: currentIsTestnet,
        isPinSet: currentIsPinSet,
        transactions: transactions,
      ));

      // Sau đó phát trạng thái sẵn sàng sau một khoảng thời gian
      await Future.delayed(const Duration(seconds: 2));

      emit(WalletReady(
        wallet: updatedWallet,
        isTestnet: currentIsTestnet,
        isPinSet: currentIsPinSet,
        transactions: transactions,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi trong _onSendTransaction: ${e.toString()}');
      }

      // Xử lý thông báo lỗi
      String errorMessage = e.toString();

      // Làm sạch thông báo lỗi cho người dùng
      if (errorMessage
          .contains("Exception: Failed to send transaction: Exception:")) {
        errorMessage = errorMessage.replaceAll(
            "Exception: Failed to send transaction: Exception:", "");
      } else if (errorMessage
          .contains("Exception: Failed to send transaction:")) {
        errorMessage = errorMessage.replaceAll(
            "Exception: Failed to send transaction:", "");
      } else if (errorMessage.contains("Exception:")) {
        errorMessage = errorMessage.replaceAll("Exception:", "");
      }

      errorMessage = errorMessage.trim();

      emit(WalletError(
        errorMessage: errorMessage,
        isTestnet: currentIsTestnet,
        isPinSet: currentIsPinSet,
      ));
    }
  }
}
