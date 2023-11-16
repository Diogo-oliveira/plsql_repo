CREATE OR REPLACE TYPE t_epis_diagnosis force AS OBJECT
(

    id_episode             NUMBER(24),
    id_alert_diagnosis     NUMBER(24),
    id_diagnosis           NUMBER(24),
    id_epis_diagnosis      NUMBER(24),
    dt_confirmed_tstz      TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_epis_diagnosis_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_prof_confirmed      NUMBER(24),
    id_professional_diag   NUMBER(24),
    desc_epis_diagnosis    VARCHAR2(200 CHAR),
    flg_status             VARCHAR2(1 CHAR)

)
;
/
