import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum AppLanguage { english, vietnamese }

abstract final class AppStrings {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final ValueNotifier<AppLanguage> language = ValueNotifier(
    AppLanguage.english,
  );

  static Future<void> initialize() async {
    final savedLanguage = await _storage.read(key: 'app-language');
    if (savedLanguage == 'vi') {
      language.value = AppLanguage.vietnamese;
    }
  }

  static Future<void> setLanguage(AppLanguage value) async {
    await _storage.write(
      key: 'app-language',
      value: value == AppLanguage.vietnamese ? 'vi' : 'en',
    );
    language.value = value;
  }

  static bool get isVietnamese => language.value == AppLanguage.vietnamese;

  static String _text(String english, String vietnamese) =>
      isVietnamese ? vietnamese : english;

  static String get languageTitle => _text('Language', 'Ngôn ngữ');
  static String get languageEnglish => 'English';
  static String get languageVietnamese => 'Tiếng Việt';
  static String get languageCode => isVietnamese ? 'VI' : 'EN';

  // App -------------------------------------------------------------------

  /// Platform application title, in sentence case.
  static const String appTitle = 'BigFit';

  /// Storefront wordmark, in caps.
  static const String brandName = 'BIGFIT';

  // Actions ---------------------------------------------------------------

  static String get cancel => _text('Cancel', 'Hủy');
  static String get save => _text('Save', 'Lưu');
  static String get later => _text('Later', 'Để sau');
  static String get tryAgain => _text('Try again', 'Thử lại');
  static String get refresh => _text('Refresh', 'Làm mới');
  static String get required => _text('Required', 'Bắt buộc');

  // Storefront ------------------------------------------------------------

  static String get heroTitle =>
      _text('Clothing that fits', 'Trang phục vừa vặn');
  static String get heroSubtitle =>
      _text('Explore the BigFit collection', 'Khám phá bộ sưu tập BigFit');
  static String get collectionHeading => _text('THE COLLECTION', 'BỘ SƯU TẬP');
  static String get onSaleHeading => _text('ON SALE', 'ĐANG GIẢM GIÁ');
  static String get womenSegment => _text('WOMEN', 'NỮ');
  static String get menSegment => _text('MEN', 'NAM');
  static String get searchHint => _text(
    'Search clothes, styles, and sizes',
    'Tìm quần áo, phong cách và kích cỡ',
  );
  static String get filterAll => _text('All', 'Tất cả');
  static String get filterOnSale => _text('On sale', 'Đang giảm giá');
  static String get filterInStock => _text('In stock', 'Còn hàng');
  static String get sortName => _text('Name', 'Tên');
  static String get sortPriceAsc => _text('Price ↑', 'Giá tăng dần ↑');
  static String get sortPriceDesc => _text('Price ↓', 'Giá giảm dần ↓');
  static String get sortNewest => _text('Newest', 'Mới nhất');
  static String get loadMore => _text('Load more', 'Tải thêm');
  static String get catalogEmptyTitle => _text(
    'Your next favourite fit is on its way.',
    'Mẫu trang phục yêu thích tiếp theo sắp có mặt.',
  );
  static String get catalogEmptySubtitle => _text(
    'The cleaned catalogue is ready for review. Products will appear here after you approve and import the CSV.',
    'Danh mục đã được làm sạch và sẵn sàng để xem xét. Sản phẩm sẽ xuất hiện sau khi bạn duyệt và nhập tệp CSV.',
  );
  static String get navShop => _text('Shop', 'Mua sắm');
  static String get navSale => _text('Sale', 'Khuyến mãi');

  // Store connection ------------------------------------------------------

  static String get storeConnectionTitle =>
      _text('Store connection', 'Kết nối cửa hàng');
  static String get renderDeployment =>
      _text('Render deployment', 'Máy chủ Render');
  static String get localDevelopmentServer =>
      _text('Local development server', 'Máy chủ phát triển cục bộ');
  static String get apiPathNote => _text(
    'The API path is added automatically. Changing servers signs you out so credentials are not reused on another server.',
    'Đường dẫn API được tự động thêm vào. Khi đổi máy chủ, bạn sẽ đăng xuất để thông tin đăng nhập không được dùng lại trên máy chủ khác.',
  );

  // Account sheet ---------------------------------------------------------

  static String get ordersTitle => _text('Orders', 'Đơn hàng');
  static String get favoritesTitle => _text('Favorites', 'Yêu thích');
  static String get addressesTitle => _text('Addresses', 'Địa chỉ');
  static String get notificationsTitle => _text('Notifications', 'Thông báo');
  static String get aiStylist => _text('AI stylist', 'Tư vấn AI');
  static String get moreFeatures => _text('More features', 'Thêm tính năng');
  static String get signOut => _text('Sign out', 'Đăng xuất');
  static String get signIn => _text('Sign in', 'Đăng nhập');
  static String get account => _text('Account', 'Tài khoản');

  // Authentication --------------------------------------------------------

  static String get joinBigFit => _text('Join BigFit', 'Tham gia BigFit');
  static String get welcomeBack =>
      _text('Welcome back', 'Chào mừng bạn quay lại');
  static String get registerSubtitle => _text(
    'Create a customer account to get started.',
    'Tạo tài khoản khách hàng để bắt đầu.',
  );
  static String get loginSubtitle => _text(
    'Sign in with your BigFit account.',
    'Đăng nhập bằng tài khoản BigFit của bạn.',
  );
  static String get displayName => _text('Display name', 'Tên hiển thị');
  static String get email => _text('Email', 'Email');
  static String get password => _text('Password', 'Mật khẩu');
  static String get passwordPolicyHint => _text(
    'Use 12+ characters with uppercase, lowercase, number, and symbol.',
    'Dùng ít nhất 12 ký tự, gồm chữ hoa, chữ thường, số và ký hiệu.',
  );
  static String get createAccount =>
      _text('Create customer account', 'Tạo tài khoản khách hàng');
  static String get switchToSignIn =>
      _text('Already have an account? Sign in', 'Đã có tài khoản? Đăng nhập');
  static String get switchToRegister => _text(
    'New to BigFit? Create an account',
    'Bạn mới biết BigFit? Tạo tài khoản',
  );
  static String get validationDisplayName =>
      _text('Enter at least 2 characters.', 'Nhập ít nhất 2 ký tự.');
  static String get validationEmail =>
      _text('Enter a valid email address.', 'Nhập địa chỉ email hợp lệ.');
  static String get validationPasswordLength =>
      _text('Use at least 12 characters.', 'Mật khẩu cần ít nhất 12 ký tự.');
  static String get validationPasswordRequired =>
      _text('Enter your password.', 'Nhập mật khẩu.');

