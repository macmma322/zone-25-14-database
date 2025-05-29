-- 06 Community Engagement — Zone 25-14 Schema

-- FRIEND REQUESTS
CREATE TABLE public.friend_requests (
	request_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	sender_id uuid NULL,
	receiver_id uuid NULL,
	status public."friend_request_status" DEFAULT 'pending'::friend_request_status NULL,
	sent_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	responded_at timestamp NULL,
	CONSTRAINT friend_requests_pkey PRIMARY KEY (request_id),
	CONSTRAINT friend_requests_receiver_id_fkey FOREIGN KEY (receiver_id) REFERENCES public.users(user_id) ON DELETE CASCADE,
	CONSTRAINT friend_requests_sender_id_fkey FOREIGN KEY (sender_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_requests_receiver ON public.friend_requests USING btree (receiver_id);
CREATE INDEX idx_requests_sender ON public.friend_requests USING btree (sender_id);

-- FRIENDS
CREATE TABLE public.friends (
	friendship_id uuid DEFAULT uuid_generate_v4() NOT NULL,
	user_id uuid NULL,
	friend_id uuid NULL,
	became_friends_at timestamp DEFAULT CURRENT_TIMESTAMP NULL,
	is_blocked bool DEFAULT false NULL,
	is_removed bool DEFAULT false NULL,
	CONSTRAINT friends_pkey PRIMARY KEY (friendship_id),
	CONSTRAINT friends_user_id_friend_id_key UNIQUE (user_id, friend_id),
	CONSTRAINT friends_friend_id_fkey FOREIGN KEY (friend_id) REFERENCES public.users(user_id) ON DELETE CASCADE,
	CONSTRAINT friends_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE
);

CREATE INDEX idx_friends_friend ON public.friends USING btree (friend_id);
CREATE INDEX idx_friends_user ON public.friends USING btree (user_id);
