-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 01/08/2019
-- CHANGE REASON: EMR-16311
CREATE OR REPLACE TYPE t_rec_dd_block AS OBJECT
(
    id_dd_block           NUMBER(24),
    condition_val         VARCHAR2(200 CHAR),
    rank                  NUMBER(24),
    hist_code_transaction VARCHAR2(200 CHAR)
);
-- CHANGE END: Pedro Teixeira
