from django.urls import path
from .views import UserProfileView, UploadAvatarView

urlpatterns = [
    path('profile/', UserProfileView.as_view(), name='user-profile'),
    path('upload-avatar/', UploadAvatarView.as_view(), name='upload-avatar'),
] 