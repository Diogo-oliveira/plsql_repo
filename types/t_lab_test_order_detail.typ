CREATE OR REPLACE TYPE t_lab_test_order_detail force AS OBJECT
(
    id_analysis_req NUMBER(24),
    registry        VARCHAR2(1000 CHAR),
    num_order       VARCHAR2(1000 CHAR),
    priority        VARCHAR2(1000 CHAR),
    desc_status     VARCHAR2(1000 CHAR),
    desc_time       VARCHAR2(1000 CHAR),
    desc_analysis   VARCHAR2(4000 CHAR),
    cancel_reason   VARCHAR2(1000 CHAR),
    notes_cancel    VARCHAR2(1000 CHAR),
    dt_ord          VARCHAR2(200 CHAR)
)
;
/