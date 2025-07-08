from django.db import models
from django.contrib.auth.models import User

# Create your models here.

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    avatar = models.ImageField(upload_to='avatars/', blank=True, null=True)
    bio = models.TextField(blank=True)
    # Add more fields as needed

    def __str__(self):
        return self.user.username

class UserPreferenceGraph(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='preference_graph')
    graph = models.JSONField(default=dict, blank=True)  # Store as a simple knowledge graph (nodes/edges or key-value)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.user.username} Preferences Graph"
