-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 02/12/2010 17:25
-- CHANGE REASON: [ALERT-146441] Associate a surgical procedure to supplies
CREATE OR REPLACE VIEW v_sr_surgical_supplies AS
SELECT SUM(1) AS status,
       SUM(CASE
                WHEN sw.flg_status IN ('J', 'O', 'L', 'F') THEN
                 0
                ELSE
                 1
            END) AS status_completed,
            sw.id_episode
  FROM supply_workflow sw
 WHERE sw.id_supply_area = 3
 and sw.flg_status <> 'C'
   group by sw.id_episode;
-- CHANGE END: Filipe Silva
