-- CHANGED BY: nuno.amorim
-- CHANGE DATE: 22-10-2018
-- CHANGE REASON: EMR-7985
CREATE OR REPLACE VIEW V_SCH_API_MAP_IDS AS
select s.id_schedule_pfh,
       s.id_schedule_ext,
       s.create_user,
       s.create_time,
       s.create_institution,
       s.update_user,
       s.update_time,
       s.update_institution,
       s.id_schedule_procedure,
       s.dt_created from sch_api_map_ids s;
-- CHANGE END: nuno.amorim