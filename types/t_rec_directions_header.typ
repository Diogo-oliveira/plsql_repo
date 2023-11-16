CREATE OR REPLACE FORCE TYPE t_rec_directions_header AS OBJECT
(
	flg_ins_upd_del        VARCHAR2(1),
	id_presc_directions    VARCHAR2(255),
	flg_take_type          VARCHAR2(1),
	take_type_description  VARCHAR2(1000),
	flg_execution          VARCHAR2(1),
	execution_description  VARCHAR2(1000),
	id_route               VARCHAR2(255),
	route_description      VARCHAR2(1000),
	vers                   VARCHAR2(10),
	notes                  VARCHAR2(4000),
	flg_free_text          VARCHAR2(1),
	directions_description VARCHAR2(4000),
	flg_fractionable       VARCHAR2(1)
);
