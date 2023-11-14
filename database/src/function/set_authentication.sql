CREATE OR REPLACE FUNCTION utl_http_utility.set_authentication(
	r utl_http_utility.req,
	username character varying,
	password character varying DEFAULT NULL::character varying,
	scheme character varying DEFAULT 'Basic'::character varying)
    RETURNS utl_http_utility.req
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	l_req utl_http_utility.req;
	l_authentication JSONB;
BEGIN   
	l_req := r;
	
	if (json_extract_path(l_req.payload,'auth') IS NULL)
	then
		l_authentication := json_build_object('auth',json_build_object('username', username,'password',password));
	else
		l_authentication := json_extract_path(l_req.payload,'auth')::jsonb || json_build_object('username', username,'password',password)::jsonb;
		l_authentication := json_build_object('auth',l_authentication);
	end if; 
	
	l_req.payload := l_req.payload::jsonb || l_authentication::jsonb;
	
	RETURN l_req;
    
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'In exception of utl_http_utility.set_authentication: %', sqlerrm;
END;
$BODY$;