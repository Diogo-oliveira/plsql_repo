-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
CREATE OR REPLACE VIEW v_sch_upg_schedules AS
   SELECT s.*, dcs.id_department, dcs.id_clinical_service, d.id_institution, cs.id_content id_content_clinical_service
   FROM alert.schedule s
           JOIN alert.dep_clin_serv dcs ON s.id_dcs_requested = dcs.id_dep_clin_serv
           JOIN alert.department d ON dcs.id_department = d.id_department
           JOIN alert.clinical_service cs ON dcs.id_clinical_service = cs.id_clinical_service
   WHERE s.flg_status IN ('A', 'T')
     AND NOT EXISTS (SELECT 1
                       FROM alert.sch_api_map_ids m
                      WHERE m.id_schedule_pfh = s.id_schedule)
     AND s.id_schedule <> -1
     AND s.flg_sch_type <> 'PM'
   UNION
   SELECT s1.*, dcs.id_department, dcs.id_clinical_service, d.id_institution, cs.id_content id_content_clinical_service
   FROM alert.schedule s1
       LEFT JOIN alert.schedule s2 ON s1.id_Schedule = s2.id_schedule_ref
       JOIN alert.dep_clin_serv dcs ON s1.id_dcs_requested = dcs.id_dep_clin_serv
       JOIN alert.department d ON dcs.id_department = d.id_department
       JOIN alert.clinical_service cs ON dcs.id_clinical_service = cs.id_clinical_service
   WHERE s1.flg_status = 'C'
     AND NOT EXISTS (SELECT 1
                       FROM alert.sch_api_map_ids m
                      WHERE m.id_schedule_pfh = s1.id_schedule)
     AND s1.id_schedule <> -1
     AND s1.id_schedule_ref IS NULL
     AND s2.id_schedule_ref IS NULL
     AND s1.flg_sch_type <> 'PM';
-- CHANGE END: Telmo