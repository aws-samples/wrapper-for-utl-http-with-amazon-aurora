CREATE OR REPLACE FUNCTION utl_http_utility.write_line(
	r utl_http_utility.req,
	data text)
    RETURNS utl_http_utility.req
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	l_req utl_http_utility.req;
	l_data JSONB;
	l_text TEXT;
BEGIN   
	l_req := r;
	
	if (json_extract_path(l_req.payload,'body') IS NULL)
	then
		l_data := json_build_object('body', CONCAT_WS('', data, CHR(13), CHR(10)));
	else
		l_text := CONCAT_WS('', json_extract_path_text(l_req.payload,'body'), CHR(13), CHR(10), data, CHR(13), CHR(10));
		l_data := json_build_object('body', l_text);
	end if; 
	
	l_req.payload := l_req.payload::jsonb || l_data::jsonb;
	
	RETURN l_req;
    
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'In exception of utl_http_utility.write_line: %', sqlerrm;
END;
$BODY$;
