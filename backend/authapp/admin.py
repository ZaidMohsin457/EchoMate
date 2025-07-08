from django.contrib import admin
from .models import UserProfile, UserPreferenceGraph

# Register your models here.

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'bio')
    search_fields = ('user__username', 'user__email')
    list_filter = ('user__date_joined',)

@admin.register(UserPreferenceGraph)
class UserPreferenceGraphAdmin(admin.ModelAdmin):
    list_display = ('user', 'updated_at')
    search_fields = ('user__username',)
    list_filter = ('updated_at',)
    readonly_fields = ('updated_at',)
