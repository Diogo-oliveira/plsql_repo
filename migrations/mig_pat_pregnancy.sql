-- CHANGED BY: José Silva
-- CHANGE DATE: 06/06/2011 11:52
-- CHANGE REASON: [ALERT-183624] Pregnancy developments
DECLARE
 l_count NUMBER;

BEGIN

     SELECT COUNT(*)
       INTO l_count
       FROM pat_pregnancy pp
      WHERE pp.dt_init_pregnancy IS NOT NULL;
      
     IF l_count = 0
     THEN
        UPDATE pat_pregnancy pp
           SET pp.dt_init_pregnancy = coalesce(pp.dt_last_menstruation,
                                               CAST(pk_date_utils.trunc_insttimezone(profissional(0,
                                                                                                  (SELECT id_institution
                                                                                                     FROM episode
                                                                                                    WHERE id_patient =
                                                                                                          pp.id_patient
                                                                                                      AND rownum = 1),
                                                                                                  0),
                                                                                     
                                                                                     (pk_date_utils.add_to_tstz(nvl(pp.dt_intervention,
                                                                                                                    current_timestamp),
                                                                                                                -pp.num_gest_weeks * 7,
                                                                                                                'DAY'))) AS DATE),
                                               pp.dt_pat_pregnancy_tstz,
                                               current_timestamp);
                                               
        UPDATE pat_pregnancy_hist pp
           SET pp.dt_init_pregnancy = coalesce(pp.dt_last_menstruation,
                                               CAST(pk_date_utils.trunc_insttimezone(profissional(0,
                                                                                                  (SELECT id_institution
                                                                                                     FROM pat_pregnancy p
                                                                                                     JOIN episode e ON e.id_patient = p.id_patient
                                                                                                    WHERE id_pat_pregnancy = pp.id_pat_pregnancy
                                                                                                      AND rownum = 1),
                                                                                                  0),
                                                                                     
                                                                                     (pk_date_utils.add_to_tstz(nvl(pp.dt_intervention,
                                                                                                                    current_timestamp),
                                                                                                                -pp.num_gest_weeks * 7,
                                                                                                                'DAY'))) AS DATE),
                                               pp.dt_pat_pregnancy_tstz,
                                               current_timestamp);
                                                                                                     
        UPDATE pat_pregnancy pp SET pp.dt_init_preg_lmp = pp.dt_last_menstruation;
        UPDATE pat_pregnancy pp SET pp.dt_last_menstruation = NULL WHERE pp.num_gest_weeks IS NOT NULL;

        UPDATE pat_pregnancy_hist pp SET pp.dt_init_preg_lmp = pp.dt_last_menstruation;
        UPDATE pat_pregnancy_hist pp SET pp.dt_last_menstruation = NULL WHERE pp.num_gest_weeks IS NOT NULL;
        

        
     END IF;
END;
/
-- CHANGE END: José Silva