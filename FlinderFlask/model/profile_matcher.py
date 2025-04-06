#!/usr/bin/env python3
import os
import numpy as np
import logging
import torch
import json
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Global instances
model = None
supabase = None

# Profile categories
CATEGORIES = ["hobbies", "interests", "traits", "personality", "likes", "dislikes"]

# Category weights for similarity calculation
CATEGORY_WEIGHTS = {
    "hobbies": 0.15,
    "interests": 0.15,
    "traits": 0.125,
    "personality": 0.125,
    "likes": 0.25,
    "dislikes": 0.20
}

# Penalty weight for conflicts
CONFLICT_PENALTY_WEIGHT = 0.15

def load_model():
    """
    Load the SentenceTransformer model
    
    Returns:
        model: Loaded SentenceTransformer model
    """
    global model
    
    if model is None:
        # Initialize model
        logger.info("Loading SentenceTransformer model...")
        model = SentenceTransformer('all-MiniLM-L6-v2')
    
    return model

def connect_to_supabase():
    """
    Connect to Supabase client
    
    Returns:
        supabase: Supabase client
    """
    global supabase
    
    if supabase is None:
        # Get Supabase URL and Key from environment variables
        url = os.environ.get("SUPABASE_URL")
        key = os.environ.get("SUPABASE_KEY")
        
        if not url or not key:
            logger.error("SUPABASE_URL and SUPABASE_KEY environment variables must be set")
            raise ValueError("Missing Supabase credentials")
        
        logger.info("Connecting to Supabase...")
        supabase = create_client(url, key)
    
    return supabase

def get_profile_data(user_id):
    """
    Get profile data (JSON) for a user from the profiles table
    
    Args:
        user_id: User ID (UUID) to fetch profile for
        
    Returns:
        profile_data: Dictionary with profile categories
    """
    connect_to_supabase()
    
    try:
        # Ensure user_id is treated as string for UUID compatibility
        user_id_str = str(user_id)
        response = supabase.table('profiles').select('generated_description').eq('user_id', user_id_str).execute()
        
        if not response.data:
            logger.warning(f"Profile not found for user_id: {user_id_str}")
            return None
        
        # Get the JSON data from the response
        json_data = response.data[0]['generated_description']
        
        # Handle the case where json_data is already a dict or still a string
        if isinstance(json_data, dict):
            profile_data = json_data
        else:
            # Parse the JSON string
            try:
                profile_data = json.loads(json_data)
            except json.JSONDecodeError as e:
                logger.error(f"Invalid JSON in profile data for user_id {user_id_str}: {e}")
                return None
        
        return profile_data
            
    except Exception as e:
        logger.error(f"Error fetching profile: {e}")
        return None

def calculate_embedding_for_text(text):
    """
    Calculate embedding for a text string
    
    Args:
        text: Text to calculate embedding for
        
    Returns:
        embedding: Numpy array containing the embedding
    """
    load_model()
    
    if not text:
        return None
        
    try:
        # Encode the text
        embedding = model.encode(text, convert_to_tensor=True)
        
        # Convert to numpy for storage and similarity calculation
        return embedding.cpu().numpy()
    except Exception as e:
        logger.error(f"Error calculating embedding: {e}")
        return None

def calculate_profile_embeddings(profile_data):
    """
    Calculate embeddings for each category in profile data
    
    Args:
        profile_data: Dictionary with profile categories
        
    Returns:
        embeddings: Dictionary mapping categories to embeddings
    """
    if not profile_data:
        return None
    
    embeddings = {}
    
    for category in CATEGORIES:
        if category in profile_data and profile_data[category]:
            embedding = calculate_embedding_for_text(profile_data[category])
            if embedding is not None:
                embeddings[f"embedding_{category}"] = embedding
    
    return embeddings

