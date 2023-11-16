CREATE OR REPLACE TYPE t_wl_hhc_req FORCE AS OBJECT
(
    id_patient       NUMBER(24),
    id_dep_clin_serv NUMBER(24),
    id_service       NUMBER(24),
    id_speciality    NUMBER(24),
    id_requisition   NUMBER(24),
    flg_type         VARCHAR(0010 CHAR),
    dt_creation      TIMESTAMP WITH LOCAL TIME ZONE,
    id_user_creation NUMBER(24),
    id_institution   NUMBER(24),
    id_language      NUMBER(24),
    patient_name     VARCHAR2(1000),
    patient_origin   VARCHAR(1000),
    dt_status        TIMESTAMP WITH LOCAL TIME ZONE,
    id_content       VARCHAR2(1000),
    professionals    table_number
)
/