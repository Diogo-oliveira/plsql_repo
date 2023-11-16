CREATE OR REPLACE TYPE t_exam_co_sign force AS OBJECT
(
    id_exam_req_det NUMBER(24),
    prof_order      VARCHAR2(1000 CHAR),
    dt_order        VARCHAR2(200 CHAR),
    order_type      VARCHAR2(1000 CHAR),
    co_sign_prof    VARCHAR2(1000 CHAR),
    co_sign_date    VARCHAR2(200 CHAR),
    registry        VARCHAR2(1000 CHAR),
    flg_status      VARCHAR2(1 CHAR),
    co_sign_notes   CLOB
)
;
/