using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BigFit.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddInventoryAndAddressConstraints : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_customer_addresses_coordinates",
                table: "customer_addresses");

            migrationBuilder.AddCheckConstraint(
                name: "CK_product_variants_stock_quantity",
                table: "product_variants",
                sql: "\"StockQuantity\" >= 0");

            migrationBuilder.AddCheckConstraint(
                name: "CK_customer_addresses_coordinates",
                table: "customer_addresses",
                sql: "(\"Latitude\" IS NULL AND \"Longitude\" IS NULL) OR (\"Latitude\" IS NOT NULL AND \"Longitude\" IS NOT NULL AND \"Latitude\" BETWEEN -90 AND 90 AND \"Longitude\" BETWEEN -180 AND 180)");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "CK_product_variants_stock_quantity",
                table: "product_variants");

            migrationBuilder.DropCheckConstraint(
                name: "CK_customer_addresses_coordinates",
                table: "customer_addresses");

            migrationBuilder.AddCheckConstraint(
                name: "CK_customer_addresses_coordinates",
                table: "customer_addresses",
                sql: "(\"Latitude\" IS NULL AND \"Longitude\" IS NULL) OR (\"Latitude\" BETWEEN -90 AND 90 AND \"Longitude\" BETWEEN -180 AND 180)");
        }
    }
}
