CREATE OR REPLACE VIEW V_PAT_PROBLEMS AS
SELECT pp.id_pat_problem,
       pp.id_patient,
       pp.id_diagnosis,
       pp.id_professional_ins,
       pp.desc_pat_problem,
       pp.notes,
       pp.flg_age,
       pp.year_begin,
       pp.month_begin,
       pp.day_begin,
       pp.year_end,
       pp.month_end,
       pp.id_pat_habit,
       pp.id_habit,
       pp.dt_resolution,
       pp.id_alert_diagnosis,
       d.id_codification,
       d.code_icd,
       d.id_content,
			 pp.flg_status,
			 pp.id_epis_diagnosis
  FROM pat_problem pp, habit h, diagnosis d, alert_diagnosis ad
 WHERE pp.id_diagnosis = d.id_diagnosis(+)
       AND pp.id_alert_diagnosis = ad.id_alert_diagnosis(+) -- ALERT 736: diagnosis synonyms
       AND pp.id_habit = h.id_habit(+);
