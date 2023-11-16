-- CHANGED BY: Adriana Ramos
-- CHANGE DATE: 09/10/2019
-- CHANGE REASON: EMR-21302
CREATE OR REPLACE TYPE t_rec_dd_data_rank force AS OBJECT
(
    descr VARCHAR2(2000 CHAR),
    val   VARCHAR2(4000 CHAR),
    TYPE  VARCHAR2(200 CHAR),
    rank_block NUMBER(24),
    rank_content NUMBER(24)
)
;
/
-- CHANGE END: Adriana Ramos
