import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bernie_wallet/app.dart';
import 'package:bernie_wallet/bloc/wallet_observer.dart'; // For observing BLoC events
import 'package:bernie_wallet/services/algorand_service.dart';
import 'package:bernie_wallet/services/storage_service.dart';
import 'package:bernie_wallet/repositories/wallet_repository.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  // StorageService is a prerequisite for AlgorandService (to load network preference)
  // and for WalletRepository.
  final storageService = StorageService();
  final algorandService = AlgorandService(storageService);
  final walletRepository = WalletRepository(
    algorandService: algorandService,
    storageService: storageService,
  );

  // Set up BLoC observer for debugging or logging (optional)
  Bloc.observer = WalletBlocObserver();

  // Run the app, providing the WalletRepository
  // The BernieWalletApp widget will then provide this repository (and others)
  // to the rest of the widget tree, including initializing WalletBloc.
  runApp(
    RepositoryProvider<WalletRepository>(
      create: (context) => walletRepository,
      // We can also provide AlgorandService and StorageService here if needed directly by UI elements,
      // but usually, they are accessed via the repository or BLoC.
      // For direct access, use MultiRepositoryProvider as in app.dart if necessary.
      child: const BernieWalletApp(),
    ),
  );
}
