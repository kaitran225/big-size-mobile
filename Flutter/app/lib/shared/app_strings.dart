/// Every user-facing string in the BigFit app.
///
/// How to read this file:
///
///   * One constant per **distinct** string. Two constants never hold the
///     same value, so the value is always a reliable way to find the name.
///   * The name predicts the role of the string:
///     - `error...` / `...Failed`  failure messages
///     - `...Title`                screen or card titles
///     - `...Empty`                "nothing here yet" messages
///     - `...Hint`                 input hints
///     - `...Label`                field and option labels
///     - `...Subtitle` / `...Description` / `...Message` / `...Note`
///                                supporting copy
///     - `tooltip...`              icon button tooltips
///   * Constants are grouped by the screen that shows them, so a string is
///     found by going to its feature and scanning the group.
///   * The last group holds the builders for strings that depend on runtime
///     data. They read as sentences and are named after what they produce.
abstract final class AppStrings {
  // App -------------------------------------------------------------------

  /// Platform application title, in sentence case.
  static const String appTitle = 'BigFit';

  /// Storefront wordmark, in caps.
  static const String brandName = 'BIGFIT';

  // Actions ---------------------------------------------------------------

  static const String cancel = 'Cancel';
  static const String save = 'Save';
  static const String continueAction = 'Continue';
  static const String later = 'Later';
  static const String tryAgain = 'Try again';
  static const String refresh = 'Refresh';
  static const String required = 'Required';

  // Storefront ------------------------------------------------------------

  static const String heroTitle = 'Clothing that fits';
  static const String heroSubtitle = 'Explore the BigFit collection';
  static const String collectionHeading = 'THE COLLECTION';
  static const String onSaleHeading = 'ON SALE';
  static const String womenSegment = 'WOMEN';
  static const String menSegment = 'MEN';
  static const String searchHint = 'Search clothes, styles, and sizes';
  static const String filterAll = 'All';
  static const String filterOnSale = 'On sale';
  static const String filterInStock = 'In stock';
  static const String sortName = 'Name';
  static const String sortPriceAsc = 'Price ↑';
  static const String sortPriceDesc = 'Price ↓';
  static const String sortNewest = 'Newest';
  static const String loadMore = 'Load more';
  static const String catalogEmptyTitle =
      'Your next favourite fit is on its way.';
  static const String catalogEmptySubtitle =
      'The cleaned catalogue is ready for review. Products will appear here '
      'after you approve and import the CSV.';
  static const String navShop = 'Shop';
  static const String navSale = 'Sale';
  static const String navMore = 'More';

  // Store connection ------------------------------------------------------

  static const String storeConnectionTitle = 'Store connection';
  static const String renderDeployment = 'Render deployment';
  static const String localDevelopmentServer = 'Local development server';
  static const String apiPathNote =
      'The API path is added automatically. Changing servers signs you out so '
      'credentials are not reused on another server.';

  // Account sheet ---------------------------------------------------------

  static const String ordersTitle = 'Orders';
  static const String favoritesTitle = 'Favorites';
  static const String addressesTitle = 'Addresses';
  static const String notificationsTitle = 'Notifications';
  static const String aiStylist = 'AI stylist';
  static const String moreFeatures = 'More features';
  static const String signOut = 'Sign out';
  static const String signIn = 'Sign in';
  static const String account = 'Account';

  // Authentication --------------------------------------------------------

  static const String joinBigFit = 'Join BigFit';
  static const String welcomeBack = 'Welcome back';
  static const String registerSubtitle =
      'Create a customer account to get started.';
  static const String loginSubtitle = 'Sign in with your BigFit account.';
  static const String displayName = 'Display name';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String passwordPolicyHint =
      'Use 12+ characters with uppercase, lowercase, number, and symbol.';
  static const String createAccount = 'Create customer account';
  static const String switchToSignIn = 'Already have an account? Sign in';
  static const String switchToRegister = 'New to BigFit? Create an account';
  static const String validationDisplayName = 'Enter at least 2 characters.';
  static const String validationEmail = 'Enter a valid email address.';
  static const String validationPasswordLength = 'Use at least 12 characters.';
  static const String validationPasswordRequired = 'Enter your password.';

  // Product ---------------------------------------------------------------

  static const String soldOut = 'SOLD OUT';
  static const String sizeAndColour = 'Size & colour';
  static const String currentlyUnavailable = 'Currently unavailable';
  static const String addToBag = 'Add to bag';
  static const String addToFavorites = 'Add to favorites';

  // Cart and checkout -----------------------------------------------------

