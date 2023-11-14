CREATE OR REPLACE FUNCTION utl_http_utility.write_raw(
	r utl_http_utility.req,
	data bytea)
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
    
    IF (json_extract_path(l_req.payload,'body') IS NULL) THEN
        l_data := json_build_object('body', encode(data, 'base64'));
    ELSE
        l_text := CONCAT_WS('', json_extract_path_text(l_req.payload,'body'), decode(CHR(13) || CHR(10), 'base64'), encode(data, 'base64'));
        l_data := json_build_object('body', l_text);
    END IF;
    
    l_req.payload := l_req.payload::jsonb || l_data::jsonb;
    
    RETURN l_req;
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'In exception of utl_http_utility.write_raw: %', sqlerrm;
END;
$BODY$;