from django.db import models

class AIFriend(models.Model):
    name = models.CharField(max_length=100)
    friend_type = models.CharField(max_length=50, unique=True)
    description = models.TextField()
    system_prompt = models.TextField()
    avatar_url = models.URLField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    
    def __str__(self):
        return self.name

class SearchQuery(models.Model):
    query = models.CharField(max_length=500)
    query_type = models.CharField(max_length=50, choices=[
        ('hotels', 'Hotels'),
        ('restaurants', 'Restaurants'),
        ('attractions', 'Tourist Attractions'),
        ('flights', 'Flights'),
        ('general', 'General Search'),
    ])
    results = models.JSONField(default=dict)
    timestamp = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.query_type}: {self.query[:50]}"
