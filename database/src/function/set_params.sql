CREATE OR REPLACE FUNCTION utl_http_utility.set_params(
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
	l_params JSONB;
	
BEGIN   
	l_req := r;
	
	if (json_extract_path(l_req.payload,'params') IS NULL)
	then
		l_params := json_build_object('params',json_build_object(name, value));
	else
		l_params := json_extract_path(l_req.payload,'params')::jsonb || json_build_object(name, value)::jsonb;
		l_params := json_build_object('params',l_params);
	end if; 
	
	l_req.payload := l_req.payload::jsonb || l_params::jsonb;
	
	RETURN l_req;
    
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'In exception of utl_http_utility.set_header: %', sqlerrm;
END;
$BODY$;