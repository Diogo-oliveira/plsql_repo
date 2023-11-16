-- CHANGED BY: Luis Oliveira
-- CHANGE DATE: 28/07/2011 11:10
-- CHANGE REASON: [ALERT-37785] Implementation of the recurrence mechanism in ICNP functionality
CREATE OR REPLACE TYPE t_rec_interv_icnp_ea AS OBJECT
(
    id_icnp_epis_interv       NUMBER(24),
    id_icnp_epis_interv_group VARCHAR2(4000 CHAR), --Used to group interventions
    instr_desc                VARCHAR2(4000 CHAR), --Used to check the intervention group using the instructions
    id_composition_interv     NUMBER(12),
    id_icnp_epis_diag         NUMBER(24),
    id_composition_diag       NUMBER(12),
    flg_time                  VARCHAR2(1),
    status_str                VARCHAR2(200),
    status_msg                VARCHAR2(200),
    status_icon               VARCHAR2(200),
    status_flg                VARCHAR2(1),
    flg_status                VARCHAR2(1),
    flg_type                  VARCHAR2(1),
    dt_next                   TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    dt_plan                   TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    id_vs                     VARCHAR2(8),
    id_prof_close             NUMBER(24),
    dt_close                  TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    dt_icnp_epis_interv       TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    id_prof                   NUMBER(24),
    id_episode_origin         NUMBER(24),
    id_episode                NUMBER(24),
    id_patient                NUMBER(24),
    flg_status_plan           VARCHAR2(1),
    id_prof_take              NUMBER(24),
    notes                     VARCHAR2(4000),
    notes_close               VARCHAR2(4000),
    dt_begin                  TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    dt_take_ea                TIMESTAMP(6)
        WITH LOCAL TIME ZONE,
    dt_dg_last_update         TIMESTAMP(6)
);
/
-- CHANGE END: Luis Oliveira
