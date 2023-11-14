CREATE OR REPLACE FUNCTION utl_http_utility.get_response(
	r utl_http_utility.req)
    RETURNS utl_http_utility.resp
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
AS $BODY$
DECLARE
	l_lambda_arn CHARACTER VARYING(255);
	l_lambda_region CHARACTER VARYING(55);
	l_resp utl_http_utility.resp;	
	l_res_payload JSON;
BEGIN   
	
	BEGIN
	
		SELECT lambda_arn, lambda_region INTO l_lambda_arn, l_lambda_region
		FROM utl_http_utility.utl_http_utility_params 
		WHERE lambda_key = 'aurora-http-helper' 
		LIMIT 1;
	
	EXCEPTION 
	WHEN OTHERS THEN
		RETURN NULL; 
	END; 
		
	RAISE NOTICE '%', r.payload; 
	
	SELECT payload INTO l_res_payload FROM aws_lambda.invoke(aws_commons.create_lambda_function_arn(l_lambda_arn, l_lambda_region), r.payload);	
	
	SELECT json_extract_path_text(l_res_payload, 'statusCode') status_code, l_res_payload, 'HTTP/1.1', r.private_hndl
	INTO l_resp.status_code,l_resp.response,l_resp.http_version, l_resp.private_hndl;
	
	RETURN l_resp;
    
EXCEPTION
    WHEN others THEN
        RAISE NOTICE 'In exception of utl_http_utility.get_response: %', sqlerrm;
END;
$BODY$;
