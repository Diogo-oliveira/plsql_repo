create or replace view v_disch_reas_dest as
select 'Destinations' tipo, dd.id_disch_reas_dest, dd.id_discharge_reason, dr.id_discharge_dest id_disch_dest,
 pk_translation.get_translation(l.id_language, re.CODE_DISCHARGE_REASON) desc_discharge_reason,
pk_translation.GET_TRANSLATION(l.id_language, dr.code_discharge_dest) desc_discharge_dest,
 dr.rank, dr.flg_available, l.id_language
 from discharge_dest dr, disch_reas_dest dd, discharge_reason re, language l
 where dr.id_discharge_dest = dd.id_discharge_dest
 and re.id_discharge_reason = dd.id_discharge_reason
 UNION ALL
 select 'Specialties' tipo, dr.id_disch_reas_dest,  dr.id_discharge_reason, c.id_clinical_service id_disch_dest,
 pk_translation.get_translation(l.id_language, re.CODE_DISCHARGE_REASON) desc_discharge_reason,
 pk_translation.GET_TRANSLATION(l.id_language, c.code_clinical_service) desc_discharge_dest,
 cs.rank, 'Y' flg_available, l.id_language
 from disch_reas_dest dr, dep_clin_serv cs, clinical_service c , discharge_reason re, language l
 where cs.id_dep_clin_serv = dr.id_dep_clin_serv
 and c.id_clinical_service = cs.id_clinical_service
 and re.id_discharge_reason = dr.id_discharge_reason
 and dr.id_department is null
 UNION ALL
 select 'Institutions' tipo,dr.id_disch_reas_dest,  dr.id_discharge_reason, i.id_institution id_disch_dest,
 pk_translation.get_translation(l.id_language, re.CODE_DISCHARGE_REASON) desc_discharge_reason,
 pk_translation.GET_TRANSLATION(l.id_language, i.code_institution) desc_discharge_dest,
 i.rank, i.FLG_AVAILABLE, l.id_language
 from disch_reas_dest dr, institution i, discharge_reason re, language l
 where  i.id_institution = dr.id_institution
 and re.id_discharge_reason = dr.id_discharge_reason
UNION ALL
 select 'Department' tipo,dr.id_disch_reas_dest,  dr.id_discharge_reason, i.id_department id_disch_dest,
 pk_translation.get_translation(l.id_language, re.CODE_DISCHARGE_REASON) desc_discharge_reason,
 pk_translation.GET_TRANSLATION(l.id_language, i.code_department) ||
 nvl2(dr.id_dep_clin_serv,
      ' - ' || pk_translation.GET_TRANSLATION(l.id_language, 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || dcs.id_clinical_service),
			'') desc_discharge_dest,
 i.rank, 'Y' FLG_AVAILABLE, l.id_language
 from disch_reas_dest dr, department i, discharge_reason re, language l, dep_clin_serv dcs
 where  i.id_department = dr.id_department
 and re.id_discharge_reason = dr.id_discharge_reason
 AND dr.id_dep_clin_serv = dcs.id_dep_clin_serv(+)
