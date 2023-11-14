CREATE OR REPLACE PROCEDURE utl_http_utility.read_raw(
	IN r utl_http_utility.resp,
	OUT data bytea)
LANGUAGE 'plpgsql'
AS $BODY$
DECLARE
    l_resp utl_http_utility.resp;
    l_body BYTEA;
BEGIN
    l_resp := r;

    IF (l_resp.response IS NULL) THEN
        RAISE EXCEPTION 'The response payload is null.';
    END IF;

    l_body := convert_from(l_resp.response::bytea, 'UTF8');

    IF (l_body IS NOT NULL) THEN
        data := l_body;
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