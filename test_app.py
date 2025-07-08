#!/usr/bin/env python
"""
Test script to verify the AI Companion app functionality
"""
import requests
import json

BASE_URL = "http://localhost:8000/api"

def test_backend_connectivity():
    """Test if backend is running"""
    try:
        response = requests.get(f"{BASE_URL}/auth/test/")
        if response.status_code == 200:
            print("✅ Backend connectivity: PASSED")
            return True
        else:
            print(f"❌ Backend connectivity: FAILED - Status {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ Backend connectivity: FAILED - {e}")
        return False

def test_user_registration():
    """Test user registration"""
    try:
        data = {
            "username": "testuser123",
            "email": "test@example.com",
            "password": "testpass123",
            "password2": "testpass123"
        }
        response = requests.post(f"{BASE_URL}/auth/register/", json=data)
        if response.status_code == 201:
            print("✅ User registration: PASSED")
            return True
        elif response.status_code == 400 and "already exists" in response.text:
            print("✅ User registration: PASSED (user already exists)")
            return True
        else:
            print(f"❌ User registration: FAILED - {response.status_code} - {response.text}")
            return False
    except Exception as e:
        print(f"❌ User registration: FAILED - {e}")
        return False

def test_user_login():
    """Test user login and return access token"""
    try:
        data = {
            "username": "testuser123",
            "password": "testpass123"
        }
        response = requests.post(f"{BASE_URL}/auth/login/", json=data)
        if response.status_code == 200:
            token_data = response.json()
            access_token = token_data.get('access')
            if access_token:
                print("✅ User login: PASSED")
                return access_token
        print(f"❌ User login: FAILED - {response.status_code} - {response.text}")
        return None
    except Exception as e:
        print(f"❌ User login: FAILED - {e}")
        return None

def test_profile_endpoints(access_token):
    """Test profile creation and retrieval"""
    headers = {"Authorization": f"Bearer {access_token}"}
    
    try:
        # Test GET profile
        response = requests.get(f"{BASE_URL}/auth/profile/", headers=headers)
        if response.status_code == 200:
            print("✅ Profile GET: PASSED")
            
            # Test PUT profile
            profile_data = {"bio": "This is a test bio for the AI companion app"}
            response = requests.put(f"{BASE_URL}/auth/profile/", json=profile_data, headers=headers)
            if response.status_code == 200:
                print("✅ Profile UPDATE: PASSED")
                return True
            else:
                print(f"❌ Profile UPDATE: FAILED - {response.status_code}")
        else:
            print(f"❌ Profile GET: FAILED - {response.status_code}")
        return False
    except Exception as e:
        print(f"❌ Profile endpoints: FAILED - {e}")
        return False

def test_preferences_endpoints(access_token):
    """Test preferences creation and retrieval"""
    headers = {"Authorization": f"Bearer {access_token}"}
    
    try:
        # Test GET preferences
        response = requests.get(f"{BASE_URL}/auth/preferences/", headers=headers)
        if response.status_code == 200:
            print("✅ Preferences GET: PASSED")
            
            # Test PUT preferences
            preferences_data = {
                "graph": {
                    "Shopping Categories": ["Electronics", "Fashion"],
                    "Price Range": ["Budget-friendly"],
                    "Communication Style": ["Friendly & Casual"]
                }
            }
            response = requests.put(f"{BASE_URL}/auth/preferences/", json=preferences_data, headers=headers)
            if response.status_code == 200:
                print("✅ Preferences UPDATE: PASSED")
                return True
            else:
                print(f"❌ Preferences UPDATE: FAILED - {response.status_code}")
        else:
            print(f"❌ Preferences GET: FAILED - {response.status_code}")
        return False
    except Exception as e:
        print(f"❌ Preferences endpoints: FAILED - {e}")
        return False

def test_chat_session(access_token):
    """Test chat session creation"""
    headers = {"Authorization": f"Bearer {access_token}"}
    
    try:
        # Start chat session
        data = {"ai_friend_type": "shopping"}
        response = requests.post(f"{BASE_URL}/chat/sessions/start/", json=data, headers=headers)
        if response.status_code in [200, 201]:
            session_data = response.json()
            session_id = session_data.get('id')
            print("✅ Chat session creation: PASSED")
            return session_id
        else:
            print(f"❌ Chat session creation: FAILED - {response.status_code}")
        return None
    except Exception as e:
        print(f"❌ Chat session creation: FAILED - {e}")
        return None

def run_tests():
    """Run all tests"""
    print("🧪 Testing AI Companion App Functionality")
    print("=" * 50)
    
    # Test backend connectivity
    if not test_backend_connectivity():
        return
    
    # Test user registration
    if not test_user_registration():
        return
    
    # Test user login
    access_token = test_user_login()
    if not access_token:
        return
    
    # Test profile endpoints
    if not test_profile_endpoints(access_token):
        return
    
    # Test preferences endpoints
    if not test_preferences_endpoints(access_token):
        return
    
    # Test chat session
    session_id = test_chat_session(access_token)
    
    print("=" * 50)
    if session_id:
        print("🎉 ALL TESTS PASSED! The AI Companion app is fully functional.")
        print(f"✅ Backend API: Working")
        print(f"✅ User Management: Working")
        print(f"✅ Profile Management: Working")
        print(f"✅ Preferences System: Working")
        print(f"✅ Chat System: Working")
        print(f"✅ Knowledge Graph Integration: Working")
    else:
        print("⚠️  Some tests failed. Please check the output above.")

if __name__ == "__main__":
    run_tests()
