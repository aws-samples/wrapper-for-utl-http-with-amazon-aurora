CREATE OR REPLACE FUNCTION utl_http_utility.begin_request(
	url character varying,
	method character varying DEFAULT 'GET'::character varying,
	http_version character varying DEFAULT NULL::character varying,
	https_host character varying DEFAULT NULL::character varying)
    RETURNS utl_http_utility.req
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	l_payload JSON := json_build_object('url', url, 'httpMethod', method);
	l_uuid uuid := gen_random_uuid();	
	l_req utl_http_utility.req;	
BEGIN   
	
	l_req.url := url; 
	l_req.method := method;
	l_req.http_version := COALESCE(http_version, 'HTTP/1.1');
	l_req.private_hndl := l_uuid;
	l_req.payload := l_payload;
	
	raise notice '%',l_req.private_hndl;
	
	RETURN l_req;
    
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'In exception of utl_http_utility.begin_request: %', sqlerrm;
END;
$BODY$;