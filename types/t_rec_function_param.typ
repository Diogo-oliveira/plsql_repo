CREATE OR REPLACE TYPE T_REC_FUNCTION_PARAM AS OBJECT
(
    flg_param_type VARCHAR2(1),
    flg_value_type VARCHAR2(1),
    param_value    VARCHAR2(4000)
);
/