  static const String shoppingBagTitle = 'Shopping bag';
  static const String bagEmpty = 'Your bag is empty.';
  static const String subtotal = 'Subtotal';
  static const String pleaseWait = 'Please wait…';
  static const String continueToOrder = 'Continue to order';
  static const String addressNeededTitle = 'Delivery address needed';
  static const String addressNeededMessage =
      'Add a delivery address before creating your order.';
  static const String addAddress = 'Add address';
  static const String reviewOrderTitle = 'Review your order';
  static const String deliveryAddress = 'Delivery address';
  static const String orderOnlyNotice =
      'This creates an order only. Online payment is not connected to the '
      'backend yet.';
  static const String createOrder = 'Create order';

  // Favorites -------------------------------------------------------------

  static const String favoritesEmpty = 'No favorites saved yet.';
  static const String addedToFavorites = 'Added to your favorites.';

  // Orders ----------------------------------------------------------------

  static const String orderHistoryTitle = 'Order history';
  static const String ordersEmpty = 'No orders yet.';

  // Addresses -------------------------------------------------------------

  static const String deliveryAddressesTitle = 'Delivery addresses';
  static const String addressesEmpty = 'No delivery addresses saved yet.';
  static const String mapSdkNotice =
      'Map SDK is not configured. You can save optional coordinates '
      'manually; saved locations are sent to the backend.';
  static const String editAddressTitle = 'Edit address';
  static const String defaultAddressLabel = 'Home';
  static const String defaultCountryCode = 'VN';
  static const String setAsDefault = 'Set as default';
  static const String fieldAddressLabel = 'Address label';
  static const String fieldRecipientName = 'Recipient name';
  static const String fieldPhoneNumber = 'Phone number';
  static const String fieldAddressLine = 'Street address';
  static const String fieldCity = 'City';
  static const String fieldProvince = 'Province / state';
  static const String fieldPostalCode = 'Postal code';
  static const String fieldCountryCode = 'Country code (2 letters)';
  static const String fieldLatitude = 'Latitude (optional)';
  static const String fieldLongitude = 'Longitude (optional)';

  // Notifications ---------------------------------------------------------

  static const String pushNotConnectedNotice =
      'Live push updates are not connected yet';
  static const String notificationsEmpty = 'You are all caught up.';

  // Assistant -------------------------------------------------------------

  static const String assistantTitle = 'BigFit AI stylist';
  static const String assistantSubtitle =
      'Ask about catalogue items, prices, availability, or size guidance.';
  static const String assistantEmpty = 'How can I help you find your fit?';
  static const String assistantInputHint = 'Ask your stylist…';

  // Payment ---------------------------------------------------------------

  static const String paymentTitle = 'Payment';
  static const String choosePaymentMethod = 'Choose a payment method';
  static const String paymentTotalNote =
      'Your order total will appear here at checkout.';
  static const String paymentCod = 'Cash on delivery';
  static const String paymentCodSubtitle = 'Pay when your order arrives';
  static const String paymentBank = 'Bank transfer';
  static const String paymentBankSubtitle =
      'Transfer instructions will be shown at checkout';
  static const String paymentGateway = 'VNPay / MoMo';
  static const String paymentGatewaySubtitle =
      'Sandbox integration is not configured';
  static const String paymentFrameNotice =
      'This is a UI frame. No payment is created or charged until a backend '
      'payment API and provider sandbox are connected.';
  static const String paymentPreviewSnack =
      'Preview only: payment processing is not connected.';

  // Map -------------------------------------------------------------------

  static const String mapTitle = 'Choose delivery location';
  static const String mapSearchHint = 'Search for an address';
  static const String demoLocation = 'BigFit demo location';
  static const String mapPreviewNotice =
      'Map preview only. Add a Maps SDK key to enable live maps and device '
      'location.';
  static const String selectedLocation = 'Selected location';
  static const String useThisLocation = 'Use this location';

  // Profile ---------------------------------------------------------------

  static const String profileTitle = 'My profile';
  static const String avatarFallback = 'B';
  static const String guest = 'Guest';
  static const String signInToSaveProfile = 'Sign in to save your profile';
  static const String accountType = 'Account type';
  static const String customerProfile = 'Customer profile';
  static const String fitPreferences = 'Fit preferences';
  static const String fitPreferencesValue = 'Sizes M–XXL · Not set';
  static const String myReviews = 'My reviews';
  static const String reviewsNotConnected =
      'Review management API is not connected';
  static const String profileFrameNote =
      'Profile editing and size preferences are shown as a frame. The current '
      'backend does not expose profile update or review endpoints.';

  // Account security ------------------------------------------------------

