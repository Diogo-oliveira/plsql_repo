CREATE OR REPLACE TYPE t_rehab_interv AS OBJECT
(
    id_rehab_area_interv    NUMBER,
    id_intervention         NUMBER,
    id_intervention_parent  NUMBER,
    code_intervention       VARCHAR2(4000),
    id_rehab_area           NUMBER,
    id_rehab_session_type   VARCHAR2(200),
    code_rehab_session_type VARCHAR2(4000),
    flg_has_children        VARCHAR2(1),
    id_exec_institution     NUMBER(24)
)
;
/