def get_category_embeddings(user_id):
    """
    Get all category embeddings for a user from the user_embeds table
    
    Args:
        user_id: User ID (UUID) to fetch embeddings for
        
    Returns:
        embeddings: Dictionary mapping categories to embeddings
    """
    connect_to_supabase()
    
    try:
        # Ensure user_id is treated as string for UUID compatibility
        user_id_str = str(user_id)
        
        # Construct query to select all embedding columns
        columns = ["user_id"]
        for category in CATEGORIES:
            columns.append(f"embedding_{category}")
        
        response = supabase.table('user_embeds').select(','.join(columns)).eq('user_id', user_id_str).execute()
        
        if not response.data:
            logger.info(f"Embeddings not found for user_id: {user_id_str}")
            return None
        
        # Process the response into a dictionary of embeddings
        embeddings = {}
        for category in CATEGORIES:
            embed_key = f"embedding_{category}"
            if embed_key in response.data[0] and response.data[0][embed_key]:
                embedding_data = response.data[0][embed_key]
                
                # Handle case where embedding is returned as a string representation
                if isinstance(embedding_data, str):
                    try:
                        # Clean the string representation and convert to a list of floats
                        # Remove np.str_() wrapper if present
                        if embedding_data.startswith('np.str_('):
                            embedding_data = embedding_data[8:-1]  # Remove np.str_(' and ')
                        
                        # Remove any other array notation
                        embedding_data = embedding_data.strip('[]')
                        
                        # Split by comma and convert each element to float
                        float_list = [float(x.strip()) for x in embedding_data.split(',')]
                        
                        # Convert to numpy array
                        embeddings[embed_key] = np.array(float_list)
                    except Exception as e:
                        logger.error(f"Error parsing embedding string for {embed_key}: {e}")
                        continue
                else:
                    # If it's already an array-like structure
                    embeddings[embed_key] = np.array(embedding_data)
        
        return embeddings
    except Exception as e:
        logger.error(f"Error fetching embeddings: {e}")
        return None

def store_category_embeddings(user_id, embeddings):
    """
    Store category embeddings for a user in the user_embeds table
    
    Args:
        user_id: User ID (UUID) to store embeddings for
        embeddings: Dictionary mapping categories to embeddings
        
    Returns:
        success: Boolean indicating if the operation succeeded
    """
    connect_to_supabase()
    
    if not embeddings:
        logger.warning(f"No embeddings to store for user_id: {user_id}")
        return False
    
    try:
        # Ensure user_id is treated as string for UUID compatibility
        user_id_str = str(user_id)
        
        # Convert numpy arrays to lists for storage
        data_to_store = {"user_id": user_id_str}
        
        for key, embedding in embeddings.items():
            data_to_store[key] = embedding.tolist()
        
        # Check if the user already has embeddings
        response = supabase.table('user_embeds').select('user_id').eq('user_id', user_id_str).execute()
        
        if response.data:
            # Update existing embeddings
            supabase.table('user_embeds').update(data_to_store).eq('user_id', user_id_str).execute()
        else:
            # Insert new embeddings
            supabase.table('user_embeds').insert(data_to_store).execute()
        
        logger.info(f"Stored category embeddings for user_id: {user_id_str}")
        return True
    except Exception as e:
        logger.error(f"Error storing embeddings: {e}")
        return False

def get_or_create_category_embeddings(user_id):
    """
    Get existing category embeddings or create new ones for user
    
    Args:
        user_id: User ID (UUID)
        
    Returns:
        embeddings: Dictionary of embeddings by category
        error: Error message if any
    """
    # Ensure user_id is treated as string for UUID compatibility
    user_id_str = str(user_id)
    
    # Try to get existing embeddings
    embeddings = get_category_embeddings(user_id_str)
    
    if embeddings is None or not embeddings:
        # Need to calculate them
        profile_data = get_profile_data(user_id_str)
        
        if profile_data is None:
            return None, f"Profile not found for user_id: {user_id_str}"
        
        embeddings = calculate_profile_embeddings(profile_data)
        
        if embeddings is None or not embeddings:
            return None, f"Failed to calculate embeddings for user_id: {user_id_str}"
        
        # Store the newly calculated embeddings
        store_category_embeddings(user_id_str, embeddings)
    
    return embeddings, None

def calculate_field_similarity(embedding1, embedding2):
    """
    Calculate similarity between two field embeddings
    
    Args:
        embedding1: First embedding
        embedding2: Second embedding
        
    Returns:
        similarity: Similarity score
    """
    if embedding1 is None or embedding2 is None:
        return 0.0
    
    return cosine_similarity([embedding1], [embedding2])[0][0]

