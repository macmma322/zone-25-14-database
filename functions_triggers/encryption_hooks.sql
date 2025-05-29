-- Encryption Hooks Trigger Function — Zone 25-14

CREATE OR REPLACE FUNCTION public.encrypt_sensitive_data()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Check if email needs encryption
  BEGIN
    PERFORM pgp_sym_decrypt(NEW.email, 'your_secret_key_here');
  EXCEPTION WHEN others THEN
    NEW.email := pgp_sym_encrypt(convert_from(NEW.email, 'UTF8'), 'your_secret_key_here');
  END;

  -- Same for phone
  IF NEW.phone IS NOT NULL THEN
    BEGIN
      PERFORM pgp_sym_decrypt(NEW.phone, 'your_secret_key_here');
    EXCEPTION WHEN others THEN
      NEW.phone := pgp_sym_encrypt(convert_from(NEW.phone, 'UTF8'), 'your_secret_key_here');
    END;
  END IF;

  RETURN NEW;
END;
$function$;
