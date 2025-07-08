from rest_framework import status
from rest_framework.decorators import api_view, permission_classes, authentication_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.authentication import JWTAuthentication
from django.shortcuts import get_object_or_404
from .models import ChatSession, Message
from .services import AIService, SearchService
from .serializers import ChatSessionSerializer, MessageSerializer

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def start_chat_session(request):
    """Start a new chat session with an AI friend"""
    ai_friend_type = request.data.get('ai_friend_type')
    
    if ai_friend_type not in ['foodie', 'travel', 'shopping']:
        return Response({'error': 'Invalid AI friend type'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Create or get existing session
    chat_session, created = ChatSession.objects.get_or_create(
        user=request.user,
        ai_friend_type=ai_friend_type,
        defaults={'title': f'Chat with {ai_friend_type.title()} Friend'}
    )
    
    serializer = ChatSessionSerializer(chat_session)
    return Response(serializer.data, status=status.HTTP_201_CREATED if created else status.HTTP_200_OK)

@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_chat_sessions(request):
    """Get all chat sessions for the user"""
    sessions = ChatSession.objects.filter(user=request.user)
    serializer = ChatSessionSerializer(sessions, many=True)
    return Response(serializer.data)

@api_view(['GET'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def get_chat_messages(request, session_id):
    """Get all messages for a chat session"""
    session = get_object_or_404(ChatSession, id=session_id, user=request.user)
    messages = Message.objects.filter(chat_session=session)
    serializer = MessageSerializer(messages, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def send_message(request, session_id):
    """Send a message and get AI response"""
    session = get_object_or_404(ChatSession, id=session_id, user=request.user)
    content = request.data.get('content', '').strip()
    
    if not content:
        return Response({'error': 'Message content is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    # Save user message
    user_message = Message.objects.create(
        chat_session=session,
        content=content,
        is_from_user=True
    )

    conversation_history = Message.objects.filter(chat_session=session).order_by('timestamp')
    ai_service = AIService()
    search_service = SearchService()
    # Initialize variables
    ai_response = None
    search_results = None
    marketplace_results = None
    extra_info = {}
    
    # Check for marketplace intent
    marketplace_intent = ai_service.detect_marketplace_intent(content)
    
    # Check for order commands first
    order_response = ai_service.process_order_from_chat(request.user, content)
    if order_response:
        ai_response = order_response
        extra_info['order_processed'] = True
    elif marketplace_intent == "list":
        # Seller wants to list a product/hotel
        product = ai_service.create_marketplace_product_from_chat(request.user, content)
        ai_response = f"Your product '{product.title}' has been listed in the marketplace!"
        extra_info['product'] = product.id
        # Optionally, show product details
        ai_response += f"\n\nDetails:\nTitle: {product.title}\nPrice: ${product.price}\nDescription: {product.description}"
    elif marketplace_intent in ["buy", "search"]:
        # Buyer wants to buy/book/search: show marketplace items first
        # Extract meaningful keywords from the message for better search
        search_keywords = ai_service.extract_search_keywords(content)
        marketplace_results = ai_service.fetch_marketplace_items(query=search_keywords)
        if marketplace_results and isinstance(marketplace_results, list) and len(marketplace_results) > 0:
            formatted = ai_service.format_marketplace_results_for_chat(marketplace_results)
            ai_response = f"Here are some items from our marketplace:\n\n{formatted}\n\nIf you don't find what you want, reply with 'none' or 'not found' to search the web."
            extra_info['marketplace_results'] = marketplace_results
        else:
            # No marketplace results, fallback to web search
            search_type = 'products' if marketplace_intent == 'buy' else 'general'
            search_results = search_service.search_places(content, search_type)
            if search_results and 'results' in search_results:
                ai_response = "No items found in our marketplace. Here are some results from the web:\n\n"
                for result in search_results['results'][:3]:
                    ai_response += f"- {result['title']}: {result['snippet']}\n"
            else:
                ai_response = "Sorry, no relevant items found."
    elif content.strip().lower() in ["none", "not found", "no", "nope"]:
        # User didn't like marketplace results, fallback to web search
        search_results = search_service.search_places(content, 'products')
        if search_results and 'results' in search_results:
            ai_response = "Here are some results from the web:\n\n"
            for result in search_results['results'][:3]:
                ai_response += f"- {result['title']}: {result['snippet']}\n"
        else:
            ai_response = "Sorry, no relevant items found online."
    else:
        # Fallback to previous logic (AI + search)
        # Simple search detection
        search_keywords = ['find', 'search', 'recommend', 'suggest', 'where', 'hotel', 'restaurant', 'buy', 'purchase', 'order', 'shop', 'product']
        if any(keyword in content.lower() for keyword in search_keywords):
            if any(word in content.lower() for word in ['hotel', 'accommodation', 'stay']):
                search_type = 'hotels'
            elif any(word in content.lower() for word in ['restaurant', 'food', 'eat', 'dining']):
                search_type = 'restaurants'
            elif any(word in content.lower() for word in ['attraction', 'visit', 'see', 'tourist']):
                search_type = 'attractions'
            elif any(word in content.lower() for word in ['buy', 'purchase', 'order', 'shop', 'product', 'price']) or session.ai_friend_type == 'shopping':
                search_type = 'products'
            else:
                search_type = 'general'
            search_results = search_service.search_places(content, search_type)
        # Get AI response
        enhanced_message = content
        if search_results and 'results' in search_results:
            enhanced_message += "\n\nSearch results:\n"
            for result in search_results['results'][:3]:
                enhanced_message += f"- {result['title']}: {result['snippet']}\n"
        ai_response = ai_service.get_ai_response(
            enhanced_message, 
            session.ai_friend_type, 
            conversation_history,
            request.user
        )

    # Save AI response
    ai_message = Message.objects.create(
        chat_session=session,
        content=ai_response,
        is_from_user=False,
        metadata=search_results or extra_info or {}
    )

    session.save()

    return Response({
        'user_message': MessageSerializer(user_message).data,
        'ai_response': MessageSerializer(ai_message).data,
        'marketplace_results': marketplace_results,
        'search_results': search_results
    })

@api_view(['POST'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def search_places(request):
    """Search for places using SERP API"""
    query = request.data.get('query', '').strip()
    search_type = request.data.get('type', 'general')
    location = request.data.get('location', '')
    
    if not query:
        return Response({'error': 'Search query is required'}, status=status.HTTP_400_BAD_REQUEST)
    
    search_service = SearchService()
    results = search_service.search_places(query, search_type, location)
    
    return Response(results)

@api_view(['DELETE'])
@authentication_classes([JWTAuthentication])
@permission_classes([IsAuthenticated])
def delete_chat_session(request, session_id):
    """Delete a chat session"""
    session = get_object_or_404(ChatSession, id=session_id, user=request.user)
    session.delete()
    return Response({'message': 'Chat session deleted'}, status=status.HTTP_204_NO_CONTENT)

@api_view(['GET'])
@permission_classes([])
def test_ai(request):
    """Test AI service"""
    try:
        ai_service = AIService()
        response = ai_service.get_ai_response("Say hello!", "foodie")
        return Response({"ai_response": response, "status": "success"})
    except Exception as e:
        import traceback
        return Response({
            "error": str(e), 
            "traceback": traceback.format_exc(),
            "status": "failed"
        }, status=500)
