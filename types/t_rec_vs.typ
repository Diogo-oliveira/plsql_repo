CREATE OR REPLACE TYPE t_rec_vs FORCE AS OBJECT
(
    id_vital_sign        NUMBER(24),
    dt_registry          TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_vital_sign_read   TIMESTAMP(6) WITH LOCAL TIME ZONE,
    VALUE                NUMBER(10, 3),
    id_vital_sign_read   NUMBER(24),
    id_unit_measure_vsr  NUMBER(24),
    flg_state            VARCHAR2(1 CHAR),
    id_prof_read         NUMBER(24),
    rank                 NUMBER(24),
    flg_fill_type        VARCHAR2(1),
    id_epis_triage       NUMBER(24),
    id_vital_sign_desc   NUMBER(24),
    id_unit_measure_vsi  NUMBER(24),
    relation_domain      VARCHAR2(1 CHAR),
    id_episode           NUMBER(24),
    vital_sign_scale     NUMBER(24),
    code_vs_short_desc   VARCHAR2(200 CHAR),
    id_software          NUMBER(24),
    id_institution       NUMBER(12),
    id_vs_scales_element NUMBER(24),
    color_grafh          VARCHAR2(200 CHAR),
    color_text           VARCHAR2(200 CHAR),
    id_fetus_number      NUMBER(24)
)
/
