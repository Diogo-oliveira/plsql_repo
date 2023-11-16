
CREATE OR REPLACE TYPE t_rec_nnn_default_instruct force AS OBJECT
(
    id_nnn_entity          NUMBER(24),
    id_order_recurr_option NUMBER(24),
    id_order_recurr_plan   NUMBER(24),
    start_date             TIMESTAMP(6) WITH LOCAL TIME ZONE,
    flg_priority           VARCHAR2(1 CHAR),
    flg_time               VARCHAR2(1 CHAR),
    flg_prn                VARCHAR2(1 CHAR),
    prn_notes              CLOB
)
;
/