CREATE OR REPLACE VIEW V_REFERRAL_DATA AS
SELECT v.id_external_request,
       v.id_workflow,
       v.id_patient,
       v.id_inst_orig,
       pk_translation.get_translation(1, v.code_institution_orig) orig_inst_desc,
       v.orig_inst_ext_code,
       v.id_inst_dest,
       pk_translation.get_translation(1, v.code_institution_dest) dest_inst_desc,
       v.dest_inst_ext_code,
       v.id_speciality,
       pk_translation.get_translation(1, v.code_speciality) desc_speciality,
       v.id_dep_clin_serv,
       pk_translation.get_translation(1, v.code_clinical_service) desc_clinical_service,
       pk_p1_interface.get_justification(1, profissional(NULL, v.id_inst_orig, 4), v.id_external_request) justification,
       v.flg_priority,
       pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_PRIORITY', v.flg_priority, 1) desc_flg_priority,
       v.flg_home flg_home,
       pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_HOME', v.flg_priority, 1) desc_flg_home,
       v.flg_status,
       pk_sysdomain.get_domain('P1_EXTERNAL_REQUEST.FLG_STATUS', v.flg_status, 1) desc_flg_status,
       v.dt_status,
       v.dt_schedule,
       v.dt_requested,
       v.req_num_order prof_no_req, -- req_num_order
       v.nickname_orig prof_nickname_req, -- nickname_orig
       v.flg_doc,
       v.id_reason,
       pk_translation.get_translation(1, 'P1_REASON_CODE.CODE_REASON.' || v.id_reason) desc_reason,
       v.id_prof_status,
       v.name_prof_status prof_name_status, -- name_prof_status
       -- dt_last_update
       (SELECT dt_tracking_tstz
          FROM (SELECT id_external_request, dt_tracking_tstz
                  FROM p1_tracking
                 WHERE flg_type != 'R'
                 ORDER BY dt_tracking_tstz DESC) t
         WHERE t.id_external_request = v.id_external_request
           AND rownum = 1) dt_last_update,
       decision_urg_level,
       pk_sysdomain.get_domain('P1_TRIAGE_LEVEL.MED_HS_1', decision_urg_level, 1) decision_urg_level_desc,
       prof_answer.num_order prof_no_answer,
       prof_answer.name prof_name_answer,
       prof_sch.num_order prof_no_scheduled,
       prof_sch.name prof_name_scheduled
  FROM (SELECT exr.id_external_request,
               exr.id_workflow,
               exr.id_patient,
               i_orig.id_institution id_inst_orig,
               i_orig.code_institution code_institution_orig,
               i_orig.ext_code orig_inst_ext_code,
               i_dest.id_institution id_inst_dest,
               i_dest.code_institution code_institution_dest,
               i_dest.ext_code dest_inst_ext_code,
               ps.id_speciality,
               ps.code_speciality,
               exr.id_dep_clin_serv,
               cs.code_clinical_service,
               exr.flg_priority,
               exr.flg_home flg_home,
               exr.flg_status,
               exr.dt_status_tstz dt_status,
               s.dt_begin_tstz dt_schedule,
               exr.dt_requested,
               nvl(rod_prof.num_order, prof.num_order) req_num_order, --decode(exr.id_workflow, 4, rod.num_order, prof.num_order) req_num_order,
               nvl(rod_prof.name, prof.nick_name) nickname_orig, --decode(exr.id_workflow, 4, rod.prof_name, prof.nick_name) nickname_orig,
               -- documents?
               decode((SELECT COUNT(1)
                        FROM doc_external de
                       WHERE de.id_external_request = exr.id_external_request
                         AND flg_status = 'A'
                         AND rownum = 1),
                      0,
                      'N',
                      'Y') flg_doc,
               -- reason code
               (SELECT id_reason_code
                  FROM (SELECT id_external_request, id_reason_code
                          FROM p1_tracking
                         WHERE ext_req_status IN ('C', 'X', 'D', 'B')
                           AND flg_type = 'S'
                         ORDER BY dt_tracking_tstz DESC) t
                 WHERE t.id_external_request = exr.id_external_request
                   AND rownum = 1) id_reason,
               prof_status.id_professional id_prof_status,
               prof_status.name name_prof_status,
               exr.decision_urg_level,
               -- professional that answerd the referral
               (SELECT id_professional
                  FROM (SELECT id_external_request, id_professional
                          FROM p1_tracking
                         WHERE flg_type = 'S'
                           AND ext_req_status = 'W'
                         ORDER BY dt_tracking_tstz DESC) t1
                 WHERE t1.id_external_request = exr.id_external_request
                   AND rownum = 1) id_prof_answer,
               s_p_outp.id_professional id_prof_sch
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
          JOIN professional prof_status
            ON (prof_status.id_professional = exr.id_prof_status)
          LEFT JOIN schedule s
            ON (exr.id_schedule = s.id_schedule AND s.flg_status = 'A')
          LEFT JOIN schedule_outp s_outp
            ON (s_outp.id_schedule = s.id_schedule)
          LEFT JOIN sch_prof_outp s_p_outp
            ON (s_p_outp.id_schedule_outp = s_outp.id_schedule_outp)
          LEFT JOIN ref_orig_data rod
            ON (rod.id_external_request = exr.id_external_request)
          LEFT JOIN professional rod_prof
            ON (rod.id_professional = rod_prof.id_professional)) v
  LEFT JOIN professional prof_answer
    ON (prof_answer.id_professional = v.id_prof_answer)
  LEFT JOIN professional prof_sch
    ON (prof_sch.id_professional = v.id_prof_sch);