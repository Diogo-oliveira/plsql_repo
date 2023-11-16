-- CHANGED BY: Telmo
-- CHANGE DATE: 27-01-2011
-- CHANGE REASON: ALERT-156437
create or replace view v_sch_upg_vacancies as
-- vagas mfr --  nao ha suporte 
-- vagas oris -- nao ha suporte. Porque nao há informacao para obter um procedure de cirurgia no scheduler para cada vaga
-- vagas consulta, inpatient,
select scv.dt_begin_tstz dt_begin, 
      scv.dt_end_tstz dt_end,
      scv.id_prof, 
      scv.id_dep_clin_serv, 
      scv.id_room, 
      scv.id_sch_event,
      'N' flg_urgency,
      scv.id_sch_consult_vacancy,
      scv.id_institution,
      dcs.id_clinical_service, 
      cs.id_content id_content_cs,
      a.id_appointment id_content,
      se.dep_type flg_characteristic
from sch_event se
  JOIN sch_consult_vacancy scv ON se.id_sch_event = scv.id_sch_event
  JOIN alert.dep_clin_serv dcs ON scv.id_dep_clin_serv = dcs.id_dep_clin_serv
  JOIN alert.clinical_service cs on dcs.id_clinical_service = cs.id_clinical_service
  JOIN alert.appointment a ON a.id_sch_event = scv.id_sch_event AND a.id_clinical_service = cs.id_clinical_service
where nvl(scv.dt_end_tstz, scv.dt_begin_tstz) >= scv.dt_begin_tstz
  and nvl(scv.dt_end_tstz,  current_timestamp) >= current_timestamp
  and scv.flg_status = 'A'
  and scv.id_sch_event not in (11, 14, 7, 13)
  and scv.max_vacancies - scv.used_vacancies > 0
  and a.id_appointment is not null
union
-- vagas exames, outros exames
select scv.dt_begin_tstz, 
      scv.dt_end_tstz,
      scv.id_prof, 
      scv.id_dep_clin_serv, 
      scv.id_room, 
      scv.id_sch_event,
      'N',
      scv.id_sch_consult_vacancy,
      scv.id_institution,
      dcs.id_clinical_service, 
      cs.id_content id_content_cs,
      e.id_content,
      decode(scv.id_sch_event, 7, 'E', 13, 'X')
from exam e 
  JOIN sch_consult_vac_exam scve ON e.id_exam = scve.id_exam
  JOIN sch_consult_vacancy scv ON scve.id_sch_consult_vacancy = scv.id_sch_consult_vacancy
  JOIN alert.dep_clin_serv dcs ON scv.id_dep_clin_serv = dcs.id_dep_clin_serv
  JOIN alert.clinical_service cs on dcs.id_clinical_service = cs.id_clinical_service
where nvl(scv.dt_end_tstz, scv.dt_begin_tstz) >= scv.dt_begin_tstz
  and nvl(scv.dt_end_tstz,  current_timestamp) >= current_timestamp
  and scv.flg_status = 'A'
  and scv.id_sch_event in (7, 13)
  and scv.max_vacancies - scv.used_vacancies > 0
  and e.id_content IS NOT NULL;
-- CHANGE END: Telmo