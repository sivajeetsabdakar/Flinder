import os
import sys
import logging
from flask import Flask, request, jsonify
import argparse

# Add parent directory to path so we can import from model
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from model.profile_matcher import (
    load_model, connect_to_supabase, match_users, 
    calculate_profile_embeddings,
    calculate_users_similarity, interpret_similarity, calculate_field_similarity,
    CATEGORIES, get_profile_data, store_category_embeddings
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Initialize Flask app
app = Flask(__name__)

@app.route('/api/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'ok',
        'message': 'Server is running'
    })

@app.route('/api/batch-match', methods=['POST'])
def batch_match():
    """
    Match a user against a filtered list of other users using pre-computed embeddings
    
    Request body:
        {
            "current_user_id": "id (UUID) of the user to match against others",
            "filtered_user_ids": ["user_id1", "user_id2", ...]
        }
        
    Response:
        {
            "matches": [
                {
                    "user_id": "matched_user_id",
                    "similarity": float,
                    "match_probability": float,
                    "interpretation": string
                },
                ...
            ],
            "missing_embeddings": ["user_id3", "user_id4", ...] (if any)
        }
    """
    # Get request data
    data = request.json
    
    # Validate request
    if not data or 'current_user_id' not in data or 'filtered_user_ids' not in data:
        return jsonify({
            'error': 'Missing required parameters: current_user_id, filtered_user_ids'
        }), 400
    
    current_user_id = data['current_user_id']
    filtered_user_ids = data['filtered_user_ids']
    
    # Validate filtered_user_ids is a list
    if not isinstance(filtered_user_ids, list):
        return jsonify({
            'error': 'filtered_user_ids must be a list'
        }), 400
    
    try:
        # Match users
        matches, error = match_users(current_user_id, filtered_user_ids)
        
        if matches is None:
            return jsonify({
                'error': error,
                'message': "Call /api/update-embeddings first for users missing embeddings"
            }), 404
        
        # Return results
        return jsonify({
            'matches': matches
        })
    except Exception as e:
        logger.error(f"Error computing batch similarities: {e}")
        return jsonify({
            'error': f'Error computing batch similarities: {str(e)}'
        }), 500

@app.route('/api/match-profiles', methods=['POST'])
def match_profiles():
    """
    Calculate similarity between two structured profile data objects
    
    Request body:
        {
            "profile1": {
                "hobbies": "text",
                "interests": "text",
                "traits": "text", 
                "personality": "text",
                "likes": "text",
                "dislikes": "text"
            },
            "profile2": {
                "hobbies": "text",
                "interests": "text",
                "traits": "text", 
                "personality": "text",
                "likes": "text",
                "dislikes": "text"
            }
        }
        
    Response:
        {
            "similarity": float,
            "match_probability": float,
            "interpretation": string,
            "category_scores": {
                "hobbies": float,
                "interests": float,
                ...
            },
            "conflicts": {
                "likes_vs_dislikes": float,
                "dislikes_vs_likes": float
            }
        }
    """
    # Get request data
    data = request.json
    
    # Validate request
    if not data or 'profile1' not in data or 'profile2' not in data:
        return jsonify({
            'error': 'Missing required parameters: profile1, profile2'
        }), 400
    
    profile1 = data['profile1']
    profile2 = data['profile2']
    
    # Validate profiles are objects with category fields
    if not isinstance(profile1, dict) or not isinstance(profile2, dict):
        return jsonify({
            'error': 'Profiles must be objects with category fields'
        }), 400
    
    try:
        # Calculate embeddings for each category
        profile1_embeddings = calculate_profile_embeddings(profile1)
        profile2_embeddings = calculate_profile_embeddings(profile2)
        
        if not profile1_embeddings or not profile2_embeddings:
            return jsonify({
                'error': 'Failed to calculate embeddings for profiles'
            }), 500
        
        # Calculate overall similarity
        similarity = calculate_users_similarity(profile1_embeddings, profile2_embeddings)
        interpretation = interpret_similarity(similarity)
        
        # Calculate category-specific scores
        category_scores = {}
        for category in CATEGORIES:
            embed_key = f"embedding_{category}"
            if (embed_key in profile1_embeddings and 
                embed_key in profile2_embeddings):
                score = calculate_field_similarity(
                    profile1_embeddings[embed_key],
                    profile2_embeddings[embed_key]
                )
                category_scores[category] = float(score)
        
        # Calculate conflict scores
        conflicts = {}
        if ("embedding_likes" in profile1_embeddings and 
            "embedding_dislikes" in profile2_embeddings):
            conflicts["likes_vs_dislikes"] = float(calculate_field_similarity(
                profile1_embeddings["embedding_likes"],
                profile2_embeddings["embedding_dislikes"]
            ))
        
        if ("embedding_dislikes" in profile1_embeddings and 
            "embedding_likes" in profile2_embeddings):
            conflicts["dislikes_vs_likes"] = float(calculate_field_similarity(
                profile1_embeddings["embedding_dislikes"],
                profile2_embeddings["embedding_likes"]
            ))
        
        # Return detailed result
        return jsonify({
            'similarity': float(similarity),
            'match_probability': float(similarity * 100),
            'interpretation': interpretation,
            'category_scores': category_scores,
            'conflicts': conflicts
        })
    except Exception as e:
        logger.error(f"Error computing structured similarity: {e}")
        return jsonify({
            'error': f'Error computing structured similarity: {str(e)}'
        }), 500

