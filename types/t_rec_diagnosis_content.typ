-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 2013-11-18
-- CHANGE REASON: ALERT-265471
CREATE OR REPLACE TYPE t_rec_diagnosis_content AS OBJECT
(
    id_diagnosis        NUMBER(24),
    id_diagnosis_parent NUMBER(24),
    id_alert_diagnosis  NUMBER(24),
    code_icd            VARCHAR2(200 CHAR),
    id_language         NUMBER(24),
    code_translation    VARCHAR2(200 CHAR),
    desc_translation    VARCHAR2(1000 CHAR),
    lucene_position     NUMBER,
    flg_other           VARCHAR2(1 CHAR),
    flg_icd9            VARCHAR2(1 CHAR),
    flg_select          VARCHAR2(1 CHAR),
    id_dep_clin_serv    NUMBER(24),
    flg_terminology     VARCHAR2(200 CHAR)
);
-- CHANGE END: Alexandre Santos