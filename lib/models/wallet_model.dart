// models/wallet_model.dart - Wallet data model

import 'package:equatable/equatable.dart';

class WalletModel extends Equatable {
  final String address;
  final String?
      mnemonic; // Should be null after initial creation/import for security
  final double balance; // In Algos
  final String?
      privateKey; // For signing, keep secure. Only in memory when needed.

  const WalletModel({
    required this.address,
    this.mnemonic,
    this.balance = 0.0,
    this.privateKey,
  });

  // Helper to get a truncated address for display
  String get truncatedAddress {
    if (address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return address;
  }

  @override
  List<Object?> get props => [address, mnemonic, balance, privateKey];

  WalletModel copyWith({
    String? address,
    String? mnemonic, // Be careful with this
    double? balance,
    String? privateKey, // And this
  }) {
    return WalletModel(
      address: address ?? this.address,
      mnemonic: mnemonic ??
          this.mnemonic, // Consider if mnemonic should ever be copied like this
      balance: balance ?? this.balance,
      privateKey: privateKey ?? this.privateKey, // Same for privateKey
    );
  }

  // It might be useful to have a factory constructor for JSON serialization/deserialization
  // if you plan to store the WalletModel directly (though not recommended for sensitive parts).
  // For example:
  // factory WalletModel.fromJson(Map<String, dynamic> json) => WalletModel(
  //       address: json['address'],
  //       balance: (json['balance'] as num).toDouble(),
  //       // Avoid storing mnemonic/privateKey in easily accessible JSON
  //     );
  // Map<String, dynamic> toJson() => {
  //       'address': address,
  //       'balance': balance,
  //     };
}