  // Product ---------------------------------------------------------------

  static String get soldOut => _text('SOLD OUT', 'HẾT HÀNG');
  static String get sizeAndColour =>
      _text('Size & colour', 'Kích cỡ và màu sắc');
  static String get currentlyUnavailable =>
      _text('Currently unavailable', 'Hiện không có sẵn');
  static String get addToBag => _text('Add to bag', 'Thêm vào túi');
  static String get buyNow => _text('Buy now', 'Mua ngay');
  static String get addToFavorites =>
      _text('Add to favorites', 'Thêm vào yêu thích');

  // Cart and checkout -----------------------------------------------------

  static String get shoppingBagTitle => _text('Shopping bag', 'Túi hàng');
  static String get bagEmpty =>
      _text('Your bag is empty.', 'Túi hàng của bạn đang trống.');
  static String get subtotal => _text('Subtotal', 'Tạm tính');
  static String get pleaseWait => _text('Please wait…', 'Vui lòng đợi…');
  static String get continueToOrder =>
      _text('Continue to order', 'Tiếp tục đặt hàng');
  static String get addressNeededTitle =>
      _text('Delivery address needed', 'Cần địa chỉ giao hàng');
  static String get addressNeededMessage => _text(
    'Add a delivery address before creating your order.',
    'Thêm địa chỉ giao hàng trước khi tạo đơn hàng.',
  );
  static String get addAddress => _text('Add address', 'Thêm địa chỉ');
  static String get reviewOrderTitle =>
      _text('Review your order', 'Kiểm tra đơn hàng');
  static String get deliveryAddress =>
      _text('Delivery address', 'Địa chỉ giao hàng');
  static String get orderOnlyNotice => _text(
    'This creates an order only. Online payment is not connected to the backend yet.',
    'Thao tác này chỉ tạo đơn hàng. Thanh toán trực tuyến chưa được kết nối với backend.',
  );
  static String get createOrder => _text('Create order', 'Tạo đơn hàng');

  // Favorites -------------------------------------------------------------

  static String get favoritesEmpty =>
      _text('No favorites saved yet.', 'Bạn chưa lưu sản phẩm yêu thích nào.');
  static String get addedToFavorites =>
      _text('Added to your favorites.', 'Đã thêm vào danh sách yêu thích.');

  // Orders ----------------------------------------------------------------

  static String get orderHistoryTitle =>
      _text('Order history', 'Lịch sử đơn hàng');
  static String get ordersEmpty =>
      _text('No orders yet.', 'Chưa có đơn hàng nào.');

  // Addresses -------------------------------------------------------------

  static String get deliveryAddressesTitle =>
      _text('Delivery addresses', 'Địa chỉ giao hàng');
  static String get addressesEmpty => _text(
    'No delivery addresses saved yet.',
    'Chưa lưu địa chỉ giao hàng nào.',
  );
  static String get mapSdkNotice => _text(
    'Map SDK is not configured. You can save optional coordinates manually; saved locations are sent to the backend.',
    'Chưa cấu hình SDK bản đồ. Bạn có thể nhập tọa độ tùy chọn; vị trí đã lưu sẽ được gửi đến backend.',
  );
  static String get editAddressTitle =>
      _text('Edit address', 'Chỉnh sửa địa chỉ');
  static String get defaultAddressLabel => _text('Home', 'Nhà riêng');
  static const String defaultCountryCode = 'VN';
  static String get setAsDefault => _text('Set as default', 'Đặt làm mặc định');
  static String get fieldAddressLabel => _text('Address label', 'Tên địa chỉ');
  static String get fieldRecipientName =>
      _text('Recipient name', 'Tên người nhận');
  static String get fieldPhoneNumber => _text('Phone number', 'Số điện thoại');
  static String get fieldAddressLine =>
      _text('Street address', 'Địa chỉ đường phố');
  static String get fieldCity => _text('City', 'Thành phố');
  static String get fieldProvince => _text('Province / state', 'Tỉnh / bang');
  static String get fieldPostalCode => _text('Postal code', 'Mã bưu chính');
  static String get fieldCountryCode =>
      _text('Country code (2 letters)', 'Mã quốc gia (2 chữ cái)');
  static String get fieldLatitude =>
      _text('Latitude (optional)', 'Vĩ độ (không bắt buộc)');
  static String get fieldLongitude =>
      _text('Longitude (optional)', 'Kinh độ (không bắt buộc)');
  static String get mapLocationPickerHeader => _text(
    'Map location (tap or drag to place pin)',
    'Vị trí trên bản đồ (chạm hoặc vuốt để chọn ghim)',
  );
  static String get myLocationTooltip =>
      _text('Get my current location', 'Lấy vị trí hiện tại của tôi');
  static String continueWithSelectedAddress(String label) => _text(
    'Continue with selected address ($label)',
    'Tiếp tục với địa chỉ đã chọn ($label)',
  );
  static String get orEnterNewAddress =>
      _text('Or enter new address details', 'Hoặc nhập thông tin địa chỉ mới');
  static String get saveNewAddressAndContinue =>
      _text('Save new address & continue', 'Lưu địa chỉ mới & tiếp tục');
  static String get trackingDeliveredSuccess =>
      _text('Package delivered successfully', 'Đã giao hàng thành công');
  static String get trackingDriverOnTheWay =>
      _text('Driver is delivering to you', 'Tài xế đang giao hàng đến bạn');
  static String get trackingLoadingRoute =>
      _text('Loading road route...', 'Đang tải lộ trình đường đi...');

