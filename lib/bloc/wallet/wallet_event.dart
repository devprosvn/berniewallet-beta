// bloc/wallet/wallet_event.dart - Wallet BLoC Events

part of 'wallet_bloc.dart';

abstract class WalletEvent extends Equatable {
  const WalletEvent();

  @override
  List<Object> get props => [];
}

class LoadWallet extends WalletEvent {
  const LoadWallet();
}

class CreateWallet extends WalletEvent {
  final String? pin; // Optional: if PIN is set at creation
  const CreateWallet({this.pin});

  @override
  List<Object> get props => [pin ?? ''];
}

class ImportWallet extends WalletEvent {
  final String mnemonic;
  final String? pin; // Optional: if PIN is set at import
  const ImportWallet({required this.mnemonic, this.pin});

  @override
  List<Object> get props => [mnemonic, pin ?? ''];
}

class DeleteWallet extends WalletEvent {
  const DeleteWallet();
}

class RefreshBalance extends WalletEvent {
  final bool silentRefresh;
  final bool forceRefresh;
  const RefreshBalance({this.silentRefresh = false, this.forceRefresh = false});

  @override
  List<Object> get props => [silentRefresh, forceRefresh];
}

class SetPin extends WalletEvent {
  final String pin;
  const SetPin({required this.pin});

  @override
  List<Object> get props => [pin];
}

class VerifyPin extends WalletEvent {
  final String pin;
  const VerifyPin({required this.pin});

  @override
  List<Object> get props => [pin];
}

class ClearPin extends WalletEvent {
  const ClearPin();
}

class ToggleNetwork extends WalletEvent {
  const ToggleNetwork();
}

class SendTransaction extends WalletEvent {
  final String recipientAddress;
  final double amount;
  final String? note;

  const SendTransaction({
    required this.recipientAddress,
    required this.amount,
    this.note,
  });

  @override
  List<Object> get props => [recipientAddress, amount, note ?? ''];
}
