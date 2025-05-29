-- Prevent Duplicate Friend Requests Trigger Function — Zone 25-14

CREATE OR REPLACE FUNCTION public.prevent_duplicate_friend_requests()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF EXISTS (
        SELECT 1 FROM friend_requests 
        WHERE sender_id = NEW.sender_id 
          AND receiver_id = NEW.receiver_id 
          AND status = 'pending'
    ) THEN
        RAISE EXCEPTION 'Friend request already sent.';
    END IF;
    RETURN NEW;
END;
$function$;