  // Notifications ---------------------------------------------------------

  static String get pushNotConnectedNotice => _text(
    'Live push updates are not connected yet',
    'Chưa kết nối cập nhật thông báo trực tiếp',
  );
  static String get pushConnectedNotice =>
      _text('Live push connected', 'Đã kết nối thông báo trực tiếp');
  static String get notificationsEmpty =>
      _text('You are all caught up.', 'Bạn đã xem hết thông báo.');

  // Payment ---------------------------------------------------------------

  static String get paymentTitle => _text('Payment', 'Thanh toán');
  static String get paymentCod =>
      _text('Cash on delivery', 'Thanh toán khi nhận hàng');
  static String get paymentCodSubtitle =>
      _text('Pay when your order arrives', 'Thanh toán khi đơn hàng được giao');
  static String get paymentBank =>
      _text('Bank transfer', 'Chuyển khoản ngân hàng');
  static String get paymentBankSubtitle => _text(
    'Bank Hub sandbox transfer. No real money is charged.',
    'Chuyển khoản thử trên Bank Hub sandbox. Không phát sinh tiền thật.',
  );
  static String get paymentGateway =>
      _text('SePay card sandbox', 'Thẻ SePay sandbox');
  static String get paymentGatewaySubtitle => _text(
    'Bank Hub sandbox card. No real money is charged.',
    'Thẻ thử trên Bank Hub sandbox. Không phát sinh tiền thật.',
  );
  static String get paymentHubBody => _text(
    'Choose a method while checking out from your bag. Bank transfer waits for Bank Hub sandbox confirmation. Cash on delivery stays unpaid until the order arrives.',
    'Chọn phương thức khi thanh toán từ túi hàng. Chuyển khoản chờ Bank Hub sandbox xác nhận. Thanh toán khi nhận hàng được thu lúc giao.',
  );

  // Map -------------------------------------------------------------------

  static String get mapTitle =>
      _text('Choose delivery location', 'Chọn vị trí giao hàng');
  static String get useThisLocation =>
      _text('Use this location', 'Dùng vị trí này');

  // Profile ---------------------------------------------------------------

  static String get profileTitle => _text('My profile', 'Hồ sơ của tôi');
  static String get profileEditTitle =>
      _text('Account details', 'Thông tin tài khoản');
  static const String avatarFallback = 'B';
  static String get guest => _text('Guest', 'Khách');
  static String get signInToSaveProfile =>
      _text('Sign in to save your profile', 'Đăng nhập để lưu hồ sơ');
  static String get accountType => _text('Account type', 'Loại tài khoản');
  static String get customerProfile =>
      _text('Customer profile', 'Hồ sơ khách hàng');
  static String get fitPreferences =>
      _text('Fit preferences', 'Tùy chọn kích cỡ');
  static String get fitPreferencesValue =>
      _text('Sizes M–XXL · Not set', 'Cỡ M–XXL · Chưa thiết lập');
  static String get myReviews => _text('My reviews', 'Đánh giá của tôi');
  static String get reviewsNotConnected => _text(
    'Review management API is not connected',
    'API quản lý đánh giá chưa được kết nối',
  );
  static String get profileFrameNote => _text(
    'Profile editing and size preferences are shown as a frame. The current backend does not expose profile update or review endpoints.',
    'Màn hình chỉnh sửa hồ sơ và tùy chọn kích cỡ chỉ là bản xem trước. Backend hiện chưa hỗ trợ cập nhật hồ sơ hoặc đánh giá.',
  );

  // Account security ------------------------------------------------------

  static String get securityTitle =>
      _text('Account security', 'Bảo mật tài khoản');
  static String get securityHeadline =>
      _text('Protect your BigFit account', 'Bảo vệ tài khoản BigFit của bạn');
  static String get securityIntro => _text(
    'Verify your email, reset your password, or confirm a one-time passcode.',
    'Xác minh email, đặt lại mật khẩu hoặc xác nhận mã OTP.',
  );
  static String get verifyEmail => _text('Verify your email', 'Xác minh email');
  static String get verifyEmailDescription => _text(
    'Confirm your email address with a one-time link.',
    'Xác nhận địa chỉ email bằng liên kết dùng một lần.',
  );
  static String get emailServiceReady => _text(
    'API ready — wire SMTP on the server',
    'API sẵn sàng — cấu hình SMTP trên server',
  );
  static String get resetPassword =>
      _text('Reset password', 'Đặt lại mật khẩu');
  static String get resetPasswordDescription => _text(
    'Request a secure password reset email.',
    'Yêu cầu email đặt lại mật khẩu an toàn.',
  );
  static String get resetApiReady =>
      _text('Reset via email token', 'Đặt lại qua token email');
  static String get otpTitle =>
      _text('One-time passcode', 'Mã xác minh một lần');
  static String get otpDescription => _text(
    'Enter a time-limited code sent to your email.',
    'Nhập mã có thời hạn được gửi đến email của bạn.',
  );
  static String get otpApiReady =>
      _text('Email OTP with retry limits', 'OTP email có giới hạn thử lại');
  static String get securityEmailLoggingNotice => _text(
    'When SMTP is off, links and codes appear in server logs and dev hints here.',
    'Khi tắt SMTP, liên kết và mã hiện trong log server và gợi ý dev tại đây.',
  );
  static String get sendVerificationEmail =>
      _text('Send verification email', 'Gửi email xác minh');
  static String get verificationEmailSent =>
      _text('Verification email requested', 'Đã yêu cầu email xác minh');
  static String devEmailLinkHint(String link) =>
      _text('Dev link (SMTP off): $link', 'Liên kết dev (tắt SMTP): $link');
  static String get requestResetEmail =>
      _text('Request reset email', 'Yêu cầu email đặt lại');
  static String get resetEmailSent => _text(
    'If the email exists, reset instructions were sent.',
    'Nếu email tồn tại, hướng dẫn đặt lại đã được gửi.',
  );
  static String get enterResetToken =>
      _text('Enter the token from your email', 'Nhập token từ email');
  static String get resetTokenLabel => _text('Reset token', 'Token đặt lại');
  static String get newPasswordLabel => _text('New password', 'Mật khẩu mới');
  static String get saveNewPassword =>
      _text('Save new password', 'Lưu mật khẩu mới');
  static String get resetPasswordSuccess =>
      _text('Password updated', 'Đã cập nhật mật khẩu');
  static String get sendOtp => _text('Send code', 'Gửi mã');
  static String get otpSent => _text('Code sent', 'Đã gửi mã');
  static String get otpCodeLabel => _text('One-time code', 'Mã một lần');
  static String get verifyOtp => _text('Verify code', 'Xác minh mã');
  static String get otpVerified => _text('Code accepted', 'Mã hợp lệ');
  static String get otpInvalid =>
      _text('Code was not accepted', 'Mã không hợp lệ');
  static String devOtpHint(String code) =>
      _text('Dev code (SMTP off): $code', 'Mã dev (tắt SMTP): $code');

