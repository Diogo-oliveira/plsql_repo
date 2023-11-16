set feedback off
set termout off
set echo off
set heading off
set verify off
set pau off
set trims         on
set lines 1000
set long 10000
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SEGMENT_ATTRIBUTES', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'STORAGE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'TABLESPACE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'PRETTY', true)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'CONSTRAINTS_AS_ALTER'', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SQLTERMINATOR', true)
col text format A1000 word wrap

spool 'c:\mighdc\alert\sequences\seq_prof_soft_inst.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_SOFT_INST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_soft_inst_services.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOFT_INST_SERVICES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_preferences.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_PREFERENCES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_access.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_ACCESS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_composition.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_COMPOSITION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_relationship.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_RELATIONSHIP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_predefined_action.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_PREDEFINED_ACTION','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_folder.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_FOLDER','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_compo_folder.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_COMPO_FOLDER','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_compo_inst.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_COMPO_INST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_icnp_composition_term.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_COMPOSITION_TERM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sample_text_freq.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SAMPLE_TEXT_FREQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_wl_msg_queue.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WL_MSG_QUEUE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_transp_ent_inst.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TRANSP_ENT_INST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_institution.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_INSTITUTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_material_protocols.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MATERIAL_PROTOCOLS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_room.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ROOM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_room_dep_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ROOM_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_department.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DEPARTMENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_speciality.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SPECIALITY','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_scholarship.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCHOLARSHIP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_dep_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_cat.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_CAT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_dependency.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DEPENDENCY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_institution.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INSTITUTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_doc.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_DOC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_country.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_COUNTRY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_clinical_service.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CLINICAL_SERVICE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_institution.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_INSTITUTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_material.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MATERIAL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_diagnosis.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIAGNOSIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_episode.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPISODE','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_pat_problem.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_PROBLEM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_external_cause.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXTERNAL_CAUSE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_bed.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_BED','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_origin.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ORIGIN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_diagnosis.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_DIAGNOSIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_task.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_TASK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_epis_readmission.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_READMISSION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_prob_visit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_PROB_VISIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_visit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VISIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_info.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_INFO','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_schedule_alter.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCHEDULE_ALTER','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_slot.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SLOT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_schedule.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCHEDULE','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_serv_sched_access.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SERV_SCHED_ACCESS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_time_event_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TIME_EVENT_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_clin_record.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CLIN_RECORD','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sys_time_event_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_TIME_EVENT_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_axis.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_AXIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_wound_treatment.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WOUND_TREATMENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_wound_evaluation.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WOUND_EVALUATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_epis_interv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_EPIS_INTERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_interv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_INTERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_pregn_fetus_det.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_PREGN_FETUS_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_pregn_fetus.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_PREGN_FETUS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_pregn_fetus_biom.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_PREGN_FETUS_BIOM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_monitorization_vs.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MONITORIZATION_VS','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_harvest.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_HARVEST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_system_apparati.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYSTEM_APPARATI','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_spec_sys_appar.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SPEC_SYS_APPAR','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_intervention.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INTERVENTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_cli_rec_req_mov.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CLI_REC_REQ_MOV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vaccine_presc_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VACCINE_PRESC_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_pat_fam_soc_hist.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_FAM_SOC_HIST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_agp.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_AGP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_interv_presc_det.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INTERV_PRESC_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_barcode_h.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_BARCODE_H','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_barcode_e.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_BARCODE_E','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_req_supply.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_REQ_SUPPLY','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_drug_req.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_REQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_req_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_REQ_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_cli_rec_req_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CLI_REC_REQ_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_monitorization.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MONITORIZATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_wound_eval_charac.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WOUND_EVAL_CHARAC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_nurse_activity_req.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_NURSE_ACTIVITY_REQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_nurse_actv_req_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_NURSE_ACTV_REQ_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_nurse_discharge.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_NURSE_DISCHARGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam_req_ext_sys.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_REQ_EXT_SYS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam_ext_sys.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_EXT_SYS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_problem_hist.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_PROBLEM_HIST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam_egp.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_EGP','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_pat_allergy_hist.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_ALLERGY_HIST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_photo.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_PHOTO','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sample_text_prof.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SAMPLE_TEXT_PROF','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_consult_req_prof.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CONSULT_REQ_PROF','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_consult_req.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CONSULT_REQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_func.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_FUNC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_external_request.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXTERNAL_REQUEST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_opinion_prof.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_OPINION_PROF','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_profile_template.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_PROFILE_TEMPLATE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_access_field_func.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_ACCESS_FIELD_FUNC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_profile_template.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROFILE_TEMPLATE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_room.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_ROOM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_wl_prof_room.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WL_PROF_ROOM','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_category.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CATEGORY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_error.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_ERROR','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_session.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_SESSION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sys_request.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_REQUEST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_mach.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_MACH','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_ext_sys.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_EXT_SYS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_external_sys.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXTERNAL_SYS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_ext_sys.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_EXT_SYS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_wl_waiting_room.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WL_WAITING_ROOM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_clin_serv_ext_sys.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CLIN_SERV_EXT_SYS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_wl_machine.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WL_MACHINE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_epis_interv_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_EPIS_INTERV_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_service_dcs.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_SERVICE_DCS','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_sch_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_grid_task.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_GRID_TASK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_btn_sbg.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_BTN_SBG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sch_prof_outp.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_PROF_OUTP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_schedule_outp.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCHEDULE_OUTP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_calendar.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_CALENDAR','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sch_appointement.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_APPOINTEMENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_service.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_SERVICE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_involvement.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_INVOLVEMENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_resource.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_RESOURCE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_schedule.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_SCHEDULE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_patient.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PATIENT','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_wl_demo.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WL_DEMO','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_soft_inst_impl.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOFT_INST_IMPL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_cli_rec_req.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CLI_REC_REQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_time_unit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TIME_UNIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_event.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EVENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_health_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_HEALTH_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_pat_permission.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_PERMISSION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_med_decl.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_MED_DECL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_health_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_HEALTH_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_job.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_JOB','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_medication.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_MEDICATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_home.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_HOME','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vaccine.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VACCINE','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_pat_family.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_FAMILY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_notes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_vaccine.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_VACCINE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_pat_allergy.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_ALLERGY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_family_disease.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_FAMILY_DISEASE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_photo.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_PHOTO','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_pat_habit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_HABIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_baixa.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_BAIXA','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_family_prof.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_FAMILY_PROF','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_necessity.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_NECESSITY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_cli_attributes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_CLI_ATTRIBUTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_family_member.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_FAMILY_MEMBER','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_doc.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_DOC','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_pat_soc_attributes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_SOC_ATTRIBUTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_necessity.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_NECESSITY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_interv_prescription.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INTERV_PRESCRIPTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_drug_dep_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_body_part.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_BODY_PART','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_brand.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_BRAND','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_drug_route.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_ROUTE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_prescription.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_PRESCRIPTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vaccine_prescription.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VACCINE_PRESCRIPTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_pharma_class.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_PHARMA_CLASS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vaccine_presc_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VACCINE_PRESC_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prep_message.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PREP_MESSAGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_presc_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_PRESC_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_drug_form.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_FORM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_interv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_INTERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_adverse_interv_allergy.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ADVERSE_INTERV_ALLERGY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_interv_drug.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INTERV_DRUG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_drug.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_DRUG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_take_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_TAKE_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_drug_pharma.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_PHARMA','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_in_out.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_IN_OUT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_pharma_interaction.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_PHARMA_INTERACTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_interv_prep_msg.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INTERV_PREP_MSG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_interv_presc_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INTERV_PRESC_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_take_time.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_TAKE_TIME','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_prep_mesg.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_PREP_MESG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_hemo_req_supply.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_HEMO_REQ_SUPPLY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_urgency_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_URGENCY_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_pat_blood_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_BLOOD_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_barcode_p.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_BARCODE_P','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_comp_dcs.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_COMP_DCS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_icnp_term.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_TERM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_classification.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_CLASSIFICATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_param_analysis_ext_sys.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PARAM_ANALYSIS_EXT_SYS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_interv_ext_sys.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INTERV_EXT_SYS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_ext_sys.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_EXT_SYS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_interface_exchange.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INTERFACE_EXCHANGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_wl_topics.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WL_TOPICS','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_clin_srv_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CLIN_SRV_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_p1_prblm_rec_procedure.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_P1_PRBLM_REC_PROCEDURE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_p1_doc_external.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_P1_DOC_EXTERNAL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_p1_documents_done.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_P1_DOCUMENTS_DONE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_p1_ext_req_tracking.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_P1_EXT_REQ_TRACKING','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_p1_problem.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_P1_PROBLEM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_p1_problem_dep_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_P1_PROBLEM_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_dep_clin_serv_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DEP_CLIN_SERV_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_p1_documents.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_P1_DOCUMENTS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_p1_external_request.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_P1_EXTERNAL_REQUEST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_p1_recomended_procedure.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_P1_RECOMENDED_PROCEDURE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_p1_doc_external_request.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_P1_DOC_EXTERNAL_REQUEST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_p1_history.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_P1_HISTORY','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_institution_tree.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INSTITUTION_TREE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_dep_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analy_parm_limit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALY_PARM_LIMIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_nurse_tea_req.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_NURSE_TEA_REQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_epis_diag_interv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_EPIS_DIAG_INTERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_epis_diagnosis.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_EPIS_DIAGNOSIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_icnp_epis_intervention.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_EPIS_INTERVENTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_transition_state.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_TRANSITION_STATE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_monitorization_vs_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MONITORIZATION_VS_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_presc_det.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_PRESC_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_schedule_sr.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCHEDULE_SR','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_hemo_req_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_HEMO_REQ_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_hemo_req.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_HEMO_REQ','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_wl_call_queue.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WL_CALL_QUEUE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_functionality.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_FUNCTIONALITY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_wl_waiting_line.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WL_WAITING_LINE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_wl_mach_prof_queue.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WL_MACH_PROF_QUEUE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_wl_status.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WL_STATUS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_wl_queue.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WL_QUEUE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_profile_templ_acc_func.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROFILE_TEMPL_ACC_FUNC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_field.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_FIELD','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_req.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_REQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sample_recipient.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SAMPLE_RECIPIENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_result_par.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_RESULT_PAR','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_req_par.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_REQ_PAR','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_movement.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MOVEMENT','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_sample_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SAMPLE_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_graffar_criteria.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_GRAFFAR_CRITERIA','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_social_episode.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOCIAL_EPISODE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_family_monetary.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_FAMILY_MONETARY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_dietary_drug.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIETARY_DRUG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_ingredient.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INGREDIENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_manipulated_ingredient.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MANIPULATED_INGREDIENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_manipulated.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MANIPULATED','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_manipulated_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MANIPULATED_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_medication_hist_list.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_MEDICATION_HIST_LIST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_medication_list.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_MEDICATION_LIST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prescription_print.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESCRIPTION_PRINT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_origin_soft.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ORIGIN_SOFT','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_presc_pat_problem.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESC_PAT_PROBLEM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_presc_attention_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESC_ATTENTION_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prescription_xml_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESCRIPTION_XML_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_prescription_xml.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESCRIPTION_XML','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prescription_type_access.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESCRIPTION_TYPE_ACCESS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prescription_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESCRIPTION_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_prescription_pharm_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESCRIPTION_PHARM_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prescription_pharm.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESCRIPTION_PHARM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prescription.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESCRIPTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_emb_dep_clin_serv.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EMB_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_contra_indic.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CONTRA_INDIC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_diagram_detail_notes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIAGRAM_DETAIL_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_diagram_detail.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIAGRAM_DETAIL','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_diagram.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIAGRAM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_diagram_tools.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIAGRAM_TOOLS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_diagram_tools_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIAGRAM_TOOLS_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_diagram_lay_imag.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIAGRAM_LAY_IMAG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_diagram_image.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIAGRAM_IMAGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_diagram_layout.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIAGRAM_LAYOUT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_unit_measure.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_UNIT_MEASURE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_unit_measure_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_UNIT_MEASURE_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_geo_location.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_GEO_LOCATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_unit_mea_soft_inst.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_UNIT_MEA_SOFT_INST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_health_plan_instit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_HEALTH_PLAN_INSTIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_ine_location.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INE_LOCATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_viewer_synch_param.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VIEWER_SYNCH_PARAM','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_parameter_analysis.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PARAMETER_ANALYSIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_interv_dep_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INTERV_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam_room.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_ROOM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_exam_dep_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_dep_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_analysis_room.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_ROOM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_param.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_PARAM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_viewer_synchronize.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VIEWER_SYNCHRONIZE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_log.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_LOG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_schedule_request.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_SCHEDULE_REQUEST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_permission.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_PERMISSION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_cancel_reason.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_CANCEL_REASON','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_sch_action.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_ACTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_consult_vacancy.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_CONSULT_VACANCY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_grid_task_between.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_GRID_TASK_BETWEEN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_presc_pharm_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESC_PHARM_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_ext_sys.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_EXT_SYS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_professional.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROFESSIONAL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_analysis_req_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_REQ_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_result.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_RESULT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_harvest.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_HARVEST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_analysis.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_ANALYSIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam_drug.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_DRUG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_adverse_exam_allergy.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ADVERSE_EXAM_ALLERGY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam_prep_mesg.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_PREP_MESG','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_exam_result.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_RESULT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam_req_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_REQ_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam_req.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_REQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_prof_exam.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_EXAM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_drug_usage.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_DRUG_USAGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_estate.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ESTATE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_vital_sign_desc.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VITAL_SIGN_DESC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_bp_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_BP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_anamnesis.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_ANAMNESIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vital_sign_notes.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VITAL_SIGN_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_dimension.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIMENSION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_floors.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_FLOORS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_floors_department.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_FLOORS_DEPARTMENT','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_floors_dep_position.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_FLOORS_DEP_POSITION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_floors_institution.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_FLOORS_INSTITUTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_room_dep_position.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ROOM_DEP_POSITION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_triage_units.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TRIAGE_UNITS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_action_criteria.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ACTION_CRITERIA','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_team.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_TEAM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_prof_team_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_TEAM_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_protocols.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_PROTOCOLS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_protocols.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_PROTOCOLS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_protocols.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_PROTOCOLS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_equip_protocols.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EQUIP_PROTOCOLS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam_protocols.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_PROTOCOLS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_hemo_protocols.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_HEMO_PROTOCOLS','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_interv_protocols.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_INTERV_PROTOCOLS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_protocols.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROTOCOLS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_protoc_diag.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROTOC_DIAG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_time.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TIME','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_complaint.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_COMPLAINT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_documentation.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOCUMENTATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_documentation_rel.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOCUMENTATION_REL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_documentation_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOCUMENTATION_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_document_area.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOCUMENT_AREA','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_document_type.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOCUMENT_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_action_criteria.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_ACTION_CRITERIA','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_area.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_AREA','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_component.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_COMPONENT','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_doc_criteria.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_CRITERIA','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_dimension.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_DIMENSION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_element_qualif.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_ELEMENT_QUALIF','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_doc_element_quantif.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_ELEMENT_QUANTIF','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_external.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_EXTERNAL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_image.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_IMAGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_doc_qualification.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_QUALIFICATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_quantification.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_QUANTIFICATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_template.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_TEMPLATE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_template_diagnosis.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_TEMPLATE_DIAGNOSIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_type_soft.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_TYPE_SOFT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_bartchart.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_BARTCHART','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_epis_bartchart_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_BARTCHART_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_complaint.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_COMPLAINT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_documentation.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_DOCUMENTATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_epis_documentation_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_DOCUMENTATION_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_triage.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_TRIAGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_identification_notes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_IDENTIFICATION_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sys_element.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_ELEMENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_element_crit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_ELEMENT_CRIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_triage.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TRIAGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_triage_color.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TRIAGE_COLOR','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_triage_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TRIAGE_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_base_diag.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_BASE_DIAG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_cancel_reason.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_CANCEL_REASON','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_sr_chklist.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_CHKLIST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_chklist_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_CHKLIST_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_chklist_manual.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_CHKLIST_MANUAL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sr_epis_interv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_EPIS_INTERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_epis_interv_desc.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_EPIS_INTERV_DESC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_equip_kit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_EQUIP_KIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sr_equip_period.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_EQUIP_PERIOD','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_evaluation.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_EVALUATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_eval_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_EVAL_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_eval_notes.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_EVAL_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_eval_rule.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_EVAL_RULE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_eval_visit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_EVAL_VISIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_interv_dep_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_INTERV_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_sr_interv_desc.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_INTERV_DESC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_interv_group_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_INTERV_GROUP_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_nurse_rec.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_NURSE_REC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sr_pat_status.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_PAT_STATUS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_intervention.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_INTERVENTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vaccine_desc.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VACCINE_DESC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_vaccine_status.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VACCINE_STATUS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_unit_measure.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_UNIT_MEASURE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_desc.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_DESC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_event_most_freq.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EVENT_MOST_FREQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_pregnancy.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_PREGNANCY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vaccine_dose_admin.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VACCINE_DOSE_ADMIN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vaccine_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VACCINE_DET','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_vaccine_dose.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VACCINE_DOSE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_time_group_soft_inst.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TIME_GROUP_SOFT_INST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_time_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TIME_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_time_event_read.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TIME_EVENT_READ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_event_group_soft_inst.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EVENT_GROUP_SOFT_INST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_event_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EVENT_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_hcn_def_crit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_HCN_DEF_CRIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_drip.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_DRIP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_bolus.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_BOLUS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_element_rel.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_ELEMENT_REL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_element_crit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_ELEMENT_CRIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_element.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_ELEMENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_dmgr_hist.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_DMGR_HIST','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_rep_section_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_REP_SECTION_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_diagnosis_notes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_DIAGNOSIS_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_rep_profile_template_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_REP_PROFILE_TEMPLATE_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_drug_pharma_class_link.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_PHARMA_CLASS_LINK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_param_instit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_PARAM_INSTIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_param_instit_samp.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_PARAM_INSTIT_SAMP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_analysis_alias.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_ALIAS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_result_status.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_RESULT_STATUS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_abnormality_nature.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ABNORMALITY_NATURE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_abnormality.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ABNORMALITY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_parameter.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_PARAMETER','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_instit_soft.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_INSTIT_SOFT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_presc_xml_0102.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESC_XML_0102','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_presc_number_0102.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESC_NUMBER_0102','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_loinc_template.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_LOINC_TEMPLATE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_analysis_loinc.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ANALYSIS_LOINC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sys_btn_crit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_BTN_CRIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_message.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_MESSAGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_prof_resp.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_PROF_RESP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_epis_report.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_REPORT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_report_section.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_REPORT_SECTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_match_epis.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MATCH_EPIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_prof_rec.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_PROF_REC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_history_hist.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_HISTORY_HIST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_history.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_HISTORY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_building.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_BUILDING','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_epis_review_systems.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_REVIEW_SYSTEMS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_history_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_HISTORY_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sample_text.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SAMPLE_TEXT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sys_entrance.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_ENTRANCE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_postal_code_pt.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_POSTAL_CODE_PT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_doc_original.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DOC_ORIGINAL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_mcdt_req_diagnosis.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MCDT_REQ_DIAGNOSIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_screen_template.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCREEN_TEMPLATE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_district.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISTRICT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_allergy_ext_sys.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ALLERGY_EXT_SYS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_login.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_LOGIN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_discharge_notes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISCHARGE_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sample_text_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SAMPLE_TEXT_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_sample_text_type_cat.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SAMPLE_TEXT_TYPE_CAT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_alert_profile.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_ALERT_PROFILE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_allergy.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ALLERGY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_software_institution.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOFTWARE_INSTITUTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_presc_xml_0124.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESC_XML_0124','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_presc_xml_0083.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESC_XML_0083','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_presc_number_0124.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESC_NUMBER_0124','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_presc_number_0083.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PRESC_NUMBER_0083','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_hidrics_det.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_HIDRICS_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_hidrics_balance.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_HIDRICS_BALANCE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_hidrics.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_HIDRICS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_allocation_bed.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ALLOCATION_BED','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_epis_positioning_plan.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_POSITIONING_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_positioning_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_POSITIONING_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_positioning.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_POSITIONING','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_epis_diet.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_DIET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_complete_history.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_COMPLETE_HISTORY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_positioning.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_POSITIONING','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_viewer_refresh.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VIEWER_REFRESH','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_translation.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TRANSLATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_compo_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_COMPO_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_icnp_compo_dcs.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ICNP_COMPO_DCS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_alert_prof.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_ALERT_PROF','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prev_episodes_temp.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PREV_EPISODES_TEMP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_profile_templ_access.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROFILE_TEMPL_ACCESS','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_epis_interval_notes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_INTERVAL_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_software_dept.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOFTWARE_DEPT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_schedule_sr_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCHEDULE_SR_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_mdm_prof_coding.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MDM_PROF_CODING','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_critical_care_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CRITICAL_CARE_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_critical_care_read.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CRITICAL_CARE_READ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_records_review_read.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_RECORDS_REVIEW_READ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_attending_notes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_ATTENDING_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_treatment_management.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TREATMENT_MANAGEMENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_tests_review.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TESTS_REVIEW','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vs_soft_inst.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VS_SOFT_INST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vital_sign_unit_measure.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VITAL_SIGN_UNIT_MEASURE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_config.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_CONFIG','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_epis_diagnosis_hist.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_DIAGNOSIS_HIST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_pat_status_notes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_PAT_STATUS_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_pat_status_period.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_PAT_STATUS_PERIOD','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sr_posit_req.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_POSIT_REQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_pos_eval_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_POS_EVAL_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_pos_eval_visit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_POS_EVAL_VISIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sr_pre_anest.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_PRE_ANEST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_pre_anest_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_PRE_ANEST_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_pre_eval.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_PRE_EVAL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_pre_eval_det.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_PRE_EVAL_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_pre_eval_notes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_PRE_EVAL_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_pre_eval_visit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_PRE_EVAL_VISIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_prof_team_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_PROF_TEAM_DET','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_sr_receive.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_RECEIVE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_receive_manual.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_RECEIVE_MANUAL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_receive_proc.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_RECEIVE_PROC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sr_receive_proc_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_RECEIVE_PROC_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_receive_proc_notes.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_RECEIVE_PROC_NOTES','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_reserv_req.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_RESERV_REQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_sr_room_status.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_ROOM_STATUS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_schedule.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_SCHEDULE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_surgery_record.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_SURGERY_RECORD','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_surgery_rec_det.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_SURGERY_REC_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_surgery_time.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_SURGERY_TIME','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sr_surgery_time_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SR_SURGERY_TIME_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_log.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_LOG','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_error.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ERROR','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_discharge_detail.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISCHARGE_DETAIL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_family_relationship_relat.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_FAMILY_RELATIONSHIP_RELAT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_exam_cat.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_CAT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_exam_cat_dcs.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EXAM_CAT_DCS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_drug_despachos_soft_inst.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_DESPACHOS_SOFT_INST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_drug_despachos.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DRUG_DESPACHOS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sys_alert_software.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SYS_ALERT_SOFTWARE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_soft_lang.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOFT_LANG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_cancel_reason_inst.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_CANCEL_REASON_INST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_event_dcs.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_EVENT_DCS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_sch_event.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCH_EVENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_graffar_crit_value.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_GRAFFAR_CRIT_VALUE','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_pat_graffar_crit.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_GRAFFAR_CRIT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_social_epis_interv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOCIAL_EPIS_INTERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_social_epis_solution.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOCIAL_EPIS_SOLUTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_social_intervention.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOCIAL_INTERVENTION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_social_diagnosis.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOCIAL_DIAGNOSIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_social_epis_discharge.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOCIAL_EPIS_DISCHARGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_social_epis_diag.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOCIAL_EPIS_DIAG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_social_class.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOCIAL_CLASS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_social_epis_situation.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOCIAL_EPIS_SITUATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_social_epis_request.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SOCIAL_EPIS_REQUEST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_opinion.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_OPINION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_diagnosis_dep_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DIAGNOSIS_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_periodic_exam_educ.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PERIODIC_EXAM_EDUC','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_vital_sign_read.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VITAL_SIGN_READ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_body_painting.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_BODY_PAINTING','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_obs_exam.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_OBS_EXAM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_epis_obs_photo.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_OBS_PHOTO','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_body_part_image.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_BODY_PART_IMAGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_photo.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_PHOTO','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_epis_observation.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_OBSERVATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_diagnosis.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_DIAGNOSIS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_body_painting_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_BODY_PAINTING_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_health_plan.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_HEALTH_PLAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vs_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VS_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_problem.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_PROBLEM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_vital_sign.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VITAL_SIGN','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_matr_scheduled.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MATR_SCHEDULED','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_room_scheduled.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_ROOM_SCHEDULED','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_prof_scheduled.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PROF_SCHEDULED','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_pat_child_clin_rec.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_CHILD_CLIN_REC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_school.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_SCHOOL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_child_feed_dev.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_CHILD_FEED_DEV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_child_feed_dev.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CHILD_FEED_DEV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_board_grouping.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_BOARD_GROUPING','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_white_reason.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_WHITE_REASON','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_discriminator_help.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISCRIMINATOR_HELP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_disc_help.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISC_HELP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_discriminator.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISCRIMINATOR','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_color.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_COLOR','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_vital_sign_relation.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_VITAL_SIGN_RELATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_manchester.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MANCHESTER','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_board_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_BOARD_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_disc_vs_valid.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISC_VS_VALID','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_board.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_BOARD','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_man.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_MAN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_matr_dep_clin_serv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MATR_DEP_CLIN_SERV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_matr_room.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MATR_ROOM','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_material_req_det.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MATERIAL_REQ_DET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_material_req.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MATERIAL_REQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_material_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_MATERIAL_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_ginec.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_GINEC','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_pregnancy_risk.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_PREGNANCY_RISK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_pat_pregnancy.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_PREGNANCY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_contraceptive.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_CONTRACEPTIVE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pregnancy_risk_eval.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PREGNANCY_RISK_EVAL','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_pat_pregn_measure.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_PREGN_MEASURE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_cntrceptiv.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_CNTRCEPTIV','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_pat_ginec_obstet.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_GINEC_OBSTET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_pat_delivery.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_PAT_DELIVERY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_ginec_obstet.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_GINEC_OBSTET','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_transportation.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TRANSPORTATION','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_disch_reas_dest.seq'

select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISCH_REAS_DEST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_transp_req_group.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TRANSP_REQ_GROUP','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_transp_req.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TRANSP_REQ','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_transport_type.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TRANSPORT_TYPE','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\sequences\seq_disch_prep_mesg.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISCH_PREP_MESG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_epis_recomend.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_EPIS_RECOMEND','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_discharge.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISCHARGE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\seq_transp_entity.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_TRANSP_ENTITY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_discharge_dest.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISCHARGE_DEST','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\sequences\seq_discharge_reason.seq'
select replace(replace(dbms_metadata.get_ddl('SEQUENCE','SEQ_DISCHARGE_REASON','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\sequences\execute_sequences.sql'
select '@@' || lower(object_name) || '.seq' from all_objects where owner = 'ALERT' and object_type = 'SEQUENCE';
spool off

