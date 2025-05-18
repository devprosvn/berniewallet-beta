# Bernie Wallet - Technical Documentation

## Introduction

Bernie Wallet is a Flutter-based cryptocurrency wallet application specifically designed for the Algorand blockchain. It provides a secure, user-friendly interface for managing Algorand assets, implementing modern security practices and following a robust architectural design.

This documentation provides a comprehensive overview of Bernie Wallet's functionality, architecture, and implementation status.

## Key Features

- **Wallet Management**: Create new wallets or import existing ones using a 25-word mnemonic phrase
- **Secure Storage**: All sensitive data (including mnemonics and PINs) is securely stored using Flutter Secure Storage
- **Balance Tracking**: View your ALGO balance in real-time
- **Transaction History**: Track incoming and outgoing transactions
- **Network Switching**: Toggle between Algorand MainNet and TestNet
- **PIN Protection**: Secure your wallet with PIN authentication
- **QR Code Generation**: Share your address easily with QR codes

## Technical Architecture

Bernie Wallet follows a structured architecture that separates concerns and enables maintainable code. The architecture is built around the BLoC pattern, which separates business logic from the UI.

### Project Structure

```
lib/
├── app.dart                 # Main application entry point
├── main.dart                # Flutter's main entry point
├── config/                  # App configuration
│   ├── constants.dart       # App constants
│   ├── routes.dart          # Navigation routes
│   └── theme.dart           # App theme definitions
├── models/                  # Data models
│   ├── wallet_model.dart
│   └── transaction_model.dart
├── services/                # Core services
│   ├── algorand_wallet_service.dart
│   └── secure_storage_service.dart
├── repositories/            # Repository layer
│   └── wallet_repository.dart
├── bloc/                    # Business Logic Components
│   ├── wallet/
│   │   ├── wallet_bloc.dart
│   │   ├── wallet_event.dart
│   │   └── wallet_state.dart
│   └── auth/
│       ├── auth_bloc.dart
│       ├── auth_event.dart
│       └── auth_state.dart
├── screens/                 # UI Screens
│   ├── onboarding/
│   ├── home/
│   └── settings/
└── widgets/                 # Reusable UI components
```

### BLoC Pattern Implementation

Bernie Wallet implements the BLoC (Business Logic Component) pattern to separate business logic from UI components, ensuring a unidirectional data flow:

#### Wallet BLoC

**States:**
- `WalletInitial`: Initial state before any wallet operations
- `WalletLoading`: Loading state during wallet operations
- `WalletCreated`: State after successful wallet creation
- `WalletImported`: State after successful wallet import
- `WalletReady`: State when wallet is loaded and ready for use
- `WalletError`: Error state with error details

**Events:**
- `CreateWallet`: Trigger wallet creation
- `ImportWallet`: Import existing wallet via mnemonic
- `LoadWallet`: Load existing wallet from secure storage
- `DeleteWallet`: Delete current wallet
- `RefreshBalance`: Refresh wallet balance

#### Auth BLoC

**States:**
- `Unauthenticated`: User is not authenticated
- `Authenticating`: Authentication is in progress
- `Authenticated`: User is successfully authenticated
- `AuthError`: Authentication error with details

**Events:**
- `Login`: Attempt login with PIN
- `Logout`: Log user out
- `SetupPin`: Set up a new PIN
- `VerifyBiometrics`: Verify using biometric authentication

### Service Layer

The service layer provides core functionality for wallet operations and security:

#### AlgorandWalletService

Handles all blockchain-specific operations:

```dart
class AlgorandWalletService {
  Future<WalletModel> createWallet();
  Future<WalletModel> importWallet(String mnemonic);
  Future<double> getBalance(String address);
  Future<List<TransactionModel>> getTransactions(String address);
  // Network-specific methods
  Future<void> switchNetwork(NetworkType type);
}
```

#### SecureStorageService

Handles secure storage of sensitive information:

