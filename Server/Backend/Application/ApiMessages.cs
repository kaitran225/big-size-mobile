namespace BigFit.Application.Abstractions;

/// <summary>
/// Every message the BigFit API sends to a client, writes to a log, or
/// reports at startup, together with the OpenAPI documentation text it
/// publishes.
/// </summary>
/// <remarks>
/// <para>How to read this file:</para>
/// <list type="bullet">
/// <item><description>One constant per distinct string.</description></item>
/// <item><description>
/// The name predicts the role:
/// <c>...Title</c> and <c>...Detail</c> for ProblemDetails, <c>error...</c>
/// for failures, <c>...Log</c> for log templates, <c>Summary...</c> and
/// <c>Description...</c> for OpenAPI text.
/// </description></item>
/// <item><description>Grouped by the feature that owns the message.</description></item>
/// </list>
/// <para>
/// Strings that are not messages stay with their code: route templates,
/// OpenAPI operation ids, JSON property names, database identifiers,
/// configuration keys, and the Swagger UI document.
/// </para>
/// </remarks>
public static class ApiMessages
{
    // ---------------------------------------------------------------------
    // Problem titles and details
    // ---------------------------------------------------------------------

    public const string InvalidRequestTitle = "Invalid request";
    public const string DataConflictTitle = "Data conflict";
    public const string UnexpectedErrorTitle = "An unexpected error occurred";
    public const string InvalidRequestBodyDetail =
        "The request body is missing or contains invalid JSON.";
    public const string UnexpectedErrorDetail =
        "The server could not complete the request.";

    // ---------------------------------------------------------------------
    // Product query validation
    // ---------------------------------------------------------------------

    public const string InvalidPaginationTitle = "Invalid pagination";
    public const string InvalidPaginationDetail =
        "Page must be at least 1 and pageSize must be between 1 and 100.";
    public const string UnsupportedSortOrderTitle = "Unsupported sort order";
    public const string UnsupportedSortOrderDetail =
        "sortBy must be name, price_asc, price_desc, or newest.";
    public const string UnsupportedGenderTitle = "Unsupported gender";
    public const string UnsupportedGenderDetail =
        "gender must be Men, Women, or Unisex.";

    // ---------------------------------------------------------------------
    // Categories
    // ---------------------------------------------------------------------

    public const string CategoryContainsProductsTitle = "Category contains products";
    public const string CategoryContainsProductsDetail =
        "Move or delete the category's products before deleting this category.";

    // ---------------------------------------------------------------------
    // Catalogue
    // ---------------------------------------------------------------------

    public const string SalePriceOutOfRange =
        "SalePrice must be greater than zero and lower than Price.";
    public const string DuplicateCategoryOrVariant =
        "The category name or variant SKU/size/color combination already exists.";

    // ---------------------------------------------------------------------
    // Shopping
    // ---------------------------------------------------------------------

    public const string VariantNotFound =
        "Product variant was not found or is inactive.";
    public const string QuantityExceedsStock =
        "Requested quantity exceeds available stock.";
    public const string CartEmpty = "The cart is empty.";
    public const string AddressNotOwned =
        "Shipping address does not belong to the current user.";
    public const string MixedCurrencies =
        "A single order cannot contain products in different currencies.";
    public const string StockChangedDuringOrder =
        "Product stock changed while placing the order. Refresh the cart and try again.";

    // ---------------------------------------------------------------------
    // Addresses
    // ---------------------------------------------------------------------

    public const string CoordinatesRequiredTogether =
        "Latitude and longitude must be provided together.";

    // ---------------------------------------------------------------------
    // Notifications
    // ---------------------------------------------------------------------

    public const string InvalidNotificationData =
        "DataJson must contain valid JSON.";

    // ---------------------------------------------------------------------
    // Authentication
    // ---------------------------------------------------------------------

    public const string AccountAlreadyExistsTitle = "Account already exists";
    public const string AccountCreationFailedTitle = "Account could not be created";
    public const string AuthenticatedTokenWithoutUserId =
        "Authenticated token does not contain a valid user identifier.";

    // ---------------------------------------------------------------------
    // Health
    // ---------------------------------------------------------------------

    public const string DatabaseHealthy = "healthy";
    public const string DatabaseUnavailableTitle = "Database unavailable";
    public const string DatabaseUnavailableDetail =
        "The database health check could not connect to PostgreSQL.";

