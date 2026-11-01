using System.Net.Http.Headers;
using System.Text;
using System.Text.Json;
using System.Text.RegularExpressions;
using BigFit.Application.Abstractions;
using BigFit.Application.Assistant;
using BigFit.Domain.Entities;
using BigFit.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BigFit.Infrastructure.Assistant;

internal sealed class ChatAssistantService(
    HttpClient httpClient,
    IConfiguration configuration,
    BigFitDbContext dbContext,
    ILogger<ChatAssistantService> logger) : IChatAssistantService
{
    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);
    private static readonly Regex SearchTermSeparator = new(
        @"[^\p{L}\p{N}]+",
        RegexOptions.Compiled | RegexOptions.CultureInvariant);
    private static readonly Regex PersonalRequestPattern = new(
        @"\b(?:for me|my (?:size|fit|body|measurements|outfit)|i am|i'm|i weigh|i wear|what should i (?:wear|choose|get)|what size (?:should|would) i)\b|" +
        @"(?:cho tôi|của tôi|tôi cao|tôi nặng|tôi mặc|tôi nên|mình cao|mình nặng|mình mặc|mình nên|size của mình)",
        RegexOptions.Compiled | RegexOptions.CultureInvariant | RegexOptions.IgnoreCase);

    public async Task<ChatAssistantResponse> AskAsync(
        ChatAssistantRequest request,
        CancellationToken cancellationToken)
    {
        var apiKey = ReadApiKey();
        if (string.IsNullOrWhiteSpace(apiKey) ||
            apiKey.StartsWith("replace-", StringComparison.OrdinalIgnoreCase))
        {
            return GenerateFallbackResponse(request);
        }

        var baseUrl = configuration["Ai:OpenAiCompatible:BaseUrl"]
            ?? "https://api.groq.com/openai/v1";
        if (!Uri.TryCreate(baseUrl, UriKind.Absolute, out var baseUri))
        {
            throw CreateUnavailableException(
                request,
                AssistantMessages.NotConfigured(request.Language));
        }

        var userGender = ShouldUseGenderContext(request) ? request.Gender : null;
        var categoryName = string.IsNullOrWhiteSpace(request.Category)
            ? null
            : request.Category.Trim();

        var categories = await LoadCategoriesAsync(
            userGender,
            categoryName,
            cancellationToken);
        var products = await LoadProductsAsync(
            userGender,
            categoryName,
            request.Message,
            cancellationToken);

        var contextJson = JsonSerializer.Serialize(new
        {
            UserGender = userGender,
            UserCategory = categoryName,
            AvailableCategories = categories,
            AvailableProducts = products
        }, JsonOptions);

        var systemPrompt =
            $"{ChatAssistantPrompts.System(request.Language)}\n\n"
            + $"{ChatAssistantPrompts.ProductDataHeading(request.Language)}\n{contextJson}";
        var messages = BuildMessages(systemPrompt, request);
        var payload = JsonSerializer.Serialize(new
        {
            model = configuration["Ai:OpenAiCompatible:Model"] ?? "openai/gpt-oss-120b",
            temperature = 0.5,
            max_tokens = ReadMaxOutputTokens(),
            messages
        }, JsonOptions);

        using var httpRequest = new HttpRequestMessage(
            HttpMethod.Post,
            new Uri($"{baseUri.AbsoluteUri.TrimEnd('/')}/chat/completions"));
        httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        httpRequest.Content = new StringContent(payload, Encoding.UTF8, "application/json");

        return await SendRequestAsync(httpRequest, request, cancellationToken);
    }

    private string? ReadApiKey() =>
        configuration["Ai:OpenAiCompatible:ApiKey"]
        ?? Environment.GetEnvironmentVariable("Ai__OpenAiCompatible__ApiKey")
        ?? Environment.GetEnvironmentVariable("GROQ_API_KEY");

    private async Task<List<CategoryContext>> LoadCategoriesAsync(
        string? gender,
        string? categoryName,
        CancellationToken cancellationToken)
    {
        var query = dbContext.Categories.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(gender))
        {
            query = query.Where(category => category.Gender == gender);
        }

        if (!string.IsNullOrWhiteSpace(categoryName))
        {
            var normalizedCategory = categoryName.ToLowerInvariant();
            query = query.Where(category => category.Name.ToLower() == normalizedCategory);
        }

        var rows = await query
            .OrderBy(category => category.Gender)
            .ThenBy(category => category.Name)
            .Select(category => new CategoryContext(
                category.Gender,
                category.Name,
                category.Products.Count(product => product.IsActive),
                category.Products.Count(product => product.IsActive && product.SalePrice != null),
                category.Products
                    .Where(product => product.IsActive)
                    .SelectMany(product => product.Variants)
                    .Sum(variant => (int?)variant.StockQuantity) ?? 0))
            .ToListAsync(cancellationToken);

        return rows;
    }

    private async Task<List<ProductContext>> LoadProductsAsync(
        string? gender,
        string? categoryName,
        string message,
        CancellationToken cancellationToken)
    {
        var query = dbContext.Products
            .AsNoTracking()
            .Where(product => product.IsActive);

        if (!string.IsNullOrWhiteSpace(gender))
        {
            query = query.Where(product => product.Category.Gender == gender);
        }

        if (!string.IsNullOrWhiteSpace(categoryName))
        {
            var normalizedCategory = categoryName.ToLowerInvariant();
            query = query.Where(product => product.Category.Name.ToLower() == normalizedCategory);
        }

        var searchTerms = SearchTermSeparator.Split(message.ToLowerInvariant())
            .Where(term => term.Length >= 2 && !IsCommonStopword(term))
            .ToList();

        if (searchTerms.Count == 0)
        {
            return await SelectProductsAsync(query, cancellationToken);
        }

        var primaryTerm = searchTerms.MaxBy(term => term.Length)!;
        var matchedQuery = query.Where(product =>
                product.Name.ToLower().Contains(primaryTerm) ||
                product.Category.Name.ToLower().Contains(primaryTerm) ||
                product.Variants.Any(variant =>
                    variant.Size.ToLower().Contains(primaryTerm) ||
                    variant.Color.ToLower().Contains(primaryTerm)));
        var matchedProducts = await SelectProductsAsync(matchedQuery, cancellationToken);
        return matchedProducts.Count > 0
            ? matchedProducts
            : await SelectProductsAsync(query, cancellationToken);
    }

    private static Task<List<ProductContext>> SelectProductsAsync(
        IQueryable<Product> query,
        CancellationToken cancellationToken) =>
        query
            .OrderByDescending(product => product.SalePrice != null)
            .ThenBy(product => product.Name)
            .Take(8)
            .Select(product => new ProductContext(
                product.Name,
                product.Category.Gender,
                product.Category.Name,
                product.Price,
                product.SalePrice,
                product.SalePrice ?? product.Price,
                product.CurrencyCode,
                product.SalePrice != null,
                product.Variants.Sum(variant => (int?)variant.StockQuantity) ?? 0,
                product.Variants.Select(variant => variant.Size).Distinct().ToArray(),
                product.Variants.Select(variant => variant.Color).Distinct().ToArray()))
            .ToListAsync(cancellationToken);

    private static List<object> BuildMessages(string systemPrompt, ChatAssistantRequest request)
    {
        var messages = new List<object>
        {
            new { role = "system", content = systemPrompt }
        };

        if (request.History is { Count: > 0 })
        {
            messages.AddRange(request.History.TakeLast(6).Select(historyItem => new
            {
                role = historyItem.Role.Equals("user", StringComparison.OrdinalIgnoreCase)
                    ? "user"
                    : "assistant",
                content = historyItem.Content
            }));
        }

        messages.Add(new { role = "user", content = request.Message });
        return messages;
    }

    private async Task<ChatAssistantResponse> SendRequestAsync(
        HttpRequestMessage httpRequest,
        ChatAssistantRequest request,
        CancellationToken cancellationToken)
    {
        try
        {
            using var response = await httpClient.SendAsync(httpRequest, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync(cancellationToken);
                logger.LogWarning(AssistantMessages.ProviderErrorStatusLog, (int)response.StatusCode, errorBody);
                throw CreateUnavailableException(request, AssistantMessages.ProviderRequestFailed(request.Language));
            }

            await using var responseStream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var document = await JsonDocument.ParseAsync(responseStream, cancellationToken: cancellationToken);
            var answer = document.RootElement
                .GetProperty("choices")[0]
                .GetProperty("message")
                .GetProperty("content")
                .GetString();

            if (string.IsNullOrWhiteSpace(answer))
            {
                throw CreateUnavailableException(request, AssistantMessages.ProviderEmptyResponse(request.Language));
            }

            return new ChatAssistantResponse(answer.Trim());
        }
        catch (HttpRequestException exception)
        {
            logger.LogWarning(exception, AssistantMessages.ProviderUnreachableLog);
            throw CreateUnavailableException(request, AssistantMessages.ProviderUnavailable(request.Language));
        }
        catch (OperationCanceledException exception) when (!cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning(exception, AssistantMessages.ProviderTimeoutLog);
            throw CreateUnavailableException(request, AssistantMessages.ProviderTimedOut(request.Language));
        }
        catch (JsonException exception)
        {
            logger.LogWarning(exception, AssistantMessages.ProviderInvalidResponseLog);
            throw CreateUnavailableException(request, AssistantMessages.ProviderInvalidResponse(request.Language));
        }
    }

    private static bool ShouldUseGenderContext(ChatAssistantRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Gender))
        {
            return false;
        }

        if (PersonalRequestPattern.IsMatch(request.Message))
        {
            return true;
        }

        return request.History?
            .Where(item => item.Role.Equals("user", StringComparison.OrdinalIgnoreCase))
            .TakeLast(6)
            .Any(item => PersonalRequestPattern.IsMatch(item.Content)) == true;
    }

    private static bool IsCommonStopword(string word) =>
        word is "cho" or "minh" or "mình" or "tôi" or "ban" or "bạn" or "hoi" or "hỏi" or "can" or "cần" or "co" or "có" or "khong" or "không" or "nhé" or "nha" or "xem";

    private static ChatAssistantResponse GenerateFallbackResponse(ChatAssistantRequest request)
    {
        var msg = request.Message.ToLowerInvariant();
        var isEnglish = request.Language == "en";

        var outOfScopeWords = isEnglish
            ? new[] { "code", "python", "java", "programming", "math", "weather", "politics", "game", "movie", "homework" }
            : new[] { "code", "python", "java", "lập trình", "toán", "thời tiết", "chính trị", "game", "phim", "bài tập" };
        if (outOfScopeWords.Any(w => msg.Contains(w)))
        {
            return new ChatAssistantResponse(
                AssistantMessages.OutOfScopeFallback(request.Language));
        }

        if (msg.Contains("size") || msg.Contains("nặng") || msg.Contains("cao") || msg.Contains("kg") ||
            (isEnglish && (msg.Contains("height") || msg.Contains("weight") || msg.Contains("fit"))))
        {
            return new ChatAssistantResponse(
                AssistantMessages.SizeGuideFallback(request.Language));
        }

        if (msg.Contains("đổi") || msg.Contains("trả") || msg.Contains("ship") || msg.Contains("vận chuyển") ||
            (isEnglish && (msg.Contains("exchange") || msg.Contains("return") || msg.Contains("shipping") || msg.Contains("delivery"))))
        {
            return new ChatAssistantResponse(
                AssistantMessages.PoliciesFallback(request.Language));
        }

        return new ChatAssistantResponse(
            AssistantMessages.GeneralFallback(request.Language));
    }

    private static ChatAssistantUnavailableException CreateUnavailableException(
        ChatAssistantRequest request,
        string message) =>
        new(message, AssistantMessages.UnavailableTitle(request.Language));

    private int ReadMaxOutputTokens() =>
        int.TryParse(configuration["Ai:OpenAiCompatible:MaxOutputTokens"], out var value)
            ? Math.Clamp(value, 64, 2048)
            : 600;

    private sealed record CategoryContext(
        string Gender,
        string Name,
        int ProductCount,
        int OnSaleCount,
        int AvailableUnits);

    private sealed record ProductContext(
        string Name,
        string Gender,
        string Category,
        decimal Price,
        decimal? SalePrice,
        decimal CurrentPrice,
        string CurrencyCode,
        bool IsOnSale,
        int AvailableUnits,
        string[] Sizes,
        string[] Colors);
}
