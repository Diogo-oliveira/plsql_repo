-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 01/08/2019
-- CHANGE REASON: EMR-16311
CREATE OR REPLACE TYPE t_rec_dd_data force AS OBJECT
(
    descr    VARCHAR2(1000 CHAR),
    val   VARCHAR2(4000 CHAR),
    flg_type VARCHAR2(200 CHAR),
    flg_html VARCHAR2(1 CHAR),
    val_clob CLOB,
    flg_clob VARCHAR2(1 CHAR)
)
;
/
-- CHANGE END: Pedro Teixeira