```dart
class SecureStorageService {
  Future<void> saveMnemonic(String mnemonic);
  Future<String?> getMnemonic();
  Future<void> savePin(String pin);
  Future<bool> verifyPin(String pin);
  Future<void> clearStorage();
}
```

### Repository Pattern

The repository layer acts as an interface between BLoCs and services:

```dart
class WalletRepository {
  final AlgorandWalletService _algorandService;
  final SecureStorageService _storageService;

  Future<WalletModel> createWallet();
  Future<WalletModel> importWallet(String mnemonic);
  Future<WalletModel?> loadWallet();
  Future<void> deleteWallet();
  Future<double> getBalance(String address);
  Future<List<TransactionModel>> getTransactions(String address);
}
```

### Models

#### WalletModel

```dart
class WalletModel extends Equatable {
  final String address;
  final double balance;
  
  // Constructor and methods
}
```

#### TransactionModel

```dart
class TransactionModel extends Equatable {
  final String id;
  final double amount;
  final String sender;
  final String receiver;
  final DateTime timestamp;
  final TransactionType type;
  
  // Constructor and methods
}
```

## Core Wallet Functionality

### Wallet Creation

The wallet creation process follows these steps:

1. Generate a cryptographically secure 25-word mnemonic using the `bip39` library
2. Derive Algorand public address from this mnemonic using `algorand_dart`
3. Store the mnemonic securely using `flutter_secure_storage`
4. Return the wallet address to the user interface

Implementation Status: ✅ Implemented

### Wallet Import

Users can import existing wallets using their 25-word mnemonic phrase:

1. Validate the 25-word mnemonic format using `bip39`
2. Recover the wallet address from the valid mnemonic using `algorand_dart`
3. Store the imported mnemonic securely using `flutter_secure_storage`
4. Return the wallet address to the user interface

Implementation Status: ✅ Implemented

### Balance and Transaction History

The application provides real-time balance information and transaction history:

1. Connect to the Algorand API (MainNet or TestNet)
2. Fetch account balance and format in both ALGOs and microALGOs
3. Retrieve transaction history with pagination support
4. Display transaction details including type, amount, and timestamp

Implementation Status: ✅ Balance fetching implemented, 🔄 UI components in progress

### Wallet Management

Users can manage their wallet through various operations:

1. View wallet address in both full and truncated formats
2. Generate QR code for address sharing
3. Copy address to clipboard
4. Reset/delete wallet securely
5. Switch between MainNet and TestNet

Implementation Status: ✅ Core functionality implemented, 🔄 UI components in progress

## Security Implementation

Bernie Wallet implements multiple layers of security to protect user assets:

### Secure Storage

- Mnemonics are never stored in plain text
- Flutter Secure Storage is used for all sensitive data
- Implementation includes proper error handling for all storage operations

Implementation Status: ✅ Implemented

### PIN Authentication

- Simple PIN protection for application access
- PIN is stored securely (not in plain text)
- PIN verification is required to access wallet functionality

Recent Improvements:
- Enhanced PIN Authentication with fixed critical issues in PIN dialog implementation
- Properly managing TextEditingController lifecycle to prevent memory leaks and crashes
- Improved context handling in dialogs to prevent widget tree ancestry failures
- Better handling of PIN verification errors with clear user feedback
- Added safeguards to prevent multiple PIN dialogs appearing simultaneously

Implementation Status: ✅ Implemented with recent security enhancements

### Additional Security Features

- Automatic session timeout (planned)
- Biometric authentication support (planned)
- Protection against screenshot/screen recording (planned)

## User Interface

### Screen Flow

The application follows a logical flow:

1. **Welcome/Onboarding**: Initial screen for new users
2. **Create/Import Wallet**: Options to create new wallet or import existing one
3. **PIN Setup**: Set up security PIN
4. **Home/Dashboard**: Main wallet interface showing balance and options
5. **Transaction History**: List of past transactions
6. **Settings**: Configuration options for the wallet

Implementation Status: ✅ Core screens implemented, 🔄 Additional screens in progress