  // Feature hub -----------------------------------------------------------

  static String get featureHubTitle =>
      _text('More from BigFit', 'Khám phá thêm từ BigFit');
  static String get yourAccount => _text('Your account', 'Tài khoản của bạn');
  static String get profileAndFit =>
      _text('Profile & fit preferences', 'Hồ sơ và tùy chọn kích cỡ');
  static String get profileAndFitPreview => _text(
    'Preview account details and fit preferences',
    'Xem trước thông tin tài khoản và tùy chọn kích cỡ',
  );
  static String get profileAndFitSignedIn => _text(
    'Personal details, sizes, and reviews',
    'Thông tin cá nhân, kích cỡ và đánh giá',
  );
  static String get deliveryMap => _text('Delivery map', 'Bản đồ giao hàng');
  static String get paymentMethods =>
      _text('Payment methods', 'Phương thức thanh toán');
  static String get paymentMethodsSubtitle => _text(
    'COD, SePay transfer, and SePay card',
    'Khi nhận hàng, chuyển khoản SePay và thẻ SePay',
  );
  static String get accountSecuritySubtitle => _text(
    'Email verification, reset, and OTP',
    'Xác minh email, đặt lại mật khẩu và OTP',
  );
  static String get storeTools => _text('Store tools', 'Công cụ cửa hàng');
  static String get storeToolsSubtitle => _text(
    'Products, inventory, orders, and reviews',
    'Sản phẩm, tồn kho, đơn hàng và đánh giá',
  );

  // Store management ------------------------------------------------------

  static String get storeManagementTitle =>
      _text('Store management', 'Quản lý cửa hàng');
  static String get managementOverview =>
      _text('Management overview', 'Tổng quan quản lý');
  static String get productsAndInventory =>
      _text('Products & inventory', 'Sản phẩm và tồn kho');
  static String get productsAndInventoryDetail => _text(
    'Manage catalogue items, variants, and stock.',
    'Quản lý sản phẩm, biến thể và hàng tồn kho.',
  );
  static String get ordersDetail => _text(
    'Review orders and update fulfilment status.',
    'Xem đơn hàng và cập nhật trạng thái xử lý.',
  );
  static String get customerReviews =>
      _text('Customer reviews', 'Đánh giá của khách hàng');
  static String get customerReviewsDetail =>
      _text('Moderate product feedback.', 'Kiểm duyệt phản hồi về sản phẩm.');
  static String get managementNotConnected => _text(
    'Management endpoints are not connected. This screen does not change store data.',
    'Các endpoint quản lý chưa được kết nối. Màn hình này không thay đổi dữ liệu cửa hàng.',
  );
  static String get storeManagementRestricted => _text(
    'Store management is available to Admin and Store Staff accounts.',
    'Chỉ tài khoản Admin và Nhân viên cửa hàng mới có thể quản lý cửa hàng.',
  );

  // Storefront redesign ---------------------------------------------------

  static String get promoHeadline => _text(
    'Up to 40% off mid-season styles',
    'Giảm đến 40% cho bộ sưu tập giữa mùa',
  );
  static String get promoCaption => _text(
    'Free delivery over 2.000.000 VND',
    'Miễn phí giao hàng cho đơn từ 2.000.000 VND',
  );
  static String get shopAll => _text('Shop all', 'Mua tất cả');
  static String get newIn => _text('New in', 'Hàng mới');
  static String get bestSellers => _text('Best sellers', 'Bán chạy nhất');
  static String get womenCategory => _text('Women', 'Nữ');
  static String get menCategory => _text('Men', 'Nam');
  static String get shopBySize => _text('Shop by size', 'Mua theo kích cỡ');
  static String get viewAll => _text('View all', 'Xem tất cả');
  static String get freeDeliveryNote => _text(
    'Free delivery on orders over 2.000.000 VND',
    'Miễn phí giao hàng cho đơn từ 2.000.000 VND',
  );
  static String get easyReturnsNote => _text(
    'Free size exchange within 14 days',
    'Đổi kích cỡ miễn phí trong vòng 14 ngày',
  );
  static String get securePaymentNote => _text(
    'Secure checkout with sandbox payment',
    'Thanh toán an toàn trong môi trường thử nghiệm',
  );
  static String get resultsFor => _text('Results for', 'Kết quả cho');

  // Product page ----------------------------------------------------------

