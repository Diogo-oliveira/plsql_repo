CREATE OR REPLACE TYPE t_health_education_order force AS OBJECT
(
    id_nurse_tea_req    NUMBER(24),
    action              VARCHAR2(50),
    subject             VARCHAR2(1000),
    topic               VARCHAR2(1000),
    clinical_indication VARCHAR2(4000),
    to_execute          VARCHAR2(1000),
    frequency           VARCHAR2(1000),
    start_date          VARCHAR2(200),
    order_notes         CLOB,
    description         CLOB,
    status              VARCHAR2(200),
    registry            VARCHAR2(1000),
    end_date            VARCHAR2(200)
)
;
/