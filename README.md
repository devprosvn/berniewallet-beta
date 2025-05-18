# Bernie Wallet

Bernie Wallet is a Flutter-based cryptocurrency wallet application specifically designed for the Algorand blockchain. It provides a secure, user-friendly interface for managing Algorand assets.

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

## Features

- **Wallet Management**: Create new wallets or import existing ones using a 25-word mnemonic phrase
- **Secure Storage**: All sensitive data (including mnemonics and PINs) is securely stored using Flutter Secure Storage
- **Balance Tracking**: View your ALGO balance in real-time
- **Transaction History**: Track incoming and outgoing transactions
- **Network Switching**: Toggle between Algorand MainNet and TestNet
- **PIN Protection**: Secure your wallet with PIN authentication
- **QR Code Generation**: Share your address easily with QR codes

## Project Development Process

### Project Planning & Architecture

The project was developed following the BLoC (Business Logic Component) architecture pattern, which separates the UI from business logic. The development followed a structured approach:

1. **Requirements Analysis**: Defined core wallet functionality, security needs, and user interface requirements
2. **Architecture Design**: Designed a layered architecture with clear separation of concerns:
   - Presentation Layer (Screens & Widgets)
   - Business Logic Layer (BLoCs)
   - Data Layer (Repositories & Services)
   - Model Layer (Data Models)

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

#### AI Integration Benefits
- **Rapid Development**: Accelerated project setup and implementation
- **Code Quality**: AI suggestions for best practices and design patterns
- **Documentation**: Auto-generated comments and documentation
- **Problem Solving**: Assisted in resolving complex integration issues
- **Bug Fixing**: Identified and fixed lifecycle and context management issues

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

## Security Improvements

Recent updates to the application have significantly improved security:

- **Enhanced PIN Authentication**: Fixed critical issues in PIN dialog implementation
- **Controller Lifecycle Management**: Properly managing TextEditingController lifecycle to prevent memory leaks and crashes
- **Context Management**: Improved context handling in dialogs to prevent widget tree ancestry failures
- **Error Handling**: Better handling of PIN verification errors with clear user feedback
- **Multiple PIN Dialog Prevention**: Added safeguards to prevent multiple PIN dialogs appearing simultaneously

## Tech Stack

- **Flutter**: Cross-platform UI framework
- **BLoC Pattern**: State management architecture
- **Algorand Dart**: Official Algorand SDK for Dart
- **Flutter Secure Storage**: Secure storage solution
- **Flutter BLoC**: Implementation of the BLoC pattern
- **Equatable**: For value equality comparisons
- **BIP39**: For mnemonic phrase generation
- **QR Flutter**: For QR code generation

## Getting Started

1. Ensure you have Flutter installed (version 3.0.0 or higher)
2. Clone the repository
3. Run `flutter pub get` to install dependencies
4. Run `flutter run` to start the application

## Project Structure

- `lib/models`: Data models for wallet and transactions
- `lib/services`: Services for Algorand blockchain interaction and secure storage
- `lib/repositories`: Repository layer for managing data flow
- `lib/bloc`: Business logic components for state management
- `lib/screens`: UI screens
- `lib/widgets`: Reusable UI components
- `lib/config`: Application configuration and constants

## Build and Deployment

### Development Build
```bash
flutter build apk --debug
```

### Production Build
```bash
flutter build apk --release
```

### Running Tests
```bash
flutter test
```

## Future Roadmap

1. Complete remaining UI implementation with modern design
2. Add biometric authentication support
3. Implement asset management for Algorand Standard Assets (ASAs)
4. Add multi-wallet support
5. Integrate with DeFi platforms on Algorand

---

# Bernie Wallet (Vietnamese)

Bernie Wallet là ứng dụng ví tiền điện tử được phát triển bằng Flutter, được thiết kế đặc biệt cho blockchain Algorand. Ứng dụng cung cấp giao diện người dùng thân thiện và bảo mật để quản lý tài sản Algorand.

## Đội Ngũ Phát Triển

**Đội: DevPros**
- Email: work.devpros@gmail.com
- Facebook: https://facebook.com/blog.devpros

**Nhà Phát Triển Chính:**
- Nguyễn Ngọc Gia Bảo
- Mã sinh viên: 6151071036
- Lớp: CQ.61.CNTT
- Vai trò: Trưởng nhóm

**Nhà Phát Triển:**
- Vũ Đức Huy
- Mã sinh viên: 6351071029
- Lớp: CQ.63.CNTT

## Tính năng

- **Quản lý ví**: Tạo ví mới hoặc nhập ví đã tồn tại bằng cụm từ ghi nhớ 25 từ
- **Lưu trữ bảo mật**: Tất cả dữ liệu nhạy cảm (bao gồm cụm từ ghi nhớ và mã PIN) được lưu trữ an toàn bằng Flutter Secure Storage
- **Theo dõi số dư**: Xem số dư ALGO của bạn theo thời gian thực
- **Lịch sử giao dịch**: Theo dõi các giao dịch đến và đi
- **Chuyển đổi mạng**: Chuyển đổi giữa Algorand MainNet và TestNet
- **Bảo vệ bằng PIN**: Bảo mật ví của bạn với xác thực PIN
- **Tạo mã QR**: Chia sẻ địa chỉ ví của bạn dễ dàng với mã QR

## Quy Trình Phát Triển Dự Án

### Lập Kế Hoạch & Kiến Trúc Dự Án

Dự án được phát triển theo mẫu kiến trúc BLoC (Business Logic Component), tách biệt UI khỏi logic nghiệp vụ. Quá trình phát triển theo cách tiếp cận có cấu trúc:

