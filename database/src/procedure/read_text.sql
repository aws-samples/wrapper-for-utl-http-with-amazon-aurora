CREATE OR REPLACE PROCEDURE utl_http_utility.read_text(
	IN r utl_http_utility.resp,
	OUT data text)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    l_resp utl_http_utility.resp;    
    l_body JSONB;
    l_body_text TEXT;
BEGIN   
    IF (r IS NULL) THEN
        RAISE EXCEPTION 'The response object is null.';
    END IF;

    l_resp := r;

    IF (l_resp.response IS NULL) THEN
        RAISE EXCEPTION 'The response payload is null.';
    END IF;

    l_body := json_extract_path(l_resp.response,'body');

    IF (l_body IS NOT NULL) THEN
        BEGIN
            SELECT json_extract_path_text(l_resp.response,'body') INTO l_body_text;
        EXCEPTION
            WHEN OTHERS THEN
                l_body_text := NULL;
                RAISE WARNING 'Unable to extract body text from response: %', SQLERRM;
        END;
        data := l_body_text;
    ELSE
        RAISE WARNING 'No body field found in response payload.';
        data := NULL;
    END IF;

    IF (l_resp.status_code >= 400) THEN
        RAISE WARNING 'HTTP error %: %', l_resp.status_code, data;
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'An error occurred while processing the HTTP response: %', SQLERRM;
END;
$BODY$;