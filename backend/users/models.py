from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    # Add extra fields here if needed (e.g., avatar, phone, etc.)
    avatar = models.ImageField(upload_to='avatars/', null=True, blank=True)
    # Example: phone = models.CharField(max_length=20, blank=True, null=True)

    def __str__(self):
        return self.username
