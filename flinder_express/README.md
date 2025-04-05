# Flinder Express Server

Backend server for the Flinder roommate matching application.

## Overview

This is an Express.js server implementation for the Flinder application, providing RESTful API endpoints for the Flutter frontend. The server is built using an MVC (Model-View-Controller) architecture pattern and integrates with Supabase for data storage and authentication.

## Project Structure

```
Flinder_Express_Server/
├── config/               # Configuration files
├── controllers/          # Controller logic for handling requests
├── middleware/           # Custom middleware functions
├── models/               # Data models and database operations
├── routes/               # API route definitions
├── utils/                # Utility functions and helpers
├── .env                  # Environment variables
├── package.json          # Project dependencies
├── server.js             # Main application entry point
└── supabaseClient.js     # Supabase client configuration
```

## API Endpoints

### Authentication

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Authenticate a user

### Profiles

- `GET /api/profile/:id` - Get user profile
- `PUT /api/profile/:id` - Update user profile
- `POST /api/profile/photos` - Upload a profile photo
- `DELETE /api/profile/photos/:id` - Delete a profile photo

### Discovery

- `GET /api/discover` - Get potential roommate matches
- `POST /api/swipe` - Record a swipe action
- `GET /api/matches` - Get all user matches

### Conversations

- `GET /api/conversations` - Get all user conversations
- `GET /api/conversations/:id/messages` - Get messages for a conversation
- `POST /api/conversations/:id/messages` - Send a new message

### Preferences

- `GET /api/preferences` - Get user preferences
- `PUT /api/preferences` - Update user preferences

## Authentication

The server uses a simplified authentication approach where the client stores the user's email in SharedPreferences and provides it in the Authorization header for authenticated requests. The server validates this email against the database for each request.

## Database 

This server uses Supabase as the backend database. The database schema includes the following tables:

- users - User authentication and profile data
- device_info - User device information
- profiles - User profiles and preferences
- profile_pictures - User profile photos
- preferences - User matching preferences
- swipes - Swipe actions
- matches - Matched users
- conversations - Chat conversations
- messages - Chat messages
- notifications - User notifications

## Getting Started

1. Clone the repository
2. Install dependencies:
   ```
   npm install
   ```
3. Set up environment variables:
   - Copy `.env.example` to `.env`
   - Fill in the required values for SUPABASE_URL and SUPABASE_KEY
   
4. Run the development server:
   ```
   npm run dev
   ```

## Environment Variables

- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_KEY` - Supabase project API key
- `PORT` - Server port (default: 3000)
- `NODE_ENV` - Environment mode (development, production)

## Technologies Used

- Node.js
- Express.js
- Supabase
- bcrypt (for password hashing)
- Joi (for request validation)
- dotenv (for environment variables) 