# Flinder: Flatmates + Tinder

## Project Overview

    Flinder is a mobile application designed to help users find compatible roommates in desired locations. The app follows a Tinder-like swiping interface where users can indicate interest in potential flatmates or reject them based on their profiles.

## System Architecture

```
┌─────────────┐      ┌────────────────┐      ┌───────────────┐
│    Flutter  │◄────►│  Main Backend  │◄────►│ Database/Auth │
│   Frontend  │      │     Server     │      │    Supabase   │
└─────────────┘      │   (ExpressJS)  │      └───────────────┘
        ▲            └────────┬───────┘              ▲
        │                     │                      │
        │                     ▼                      │
        │            ┌────────────────┐      ┌───────────────┐
        │            │  Flask Server  │◄────►│    ML Model   │
        │            │   for ML Model │      │               │
        │            └────────────────┘      └───────────────┘
        │                     ▲
        │                     │
        │                     ▼
        │            ┌────────────────┐
        │            │     Gen AI     │
        │            │               │
        │            └────────────────┘
        │
        ▼
┌────────────────┐
│   Supabase     │
│   Realtime     │
└────────────────┘
```

## Core Components

### 1. Flutter Frontend

- User authentication and profile management
- Tinder-like swiping interface for potential roommates
- Chat functionality
- Profile creation and editing
- Preference settings for location, budget, lifestyle, etc.
- Notifications system
- Real-time messaging with typing indicators and online status

### 2. ExpressJS Backend Server

- Central API gateway for the Flutter app
- Routes management and API endpoint handling
- Authentication middleware
- Business logic implementation
- Coordination between various services
- Message history and conversation management

### 3. Supabase Database/Authentication

- User data storage
- Authentication services
- Profile information
- Match history and preferences
- Chat message storage
- File storage for message attachments

### 4. Supabase Realtime

- Real-time chat functionality
- Presence indicators (online/offline status)
- Typing indicators
- Instant message delivery
- Read receipts
- Real-time notification delivery

### 5. Flask Server for ML Model

- Hosting machine learning model API endpoints
- Processing compatibility algorithms
- Generating roommate recommendations
- Analyzing user preferences

### 6. ML Model

- Compatibility scoring algorithm
- Preference matching
- Smart recommendations based on user behavior
- Interest clustering

### 7. Gen AI Integration

- Enhanced profile suggestions
- Smart bio generation assistance
- Conversation starters for matches
- Interest tag recommendations
- Smart reply suggestions in chat

## User Flow

1. **Onboarding & Authentication**

   - User registration/login via email or social accounts
   - Basic profile setup (name, age, gender, etc.)
   - Location preferences setup

2. **Profile Creation**

   - Upload photos
   - Write bio describing themselves
   - Add interests and lifestyle preferences
   - Set roommate preferences (cleanliness, noise level, etc.)
   - Budget range and move-in timeline

3. **Discovery & Matching**

   - Main swiping interface to view potential roommates
   - Swipe right to express interest, left to reject
   - Algorithm presents candidates based on compatibility
   - Match notification when both users express interest

4. **Communication**

   - Real-time chat interface for matched users
   - Typing indicators and online status
   - Ability to share additional details/photos
   - Read receipts for message tracking
   - Option to unmatch if necessary
   - AI-suggested conversation starters
   - Media sharing capabilities

5. **Advanced Features**
   - Virtual tour scheduling for properties
   - Roommate agreement templates
   - Verification badges for trusted users
   - Integration with property listings

## Detailed Data Models

### User Model

```typescript
interface User {
  id: string;
  email: string;
  password: string; // Hashed
  name: string;
  phone?: string;
  dateOfBirth: Date;
  gender: "male" | "female" | "non_binary" | "prefer_not_to_say";
  createdAt: Date;
  lastActive: Date;
  profileCompleted: boolean;
  accountStatus: "active" | "inactive" | "suspended";
  verificationStatus: {
    email: boolean;
    phone: boolean;
    identity: boolean;
  };
  notificationSettings: {
    newMatches: boolean;
    messages: boolean;
    appUpdates: boolean;
    emailAlerts: boolean;
    pushNotifications: boolean;
  };
  deviceInfo: {
    deviceId: string;
    fcmToken?: string; // Firebase Cloud Messaging
    platform: "ios" | "android" | "web";
  }[];
  onlineStatus: "online" | "away" | "offline";
  lastOnline: Date;
}
```

### Profile Model

