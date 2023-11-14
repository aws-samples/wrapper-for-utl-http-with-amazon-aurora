CREATE TYPE utl_http_utility.req AS
(
	url character varying(32767),
	method character varying(64),
	http_version character varying(64),
	private_hndl uuid,
	payload json
);
