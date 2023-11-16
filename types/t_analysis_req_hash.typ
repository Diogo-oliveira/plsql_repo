CREATE OR REPLACE TYPE t_analysis_req_hash AS OBJECT
(
    id_analysis_req           NUMBER(24),
    id_analysis_req_det       NUMBER(24),
    flg_time_harvest          VARCHAR2(10),
    id_analysis_group         NUMBER(24),
    clinical_indication_hash  VARCHAR2(200 CHAR),
    instructions_hash         VARCHAR2(200 CHAR),
    patient_instructions_hash VARCHAR2(200 CHAR),
    execution_hash            VARCHAR2(200 CHAR),
    health_plan_hash          VARCHAR2(200 CHAR),
    id_req_group              NUMBER(24)
);
/