```typescript
interface Profile {
  userId: string;
  bio: string;
  generatedDescription: string;
  occupation?: string;
  education?: string;
  interests: string[];
  profilePictures: {
    id: string;
    url: string;
    isPrimary: boolean;
    uploadedAt: Date;
  }[];
  socialProfiles?: {
    instagram?: string;
    linkedin?: string;
    facebook?: string;
  };

  // Critical data (hard filters)
  location: {
    city: string;
    neighborhood?: string;
    coordinates?: {
      latitude: number;
      longitude: number;
    };
  };
  budget: {
    min: number;
    max: number;
    currency: string;
  };
  roomPreference: "private" | "shared" | "studio" | "any";
  genderPreference: "same_gender" | "any_gender";
  moveInDate: Date | "immediate" | "next_month" | "flexible";
  leaseDuration: "short_term" | "long_term" | "flexible";

  // Non-critical data (soft preferences)
  lifestyle: {
    schedule: "early_riser" | "night_owl" | "flexible";
    noiseLevel: "silent" | "moderate" | "loud";
    cookingFrequency: "rarely" | "sometimes" | "daily";
    diet: "vegetarian" | "vegan" | "non_vegetarian" | "no_restrictions";
    smoking: "yes" | "no" | "occasionally";
    drinking: "yes" | "no" | "occasionally";
    pets: "has_pets" | "no_pets" | "comfortable_with_pets";
    cleaningHabits: "very_clean" | "average" | "messy";
    guestPolicy: "no_guests" | "occasional_guests" | "frequent_guests";
  };

  // Additional information
  languages: string[];
  allergies?: string[];
  workSchedule?: "remote" | "office" | "hybrid" | "night_shifts";
  personalityTraits?: string[]; // AI-generated
}
```

### Preference Model

```typescript
interface Preference {
  userId: string;

  // Critical preferences (hard filters)
  critical: {
    location: {
      city: string;
      neighborhoods?: string[];
      maxDistance?: number; // in miles/km
    };
    budget: {
      min: number;
      max: number;
    };
    roomType: "private" | "shared" | "studio" | "any";
    genderPreference: "same_gender" | "any_gender";
    moveInDate: Date | "immediate" | "next_month" | "flexible";
    leaseDuration: "short_term" | "long_term" | "flexible";
  };

  // Non-critical preferences (soft preferences)
  nonCritical: {
    schedule?: "early_riser" | "night_owl" | "flexible";
    noiseLevel?: "silent" | "moderate" | "loud";
    cookingFrequency?: "rarely" | "sometimes" | "daily";
    diet?: "vegetarian" | "vegan" | "non_vegetarian" | "no_restrictions";
    smoking?: "yes" | "no" | "occasionally";
    drinking?: "yes" | "no" | "occasionally";
    pets?: "has_pets" | "no_pets" | "comfortable_with_pets";
    cleaningHabits?: "very_clean" | "average" | "messy";
    guestPolicy?: "no_guests" | "occasional_guests" | "frequent_guests";
    interestWeights?: Record<string, number>; // Interest name to weight (1-5)
  };

  // Discovery settings
  discoverySettings: {
    ageRange: {
      min: number;
      max: number;
    };
    distance: number; // in miles/km
    showMeToOthers: boolean;
    hideAfterMatch: boolean;
  };

  // ML model feedback
  mlFeedbackSettings?: {
    prioritizeCleanlinessMatch: boolean;
    prioritizeScheduleMatch: boolean;
    prioritizeInterestsMatch: boolean;
  };
}
```

### Swipe Model

```typescript
interface Swipe {
  id: string;
  swiperId: string;
  targetUserId: string;
  direction: "left" | "right" | "super"; // left for reject, right for like, super for super like
  timestamp: Date;
  seen: boolean; // Whether the target user has seen this swipe
  feedback?: {
    reason?:
      | "lifestyle"
      | "location"
      | "budget"
      | "appearance"
      | "bio"
      | "other";
    comment?: string;
  };
}
```

### Match Model

```typescript
interface Match {
  id: string;
  user1Id: string;
  user2Id: string;
  createdAt: Date;
  lastInteractionAt: Date;
  status: "active" | "inactive" | "blocked";
  compatibility: {
    score: number; // 0-100
    factors: string[]; // What factors contributed to high score
    challenges: string[]; // Potential challenges
  };
  conversationId: string; // Reference to the chat conversation
  notes?: {
    // Private notes each user can make about the match
    [userId: string]: string;
  };
  meetingScheduled?: {
    date: Date;
    location?: string;
    confirmed: boolean;
  };
}
```

### Chat Models