    // ---------------------------------------------------------------------
    // Startup and configuration
    // ---------------------------------------------------------------------

    public const string DatabaseConnectionNotConfigured =
        "Database connection is not configured. Set ConnectionStrings:Default using .NET user-secrets or an environment variable.";
    public const string JwtSigningKeyNotConfigured =
        "Auth:Jwt:SigningKey must be configured as a secret of at least 32 UTF-8 bytes.";
    public const string JwtIssuerAudienceNotConfigured =
        "Auth:Jwt:Issuer and Auth:Jwt:Audience must be configured.";
    public const string PostgresUrlMissingCredentials =
        "The PostgreSQL URL must include a username, password, and database name.";
    public const string PostgresUrlRequiresSsl =
        "The PostgreSQL URL must use sslmode=require.";

    // ---------------------------------------------------------------------
    // Bootstrap administrator
    // ---------------------------------------------------------------------

    public const string BootstrapAdminDisplayName = "BigFit Administrator";
    public const string BootstrapCredentialsMustBePaired =
        "Both Auth:BootstrapAdmin:Email and Auth:BootstrapAdmin:Password must be configured together.";
    public const string BootstrapEmailBelongsToNonAdmin =
        "The configured bootstrap administrator email already belongs to a non-admin user. Choose a dedicated bootstrap email.";

    // ---------------------------------------------------------------------
    // Logging
    // ---------------------------------------------------------------------

    public const string ApiRequestFailedLog =
        "API request failed with status {StatusCode}.";
    public const string DatabaseHealthCheckFailedLog =
        "PostgreSQL health check failed.";
    public const string BootstrapAdminCreatedLog =
        "Created configured bootstrap administrator {Email}.";

    // ---------------------------------------------------------------------
    // OpenAPI tags
    // ---------------------------------------------------------------------

    public const string TagAuthentication = "Authentication";
    public const string TagAdministration = "Administration";
    public const string TagProducts = "Products";
    public const string TagProductVariants = "Product variants";
    public const string TagCategories = "Categories";
    public const string TagShoppingCart = "Shopping cart";
    public const string TagFavorites = "Favorites";
    public const string TagOrders = "Orders";
    public const string TagDeliveryAddresses = "Delivery addresses";
    public const string TagNotifications = "Notifications";
    public const string TagAssistant = "AI assistant";

    // ---------------------------------------------------------------------
    // OpenAPI summaries
    // ---------------------------------------------------------------------

    public const string SummaryRegisterCustomer = "Register a customer account";
    public const string SummaryLogin = "Sign in and receive a JWT access token";
    public const string SummaryCreateStoreStaff = "Create a store staff account";
    public const string SummaryGetProducts = "List and filter catalogue products";
    public const string SummaryGetProduct = "Get a product and its variants by ID";
    public const string SummaryCreateProduct =
        "Create a product with size/color variants and optional sale price";
    public const string SummaryUpdateProduct = "Replace a product and its variants";
    public const string SummaryDeleteProduct = "Delete a product";
    public const string SummaryGetProductVariant = "Get a product variant";
    public const string SummaryCreateProductVariant =
        "Add a size/color variant to a product";
    public const string SummaryUpdateProductVariant =
        "Update variant details and stock quantity";
    public const string SummaryDeleteProductVariant = "Delete a product variant";
    public const string SummaryGetCategories = "List product categories";
    public const string SummaryGetCategory = "Get a category by ID";
    public const string SummaryCreateCategory = "Create a category";
    public const string SummaryUpdateCategory = "Replace a category";
    public const string SummaryDeleteCategory =
        "Delete a category that has no products";
    public const string SummaryGetMyCart = "Get the current user's cart";
    public const string SummaryAddMyCartItem =
        "Add a product variant to the current user's cart";
    public const string SummaryUpdateMyCartItem =
        "Replace the quantity of one of the current user's cart items";
    public const string SummaryRemoveMyCartItem =
        "Remove one of the current user's cart items";
    public const string SummaryGetMyFavorites =
        "List favorite products for the current user";
    public const string SummaryAddMyFavorite =
        "Add an active product to the current user's favorites";
    public const string SummaryRemoveMyFavorite =
        "Remove a product from the current user's favorites";
    public const string SummaryGetMyOrders = "List orders belonging to the current user";
    public const string SummaryGetMyOrder = "Get one order belonging to the current user";
    public const string SummaryCreateMyOrder = "Create an order from the current user's cart";
    public const string SummaryGetMyAddresses =
        "List delivery addresses belonging to the current user";
    public const string SummaryCreateMyAddress =
        "Save a delivery address and optional map coordinates";
    public const string SummaryUpdateMyAddress =
        "Update a delivery address belonging to the current user";
    public const string SummaryDeleteMyAddress =
        "Delete a delivery address belonging to the current user";
    public const string SummaryGetMyNotifications =
        "List notifications belonging to the current user";
    public const string SummaryCreateMyNotification =
        "Create a notification for the current user";
    public const string SummaryMarkMyNotificationRead =
        "Mark one of the current user's notifications as read";
    public const string SummaryDeleteMyNotification =
        "Delete one of the current user's notifications";
    public const string SummaryGetDatabaseHealth = "Check PostgreSQL connectivity";
    public const string SummaryAskAssistant = "Hỏi đáp tư vấn thời trang & size BigFit";

