-- CHANGED BY: José Silva
-- CHANGE DATE: 27/08/2010 00:47
-- CHANGE REASON: [ALERT-120163] Administrative discharge cancellation
BEGIN
   UPDATE discharge d
    SET d.flg_status_adm = 'A'
WHERE d.flg_status = 'A' AND d.dt_admin_tstz IS NOT NULL;


   UPDATE discharge d
    SET d.flg_status_adm = 'C'
WHERE d.flg_status = 'C' AND d.dt_admin_tstz IS NOT NULL;

   UPDATE discharge_hist dh
    SET dh.flg_status_adm = 'A'
WHERE dh.flg_status = 'A' AND dh.dt_admin_tstz IS NOT NULL;


   UPDATE discharge_hist dh
    SET dh.flg_status_adm = 'C'
WHERE dh.flg_status = 'C' AND dh.dt_admin_tstz IS NOT NULL;


 UPDATE discharge d
    SET d.flg_market = 'US'
WHERE EXISTS (SELECT 0
                FROM discharge_hist dh
 WHERE dh.id_discharge = d.id_discharge)
  AND EXISTS (SELECT 0
              FROM episode e
 WHERE e.id_episode = d.id_episode
   AND e.id_epis_type IN (2, 4, 5));

 UPDATE discharge d
    SET d.flg_market = 'PT'
WHERE d.flg_market IS NULL;
END;
/
-- CHANGE END: José Silva