-- CHANGED BY: Telmo
-- CHANGE DATE: 13-10-2011
-- CHANGE REASON: ALERT-193939
CREATE OR REPLACE VIEW V_OCCUPIED_BEDS AS
SELECT bab.id_bmng_allocation_bed,
       b.id_bed,
       bab.id_patient,
       ei.id_dep_clin_serv,
       dcs.id_clinical_service,
       ba.dt_begin_action,
       pk_bmng_core.check_allocation_dates(1, profissional(null, 1, 11), ba.dt_begin_action, ba.dt_end_action) dt_end,
       dep.id_institution,
       p.name, 
       p.dt_birth, 
       p.gender
FROM bed b
 INNER JOIN room ro ON ro.id_room = b.id_room
 INNER JOIN department dep ON dep.id_department = ro.id_department
 INNER JOIN bmng_action ba ON ba.id_bed = b.id_bed
 LEFT JOIN bmng_allocation_bed bab ON bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed AND bab.flg_outdated = 'N'
 INNER JOIN epis_info ei ON ei.id_episode = bab.id_episode
 INNER JOIN dep_clin_serv dcs ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
 LEFT JOIN discharge_schedule ds ON ds.id_episode = ei.id_episode AND ds.flg_status = 'Y'
 INNER JOIN patient p ON p.id_patient = bab.id_patient
 WHERE b.flg_status = 'O'
   AND b.flg_type = 'P'
   AND b.flg_available = 'Y'
   AND ba.flg_status = 'A' 
   AND ba.flg_bed_ocupacity_status = 'O' 
   AND ba.flg_bed_status IN ('N', 'R');
-- CHANGE END: Telmo