    // ---------------------------------------------------------------------
    // OpenAPI descriptions
    // ---------------------------------------------------------------------

    public const string DescriptionGetProducts =
        "Supports text search, gender, category, size, color, sale, stock, sorting, and pagination.";
    public const string DescriptionCreateMyOrder =
        "Uses current sale prices, snapshots item details, and decrements stock transactionally.";
    public const string DescriptionBearerSecurityScheme =
        "Paste the access token returned by /api/auth/login. Swagger UI sends it as a Bearer header.";
    public const string DescriptionAskAssistant =
        "Nhận câu hỏi từ khách hàng, kết hợp bảng size, chính sách và danh mục BigFit để AI tư vấn.";

    // ---------------------------------------------------------------------
    // AI Assistant
    // ---------------------------------------------------------------------

    public const string AssistantUnavailableTitle = "Trợ lý AI tạm thời gián đoạn";
    public const string AssistantNotConfigured =
        "Trợ lý AI chưa được cấu hình API key. Vui lòng kiểm tra cấu hình nhà cung cấp.";
    public const string AssistantProviderRequestFailed =
        "Không thể hoàn thành yêu cầu đến nhà cung cấp AI.";
    public const string AssistantProviderEmptyResponse =
        "Nhà cung cấp AI phản hồi rỗng.";
    public const string AssistantProviderUnavailable =
        "Dịch vụ AI đang tạm thời gián đoạn. Vui lòng thử lại sau ít phút.";
    public const string AssistantProviderTimedOut =
        "Yêu cầu đến dịch vụ AI đã hết thời gian chờ.";
    public const string AssistantProviderInvalidResponse =
        "Phản hồi từ dịch vụ AI không hợp lệ.";

    public const string AssistantProviderErrorStatusLog =
        "Configured AI provider returned HTTP {StatusCode}. Details: {Details}";
    public const string AssistantProviderUnreachableLog =
        "Could not reach the configured AI provider.";
    public const string AssistantProviderTimeoutLog =
        "The configured AI provider timed out.";

    public const string AssistantOutOfScopeFallback =
        "Dạ, em là AI Stylist chuyên về thời trang Big Size của BigFit ạ. Em chỉ có thể hỗ trợ bạn về tư vấn chọn size, gợi ý phối đồ cho người ngoại cỡ và các sản phẩm, chính sách của BigFit thôi ạ. Bạn có muốn em tư vấn trang phục Big Size nào cho bạn không ạ? 😊";

    public const string AssistantSizeGuideFallback =
        "Dạ chào bạn! Để chọn size BigFit chuẩn nhất cho vóc dáng:\n\n" +
        "• **Size L**: 65kg - 75kg (Cao 1m65 - 1m72)\n" +
        "• **Size XL**: 75kg - 85kg (Cao 1m70 - 1m78)\n" +
        "• **Size 2XL (XXL)**: 85kg - 95kg (Cao 1m72 - 1m82)\n" +
        "• **Size 3XL**: 95kg - 110kg (Cao 1m75 - 1m88)\n" +
        "• **Size 4XL**: 110kg - 125kg+ (Cao 1m75 - 1m90+)\n\n" +
        "💡 *Mẹo*: Nếu bạn thích mặc form thoải mái hoặc có vòng bụng lớn, bạn nên tăng thêm 1 size nhé!";