  static String get productDetailsTitle => _text('Product', 'Sản phẩm');
  static String get selectSize => _text('Select a size', 'Chọn kích cỡ');
  static String get selectSizeFirst =>
      _text('Choose a size to continue', 'Chọn kích cỡ để tiếp tục');
  static String get quantity => _text('Quantity', 'Số lượng');
  static String get quantityShort => _text('Qty', 'SL');
  static String get productOverview => _text('Overview', 'Tổng quan');
  static String get productCare =>
      _text('Care and fit', 'Bảo quản và độ vừa vặn');
  static String get productCareNote => _text(
    'Machine wash cold, dry flat, and wash with similar colours.',
    'Giặt máy bằng nước lạnh, phơi phẳng và giặt cùng màu tương tự.',
  );
  static String get fitGuarantee =>
      _text('BigFit fit guarantee', 'Cam kết vừa vặn BigFit');
  static String get fitGuaranteeNote => _text(
    'Every order includes a free size exchange if the fit is not right.',
    'Mỗi đơn hàng đều được đổi kích cỡ miễn phí nếu sản phẩm không vừa.',
  );
  static String onlyLeft(int quantity) =>
      _text('Only $quantity left', 'Chỉ còn $quantity sản phẩm');
  static String get addToBagAndCheckout =>
      _text('Add to bag and checkout', 'Thêm vào túi và thanh toán');

  // Checkout --------------------------------------------------------------

  static String get checkoutTitle => _text('Checkout', 'Thanh toán');
  static String get stepContact => _text('Contact', 'Liên hệ');
  static String get stepAddress => _text('Address', 'Địa chỉ');
  static String get stepPayment => _text('Payment', 'Thanh toán');
  static String get stepDone => _text('Done', 'Hoàn tất');
  static String get useSavedContact =>
      _text('Use a saved contact', 'Dùng thông tin liên hệ đã lưu');
  static String get newContact => _text('New contact', 'Thông tin liên hệ mới');
  static String get saveAndContinue =>
      _text('Save and continue', 'Lưu và tiếp tục');
  static String get contactSaved =>
      _text('Contact saved', 'Đã lưu thông tin liên hệ');
  static String get noSavedContacts =>
      _text('No saved contacts yet', 'Chưa có thông tin liên hệ nào được lưu');
  static String get deliveryAddressStep =>
      _text('Delivery address', 'Địa chỉ giao hàng');
  static String get dropPinHint => _text(
    'Tap the map to drop a pin on your address, then drag it to fine-tune.',
    'Chạm vào bản đồ để ghim địa chỉ, sau đó kéo ghim để điều chỉnh vị trí.',
  );
  static String get pinPlaced => _text('Pin placed', 'Đã ghim vị trí');
  static String get coordinatesLabel => _text('Coordinates', 'Tọa độ');
  static String get clearPin => _text('Clear pin', 'Xóa ghim');
  static String get orderSummary => _text('Order summary', 'Tóm tắt đơn hàng');
  static String get delivery => _text('Delivery', 'Giao hàng');
  static String get free => _text('Free', 'Miễn phí');
  static String get total => _text('Total', 'Tổng cộng');
  static String get paymentStepTitle =>
      _text('Payment method', 'Phương thức thanh toán');
  static String get sandboxBannerNote => _text(
    'SePay sandbox. You will not be charged.',
    'SePay sandbox. Bạn sẽ không bị tính phí.',
  );
  static String get secureCheckoutTitle =>
      _text('Secure checkout', 'Thanh toán an toàn');
  static String get stylistTab => _text('Stylist', 'Tư vấn');
  static String get processingPayment =>
      _text('Processing payment…', 'Đang xử lý thanh toán…');
  static String get placeOrder => _text('Place order', 'Đặt hàng');
  static String get orderPlacedTitle =>
      _text('Order placed', 'Đặt hàng thành công');
  static String get orderPlacedBody => _text(
    'Your order is confirmed. Track it any time from your order history.',
    'Đơn hàng của bạn đã được xác nhận. Bạn có thể theo dõi bất cứ lúc nào trong lịch sử đơn hàng.',
  );
  static String get orderPlacedCodBody => _text(
    'Your order is placed. Pay the courier when it arrives.',
    'Đơn hàng đã được tạo. Thanh toán cho người giao khi nhận hàng.',
  );
  static String get paymentWaitingBody => _text(
    'SePay has not confirmed this payment yet. Check again in a moment.',
    'SePay chưa xác nhận thanh toán. Hãy kiểm tra lại sau giây lát.',
  );
  static String get bankCodeLabel => _text('Bank code', 'Mã ngân hàng');
  static String get accountNumberLabel =>
      _text('Account number', 'Số tài khoản');
  static String get accountHolderLabel =>
      _text('Account holder', 'Chủ tài khoản');
  static String get transferContentLabel =>
      _text('Transfer content', 'Nội dung chuyển khoản');
  static String get simulateSandboxPayment =>
      _text('Simulate sandbox transfer', 'Mô phỏng giao dịch sandbox');
  static String get waitingForBankHub => _text(
    'Waiting for the Bank Hub sandbox to confirm this transfer.',
    'Đang chờ Bank Hub sandbox xác nhận giao dịch.',
  );
  static String get checkPayment =>
      _text('Check payment', 'Kiểm tra thanh toán');
  static String get trackOrder => _text('Track order', 'Theo dõi đơn hàng');
  static String get continueShopping =>
      _text('Continue shopping', 'Tiếp tục mua sắm');
  static String get paymentDeclinedTitle =>
      _text('Payment declined', 'Thanh toán bị từ chối');
  static String get paymentDeclinedBody => _text(
    'The SePay sandbox did not complete this payment. The order is still open so you can try again.',
    'SePay sandbox chưa hoàn tất thanh toán. Đơn vẫn mở để bạn thử lại.',
  );
  static String get paymentReference => _text('Reference', 'Mã giao dịch');

  // Orders and tracking ----------------------------------------------------