1. **Phân Tích Yêu Cầu**: Xác định chức năng cốt lõi của ví, nhu cầu bảo mật và yêu cầu giao diện người dùng
2. **Thiết Kế Kiến Trúc**: Thiết kế kiến trúc phân lớp với sự phân tách rõ ràng:
   - Lớp Trình Bày (Màn hình & Widget)
   - Lớp Logic Nghiệp Vụ (BLoC)
   - Lớp Dữ Liệu (Repository & Service)
   - Lớp Mô Hình (Data Model)

### Phát Triển Hỗ Trợ Bởi AI

Dự án sử dụng các công cụ AI để nâng cao năng suất và chất lượng mã:

#### Manus AI
- Được sử dụng để dựng cấu trúc dự án ban đầu
- Tạo ra cấu trúc thư mục cơ bản và mẫu tệp trống
- Tạo phác thảo ban đầu cho chức năng cốt lõi của ví

#### Cursor IDE với Claude AI
- Hỗ trợ phát triển chức năng phức tạp hơn:
  - Triển khai tích hợp blockchain Algorand
  - Tạo tính năng bảo mật với mã hóa
  - Tạo triển khai mẫu BLoC
  - Hỗ trợ xử lý lỗi và kiểm thử
  - Sửa lỗi quan trọng trong hệ thống xác thực PIN

#### Lợi Ích Tích Hợp AI
- **Phát Triển Nhanh Chóng**: Đẩy nhanh việc thiết lập và thực hiện dự án
- **Chất Lượng Mã**: Đề xuất AI cho các phương pháp tốt nhất và mẫu thiết kế
- **Tài Liệu**: Tự động tạo nhận xét và tài liệu
- **Giải Quyết Vấn Đề**: Hỗ trợ giải quyết các vấn đề tích hợp phức tạp
- **Sửa Lỗi**: Xác định và sửa các vấn đề về quản lý vòng đời và ngữ cảnh

### Trạng Thái Triển Khai Hiện Tại

Dự án đã đạt được tiến bộ đáng kể trong chức năng cốt lõi:

- ✅ Kiến trúc kỹ thuật và cấu trúc dự án hoàn chỉnh
- ✅ Dịch vụ ví cốt lõi (tạo, nhập, tải, xóa ví)
- ✅ Triển khai bảo mật với lưu trữ an toàn
- ✅ Tích hợp blockchain với mạng Algorand
- ✅ Chức năng lịch sử giao dịch
- ✅ Chuyển đổi mạng giữa MainNet và TestNet
- ✅ Triển khai mô hình và quản lý trạng thái (BLoC)
- ✅ Hệ thống xác thực PIN với quản lý vòng đời thích hợp
- ✅ Giao diện màn hình chính với hiển thị thông tin ví
- 🔄 Đang triển khai các màn hình UI bổ sung
- 🔄 Đang kiểm thử và hoàn thiện

## Cải Tiến Bảo Mật

Các cập nhật gần đây cho ứng dụng đã cải thiện đáng kể bảo mật:

- **Tăng cường xác thực PIN**: Sửa các vấn đề quan trọng trong việc triển khai hộp thoại PIN
- **Quản lý vòng đời Controller**: Quản lý thích hợp vòng đời TextEditingController để ngăn rò rỉ bộ nhớ và sự cố
- **Quản lý ngữ cảnh**: Cải thiện xử lý ngữ cảnh trong hộp thoại để ngăn các lỗi về phả hệ cây widget
- **Xử lý lỗi**: Xử lý tốt hơn các lỗi xác minh PIN với phản hồi rõ ràng cho người dùng
- **Ngăn chặn nhiều hộp thoại PIN**: Thêm biện pháp bảo vệ để ngăn nhiều hộp thoại PIN xuất hiện đồng thời

## Công Nghệ Sử Dụng

- **Flutter**: Framework UI đa nền tảng
- **BLoC Pattern**: Kiến trúc quản lý trạng thái
- **Algorand Dart**: SDK chính thức của Algorand cho Dart
- **Flutter Secure Storage**: Giải pháp lưu trữ bảo mật
- **Flutter BLoC**: Triển khai mẫu BLoC
- **Equatable**: Cho so sánh giá trị bình đẳng
- **BIP39**: Cho việc tạo cụm từ ghi nhớ
- **QR Flutter**: Cho việc tạo mã QR

## Bắt Đầu

1. Đảm bảo bạn đã cài đặt Flutter (phiên bản 3.0.0 trở lên)
2. Clone repository
3. Chạy `flutter pub get` để cài đặt các dependency
4. Chạy `flutter run` để khởi động ứng dụng

## Cấu Trúc Dự Án

- `lib/models`: Các mô hình dữ liệu cho ví và giao dịch
- `lib/services`: Các dịch vụ tương tác với blockchain Algorand và lưu trữ bảo mật
- `lib/repositories`: Lớp repository quản lý luồng dữ liệu
- `lib/bloc`: Các component xử lý logic nghiệp vụ và quản lý trạng thái
- `lib/screens`: Các màn hình UI
- `lib/widgets`: Các component UI có thể tái sử dụng
- `lib/config`: Cấu hình ứng dụng và các hằng số

## Build và Triển Khai

### Build Phát Triển
```bash
flutter build apk --debug
```

### Build Sản Phẩm
```bash
flutter build apk --release
```

### Chạy Kiểm Thử
```bash
flutter test
```

## Lộ Trình Tương Lai

1. Hoàn thành triển khai UI còn lại với thiết kế hiện đại
2. Thêm hỗ trợ xác thực sinh trắc học
3. Triển khai quản lý tài sản cho Tài sản tiêu chuẩn Algorand (ASA)
4. Thêm hỗ trợ đa ví
5. Tích hợp với các nền tảng DeFi trên Algorand
