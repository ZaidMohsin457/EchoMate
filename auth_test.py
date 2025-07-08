#!/usr/bin/env python
"""
Quick test to verify JWT authentication is working
"""
import requests
import json

def test_auth_flow():
    print("Testing Authentication Flow...")
    
    # Test 1: Login
    print("\n1. Testing Login...")
    login_data = {
        "username": "testuser123",
        "password": "testpass123"
    }
    
    try:
        response = requests.post("http://localhost:8000/api/auth/login/", json=login_data)
        print(f"Login Status: {response.status_code}")
        print(f"Login Response: {response.text}")
        
        if response.status_code == 200:
            token_data = response.json()
            access_token = token_data.get('access')
            print(f"Access Token: {access_token[:50]}..." if access_token else "No access token")
            
            # Test 2: Profile access with token
            if access_token:
                print("\n2. Testing Profile Access...")
                headers = {"Authorization": f"Bearer {access_token}"}
                profile_response = requests.get("http://localhost:8000/api/auth/profile/", headers=headers)
                print(f"Profile Status: {profile_response.status_code}")
                print(f"Profile Response: {profile_response.text}")
                
                # Test 3: Chat session creation
                print("\n3. Testing Chat Session...")
                chat_data = {"ai_friend_type": "shopping"}
                chat_response = requests.post("http://localhost:8000/api/chat/sessions/start/", json=chat_data, headers=headers)
                print(f"Chat Status: {chat_response.status_code}")
                print(f"Chat Response: {chat_response.text}")
                
                if profile_response.status_code == 200 and chat_response.status_code in [200, 201]:
                    print("\n✅ Authentication is working correctly!")
                    return True
                else:
                    print("\n❌ Authentication issues detected")
                    return False
            else:
                print("\n❌ No access token received")
                return False
        else:
            print(f"\n❌ Login failed with status {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    test_auth_flow()
