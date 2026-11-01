using Npgsql;

namespace BigFit.Infrastructure;

internal static class LocalDevelopmentDatabase
{
    public static async Task EnsureCreatedAsync(
        string connectionString,
        CancellationToken cancellationToken)
    {
        var target = new NpgsqlConnectionStringBuilder(connectionString);
        if (string.IsNullOrWhiteSpace(target.Database))
        {
            throw new InvalidOperationException(
                "The local PostgreSQL connection string must specify a database name.");
        }

        var databaseName = target.Database;
        var admin = new NpgsqlConnectionStringBuilder(connectionString)
        {
            Database = "postgres"
        };

        await using var connection = new NpgsqlConnection(admin.ConnectionString);
        await connection.OpenAsync(cancellationToken);

        await using var check = new NpgsqlCommand(
            "SELECT EXISTS (SELECT 1 FROM pg_database WHERE datname = @name)",
            connection);
        check.Parameters.AddWithValue("name", databaseName);
        if (await check.ExecuteScalarAsync(cancellationToken) is true)
        {
            return;
        }

        await using var create = new NpgsqlCommand(
            $"CREATE DATABASE {new NpgsqlCommandBuilder().QuoteIdentifier(databaseName)}",
            connection);
        await create.ExecuteNonQueryAsync(cancellationToken);
    }
}
