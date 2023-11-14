CREATE OR REPLACE FUNCTION utl_http_utility.set_transfer_timeout(
	r utl_http_utility.req,
	timeout integer DEFAULT 60)
    RETURNS utl_http_utility.req
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	l_req utl_http_utility.req;
	l_timeout JSONB;
BEGIN   
	l_req := r;
	
	l_timeout := json_build_object('timeout', timeout);
	
	l_req.payload := l_req.payload::jsonb || l_timeout::jsonb;
	
	RETURN l_req;
    
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'In exception of utl_http_utility.set_transfer_timeout: %', sqlerrm;
END;
$BODY$;