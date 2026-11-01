using System.Globalization;
using BigFit.Domain.Entities;
using BigFit.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.VisualBasic.FileIO;

namespace BigFit.Infrastructure;

internal sealed class DevelopmentCatalogSeeder(
    BigFitDbContext dbContext,
    ILogger<DevelopmentCatalogSeeder> logger)
{
    private static readonly string[] RequiredColumns =
    [
        "Gender", "Category", "ProductName", "Description", "Price", "SalePrice",
        "CurrencyCode", "ImageUrl", "SKU", "Size", "Color", "StockQuantity"
    ];

    public async Task SeedAsync(string contentRootPath, CancellationToken cancellationToken)
    {
        if (await dbContext.Products.AnyAsync(cancellationToken))
        {
            logger.LogInformation("Development catalogue already contains products; skipping CSV seed.");
            return;
        }

        var csvPath = Path.Combine(contentRootPath, "Mock", "BigFitProducts.review.csv");
        if (!File.Exists(csvPath))
        {
            throw new FileNotFoundException(
                "The development catalogue CSV was not found. Ensure Mock/BigFitProducts.review.csv is available.",
                csvPath);
        }

        var rows = ReadRows(csvPath, cancellationToken);
        if (rows.Count == 0)
        {
            throw new InvalidDataException($"The development catalogue CSV is empty: {csvPath}");
        }

        var categories = await dbContext.Categories.ToDictionaryAsync(
            category => (category.Gender, category.Name),
            cancellationToken);

        foreach (var row in rows)
        {
            if (!categories.ContainsKey((row.Gender, row.Category)))
            {
                var category = new Category { Gender = row.Gender, Name = row.Category };
                categories.Add((row.Gender, row.Category), category);
                dbContext.Categories.Add(category);
            }
        }

        foreach (var productRows in rows.GroupBy(row => new
        {
            row.Gender,
            row.Category,
            row.ProductCode,
            row.ProductName,
            row.Price,
            row.SalePrice,
            row.CurrencyCode
        }))
        {
            var first = productRows.First();
            var product = new Product
            {
                Name = first.ProductName,
                Description = first.Description,
                Price = first.Price,
                SalePrice = first.SalePrice,
                CurrencyCode = first.CurrencyCode,
                ImageUrl = first.ImageUrl,
                Category = categories[(first.Gender, first.Category)]
            };
            foreach (var row in productRows)
            {
                product.Variants.Add(new ProductVariant
                {
                    Sku = row.Sku,
                    Size = row.Size,
                    Color = row.Color,
                    StockQuantity = row.StockQuantity
                });
            }

            dbContext.Products.Add(product);
        }

        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        logger.LogInformation(
            "Seeded {ProductCount} development products and {VariantCount} variants from {CsvPath}.",
            await dbContext.Products.CountAsync(cancellationToken),
            rows.Count,
            csvPath);
    }

    private static List<CatalogueRow> ReadRows(string csvPath, CancellationToken cancellationToken)
    {
        using var parser = new TextFieldParser(csvPath)
        {
            TextFieldType = FieldType.Delimited,
            HasFieldsEnclosedInQuotes = true,
            TrimWhiteSpace = false
        };
        parser.SetDelimiters(",");

        var headers = parser.ReadFields();
        if (headers is null || !RequiredColumns.SequenceEqual(headers, StringComparer.Ordinal))
        {
            throw new InvalidDataException(
                $"The development catalogue CSV must have these columns in order: {string.Join(", ", RequiredColumns)}.");
        }

        var rows = new List<CatalogueRow>();
        var skus = new HashSet<string>(StringComparer.Ordinal);
        while (!parser.EndOfData)
        {
            cancellationToken.ThrowIfCancellationRequested();
            var fields = parser.ReadFields();
            if (fields is null || fields.Length != RequiredColumns.Length)
            {
                throw new InvalidDataException(
                    $"Invalid development catalogue CSV row near line {parser.LineNumber}.");
            }

            var values = RequiredColumns
                .Select((column, index) => (column, value: fields[index]))
                .ToDictionary(item => item.column, item => item.value, StringComparer.Ordinal);
            var sku = Required(values, "SKU", parser.LineNumber);
            var skuParts = sku.Split('-', 2);
            if (skuParts.Length != 2 || !skus.Add(sku))
            {
                throw new InvalidDataException(
                    $"Invalid or duplicate SKU '{sku}' near line {parser.LineNumber} in the development catalogue CSV.");
            }

            var price = ParsePrice(Required(values, "Price", parser.LineNumber), "Price", parser.LineNumber);
            var salePriceValue = values["SalePrice"];
            decimal? salePrice = string.IsNullOrWhiteSpace(salePriceValue)
                ? null
                : ParsePrice(salePriceValue, "SalePrice", parser.LineNumber);
            if (salePrice is not null && (salePrice <= 0 || salePrice >= price))
            {
                throw new InvalidDataException(
                    $"Invalid SalePrice near line {parser.LineNumber} in the development catalogue CSV.");
            }

            if (!int.TryParse(values["StockQuantity"], NumberStyles.Integer, CultureInfo.InvariantCulture, out var stockQuantity) ||
                stockQuantity < 0)
            {
                throw new InvalidDataException(
                    $"Invalid StockQuantity near line {parser.LineNumber} in the development catalogue CSV.");
            }

            rows.Add(new CatalogueRow(
                Required(values, "Gender", parser.LineNumber),
                Required(values, "Category", parser.LineNumber),
                skuParts[0],
                Required(values, "ProductName", parser.LineNumber),
                values["Description"],
                price,
                salePrice,
                Required(values, "CurrencyCode", parser.LineNumber),
                values["ImageUrl"],
                sku,
                Required(values, "Size", parser.LineNumber),
                Required(values, "Color", parser.LineNumber),
                stockQuantity));
        }

        return rows;
    }

    private static string Required(
        IReadOnlyDictionary<string, string> values,
        string column,
        long lineNumber)
    {
        var value = values[column];
        if (!string.IsNullOrWhiteSpace(value))
        {
            return value;
        }

        throw new InvalidDataException(
            $"Required column '{column}' is empty near line {lineNumber} in the development catalogue CSV.");
    }

    private static decimal ParsePrice(string value, string column, long lineNumber)
    {
        if (decimal.TryParse(value, NumberStyles.Number, CultureInfo.InvariantCulture, out var price) &&
            price > 0)
        {
            return price;
        }

        throw new InvalidDataException(
            $"Invalid {column} near line {lineNumber} in the development catalogue CSV.");
    }

    private sealed record CatalogueRow(
        string Gender,
        string Category,
        string ProductCode,
        string ProductName,
        string Description,
        decimal Price,
        decimal? SalePrice,
        string CurrencyCode,
        string ImageUrl,
        string Sku,
        string Size,
        string Color,
        int StockQuantity);
}
