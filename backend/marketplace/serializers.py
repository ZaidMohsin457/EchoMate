from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Category, Product, ProductImage, Order, Wishlist, Review

class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'description', 'icon', 'created_at']

class ProductImageSerializer(serializers.ModelSerializer):
    class Meta:
        model = ProductImage
        fields = ['id', 'image', 'alt_text', 'is_primary']

class SellerSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']

class ProductSerializer(serializers.ModelSerializer):
    seller = SellerSerializer(read_only=True)
    category = CategorySerializer(read_only=True)
    category_id = serializers.IntegerField(write_only=True)
    images = ProductImageSerializer(many=True, read_only=True)
    image = serializers.ImageField(write_only=True, required=False)  # For single image upload
    average_rating = serializers.SerializerMethodField()
    review_count = serializers.SerializerMethodField()
    
    class Meta:
        model = Product
        fields = [
            'id', 'seller', 'title', 'description', 'category', 'category_id',
            'product_type', 'price', 'currency', 'negotiable', 'condition',
            'brand', 'model', 'location', 'latitude', 'longitude',
            'image_url', 'image_urls', 'available', 'quantity', 'amenities',
            'rating', 'listed_via_chat', 'views', 'created_at', 'updated_at',
            'images', 'image', 'average_rating', 'review_count', 'status'
        ]
        read_only_fields = ['seller', 'views', 'created_at', 'updated_at']
    
    def get_average_rating(self, obj):
        reviews = obj.reviews.all()
        if reviews:
            return sum(review.rating for review in reviews) / len(reviews)
        return None
    
    def get_review_count(self, obj):
        return obj.reviews.count()
    
    def create(self, validated_data):
        # Extract image from validated_data if present
        image_file = validated_data.pop('image', None)
        
        # Ensure category_id is set - use default if not provided
        if 'category_id' not in validated_data:
            from .models import Category
            default_category = Category.objects.get_or_create(name='General')[0]
            validated_data['category_id'] = default_category.id
        
        # Ensure product is available by default - force it to True
        validated_data['available'] = True
        
        # Set seller to current user (for now use a default seller since auth is disabled)
        request = self.context.get('request')
        if request and hasattr(request, 'user') and request.user.is_authenticated:
            validated_data['seller'] = request.user
        else:
            # For testing without auth, use first user or create one
            from django.contrib.auth.models import User
            seller, created = User.objects.get_or_create(username='test_seller')
            validated_data['seller'] = seller
        
        # Create the product
        product = super().create(validated_data)
        
        # Create ProductImage if image was uploaded
        if image_file:
            ProductImage.objects.create(
                product=product,
                image=image_file,
                is_primary=True
            )
        
        return product

class ProductListSerializer(serializers.ModelSerializer):
    """Simplified serializer for listing products"""
    seller = SellerSerializer(read_only=True)
    category = CategorySerializer(read_only=True)
    images = ProductImageSerializer(many=True, read_only=True)  # Add images field
    average_rating = serializers.SerializerMethodField()
    
    class Meta:
        model = Product
        fields = [
            'id', 'seller', 'title', 'category', 'product_type', 'price',
            'currency', 'condition', 'location', 'image_url', 'available',
            'rating', 'created_at', 'average_rating', 'images', 'status', 'quantity'  # Add quantity
        ]
    
    def get_average_rating(self, obj):
        reviews = obj.reviews.all()
        if reviews:
            return round(sum(review.rating for review in reviews) / len(reviews), 1)
        return None

class OrderSerializer(serializers.ModelSerializer):
    buyer = SellerSerializer(read_only=True)
    product = ProductListSerializer(read_only=True)
    product_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = Order
        fields = [
            'id', 'buyer', 'product', 'product_id', 'quantity', 'total_price',
            'status', 'buyer_email', 'buyer_phone', 'delivery_address',
            'ordered_via_chat', 'created_at', 'updated_at'
        ]
        read_only_fields = ['buyer', 'total_price', 'created_at', 'updated_at']
    
    def create(self, validated_data):
        # For testing without authentication, create or get a default user
        request = self.context['request']
        if hasattr(request, 'user') and request.user.is_authenticated:
            validated_data['buyer'] = request.user
        else:
            # For testing - use or create a default buyer
            from django.contrib.auth.models import User
            default_user, created = User.objects.get_or_create(
                username='anonymous_buyer',
                defaults={'email': 'test@example.com'}
            )
            validated_data['buyer'] = default_user
        
        # Calculate total price
        product = Product.objects.get(id=validated_data['product_id'])
        validated_data['total_price'] = product.price * validated_data['quantity']
        
        # Create the order
        order = super().create(validated_data)
        
        # Mark product as sold if quantity becomes 0
        if product.quantity <= validated_data['quantity']:
            product.status = 'sold'
            product.available = False
        else:
            # Reduce quantity
            product.quantity -= validated_data['quantity']
        
        product.save()
        return order

class WishlistSerializer(serializers.ModelSerializer):
    product = ProductListSerializer(read_only=True)
    product_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = Wishlist
        fields = ['id', 'product', 'product_id', 'added_at']
        read_only_fields = ['added_at']

class ReviewSerializer(serializers.ModelSerializer):
    reviewer = SellerSerializer(read_only=True)
    product = ProductListSerializer(read_only=True)
    product_id = serializers.IntegerField(write_only=True)
    
    class Meta:
        model = Review
        fields = [
            'id', 'reviewer', 'product', 'product_id', 'rating',
            'comment', 'created_at'
        ]
        read_only_fields = ['reviewer', 'created_at']
    
    def create(self, validated_data):
        validated_data['reviewer'] = self.context['request'].user
        return super().create(validated_data)
