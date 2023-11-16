CREATE OR REPLACE VIEW V_SCH_RESOURCE AS
SELECT id_sch_resource,
       id_schedule,
       id_institution,
       id_professional,
       dt_sch_resource_tstz,
       flg_leader,
       id_sch_consult_vacancy
  FROM sch_resource;
