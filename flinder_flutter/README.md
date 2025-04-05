# Flinder Flutter App

A modern Flutter application for finding roommates, with integrated real-time chat functionality powered by Supabase.

## Setting up Supabase for Chat Functionality

This application uses Supabase for real-time chat functionality. Follow these steps to set up Supabase:

### 1. Supabase Project Setup

1. Create an account at [supabase.com](https://supabase.com) if you don't have one
2. Create a new Supabase project
3. Once your project is created, you'll need the Supabase URL and anon key
4. These credentials are already configured in the app at:
   ```
   lib/constants/api_constants.dart
   ```

### 2. Database Schema Setup

1. Go to the SQL Editor in your Supabase dashboard
2. Copy the contents of the `database_schema.sql` file from this project
3. Paste and execute the SQL to create the necessary tables and permissions

### 3. Enable Realtime

1. Go to Database → Replication in your Supabase dashboard
2. Make sure Realtime is enabled for the following tables:
   - `chats`
   - `chat_members`
   - `messages`

## Features

This app includes:

- User authentication
- User profile creation and management
- Matching with potential roommates
- Real-time chat with matches
- Property/room listings

## Technologies Used

- Flutter for cross-platform mobile development
- Supabase for backend services (authentication, database, realtime)
- Provider for state management

## Development

### Getting Started

1. Ensure you have Flutter installed on your development machine
2. Clone this repository
3. Run `flutter pub get` to install dependencies
4. Set up Supabase as described above
5. Run the app with `flutter run`

## Troubleshooting

If you encounter issues with the chat functionality:

1. Verify that Supabase is properly initialized in the app
2. Check that the database schema has been properly set up
3. Ensure that Realtime functionality is enabled in your Supabase project
4. Check the app console logs for any specific error messages

## License

This project is licensed under the MIT License - see the LICENSE file for details.
