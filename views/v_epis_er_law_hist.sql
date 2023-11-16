CREATE OR REPLACE VIEW V_EPIS_ER_LAW_HIST AS
SELECT e.id_epis_er_law,
       e.dt_epis_er_law_hist,
       e.id_episode,
       e.dt_activation,
       e.dt_inactivation,
       e.flg_er_law_status,
       e.id_cancel_reason,
       e.notes_cancel,
       e.id_prof_create,
       e.dt_create
  FROM epis_er_law_hist e;
