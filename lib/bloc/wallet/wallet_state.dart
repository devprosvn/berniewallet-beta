// bloc/wallet/wallet_state.dart - Wallet BLoC States

part of 'wallet_bloc.dart';

enum WalletStatus {
  initial,
  loading,
  ready,
  error,
  created,
  imported,
  pinVerified,
  pinProtected, // For PIN-protected wallet state
  transactionSent, // For transaction sent state
}

abstract class WalletState extends Equatable {
  final WalletStatus status;
  final WalletModel? wallet;
  final bool isTestnet;
  final bool isPinSet;
  final String? errorMessage;
  // Store the list of transactions in the shared state
  final List<TransactionModel> transactions;

  const WalletState({
    required this.status,
    this.wallet,
    required this.isTestnet,
    required this.isPinSet,
    this.errorMessage,
    this.transactions = const [], // Default empty list
  });

  @override
  List<Object?> get props =>
      [status, wallet, isTestnet, isPinSet, errorMessage, transactions];
}

class WalletInitial extends WalletState {
  const WalletInitial({
    bool isTestnet = true,
    required bool isPinSet,
  }) : super(
          status: WalletStatus.initial,
          isTestnet: isTestnet,
          isPinSet: isPinSet,
        );
}

class WalletLoading extends WalletState {
  const WalletLoading({
    required bool currentIsTestnet,
    required bool currentIsPinSet,
    List<TransactionModel> currentTransactions = const [],
    WalletModel? currentWallet,
  }) : super(
          status: WalletStatus.loading,
          isTestnet: currentIsTestnet,
          isPinSet: currentIsPinSet,
          transactions: currentTransactions,
          wallet: currentWallet,
        );
}

class WalletReady extends WalletState {
  const WalletReady({
    required WalletModel wallet,
    required bool isTestnet,
    required bool isPinSet,
    String? errorMessage,
    List<TransactionModel> transactions = const [],
  }) : super(
          status: WalletStatus.ready,
          wallet: wallet,
          isTestnet: isTestnet,
          isPinSet: isPinSet,
          errorMessage: errorMessage,
          transactions: transactions,
        );

  // Allow creating a copy with updated fields
  WalletReady copyWith({
    WalletModel? wallet,
    bool? isTestnet,
    bool? isPinSet,
    String? errorMessage,
    List<TransactionModel>? transactions,
  }) {
    return WalletReady(
      wallet: wallet ?? this.wallet!,
      isTestnet: isTestnet ?? this.isTestnet,
      isPinSet: isPinSet ?? this.isPinSet,
      errorMessage: errorMessage,
      transactions: transactions ?? this.transactions,
    );
  }
}

class WalletError extends WalletState {
  const WalletError({
    required String errorMessage,
    required bool isTestnet,
    required bool isPinSet,
    WalletModel? wallet,
    List<TransactionModel> transactions = const [],
  }) : super(
          status: WalletStatus.error,
          errorMessage: errorMessage,
          isTestnet: isTestnet,
          isPinSet: isPinSet,
          wallet: wallet,
          transactions: transactions,
        );
}

class WalletCreated extends WalletState {
  const WalletCreated({
    required WalletModel wallet,
    required bool isTestnet,
    required bool isPinSet,
    List<TransactionModel> transactions = const [],
  }) : super(
          status: WalletStatus.created,
          wallet: wallet,
          isTestnet: isTestnet,
          isPinSet: isPinSet,
          transactions: transactions,
        );
}

class WalletImported extends WalletState {
  const WalletImported({
    required WalletModel wallet,
    required bool isTestnet,
    required bool isPinSet,
    List<TransactionModel> transactions = const [],
  }) : super(
          status: WalletStatus.imported,
          wallet: wallet,
          isTestnet: isTestnet,
          isPinSet: isPinSet,
          transactions: transactions,
        );
}

class WalletRequiresPin extends WalletState {
  const WalletRequiresPin({
    required bool isTestnet,
    required bool isPinSet,
    required WalletModel? wallet,
    String? errorMessage,
    List<TransactionModel> transactions = const [],
  }) : super(
          status: WalletStatus.pinProtected,
          wallet: wallet,
          isTestnet: isTestnet,
          isPinSet: isPinSet,
          errorMessage: errorMessage,
          transactions: transactions,
        );
}

class WalletPinVerified extends WalletState {
  const WalletPinVerified({
    required WalletModel wallet,
    required bool isTestnet,
    required bool isPinSet,
    List<TransactionModel> transactions = const [],
  }) : super(
          status: WalletStatus.pinVerified,
          wallet: wallet,
          isTestnet: isTestnet,
          isPinSet: isPinSet,
          transactions: transactions,
        );
}

class WalletTransactionSent extends WalletState {
  const WalletTransactionSent({
    required WalletModel wallet,
    required bool isTestnet,
    required bool isPinSet,
    List<TransactionModel> transactions = const [],
  }) : super(
          status: WalletStatus.transactionSent,
          wallet: wallet,
          isTestnet: isTestnet,
          isPinSet: isPinSet,
          transactions: transactions,
        );
}
