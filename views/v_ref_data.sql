CREATE OR REPLACE VIEW V_REF_DATA AS
SELECT exr.id_external_request,
       i_orig.id_institution id_inst_orig,
       pk_translation.get_translation(1, i_orig.code_institution) orig_inst_desc,
       i_orig.ext_code orig_inst_ext_code,
       i_dest.id_institution id_inst_dest,
       pk_translation.get_translation(1, i_dest.code_institution) dest_inst_desc,
       i_dest.ext_code dest_inst_ext_code,
       ps.id_speciality,
       pk_translation.get_translation(1, ps.code_speciality) desc_speciality,
       exr.id_dep_clin_serv,
       pk_translation.get_translation(1, cs.code_clinical_service) desc_clinical_service,
       pk_p1_interface.get_justification(1, profissional(NULL, i_orig.id_institution, 4), exr.id_external_request) justification,
       (SELECT p1d.text
          FROM p1_detail p1d
         WHERE p1d.flg_type = 13
           AND p1d.flg_status = 'A'
           AND p1d.id_external_request = exr.id_external_request) observation,
       (SELECT p1d.text
          FROM p1_detail p1d
         WHERE p1d.flg_type = 16
           AND p1d.flg_status = 'A'
           AND p1d.id_external_request = exr.id_external_request) conclusions,
       exr.flg_priority,
       pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_PRIORITY', exr.flg_priority, 1) desc_flg_priority,
       exr.dt_requested,
       exr.dt_status_tstz,
       exr.flg_status,
       pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', exr.flg_status, 1) desc_flg_status,
       s.dt_begin_tstz dt_schedule_tstz,
       exr.id_patient,
       nvl(rod_prof.num_order, prof.num_order) num_order_orig, -- decode(exr.id_workflow, 4, rod.num_order, prof.num_order) num_order_orig,
       nvl(rod_prof.name, prof.name) name_orig --decode(exr.id_workflow, 4, rod.prof_name, prof.name) name_orig
  FROM p1_external_request exr
  JOIN p1_speciality ps
    ON (ps.id_speciality = exr.id_speciality)
  LEFT JOIN institution i_dest
    ON (i_dest.id_institution = exr.id_inst_dest)
  JOIN institution i_orig
    ON (i_orig.id_institution = exr.id_inst_orig)
  LEFT JOIN dep_clin_serv dcs
    ON (dcs.id_dep_clin_serv = exr.id_dep_clin_serv)
  LEFT JOIN clinical_service cs
    ON (cs.id_clinical_service = dcs.id_clinical_service)
  JOIN professional prof
    ON (prof.id_professional = exr.id_prof_requested)
  LEFT JOIN schedule s
    ON exr.id_schedule = s.id_schedule
  LEFT JOIN ref_orig_data rod
    ON exr.id_external_request = rod.id_external_request
  LEFT JOIN professional rod_prof
    ON (rod.id_professional = rod_prof.id_professional);
