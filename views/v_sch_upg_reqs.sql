-- CHANGED BY: Telmo
-- CHANGE DATE: 27-06-2013
-- CHANGE REASON: ALERT-260738
create or replace view v_sch_upg_reqs as
select v.id_schedule, v.id_clinical_service, v.id_institution, sb.id_waiting_list external_id, 'W' flg_type
from v_sch_upg_schedules v join schedule_bed sb on v.id_schedule = sb.id_schedule
where sb.id_waiting_list is not null
union
select v.id_schedule, v.id_clinical_service, v.id_institution, we.id_waiting_list, 'W'
from v_sch_upg_schedules v join wtl_epis we on v.id_schedule = we.id_schedule
where we.id_epis_type = 4 and we.id_waiting_list is not null
union
select v.id_schedule, v.id_clinical_service, v.id_institution, erd.id_exam_req_det, 'R'
from v_sch_upg_schedules v 
  join schedule_exam se on v.id_schedule = se.id_schedule
  join exam_req_det erd on se.id_exam_req = erd.id_exam_req and se.id_exam = erd.id_exam
where  erd.id_exam_req_det is not null
union
select v.id_schedule, v.id_clinical_service, v.id_institution, cr.id_consult_req, 'R'
from v_sch_upg_schedules v join consult_req cr on v.id_schedule = cr.id_schedule
where v.flg_sch_type IN ('C', 'U', 'N', 'AS');
-- CHANGE END: Telmo