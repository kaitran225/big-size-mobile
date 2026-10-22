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
/// <para>
/// The AI assistant keeps its own text in
/// <see cref="BigFit.Application.Assistant.AssistantMessages"/> so the
/// provider prompt can be tuned without touching this file.
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

    // ---------------------------------------------------------------------
    // OpenAPI descriptions
    // ---------------------------------------------------------------------

    public const string DescriptionGetProducts =
        "Supports text search, gender, category, size, color, sale, stock, sorting, and pagination.";
    public const string DescriptionCreateMyOrder =
        "Uses current sale prices, snapshots item details, and decrements stock transactionally.";
    public const string DescriptionBearerSecurityScheme =
        "Paste the access token returned by /api/auth/login. Swagger UI sends it as a Bearer header.";

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