  static String get noOrdersTitle => _text('No orders yet', 'Chưa có đơn hàng');
  static String get noOrdersBody => _text(
    'When you place an order it will appear here with its tracking.',
    'Đơn hàng bạn đặt sẽ xuất hiện tại đây cùng thông tin theo dõi.',
  );
  static String get orderStatusTitle => _text('Status', 'Trạng thái');
  static String get orderRejectionTitle =>
      _text('Order update', 'Cập nhật đơn hàng');
  static String get orderRejectionReason => _text(
    'This order was rejected for the following reason:',
    'Đơn hàng bị từ chối vì lý do sau:',
  );
  static String get orderRejectedHelp => _text(
    'Your payment was not captured. Contact support if you need help.',
    'Thanh toán của bạn chưa được ghi nhận. Hãy liên hệ hỗ trợ nếu cần giúp đỡ.',
  );
  static String get shipmentTracking =>
      _text('Shipment tracking', 'Theo dõi giao hàng');
  static String get stagePlaced => _text('Order placed', 'Đã đặt hàng');
  static String get stageConfirmed => _text('Confirmed', 'Đã xác nhận');
  static String get stagePacked => _text('Packed', 'Đã đóng gói');
  static String get stageShipped => _text('Shipped', 'Đã gửi hàng');
  static String get stageOutForDelivery =>
      _text('Out for delivery', 'Đang giao hàng');
  static String get stageDelivered => _text('Delivered', 'Đã giao hàng');
  static String get trackingNumber => _text('Tracking number', 'Mã vận đơn');
  static String get courier => _text('Courier', 'Đơn vị vận chuyển');
  static String get orderItems => _text('Items', 'Sản phẩm');
  static String get orderPlacedOn => _text('Placed on', 'Ngày đặt');
  static String get shippingTo => _text('Shipping to', 'Giao đến');

  // Staff tools ------------------------------------------------------------

  static String get staffShipmentsTitle =>
      _text('Shipment tracker', 'Theo dõi giao hàng');
  static String get staffShipmentsSubtitle => _text(
    'Live board of every shipment leaving the warehouse',
    'Bảng theo dõi trực tiếp các đơn rời kho',
  );
  static String get advanceStatus =>
      _text('Advance status', 'Chuyển trạng thái');
  static String get markDelivered =>
      _text('Mark delivered', 'Đánh dấu đã giao');
  static String get boardNote => _text(
    'Status updates are saved on the server and customers receive notifications.',
    'Trạng thái được lưu trên server và khách hàng nhận thông báo.',
  );
  static String get showDeliveredOrders =>
      _text('Show delivered orders', 'Hiển thị đơn đã giao');
  static String get fulfillmentAccept => _text('Accept order', 'Tiếp nhận đơn');
  static String get fulfillmentVerifyAndAccept =>
      _text('Verify payment & accept', 'Xác nhận thanh toán và tiếp nhận');
  static String get verifyPaymentPrompt => _text(
    'Confirm that the transfer is visible in the bank account before accepting this order.',
    'Vui lòng xác nhận đã thấy giao dịch trong tài khoản ngân hàng trước khi tiếp nhận đơn.',
  );
  static String get verifyPaymentConfirmation =>
      _text('I verified the payment', 'Tôi đã xác minh thanh toán');
  static String get fulfillmentReject => _text('Reject order', 'Từ chối đơn');
  static String get rejectionDialogTitle =>
      _text('Reject this order?', 'Từ chối đơn hàng này?');
  static String get rejectionReasonLabel =>
      _text('Reason for rejection', 'Lý do từ chối');
  static String get rejectionReasonHint => _text(
    'Explain why this order cannot be fulfilled.',
    'Giải thích lý do không thể xử lý đơn hàng.',
  );
  static String get rejectionReasonRequired =>
      _text('Enter a reason to continue.', 'Nhập lý do để tiếp tục.');
  static String get rejectionReasonTooLong =>
      _text('Use 500 characters or fewer.', 'Dùng tối đa 500 ký tự.');
  static String get confirmRejection =>
      _text('Reject order', 'Từ chối đơn');
  static String get rejectionSuccess =>
      _text('Order rejected and customer notified.', 'Đã từ chối đơn và thông báo khách hàng.');
  static String get acceptUnavailable => _text(
    'Cannot accept: payment is missing or not awaiting verification.',
    'Không thể tiếp nhận: chưa có thanh toán hoặc chưa chờ xác minh.',
  );
  static String get rejectUnavailable => _text(
    'This order cannot be rejected because payment has been completed.',
    'Không thể từ chối vì thanh toán đã hoàn tất.',
  );
  static String get orderActionFailedTitle =>
      _text('Could not update order', 'Không thể cập nhật đơn hàng');
  static String get orderActionFailedHelp => _text(
    'Your order has not been changed. Review the message and try again.',
    'Đơn hàng chưa được thay đổi. Hãy kiểm tra thông báo và thử lại.',
  );
  static String get fulfillmentShip => _text('Mark shipped', 'Đánh dấu đã gửi');
  static String get fulfillmentComplete =>
      _text('Mark delivered', 'Đánh dấu đã giao');
  static String get noShipments =>
      _text('No shipments on the board', 'Không có đơn giao hàng nào');
  static String get customerLabel => _text('Customer', 'Khách hàng');

  // Account page -----------------------------------------------------------

  static String get accountTitle => _text('My account', 'Tài khoản của tôi');
  static String get accountSubtitle => _text(
    'Orders, addresses and account security',
    'Đơn hàng, địa chỉ và bảo mật tài khoản',
  );
  static String get accountOrders => _text('Orders', 'Đơn hàng');
  static String get accountAddresses => _text('Addresses', 'Địa chỉ');
  static String get accountFavorites => _text('Favourites', 'Yêu thích');
  static String get accountNotifications => _text('Notifications', 'Thông báo');
  static String get accountStylist => _text('AI stylist', 'Tư vấn AI');
  static String get accountSecurity =>
      _text('Account security', 'Bảo mật tài khoản');
  static String get accountStaff => _text('Staff tools', 'Công cụ nhân viên');
  static String get accountOverview => _text('Overview', 'Tổng quan');
  static String get signOutAction => _text('Sign out', 'Đăng xuất');
  static String get signedInAs => _text('Signed in as', 'Đang đăng nhập với');

