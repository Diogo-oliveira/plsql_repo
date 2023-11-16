CREATE OR REPLACE TYPE t_health_education_order_hist force AS OBJECT
(
    id_nurse_tea_req_hist   NUMBER(24),
    action                  VARCHAR2(50),
    subject                 VARCHAR2(1000),
    topic                   VARCHAR2(1000),
    clinical_indication     VARCHAR2(4000),
    clinical_indication_new VARCHAR2(4000),
    to_execute              VARCHAR2(1000),
    to_execute_new          VARCHAR2(1000),
    frequency               VARCHAR2(1000),
    frequency_new           VARCHAR2(1000),
    start_date              VARCHAR2(200),
    start_date_new          VARCHAR2(200),
    order_notes             CLOB,
    order_notes_new         CLOB,
    description             CLOB,
    description_new         CLOB,
    status                  VARCHAR2(200),
    status_new              VARCHAR2(200),
    registry                VARCHAR2(1000),
    white_line              VARCHAR2(1),
    end_date                VARCHAR2(200),
    end_date_new            VARCHAR2(200)
)
;
/
