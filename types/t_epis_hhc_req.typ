CREATE OR REPLACE TYPE t_epis_hhc_req AS OBJECT
(
    id_epis_hhc_req     NUMBER(24),
    id_episode          NUMBER(24),
    flg_status          VARCHAR2(1 CHAR),
    id_cancel_reason    NUMBER(24),
    cancel_notes        CLOB,
    id_prof_manager     NUMBER(24),
    dt_prof_manager     TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_patient          NUMBER(24),
    id_epis_hhc         NUMBER(24),
    id_prof_coordinator NUMBER(24)

);
/