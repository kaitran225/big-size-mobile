using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace BigFit.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddComputedProductSaleFlag : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsOnSale",
                table: "products",
                type: "boolean",
                nullable: false,
                computedColumnSql: "\"SalePrice\" IS NOT NULL",
                stored: true);

            migrationBuilder.CreateIndex(
                name: "IX_products_SalePrice",
                table: "products",
                column: "SalePrice");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_products_SalePrice",
                table: "products");

            migrationBuilder.DropColumn(
                name: "IsOnSale",
                table: "products");
        }
    }
}
