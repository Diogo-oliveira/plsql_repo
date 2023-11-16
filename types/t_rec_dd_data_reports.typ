CREATE OR REPLACE TYPE t_rec_dd_data_reports force AS OBJECT
(
    id_record  NUMBER(24),
    descr      VARCHAR2(1000 CHAR),
    val        VARCHAR2(4000 CHAR),
    flg_type   VARCHAR2(200 CHAR),
    flg_html   VARCHAR2(1 CHAR),
    val_clob   CLOB,
    flg_clob   VARCHAR2(1 CHAR),
    flg_status VARCHAR2(1 CHAR)
)
;
/