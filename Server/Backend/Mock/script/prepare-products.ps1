$ErrorActionPreference = "Stop"

$mockRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $mockRoot "Uniqlo Products.csv"
$outputPath = Join-Path $mockRoot "BigFitProducts.review.csv"
$invariantCulture = [System.Globalization.CultureInfo]::InvariantCulture

function ConvertTo-Price {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $numericValue = $Value -replace "[^\d,.-]", ""
    $numericValue = $numericValue.Replace(",", ".")
    $parsedPrice = [decimal]::Zero
    if (-not [decimal]::TryParse(
        $numericValue,
        [System.Globalization.NumberStyles]::Number,
        $invariantCulture,
        [ref]$parsedPrice
    )) {
        return $null
    }

    return $parsedPrice
}

function Get-CleanCategory {
    param(
        [string]$Gender,
        [string]$SourceCategory
    )

    switch -Regex ($SourceCategory) {
        "^Jeans, Trousers & Shorts$" { return "Bottoms" }
        "^Knitwear$" { return "Knitwear" }
        "^Outerwear$" { return "Outerwear" }
        "^Innerwear, Underwear & Socks$" { return "Innerwear" }
        "^(AIRism|HEATTECH)$" { return "Innerwear" }
        "^Shirts" { return "Shirts" }
        "^Linen$" {
            if ($Gender -eq "Women") {
                return "Shirts"
            }
            return $null
        }
        "^T-Shirts" { return "Casualwear" }
        "^Loungewear & Pyjamas$" { return "Casualwear" }
        "^Sport Utility Wear$" { return "Casualwear" }
        "^Dresses, Skirts & Jumpsuits$" {
            if ($Gender -eq "Women") {
                return "Dresses & Skirts"
            }
            return $null
        }
        default { return $null }
    }
}

function Get-VariantAttribute {
    param(
        [object[]]$Attributes,
        [string]$AttributeName
    )

    $attribute = $Attributes | Where-Object { $_.name -eq $AttributeName } | Select-Object -First 1
    if ($null -eq $attribute) {
        return ""
    }

    return [string]$attribute.value
}

function Get-BigFitSize {
    param([string]$SourceSize)

    $normalizedSize = $SourceSize.Trim().ToUpperInvariant()
    switch -Regex ($normalizedSize) {
        "^(XXS|XS|S)$" { return "M" }
        "^S/M$" { return "L" }
        "^M$" { return "L" }
        "^L$" { return "XL" }
        "^XL$" { return "XXL" }
        "^XXL$" { return "3XL" }
        "^3XL$" { return "4XL" }
        "^ONE SIZE$" { return "L" }
        "^(\d+)INCH$" {
            $waist = [int]$Matches[1]
            if ($waist -le 26) { return "M" }
            if ($waist -le 30) { return "L" }
            if ($waist -le 34) { return "XL" }
            if ($waist -le 38) { return "XXL" }
            return "3XL"
        }
        "^(65/70 B C|65/70 D E|B90|C85)$" { return "M" }
        "^(75/80 B C|C90|D85)$" { return "L" }
        "^(75/80 D E|90 B C|90 D E)$" { return "XL" }
        default { throw "Unsupported source size '$SourceSize'; map it before generating the review CSV." }
    }
}

if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw "Source CSV was not found: $sourcePath"
}

