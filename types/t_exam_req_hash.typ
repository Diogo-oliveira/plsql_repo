CREATE OR REPLACE TYPE t_exam_req_hash AS OBJECT
(
    id_exam_req               NUMBER(24),
    id_exam_req_det           NUMBER(24),
    flg_time                  VARCHAR2(10),
    clinical_indication_hash  VARCHAR2(200 CHAR),
    instructions_hash         VARCHAR2(200 CHAR),
    patient_instructions_hash VARCHAR2(200 CHAR),
    execution_hash            VARCHAR2(200 CHAR),
    health_plan_hash          VARCHAR2(200 CHAR),
    id_req_group              NUMBER(24)
)
;
/