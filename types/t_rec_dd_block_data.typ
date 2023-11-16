-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 01/08/2019
-- CHANGE REASON: EMR-16311
CREATE OR REPLACE TYPE t_rec_dd_block_data force AS OBJECT
(
    id_dd_block           NUMBER(24),
    rnk                   NUMBER(24),
    hist_dt_create        TIMESTAMP(6) WITH LOCAL TIME ZONE,
    hist_code_transaction VARCHAR2(200 CHAR),
    id_status             VARCHAR2(200 CHAR),
    id_prev_status        VARCHAR2(200 CHAR),
    c_n                   VARCHAR2(1 CHAR),
    data_source           VARCHAR2(200 CHAR),
    data_source_val       VARCHAR2(4000 CHAR),
    data_source_val_old   VARCHAR2(4000 CHAR)
)
;
/
-- CHANGE END: Pedro Teixeira
