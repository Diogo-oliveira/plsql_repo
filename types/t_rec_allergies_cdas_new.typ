-- CHANGED BY: Joel Lopes
-- CHANGE DATE: 15/01/2013
-- CHANGE REASON: [ALERT-179277] Print tool - CDA - one allergy is not appearing correctly, we have two allergies with the same name and in the report we can see 3
CREATE OR REPLACE TYPE t_rec_allergies_cdas_new FORCE AS OBJECT
(
    id_pat_allergy        NUMBER(24),
    id_allergy            NUMBER(12),
    flg_type              VARCHAR2(1 CHAR),
    flg_status            VARCHAR2(1 CHAR),
    status_desc           VARCHAR2(4000),
    onset                 NUMBER(4),
    allergy_type_code     VARCHAR2(1000 CHAR),
    allergy_type_desc     VARCHAR2(4000),
    severity_code         VARCHAR2(1000 CHAR),
    severity_desc         VARCHAR2(4000),
    severity_alert_desc   VARCHAR2(4000),
    symptoms_id           table_varchar,
    symptoms_code         table_varchar,
    symptoms_desc         table_varchar,
    symptoms_alert_desc   table_varchar,
	symptoms_num_id       table_number,
    drug_ingredient_code  VARCHAR2(1000 CHAR),
    drug_ingredient_desc  VARCHAR2(4000),
    allergy_alert_desc    VARCHAR2(4000),
    start_date_app_format VARCHAR2(100 CHAR),
    start_date            VARCHAR2(100 CHAR),
    id_content            VARCHAR2(200 CHAR),
    id_content_parent     VARCHAR2(200 CHAR),
    type_reaction         VARCHAR2(4000),
    desc_allergy          VARCHAR2(200),
    notes                 VARCHAR2(4000),
    flg_approved          VARCHAR2(1),
    desc_approved         VARCHAR2(200),
    day_begin             NUMBER(2),
    month_begin           NUMBER(2),
    year_begin            NUMBER(4),
    flg_edit              VARCHAR2(1),
    desc_edit             VARCHAR2(200),
    id_cancel_reason      NUMBER(24),
    cancel_notes          VARCHAR2(4000),
    update_time           TIMESTAMP(6) WITH LOCAL TIME ZONE
)
;
/
