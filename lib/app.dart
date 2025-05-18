// app.dart - App entry point

import 'package:bernie_wallet/bloc/wallet/wallet_bloc.dart';
import 'package:bernie_wallet/repositories/wallet_repository.dart';
import 'package:bernie_wallet/services/algorand_service.dart';
import 'package:bernie_wallet/services/storage_service.dart';
import 'package:bernie_wallet/services/transaction_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/config/routes.dart';
import 'package:bernie_wallet/config/theme.dart';
import 'package:bernie_wallet/config/constants.dart';

class BernieWalletApp extends StatelessWidget {
  const BernieWalletApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize services and repositories
    // It's good practice to use a dependency injection solution for larger apps (e.g., get_it)
    // For simplicity, we are initializing them here or they will be singletons.
    final StorageService storageService = StorageService();
    final TransactionStorageService transactionStorageService =
        TransactionStorageService();
    final AlgorandService algorandService = AlgorandService(storageService);
    final WalletRepository walletRepository = WalletRepository(
      algorandService: algorandService,
      storageService: storageService,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: storageService),
        RepositoryProvider.value(value: transactionStorageService),
        RepositoryProvider.value(value: algorandService),
        RepositoryProvider.value(value: walletRepository),
      ],
      child: BlocProvider(
        create: (context) => WalletBloc(
          walletRepository: walletRepository,
        )..add(const LoadWallet()), // Initial event to load wallet if exists
        child: MaterialApp(
          title: kAppName,
          theme: AppTheme.lightTheme,
          // darkTheme: AppTheme.darkTheme, // TODO: Implement darkTheme in AppTheme (config/theme.dart) or remove this line
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          initialRoute: kSplashRoute,
          onGenerateRoute: AppRouter.generateRoute,
        ),
      ),
    );
  }
}
