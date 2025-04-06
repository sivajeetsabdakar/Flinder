-- SQL command to create flat_applications table
CREATE TABLE IF NOT EXISTS flat_applications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  flat_id UUID NOT NULL,
  group_chat_id UUID NOT NULL,
  user_id UUID NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE,
  FOREIGN KEY (flat_id) REFERENCES flats(id) ON DELETE CASCADE,
  FOREIGN KEY (group_chat_id) REFERENCES chats(id) ON DELETE CASCADE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_flat_applications_flat_id ON flat_applications(flat_id);
CREATE INDEX IF NOT EXISTS idx_flat_applications_group_chat_id ON flat_applications(group_chat_id);
CREATE INDEX IF NOT EXISTS idx_flat_applications_user_id ON flat_applications(user_id);

-- Enable row level security
ALTER TABLE flat_applications ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own applications"
  ON flat_applications FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own applications"
  ON flat_applications FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Only flat owners can update application status"
  ON flat_applications FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM flats
    WHERE flats.id = flat_applications.flat_id
    AND flats.owner_id = auth.uid()
  )); 