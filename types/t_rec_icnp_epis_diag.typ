CREATE OR REPLACE TYPE t_rec_icnp_epis_diag AS OBJECT
(
    id_icnp_epis_diag      NUMBER(24),
    id_icnp_epis_diag_hist NUMBER(24),
    id_composition         NUMBER(12),
    id_professional        NUMBER(24),
    flg_status             VARCHAR2(1),
    id_episode             NUMBER(24),
    notes                  VARCHAR2(4000),
    id_prof_close          NUMBER(24),
    notes_close            VARCHAR2(4000),
    id_patient             NUMBER(24),
    dt_icnp_epis_diag_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    dt_close_tstz          TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_visit               NUMBER(24),
    id_epis_type           NUMBER(24),
    flg_executions         VARCHAR2(1),
    icnp_compo_reeval      NUMBER(24),
    id_prof_last_update    NUMBER(24),
    dt_last_update         TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_suspend_reason      NUMBER(24),
    id_suspend_prof        NUMBER(24),
    suspend_notes          VARCHAR2(1000 CHAR),
    dt_suspend             TIMESTAMP(6) WITH LOCAL TIME ZONE,
    id_cancel_reason       NUMBER(24),
    id_cancel_prof         NUMBER(24),
    cancel_notes           VARCHAR2(1000 CHAR),
    dt_cancel              TIMESTAMP(6) WITH LOCAL TIME ZONE,
    desc_interv            VARCHAR2(4000),
    flg_reav               varchar2(1 char)
);