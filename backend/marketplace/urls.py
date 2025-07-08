from django.urls import path
from . import views

app_name = 'marketplace'

urlpatterns = [
    # Categories
    path('categories/', views.CategoryListView.as_view(), name='category-list'),
    
    # Products
    path('products/', views.ProductListView.as_view(), name='product-list'),
    path('products/create/', views.ProductCreateView.as_view(), name='product-create'),
    path('products/my/', views.MyProductsView.as_view(), name='my-products'),
    path('products/search/', views.search_products, name='product-search'),
    path('products/<int:pk>/', views.ProductDetailView.as_view(), name='product-detail'),
    path('products/<int:pk>/update/', views.ProductUpdateView.as_view(), name='product-update'),
    path('products/<int:pk>/delete/', views.ProductDeleteView.as_view(), name='product-delete'),
    
    # Orders
    path('orders/', views.OrderListView.as_view(), name='order-list'),
    path('orders/create/', views.OrderCreateView.as_view(), name='order-create'),
    path('orders/<int:pk>/', views.OrderDetailView.as_view(), name='order-detail'),
    
    # Wishlist
    path('wishlist/', views.WishlistListView.as_view(), name='wishlist'),
    path('wishlist/toggle/<int:product_id>/', views.toggle_wishlist, name='toggle-wishlist'),
    
    # Reviews
    path('products/<int:product_id>/reviews/', views.ReviewListView.as_view(), name='product-reviews'),
    path('reviews/create/', views.ReviewCreateView.as_view(), name='review-create'),
    
    # Chat Integration
    path('chat/create-product/', views.create_product_from_chat, name='chat-create-product'),
    path('chat/create-order/', views.create_order_from_chat, name='chat-create-order'),
]
