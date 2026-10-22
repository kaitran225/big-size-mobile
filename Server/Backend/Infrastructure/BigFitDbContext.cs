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
    public DbSet<CustomerAddress> CustomerAddresses => Set<CustomerAddress>();
    public DbSet<ShoppingCart> ShoppingCarts => Set<ShoppingCart>();
    public DbSet<ShoppingCartItem> ShoppingCartItems => Set<ShoppingCartItem>();
    public DbSet<FavoriteProduct> FavoriteProducts => Set<FavoriteProduct>();
    public DbSet<CustomerOrder> Orders => Set<CustomerOrder>();
    public DbSet<CustomerOrderItem> OrderItems => Set<CustomerOrderItem>();
    public DbSet<Payment> Payments => Set<Payment>();
    public DbSet<EmailVerificationToken> EmailVerificationTokens => Set<EmailVerificationToken>();
    public DbSet<EmailOutboxMessage> EmailOutboxMessages => Set<EmailOutboxMessage>();
    public DbSet<OtpChallenge> OtpChallenges => Set<OtpChallenge>();
    public DbSet<UserNotification> Notifications => Set<UserNotification>();
    public DbSet<ProductReview> ProductReviews => Set<ProductReview>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Category>().HasData(
            new Category { Id = Guid.Parse("7a82d2ef-e144-42ba-a51a-30a72983399d"), Name = "Tops", Gender = "Unisex", Description = "Big size tops and shirts" },
            new Category { Id = Guid.Parse("b6cc5dfb-66bb-4765-87a5-4167f24677bd"), Name = "Bottoms", Gender = "Unisex", Description = "Big size trousers and skirts" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20001"), Name = "Bottoms", Gender = "Men" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20002"), Name = "Casualwear", Gender = "Men" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20003"), Name = "Innerwear", Gender = "Men" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20004"), Name = "Knitwear", Gender = "Men" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20005"), Name = "Outerwear", Gender = "Men" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20006"), Name = "Shirts", Gender = "Men" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20007"), Name = "Bottoms", Gender = "Women" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20008"), Name = "Casualwear", Gender = "Women" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20009"), Name = "Dresses & Skirts", Gender = "Women" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20010"), Name = "Innerwear", Gender = "Women" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20011"), Name = "Knitwear", Gender = "Women" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20012"), Name = "Outerwear", Gender = "Women" },
            new Category { Id = Guid.Parse("f84c68a1-2bf2-4df5-a243-e555cfe20013"), Name = "Shirts", Gender = "Women" });

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
            entity.Property(product => product.IsOnSale)
                .HasComputedColumnSql("\"SalePrice\" IS NOT NULL", stored: true);
            entity.Property(product => product.CurrencyCode).HasMaxLength(3).HasDefaultValue("EUR").IsRequired();
            entity.Property(product => product.ImageUrl).HasMaxLength(2048);
            entity.Property(product => product.CreatedAt).IsRequired();
            entity.HasOne(product => product.Category)
                .WithMany(category => category.Products)
                .HasForeignKey(product => product.CategoryId)
                .OnDelete(DeleteBehavior.Restrict);
            entity.HasIndex(product => product.CategoryId);
            entity.HasIndex(product => product.SalePrice);
        });

        modelBuilder.Entity<ProductVariant>(entity =>
        {
            entity.ToTable("product_variants", table =>
                table.HasCheckConstraint("CK_product_variants_stock_quantity", "\"StockQuantity\" >= 0"));
            entity.HasKey(variant => variant.Id);
            entity.Property(variant => variant.Sku).HasMaxLength(80).IsRequired();
            entity.Property(variant => variant.Size).HasMaxLength(40).IsRequired();
            entity.Property(variant => variant.Color).HasMaxLength(60).IsRequired();
            entity.Property(variant => variant.StockQuantity).IsConcurrencyToken();
            entity.HasIndex(variant => variant.Sku).IsUnique();
            entity.HasIndex(variant => new { variant.ProductId, variant.Size, variant.Color }).IsUnique();
            entity.HasOne(variant => variant.Product)
                .WithMany(product => product.Variants)
                .HasForeignKey(variant => variant.ProductId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<CustomerAddress>(entity =>
        {
            entity.ToTable("customer_addresses", table =>
            {
                table.HasCheckConstraint("CK_customer_addresses_coordinates", "(\"Latitude\" IS NULL AND \"Longitude\" IS NULL) OR (\"Latitude\" IS NOT NULL AND \"Longitude\" IS NOT NULL AND \"Latitude\" BETWEEN -90 AND 90 AND \"Longitude\" BETWEEN -180 AND 180)");
            });
            entity.HasKey(address => address.Id);
            entity.Property(address => address.Label).HasMaxLength(80).IsRequired();
            entity.Property(address => address.RecipientName).HasMaxLength(120).IsRequired();
            entity.Property(address => address.PhoneNumber).HasMaxLength(32).IsRequired();
            entity.Property(address => address.AddressLine).HasMaxLength(300).IsRequired();
            entity.Property(address => address.City).HasMaxLength(120).IsRequired();
            entity.Property(address => address.Province).HasMaxLength(120);
            entity.Property(address => address.PostalCode).HasMaxLength(24);
            entity.Property(address => address.CountryCode).HasMaxLength(2).IsRequired();
            entity.Property(address => address.Latitude).HasPrecision(9, 6);
            entity.Property(address => address.Longitude).HasPrecision(9, 6);
            entity.HasIndex(address => new { address.UserId, address.IsDefault });
            entity.HasOne<ApplicationUser>().WithMany().HasForeignKey(address => address.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ShoppingCart>(entity =>
        {
            entity.ToTable("shopping_carts");
            entity.HasKey(cart => cart.Id);
            entity.HasIndex(cart => cart.UserId).IsUnique();
            entity.HasOne<ApplicationUser>().WithMany().HasForeignKey(cart => cart.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ShoppingCartItem>(entity =>
        {
            entity.ToTable("shopping_cart_items", table =>
                table.HasCheckConstraint("CK_shopping_cart_items_quantity", "\"Quantity\" > 0"));
            entity.HasKey(item => item.Id);
            entity.HasIndex(item => new { item.CartId, item.ProductVariantId }).IsUnique();
            entity.HasOne(item => item.Cart).WithMany(cart => cart.Items).HasForeignKey(item => item.CartId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne(item => item.ProductVariant).WithMany().HasForeignKey(item => item.ProductVariantId).OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<FavoriteProduct>(entity =>
        {
            entity.ToTable("favorite_products");
            entity.HasKey(favorite => new { favorite.UserId, favorite.ProductId });
            entity.HasIndex(favorite => favorite.ProductId);
            entity.HasOne<ApplicationUser>().WithMany().HasForeignKey(favorite => favorite.UserId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne<Product>().WithMany().HasForeignKey(favorite => favorite.ProductId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<CustomerOrder>(entity =>
        {
            entity.ToTable("orders", table =>
            {
                table.HasCheckConstraint("CK_orders_amounts", "\"Subtotal\" >= 0 AND \"ShippingAmount\" >= 0 AND \"TotalAmount\" >= 0");
                table.HasCheckConstraint("CK_orders_status", "\"Status\" IN ('Pending', 'Confirmed', 'Processing', 'Shipped', 'Delivered', 'Cancelled', 'Refunded')");
            });
            entity.HasKey(order => order.Id);
            entity.Property(order => order.OrderNumber).HasMaxLength(40).IsRequired();
            entity.Property(order => order.Status).HasMaxLength(20).IsRequired();
            entity.Property(order => order.CurrencyCode).HasMaxLength(3).IsRequired();
            entity.Property(order => order.Subtotal).HasPrecision(11, 2);
            entity.Property(order => order.ShippingAmount).HasPrecision(11, 2);
            entity.Property(order => order.TotalAmount).HasPrecision(11, 2);
            entity.Property(order => order.ShippingAddressSnapshot).HasColumnType("jsonb");
            entity.HasIndex(order => order.OrderNumber).IsUnique();
            entity.HasIndex(order => new { order.UserId, order.CreatedAt });
            entity.HasOne<ApplicationUser>().WithMany().HasForeignKey(order => order.UserId).OnDelete(DeleteBehavior.Restrict);
            entity.HasOne<CustomerAddress>().WithMany().HasForeignKey(order => order.ShippingAddressId).OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<CustomerOrderItem>(entity =>
        {
            entity.ToTable("order_items", table =>
                table.HasCheckConstraint("CK_order_items_quantity_and_amount", "\"Quantity\" > 0 AND \"UnitPrice\" >= 0 AND \"LineTotal\" >= 0"));
            entity.HasKey(item => item.Id);
            entity.Property(item => item.ProductName).HasMaxLength(200).IsRequired();
            entity.Property(item => item.Sku).HasMaxLength(80).IsRequired();
            entity.Property(item => item.Size).HasMaxLength(40).IsRequired();
            entity.Property(item => item.Color).HasMaxLength(60).IsRequired();
            entity.Property(item => item.UnitPrice).HasPrecision(11, 2);
            entity.Property(item => item.LineTotal).HasPrecision(11, 2);
            entity.HasOne(item => item.Order).WithMany(order => order.Items).HasForeignKey(item => item.OrderId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne<ProductVariant>().WithMany().HasForeignKey(item => item.ProductVariantId).OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<Payment>(entity =>
        {
            entity.ToTable("payments", table =>
            {
                table.HasCheckConstraint("CK_payments_amount", "\"Amount\" >= 0");
                table.HasCheckConstraint("CK_payments_status", "\"Status\" IN ('Pending', 'Authorized', 'Succeeded', 'Failed', 'Refunded', 'Cancelled')");
            });
            entity.HasKey(payment => payment.Id);
            entity.Property(payment => payment.Provider).HasMaxLength(60).IsRequired();
            entity.Property(payment => payment.Method).HasMaxLength(40).IsRequired();
            entity.Property(payment => payment.Status).HasMaxLength(20).IsRequired();
            entity.Property(payment => payment.Amount).HasPrecision(11, 2);
            entity.Property(payment => payment.CurrencyCode).HasMaxLength(3).IsRequired();
            entity.Property(payment => payment.ProviderReference).HasMaxLength(200);
            entity.HasIndex(payment => payment.OrderId);
            entity.HasIndex(payment => new { payment.Provider, payment.ProviderReference }).IsUnique();
            entity.HasOne<CustomerOrder>().WithMany().HasForeignKey(payment => payment.OrderId).OnDelete(DeleteBehavior.Restrict);
        });

        modelBuilder.Entity<EmailVerificationToken>(entity =>
        {
            entity.ToTable("email_verification_tokens");
            entity.HasKey(token => token.Id);
            entity.Property(token => token.Purpose).HasMaxLength(40).IsRequired();
            entity.Property(token => token.TokenHash).HasMaxLength(128).IsRequired();
            entity.HasIndex(token => token.TokenHash).IsUnique();
            entity.HasIndex(token => new { token.UserId, token.Purpose, token.ExpiresAt });
            entity.HasOne<ApplicationUser>().WithMany().HasForeignKey(token => token.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<EmailOutboxMessage>(entity =>
        {
            entity.ToTable("email_outbox", table =>
            {
                table.HasCheckConstraint("CK_email_outbox_status", "\"Status\" IN ('Pending', 'Sending', 'Sent', 'Failed')");
                table.HasCheckConstraint("CK_email_outbox_attempt_count", "\"AttemptCount\" >= 0");
            });
            entity.HasKey(message => message.Id);
            entity.Property(message => message.Recipient).HasMaxLength(254).IsRequired();
            entity.Property(message => message.Subject).HasMaxLength(200).IsRequired();
            entity.Property(message => message.TemplateKey).HasMaxLength(80).IsRequired();
            entity.Property(message => message.PayloadJson).HasColumnType("jsonb");
            entity.Property(message => message.Status).HasMaxLength(20).IsRequired();
            entity.HasIndex(message => new { message.Status, message.NextAttemptAt });
            entity.HasOne<ApplicationUser>().WithMany().HasForeignKey(message => message.UserId).OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<OtpChallenge>(entity =>
        {
            entity.ToTable("otp_challenges", table =>
                table.HasCheckConstraint("CK_otp_challenges_failed_attempts", "\"FailedAttempts\" BETWEEN 0 AND 10"));
            entity.HasKey(challenge => challenge.Id);
            entity.Property(challenge => challenge.Destination).HasMaxLength(254).IsRequired();
            entity.Property(challenge => challenge.Purpose).HasMaxLength(40).IsRequired();
            entity.Property(challenge => challenge.CodeHash).HasMaxLength(128).IsRequired();
            entity.HasIndex(challenge => new { challenge.Destination, challenge.Purpose, challenge.ExpiresAt });
            entity.HasOne<ApplicationUser>().WithMany().HasForeignKey(challenge => challenge.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<UserNotification>(entity =>
        {
            entity.ToTable("notifications");
            entity.HasKey(notification => notification.Id);
            entity.Property(notification => notification.Type).HasMaxLength(40).IsRequired();
            entity.Property(notification => notification.Title).HasMaxLength(160).IsRequired();
            entity.Property(notification => notification.Message).HasMaxLength(2000).IsRequired();
            entity.Property(notification => notification.DataJson).HasColumnType("jsonb");
            entity.HasIndex(notification => new { notification.UserId, notification.CreatedAt });
            entity.HasIndex(notification => new { notification.UserId, notification.ReadAt });
            entity.HasOne<ApplicationUser>().WithMany().HasForeignKey(notification => notification.UserId).OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<ProductReview>(entity =>
        {
            entity.ToTable("product_reviews", table =>
                table.HasCheckConstraint("CK_product_reviews_rating", "\"Rating\" BETWEEN 1 AND 5"));
            entity.HasKey(review => review.Id);
            entity.Property(review => review.Comment).HasMaxLength(2000);
            entity.HasIndex(review => new { review.UserId, review.ProductId }).IsUnique();
            entity.HasIndex(review => new { review.ProductId, review.CreatedAt });
            entity.HasOne<ApplicationUser>().WithMany().HasForeignKey(review => review.UserId).OnDelete(DeleteBehavior.Cascade);
            entity.HasOne<Product>().WithMany().HasForeignKey(review => review.ProductId).OnDelete(DeleteBehavior.Cascade);
        });
    }
}
