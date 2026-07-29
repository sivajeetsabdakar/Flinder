# Flinder Data Models

This document outlines the data models required for the Flinder application using Supabase.

## Core Models

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
  verificationStatus: {
    email: boolean;
    phone: boolean;
  };
  notificationSettings: {
    newMatches: boolean;
    messages: boolean;
    appUpdates: boolean;
    pushNotifications: boolean;
  };
  deviceInfo: {
    deviceId: string;
    pushToken?: string;
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
  interests: string[];
  profilePictures: {
    id: string;
    url: string;
    isPrimary: boolean;
    uploadedAt: Date;
  }[];
  location: {
    city: string;
    neighborhood?: string;
    coordinates?: { latitude: number; longitude: number };
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
  languages: string[];
}
```

### Preference Model

```typescript
interface Preference {
  userId: string;
  critical: {
    location: {
      city: string;
      neighborhoods?: string[];
      maxDistance?: number;
    };
    budget: { min: number; max: number };
    roomType: "private" | "shared" | "studio" | "any";
    genderPreference: "same_gender" | "any_gender";
    moveInDate: Date | "immediate" | "next_month" | "flexible";
    leaseDuration: "short_term" | "long_term" | "flexible";
  };
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
    interestWeights?: Record<string, number>;
  };
  discoverySettings: {
    ageRange: { min: number; max: number };
    distance: number;
    showMeToOthers: boolean;
  };
}
```

## Interaction Models

### Swipe Model

```typescript
interface Swipe {
  id: string;
  swiperId: string;
  targetUserId: string;
  direction: "left" | "right";
  timestamp: Date;
}
```

### Match Model

```typescript
interface Match {
  id: string;
  user1Id: string;
  user2Id: string;
  createdAt: Date;
}
```

## Chat Models

### Conversation Model

```typescript
interface Conversation {
  id: string;
  matchId: string;
  participants: string[];
  createdAt: Date;
  lastMessageAt: Date;
}
```

### Message Model

```typescript
interface Message {
  id: string;
  conversationId: string;
  senderId: string;
  content: string;
  sentAt: Date;
}
```

## Notification Model

```typescript
interface Notification {
  id: string;
  userId: string;
  type: "match" | "message";
  title: string;
  body: string;
  createdAt: Date;
}
```

## Supabase Database Schema

### Tables

1. `users` - Authentication data
2. `profiles` - User profile information
3. `preferences` - Matching preferences
4. `profile_pictures` - User photos
5. `swipes` - Swipe actions
6. `matches` - Successful matches
7. `conversations` - Chat conversations
8. `messages` - Conversation messages
9. `notifications` - User notifications

## Data Classification

As outlined in the README.md, data is classified into:

### Critical Data (Hard Filters)

Used for filtering out incompatible matches based on absolute requirements:

- Location Preference
- Budget Range
- Room Type Preference
- Gender Preference
- Move-in Date
- Lease Duration

### Non-Critical Data (Soft Preferences)

Used by GenAI to create a more detailed profile description:

- Daily Schedule
- Noise Tolerance
- Cooking Frequency
- Diet Preferences
- Smoking Habits
- Alcohol Consumption
- Pet Preferences
- Hobbies & Interests
- Cleaning Habits
- Guest Policy

### Textual Data (Bio)

User-entered description for personalized matching using the Siamese Network.

### Real-time Communication Data

Data exchanged in real-time between matched users:

- Chat messages
- Typing indicators
- Online presence
- Read receipts
