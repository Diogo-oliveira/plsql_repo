CREATE OR REPLACE TYPE t_rec_episode_diagnosis_cda FORCE AS OBJECT
(
    id_epis_diagnosis     NUMBER(24),
    id_diagnosis          NUMBER(24),
    id_alert_diagnosis    NUMBER(24),
    desc_diagnosis        VARCHAR(1000 CHAR),
    dt_initial_diag       VARCHAR2(30),--TIMESTAMP WITH LOCAL TIME ZONE,
    dt_initial_diag_chr   VARCHAR2(200 CHAR),
    flg_status            VARCHAR2(1 CHAR),
    desc_status           VARCHAR2(200 CHAR),
    dt_epis_diagnosis     TIMESTAMP
        WITH LOCAL TIME ZONE,
    dt_epis_diagnosis_chr VARCHAR2(200 CHAR),
    id_prof_diagnosis     NUMBER(24),
    name_prof_diag        VARCHAR2(200 CHAR),
    spec_prof_diag        VARCHAR(1000 CHAR),
    flg_type              VARCHAR2(200 CHAR),
		flg_previous          VARCHAR2(1 CHAR), 
		notes                 VARCHAR2(4000),
		flg_other             VARCHAR2(1 CHAR),
    id_content            VARCHAR2(200 CHAR),
    code_icd               VARCHAR2(200 CHAR),
    id_terminology_version NUMBER(24)
);

-- CHANGE END: Joel Lopes
/
-- CHANGED BY: Joel Lopes
-- CHANGE DATE: 2013-12-26
-- CHANGE REASON: ALERT-268459
CREATE OR REPLACE TYPE t_rec_episode_diagnosis_cda FORCE AS OBJECT
(
    id_epis_diagnosis     NUMBER(24),
    id_diagnosis          NUMBER(24),
    id_alert_diagnosis    NUMBER(24),
    desc_diagnosis        VARCHAR(1000 CHAR),
    dt_initial_diag       VARCHAR2(30),--TIMESTAMP WITH LOCAL TIME ZONE,
    dt_initial_diag_chr   VARCHAR2(200 CHAR),
    flg_status            VARCHAR2(1 CHAR),
    desc_status           VARCHAR2(200 CHAR),
    dt_epis_diagnosis     TIMESTAMP
        WITH LOCAL TIME ZONE,
    dt_epis_diagnosis_chr VARCHAR2(200 CHAR),
    id_prof_diagnosis     NUMBER(24),
    name_prof_diag        VARCHAR2(200 CHAR),
    spec_prof_diag        VARCHAR(1000 CHAR),
    flg_type              VARCHAR2(200 CHAR),
		flg_previous          VARCHAR2(1 CHAR), 
		notes                 VARCHAR2(4000),
		flg_other             VARCHAR2(1 CHAR),
    id_content            VARCHAR2(200 CHAR),
    code_icd               VARCHAR2(200 CHAR),
    id_terminology_version NUMBER(24)
);

-- CHANGE END: Joel Lopes
/
