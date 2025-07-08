# AI Companion App - Complete Setup Guide

## 🚀 Your Fully Functional AI Companion App

This app now includes:
- **Real AI Chat** using Groq API
- **Live Search Functionality** using SERP API  
- **Professional UI/UX**
- **Complete Backend Integration**

## 📋 Setup Instructions

### Step 1: Install Backend Dependencies

```bash
cd "backend"
pip install groq requests python-dotenv django djangorestframework djangorestframework-simplejwt django-cors-headers pillow psycopg2-binary django-extensions python-decouple
```

### Step 2: Configure API Keys

1. **Get your Groq API Key**:
   - Go to https://console.groq.com/
   - Create account and get API key

2. **Get your SERP API Key**:
   - Go to https://serpapi.com/
   - Create account and get API key

3. **Update .env file**:
   ```
   GROQ_API_KEY=your_actual_groq_api_key_here
   SERP_API_KEY=your_actual_serp_api_key_here
   ```

### Step 3: Setup Database

```bash
cd "backend"
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser  # Optional: for admin access
```

### Step 4: Install Flutter Dependencies

```bash
cd "ai_companion_app"
flutter pub get
```

### Step 5: Run the Complete App

**Terminal 1 - Backend:**
```bash
cd "backend"
python manage.py runserver
```

**Terminal 2 - Frontend:**
```bash
cd "ai_companion_app"
flutter run -d web-server --web-port 3000
```

## ✨ New Features Added

### 🤖 Real AI Chat Functionality
- **Groq AI Integration**: Powered by Mixtral-8x7B model
- **Three AI Personalities**:
  - **Foodie Friend**: Restaurant recommendations and food advice
  - **Travel Guru**: Travel planning and destination guidance  
  - **Study Buddy**: Academic support and learning assistance
- **Context-Aware Conversations**: AI remembers conversation history
- **Smart Search Integration**: AI responses include relevant search results

### 🔍 Live Search Capabilities
- **SERP API Integration**: Real-time search results
- **Multiple Search Types**:
  - Hotels and accommodations
  - Restaurants and dining
  - Tourist attractions
  - General web search
- **Clickable Results**: Direct links to websites
- **Integrated in Chat**: Search results appear automatically in AI responses

### 💼 Professional Features
- **Real-time Chat**: Instant messaging with AI
- **Message History**: Persistent chat sessions
- **Search Dialog**: Dedicated search interface
- **URL Launcher**: Open search results in browser
- **Loading States**: Professional loading indicators
- **Error Handling**: Comprehensive error management

### 🎨 Enhanced UI/UX
- **Modern Chat Interface**: Beautiful message bubbles
- **Search Result Cards**: Elegant display of search results
- **Responsive Design**: Works perfectly on web
- **Professional Animations**: Smooth transitions
- **Custom Theming**: Consistent design language

## 🛠️ API Endpoints

### Chat Endpoints
- `POST /api/chat/sessions/start/` - Start new chat session
- `GET /api/chat/sessions/` - Get all chat sessions
- `GET /api/chat/sessions/{id}/` - Get chat messages
- `POST /api/chat/sessions/{id}/send/` - Send message
- `DELETE /api/chat/sessions/{id}/delete/` - Delete session

### Search Endpoints  
- `POST /api/chat/search/` - Search places/information

### User Endpoints
- `POST /api/auth/login/` - User login
- `POST /api/auth/register/` - User registration  
- `GET /api/users/profile/` - Get user profile

## 📱 How to Use

1. **Register/Login**: Create account or login
2. **Choose AI Friend**: Select from Foodie, Travel, or Study Buddy
3. **Start Chatting**: Ask questions, get recommendations
4. **Use Search**: Click search icon for specific queries
5. **Get Results**: AI provides answers + relevant search results
6. **Click Links**: Open search results in browser

## 🎯 Example Conversations

**Foodie Friend:**
- "Find me Italian restaurants in New York"
- "What's a good recipe for pasta?"
- "Recommend a wine for dinner"

**Travel Guru:**
- "Plan a trip to Tokyo"
- "Find hotels in Paris under $200"
- "What are the best attractions in London?"

**Study Buddy:**
- "Help me understand calculus"
- "Create a study schedule"
- "Explain quantum physics"

## 🔧 Troubleshooting

1. **Backend won't start**: Check Python dependencies and database migrations
2. **Flutter errors**: Run `flutter clean` then `flutter pub get`
3. **API not working**: Verify API keys in .env file
4. **CORS issues**: Check CORS settings in Django settings.py

## 🎉 You're Ready!

Your AI Companion App is now a fully functional, professional-grade application with real AI capabilities and live search functionality!

Test all features:
- ✅ Registration/Login
- ✅ AI Chat with all three personalities  
- ✅ Search functionality
- ✅ Real-time responses
- ✅ Search result integration
- ✅ Professional UI/UX