$sourceRows = Import-Csv -LiteralPath $sourcePath
$cleanRows = foreach ($row in $sourceRows) {
    $categoryPath = @($row.product_category -split "\s*>\s*")
    if ($categoryPath.Count -lt 2 -or $categoryPath[0] -notin @("MEN", "WOMEN")) {
        continue
    }

    $gender = if ($categoryPath[0] -eq "MEN") { "Men" } else { "Women" }
    $category = Get-CleanCategory -Gender $gender -SourceCategory $categoryPath[1]
    if ([string]::IsNullOrWhiteSpace($category)) {
        continue
    }

    if ($row.title -match "(?i)\bsocks?\b") {
        continue
    }

    $price = ConvertTo-Price -Value $row.price
    if ($null -eq $price -or $price -le 0) {
        continue
    }

    $salePrice = ConvertTo-Price -Value $row.sale_price
    if ($null -eq $salePrice -or $salePrice -le 0 -or $salePrice -ge $price) {
        $salePrice = ""
    }

    $attributes = @()
    if (-not [string]::IsNullOrWhiteSpace($row.variant_attributes)) {
        $attributes = ConvertFrom-Json -InputObject ([string]$row.variant_attributes)
    }

    $sku = if ([string]::IsNullOrWhiteSpace($row.variant_id)) { $row.item_id } else { $row.variant_id }
    $stockQuantity = if ($row.availability -eq "in_stock") { 8 } else { 0 }
    $sourceSize = Get-VariantAttribute -Attributes $attributes -AttributeName "Size"
    $color = Get-VariantAttribute -Attributes $attributes -AttributeName "Color"
    if ([string]::IsNullOrWhiteSpace($sourceSize) -or [string]::IsNullOrWhiteSpace($color)) {
        throw "Variant '$sku' is missing its source size or color."
    }
    $description = [string]$row.description
    if ($description.Length -gt 4000) {
        $description = $description.Substring(0, 4000)
    }

    [pscustomobject][ordered]@{
        Gender       = $gender
        Category     = $category
        ProductName  = ([string]$row.title).Trim()
        Description  = $description
        Price        = $price.ToString("0.00", $invariantCulture)
        SalePrice    = if ($salePrice -is [decimal]) { $salePrice.ToString("0.00", $invariantCulture) } else { "" }
        CurrencyCode = "EUR"
        ImageUrl     = ([string]$row.image_url).Trim()
        SKU          = ([string]$sku).Trim()
        Size         = Get-BigFitSize -SourceSize $sourceSize
        Color        = $color.Trim()
        StockQuantity = $stockQuantity
    }
}

$cleanRows = @($cleanRows |
    Group-Object Gender, Category, ProductName, Size, Color |
    ForEach-Object {
        $_.Group | Sort-Object SKU | Select-Object -First 1
    })

$requiredColumns = @(
    "Gender", "Category", "ProductName", "Description", "Price", "SalePrice",
    "CurrencyCode", "ImageUrl", "SKU", "Size", "Color", "StockQuantity"
)
if (@($cleanRows).Count -eq 0) {
    throw "No eligible Men/Women catalogue rows were found."
}

$duplicateSkus = @($cleanRows | Group-Object SKU | Where-Object { $_.Count -gt 1 })
if ($duplicateSkus.Count -gt 0) {
    throw "The cleaned data contains duplicate SKUs."
}

$belowMinimum = foreach ($group in ($cleanRows | Group-Object Gender, Category)) {
    $uniqueProducts = @($group.Group.ProductName | Sort-Object -Unique)
    if ($uniqueProducts.Count -lt 10) {
        [pscustomobject]@{
            Category = $group.Name
            ProductCount = $uniqueProducts.Count
        }
    }
}
if (@($belowMinimum).Count -gt 0) {
    throw "Every included gender/category must have at least 10 distinct product names."
}

$cleanRows | Select-Object $requiredColumns | Export-Csv -LiteralPath $outputPath -NoTypeInformation -Encoding UTF8

Write-Output "Created review file: $outputPath"
Write-Output "Source rows: $($sourceRows.Count)"
Write-Output "Clean product-variant rows: $(@($cleanRows).Count)"
Write-Output "Distinct product names by gender/category:"
$cleanRows |
    Group-Object Gender, Category |
    Sort-Object Name |
    ForEach-Object {
        $count = @($_.Group.ProductName | Sort-Object -Unique).Count
        Write-Output ("{0}: {1}" -f $_.Name, $count)
    }
