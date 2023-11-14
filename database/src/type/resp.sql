CREATE TYPE utl_http_utility.resp AS
(
	status_code integer,
	response json,
	http_version character varying(64),
	private_hndl uuid
);