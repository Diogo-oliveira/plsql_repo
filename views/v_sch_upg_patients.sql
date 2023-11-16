-- CHANGED BY: Telmo
-- CHANGE DATE: 21-11-2011
-- CHANGE REASON: ALERT-201623
create or replace view v_sch_upg_patients as
select sg.id_patient, d.id_institution, p.name, p.dt_birth, p.gender
from alert.sch_group sg join alert.schedule s on sg.id_schedule = s.id_schedule
  JOIN alert.dep_clin_serv dcs ON s.id_dcs_requested = dcs.id_dep_clin_serv
  JOIN alert.department d ON dcs.id_department = d.id_department
  left join patient p on p.id_patient = sg.id_patient
where d.id_institution <> 0
union
select sr.id_patient, d.id_institution, p.name, p.dt_birth, p.gender
from alert.schedule_sr sr join alert.schedule s on sr.id_schedule = s.id_schedule
  JOIN alert.dep_clin_serv dcs ON s.id_dcs_requested = dcs.id_dep_clin_serv
  JOIN alert.department d ON dcs.id_department = d.id_department
  left join patient p on p.id_patient = sr.id_patient
where d.id_institution <> 0;
-- CHANGE END: Telmo
