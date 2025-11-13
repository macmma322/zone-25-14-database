-- ##########################################################
-- #              MESSAGE READ TRACKING                     #
-- # Track individual message reads by users                #
-- ##########################################################

-- TABLE: Message Reads
CREATE TABLE IF NOT EXISTS message_reads (
    read_id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id UUID REFERENCES messages(message_id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    read_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(message_id, user_id)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_message_reads_message_id ON message_reads(message_id);
CREATE INDEX IF NOT EXISTS idx_message_reads_user_id ON message_reads(user_id);

-- Create index for conversation member last_read_at if not exists
CREATE INDEX IF NOT EXISTS idx_conversation_members_last_read_at ON conversation_members(conversation_id, last_read_at);