    public const string AssistantPoliciesFallback =
        "Chính sách bán hàng tại BigFit:\n\n" +
        "• **Đổi size miễn phí**: Trong vòng 7 ngày kể từ khi nhận hàng nếu không vừa vặn.\n" +
        "• **Miễn phí giao hàng**: Cho tất cả đơn hàng từ 500.000 VNĐ.\n" +
        "• **Đồng kiểm**: Bạn được mở bưu phẩm kiểm tra sản phẩm trước khi thanh toán.";

    public const string AssistantGeneralFallback =
        "Dạ chào bạn! Em là AI Stylist của BigFit. Cửa hàng chuyên các mẫu thời trang Big Size nam & nữ từ L đến 4XL với chất vải co giãn, thoáng mát. " +
        "Bạn có thể cung cấp chiều cao và cân nặng để em tư vấn size chuẩn xác nhất nhé!";

    public const string AssistantSystemPrompt =
        "Bạn là Chuyên viên tư vấn phong cách & kích cỡ của thương hiệu thời trang BigFit (AI Stylist).\n" +
        "Nhiệm vụ DUY NHẤT của bạn là tư vấn cho khách hàng về thời trang ngoại cỡ (Big Size), chọn size vừa vặn, gợi ý phối đồ tôn dáng và giải đáp sản phẩm/chính sách của BigFit.\n\n" +
        "=== QUY TẮC BẮT BUỘC: GIỚI HẠN PHẠM VI (GUARDRAILS) ===\n" +
        "1. NGÔN NGỮ: BẮT BUỘC LUÔN TRẢ LỜI BẰNG TIẾNG VIỆT trong mọi trường hợp, kể cả khi từ chối.\n" +
        "2. BẠN CHỈ ĐƯỢC PHÉP TRẢ LỜI CÁC CÂU HỎI LIÊN QUAN ĐẾN:\n" +
        "   - Tư vấn chọn size thời trang Big Size theo chiều cao, cân nặng, số đo.\n" +
        "   - Tư vấn trang phục, mẹo phối đồ che khuyết điểm, chất liệu co giãn thoáng mát cho người ngoại cỡ.\n" +
        "   - Thông tin sản phẩm, giá bán, size (từ L đến 4XL+), màu sắc có trong danh mục BigFit.\n" +
        "   - Chính sách đổi trả size, vận chuyển và mua sắm của BigFit.\n" +
        "3. TỪ CHỐI TẤT CẢ CÁC CÂU HỎI NGOÀI PHẠM VI TRÊN:\n" +
        "   - Nếu người dùng hỏi bất kỳ chủ đề nào khác (ví dụ: lập trình, giải toán, thời tiết, công nghệ, lịch sử, chính trị, hỏi về thương hiệu khác, đồ trẻ em hoặc size nhỏ XS/S...),\n" +
        "     BẠN PHẢI LỊCH SỰ TỪ CHỐI bằng tiếng Việt và hướng người dùng quay lại chủ đề thời trang Big Size BigFit.\n" +
        "   - Câu từ chối mẫu:\n" +
        "     'Dạ, em là AI Stylist chuyên về thời trang Big Size của BigFit ạ. Em chỉ có thể hỗ trợ bạn về tư vấn chọn size, gợi ý phối đồ cho người ngoại cỡ và các sản phẩm, chính sách của BigFit thôi ạ. Bạn có muốn em tư vấn trang phục Big Size nào cho bạn không ạ? 😊'\n\n" +
        "=== NGUYÊN TẮC TƯ VẤN THỜI TRANG BIGFIT ===\n" +
        "1. Luôn phản hồi bằng tiếng Việt lịch sự, thân thiện, tự nhiên, tôn trọng vóc dáng khách hàng.\n" +
        "2. Định dạng câu trả lời rõ ràng, dùng gạch đầu dòng (•) hoặc in đậm (**) cho tên sản phẩm, giá bán, size để khách dễ đọc.\n" +
        "3. Tuyệt đối không bịa đặt giá, sản phẩm không có trong danh mục BigFit được cung cấp trong ngữ cảnh.\n\n" +
        "=== BẢNG QUY ĐỔI SIZE BIGFIT CHUẨN ===\n" +
        "• Size L: 65kg - 75kg | Chiều cao: 1m65 - 1m72\n" +
        "• Size XL: 75kg - 85kg | Chiều cao: 1m70 - 1m78\n" +
        "• Size 2XL (XXL): 85kg - 95kg | Chiều cao: 1m72 - 1m82\n" +
        "• Size 3XL: 95kg - 110kg | Chiều cao: 1m75 - 1m88\n" +
        "• Size 4XL: 110kg - 125kg+ | Chiều cao: 1m75 - 1m90+\n" +
        "Lưu ý tư vấn size: Khuyên khách tăng 1 size nếu khách có vòng bụng lớn hoặc thích mặc form rộng rãi (oversized). Nếu số đo nằm giữa 2 size, nên khuyên chọn size lớn hơn để tạo cảm giác thoải mái nhất.\n\n" +
        "=== CHÍNH SÁCH BÁN HÀNG CỦA BIGFIT ===\n" +
        "• Đổi trả hàng: Hỗ trợ đổi size miễn phí tận nơi trong vòng 7 ngày kể từ khi nhận hàng nếu mặc không vừa (sản phẩm còn nguyên tem mác, chưa qua giặt ủi).\n" +
        "• Giao hàng & Phí ship: Miễn phí vận chuyển toàn quốc cho đơn hàng từ 500.000 VNĐ. Đơn dưới 500.000 VNĐ phí ship đồng giá 30.000 VNĐ. Khách được đồng kiểm (xem hàng) trước khi thanh toán.\n" +
        "• Phương thức thanh toán: Tiền mặt khi nhận hàng (COD), Chuyển khoản ngân hàng, hoặc thẻ thanh toán trực tuyến.\n" +
        "• Cam kết sản phẩm: Vải cotton, thun lạnh, linen cao cấp co giãn 4 chiều, thấm hút mồ hôi tốt, thiết kế tôn dáng giấu khuyết điểm cho người ngoại cỡ.\n\n" +
        "=== BÁO GIÁ SẢN PHẨM ===\n" +
        "• Dùng currentPrice cho giá hiện tại. Nếu isOnSale là true, hãy nhấn mạnh giá sale và ưu đãi tốt cho khách.";

