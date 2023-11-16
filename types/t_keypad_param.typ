-- CHANGED BY: António Neto
-- CHANGE DATE: 13/02/2012
-- CHANGE REASON: [ALERT-166586] EDIS restructuring - Present Illness
CREATE OR REPLACE TYPE t_keypad_param IS OBJECT
(
    data_area      VARCHAR2(24 CHAR),
    flg_may_clean  VARCHAR2(1 CHAR),
    flg_format     VARCHAR2(24 CHAR),
    cur_value      VARCHAR2(30 CHAR),
    min_value      VARCHAR2(30 CHAR),
    max_value      VARCHAR2(30 CHAR),
    flg_validation VARCHAR2(24 CHAR),
    CONSTRUCTOR FUNCTION t_keypad_param RETURN SELF AS RESULT
)
;
/
--CHANGE END: António Neto