### UI Components

Bernie Wallet uses reusable components for consistent UI:

- Address Card: Display and sharing of wallet address
- Balance Display: Shows current ALGO balance with refresh option
- Transaction List Items: Display transaction details
- PIN Entry: Secure PIN input interface
- Loading Indicators: Visual feedback during async operations

Implementation Status: 🔄 In progress

## Algorand Integration

### Network Configuration

Bernie Wallet supports both Algorand MainNet and TestNet, with the ability to switch between them:

- **MainNet API Endpoints**:
  - `https://mainnet-api.algonode.cloud`
  - `https://mainnet-idx.algonode.cloud`
  
- **TestNet API Endpoints**:
  - `https://testnet-api.algonode.cloud`
  - `https://testnet-idx.algonode.cloud`

Implementation Status: ✅ Implemented

### API Features

- Balance checking with proper error handling
- Transaction history retrieval with pagination
- Network status monitoring
- Rate limiting and request throttling

Implementation Status: ✅ Core API functionality implemented

## Development Process

### AI-Assisted Development

The project utilized AI tools for enhanced productivity and code quality:

#### Manus AI
- Used to scaffold the initial project structure
- Generated the base folder hierarchy and empty file templates
- Created the initial outline for core wallet functionality

#### Cursor IDE with Claude AI
- Assisted in developing more complex functionality:
  - Implemented the Algorand blockchain integration
  - Created security features with encryption
  - Generated BLoC pattern implementations
  - Helped with error handling and testing
  - Fixed critical bugs in PIN authentication system

### Current Implementation Status

The project has made significant progress in core functionality:

- ✅ Complete technical architecture and project structure
- ✅ Core wallet services (create, import, load, delete wallets)
- ✅ Security implementation with secure storage
- ✅ Blockchain integration with the Algorand network
- ✅ Transaction history functionality
- ✅ Network switching between MainNet and TestNet
- ✅ Models and state management (BLoC) implementation
- ✅ PIN authentication system with proper lifecycle management
- ✅ Home screen UI with wallet information display
- 🔄 Additional UI screens implementation in progress
- 🔄 Testing and finalization in progress

## Web Deployment

Bernie Wallet supports web deployment with specific configurations for different hosting environments:

### GitHub Pages Deployment
- Uses a base href of `/berniewallet/`
- Custom 404.html for SPA routing support
- Configured CNAME and .nojekyll files

### Custom Domain Deployment
- Uses a base href of `/`
- Customized 404.html for root-based routing
- Enhanced loading indicator

Both deployment options are supported through the PowerShell build script (`build-web.ps1`) with the `-DeploymentTarget` parameter:

```powershell
# For GitHub Pages
.\build-web.ps1 -DeploymentTarget github

# For Custom Domain
.\build-web.ps1 -DeploymentTarget custom
```

Implementation Status: ✅ Implemented

## Future Roadmap

1. Complete remaining UI implementation with modern design
2. Add biometric authentication support
3. Implement asset management for Algorand Standard Assets (ASAs)
4. Add multi-wallet support
5. Integrate with DeFi platforms on Algorand

## Tech Stack

- **Flutter**: Cross-platform UI framework
- **BLoC Pattern**: State management architecture
- **Algorand Dart**: Official Algorand SDK for Dart
- **Flutter Secure Storage**: Secure storage solution
- **Flutter BLoC**: Implementation of the BLoC pattern
- **Equatable**: For value equality comparisons
- **BIP39**: For mnemonic phrase generation
- **QR Flutter**: For QR code generation

---

## Development Team

**Team: DevPros**
- Email: work.devpros@gmail.com
- Facebook: https://facebook.com/blog.devpros

**Main Developer:**
- Nguyễn Ngọc Gia Bảo
- Student ID: 6151071036
- Class: CQ.61.CNTT
- Role: Team Leader

**Developer:**
- Vũ Đức Huy
- Student ID: 6351071029
- Class: CQ.63.CNTT 