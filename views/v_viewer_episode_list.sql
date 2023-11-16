create or replace view V_VIEWER_EPISODE_LIST as
  SELECT id_patient, et.code_epis_type o_code, COUNT o_count, epis1.dt_begin_tstz o_date
    FROM (SELECT row_number() over(PARTITION BY id_patient ORDER BY dt_begin_tstz DESC, id_episode DESC) rn,
                 id_episode,
                 dt_begin_tstz,
                 id_epis_type,
                 id_patient,
                 COUNT(0) over(PARTITION BY id_patient) COUNT
            FROM episode e
           WHERE e.flg_ehr = 'N'
            -- ALERT-275111
             --AND e.flg_status IN ('I', 'P')
						 ) epis1
    JOIN epis_type et
      ON (et.id_epis_type = epis1.id_epis_type)
   WHERE rn = 1;
