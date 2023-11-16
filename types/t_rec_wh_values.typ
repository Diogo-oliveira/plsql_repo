CREATE OR REPLACE TYPE t_rec_wh_values force AS OBJECT
(
    time_id          VARCHAR2(20 CHAR),
    parameter_id     NUMBER(24),
    value_id         NUMBER(24),
    value_status     VARCHAR2(1 CHAR),
    value_text       clob,
    value_units      VARCHAR2(1000 CHAR),
    value_icon       VARCHAR2(200 CHAR),
    value_flg_cancel VARCHAR2(1 CHAR),
    value_abnormal   VARCHAR2(200 CHAR),
    value_elem_count NUMBER(24),
    value_style      VARCHAR2(1 CHAR),
    woman_health_id  VARCHAR2(50 CHAR),
    dt_result_real   VARCHAR2(20 CHAR)
)
/
