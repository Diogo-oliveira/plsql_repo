CREATE OR REPLACE VIEW V_EPIS_MTOS_SCORE AS
SELECT a.id_epis_mtos_score, a.id_episode, a.id_mtos_score, a.dt_create, a.flg_status, a.id_prof_create, a.id_cancel_reason, a.notes_cancel, a.dt_cancel, a.id_prof_cancel
FROM EPIS_MTOS_SCORE a;
