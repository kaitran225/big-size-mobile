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

    public async Task<ChatAssistantResponse> AskAsync(
        ChatAssistantRequest request,
        CancellationToken cancellationToken)
    {
        var baseUrl = configuration["Ai:OpenAiCompatible:BaseUrl"] ?? "https://api.groq.com/openai/v1";
        var apiKey = configuration["Ai:OpenAiCompatible:ApiKey"]
            ?? Environment.GetEnvironmentVariable("Ai__OpenAiCompatible__ApiKey")
            ?? Environment.GetEnvironmentVariable("GROQ_API_KEY");
        var model = configuration["Ai:OpenAiCompatible:Model"] ?? "openai/gpt-oss-120b";

        // Query Categories
        var categoryQuery = dbContext.Categories.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(request.Gender))
        {
            categoryQuery = categoryQuery.Where(category => category.Gender == request.Gender);
        }

        if (!string.IsNullOrWhiteSpace(request.Category))
        {
            var cat = request.Category.Trim().ToLower();
            categoryQuery = categoryQuery.Where(category => category.Name.ToLower() == cat);
        }

        var categories = await categoryQuery
            .OrderBy(category => category.Gender)
            .ThenBy(category => category.Name)
            .Select(category => new
            {
                category.Gender,
                category.Name,
                ProductCount = category.Products.Count(product => product.IsActive),
                OnSaleCount = category.Products.Count(product => product.IsActive && product.SalePrice != null),
                AvailableUnits = category.Products
                    .Where(product => product.IsActive)
                    .SelectMany(product => product.Variants)
                    .Sum(variant => (int?)variant.StockQuantity) ?? 0
            })
            .ToListAsync(cancellationToken);

        // Query relevant Products
        var productsQuery = dbContext.Products
            .AsNoTracking()
            .Where(product => product.IsActive);

        if (!string.IsNullOrWhiteSpace(request.Gender))
        {
            productsQuery = productsQuery.Where(product => product.Category.Gender == request.Gender);
        }

        if (!string.IsNullOrWhiteSpace(request.Category))
        {
            var cat = request.Category.Trim().ToLower();
            productsQuery = productsQuery.Where(product => product.Category.Name.ToLower() == cat);
        }

        // Extract search keywords from message
        var searchTerms = Regex.Split(request.Message.ToLowerInvariant(), @"[^\p{L}\p{N}]+")
            .Where(term => term.Length >= 2 && !IsCommonStopword(term))
            .ToList();

        if (searchTerms.Count > 0)
        {
            var primaryTerm = searchTerms.OrderByDescending(t => t.Length).First().ToLower();
            var matchedQuery = productsQuery.Where(product =>
                product.Name.ToLower().Contains(primaryTerm) ||
                product.Category.Name.ToLower().Contains(primaryTerm) ||
                product.Variants.Any(v => v.Size.ToLower().Contains(primaryTerm) || v.Color.ToLower().Contains(primaryTerm)));

            if (await matchedQuery.AnyAsync(cancellationToken))
            {
                productsQuery = matchedQuery;
            }
        }

        var products = await productsQuery
            .OrderByDescending(p => p.SalePrice != null)
            .ThenBy(p => p.Name)
            .Take(8)
            .Select(product => new
            {
                product.Name,
                Gender = product.Category.Gender,
                Category = product.Category.Name,
                product.Price,
                product.SalePrice,
                CurrentPrice = product.SalePrice ?? product.Price,
                product.CurrencyCode,
                IsOnSale = product.SalePrice != null,
                AvailableUnits = product.Variants.Sum(variant => (int?)variant.StockQuantity) ?? 0,
                Sizes = product.Variants.Select(variant => variant.Size).Distinct().ToArray(),
                Colors = product.Variants.Select(variant => variant.Color).Distinct().ToArray()
            })
            .ToListAsync(cancellationToken);

        // Fallback local advisor if API key is not yet configured (guarantees safe demo)
        if (string.IsNullOrWhiteSpace(apiKey) || apiKey.StartsWith("replace-", StringComparison.OrdinalIgnoreCase))
        {
            return GenerateFallbackResponse(request, products);
        }

        if (!Uri.TryCreate(baseUrl, UriKind.Absolute, out var baseUri))
        {
            throw new ChatAssistantUnavailableException(AssistantMessages.NotConfigured);
        }

        var contextJson = JsonSerializer.Serialize(new
        {
            UserGender = request.Gender,
            UserCategory = request.Category,
            AvailableCategories = categories,
            AvailableProducts = products
        }, JsonOptions);

        var systemPrompt = $"{AssistantMessages.SystemPrompt}\n\n=== DỮ LIỆU SẢN PHẨM HIỆN CÓ CỦA CỬA HÀNG ===\n{contextJson}";

        // Build messages list including multi-turn history
        var messagesList = new List<object>
        {
            new { role = "system", content = systemPrompt }
        };

        if (request.History is { Count: > 0 })
        {
            foreach (var historyItem in request.History.TakeLast(6))
            {
                var role = historyItem.Role.Equals("user", StringComparison.OrdinalIgnoreCase) ? "user" : "assistant";
                messagesList.Add(new { role, content = historyItem.Content });
            }
        }

        messagesList.Add(new { role = "user", content = request.Message });

        var payload = JsonSerializer.Serialize(new
        {
            model,
            temperature = 0.5,
            max_tokens = ReadMaxOutputTokens(),
            messages = messagesList
        }, JsonOptions);

        using var httpRequest = new HttpRequestMessage(
            HttpMethod.Post,
            new Uri($"{baseUri.AbsoluteUri.TrimEnd('/')}/chat/completions"));
        httpRequest.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
        httpRequest.Content = new StringContent(payload, Encoding.UTF8, "application/json");

        try
        {
            using var response = await httpClient.SendAsync(httpRequest, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync(cancellationToken);
                logger.LogWarning(AssistantMessages.ProviderErrorStatusLog + " Details: {Details}", (int)response.StatusCode, errorBody);
                throw new ChatAssistantUnavailableException(AssistantMessages.ProviderRequestFailed);
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
                throw new ChatAssistantUnavailableException(AssistantMessages.ProviderEmptyResponse);
            }

            return new ChatAssistantResponse(answer.Trim());
        }
        catch (HttpRequestException exception)
        {
            logger.LogWarning(exception, AssistantMessages.ProviderUnreachableLog);
            throw new ChatAssistantUnavailableException(AssistantMessages.ProviderUnavailable);
        }
        catch (OperationCanceledException exception) when (!cancellationToken.IsCancellationRequested)
        {
            logger.LogWarning(exception, AssistantMessages.ProviderTimeoutLog);
            throw new ChatAssistantUnavailableException(AssistantMessages.ProviderTimedOut);
        }
        catch (JsonException exception)
        {
            logger.LogWarning(exception, AssistantMessages.ProviderInvalidResponse);
            throw new ChatAssistantUnavailableException(AssistantMessages.ProviderInvalidResponse);
        }
    }

    private static bool IsCommonStopword(string word) =>
        word is "cho" or "minh" or "mình" or "tôi" or "ban" or "bạn" or "hoi" or "hỏi" or "can" or "cần" or "co" or "có" or "khong" or "không" or "nhé" or "nha" or "xem";

    private static ChatAssistantResponse GenerateFallbackResponse(ChatAssistantRequest request, dynamic products)
    {
        var msg = request.Message.ToLowerInvariant();

        var outOfScopeWords = new[] { "code", "python", "java", "lập trình", "toán", "thời tiết", "chính trị", "game", "phim", "bài tập" };
        if (outOfScopeWords.Any(w => msg.Contains(w)))
        {
            return new ChatAssistantResponse(
                "Dạ, em là AI Stylist chuyên về thời trang Big Size của BigFit ạ. Em chỉ có thể hỗ trợ bạn về tư vấn chọn size, gợi ý phối đồ cho người ngoại cỡ và các sản phẩm, chính sách của BigFit thôi ạ. Bạn có muốn em tư vấn trang phục Big Size nào cho bạn không ạ? 😊");
        }

        if (msg.Contains("size") || msg.Contains("nặng") || msg.Contains("cao") || msg.Contains("kg"))
        {
            return new ChatAssistantResponse(
                "Dạ chào bạn! Để chọn size BigFit chuẩn nhất cho vóc dáng:\n\n" +
                "• **Size L**: 65kg - 75kg (Cao 1m65 - 1m72)\n" +
                "• **Size XL**: 75kg - 85kg (Cao 1m70 - 1m78)\n" +
                "• **Size 2XL (XXL)**: 85kg - 95kg (Cao 1m72 - 1m82)\n" +
                "• **Size 3XL**: 95kg - 110kg (Cao 1m75 - 1m88)\n" +
                "• **Size 4XL**: 110kg - 125kg+ (Cao 1m75 - 1m90+)\n\n" +
                "💡 *Mẹo*: Nếu bạn thích mặc form thoải mái hoặc có vòng bụng lớn, bạn nên tăng thêm 1 size nhé!");
        }

        if (msg.Contains("đổi") || msg.Contains("trả") || msg.Contains("ship") || msg.Contains("vận chuyển"))
        {
            return new ChatAssistantResponse(
                "Chính sách bán hàng tại BigFit:\n\n" +
                "• **Đổi size miễn phí**: Trong vòng 7 ngày kể từ khi nhận hàng nếu không vừa vặn.\n" +
                "• **Miễn phí giao hàng**: Cho tất cả đơn hàng từ 500.000 VNĐ.\n" +
                "• **Đồng kiểm**: Bạn được mở bưu phẩm kiểm tra sản phẩm trước khi thanh toán.");
        }

        return new ChatAssistantResponse(
            "Dạ chào bạn! Em là AI Stylist của BigFit. Cửa hàng chuyên các mẫu thời trang Big Size nam & nữ từ L đến 4XL với chất vải co giãn, thoáng mát. " +
            "Bạn có thể cung cấp chiều cao và cân nặng để em tư vấn size chuẩn xác nhất nhé!");
    }

    private int ReadMaxOutputTokens() =>
        int.TryParse(configuration["Ai:OpenAiCompatible:MaxOutputTokens"], out var value)
            ? Math.Clamp(value, 64, 2048)
            : 600;
}
