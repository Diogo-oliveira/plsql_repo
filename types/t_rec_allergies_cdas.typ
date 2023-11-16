-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 16/05/2011
-- CHANGE REASON: [ALERT-179277] Print tool - CDA - one allergy is not appearing correctly, we have two allergies with the same name and in the report we can see 3
CREATE OR REPLACE TYPE t_rec_allergies_cdas FORCE AS OBJECT
(
    id_pat_allergy              NUMBER(24),
    id_allergy                  NUMBER(12),
    flg_type                    VARCHAR2(1 CHAR),
    flg_status                  VARCHAR2(1 CHAR),
    status_desc                 VARCHAR2(4000),
    onset                       NUMBER(4),
    allergy_type_code           VARCHAR2(1000 CHAR),
    allergy_type_desc           VARCHAR2(4000),
    allergy_type_flg_coding     VARCHAR2(1 CHAR),
    severity_code               VARCHAR2(1000 CHAR),
    severity_desc               VARCHAR2(4000),
    severity_alert_desc         VARCHAR2(4000),
    severity_flg_coding         VARCHAR2(1 CHAR),
    symptoms_code               table_varchar,
    symptoms_desc               table_varchar,
    symptoms_alert_desc         table_varchar,
    symptoms_flg_coding         VARCHAR2(1 CHAR),
    drug_ingredient_code        VARCHAR2(1000 CHAR),
    drug_ingredient_desc        VARCHAR2(4000),
    allergy_alert_desc          VARCHAR2(4000),
    drug_ingredient_flg_coding  VARCHAR2(1 CHAR),
    flg_medication_allergy_type VARCHAR2(1 CHAR),
    start_date_app_format       VARCHAR2(100 CHAR),
    start_date                  VARCHAR2(100 CHAR)
);
/
