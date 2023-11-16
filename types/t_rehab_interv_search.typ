CREATE OR REPLACE TYPE t_rehab_interv_search force AS OBJECT
(
    id_rehab_area_interv    NUMBER(24),
    id_intervention         NUMBER(24),
    id_intervention_parent  NUMBER(24),
    id_rehab_area           NUMBER(24),
    desc_rehab_area         VARCHAR2(1000 CHAR),
    desc_interv             VARCHAR2(1000 CHAR),
    flg_has_children        VARCHAR2(2),
    id_rehab_session_type   VARCHAR2(24 CHAR),
    desc_rehab_session_type VARCHAR2(1000 CHAR),
    flg_laterality_mcdt     VARCHAR2(10),
    id_codification         NUMBER(24)
);
/