  // Placeholders ----------------------------------------------------------

  static String get notImplementedLabel =>
      _text('NOT IMPLEMENTED', 'CHƯA TRIỂN KHAI');
  static String get notImplementedNotice => _text(
    'This feature is scheduled for a later module.',
    'Tính năng này sẽ được bổ sung trong mô-đun sau.',
  );
  static String get paymentResultTitle =>
      _text('Payment result', 'Kết quả thanh toán');
  static String get paymentResultSubtitle => _text(
    'Success and failure states after a provider callback',
    'Trạng thái thành công hoặc thất bại sau phản hồi từ nhà cung cấp',
  );

  // Errors ----------------------------------------------------------------

  static String get errorRequestFailed => _text(
    'The request failed. Please try again.',
    'Yêu cầu thất bại. Vui lòng thử lại.',
  );
  static String get checkoutFailureTitle =>
      _text('Could not place your order', 'Không thể đặt hàng');
  static String get checkoutFailureHelp => _text(
    'Your order was not completed. Review the message and try again.',
    'Đơn hàng chưa hoàn tất. Hãy xem thông báo và thử lại.',
  );
  static String get bankTransferUnavailableTitle =>
      _text('Bank transfer is unavailable', 'Chuyển khoản chưa khả dụng');
  static String get bankTransferUnavailableHelp => _text(
    'Your order is saved. Try bank transfer again or switch to cash on delivery.',
    'Đơn hàng đã được lưu. Hãy thử lại hoặc chuyển sang thanh toán khi nhận hàng.',
  );
  static String get reviewCartHelp => _text(
    'Stock changed while you were checking out. Review your bag and adjust the unavailable items.',
    'Tồn kho đã thay đổi trong lúc thanh toán. Hãy kiểm tra túi hàng và điều chỉnh sản phẩm đã hết.',
  );
  static String get switchToCod =>
      _text('Switch to cash on delivery', 'Chuyển sang thanh toán khi nhận hàng');
  static String get backToBag =>
      _text('Review bag', 'Kiểm tra túi hàng');
  static String get errorSession => _text(
    'Could not read the saved sign-in session.',
    'Không thể đọc phiên đăng nhập đã lưu.',
  );
  static String get errorStoreApi => _text(
    'Could not reach the BigFit store API. Check the server and API_BASE_URL.',
    'Không thể kết nối API cửa hàng BigFit. Hãy kiểm tra máy chủ và API_BASE_URL.',
  );
  static String get errorLoadMore =>
      _text('Could not load more products.', 'Không thể tải thêm sản phẩm.');
  static String get errorLoadBag =>
      _text('Could not load your bag.', 'Không thể tải túi hàng.');
  static String get errorAddToBag => _text(
    'Could not add this item to your bag.',
    'Không thể thêm sản phẩm này vào túi hàng.',
  );
  static String get errorSaveFavorite => _text(
    'Could not save this favorite.',
    'Không thể lưu sản phẩm yêu thích này.',
  );
  static String get errorSignIn => _text(
    'Could not sign in. Check your connection and try again.',
    'Không thể đăng nhập. Hãy kiểm tra kết nối và thử lại.',
  );
  static String get errorLoadAddresses =>
      _text('Could not load addresses.', 'Không thể tải địa chỉ.');
  static String get errorSaveAddress =>
      _text('Could not save the address.', 'Không thể lưu địa chỉ.');
  static String get errorDeleteAddress =>
      _text('Could not delete the address.', 'Không thể xóa địa chỉ.');
  static String get invalidBaseUrl => _text(
    'Enter a valid HTTP or HTTPS API base URL.',
    'Nhập URL API hợp lệ bắt đầu bằng HTTP hoặc HTTPS.',
  );

  // Tooltips --------------------------------------------------------------

  static String get tooltipChooseServer =>
      _text('Choose API server', 'Chọn máy chủ API');
  static String get tooltipSearch => _text('Search', 'Tìm kiếm');
  static String get tooltipDeleteAddress =>
      _text('Delete address', 'Xóa địa chỉ');
  static String get tooltipDeleteNotification =>
      _text('Delete notification', 'Xóa thông báo');
  static String get tooltipRemoveItem => _text('Remove item', 'Xóa sản phẩm');

  // Storefront and cart copy ----------------------------------------------

