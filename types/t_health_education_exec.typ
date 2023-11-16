CREATE OR REPLACE TYPE t_health_education_exec force AS OBJECT
(
    id_nurse_tea_req    NUMBER(24),
    id_nurse_tea_det    NUMBER(24),
    action              VARCHAR2(50),
    clinical_indication VARCHAR2(4000),
    goals               VARCHAR2(4000),
    method              VARCHAR2(4000),
    given_to            VARCHAR2(4000),
    deliverables        VARCHAR2(4000),
    understanding       VARCHAR2(4000),
    start_date          VARCHAR2(200),
    duration            VARCHAR2(200),
    end_date            VARCHAR2(200),
    description         CLOB,
    status              VARCHAR2(200),
    REGISTRY            VARCHAR2(1000),
    white_line          varchar2(1)   
)
;
/