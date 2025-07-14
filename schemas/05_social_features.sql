-- ##########################################################
-- #                  SOCIAL FEATURES CORE                 #
-- # Friends, Messages, Chat Reactions, Blog Comments      #
-- ##########################################################
-- TABLE: Friends
CREATE TABLE
	friends (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		friend_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Friend Requests
CREATE TABLE
	friend_requests (
		request_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		sender_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		receiver_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		status VARCHAR(20) CHECK (status IN ('pending', 'accepted', 'declined')) DEFAULT 'pending',
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Conversations (1-on-1 or Group)
CREATE TABLE
	conversations (
		conversation_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		is_group_chat BOOLEAN DEFAULT FALSE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Conversation Members
CREATE TABLE
	conversation_members (
		id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		conversation_id UUID REFERENCES conversations (conversation_id) ON DELETE CASCADE,
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Messages
CREATE TABLE
	messages (
		message_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		conversation_id UUID REFERENCES conversations (conversation_id) ON DELETE CASCADE,
		sender_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		message_text TEXT NOT NULL,
		is_deleted BOOLEAN DEFAULT FALSE,
		sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Default Emoji Reactions
CREATE TABLE
	message_reactions (
		reaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		message_id UUID REFERENCES messages (message_id) ON DELETE CASCADE,
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		reaction TEXT NOT NULL CHECK (
			reaction IN ('like', 'heart', 'haha', 'sad', 'angry')
		),
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Custom Reaction Packs (Planned Feature)
CREATE TABLE
	reaction_sets (
		set_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		set_name VARCHAR(100) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Blog Posts (Admins Only)
CREATE TABLE
	blog_posts (
		post_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		author_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		title VARCHAR(255) NOT NULL,
		content TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Blog Comments
CREATE TABLE
	post_comments (
		comment_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		post_id UUID REFERENCES blog_posts (post_id) ON DELETE CASCADE,
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		comment_text TEXT NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Blog Post Reactions
CREATE TABLE
	post_reactions (
		reaction_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		post_id UUID REFERENCES blog_posts (post_id) ON DELETE CASCADE,
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		reaction TEXT NOT NULL CHECK (
			reaction IN ('like', 'heart', 'haha', 'sad', 'angry')
		),
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

-- TABLE: Notifications (All-purpose)
CREATE TABLE
	notifications (
		notification_id UUID PRIMARY KEY DEFAULT uuid_generate_v4 (),
		user_id UUID REFERENCES users (user_id) ON DELETE CASCADE,
		message TEXT NOT NULL,
		is_read BOOLEAN DEFAULT FALSE,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);