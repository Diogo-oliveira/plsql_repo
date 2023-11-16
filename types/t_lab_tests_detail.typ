CREATE OR REPLACE TYPE t_lab_tests_detail FORCE AS OBJECT
(
    id_analysis_req_det  NUMBER(24),
    registry             VARCHAR2(1000 CHAR),
    desc_analysis        VARCHAR2(1000 CHAR),
    num_order            VARCHAR2(1000 CHAR),
    clinical_indication  VARCHAR2(1000 CHAR),
    diagnosis_notes      VARCHAR2(1000 CHAR),
    desc_diagnosis       VARCHAR2(1000 CHAR),
    clinical_purpose     VARCHAR2(1000 CHAR),
    instructions         VARCHAR2(1000 CHAR),
    priority             VARCHAR2(1000 CHAR),
    desc_status          VARCHAR2(1000 CHAR),
    title_order_set      VARCHAR2(1000 CHAR),
    task_depend          VARCHAR2(1000 CHAR),
    desc_time            VARCHAR2(1000 CHAR),
    desc_time_limit      VARCHAR2(1000 CHAR),
    order_recurrence     VARCHAR2(1000 CHAR),
    prn                  VARCHAR2(1000 CHAR),
    notes_prn            CLOB,
    patient_instructions VARCHAR2(1000 CHAR),
    fasting              VARCHAR2(1000 CHAR),
    notes_patient        CLOB,
    collection           VARCHAR2(1000 CHAR),
    collection_location  VARCHAR2(1000 CHAR),
    notes_scheduler      VARCHAR2(1000 CHAR),
    execution            VARCHAR2(1000 CHAR),
    perform_location     VARCHAR2(1000 CHAR),
    notes_technician     VARCHAR2(1000 CHAR),
    notes                VARCHAR2(1000 CHAR),
    results              VARCHAR2(1000 CHAR),
    prof_cc              VARCHAR2(1000 CHAR),
    prof_bcc             VARCHAR2(1000 CHAR),
    co_sign              VARCHAR2(1000 CHAR),
    prof_order           VARCHAR2(1000 CHAR),
    dt_order             VARCHAR2(200 CHAR),
    co_sign_status       VARCHAR2(200 CHAR),
    order_type           VARCHAR2(1000 CHAR),
    health_insurance     VARCHAR2(1000 CHAR),
    financial_entity     VARCHAR2(1000 CHAR),
    health_plan          VARCHAR2(1000 CHAR),
    insurance_number     VARCHAR2(200 CHAR),
    exemption            VARCHAR2(1000 CHAR),
    cancellation         VARCHAR2(1000 CHAR),
    cancel_reason        VARCHAR2(1000 CHAR),
    cancel_notes         VARCHAR2(1000 CHAR),
    cancel_prof_order    VARCHAR2(1000 CHAR),
    cancel_dt_order      VARCHAR2(200 CHAR),
    cancel_order_type    VARCHAR2(1000 CHAR),
    dt_last_update       VARCHAR2(200 CHAR),
    dt_ord               VARCHAR2(200 CHAR)
);
/
