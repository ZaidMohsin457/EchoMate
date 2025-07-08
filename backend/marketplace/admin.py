from django.contrib import admin
from .models import Category, Product, ProductImage, Order, Wishlist, Review

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'description', 'created_at')
    search_fields = ('name',)

@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('title', 'seller', 'category', 'price', 'product_type', 'available', 'created_at')
    list_filter = ('category', 'product_type', 'available', 'listed_via_chat', 'condition')
    search_fields = ('title', 'description', 'seller__username')
    readonly_fields = ('views', 'created_at', 'updated_at')
    filter_horizontal = ()

@admin.register(ProductImage)
class ProductImageAdmin(admin.ModelAdmin):
    list_display = ('product', 'alt_text', 'is_primary', 'created_at')
    list_filter = ('is_primary',)

@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'buyer', 'product', 'quantity', 'total_price', 'status', 'created_at')
    list_filter = ('status', 'ordered_via_chat', 'created_at')
    search_fields = ('buyer__username', 'product__title')
    readonly_fields = ('created_at', 'updated_at')

@admin.register(Wishlist)
class WishlistAdmin(admin.ModelAdmin):
    list_display = ('user', 'product', 'added_at')
    list_filter = ('added_at',)

@admin.register(Review)
class ReviewAdmin(admin.ModelAdmin):
    list_display = ('reviewer', 'product', 'rating', 'created_at')
    list_filter = ('rating', 'created_at')
    search_fields = ('reviewer__username', 'product__title')
