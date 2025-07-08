# AI Companion App - Complete Setup & Features

## 🎬 Demo Video
https://drive.google.com/file/d/1o6aj_nV8uwjSK6q5WwFzi06Ilq4NttYH/view?usp=drive_link
---

## 🎉 **COMPLETED FEATURES**

### ✅ **Backend (Django)**
1. **User Authentication & Authorization**
   - JWT-based authentication
   - User registration and login
   - Secure API endpoints

2. **User Profile Management**
   - UserProfile model with avatar and bio fields
   - REST API endpoints for profile CRUD operations
   - Django admin integration

3. **Knowledge Graph-based Preferences**
   - UserPreferenceGraph model with JSON field
   - Personalized user preferences storage
   - Categories: Shopping, Price Range, Communication Style, etc.

4. **AI Chat System**
   - Multiple AI assistants (Foodie Friend, Travel Guru, Shopping Assistant)
   - Conversation history management
   - User preferences integration into AI context
   - Search functionality with SERP API

5. **Database & Migrations**
   - All models properly migrated
   - Database relationships established
   - Admin interface configured

### ✅ **Frontend (Flutter)**
1. **Authentication System**
   - Login and registration screens
   - JWT token management with secure storage
   - API service integration

2. **Profile Management Screen**
   - User profile viewing and editing
   - Bio field management
   - Preference categories with filter chips
   - Intuitive UI with Material Design

3. **Home Screen**
   - AI friend selection
   - Profile and logout navigation
   - User greeting with profile info

4. **Chat Interface**
   - Real-time messaging with AI assistants
   - Message history
   - Personalized responses based on user preferences

5. **API Integration**
   - Complete API service with all endpoints
   - Error handling and loading states
   - Secure token management

### ✅ **Knowledge Graph Integration**
- User preferences stored as structured data
- AI assistants receive user context
- Personalized recommendations and responses
- Preference categories:
  - Shopping Categories (Electronics, Fashion, etc.)
  - Price Range (Budget-friendly, Premium, etc.)
  - Shopping Style (Quick & Efficient, Research-heavy, etc.)
  - Communication Style (Brief & Direct, Friendly & Casual, etc.)

## 🚀 **HOW TO USE THE APP**

### **Backend Setup:**
1. Navigate to backend directory: `cd backend`
2. Start Django server: `python manage.py runserver`
3. Access admin at: http://localhost:8000/admin/

### **Flutter App Setup:**
1. Navigate to Flutter directory: `cd ai_companion_app`
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

### **App Usage Flow:**
1. **Register/Login** - Create account or sign in
2. **Set Profile** - Click profile icon → Add bio and preferences
3. **Chat with AI** - Select Shopping Assistant (or other AI friends)
4. **Personalized Experience** - AI uses your preferences for better responses

## 📱 **Key Features in Action**

### **Profile Screen:**
- View/edit user information
- Select shopping preferences with filter chips
- Save preferences that influence AI behavior

### **AI Chat:**
- Shopping Assistant knows your preferred categories
- Responses tailored to your price range preferences
- Communication style matches your settings

### **Personalization:**
- AI context includes: "User preferences: Shopping Categories: Electronics, Fashion; Price Range: Budget-friendly; Communication Style: Friendly & Casual"
- More relevant product suggestions
- Better conversation flow

## 🔧 **Technical Architecture**

### **Backend:**
- Django REST Framework
- JWT Authentication
- PostgreSQL/SQLite database
- Groq API for AI responses
- SERP API for search functionality

### **Frontend:**
- Flutter with Material Design
- Dio for HTTP requests
- Secure storage for tokens
- State management

### **Integration:**
- RESTful API communication
- Knowledge graph stored as JSON
- Real-time preference application
- Comprehensive error handling

## ✅ **Test Results**
All functionality has been tested and verified:
- ✅ Backend API connectivity
- ✅ User registration and authentication
- ✅ Profile management
- ✅ Preferences system
- ✅ Chat functionality
- ✅ Knowledge graph integration

## 🎯 **Ready for Production**
The AI Companion app is now fully functional with:
- Complete user management
- Personalized AI interactions
- Profile and preferences management
- Robust error handling
- Clean, intuitive UI
- Secure authentication
- Knowledge graph-based personalization

**Status: 🟢 FULLY FUNCTIONAL AND READY TO USE!**
