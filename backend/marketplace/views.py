from rest_framework import status, generics, filters
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.shortcuts import get_object_or_404
from django.db.models import Q, Avg

from .models import Category, Product, ProductImage, Order, Wishlist, Review
from .serializers import (
    CategorySerializer, ProductSerializer, ProductListSerializer,
    OrderSerializer, WishlistSerializer, ReviewSerializer
)

# Category Views
class CategoryListView(generics.ListCreateAPIView):
    queryset = Category.objects.all()
    serializer_class = CategorySerializer
    permission_classes = [AllowAny]  # Categories can be viewed by anyone

# Product Views
class ProductListView(generics.ListAPIView):
    queryset = Product.objects.filter(available=True)
    serializer_class = ProductListSerializer
    permission_classes = [AllowAny]
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['title', 'description', 'brand', 'location']
    ordering_fields = ['created_at', 'price', 'views']
    ordering = ['-created_at']

class ProductDetailView(generics.RetrieveAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [AllowAny]
    
    def get_object(self):
        obj = super().get_object()
        # Increment view count
        obj.views += 1
        obj.save(update_fields=['views'])
        return obj

class ProductCreateView(generics.CreateAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [AllowAny]  # Temporarily allow anyone for testing

class ProductUpdateView(generics.UpdateAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        # Users can only update their own products
        return Product.objects.filter(seller=self.request.user)

class ProductDeleteView(generics.DestroyAPIView):
    queryset = Product.objects.all()
    permission_classes = [AllowAny]  # Allow anyone for testing

class MyProductsView(generics.ListAPIView):
    serializer_class = ProductListSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Product.objects.filter(seller=self.request.user).order_by('-created_at')

# Search and Filter Views
@api_view(['GET'])
@permission_classes([AllowAny])
def search_products(request):
    """Advanced product search with filters"""
    query = request.GET.get('q', '')
    category_id = request.GET.get('category')
    product_type = request.GET.get('type')
    min_price = request.GET.get('min_price')
    max_price = request.GET.get('max_price')
    location = request.GET.get('location')
    condition = request.GET.get('condition')
    
    products = Product.objects.filter(available=True)
    
    if query:
        products = products.filter(
            Q(title__icontains=query) |
            Q(description__icontains=query) |
            Q(brand__icontains=query) |
            Q(location__icontains=query)
        )
    
    if category_id:
        products = products.filter(category_id=category_id)
    
    if product_type:
        products = products.filter(product_type=product_type)
    
    if min_price:
        products = products.filter(price__gte=min_price)
    
    if max_price:
        products = products.filter(price__lte=max_price)
    
    if location:
        products = products.filter(location__icontains=location)
    
    if condition:
        products = products.filter(condition=condition)
    
    products = products.order_by('-created_at')[:20]  # Limit to 20 results
    
    serializer = ProductListSerializer(products, many=True)
    return Response({
        'count': len(products),
        'results': serializer.data
    })

# Order Views
class OrderCreateView(generics.CreateAPIView):
    queryset = Order.objects.all()
    serializer_class = OrderSerializer
    permission_classes = [AllowAny]  # Temporarily allow anyone for testing

class OrderListView(generics.ListAPIView):
    serializer_class = OrderSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Order.objects.filter(buyer=self.request.user).order_by('-created_at')

class OrderDetailView(generics.RetrieveAPIView):
    serializer_class = OrderSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Order.objects.filter(buyer=self.request.user)

# Wishlist Views
class WishlistListView(generics.ListAPIView):
    serializer_class = WishlistSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]
    
    def get_queryset(self):
        return Wishlist.objects.filter(user=self.request.user).order_by('-added_at')

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def toggle_wishlist(request, product_id):
    """Add or remove product from wishlist"""
    try:
        product = get_object_or_404(Product, id=product_id)
        wishlist_item, created = Wishlist.objects.get_or_create(
            user=request.user,
            product=product
        )
        
        if not created:
            # Remove from wishlist
            wishlist_item.delete()
            return Response({
                'message': 'Product removed from wishlist',
                'in_wishlist': False
            })
        else:
            # Added to wishlist
            return Response({
                'message': 'Product added to wishlist',
                'in_wishlist': True
            })
    except Exception as e:
        return Response({
            'error': str(e)
        }, status=status.HTTP_400_BAD_REQUEST)

# Review Views
class ReviewListView(generics.ListAPIView):
    serializer_class = ReviewSerializer
    permission_classes = [AllowAny]
    
    def get_queryset(self):
        product_id = self.kwargs.get('product_id')
        return Review.objects.filter(product_id=product_id).order_by('-created_at')

class ReviewCreateView(generics.CreateAPIView):
    queryset = Review.objects.all()
    serializer_class = ReviewSerializer
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

# Chat Integration Views
@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def create_product_from_chat(request):
    """Create a product listing from chat interaction"""
    data = request.data.copy()
    data['listed_via_chat'] = True
    data['chat_session_id'] = request.data.get('chat_session_id')
    
    serializer = ProductSerializer(data=data, context={'request': request})
    if serializer.is_valid():
        product = serializer.save()
        return Response({
            'message': 'Product listed successfully via chat!',
            'product': ProductSerializer(product).data
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def create_order_from_chat(request):
    """Create an order from chat interaction"""
    data = request.data.copy()
    data['ordered_via_chat'] = True
    data['chat_session_id'] = request.data.get('chat_session_id')
    
    serializer = OrderSerializer(data=data, context={'request': request})
    if serializer.is_valid():
        order = serializer.save()
        return Response({
            'message': 'Order placed successfully via chat!',
            'order': OrderSerializer(order).data
        }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