def calculate_conflicts_penalty(user1_embeddings, user2_embeddings):
    """
    Calculate penalty for conflicts between likes and dislikes
    
    Args:
        user1_embeddings: First user's embeddings
        user2_embeddings: Second user's embeddings
        
    Returns:
        penalty: Penalty score
    """
    penalty = 0.0
    
    # Check if we have the necessary embeddings
    if ("embedding_likes" in user1_embeddings and 
        "embedding_dislikes" in user2_embeddings):
        # User1's likes vs User2's dislikes
        sim_likes_dislikes = calculate_field_similarity(
            user1_embeddings["embedding_likes"], 
            user2_embeddings["embedding_dislikes"]
        )
        penalty += sim_likes_dislikes * CONFLICT_PENALTY_WEIGHT
    
    if ("embedding_dislikes" in user1_embeddings and 
        "embedding_likes" in user2_embeddings):
        # User1's dislikes vs User2's likes
        sim_dislikes_likes = calculate_field_similarity(
            user1_embeddings["embedding_dislikes"], 
            user2_embeddings["embedding_likes"]
        )
        penalty += sim_dislikes_likes * CONFLICT_PENALTY_WEIGHT
    
    return penalty

def calculate_users_similarity(user1_embeddings, user2_embeddings):
    """
    Calculate weighted similarity between users based on category embeddings
    
    Args:
        user1_embeddings: First user's embeddings
        user2_embeddings: Second user's embeddings
        
    Returns:
        similarity: Final similarity score (adjusted for conflicts)
    """
    weighted_sim = 0.0
    total_weight_applied = 0.0
    
    # Calculate similarity for each category
    for category in CATEGORIES:
        embed_key = f"embedding_{category}"
        
        if embed_key in user1_embeddings and embed_key in user2_embeddings:
            weight = CATEGORY_WEIGHTS[category]
            
            field_sim = calculate_field_similarity(
                user1_embeddings[embed_key],
                user2_embeddings[embed_key]
            )
            
            weighted_sim += field_sim * weight
            total_weight_applied += weight
    
    # Calculate the average similarity, accounting for missing fields
    if total_weight_applied > 0:
        weighted_sim = weighted_sim / total_weight_applied
    
    # Calculate penalty for conflicts
    penalty = calculate_conflicts_penalty(user1_embeddings, user2_embeddings)
    
    # Adjust score for conflicts
    adjusted_score = max(0.0, weighted_sim - penalty)
    
    return adjusted_score

def interpret_similarity(similarity):
    """
    Interpret the meaning of a similarity score
    
    Args:
        similarity: Float similarity score
        
    Returns:
        interpretation: String interpretation
    """
    if similarity > 0.8:
        return "Profiles are highly contextually similar"
    elif similarity > 0.6:
        return "Profiles have moderate contextual similarity"
    else:
        return "Profiles are likely contextually different"

def match_users(current_user_id, filtered_user_ids):
    """
    Match a user against a filtered list of other users, using only pre-computed embeddings
    
    Args:
        current_user_id: ID (UUID) of user to match against others
        filtered_user_ids: List of user IDs (UUIDs) to match against
        
    Returns:
        matches: List of match results
        error: Error message if any
    """
    # Ensure current_user_id is treated as string for UUID compatibility
    current_user_id_str = str(current_user_id)
    
    # Get embeddings for current user (only use existing ones)
    user1_embeddings = get_category_embeddings(current_user_id_str)
    
    if user1_embeddings is None:
        return None, f"Embeddings not found for user_id: {current_user_id_str}. Please call /api/update-embeddings first."
    
    results = []
    missing_embeddings = []
    
    # Process each filtered user ID
    for other_user_id in filtered_user_ids:
        # Ensure other_user_id is treated as string for UUID compatibility
        other_user_id_str = str(other_user_id)
        
        # Skip comparing with self
        if other_user_id_str == current_user_id_str:
            continue
        
        # Get embeddings for other user (only use existing ones)
        user2_embeddings = get_category_embeddings(other_user_id_str)
        
        if user2_embeddings is None:
            # Add to list of users with missing embeddings
            missing_embeddings.append(other_user_id_str)
            continue
        
        # Compute similarity
        similarity = calculate_users_similarity(user1_embeddings, user2_embeddings)
        interpretation = interpret_similarity(similarity)
        
        results.append({
            'user_id': other_user_id_str,
            'similarity': float(similarity),
            'match_probability': float(similarity * 100),
            'interpretation': interpretation
        })
    
    # Sort results by similarity (highest first)
    results.sort(key=lambda x: x['similarity'], reverse=True)
    
    # Include warning about missing embeddings in response
    if missing_embeddings:
        logger.warning(f"Missing embeddings for {len(missing_embeddings)} users: {missing_embeddings[:5]}...")
    
    return results, None 