// models/transaction_model.dart - Transaction data model

import 'package:equatable/equatable.dart';
import 'dart:convert'; // For potential note decoding

enum TransactionType { payment, assetTransfer, appCall, unknown }

class TransactionModel extends Equatable {
  final String id;
  final TransactionType type;
  final String sender;
  final String receiver;
  final double amount; // In Algos for payment transactions, units for ASA
  final double fee; // In Algos
  final DateTime dateTime;
  final String? note;
  final int roundTime; // Block round time
  final String? assetId; // For asset transfers
  final Map<String, dynamic>?
      rawJson; // To store the original JSON for more details
  final bool isStarred; // New property for user-favorited transactions

  const TransactionModel({
    required this.id,
    required this.type,
    required this.sender,
    required this.receiver,
    required this.amount,
    required this.fee,
    required this.dateTime,
    this.note,
    required this.roundTime,
    this.assetId,
    this.rawJson,
    this.isStarred = false, // Default to not starred
  });

  // Helper to determine if the transaction is outgoing or incoming for a given address
  bool isOutgoing(String currentAddress) {
    return sender == currentAddress;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        sender,
        receiver,
        amount,
        fee,
        dateTime,
        note,
        roundTime,
        assetId,
        rawJson,
        isStarred, // Added to props
      ];

  // Create a copy of this transaction with modified fields
  TransactionModel copyWith({
    String? id,
    TransactionType? type,
    String? sender,
    String? receiver,
    double? amount,
    double? fee,
    DateTime? dateTime,
    String? note,
    int? roundTime,
    String? assetId,
    Map<String, dynamic>? rawJson,
    bool? isStarred,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      type: type ?? this.type,
      sender: sender ?? this.sender,
      receiver: receiver ?? this.receiver,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      dateTime: dateTime ?? this.dateTime,
      note: note ?? this.note,
      roundTime: roundTime ?? this.roundTime,
      assetId: assetId ?? this.assetId,
      rawJson: rawJson ?? this.rawJson,
      isStarred: isStarred ?? this.isStarred,
    );
  }

  // Factory constructor for creating a TransactionModel from a JSON map (e.g., from Algorand API)
  factory TransactionModel.fromJson(
      Map<String, dynamic> json, String currentAddress) {
    TransactionType txType = TransactionType.unknown;
    String actualReceiver = json['payment-transaction']?['receiver'] ?? '';
    double txAmount = 0.0;
    String? txAssetId;
    String? decodedNote;

    final String txTypeString = json['tx-type'] as String? ?? '';

    if (txTypeString == 'pay') {
      txType = TransactionType.payment;
      final paymentTx = json['payment-transaction'] as Map<String, dynamic>?;
      txAmount = ((paymentTx?['amount'] ?? 0) as num).toDouble() / 1000000.0;
      actualReceiver = paymentTx?['receiver'] as String? ?? '';
    } else if (txTypeString == 'axfer') {
      txType = TransactionType.assetTransfer;
      final assetTransferTx =
          json['asset-transfer-transaction'] as Map<String, dynamic>?;
      txAmount = ((assetTransferTx?['amount'] ?? 0) as num).toDouble();
      actualReceiver = assetTransferTx?['receiver'] as String? ?? '';
      txAssetId = (assetTransferTx?['asset-id'] as num?)?.toString();
    } else if (txTypeString == 'appl') {
      txType = TransactionType.appCall;
      // For app calls, amount and receiver might not be directly applicable in the same way.
      // The application-transaction field would have more details like app ID.
      final appTx = json['application-transaction'] as Map<String, dynamic>?;
      actualReceiver = (appTx?['application-id'] as num?)?.toString() ??
          'App Call'; // Often receiver is empty, app-id is key.
    }

    if (json['note'] != null) {
      try {
        // Attempt to decode from base64, then UTF-8
        final List<int> noteBytes = base64Decode(json['note']);
        decodedNote = utf8.decode(noteBytes, allowMalformed: true);
      } catch (e) {
        // If decoding fails, use the raw note or a placeholder
        decodedNote =
            json['note'] is String ? json['note'] : '[Note decoding error]';
      }
    }

    return TransactionModel(
      id: json['id'] as String? ?? 'N/A',
      type: txType,
      sender: json['sender'] as String? ?? '',
      receiver: actualReceiver,
      amount: txAmount,
      fee: ((json['fee'] ?? 0) as num).toDouble() / 1000000.0,
      dateTime: json['round-time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['round-time'] as int) * 1000)
          : DateTime.now(),
      note: decodedNote,
      roundTime: json['round-time'] as int? ?? 0,
      assetId: txAssetId,
      rawJson: json, // Store the full JSON
      isStarred: false, // Default to not starred
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'sender': sender,
      'receiver': receiver,
      'amount': amount,
      'fee': fee,
      'dateTime': dateTime.millisecondsSinceEpoch,
      'note': note,
      'roundTime': roundTime,
      'assetId': assetId,
      'isStarred': isStarred,
      // We don't include rawJson as it can be very large and not needed for local storage
    };
  }
}
