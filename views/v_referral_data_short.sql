CREATE OR REPLACE VIEW V_REFERRAL_DATA_SHORT AS
SELECT v.id_external_request,
       v.id_patient,
       v.id_inst_orig,
       v.code_institution_orig orig_inst_code, --
       v.orig_inst_ext_code,
       v.id_inst_dest,
       v.code_institution_dest desc_inst_code, --
       v.dest_inst_ext_code,
       v.id_speciality,
       v.code_speciality speciality_code, --
       v.id_dep_clin_serv,
       v.code_clinical_service clinical_service_code, --
       v.flg_priority,
       'P1_EXTERNAL_REQUEST.FLG_PRIORITY' flg_priority_code, --
       v.flg_status,
       'P1_EXTERNAL_REQUEST.FLG_STATUS' flg_status_code, --
       v.decision_urg_level,
       'P1_EXTERNAL_REQUEST.DECISION_URG_LEVEL.' || v.decision_urg_level decision_urg_level_code,
       v.dt_status,
       v.dt_schedule,
       v.dt_requested,
       v.req_num_order prof_no_req,
       v.nickname_orig prof_nickname_req
  FROM (SELECT exr.id_external_request,
               exr.id_patient,
               i_orig.id_institution id_inst_orig,
               i_orig.code_institution code_institution_orig,
               i_orig.ext_code orig_inst_ext_code,
               i_dest.id_institution id_inst_dest,
               i_dest.code_institution code_institution_dest,
               i_dest.ext_code dest_inst_ext_code,
               exr.id_speciality,
               'P1_SPECIALITY.CODE_SPECIALITY.' || exr.id_speciality code_speciality,
               exr.id_dep_clin_serv,
               'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || dcs.id_clinical_service code_clinical_service,
               exr.flg_priority,
               exr.flg_status,
               exr.dt_status_tstz dt_status,
               exr.decision_urg_level,
               s.dt_begin_tstz dt_schedule,
               exr.dt_requested,
               nvl(rod_prof.num_order, prof.num_order) req_num_order, --         decode(exr.id_workflow, 4, rod.num_order, prof.num_order) req_num_order,
               nvl(rod_prof.name, prof.nick_name) nickname_orig -- decode(exr.id_workflow, 4, rod.prof_name, prof.nick_name) nickname_orig
          FROM p1_external_request exr
          LEFT JOIN institution i_dest
            ON (i_dest.id_institution = exr.id_inst_dest)
          JOIN institution i_orig
            ON (i_orig.id_institution = exr.id_inst_orig)
          LEFT JOIN dep_clin_serv dcs
            ON (dcs.id_dep_clin_serv = exr.id_dep_clin_serv)
          JOIN professional prof
            ON (prof.id_professional = exr.id_prof_requested)
          LEFT JOIN schedule s
            ON (exr.id_schedule = s.id_schedule AND s.flg_status = 'A')
          LEFT JOIN alert.ref_orig_data rod
            ON (rod.id_external_request = exr.id_external_request)
          LEFT JOIN professional rod_prof
            ON (rod.id_professional = rod_prof.id_professional)) v;
