CREATE OR REPLACE TYPE t_hhc_req AS OBJECT
(
    l_referral_type             VARCHAR2(4000),
    l_referral_origin           VARCHAR2(4000),
    l_medical_history           VARCHAR2(4000),
    l_problems                  table_varchar,
    l_vaccines                  VARCHAR2(4000),
    l_plan_care                 table_varchar,
    l_supply                    VARCHAR2(4000),
    l_referral_required         VARCHAR2(4000),
    l_referral_pharm            VARCHAR2(4000),
    l_inf_control               VARCHAR2(4000),
    l_investigation_lab         table_varchar,
    l_investigation_exam        table_varchar,
    l_care_giver_name           VARCHAR2(4000),
    l_care_giver_number         NUMBER,
    l_consult_name              VARCHAR2(4000),
    l_consult_number            NUMBER,
    l_family_relationship       NUMBER,
    l_firstname                 VARCHAR2(4000),
    l_othernames1               VARCHAR2(4000),
    l_lastname                  VARCHAR2(4000),
    l_othernames3               VARCHAR2(4000),
    l_phone_mobile_country_code NUMBER,
    l_phone_mobile              VARCHAR2(4000)
)
;
