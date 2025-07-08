import os
import requests
from groq import Groq
from django.conf import settings

class AIService:
    def detect_marketplace_intent(self, message):
        """Detect if the user wants to list, buy, or search marketplace items."""
        msg = message.lower()
        
        # Enhanced keyword detection for listing
        list_keywords = [
            "sell", "list product", "add product", "create listing", "post product",
            "list hotel", "add hotel", "want to sell", "selling my", "list my"
        ]
        if any(keyword in msg for keyword in list_keywords):
            return "list"
        
        # Enhanced keyword detection for buying
        buy_keywords = [
            "buy", "order", "purchase", "book hotel", "book room", "want to buy",
            "looking for", "need to buy", "ordering", "get me", "find me",
            "i want", "want a", "want an", "need a", "need an", "get a"
        ]
        if any(keyword in msg for keyword in buy_keywords):
            return "buy"
        
        # Enhanced keyword detection for searching/browsing
        search_keywords = [
            "find", "search", "show products", "show items", "browse", "what's available",
            "see products", "list products", "marketplace", "what do you have",
            "available products", "show me", "display", "view products"
        ]
        if any(keyword in msg for keyword in search_keywords):
            return "search"
            
        return None

    def extract_search_keywords(self, message):
        """Extract product/search keywords from a chat message."""
        import re
        
        # Remove common phrases and words that aren't product names
        stop_words = [
            'i', 'want', 'need', 'looking', 'for', 'find', 'search', 'show', 'me',
            'buy', 'purchase', 'order', 'get', 'a', 'an', 'the', 'some', 'any',
            'to', 'can', 'you', 'help', 'please', 'thanks', 'hello', 'hi',
            'do', 'have', 'is', 'are', 'there', 'what', 'where', 'how', 'much'
        ]
        
        # Clean the message - remove punctuation and convert to lowercase
        cleaned = re.sub(r'[^\w\s]', '', message.lower())
        words = cleaned.split()
        
        # Filter out stop words and short words
        keywords = [word for word in words if word not in stop_words and len(word) > 2]
        
        # Join remaining words as search query
        search_query = ' '.join(keywords)
        
        # If no meaningful keywords found, return the original message
        return search_query if search_query.strip() else message

    def fetch_marketplace_items(self, query=None, category=None, item_type=None):
        """Fetch products or hotels from the marketplace app via API."""
        from django.urls import reverse
        import django
        from django.test import Client
        # Use Django test client for internal API calls (no auth)
        client = Client()
        url = reverse('marketplace:product-list')
        params = {}
        if query:
            params['search'] = query
        if category:
            params['category'] = category
        if item_type:
            params['type'] = item_type
        response = client.get(url, params)
        if response.status_code == 200:
            return response.json()
        return []

    def create_marketplace_product_from_chat(self, user, chat_message):
        """Create a product/hotel listing from chat message (improved version)."""
        import re
        from marketplace.models import Product, Category
        
        # Extract price from message using regex
        price_match = re.search(r'\$?(\d+(?:\.\d{2})?)', chat_message)
        price = float(price_match.group(1)) if price_match else 50.0
        
        # Extract title/product name (basic extraction)
        # Look for patterns like "sell my [item]" or "selling [item]"
        title_patterns = [
            r'sell my (.+?) for',
            r'selling (.+?) for',
            r'sell (.+?) for',
            r'my (.+?) for',
            r'a (.+?) for'
        ]
        
        title = None
        for pattern in title_patterns:
            match = re.search(pattern, chat_message.lower())
            if match:
                title = match.group(1).strip()
                break
        
        if not title:
            # Fallback: extract words between common keywords
            words = chat_message.lower().split()
            sell_index = -1
            for i, word in enumerate(words):
                if word in ['sell', 'selling']:
                    sell_index = i
                    break
            
            if sell_index >= 0 and sell_index + 1 < len(words):
                title = ' '.join(words[sell_index + 1:sell_index + 4])  # Take next 3 words
            else:
                title = chat_message[:30]  # Fallback to first 30 chars
        
        # Clean up title
        title = title.replace('my ', '').replace('a ', '').replace('the ', '')
        title = ' '.join(title.split()[:5])  # Limit to 5 words
        title = title.title()  # Capitalize
        
        # Create the product
        category, _ = Category.objects.get_or_create(name="General")
        product = Product.objects.create(
            title=title,
            description=chat_message,
            price=price,
            category=category,
            seller=user,
            listed_via_chat=True,
            available=True
        )
        return product

    def create_marketplace_order_from_chat(self, user, product_id):
        """Create an order for a product from chat."""
        from marketplace.models import Order, Product
        product = Product.objects.get(id=product_id)
        order = Order.objects.create(
            buyer=user,
            product=product,
            quantity=1,  # Default quantity
            total_price=product.price,  # Calculate total price
            buyer_email=user.email or f"{user.username}@example.com",  # Default email
            status="pending",
            ordered_via_chat=True  # Mark as ordered via chat
        )
        
        # Mark product as sold if quantity becomes 0
        if product.quantity <= 1:
            product.status = 'sold'
            product.available = False
        else:
            # Reduce quantity
            product.quantity -= 1
        
        product.save()
        return order

    def format_marketplace_results_for_chat(self, items):
        """Format product/hotel results for chat display."""
        if not items:
            return "No products or hotels found in our marketplace."
        
        lines = []
        for i, item in enumerate(items[:5], 1):
            title = item.get('title', 'Unknown Product')
            price = item.get('price', 'N/A')
            desc = item.get('description', 'No description available')[:100]
            product_id = item.get('id', '')
            seller = item.get('seller', {}).get('username', 'Unknown Seller')
            
            line = f"🛍️ {i}. **{title}** - ${price}\n"
            line += f"   📝 {desc}...\n"
            line += f"   👤 Seller: {seller}\n"
            line += f"   🆔 Product ID: {product_id}"
            
            lines.append(line)
        
        result = "\n\n".join(lines)
        result += "\n\n💡 **To place an order**, reply with: 'order [product_id]' or 'buy [product_id]'"
        result += "\n📱 **To view in app**, go to Marketplace section"
        
        return result

    def process_order_from_chat(self, user, message):
        """Process order commands from chat like 'order 123' or 'buy 123'"""
        import re
        
        # Extract product ID from message
        order_match = re.search(r'(?:order|buy|purchase)\s+(\d+)', message.lower())
        if order_match:
            product_id = int(order_match.group(1))
            try:
                order = self.create_marketplace_order_from_chat(user, product_id)
                return f"✅ **Order Created Successfully!**\n\n🆔 Order ID: {order.id}\n📦 Product: {order.product.title}\n💰 Price: ${order.product.price}\n📊 Status: {order.status}\n\n📱 You can track your order in the Marketplace section of the app."
            except Exception as e:
                return f"❌ **Order Failed**: {str(e)}\n\n💡 Please check the product ID and try again."
        
        return None
    def __init__(self):
        self.groq_client = Groq(api_key=settings.GROQ_API_KEY)
    
    def get_user_preferences_context(self, user):
        """Get user preferences as context for AI"""
        try:
            from authapp.models import UserPreferenceGraph
            pref_graph, _ = UserPreferenceGraph.objects.get_or_create(user=user)
            
            if not pref_graph.graph:
                return ""
            
            # Format preferences as readable context
            context_parts = []
            for category, preferences in pref_graph.graph.items():
                if preferences:  # Only include non-empty preference lists
                    pref_list = ", ".join(preferences)
                    context_parts.append(f"{category}: {pref_list}")
            
            return "; ".join(context_parts) if context_parts else ""
        except Exception as e:
            print(f"Error getting user preferences: {e}")
            return ""
        
    def get_ai_response(self, message, ai_friend_type, conversation_history=None, user=None):
        """Get AI response using Groq API"""
        
        # Get user preferences context
        preferences_context = ""
        if user:
            preferences_context = self.get_user_preferences_context(user)
        
        system_prompts = {
            'foodie': f"""You are Foodie Friend, an enthusiastic food expert and restaurant recommender. 
            You help users discover amazing restaurants, cuisines, and food experiences. You're knowledgeable 
            about different types of food, dietary restrictions, and can suggest restaurants based on location, 
            cuisine type, budget, and preferences. Be friendly, enthusiastic about food, and helpful.
            {f"User's preferences: {preferences_context}" if preferences_context else ""}""",
            
            'travel': f"""You are Travel Guru, a knowledgeable travel advisor and guide. You help users plan 
            trips, find accommodations, discover attractions, and navigate travel logistics. You're expert in 
            destinations worldwide, travel tips, budgeting, and creating memorable experiences. Be helpful, 
            informative, and inspiring about travel.
            {f"User's preferences: {preferences_context}" if preferences_context else ""}""",
            
            'shopping': f"""You are Shopping Assistant, your personal shopping companion. You help users find 
            products, compare prices, read reviews, and assist with purchase decisions. You can search for any 
            product the user wants, provide detailed product information, suggest alternatives, and help guide 
            them through the ordering process. You're knowledgeable about e-commerce, product categories, 
            brands, and shopping best practices. Be helpful, informative, and enthusiastic about finding 
            the perfect products for users.
            {f"User's preferences: {preferences_context}" if preferences_context else ""}"""
        }
        
        system_prompt = system_prompts.get(ai_friend_type, system_prompts['foodie'])
        
        messages = [{"role": "system", "content": system_prompt}]
        
        # Add conversation history
        if conversation_history:
            # Convert QuerySet to list and get last 10 messages
            history_list = list(conversation_history)
            for msg in history_list[-10:]:  # Last 10 messages for context
                role = "user" if msg.is_from_user else "assistant"
                messages.append({"role": role, "content": msg.content})
        
        messages.append({"role": "user", "content": message})
        
        try:
            chat_completion = self.groq_client.chat.completions.create(
                messages=messages,
                model="llama3-8b-8192",  # Updated to supported model
                temperature=0.7,
                max_tokens=1000,
            )
            return chat_completion.choices[0].message.content
        except Exception as e:
            print(f"Groq API Error: {str(e)}")
            import traceback
            print(f"Full traceback: {traceback.format_exc()}")
            return f"I'm sorry, I'm having trouble responding right now. Please try again. Error: {str(e)}"

