CREATE OR REPLACE VIEW V_P1_GRID AS
SELECT /*+ use_nl(exr pat) */
 exr.id_external_request,
 exr.num_req,
 exr.flg_type,
 exr.dt_requested,
 exr.flg_status,
 exr.dt_status dt_status_tstz,
 exr.flg_priority,
 exr.id_speciality,
 nvl2(exr.id_speciality, 'P1_SPECIALITY.CODE_SPECIALITY.' || to_char(exr.id_speciality), null) code_speciality,
 exr.decision_urg_level,
 exr.id_prof_requested,
 exr.id_inst_orig,
 CASE
      WHEN exr.institution_name_roda IS NOT NULL THEN
       NULL -- orig=99998
      ELSE
       i_orig.code_institution
  END code_inst_orig,
  CASE
      WHEN exr.institution_name_roda IS NOT NULL THEN
       NULL -- orig=99998
      ELSE
       i_orig.abbreviation
  END abbrev_inst_orig,
 exr.institution_name_roda,
 exr.id_inst_dest,
 i_dest.code_institution code_inst_dest,
 i_dest.abbreviation inst_dest_abbrev,
 exr.id_dep_clin_serv,
 exr.id_prof_redirected,
 exr.id_schedule,
 exr.id_prof_schedule,
 exr.dt_schedule dt_schedule_tstz,
 exr.dt_efectiv dt_efectiv_tstz,
 pat.id_patient,
 pat.name pat_name,
 pat.gender pat_gender,
 pat.age pat_age,
 pat.dt_birth pat_dt_birth,
 d.abbreviation dep_abbreviation,
 d.code_department,
 nvl2(dcs.id_clinical_service, 'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || to_char(dcs.id_clinical_service), null) code_clinical_service,
 exr.id_match,
 exr.id_prof_status,
 exr.dt_issued,
 exr.id_prof_triage,
 exr.dt_triage,
 exr.dt_forwarded,
 exr.dt_acknowledge,
 exr.dt_new,
 exr.dt_last_interaction_tstz,
 exr.id_workflow,
 NULL tr_dt_update,
 NULL tr_id_prof_dest,
 NULL tr_id_prof_transf_owner,
 NULL tr_id_status,
 NULL tr_id_trans_resp,
 NULL tr_id_workflow,
 exr.id_prof_orig,
 exr.id_external_sys,
 exr.id_prof_sch_sugg,
 exr.flg_migrated,
 exr.nr_clinical_doc,
 exr.flg_received,
 exr.flg_sent_by,
 exr.nr_clin_comments,
 exr.dt_clin_last_comment,
 exr.id_prof_clin_comment,
 exr.id_inst_clin_comment,
 exr.nr_adm_comments,
 exr.dt_adm_last_comment,
 exr.id_prof_adm_comment,
 exr.id_inst_adm_comment
  FROM patient pat
  JOIN referral_ea exr
    ON (pat.id_patient = exr.id_patient)
  JOIN institution i_orig
    ON (exr.id_inst_orig = i_orig.id_institution)
  LEFT JOIN institution i_dest
    ON (exr.id_inst_dest = i_dest.id_institution)
  LEFT JOIN dep_clin_serv dcs
    ON (exr.id_dep_clin_serv = dcs.id_dep_clin_serv)
  LEFT JOIN department d
    ON (dcs.id_department = d.id_department);