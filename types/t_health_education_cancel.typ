CREATE OR REPLACE TYPE t_health_education_cancel force AS OBJECT
(
    id_nurse_tea_req NUMBER(24),
    action           VARCHAR2(50),
    cancel_reason    VARCHAR2(4000),
    cancel_notes     VARCHAR2(4000),
    registry         VARCHAR2(1000),
    white_line       VARCHAR2(1)
);
/