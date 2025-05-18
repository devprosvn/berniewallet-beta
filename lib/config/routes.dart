// config/routes.dart - Route definitions

import 'package:flutter/material.dart';
import 'package:bernie_wallet/screens/onboarding/welcome_screen.dart';
import 'package:bernie_wallet/screens/onboarding/create_wallet_screen.dart';
import 'package:bernie_wallet/screens/onboarding/import_wallet_screen.dart';
import 'package:bernie_wallet/screens/home/home_screen.dart';
import 'package:bernie_wallet/screens/home/transaction_history_screen.dart';
import 'package:bernie_wallet/screens/onboarding/splash_screen.dart';
import 'package:bernie_wallet/screens/wallet/send_screen.dart';
import 'package:bernie_wallet/screens/wallet/receive_screen.dart';
import 'constants.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case kSplashRoute:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case kWelcomeRoute:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case kCreateWalletRoute:
        return MaterialPageRoute(builder: (_) => const CreateWalletScreen());
      case kImportWalletRoute:
        return MaterialPageRoute(builder: (_) => const ImportWalletScreen());
      case kHomeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case kSendRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        String? recipientAddress;
        if (args != null && args.containsKey('recipientAddress')) {
          recipientAddress = args['recipientAddress'] as String;
        }
        return MaterialPageRoute(
          builder: (_) => SendScreen(
            initialRecipientAddress: recipientAddress,
          ),
        );
      case kReceiveRoute:
        return MaterialPageRoute(builder: (_) => const ReceiveScreen());
      case kTransactionHistoryRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        if (args != null && args.containsKey('address')) {
          return MaterialPageRoute(
            builder: (_) =>
                TransactionHistoryScreen(address: args['address'] as String),
          );
        } else {
          return _errorRoute('Missing address for TransactionHistoryScreen');
        }
      default:
        return _errorRoute('Undefined route: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      );
    });
  }
}
