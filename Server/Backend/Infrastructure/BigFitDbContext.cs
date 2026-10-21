using BigFit.Domain.Entities;
using BigFit.Infrastructure.Identity;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;

namespace BigFit.Infrastructure.Persistence;

public sealed class BigFitDbContext(DbContextOptions<BigFitDbContext> options)
    : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>(options)
{
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<ProductVariant> ProductVariants => Set<ProductVariant>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Category>().HasData(
            new Category
            {
                Id = Guid.Parse("7a82d2ef-e144-42ba-a51a-30a72983399d"),
                Name = "Tops",
                Gender = "Unisex",
                Description = "Big size tops and shirts"
            },
            new Category
            {
                Id = Guid.Parse("b6cc5dfb-66bb-4765-87a5-4167f24677bd"),
                Name = "Bottoms",
                Gender = "Unisex",
                Description = "Big size trousers and skirts"
            });

        modelBuilder.Entity<Category>(entity =>
        {
            entity.ToTable("categories", table =>
                table.HasCheckConstraint("CK_categories_gender", "\"Gender\" IN ('Men', 'Women', 'Unisex')"));
            entity.HasKey(category => category.Id);
            entity.Property(category => category.Name).HasMaxLength(120).IsRequired();
            entity.Property(category => category.Gender).HasMaxLength(10).HasDefaultValue("Unisex").IsRequired();
            entity.Property(category => category.Description).HasMaxLength(1000);
            entity.HasIndex(category => new { category.Gender, category.Name }).IsUnique();
        });

        modelBuilder.Entity<Product>(entity =>
        {
            entity.ToTable("products", table =>
            {
                table.HasCheckConstraint("CK_products_sale_price", "\"SalePrice\" IS NULL OR (\"SalePrice\" > 0 AND \"SalePrice\" < \"Price\")");
                table.HasCheckConstraint("CK_products_price", "\"Price\" > 0");
            });
            entity.HasKey(product => product.Id);
            entity.Property(product => product.Name).HasMaxLength(200).IsRequired();
            entity.Property(product => product.Description).HasMaxLength(4000);
            entity.Property(product => product.Price).HasPrecision(11, 2);
            entity.Property(product => product.SalePrice).HasPrecision(11, 2);
            entity.Property(product => product.CurrencyCode).HasMaxLength(3).HasDefaultValue("EUR").IsRequired();
            entity.Property(product => product.ImageUrl).HasMaxLength(2048);
            entity.Property(product => product.CreatedAt).IsRequired();
            entity.HasOne(product => product.Category)
                .WithMany(category => category.Products)
                .HasForeignKey(product => product.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(product => product.CategoryId);
        });

        modelBuilder.Entity<ProductVariant>(entity =>
        {
            entity.ToTable("product_variants");
            entity.HasKey(variant => variant.Id);
            entity.Property(variant => variant.Sku).HasMaxLength(80).IsRequired();
            entity.Property(variant => variant.Size).HasMaxLength(40).IsRequired();
            entity.Property(variant => variant.Color).HasMaxLength(60).IsRequired();
            entity.HasIndex(variant => variant.Sku).IsUnique();
            entity.HasIndex(variant => new { variant.ProductId, variant.Size, variant.Color }).IsUnique();
            entity.HasOne(variant => variant.Product)
                .WithMany(product => product.Variants)
                .HasForeignKey(variant => variant.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
