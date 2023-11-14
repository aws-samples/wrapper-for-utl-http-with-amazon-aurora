CREATE TABLE IF NOT EXISTS utl_http_utility.utl_http_utility_params
(
    lambda_arn character varying(32767),
    lambda_region character varying(55),
    lambda_key character varying(255)
);

insert into utl_http_utility.utl_http_utility_params values ('arn:aws:lambda:<region>:<account-id>:function:aurora-http-helper','<region>','aurora-http-helper');