```typescript
interface Conversation {
  id: string;
  matchId: string;
  participants: string[]; // User IDs
  createdAt: Date;
  updatedAt: Date;
  lastMessageAt: Date;
  lastMessagePreview: string;
  unreadCountByUser: {
    [userId: string]: number;
  };
  status: "active" | "archived" | "deleted";
  typingUsers: string[]; // User IDs of currently typing users
}

interface Message {
  id: string;
  conversationId: string;
  senderId: string;
  content: string;
  attachments?: {
    type: "image" | "document" | "location" | "audio";
    url: string;
    name?: string;
    size?: number;
    duration?: number; // For audio/video
    previewUrl?: string;
  }[];
  sentAt: Date;
  deliveredAt?: Date;
  readAt?: {
    // Track read status per user
    [userId: string]: Date;
  };
  isDeleted: boolean;
  replyToMessageId?: string; // For threaded replies
  reactions?: {
    [userId: string]: string; // Emoji reactions
  };
  // For real-time status tracking
  status: "sending" | "sent" | "delivered" | "read" | "failed";
}

interface TypingIndicator {
  conversationId: string;
  userId: string;
  timestamp: Date;
  expiresAt: Date; // Auto-expire typing indicators
}

interface PresenceState {
  userId: string;
  status: "online" | "away" | "offline";
  lastActiveAt: Date;
  deviceInfo?: {
    deviceId: string;
    platform: "ios" | "android" | "web";
  };
}
```

### Notification Model

```typescript
interface Notification {
  id: string;
  userId: string;
  type: "match" | "message" | "system" | "verification";
  title: string;
  body: string;
  data: {
    matchId?: string;
    messageId?: string;
    userId?: string;
  };
  isRead: boolean;
  createdAt: Date;
  expireAt?: Date;
}
```

### Report Model

```typescript
interface Report {
  id: string;
  reporterId: string;
  reportedUserId: string;
  reason:
    | "inappropriate_content"
    | "harassment"
    | "fake_profile"
    | "spam"
    | "other";
  description: string;
  evidence?: {
    messageIds?: string[];
    screenshots?: string[]; // URLs
  };
  status: "pending" | "investigating" | "resolved" | "dismissed";
  createdAt: Date;
  resolvedAt?: Date;
  adminNotes?: string;
}
```

### Property Model (For future expansion)

```typescript
interface Property {
  id: string;
  ownerId: string;
  title: string;
  description: string;
  address: {
    street: string;
    city: string;
    state: string;
    zipCode: string;
    country: string;
    coordinates: {
      latitude: number;
      longitude: number;
    };
  };
  rent: {
    amount: number;
    currency: string;
    period: "monthly" | "weekly" | "daily";
    utilities: "included" | "excluded" | "partially_included";
    deposit: number;
  };
  details: {
    propertyType: "apartment" | "house" | "condo" | "townhouse";
    bedrooms: number;
    bathrooms: number;
    totalOccupants: number;
    availableRooms: number;
    amenities: string[];
    furnishing: "furnished" | "unfurnished" | "partially_furnished";
  };
  availableFrom: Date;
  minimumStay?: string; // e.g., "6 months", "1 year"
  photos: {
    id: string;
    url: string;
    caption?: string;
  }[];
  verified: boolean;
  createdAt: Date;
  updatedAt: Date;
  status: "active" | "pending" | "rented" | "inactive";
}
```

### Compatibility Score Model

```typescript
interface CompatibilityScore {
  userId1: string;
  userId2: string;
  overallScore: number; // 0-100
  categoryScores: {
    lifestyle: number; // 0-100
    interests: number; // 0-100
    location: number; // 0-100
    budget: number; // 0-100
  };
  matchingFactors: string[]; // e.g., "Both have similar cleaning standards"
  potentialChallenges: string[]; // e.g., "Different noise preferences"
  recommendationStrength: "strong" | "moderate" | "weak";
  calculatedAt: Date;
}
```

### User Activity Model

```typescript
interface UserActivity {
  userId: string;
  lastActive: Date;
  swipeMetrics: {
    rightSwipes: number;
    leftSwipes: number;
    superLikes: number;
    swipesPerDay: number;
    averageTimePerProfile: number; // in seconds
  };
  profileViewMetrics: {
    viewsReceived: number;
    averageTimeViewed: number; // in seconds
  };
  messageMetrics: {
    conversationsStarted: number;
    messagesSent: number;
    averageResponseTime: number; // in minutes
    averageMessageLength: number;
  };
  searchBehavior: {
    mostFrequentFilters: string[];
    averageSearchRadius: number;
  };
  appUsage: {
    sessionsPerDay: number;
    averageSessionLength: number; // in minutes
    mostActiveTimeOfDay: string; // e.g., "evening"
    mostUsedFeatures: string[];
  };
}
```

