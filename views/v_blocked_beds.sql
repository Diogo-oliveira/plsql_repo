-- CHANGED BY: Telmo
-- CHANGE DATE: 13-10-2011
-- CHANGE REASON: ALERT-193939
CREATE OR REPLACE VIEW V_BLOCKED_BEDS AS
WITH blocked_beds AS
(SELECT  ba.ID_BMNG_ACTION,
         ba.id_bed,
         ba.dt_begin_action,
         dep.id_institution,
         ba.dt_end_action
    FROM bmng_action ba
     INNER JOIN (SELECT ba.id_bed, MAX(ba.dt_creation) dt_creation
                FROM bmng_action ba
               INNER JOIN (SELECT ba.id_bed
                            FROM bmng_action ba
                           WHERE ba.flg_status = 'A'
                             AND ba.flg_bed_status = 'B') blocked_beds
                  ON (ba.id_bed = blocked_beds.id_bed)
               WHERE ba.flg_action = 'B'
               GROUP BY ba.id_bed) blocked_actions
      ON (ba.id_bed = blocked_actions.id_bed AND ba.dt_creation = blocked_actions.dt_creation)
   INNER JOIN bed b ON (b.id_bed = ba.id_bed)
   INNER JOIN room ro ON (ro.id_room = ba.id_room)
   INNER JOIN department dep ON (dep.id_department = ro.id_department)
   WHERE b.flg_status = 'O'
     AND b.flg_type = 'P'
     AND b.flg_available = 'Y'),
--
blocked_beds_dt_end AS
(SELECT MAX(ba.dt_end_action) dt_end, ba.id_bed
    FROM blocked_beds
   INNER JOIN bmng_action ba ON (ba.id_bed = blocked_beds.id_bed)
   WHERE ba.flg_target_action = 'B'
     AND ba.dt_end_action IS NOT NULL
   GROUP BY ba.id_bed)
--
SELECT bbs.ID_BMNG_ACTION,
       bbs.id_bed,
       bbs.dt_begin_action,
       bbs.id_institution,
       nvl(bbs.dt_end_action, bbde.dt_end) dt_end_action
  FROM blocked_beds bbs
INNER JOIN blocked_beds_dt_end bbde ON (bbs.id_bed = bbde.id_bed);
-- CHANGE END: Telmo