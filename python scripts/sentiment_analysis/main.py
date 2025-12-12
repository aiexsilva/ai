import functions_framework
from flask import jsonify
import firebase_admin
from firebase_admin import credentials, firestore
from transformers import pipeline

# --- SETUP ---
if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()

# Initialize Sentiment Analysis Model
# We print this immediately as it happens during cold start
print("[SentimentAnalysis] Loading sentiment analysis model...")
sentiment_pipeline = pipeline("sentiment-analysis", model="distilbert-base-uncased-finetuned-sst-2-english")
print("[SentimentAnalysis] Model loaded.")

def get_place_reviews(place_id, logger):
    """Fetches reviews for a place from Firestore."""
    try:
        doc = db.collection('places').document(place_id).get()
        if doc.exists:
            data = doc.to_dict()
            reviews = data.get('ratings', [])
            logger.append(f"Found {len(reviews)} reviews for {place_id} in Firestore.")
            return reviews
        return []
    except Exception as e:
        logger.append(f"Error fetching reviews for {place_id}: {e}")
        return []

def is_place_acceptable(place, logger):
    """
    Decides if a place should be kept based on sentiment analysis and ratings.
    """
    place_id = place.get('placeId') or place.get('id')
    google_rating = place.get('rating')
    
    # 1. Fetch Firebase Reviews
    reviews = get_place_reviews(place_id, logger)
    
    firebase_review_count = len(reviews)
    MIN_REVIEW_COUNT = 3
    
    if firebase_review_count >= MIN_REVIEW_COUNT:
        bad_reviews_count = 0
        
        for r in reviews:
            text = r.get('review', '')
            rating = r.get('rating', 0)
            
            is_bad = False
            
            if text and text.strip():
                input_text = f"Rating: {rating}/5. {text}"
                
                # Truncate to avoid model errors
                result = sentiment_pipeline(input_text[:512])[0]
                
                # Log detailed sentiment result
                logger.append(f"Review for {place_id}: '{text[:30]}...' -> Label: {result['label']}, Score: {result['score']:.4f}")
                
                if result['label'] == 'NEGATIVE':
                    is_bad = True
            else:
                if rating < 3:
                    is_bad = True
                    logger.append(f"Review for {place_id} (No Text): Rating {rating} -> BAD")
            
            if is_bad:
                bad_reviews_count += 1
        
        bad_ratio = bad_reviews_count / firebase_review_count
        logger.append(f"Place {place_id} stats: {bad_reviews_count}/{firebase_review_count} bad ({bad_ratio:.2%})")

        # User's logic: > 50% bad reviews = reject
        if bad_ratio > 0.5:
            logger.append(f"Place {place_id} REJECTED (Bad reviews > 50%)")
            return False
            
        logger.append(f"Place {place_id} ACCEPTED")
        return True

    # 2. Fallback to Google Rating
    if google_rating is not None:
        try:
            rating_val = float(google_rating)
            if 0.0 < rating_val < 3.0:
                logger.append(f"Place {place_id} REJECTED: Google rating {rating_val} < 3.0")
                return False
        except (ValueError, TypeError):
            pass
            
    logger.append(f"Place {place_id} ACCEPTED (Google Rating: {google_rating})")
    return True

@functions_framework.http
def filter_places_sentiment(request):
    # Setup CORS
    if request.method == 'OPTIONS':
        headers = {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'POST',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Max-Age': '3600'
        }
        return ('', 204, headers)

    headers = {'Access-Control-Allow-Origin': '*'}

    # Initialize Log Buffer
    log_buffer = []
    def dlog(msg):
        log_buffer.append(str(msg))

    dlog("===== START: FILTER PLACES SENTIMENT =====")

    request_json = request.get_json(silent=True)
    if not request_json or 'places' not in request_json:
        dlog("Error: Missing 'places' in request")
        print("\n".join(log_buffer))
        return (jsonify({"error": "Missing 'places' in request"}), 400, headers)

    places = request_json['places']
    
    if not isinstance(places, list):
        dlog("Error: 'places' must be a list")
        print("\n".join(log_buffer))
        return (jsonify({"error": "'places' must be a list"}), 400, headers)

    dlog(f"Received request to filter {len(places)} places.")

    filtered_places = []
    for place in places:
        # Pass the list append method as the logger
        if is_place_acceptable(place, log_buffer):
            filtered_places.append(place)
            
    dlog(f"Returning {len(filtered_places)} places after filtering (Original: {len(places)})")

    dlog(f"Filtered places: {filtered_places}")
    dlog("===== END: FILTER PLACES SENTIMENT =====")
    
    # Print all logs at once
    print("\n".join(log_buffer))
    
    return (jsonify({"places": filtered_places}), 200, headers)