  static String get heroBrandCaption => 'BIGFIT / STREETWEAR';
  static String get heroFindYourFit =>
      _text('FIND\nYOUR FIT.', 'TÌM PHONG CÁCH CỦA BẠN.');
  static String get heroStreetwearCaption => _text(
    'EVERYDAY STREETWEAR.\nMADE TO BE YOURS.',
    'THỜI TRANG HẰNG NGÀY.\nDÀNH RIÊNG CHO BẠN.',
  );
  static String get cartItemsHeading => _text('ITEMS', 'MÓN HÀNG');
  static String get cartSelectionHeading =>
      _text('YOUR SELECTION', 'SẢN PHẨM ĐÃ CHỌN');
  static String get cartEmptyHeading =>
      _text('YOUR BAG IS EMPTY', 'TÚI HÀNG ĐANG TRỐNG');
  static String get cartContinueShopping =>
      _text('CONTINUE SHOPPING', 'TIẾP TỤC MUA SẮM');
  static String get cartTotalHeading => _text('TOTAL', 'TỔNG CỘNG');
  static String get cartOrderSummaryHeading =>
      _text('ORDER SUMMARY', 'TÓM TẮT ĐƠN HÀNG');
  static String get categoryAll => _text('ALL', 'TẤT CẢ');
  static String get productViewAction => _text('VIEW PRODUCT', 'XEM SẢN PHẨM');
  static String get mapTapToPlacePin =>
      _text('Tap to place a pin', 'Chạm để ghim vị trí');
  static String get showPassword => _text('Show password', 'Hiện mật khẩu');
  static String get hidePassword => _text('Hide password', 'Ẩn mật khẩu');
  static String get footerStreetwear =>
      _text('EVERYDAY STREETWEAR.', 'THỜI TRANG HẰNG NGÀY.');
  static String get footerAboutHeading => _text('ABOUT BIGFIT', 'VỀ BIGFIT');
  static String get footerAboutBody => _text(
    'BIGFIT is a streetwear store focused on comfort, confidence, and '
        'personal style.\n\nWe aim to offer products that suit a wide '
        'range of body types and personalities.',
    'BIGFIT là cửa hàng thời trang streetwear hướng đến sự thoải mái, '
        'tự tin và phong cách riêng.\n\nChúng tôi mong muốn mang đến '
        'những sản phẩm phù hợp với nhiều vóc dáng và cá tính khác nhau.',
  );
  static String get footerExchangeHeading =>
      _text('EXCHANGE POLICY', 'CHÍNH SÁCH ĐỔI HÀNG');
  static String get footerExchangeConditions =>
      _text('EXCHANGE CONDITIONS', 'ĐIỀU KIỆN ĐỔI HÀNG');
  static String get footerExchangeRequirements => _text(
    '• Items must have their original tags and labels.\n'
        '• Items must be unused.\n'
        '• Items must not be damaged.\n'
        '• Provide your order details when requesting an exchange.',
    '• Sản phẩm còn nguyên tem, nhãn.\n'
        '• Sản phẩm chưa qua sử dụng.\n'
        '• Sản phẩm không bị hư hỏng.\n'
        '• Cung cấp thông tin đơn hàng khi yêu cầu đổi.',
  );
  static String get footerExchangeHowTo =>
      _text('HOW TO EXCHANGE', 'CÁCH ĐỔI HÀNG');
  static String get footerExchangeInstructions => _text(
    'Contact BIGFIT with your order number, the item you want to exchange, '
        'and the reason for the exchange.',
    'Liên hệ BIGFIT và cung cấp mã đơn hàng, sản phẩm cần đổi cùng lý do '
        'đổi hàng.',
  );
  static String get footerExchangeDisclaimer => _text(
    'The exchange period and shipping costs are confirmed according to '
        'the store’s current policy.',
    'Thời hạn đổi hàng và chi phí vận chuyển được xác nhận theo chính '
        'sách thực tế của cửa hàng.',
  );
  static String get footerCopyright => '© BIGFIT. All rights reserved.';
  // Builders --------------------------------------------------------------
  //
  // Strings that depend on runtime data. Each one is named after the text it
  // produces so the call site reads like the sentence it shows.

  static String roleLabel(String roles) =>
      _text('Role: $roles', 'Vai trò: $roles');

  static String currentApi(String url) =>
      _text('Current API: $url', 'API hiện tại: $url');

  static String connectedTo(String url) =>
      _text('Connected to $url', 'Đã kết nối tới $url');

  static String changeServerFailed(Object error) => _text(
    'Could not change the API server: $error',
    'Không thể đổi máy chủ API: $error',
  );

  static String productCountLabel(int shown, int total) =>
      _text('$shown of $total products', '$shown / $total sản phẩm');

  static String shoppingBagTooltip(int count) =>
      _text('Shopping bag ($count)', 'Túi hàng ($count)');

  static String discountBadge(int? percent) =>
      _text('${percent ?? 0}% OFF', 'GIẢM ${percent ?? 0}%');

  static String discountText(int? percent) =>
      _text('${percent ?? 0}% off', 'Giảm ${percent ?? 0}%');

  static String addedToBag(String productName, String size) => _text(
    '$productName · $size added to bag',
    'Đã thêm $productName · $size vào túi hàng',
  );

  static String orderCreated(String orderNumber) => _text(
    'Order $orderNumber created. Payment is pending integration.',
    'Đã tạo đơn hàng $orderNumber. Thanh toán chưa được tích hợp.',
  );

  static String requestFailedWithStatus(int statusCode) =>
      _text('Request failed ($statusCode).', 'Yêu cầu thất bại ($statusCode).');

  static String addressTitle(String label, bool isDefault) =>
      isDefault ? _text('$label · Default', '$label · Mặc định') : label;

  static String addressSummary(
    String recipient,
    String phone,
    String address,
  ) => '$recipient · $phone\n$address';

  static String addressOptionLabel(String label, String address) =>
      '$label · $address';

  static String variantSummary(String size, String color) => '$size · $color';

  static String orderItemSummary(String size, String color, int quantity) =>
      '$size · $color × $quantity';

  static String orderStatusLine(String status, String date) =>
      '${orderStatus(status)} · $date';

  static String orderStatus(String status) => switch (status.toLowerCase()) {
    'pending' => _text('Pending', 'Đang chờ xử lý'),
    'confirmed' => stageConfirmed,
    'processing' => _text('Processing', 'Đang xử lý'),
    'shipped' => stageShipped,
    'outfordelivery' => stageOutForDelivery,
    'delivered' => stageDelivered,
    'cancelled' => _text('Cancelled', 'Đã hủy'),
    _ => status,
  };

  static String categoryLabel(String category) => switch (category) {
    'Bottoms' => _text('Bottoms', 'Quần'),
    'Casualwear' => _text('Casualwear', 'Đồ thường ngày'),
    'Dresses & Skirts' => _text('Dresses & Skirts', 'Váy và chân váy'),
    'Innerwear' => _text('Innerwear', 'Đồ mặc trong'),
    'Knitwear' => _text('Knitwear', 'Đồ dệt kim'),
    'Outerwear' => _text('Outerwear', 'Áo khoác'),
    'Shirts' => _text('Shirts', 'Áo sơ mi'),
    _ => category,
  };

  static String paymentMethodName(String method) => switch (method) {
    'cod' => paymentCod,
    'bankTransfer' => paymentBank,
    'gateway' => paymentGateway,
    _ => method,
  };

  static String notificationSubtitle(String message, String date) =>
      '$message\n$date';

  static String descriptionWithStatus(String description, String status) =>
      '$description\n$status';
}
