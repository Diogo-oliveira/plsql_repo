--Rui Batista 2007/07/10
--Reestrutração dos Alertas

create or replace view v_prof_alerts as
select p.id_professional, dcs.id_clinical_service, null id_room
from professional p, prof_dep_clin_serv pdcs, dep_clin_serv dcs
where pdcs.id_professional = p.id_professional
and pdcs.flg_status = 'S'
and dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv
union
select p.id_professional, null id_clinical_service, r.id_room id_room
from professional p, prof_room r
where r.id_professional = p.id_professional;