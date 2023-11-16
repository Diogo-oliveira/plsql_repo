-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 15/07/2011
-- CHANGE REASON: ALERT-185868
CREATE OR REPLACE VIEW V_EPIS_DRUG_PRESC_PLAN AS
SELECT dpp.id_drug_presc_plan,
       dpp.id_drug_presc_det,
       dpp.flg_status         flg_status_plan,
       dpp.id_episode         id_episode_plan,
       dpp.dt_plan_tstz,
       dpp.dt_take_tstz,
       dpp.dt_next_take,
       dpp.id_prof_writes,
       dpp.id_prof_adm,
       dpp.lot_number,
       dpp.dt_expiration,
       dpp.application_spot,
       dpp.notes              notes_plan,
       dpp.notes_advers_react,
       dpp.id_vacc_med_ext,
       dpp.dosage
  FROM drug_presc_plan dpp;
-- CHANGE END: Pedro Teixeira