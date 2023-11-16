CREATE OR REPLACE VIEW v_ext_cause_codification AS
SELECT
-- Record ID
 t.id_transportation,
 --Gereral information
 t.id_episode,
 --codificaton
 v.id_visit,
 ecc.id_codification,
 --codificaton
 ec.id_external_cause,
 --code
 ecc.standard_code,
 --description
 ec.code_external_cause,
 --recording date
 t.dt_transportation_tstz dt_ext_cause_doc_tstz,
 --recorder name
 t.id_professional,
 --recorder acting specialty
 pk_prof_utils.get_reg_prof_id_dcs(t.id_professional, t.dt_transportation_tstz, t.id_episode) prof_id_dcs
  FROM transportation t
  JOIN episode e
    ON t.id_episode = e.id_episode
  LEFT JOIN visit v
    ON t.id_external_cause = v.id_external_cause
   AND v.id_visit = e.id_visit
  LEFT JOIN ext_cause_codification ecc
    ON ecc.id_external_cause = t.id_external_cause
  LEFT JOIN external_cause ec
    ON ec.id_external_cause = t.id_external_cause
 WHERE t.dt_transportation_tstz = (SELECT MAX(tt.dt_transportation_tstz)
                                     FROM transportation tt
                                    WHERE tt.id_episode = t.id_episode);
