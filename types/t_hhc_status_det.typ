CREATE OR REPLACE TYPE t_hhc_status_det force AS OBJECT
(
    id_epis_hhc_req   NUMBER(24),
    descr VARCHAR2(4000),
    val      NUMBER(24),
    val_clob       CLOB,
    type_text       VARCHAR2(0010 CHAR),
    flg_status    VARCHAR2(0010 CHAR)
);
/
