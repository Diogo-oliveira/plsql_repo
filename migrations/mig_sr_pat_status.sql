-- CHANGED BY: António Neto
-- CHANGE DATE: 16/12/2011 11:01
-- CHANGE REASON: [ALERT-210635] Fix duplicated lines for one SR episode/status - [PERFORMANCE] - SR_SearchActivePatientsResult01.swf

BEGIN
    FOR item IN (SELECT ps.id_episode, ps.flg_pat_status, MAX(ps.id_sr_pat_status) max_id_sr_pat_status
                   FROM sr_pat_status ps
                  WHERE ps.dt_status_tstz = (SELECT MAX(ps1.dt_status_tstz)
                                               FROM sr_pat_status ps1
                                              WHERE ps1.id_episode = ps.id_episode
                                                AND ps1.flg_pat_status = ps.flg_pat_status)
                  GROUP BY ps.id_episode, ps.flg_pat_status
                 HAVING COUNT(1) > 1)
    LOOP
        DELETE FROM sr_pat_status ps
         WHERE ps.id_sr_pat_status <> item.max_id_sr_pat_status
           AND ps.id_episode = item.id_episode
           AND ps.flg_pat_status = item.flg_pat_status;
    END LOOP;

END;
/

-- CHANGE END: António Neto
