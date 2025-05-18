// config/constants.dart - App constants

import 'package:flutter/material.dart';

// App Information
const String kAppName = 'BernieWallet';
const String kAppVersion = '1.0.0';

// Algorand Network Configuration
const String kAlgodMainnetUrl = 'https://mainnet-api.algonode.cloud';
const String kAlgodMainnetToken =
    ''; // Typically empty or an API key if required by the provider
const String kAlgodTestnetUrl = 'https://testnet-api.algonode.cloud';
const String kAlgodTestnetToken =
    ''; // Typically empty or an API key if required by the provider

const String kIndexerMainnetUrl = 'https://mainnet-idx.algonode.cloud';
const String kIndexerTestnetUrl = 'https://testnet-idx.algonode.cloud';

// Explorer URLs
const String kMainNetExplorerUrl =
    'https://explorer.perawallet.app'; // Pera Explorer is a common choice
const String kTestNetExplorerUrl = 'https://testnet.explorer.perawallet.app';

// Storage Keys
const String kMnemonicStorageKey = 'mnemonic_key';
const String kWalletAddressStorageKey = 'wallet_address_key';
const String kPinStorageKey = 'pin_key';
const String kNetworkPreferenceStorageKey =
    'network_preference_key'; // 'mainnet' or 'testnet'

// UI Constants
const double kDefaultPadding = 16.0;
const double kMediumPadding = 12.0;
const double kSmallPadding = 8.0;
const double kDefaultRadius = 12.0;
const double kButtonHeight = 50.0;

// Colors (Consider moving to theme.dart if they become extensive)
const Color kPrimaryColor = Colors.blueAccent;
const Color kSecondaryColor = Colors.lightBlueAccent;
const Color kErrorColor = Colors.redAccent;
const Color kSuccessColor = Colors.green;
const Color kWarningColor = Colors.orangeAccent;

// Durations
const Duration kDefaultAnimationDuration = Duration(milliseconds: 300);
const Duration kShortAnimationDuration = Duration(milliseconds: 150);

// Placeholders & Default Values
const int kDefaultTransactionFetchLimit = 20;

// Regex for Mnemonic Validation (25 words)
final RegExp kMnemonicRegex = RegExp(r'^(\w+\s){24}\w+$');

// Routes (Consider moving to routes.dart if more complex)
const String kWelcomeRoute = '/welcome';
const String kCreateWalletRoute = '/create_wallet';
const String kImportWalletRoute = '/import_wallet';
const String kHomeRoute = '/home';
const String kTransactionHistoryRoute = '/transaction_history';
const String kSplashRoute = '/splash';
const String kSendRoute = '/send';
const String kReceiveRoute = '/receive';
