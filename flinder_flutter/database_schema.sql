-- Schema for Flinder Chat System

-- Users Table (if not using Supabase Auth users table)
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  username TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Chats Table (representing a conversation)
CREATE TABLE IF NOT EXISTS chats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT, -- Optional, required for group chats
  is_group BOOLEAN DEFAULT FALSE,
  created_by UUID,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Chat Members Table (users in a chat)
CREATE TABLE IF NOT EXISTS chat_members (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
  user_id UUID,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(chat_id, user_id)
);

-- Messages Table
CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  chat_id UUID REFERENCES chats(id) ON DELETE CASCADE,
  sender_id UUID,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  attachment TEXT, -- URL to attachment
  attachment_type TEXT, -- Type of attachment (image, file, etc.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_messages_chat_id ON messages(chat_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_id ON messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_members_chat_id ON chat_members(chat_id);
CREATE INDEX IF NOT EXISTS idx_chat_members_user_id ON chat_members(user_id);

-- Realtime pub/sub setup
ALTER PUBLICATION supabase_realtime ADD TABLE chats;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_members;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Row Level Security Policies
-- These policies control which rows each user can see or modify

-- Chat Policies
ALTER TABLE chats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view chats they are members of" 
  ON chats FOR SELECT TO authenticated USING (
    id IN (
      SELECT chat_id FROM chat_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create chats" 
  ON chats FOR INSERT TO authenticated WITH CHECK (
    true
  );

-- Chat Members Policies
ALTER TABLE chat_members ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view chat members for chats they belong to" 
  ON chat_members FOR SELECT TO authenticated USING (
    chat_id IN (
      SELECT chat_id FROM chat_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can add members to chats" 
  ON chat_members FOR INSERT TO authenticated WITH CHECK (
    chat_id IN (
      SELECT id FROM chats WHERE created_by = auth.uid()
    ) OR (
      -- Allow users to add themselves to public chats
      user_id = auth.uid()
    )
  );

-- Messages Policies
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages for chats they are members of" 
  ON messages FOR SELECT TO authenticated USING (
    chat_id IN (
      SELECT chat_id FROM chat_members WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert messages into chats they are members of" 
  ON messages FOR INSERT TO authenticated WITH CHECK (
    chat_id IN (
      SELECT chat_id FROM chat_members WHERE user_id = auth.uid()
    ) AND sender_id = auth.uid()
  );

CREATE POLICY "Users can update their own messages" 
  ON messages FOR UPDATE TO authenticated USING (
    sender_id = auth.uid()
  );

-- Functions for common operations
CREATE OR REPLACE FUNCTION mark_messages_as_read(p_chat_id UUID, p_user_id UUID)
RETURNS VOID AS $$
BEGIN
  UPDATE messages
  SET is_read = true
  WHERE 
    chat_id = p_chat_id AND 
    is_read = false AND 
    sender_id != p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update chat's updated_at when a new message is added
CREATE OR REPLACE FUNCTION update_chat_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE chats
  SET updated_at = NOW()
  WHERE id = NEW.chat_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_chat_on_message
AFTER INSERT ON messages
FOR EACH ROW
EXECUTE FUNCTION update_chat_timestamp(); 