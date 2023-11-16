drop type t_rec_diet force ;
CREATE OR REPLACE TYPE t_rec_diet force AS OBJECT
(
    id_epis_diet_req NUMBER(24),
    id_diet_type     NUMBER(24),
    diet_type        VARCHAR2(4000 CHAR),
    dt_initial_str   VARCHAR2(1000 CHAR),
    dt_end_str       VARCHAR2(1000 CHAR),
    diet_name        VARCHAR2(4000 CHAR),
    flg_status       VARCHAR2(1 CHAR)
);
/