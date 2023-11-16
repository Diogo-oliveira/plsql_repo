CREATE OR REPLACE TYPE t_rec_epis_transf force AS OBJECT
(
    id_record NUMBER(24),
    id_type   NUMBER(24),
    dt_record TIMESTAMP(6) WITH LOCAL TIME ZONE,
    type_desc VARCHAR2(200 CHAR),
    VALUE     VARCHAR2(2000 CHAR)
)
;
/
