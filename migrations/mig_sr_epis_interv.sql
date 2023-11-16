-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 23/05/2011 
-- CHANGE REASON: [ALERT-181163]: Some fields of ALERT.SR_EPIS_INTERV not always filled 
BEGIN
    UPDATE sr_epis_interv sei
       SET sei.dt_interv_start_tstz =
           (SELECT sstd.dt_surgery_time_det_tstz
              FROM sr_surgery_time_det sstd
              JOIN sr_surgery_time srt
                ON srt.id_sr_surgery_time = sstd.id_sr_surgery_time
             WHERE sstd.id_episode = sei.id_episode_context
               AND srt.flg_type = 'IC'
               AND sstd.flg_status = 'A')
     WHERE sei.id_sr_epis_interv IN (SELECT sr.id_sr_epis_interv
                                       FROM sr_surgery_time_det s
                                       JOIN sr_epis_interv sr
                                         ON sr.id_episode_context = s.id_episode
                                       JOIN sr_surgery_time sst
                                         ON sst.id_sr_surgery_time = s.id_sr_surgery_time
                                      WHERE sr.dt_interv_start_tstz IS NULL
                                        AND sr.flg_status <> 'C'
                                        AND sst.flg_type = 'IC'
                                        AND s.flg_status = 'A');

    UPDATE sr_epis_interv sei
       SET sei.dt_interv_end_tstz =
           (SELECT sstd.dt_surgery_time_det_tstz
              FROM sr_surgery_time_det sstd
              JOIN sr_surgery_time srt
                ON srt.id_sr_surgery_time = sstd.id_sr_surgery_time
             WHERE sstd.id_episode = sei.id_episode_context
               AND srt.flg_type = 'FC'
               AND sstd.flg_status = 'A')
     WHERE sei.id_sr_epis_interv IN (SELECT sr.id_sr_epis_interv
                                       FROM sr_surgery_time_det s
                                       JOIN sr_epis_interv sr
                                         ON sr.id_episode_context = s.id_episode
                                       JOIN sr_surgery_time sst
                                         ON sst.id_sr_surgery_time = s.id_sr_surgery_time
                                      WHERE sr.dt_interv_end_tstz IS NULL
                                        AND sr.flg_status <> 'C'
                                        AND sst.flg_type = 'FC'
                                        AND s.flg_status = 'A');
END;
/
