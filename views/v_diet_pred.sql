CREATE OR REPLACE VIEW V_DIET_PRED AS 
SELECT DISTINCT dpi.id_diet_prof_instit id_diet,
                dpi.desc_diet,
                alert_context('i_lang') l_lang,
                alert_context('i_prof_id') l_prof_id,
                alert_context('i_prof_institution') l_prof_institution,
                alert_context('i_prof_software') l_prof_software
  FROM diet_prof_instit dpi
 INNER JOIN diet_prof_pref dpp
    ON dpi.id_diet_prof_instit = dpp.id_diet_prof_instit
 WHERE dpp.flg_status = 'Y'
   AND dpi.flg_status = 'A'
   AND dpp.id_prof_pref = alert_context('i_prof_id')
   AND dpi.id_institution = alert_context('i_prof_institution');