### ML Model Data

```typescript
interface MLModelInputData {
  userId: string;
  categoricalFeatures: {
    location: string;
    budget: number;
    roomType: string;
    gender: string;
    moveInTimeline: string;
    leaseDuration: string;
    schedule: string;
    noiseLevel: string;
    cookingFrequency: string;
    diet: string;
    smoking: string;
    drinking: string;
    pets: string;
    cleaningHabits: string;
    guestPolicy: string;
  };
  interestsVector: number[]; // Embedding vector of interests
  bioEmbedding: number[]; // Vector representation of bio text
  behavioralData: {
    swipeRatio: number; // Ratio of right to left swipes
    messageResponseRate: number;
    averageConversationLength: number;
    previousMatchPatterns: string[];
  };
}

interface MLModelOutputData {
  userId: string;
  recommendedProfiles: {
    userId: string;
    score: number;
    matchReason: string[];
  }[];
  clusterAssignment: number; // Which user cluster this person belongs to
  interestVector: number[]; // Updated interest vector
  preferenceWeights: {
    [preference: string]: number; // How much each preference matters to this user
  };
}
```

## Real-time Communication Implementation

### Supabase Realtime Integration

Flinder uses Supabase Realtime to provide real-time chat features:

1. **Channel Subscription**

   - Each conversation has a dedicated channel
   - Users subscribe to channels for their active conversations
   - Presence information is tracked per channel

2. **Message Delivery**

   - Messages are inserted into the database and broadcast to channel subscribers
   - Message status updates (delivered, read) are published in real-time
   - Typing indicators are sent as ephemeral events (not stored in DB)

3. **Presence Management**

   - User online status is tracked via Presence
   - App maintains heartbeats to update presence information
   - Offline detection with customizable timeout

4. **Implementation Pattern**

   ```dart
   // Flutter example of subscribing to a conversation
   final channel = supabase.channel('conversation:${conversationId}');

   // Listen for new messages
   channel.on('postgres_changes',
     event: 'INSERT',
     schema: 'public',
     table: 'messages',
     filter: 'conversation_id=eq.${conversationId}',
     callback: (payload) {
       // Handle new message
     }
   );

   // Track typing status
   channel.on('broadcast',
     event: 'typing',
     callback: (payload) {
       // Update typing indicator UI
     }
   );

   // Presence for online status
   channel.on('presence',
     event: 'sync',
     callback: (presence) {
       // Update online status UI
     }
   );

   // Subscribe to the channel
   channel.subscribe(
     (status, [error]) {
       // Handle subscription status
     }
   );
   ```

## Development Roadmap

### Phase 1: Core Development

- Set up Flutter project structure
- Implement basic UI components
- Create ExpressJS server and API routes
- Set up Supabase integration
- Implement authentication flow

### Phase 2: Feature Implementation

- Build swiping interface
- Develop profile creation flow
- Implement matching algorithm
- Create chat functionality
- Set up basic recommendation system

### Phase 3: Real-time Chat Implementation

- Integrate Supabase Realtime for messaging
- Implement typing indicators and read receipts
- Develop online status indicators
- Create message threading and reactions
- Build media sharing capabilities

### Phase 4: ML Integration

- Develop and train compatibility model
- Set up Flask server for ML model
- Integrate ML recommendations with main app
- Implement feedback loops for model improvement

### Phase 5: Gen AI Integration

- Integrate Gen AI for profile enhancements
- Implement smart replies and suggestions
- Add conversation starters
- Create interest tagging system

### Phase 6: Refinement & Scaling

- Performance optimization
- UI/UX improvements
- Expanded recommendation features
- Additional social features

## Technical Stack

### Frontend

- Flutter/Dart
- Provider for state management
- Flutter Secure Storage for local data
- Supabase Flutter SDK for real-time features

### Backend

- Node.js with Express
- JWT for authentication
- Supabase client for database operations
- API integration middleware

### Database & Real-time

- Supabase (PostgreSQL)
- Supabase Authentication
- Supabase Storage for media
- Supabase Realtime for chat and presence

### ML & AI

- Python/Flask for ML model serving
- TensorFlow/PyTorch for model development
- Gen AI integration via API

### DevOps

- GitHub for version control
- CI/CD pipeline
- Containerization for deployment
