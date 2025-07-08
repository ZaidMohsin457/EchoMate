from django.contrib import admin
from .models import AIFriend, SearchQuery

@admin.register(AIFriend)
class AIFriendAdmin(admin.ModelAdmin):
    list_display = ['name', 'friend_type', 'is_active']
    list_filter = ['friend_type', 'is_active']
    search_fields = ['name', 'description']

@admin.register(SearchQuery)
class SearchQueryAdmin(admin.ModelAdmin):
    list_display = ['query', 'query_type', 'timestamp']
    list_filter = ['query_type', 'timestamp']
    search_fields = ['query']