@app.route('/api/update-embeddings', methods=['POST'])
def update_embeddings():
    """
    Calculate and store/update embeddings for a user profile
    
    Request body:
        {
            "user_id": "id (UUID) of the user to update embeddings for"
        }
        
    Response:
        {
            "success": boolean,
            "message": string,
            "categories_updated": list of categories that were updated
        }
    """
    # Get request data
    data = request.json
    
    # Validate request
    if not data or 'user_id' not in data:
        return jsonify({
            'error': 'Missing required parameter: user_id'
        }), 400
    
    user_id = data['user_id']
    
    try:
        # Get the user's profile data
        profile_data = get_profile_data(user_id)
        
        if profile_data is None:
            return jsonify({
                'error': f'Profile not found for user_id: {user_id}'
            }), 404
        
        # Calculate embeddings for each category
        embeddings = calculate_profile_embeddings(profile_data)
        
        if embeddings is None or not embeddings:
            return jsonify({
                'error': f'Failed to calculate embeddings for user_id: {user_id}'
            }), 500
        
        # Store the embeddings in the database
        success = store_category_embeddings(user_id, embeddings)
        
        if not success:
            return jsonify({
                'error': f'Failed to store embeddings for user_id: {user_id}'
            }), 500
        
        # Get the categories that were updated
        categories_updated = []
        for category in CATEGORIES:
            embed_key = f"embedding_{category}"
            if embed_key in embeddings:
                categories_updated.append(category)
        
        # Return success response
        return jsonify({
            'success': True,
            'message': f'Embeddings updated for user_id: {user_id}',
            'categories_updated': categories_updated
        })
    except Exception as e:
        logger.error(f"Error updating embeddings: {e}")
        return jsonify({
            'error': f'Error updating embeddings: {str(e)}'
        }), 500

def main():
    parser = argparse.ArgumentParser(description='Start the profile matching API server')
    parser.add_argument('--port', type=int, default=5000, help='Server port')
    parser.add_argument('--host', type=str, default='0.0.0.0', help='Server host')
    parser.add_argument('--debug', action='store_true', help='Enable debug mode')
    args = parser.parse_args()
    
    # Initialize services
    try:
        # Load model and connect to Supabase
        load_model()
        connect_to_supabase()
        
        # Run server
        logger.info(f"Starting server on {args.host}:{args.port}")
        app.run(host=args.host, port=args.port, debug=True)
    except Exception as e:
        logger.error(f"Server initialization failed: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    sys.exit(main()) 