# Profile Matching Server

A system that uses sentence embeddings to match users based on their structured profile descriptions. This system identifies similarities between user profile categories to find compatible matches, considering both similarities and potential conflicts.

## Setup

1. Install the required dependencies:
   ```
   pip install -r requirements.txt
   ```

2. Set Supabase environment variables:
   ```
   export SUPABASE_URL="your-supabase-url"
   export SUPABASE_KEY="your-supabase-api-key"
   ```
   
   For Windows:
   ```
   set SUPABASE_URL=your-supabase-url
   set SUPABASE_KEY=your-supabase-api-key
   ```

## Database Structure

The system uses Supabase with the following tables:

1. **profiles** - User profiles
   - `user_id`: Unique user identifier
   - `generated_description`: JSON object with categorized profile data:
     ```json
     {
       "hobbies": "text...",
       "interests": "text...",
       "traits": "text...",
       "personality": "text...",
       "likes": "text...",
       "dislikes": "text..."
     }
     ```

2. **user_embeds** - Pre-computed category embeddings
   - `user_id`: Unique user identifier
   - `embedding_hobbies`: VECTOR(384) for hobbies embedding
   - `embedding_interests`: VECTOR(384) for interests embedding
   - `embedding_traits`: VECTOR(384) for traits embedding
   - `embedding_personality`: VECTOR(384) for personality embedding
   - `embedding_likes`: VECTOR(384) for likes embedding
   - `embedding_dislikes`: VECTOR(384) for dislikes embedding

## Model Architecture

The system uses SentenceTransformer to generate category-specific embeddings:

1. Each profile category (hobbies, interests, etc.) is encoded separately
2. Embeddings are stored in the database for efficient retrieval
3. Weighted similarity with conflict penalties is used when comparing profiles

### Similarity Calculation

The weighted similarity is calculated using:
- Equal weights for each category (0.166 each)
- Penalty for conflicts between one user's likes and another's dislikes
- The final score is adjusted by subtracting the penalty

## Usage

### API Server

Start the REST API server:

```
python scripts/api_server.py
```

The server provides these endpoints:

- `GET /api/health`: Health check endpoint

- `POST /api/update-embeddings`: Calculate and store embeddings for a user
  ```json
  {
    "user_id": "id of the user to update embeddings for"
  }
  ```

- `POST /api/batch-match`: Match a user against a filtered list of users
  ```json
  {
    "current_user_id": "id of the user to match against others",
    "filtered_user_ids": ["user_id1", "user_id2", ...]
  }
  ```

- `POST /api/match-profiles`: Compare two structured profile objects directly
  ```json
  {
    "profile1": {
      "hobbies": "text...",
      "interests": "text...",
      "traits": "text...",
      "personality": "text...",
      "likes": "text...",
      "dislikes": "text..."
    },
    "profile2": {
      "hobbies": "text...",
      "interests": "text...",
      "traits": "text...",
      "personality": "text...",
      "likes": "text...",
      "dislikes": "text..."
    }
  }
  ```

### Response Formats

**For /api/update-embeddings:**
```json
{
  "success": true,
  "message": "Embeddings updated for user_id: user123",
  "categories_updated": ["hobbies", "interests", "traits", "personality", "likes", "dislikes"]
}
```

**For /api/batch-match:**
```json
{
  "matches": [
    {
      "user_id": "matched_user_id",
      "similarity": 0.82,
      "match_probability": 82.0,
      "interpretation": "Profiles are highly contextually similar"
    },
    ...
  ]
}
```

**For /api/match-profiles:**
```json
{
  "similarity": 0.82,
  "match_probability": 82.0,
  "interpretation": "Profiles are highly contextually similar",
  "category_scores": {
    "hobbies": 0.75,
    "interests": 0.85,
    "traits": 0.80,
    "personality": 0.90,
    "likes": 0.78,
    "dislikes": 0.70
  },
  "conflicts": {
    "likes_vs_dislikes": 0.12,
    "dislikes_vs_likes": 0.08
  }
}
```

## Embedding Process

The system handles embeddings explicitly:

1. When a user profile is created or updated, call `/api/update-embeddings`
2. Embeddings are computed for each category and stored in the database
3. During matching, only pre-computed embeddings are used
4. If embeddings are missing, you'll be directed to call the update endpoint

## Performance

The similarity score ranges from 0 to 1:
- Scores > 0.8 indicate profiles are highly contextually similar
- Scores > 0.6 indicate profiles have moderate contextual similarity
- Scores ≤ 0.6 indicate profiles are likely contextually different 