# Flinder API Documentation

This document provides detailed specifications for all API endpoints in the Flinder application, including required inputs and expected responses, along with a Flutter implementation roadmap.

## Authentication Endpoints

### POST /api/auth/register

Register a new user in the system.

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "name": "John Doe",
  "phone": "+1234567890", // Optional
  "dateOfBirth": "1990-01-01",
  "gender": "male" // "male" | "female" | "non_binary" | "prefer_not_to_say"
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "message": "User registered successfully",
  "user": {
    "id": "user_id_123",
    "email": "user@example.com",
    "name": "John Doe",
    "createdAt": "2023-04-20T14:30:00Z",
    "profileCompleted": false,
    "verificationStatus": {
      "email": false,
      "phone": false
    }
  }
}
```

### POST /api/auth/login

Authenticate a user.

**Request Body:**

```json
{
  "email": "user@example.com",
  "password": "securePassword123"
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Login successful",
  "user": {
    "id": "user_id_123",
    "email": "user@example.com",
    "name": "John Doe",
    "profileCompleted": true,
    "onlineStatus": "online",
    "lastOnline": "2023-04-20T14:30:00Z"
  }
}
```

## Profile Endpoints

### GET /api/profile/:id

Retrieve a user's profile information.

**Request Headers:**

```
Authorization: user@example.com
```

**Response (200 OK):**

```json
{
  "success": true,
  "profile": {
    "userId": "user_id_123",
    "bio": "Hey! I'm a software engineer working remotely, so I need a quiet space during work hours. I love cooking and am happy to share meals sometimes.",
    "generatedDescription": "I usually stay up late and enjoy unwinding with music or gaming. I keep my space tidy and prefer flatmates who respect shared spaces.",
    "interests": ["cooking", "hiking", "gaming"],
    "profilePictures": [
      {
        "id": "photo_id_123",
        "url": "https://storage.example.com/profiles/user_id_123.jpg",
        "isPrimary": true,
        "uploadedAt": "2023-04-20T15:30:00Z"
      }
    ],
    "location": {
      "city": "San Francisco",
      "neighborhood": "Mission District",
      "coordinates": {
        "latitude": 37.7749,
        "longitude": -122.4194
      }
    },
    "budget": {
      "min": 1000,
      "max": 1500,
      "currency": "USD"
    },
    "roomPreference": "private",
    "genderPreference": "same_gender",
    "moveInDate": "2023-05-01",
    "leaseDuration": "long_term",
    "lifestyle": {
      "schedule": "night_owl",
      "noiseLevel": "moderate",
      "cookingFrequency": "daily",
      "diet": "no_restrictions",
      "smoking": "no",
      "drinking": "occasionally",
      "pets": "comfortable_with_pets",
      "cleaningHabits": "very_clean",
      "guestPolicy": "occasional_guests"
    },
    "languages": ["English", "Spanish"]
  }
}
```

### PUT /api/profile/:id

Update a user's profile information.

**Request Headers:**

```
Authorization: user@example.com
```

**Request Body:**

```json
{
  "bio": "Updated bio text here...",
  "interests": ["cooking", "hiking", "gaming"],
  "location": {
    "city": "San Francisco",
    "neighborhood": "Mission District"
  },
  "budget": {
    "min": 1000,
    "max": 1500,
    "currency": "USD"
  },
  "roomPreference": "private",
  "genderPreference": "same_gender",
  "moveInDate": "2023-05-01",
  "leaseDuration": "long_term",
  "lifestyle": {
    "schedule": "night_owl",
    "noiseLevel": "moderate",
    "cookingFrequency": "daily",
    "diet": "no_restrictions",
    "smoking": "no",
    "drinking": "occasionally",
    "pets": "comfortable_with_pets",
    "cleaningHabits": "very_clean",
    "guestPolicy": "occasional_guests"
  },
  "languages": ["English", "Spanish"]
}
```

## Discovery Endpoints

### GET /api/discover

Retrieve potential roommate matches based on user preferences.

**Request Headers:**

```
Authorization: user@example.com
```

**Query Parameters:**

```
limit: number (default: 10)
offset: number (default: 0)
```

**Response (200 OK):**

```json
{
  "success": true,
  "profiles": [
    {
      "userId": "user_id_456",
      "bio": "Truncated bio preview...",
      "generatedDescription": "A shortened version of the AI-generated description",
      "interests": ["yoga", "cooking", "reading"],
      "profilePictures": [
        {
          "id": "photo_id_456",
          "url": "https://storage.example.com/profiles/user_id_456.jpg",
          "isPrimary": true,
          "uploadedAt": "2023-04-20T15:30:00Z"
        }
      ],
      "location": {
        "city": "San Francisco",
        "neighborhood": "Mission District"
      },
      "lifestyle": {
        "schedule": "early_riser",
        "cleaningHabits": "very_clean"
      }
    }
  ],
  "pagination": {
    "total": 42,
    "limit": 10,
    "offset": 0,
    "hasMore": true
  }
}
```

### POST /api/discover/swipe

Record a user's swipe decision on a potential match.

**Request Headers:**

```
Authorization: user@example.com
```

**Request Body:**

```json
{
  "targetUserId": "user_id_456",
  "direction": "right" // "right" for like, "left" for pass
}
```

**Response (200 OK - No Match):**

```json
{
  "success": true,
  "message": "Preference recorded",
  "match": false
}
```

**Response (200 OK - Match Created):**

```json
{
  "success": true,
  "message": "It's a match!",
  "match": true,
  "matchDetails": {
    "id": "match_id_789",
    "user1Id": "user_id_123",
    "user2Id": "user_id_456",
    "createdAt": "2023-04-20T16:45:00Z"
  }
}
```

### GET /api/discover/matches

Retrieve all current matches for the user.

**Request Headers:**

```
Authorization: user@example.com
```

**Response (200 OK):**

```json
{
  "success": true,
  "matches": [
    {
      "id": "match_id_789",
      "user1Id": "user_id_123",
      "user2Id": "user_id_456",
      "createdAt": "2023-04-20T16:45:00Z"
    }
  ]
}
```

## Chat Endpoints

### GET /api/conversations

Retrieve all conversations for the current user.

**Request Headers:**

```
Authorization: user@example.com
```

**Response (200 OK):**

```json
{
  "success": true,
  "conversations": [
    {
      "id": "conversation_id_123",
      "matchId": "match_id_789",
      "participants": ["user_id_123", "user_id_456"],
      "createdAt": "2023-04-20T16:46:00Z",
      "lastMessageAt": "2023-04-21T10:15:00Z"
    }
  ]
}
```

### GET /api/conversations/:id/messages

Retrieve message history for a specific conversation.

**Request Headers:**

```
Authorization: user@example.com
```

**Response (200 OK):**

```json
{
  "success": true,
  "messages": [
    {
      "id": "message_id_124",
      "conversationId": "conversation_id_123",
      "senderId": "user_id_123",
      "content": "Are you still looking for a place in Mission District?",
      "sentAt": "2023-04-21T10:30:00Z"
    },
    {
      "id": "message_id_123",
      "conversationId": "conversation_id_123",
      "senderId": "user_id_456",
      "content": "Hey, when are you planning to move?",
      "sentAt": "2023-04-21T10:15:00Z"
    }
  ]
}
```

### POST /api/conversations/:id/messages

Send a new message in a conversation.

**Request Headers:**

```
Authorization: user@example.com
```

**Request Body:**

```json
{
  "content": "Yes, I'm planning to move in early May. How about you?"
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "message": {
    "id": "message_id_125",
    "conversationId": "conversation_id_123",
    "senderId": "user_id_123",
    "content": "Yes, I'm planning to move in early May. How about you?",
    "sentAt": "2023-04-21T11:05:00Z"
  }
}
```

## Preferences Endpoints

### GET /api/preferences

Retrieve the user's matching preferences.

**Request Headers:**

```
Authorization: user@example.com
```

**Response (200 OK):**

```json
{
  "success": true,
  "preferences": {
    "userId": "user_id_123",
    "critical": {
      "location": {
        "city": "San Francisco",
        "neighborhoods": ["Mission District", "SoMa", "Hayes Valley"],
        "maxDistance": 15
      },
      "budget": {
        "min": 1000,
        "max": 1500
      },
      "roomType": "private",
      "genderPreference": "same_gender",
      "moveInDate": "2023-05-01",
      "leaseDuration": "long_term"
    },
    "nonCritical": {
      "schedule": "night_owl",
      "noiseLevel": "moderate",
      "cookingFrequency": "daily",
      "diet": "no_restrictions",
      "smoking": "no",
      "drinking": "occasionally",
      "pets": "comfortable_with_pets",
      "cleaningHabits": "very_clean",
      "guestPolicy": "occasional_guests",
      "interestWeights": {
        "music": 5,
        "gaming": 4,
        "fitness": 3,
        "reading": 2
      }
    },
    "discoverySettings": {
      "ageRange": {
        "min": 21,
        "max": 35
      },
      "distance": 15,
      "showMeToOthers": true
    }
  }
}
```

### PUT /api/preferences

Update the user's matching preferences.

**Request Headers:**

```
Authorization: user@example.com
```

**Request Body:**

```json
{
  "critical": {
    "location": {
      "city": "San Francisco",
      "neighborhoods": ["Mission District", "SoMa", "Hayes Valley"],
      "maxDistance": 15
    },
    "budget": {
      "min": 1000,
      "max": 1500
    },
    "roomType": "private",
    "genderPreference": "same_gender",
    "moveInDate": "2023-05-01",
    "leaseDuration": "long_term"
  },
  "nonCritical": {
    "schedule": "night_owl",
    "noiseLevel": "moderate",
    "cookingFrequency": "daily",
    "diet": "no_restrictions",
    "smoking": "no",
    "drinking": "occasionally",
    "pets": "comfortable_with_pets",
    "cleaningHabits": "very_clean",
    "guestPolicy": "occasional_guests",
    "interestWeights": {
      "music": 5,
      "gaming": 4,
      "fitness": 3,
      "reading": 2
    }
  },
  "discoverySettings": {
    "ageRange": {
      "min": 21,
      "max": 35
    },
    "distance": 15,
    "showMeToOthers": true
  }
}
```

**Response (200 OK):**

```json
{
  "success": true,
  "message": "Preferences updated successfully",
  "preferences": {
    // Updated preferences object (same structure as in the request)
  }
}
```

## Flutter Implementation Roadmap

### 1. Project Setup and Authentication

1. **Project Structure**

   - Set up a new Flutter project
   - Organize folders (lib, assets, etc.)
   - Add necessary dependencies in pubspec.yaml

2. **Authentication Flow**

   - Create login and registration screens
   - Implement form validation
   - Store user email in SharedPreferences for authentication
   - Create an authentication service to handle API calls

3. **User Session Management**
   - Create a user session manager to handle logged-in state
   - Implement auto-login using stored email
   - Create a splash screen to check authentication status

### 2. Profile Management

1. **Profile Creation**

   - Create multi-step profile creation flow
   - Implement form validation for each step
   - Add image upload functionality for profile pictures
   - Create profile service to handle API calls

2. **Profile Editing**
   - Create profile editing screen
   - Implement form validation
   - Add image management functionality
   - Update profile service with edit methods

### 3. Discovery and Matching

1. **Discovery Screen**

   - Create a card-based UI for potential matches
   - Implement swipe gestures
   - Add profile preview functionality
   - Create discovery service to handle API calls

2. **Matching Logic**
   - Implement match creation on mutual likes
   - Create match notification system
   - Add match screen to view all matches
   - Create match service to handle API calls

### 4. Chat Implementation

1. **Chat List**

   - Create chat list screen
   - Implement real-time updates for new messages
   - Add unread message indicators
   - Create chat service to handle API calls

2. **Chat Conversation**
   - Create chat conversation screen
   - Implement message sending and receiving
   - Add message status indicators
   - Create message service to handle API calls

### 5. Preferences Management

1. **Preferences Screen**

   - Create preferences screen with form
   - Implement form validation
   - Add preference service to handle API calls

2. **Discovery Settings**
   - Create discovery settings screen
   - Implement range sliders for age and distance
   - Add toggle switches for visibility settings

### 6. State Management and Data Persistence

1. **State Management**

   - Implement a state management solution (Provider, Bloc, or Riverpod)
   - Create models for all data types
   - Implement repositories for data access

2. **Local Storage**
   - Use SharedPreferences for user session
   - Implement caching for profiles and messages
   - Create offline support for basic functionality

### 7. UI/UX Implementation

1. **Theme and Styling**

   - Create a consistent theme
   - Implement dark/light mode
   - Add custom widgets for common UI elements

2. **Animations and Transitions**
   - Add smooth transitions between screens
   - Implement loading animations
   - Add gesture animations for swipes

### 8. Testing and Optimization

1. **Testing**

   - Write unit tests for services and models
   - Implement widget tests for UI components
   - Add integration tests for critical flows

2. **Performance Optimization**
   - Optimize image loading and caching
   - Implement lazy loading for lists
   - Add error handling and retry mechanisms

### 9. Deployment and Release

1. **App Store Preparation**

   - Create app icons and splash screens
   - Write app descriptions and screenshots
   - Prepare privacy policy and terms of service

2. **Release Process**
   - Set up CI/CD pipeline
   - Implement version management
   - Create release checklist
