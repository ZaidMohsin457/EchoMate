from django.shortcuts import render
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .serializers import RegisterSerializer, LoginSerializer, UserProfileSerializer, UserPreferenceGraphSerializer
from django.contrib.auth.models import User  # Use Django's default User model
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication
from .models import UserProfile, UserPreferenceGraph
import logging

logger = logging.getLogger(__name__)

# Create your views here.

class RegisterView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []  # Explicitly disable authentication for registration
    
    def post(self, request):
        logger.info(f"Registration attempt with data: {request.data}")
        serializer = RegisterSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            logger.info(f"User created successfully: {user.username}")
            return Response({'message': 'User registered successfully.'}, status=status.HTTP_201_CREATED)
        logger.error(f"Registration failed with errors: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []  # Explicitly disable authentication for login
    
    def post(self, request):
        logger.info(f"Login attempt with data: {request.data}")
        serializer = LoginSerializer(data=request.data)
        if serializer.is_valid():
            username = serializer.validated_data['username']
            password = serializer.validated_data['password']
            user = authenticate(username=username, password=password)
            if user is not None:
                refresh = RefreshToken.for_user(user)
                logger.info(f"Login successful for user: {username}")
                return Response({
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                }, status=status.HTTP_200_OK)
            logger.error(f"Invalid credentials for user: {username}")
            return Response({'detail': 'Invalid credentials.'}, status=status.HTTP_401_UNAUTHORIZED)
        logger.error(f"Login failed with errors: {serializer.errors}")
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class TestView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []  # Explicitly disable authentication for test
    def get(self, request):
        return Response({'message': 'Backend is working!', 'status': 'ok'}, status=status.HTTP_200_OK)

class UserProfileView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        serializer = UserProfileSerializer(profile)
        return Response(serializer.data)

    def put(self, request):
        profile, _ = UserProfile.objects.get_or_create(user=request.user)
        serializer = UserProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class UserPreferenceGraphView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def get(self, request):
        pref_graph, _ = UserPreferenceGraph.objects.get_or_create(user=request.user)
        serializer = UserPreferenceGraphSerializer(pref_graph)
        return Response(serializer.data)

    def put(self, request):
        pref_graph, _ = UserPreferenceGraph.objects.get_or_create(user=request.user)
        serializer = UserPreferenceGraphSerializer(pref_graph, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
