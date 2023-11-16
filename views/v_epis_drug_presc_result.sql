-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 15/07/2011
-- CHANGE REASON: ALERT-185868
CREATE OR REPLACE VIEW V_EPIS_DRUG_PRESC_RESULT AS
SELECT dpr.id_drug_presc_result,
       dpr.id_drug_presc_plan,
       dpr.dt_drug_presc_result,
       dpr.value,
       dpr.evaluation,
       dpr.id_evaluation,
       dpr.notes_advers_react,
       dpr.id_prof_resp,
       dpr.notes
  FROM drug_presc_result dpr;
-- CHANGE END: Pedro Teixeira