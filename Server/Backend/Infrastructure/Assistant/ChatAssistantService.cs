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
        var baseUrl = configuration["Ai:OpenAiCompatible:BaseUrl"];
        var apiKey = configuration["Ai:OpenAiCompatible:ApiKey"];
        var model = configuration["Ai:OpenAiCompatible:Model"];
        if (!Uri.TryCreate(baseUrl, UriKind.Absolute, out var baseUri) ||
            string.IsNullOrWhiteSpace(apiKey) ||
            string.IsNullOrWhiteSpace(model))
        {
            throw new ChatAssistantUnavailableException(
                AssistantMessages.NotConfigured);
        }

        var categoryQuery = dbContext.Categories.AsNoTracking().AsQueryable();
        if (request.Gender is not null)
        {
            categoryQuery = categoryQuery.Where(category => category.Gender == request.Gender);
        }

        if (!string.IsNullOrWhiteSpace(request.Category))
        {
            categoryQuery = categoryQuery.Where(category =>
                EF.Functions.ILike(category.Name, request.Category.Trim()));
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

        var searchTerm = Regex.Split(request.Message.ToLowerInvariant(), @"[^\p{L}\p{N}]+")
            .Where(term => term.Length >= 3)
            .OrderByDescending(term => term.Length)
            .FirstOrDefault();

        var productsQuery = dbContext.Products
            .AsNoTracking()
            .Where(product => product.IsActive);
        if (request.Gender is not null)
        {
            productsQuery = productsQuery.Where(product => product.Category.Gender == request.Gender);
        }

        if (!string.IsNullOrWhiteSpace(request.Category))
        {
            productsQuery = productsQuery.Where(product =>
                EF.Functions.ILike(product.Category.Name, request.Category.Trim()));
        }

        if (searchTerm is not null)
        {
            var pattern = $"%{searchTerm}%";
            productsQuery = productsQuery.Where(product =>
                EF.Functions.ILike(product.Name, pattern) ||
                EF.Functions.ILike(product.Category.Name, pattern));
        }

        var products = await productsQuery
            .OrderBy(product => product.Name)
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

        var context = JsonSerializer.Serialize(new
        {
            request.Message,
            request.Gender,
            request.Category,
            Categories = categories,
            Products = products
        }, JsonOptions);

        var systemMessage = AssistantMessages.SystemPrompt;
        var payload = JsonSerializer.Serialize(new
        {
            model,
            max_tokens = ReadMaxOutputTokens(),
            messages = new[]
            {
                new { role = "system", content = systemMessage },
                new { role = "user", content = context }
            }
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
                logger.LogWarning(AssistantMessages.ProviderErrorStatusLog, (int)response.StatusCode);
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

    private int ReadMaxOutputTokens() =>
        int.TryParse(configuration["Ai:OpenAiCompatible:MaxOutputTokens"], out var value)
            ? Math.Clamp(value, 64, 1024)
            : 300;

}
