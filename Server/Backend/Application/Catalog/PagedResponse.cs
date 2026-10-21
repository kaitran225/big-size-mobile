namespace BigFit.Application.Catalog;

/// <summary>A page of catalogue results and the number of matching items.</summary>
public sealed record PagedResponse<T>(
    IReadOnlyList<T> Items,
    int Page,
    int PageSize,
    int TotalCount,
    int TotalPages);
