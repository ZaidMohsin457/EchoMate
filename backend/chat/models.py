from django.db import models
from django.contrib.auth.models import User  # Use Django's default User model

class ChatSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='chat_sessions')
    ai_friend_type = models.CharField(max_length=50, choices=[
        ('foodie', 'Foodie Friend'),
        ('travel', 'Travel Guru'),
        ('shopping', 'Shopping Assistant'),
    ])
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    title = models.CharField(max_length=200, blank=True)

    class Meta:
        ordering = ['-updated_at']

    def __str__(self):
        return f"{self.user.username} - {self.get_ai_friend_type_display()}"

class Message(models.Model):
    chat_session = models.ForeignKey(ChatSession, on_delete=models.CASCADE, related_name='messages')
    content = models.TextField()
    is_from_user = models.BooleanField(default=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    metadata = models.JSONField(default=dict, blank=True)  # For storing search results, etc.

    class Meta:
        ordering = ['timestamp']

    def __str__(self):
        sender = "User" if self.is_from_user else "AI"
        return f"{sender}: {self.content[:50]}..."

class Order(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='orders')
    chat_session = models.ForeignKey(ChatSession, on_delete=models.CASCADE, related_name='orders', null=True, blank=True)
    product_name = models.CharField(max_length=200)
    product_url = models.URLField(blank=True)
    price = models.CharField(max_length=50, blank=True)  # Store as string since prices vary
    quantity = models.PositiveIntegerField(default=1)
    status = models.CharField(max_length=50, choices=[
        ('pending', 'Pending'),
        ('confirmed', 'Confirmed'),
        ('processing', 'Processing'),
        ('shipped', 'Shipped'),
        ('delivered', 'Delivered'),
        ('cancelled', 'Cancelled'),
    ], default='pending')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    notes = models.TextField(blank=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.username} - {self.product_name} ({self.status})"