  static const String securityTitle = 'Account security';
  static const String securityHeadline = 'Protect your BigFit account';
  static const String securityIntro =
      'These flows are ready for email and OTP service wiring.';
  static const String verifyEmail = 'Verify your email';
  static const String verifyEmailDescription =
      'Confirm your email address with a one-time link.';
  static const String emailServicePending = 'Email service pending';
  static const String resetPassword = 'Reset password';
  static const String resetPasswordDescription =
      'Request a secure password reset email.';
  static const String resetApiPending = 'Reset API pending';
  static const String otpTitle = 'One-time passcode';
  static const String otpDescription =
      'Enter a time-limited code sent to your email.';
  static const String otpApiPending = 'OTP API pending';
  static const String securityPreviewNotice =
      'UI preview only. Email delivery, OTP verification, retry limits, and '
      'password reset are not active.';

  // Feature hub -----------------------------------------------------------

  static const String featureHubTitle = 'More from BigFit';
  static const String yourAccount = 'Your account';
  static const String profileAndFit = 'Profile & fit preferences';
  static const String profileAndFitPreview =
      'Preview account details and fit preferences';
  static const String profileAndFitSignedIn =
      'Personal details, sizes, and reviews';
  static const String deliveryMap = 'Delivery map';
  static const String paymentMethods = 'Payment methods';
  static const String paymentMethodsSubtitle =
      'COD, bank transfer, and gateway preview';
  static const String accountSecuritySubtitle =
      'Email verification, reset, and OTP';
  static const String storeTools = 'Store tools';
  static const String storeToolsSubtitle =
      'Products, inventory, orders, and reviews';

  // Store management ------------------------------------------------------

  static const String storeManagementTitle = 'Store management';
  static const String managementOverview = 'Management overview';
  static const String productsAndInventory = 'Products & inventory';
  static const String productsAndInventoryDetail =
      'Manage catalogue items, variants, and stock.';
  static const String ordersDetail =
      'Review orders and update fulfilment status.';
  static const String customerReviews = 'Customer reviews';
  static const String customerReviewsDetail = 'Moderate product feedback.';
  static const String managementNotConnected =
      'Management endpoints are not connected. This screen does not change '
      'store data.';
  static const String storeManagementRestricted =
      'Store management is available to Admin and Store Staff accounts.';

  // Errors ----------------------------------------------------------------

  static const String errorRequestFailed =
      'The request failed. Please try again.';
  static const String errorSession =
      'Could not read the saved sign-in session.';
  static const String errorStoreApi =
      'Could not reach the BigFit store API. Check the server and API_BASE_URL.';
  static const String errorLoadMore = 'Could not load more products.';
  static const String errorLoadBag = 'Could not load your bag.';
  static const String errorAddToBag = 'Could not add this item to your bag.';
  static const String errorSaveFavorite = 'Could not save this favorite.';
  static const String errorSignIn =
      'Could not sign in. Check your connection and try again.';
  static const String errorLoadAddresses = 'Could not load addresses.';
  static const String errorSaveAddress = 'Could not save the address.';
  static const String errorDeleteAddress = 'Could not delete the address.';
  static const String invalidBaseUrl =
      'Enter a valid HTTP or HTTPS API base URL.';

  // Tooltips --------------------------------------------------------------

  static const String tooltipChooseServer = 'Choose API server';
  static const String tooltipSearch = 'Search';
  static const String tooltipDeleteAddress = 'Delete address';
  static const String tooltipDeleteNotification = 'Delete notification';
  static const String tooltipRemoveItem = 'Remove item';

  // Builders --------------------------------------------------------------
  //
  // Strings that depend on runtime data. Each one is named after the text it
  // produces so the call site reads like the sentence it shows.

  static String roleLabel(String roles) => 'Role: $roles';

  static String currentApi(String url) => 'Current API: $url';

  static String connectedTo(String url) => 'Connected to $url';

  static String changeServerFailed(Object error) =>
      'Could not change the API server: $error';

  static String productCountLabel(int shown, int total) =>
      '$shown of $total products';

  static String shoppingBagTooltip(int count) => 'Shopping bag ($count)';

  static String discountBadge(int? percent) => '${percent ?? 0}% OFF';

  static String discountText(int? percent) => '${percent ?? 0}% off';

  static String addedToBag(String productName, String size) =>
      '$productName · $size added to bag';

  static String orderCreated(String orderNumber) =>
      'Order $orderNumber created. Payment is pending integration.';

  static String requestFailedWithStatus(int statusCode) =>
      'Request failed ($statusCode).';

  static String addressTitle(String label, bool isDefault) =>
      isDefault ? '$label · Default' : label;

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
      '$status · $date';

  static String notificationSubtitle(String message, String date) =>
      '$message\n$date';

  static String descriptionWithStatus(String description, String status) =>
      '$description\n$status';
}
