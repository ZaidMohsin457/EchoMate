from django.urls import path
from . import views

urlpatterns = [
    path('sessions/', views.get_chat_sessions, name='chat-sessions'),
    path('sessions/start/', views.start_chat_session, name='start-chat'),
    path('sessions/<int:session_id>/', views.get_chat_messages, name='chat-messages'),
    path('sessions/<int:session_id>/send/', views.send_message, name='send-message'),
    path('sessions/<int:session_id>/delete/', views.delete_chat_session, name='delete-chat'),
    path('search/', views.search_places, name='search-places'),
    path('test-ai/', views.test_ai, name='test-ai'),
]