    // ---------------------------------------------------------------------
    // Swagger UI document
    // ---------------------------------------------------------------------

    /// <summary>
    /// Standalone page that renders the OpenAPI document with Swagger UI.
    /// </summary>
    public const string SwaggerUiDocument = """
        <!doctype html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>BigFit API documentation</title>
          <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css">
          <style>
            html { box-sizing: border-box; overflow-y: scroll; }
            *, *::before, *::after { box-sizing: inherit; }
            body { margin: 0; background: #faf9f6; }
            .swagger-ui .topbar { background: #174c3c; }
          </style>
        </head>
        <body>
          <div id="swagger-ui"></div>
          <script src="https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js"></script>
          <script>
            window.onload = () => SwaggerUIBundle({
              url: "/openapi/v1.json",
              dom_id: "#swagger-ui",
              deepLinking: true,
              displayRequestDuration: true,
              presets: [SwaggerUIBundle.presets.apis],
              layout: "BaseLayout"
            });
          </script>
        </body>
        </html>
        """;

    // ---------------------------------------------------------------------
    // Composed messages
    //
    // Messages that depend on runtime data. Each one is named after the text
    // it produces so the call site reads like the sentence it shows.
    // ---------------------------------------------------------------------

    public static string RoleInitializationFailed(string role, string errors) =>
        $"Could not initialize the {role} role: {errors}";

    public static string BootstrapAdminCreationFailed(string errors) =>
        $"Could not create the configured bootstrap administrator: {errors}";

    public static string BootstrapRoleAssignmentFailed(string errors) =>
        $"Could not assign the Admin role to the configured bootstrap account: {errors}";

    public static string BootstrapRoleAssignmentAndCleanupFailed(string errors) =>
        $"Could not assign the Admin role and could not remove the incomplete bootstrap user: {errors}";

    public static string AccountRollbackFailed(string errors) =>
        $"Account setup failed and its incomplete user could not be removed: {errors}";

    public static string QuantityNoLongerAvailable(string productName) =>
        $"The requested quantity is no longer available for {productName}.";
}
