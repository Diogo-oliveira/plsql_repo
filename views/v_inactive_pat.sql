CREATE OR REPLACE VIEW v_inactive_pat AS
SELECT /*+ use_nl(e d pat v psa) */
 e.id_episode     id_episode,
 pat.id_patient   id_patient,
 pat.dt_birth     dt_birth,
 pat.age          age,
 pat.gender       gender,
 psa.location     location,
 d.dt_med_tstz    dt_med_tstz,
 e.dt_begin_tstz  dt_begin_tstz,
 e.flg_status     flg_status,
 v.id_institution id_institution,
 d.dt_cancel_tstz dt_cancel_tstz,
 d.dt_admin_tstz  dt_admin_tstz,
 e.id_epis_type   id_epis_type,
 e.dt_end_tstz    dt_end_tstz,
 d.dt_med_tstz    dt_disch
  FROM episode e
  JOIN visit v
    ON v.id_visit = e.id_visit
  JOIN patient pat
    ON v.id_patient = pat.id_patient
  JOIN (SELECT d1.*
          FROM discharge d1
         WHERE d1.dt_med_tstz >=
               CAST(current_timestamp - numtodsinterval(alert_context('ndays'), 'DAY') AS TIMESTAMP WITH LOCAL TIME ZONE)
           AND d1.flg_status IN ('A', 'P')
        UNION
        SELECT d2.*
          FROM discharge d2
         WHERE d2.dt_admin_tstz >=
               CAST(current_timestamp - numtodsinterval(alert_context('ndays'), 'DAY') AS TIMESTAMP WITH LOCAL TIME ZONE)
           AND d2.flg_status IN ('A', 'P')) d
    ON d.id_episode = e.id_episode
  JOIN pat_soc_attributes psa
    ON psa.id_patient = pat.id_patient
  LEFT JOIN episode e2
    ON e2.id_episode = e.id_prev_episode
UNION
SELECT /*+ use_nl(e d pat v psa) */
 e.id_episode     id_episode,
 pat.id_patient   id_patient,
 pat.dt_birth     dt_birth,
 pat.age          age,
 pat.gender       gender,
 psa.location     location,
 d.dt_med_tstz    dt_med_tstz,
 e.dt_begin_tstz  dt_begin_tstz,
 e.flg_status     flg_status,
 v.id_institution id_institution,
 d.dt_cancel_tstz dt_cancel_tstz,
 d.dt_admin_tstz  dt_admin_tstz,
 e.id_epis_type   id_epis_type,
 e.dt_end_tstz    dt_end_tstz,
 d.dt_med_tstz    dt_disch
  FROM (SELECT *
          FROM episode ex
         WHERE ex.dt_end_tstz >=
               CAST(current_timestamp - numtodsinterval(alert_context('ndays'), 'DAY') AS TIMESTAMP WITH LOCAL TIME ZONE)) e
  JOIN visit v
    ON v.id_visit = e.id_visit
  JOIN patient pat
    ON v.id_patient = pat.id_patient
  JOIN discharge d
    ON d.id_episode = e.id_episode
  JOIN pat_soc_attributes psa
    ON psa.id_patient = pat.id_patient
  LEFT JOIN episode e2
    ON e2.id_episode = e.id_prev_episode
 WHERE d.flg_status IN ('A', 'P');
