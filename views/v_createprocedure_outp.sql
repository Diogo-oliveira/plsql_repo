create or replace view v_createprocedure_outp as
select d.id_institution id_institution,
      a.id_appointment id_content,
      se.id_sch_event id_content_group_procedure,
      se.num_min_profs min_nbr_hresource,
      se.num_max_profs max_nbr_hresource,
      se.num_max_patients number_of_persons,
      a.code_appointment code_translation,
      se.dep_type flg_characteristic,
      decode(a.flg_available,'Y','A','I') flg_available,
      null duration,
      null icd,
      null gdh,
      null gender,
      null ageMin,
      null ageMax,
      CAST(COLLECT(to_number(dcs.id_dep_clin_serv)) AS table_number) coll_id_dep_clin_serv
from appointment a
  join sch_event_dcs sed on a.id_sch_event = sed.id_sch_event
  join sch_event se on sed.id_sch_event = se.id_sch_event
  join dep_clin_serv dcs on sed.id_dep_clin_serv = dcs.id_dep_clin_serv and dcs.id_clinical_service = a.id_clinical_service
  join department d on dcs.id_department = d.id_department
--where
 -- sed.flg_available = 'Y'
 -- and a.flg_available = 'Y'
 -- and dcs.flg_available = 'Y'
group by d.id_institution, a.id_appointment, se.id_sch_event, a.code_appointment, se.dep_type, a.flg_available,se.num_min_profs, se.num_max_profs,se.num_max_patients;