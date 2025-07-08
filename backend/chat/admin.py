from django.contrib import admin
from .models import ChatSession, Message

@admin.register(ChatSession)
class ChatSessionAdmin(admin.ModelAdmin):
    list_display = ['user', 'ai_friend_type', 'title', 'created_at', 'updated_at']
    list_filter = ['ai_friend_type', 'created_at']
    search_fields = ['user__username', 'title']

@admin.register(Message)
class MessageAdmin(admin.ModelAdmin):
    list_display = ['chat_session', 'is_from_user', 'content_preview', 'timestamp']
    list_filter = ['is_from_user', 'timestamp']
    search_fields = ['content', 'chat_session__user__username']
    
    def content_preview(self, obj):
        return obj.content[:50] + "..." if len(obj.content) > 50 else obj.content
