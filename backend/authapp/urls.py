from django.urls import path
from .views import RegisterView, LoginView, TestView, UserProfileView, UserPreferenceGraphView

urlpatterns = [
    path('register/', RegisterView.as_view(), name='register'),
    path('login/', LoginView.as_view(), name='login'),
    path('test/', TestView.as_view(), name='test'),
    path('profile/', UserProfileView.as_view(), name='user-profile'),
    path('preferences/', UserPreferenceGraphView.as_view(), name='user-preferences'),
]