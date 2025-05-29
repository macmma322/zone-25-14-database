-- 05 Social Features — Zone 25-14 Schema

-- ENUMS
CREATE TYPE public."friend_request_status" AS ENUM (
	'pending',
	'accepted',
	'declined',
	'canceled'
);

CREATE TYPE public."group_chat_role" AS ENUM (
	'owner',
	'admin',
	'member',
	'muted',
	'banned'
);

-- CONVERSATIONS
CREATE TABLE public.conversations (
	conversation_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	is_group bool DEFAULT false NULL,
	group_name varchar(100) NULL,
	created_by uuid NULL,
	created_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT conversations_pkey PRIMARY KEY (conversation_id),
	CONSTRAINT conversations_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.users(user_id) ON DELETE SET NULL
);

-- MEMBERS
CREATE TABLE public.conversation_members (
	id uuid DEFAULT uuid_generate_v4() NOT NULL,
	conversation_id uuid NULL,
	user_id uuid NULL,
	"role" public."group_chat_role" DEFAULT 'member'::group_chat_role NULL,
	joined_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT conversation_members_conversation_id_user_id_key UNIQUE (conversation_id, user_id),
	CONSTRAINT conversation_members_pkey PRIMARY KEY (id),
	CONSTRAINT conversation_members_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(conversation_id) ON DELETE CASCADE,
	CONSTRAINT conversation_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);

-- MESSAGES
CREATE TABLE public.messages (
	message_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	conversation_id uuid NULL,
	sender_id uuid NULL,
	"content" text NOT NULL,
	is_deleted bool DEFAULT false NULL,
	sent_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT messages_pkey PRIMARY KEY (message_id),
	CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(conversation_id) ON DELETE CASCADE,
	CONSTRAINT messages_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);

-- REACTIONS
CREATE TABLE public.message_reactions (
	reaction_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	message_id uuid NULL,
	user_id uuid NULL,
	reaction varchar(50) NOT NULL,
	reacted_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	CONSTRAINT message_reactions_pkey PRIMARY KEY (reaction_id),
	CONSTRAINT message_reactions_message_id_fkey FOREIGN KEY (message_id) REFERENCES public.messages(message_id) ON DELETE CASCADE,
	CONSTRAINT message_reactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);

-- MESSAGE REQUESTS
CREATE TABLE public.message_requests (
	request_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	sender_id uuid NULL,
	receiver_id uuid NULL,
	"content" text NOT NULL,
	sent_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	status varchar(20) DEFAULT 'pending'::character varying NULL,
	CONSTRAINT message_requests_pkey PRIMARY KEY (request_id),
	CONSTRAINT message_requests_status_check CHECK (((status)::text = ANY ((ARRAY['pending', 'accepted', 'declined'])::text[]))),
	CONSTRAINT message_requests_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(user_id) ON DELETE CASCADE,
	CONSTRAINT message_requests_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);
