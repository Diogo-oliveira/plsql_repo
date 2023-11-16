CREATE OR REPLACE TYPE alert.t_epis_documentation AS OBJECT
(
id_episode NUMBER(24),
ed_flg_status VARCHAR2(1),
e_flg_status varchar2(1)
);
/

CREATE OR REPLACE TYPE alert.t_tbl_epis_documentation IS TABLE OF t_epis_documentation;
