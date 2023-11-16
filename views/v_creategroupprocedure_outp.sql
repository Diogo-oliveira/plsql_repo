create or replace view v_creategroupprocedure_outp as
select distinct d.id_institution, se.id_sch_event id_group_procedure, se.code_sch_event code_translation, null id_content, se.dep_type flg_characteristic, decode(se.flg_available, 'Y', 'A', 'I')  flg_available
from sch_event_dcs sed
join dep_clin_serv dcs on sed.id_dep_clin_serv = dcs.id_dep_clin_serv
join appointment a on sed.id_sch_event = a.id_sch_event and dcs.id_clinical_service = a.id_clinical_service
join sch_event se on a.id_sch_event = se.id_sch_event
join department d on dcs.id_department = d.id_department;