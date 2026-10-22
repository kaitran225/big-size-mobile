using BigFit.Application.Addresses;
using BigFit.Application.Abstractions;
using BigFit.Domain.Entities;
using BigFit.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BigFit.Infrastructure.Addresses;

internal sealed class AddressService(BigFitDbContext dbContext) : IAddressService
{
    public async Task<IReadOnlyList<CustomerAddressResponse>> GetMineAsync(
        Guid userId,
        CancellationToken cancellationToken) =>
        await dbContext.CustomerAddresses.AsNoTracking()
            .Where(address => address.UserId == userId)
            .OrderByDescending(address => address.IsDefault)
            .ThenBy(address => address.CreatedAt)
            .Select(address => Map(address))
            .ToListAsync(cancellationToken);

    public async Task<CustomerAddressResponse> CreateAsync(
        Guid userId,
        CustomerAddressRequest request,
        CancellationToken cancellationToken)
    {
        ValidateCoordinates(request);
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
        if (request.IsDefault)
        {
            await dbContext.CustomerAddresses
                .Where(address => address.UserId == userId && address.IsDefault)
                .ExecuteUpdateAsync(setters => setters.SetProperty(address => address.IsDefault, false), cancellationToken);
        }

        var address = new CustomerAddress
        {
            UserId = userId,
            Label = request.Label.Trim(),
            RecipientName = request.RecipientName.Trim(),
            PhoneNumber = request.PhoneNumber.Trim(),
            AddressLine = request.AddressLine.Trim(),
            City = request.City.Trim(),
            Province = request.Province?.Trim(),
            PostalCode = request.PostalCode?.Trim(),
            CountryCode = request.CountryCode,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            IsDefault = request.IsDefault
        };
        dbContext.CustomerAddresses.Add(address);
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return Map(address);
    }

    public async Task<CustomerAddressResponse?> UpdateAsync(
        Guid userId,
        Guid addressId,
        CustomerAddressRequest request,
        CancellationToken cancellationToken)
    {
        ValidateCoordinates(request);
        var address = await dbContext.CustomerAddresses.SingleOrDefaultAsync(
            item => item.UserId == userId && item.Id == addressId,
            cancellationToken);
        if (address is null)
        {
            return null;
        }

        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);
        if (request.IsDefault)
        {
            await dbContext.CustomerAddresses
                .Where(item => item.UserId == userId && item.Id != addressId && item.IsDefault)
                .ExecuteUpdateAsync(setters => setters.SetProperty(item => item.IsDefault, false), cancellationToken);
        }

        address.Label = request.Label.Trim();
        address.RecipientName = request.RecipientName.Trim();
        address.PhoneNumber = request.PhoneNumber.Trim();
        address.AddressLine = request.AddressLine.Trim();
        address.City = request.City.Trim();
        address.Province = request.Province?.Trim();
        address.PostalCode = request.PostalCode?.Trim();
        address.CountryCode = request.CountryCode;
        address.Latitude = request.Latitude;
        address.Longitude = request.Longitude;
        address.IsDefault = request.IsDefault;
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);
        return Map(address);
    }

    public async Task<bool> DeleteAsync(Guid userId, Guid addressId, CancellationToken cancellationToken)
    {
        var deleted = await dbContext.CustomerAddresses
            .Where(address => address.UserId == userId && address.Id == addressId)
            .ExecuteDeleteAsync(cancellationToken);
        return deleted > 0;
    }

    private static void ValidateCoordinates(CustomerAddressRequest request)
    {
        if (request.Latitude.HasValue != request.Longitude.HasValue)
        {
            throw new ArgumentException(ApiMessages.CoordinatesRequiredTogether, nameof(request));
        }
    }

    private static CustomerAddressResponse Map(CustomerAddress address) =>
        new(
            address.Id,
            address.Label,
            address.RecipientName,
            address.PhoneNumber,
            address.AddressLine,
            address.City,
            address.Province,
            address.PostalCode,
            address.CountryCode,
            address.Latitude,
            address.Longitude,
            address.IsDefault,
            address.CreatedAt);
}