class SearchService:
    def __init__(self):
        self.serp_api_key = settings.SERP_API_KEY
        
    def search_places(self, query, search_type="general", location=None):
        """Search for places using SERP API"""
        if not self.serp_api_key:
            return {"error": "Search service not configured"}
            
        try:
            # Construct search query based on type
            search_queries = {
                'hotels': f"hotels in {location or ''} {query}",
                'restaurants': f"restaurants {query} {location or ''}",
                'attractions': f"tourist attractions {query} {location or ''}",
                'flights': f"flights {query}",
                'products': f"buy {query} online shopping",
                'shopping': f"{query} price compare buy online",
                'general': query
            }
            
            search_query = search_queries.get(search_type, query)
            
            url = "https://serpapi.com/search"
            params = {
                "engine": "google",
                "q": search_query,
                "api_key": self.serp_api_key,
                "num": 5
            }
            
            if search_type in ['hotels', 'restaurants', 'attractions'] and location:
                params["location"] = location
                
            response = requests.get(url, params=params)
            data = response.json()
            
            # Process results based on search type
            if search_type == 'hotels':
                return self._process_hotel_results(data)
            elif search_type == 'restaurants':
                return self._process_restaurant_results(data)
            elif search_type == 'attractions':
                return self._process_attraction_results(data)
            elif search_type in ['products', 'shopping']:
                return self._process_product_results(data)
            else:
                return self._process_general_results(data)
                
        except Exception as e:
            return {"error": f"Search failed: {str(e)}"}
    
    def _process_hotel_results(self, data):
        """Process hotel search results"""
        results = []
        organic_results = data.get('organic_results', [])
        
        for result in organic_results[:5]:
            results.append({
                'title': result.get('title', ''),
                'link': result.get('link', ''),
                'snippet': result.get('snippet', ''),
                'type': 'hotel'
            })
            
        return {'results': results, 'type': 'hotels'}
    
    def _process_restaurant_results(self, data):
        """Process restaurant search results"""
        results = []
        organic_results = data.get('organic_results', [])
        
        for result in organic_results[:5]:
            results.append({
                'title': result.get('title', ''),
                'link': result.get('link', ''),
                'snippet': result.get('snippet', ''),
                'type': 'restaurant'
            })
            
        return {'results': results, 'type': 'restaurants'}
    
    def _process_attraction_results(self, data):
        """Process attraction search results"""
        results = []
        organic_results = data.get('organic_results', [])
        
        for result in organic_results[:5]:
            results.append({
                'title': result.get('title', ''),
                'link': result.get('link', ''),
                'snippet': result.get('snippet', ''),
                'type': 'attraction'
            })
            
        return {'results': results, 'type': 'attractions'}
    
    def _process_general_results(self, data):
        """Process general search results"""
        results = []
        organic_results = data.get('organic_results', [])
        
        for result in organic_results[:5]:
            results.append({
                'title': result.get('title', ''),
                'link': result.get('link', ''),
                'snippet': result.get('snippet', ''),
                'type': 'general'
            })
            
        return {'results': results, 'type': 'general'}
    
    def _process_product_results(self, data):
        """Process product search results"""
        results = []
        organic_results = data.get('organic_results', [])
        
        for result in organic_results[:5]:
            # Extract additional product info if available
            snippet = result.get('snippet', '')
            title = result.get('title', '')
            
            # Try to extract price info from snippet
            price_info = ""
            if '$' in snippet or 'price' in snippet.lower():
                price_info = snippet
            
            results.append({
                'title': title,
                'link': result.get('link', ''),
                'snippet': snippet,
                'price_info': price_info,
                'type': 'product'
            })
            
        return {'results': results, 'type': 'products'}
