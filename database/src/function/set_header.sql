CREATE OR REPLACE FUNCTION utl_http_utility.set_header(
	r utl_http_utility.req,
	name character varying,
	value character varying)
    RETURNS utl_http_utility.req
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	l_req utl_http_utility.req;
	l_headers JSONB;
	
BEGIN   
	l_req := r;
	
	if (json_extract_path(l_req.payload,'headers') IS NULL)
	then
		l_headers := json_build_object('headers',json_build_object(name, value));
	else
		l_headers := json_extract_path(l_req.payload,'headers')::jsonb || json_build_object(name, value)::jsonb;
		l_headers := json_build_object('headers',l_headers);
	end if; 
	
	l_req.payload := l_req.payload::jsonb || l_headers::jsonb;
	
	RETURN l_req;
    
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'In exception of utl_http_utility.set_header: %', sqlerrm;
END;
$BODY$;