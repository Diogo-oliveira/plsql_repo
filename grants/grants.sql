set feedback off
set termout off
set echo off
set heading off
set verify off
set pau off
set lines 1000
set long 10000
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SEGMENT_ATTRIBUTES', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'STORAGE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'TABLESPACE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'PRETTY', true)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'CONSTRAINTS_AS_ALTER', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SQLTERMINATOR', true)
col text format A1000 word wrap

spool 'c:\mighdc\alert\grants\sequence_seq_presc_number_0083.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_NUMBER_0083','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_NUMBER_0083';
spool off

spool 'c:\mighdc\alert\grants\type_table_varchar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TABLE_VARCHAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TABLE_VARCHAR';
spool off

spool 'c:\mighdc\alert\grants\type_profissional.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFISSIONAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFISSIONAL';
spool off

spool 'c:\mighdc\alert\grants\table_analysis.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_dep_clin_serv_old.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_DEP_CLIN_SERV_OLD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_DEP_CLIN_SERV_OLD';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_DESC';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_GROUP';

spool off

spool 'c:\mighdc\alert\grants\table_analysis_harvest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_HARVEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_HARVEST';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_loinc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_LOINC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_LOINC';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PROTOCOLS';
spool off


spool 'c:\mighdc\alert\grants\table_analysis_unit_measure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_UNIT_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_UNIT_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\table_body_part_image.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BODY_PART_IMAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BODY_PART_IMAGE';
spool off

spool 'c:\mighdc\alert\grants\table_bp_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_dep_clin_serv_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEP_CLIN_SERV_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEP_CLIN_SERV_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_dimension.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIMENSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIMENSION';
spool off

spool 'c:\mighdc\alert\grants\table_discriminator.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCRIMINATOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCRIMINATOR';
spool off

spool 'c:\mighdc\alert\grants\table_documentation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION';
spool off

spool 'c:\mighdc\alert\grants\table_documentation_rel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION_REL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION_REL';
spool off

spool 'c:\mighdc\alert\grants\table_drug_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_drug_presc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESC_DET';

spool off

spool 'c:\mighdc\alert\grants\table_drug_req_supply.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ_SUPPLY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ_SUPPLY';
spool off

spool 'c:\mighdc\alert\grants\table_emb_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EMB_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EMB_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_epis_body_painting.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BODY_PAINTING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BODY_PAINTING';
spool off


spool 'c:\mighdc\alert\grants\table_epis_hidrics_balance.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_HIDRICS_BALANCE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_HIDRICS_BALANCE';
spool off

spool 'c:\mighdc\alert\grants\table_episode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPISODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPISODE';
spool off

spool 'c:\mighdc\alert\grants\table_epis_prof_rec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROF_REC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROF_REC';
spool off


spool 'c:\mighdc\alert\grants\table_epis_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TASK';
spool off

spool 'c:\mighdc\alert\grants\table_epis_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_exam_cat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_CAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_CAT';
spool off

spool 'c:\mighdc\alert\grants\table_floors_department.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS_DEPARTMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS_DEPARTMENT';
spool off

spool 'c:\mighdc\alert\grants\table_floors_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\table_hemo_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_compo_dcs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_DCS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_DCS';

spool off

spool 'c:\mighdc\alert\grants\table_icnp_composition_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPOSITION_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPOSITION_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_folder.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_FOLDER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_FOLDER';
spool off


spool 'c:\mighdc\alert\grants\table_import_mcdt.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_MCDT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_MCDT';
spool off

spool 'c:\mighdc\alert\grants\table_inf_cft_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_CFT_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_CFT_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_inf_class_disp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_CLASS_DISP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_CLASS_DISP';
spool off


spool 'c:\mighdc\alert\grants\table_inf_comerc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_COMERC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_COMERC';
spool off

spool 'c:\mighdc\alert\grants\table_inf_emb.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_EMB','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_EMB';
spool off

spool 'c:\mighdc\alert\grants\table_inf_patol_esp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_PATOL_ESP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_PATOL_ESP';
spool off

spool 'c:\mighdc\alert\grants\table_inf_subst_lnk.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_SUBST_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_SUBST_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_inf_tipo_prod.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_TIPO_PROD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_TIPO_PROD';
spool off

spool 'c:\mighdc\alert\grants\table_inf_vias_admin_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_VIAS_ADMIN_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_VIAS_ADMIN_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_ingredient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INGREDIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INGREDIENT';

spool off

spool 'c:\mighdc\alert\grants\table_inp_log.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INP_LOG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INP_LOG';
spool off

spool 'c:\mighdc\alert\grants\table_interv_prep_msg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PREP_MSG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PREP_MSG';
spool off

spool 'c:\mighdc\alert\grants\table_material_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_REQ';
spool off


spool 'c:\mighdc\alert\grants\table_pat_cli_attributes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CLI_ATTRIBUTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CLI_ATTRIBUTES';
spool off

spool 'c:\mighdc\alert\grants\table_pat_family.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY';
spool off

spool 'c:\mighdc\alert\grants\table_pat_ginec_obstet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_GINEC_OBSTET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_GINEC_OBSTET';
spool off


spool 'c:\mighdc\alert\grants\table_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\table_prev_episodes_temp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PREV_EPISODES_TEMP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PREV_EPISODES_TEMP';
spool off

spool 'c:\mighdc\alert\grants\table_p1_documents.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOCUMENTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOCUMENTS';
spool off

spool 'c:\mighdc\alert\grants\table_p1_external_request.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_EXTERNAL_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_EXTERNAL_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\table_reports_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REPORTS_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REPORTS_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_rep_profile_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_PROFILE_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_PROFILE_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_room_dep_position.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_DEP_POSITION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_DEP_POSITION';

spool off

spool 'c:\mighdc\alert\grants\table_sample_text_type_cat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_TYPE_CAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_TYPE_CAT';
spool off

spool 'c:\mighdc\alert\grants\table_sch_cancel_reason_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_CANCEL_REASON_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_CANCEL_REASON_INST';
spool off

spool 'c:\mighdc\alert\grants\table_sch_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_GROUP';
spool off


spool 'c:\mighdc\alert\grants\table_scholarship.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHOLARSHIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHOLARSHIP';
spool off

spool 'c:\mighdc\alert\grants\table_school.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHOOL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHOOL';
spool off

spool 'c:\mighdc\alert\grants\table_sch_permission_temp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_PERMISSION_TEMP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_PERMISSION_TEMP';
spool off


spool 'c:\mighdc\alert\grants\table_sch_service_dcs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_SERVICE_DCS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_SERVICE_DCS';
spool off

spool 'c:\mighdc\alert\grants\table_snomed_relationships.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_RELATIONSHIPS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_RELATIONSHIPS';
spool off

spool 'c:\mighdc\alert\grants\table_social_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_soft_inst_impl.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFT_INST_IMPL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFT_INST_IMPL';
spool off

spool 'c:\mighdc\alert\grants\table_software_dept.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFTWARE_DEPT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFTWARE_DEPT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_cancel_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CANCEL_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CANCEL_REASON';
spool off

spool 'c:\mighdc\alert\grants\table_sr_equip.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EQUIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EQUIP';

spool off

spool 'c:\mighdc\alert\grants\table_sr_pat_status_period.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PAT_STATUS_PERIOD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PAT_STATUS_PERIOD';
spool off

spool 'c:\mighdc\alert\grants\table_sr_pre_anest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_ANEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_ANEST';
spool off

spool 'c:\mighdc\alert\grants\table_sr_prof_recov_schd.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PROF_RECOV_SCHD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PROF_RECOV_SCHD';
spool off


spool 'c:\mighdc\alert\grants\table_sr_surg_prot_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sys_appar_organ.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_APPAR_ORGAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_APPAR_ORGAN';
spool off

spool 'c:\mighdc\alert\grants\table_sys_error.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ERROR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ERROR';
spool off


spool 'c:\mighdc\alert\grants\table_sys_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\table_toad_plan_sql.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TOAD_PLAN_SQL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TOAD_PLAN_SQL';
spool off

spool 'c:\mighdc\alert\grants\table_transportation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSPORTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSPORTATION';
spool off

spool 'c:\mighdc\alert\grants\table_transport_type.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSPORT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSPORT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_triage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE';
spool off

spool 'c:\mighdc\alert\grants\table_triage_discriminator.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_DISCRIMINATOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_DISCRIMINATOR';
spool off

spool 'c:\mighdc\alert\grants\table_unit_mea_soft_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','UNIT_MEA_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'UNIT_MEA_SOFT_INST';

spool off

spool 'c:\mighdc\alert\grants\table_vaccine_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_viewer.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VIEWER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VIEWER';
spool off

spool 'c:\mighdc\alert\grants\table_wl_machine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MACHINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MACHINE';
spool off


spool 'c:\mighdc\alert\grants\synonym_matr_scheduled.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_SCHEDULED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_SCHEDULED';
spool off

spool 'c:\mighdc\alert\grants\synonym_material_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\synonym_language.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','LANGUAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'LANGUAGE';
spool off


spool 'c:\mighdc\alert\grants\synonym_icnp_epis_diag_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAG_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAG_INTERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_hemo_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_habit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HABIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HABIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_interv_desc.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERV_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERV_DESC';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_chklist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST';
spool off

spool 'c:\mighdc\alert\grants\synonym_spec_sys_appar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SPEC_SYS_APPAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SPEC_SYS_APPAR';
spool off

spool 'c:\mighdc\alert\grants\synonym_speciality.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SPECIALITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SPECIALITY';

spool off

spool 'c:\mighdc\alert\grants\synonym_snomed_relationships.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_RELATIONSHIPS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_RELATIONSHIPS';
spool off

spool 'c:\mighdc\alert\grants\synonym_scholarship.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHOLARSHIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHOLARSHIP';
spool off

spool 'c:\mighdc\alert\grants\synonym_schedule_sr.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_SR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_SR';
spool off


spool 'c:\mighdc\alert\grants\synonym_schedule_alter.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_ALTER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_ALTER';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_preferences.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PREFERENCES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PREFERENCES';
spool off


spool 'c:\mighdc\alert\grants\synonym_prof_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_vital_sign_read.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_READ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_READ';
spool off

spool 'c:\mighdc\alert\grants\synonym_vital_sign_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_DESC';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_DET';

spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_prof_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PROF_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PROF_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_problem_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROBLEM_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROBLEM_HIST';
spool off


spool 'c:\mighdc\alert\grants\synonym_pat_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROBLEM';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_pregn_measure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_habit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HABIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HABIT';
spool off


spool 'c:\mighdc\alert\grants\synonym_pat_fam_soc_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAM_SOC_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAM_SOC_HIST';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_family_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_PROF';
spool off

spool 'c:\mighdc\alert\grants\synonym_origin.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ORIGIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ORIGIN';
spool off

spool 'c:\mighdc\alert\grants\synonym_opinion.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OPINION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OPINION';
spool off

spool 'c:\mighdc\alert\grants\synonym_nurse_tea_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_TEA_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_TEA_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_nurse_discharge.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PHOTO';

spool off

spool 'c:\mighdc\alert\grants\synonym_epis_info.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INFO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INFO';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_body_painting.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BODY_PAINTING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BODY_PAINTING';
spool off


spool 'c:\mighdc\alert\grants\synonym_drug_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PROTOCOLS';
spool off


spool 'c:\mighdc\alert\grants\synonym_child_feed_dev.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CHILD_FEED_DEV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CHILD_FEED_DEV';
spool off

spool 'c:\mighdc\alert\grants\synonym_cli_rec_req_mov.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ_MOV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ_MOV';
spool off

spool 'c:\mighdc\alert\grants\synonym_cli_rec_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_clin_record.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_RECORD';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_agp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_AGP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_AGP';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_pat_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PAT_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PAT_STATUS';

spool off

spool 'c:\mighdc\alert\grants\synonym_sr_pat_status_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PAT_STATUS_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PAT_STATUS_NOTES';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_pre_anest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_ANEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_ANEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_document_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENT_TYPE';
spool off


spool 'c:\mighdc\alert\grants\synonym_doc_element_qualif.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_QUALIF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_QUALIF';
spool off

spool 'c:\mighdc\alert\grants\synonym_triage_board_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_BOARD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_BOARD_GROUP';
spool off

spool 'c:\mighdc\alert\grants\package_pk_message.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_MESSAGE';
spool off


spool 'c:\mighdc\alert\grants\package_pk_biztalk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BIZTALK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BIZTALK';
spool off

spool 'c:\mighdc\alert\grants\package_pk_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_diet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_DIET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_DIET';
spool off

spool 'c:\mighdc\alert\grants\package_pk_login_message.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_LOGIN_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_LOGIN_MESSAGE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_backoffice.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BACKOFFICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BACKOFFICE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_VISIT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_clinical_record.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_CLINICAL_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_CLINICAL_RECORD';

spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_list.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_LIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_LIST';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_search.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_SEARCH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_SEARCH';
spool off

spool 'c:\mighdc\alert\grants\package_pk_medical_decision.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_MEDICAL_DECISION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_MEDICAL_DECISION';
spool off


spool 'c:\mighdc\alert\grants\package_pk_family.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_FAMILY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_FAMILY';
spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_tv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_TV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_TV';
spool off

spool 'c:\mighdc\alert\grants\package_pk_dmgr_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DMGR_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DMGR_HIST';
spool off


spool 'c:\mighdc\alert\grants\package_pk_diagram_new.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DIAGRAM_NEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DIAGRAM_NEW';
spool off

spool 'c:\mighdc\alert\grants\package_pk_doc_attach.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DOC_ATTACH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DOC_ATTACH';
spool off

spool 'c:\mighdc\alert\grants\package_pk_systracking.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SYSTRACKING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SYSTRACKING';
spool off

spool 'c:\mighdc\alert\grants\package_pk_beye_view.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BEYE_VIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BEYE_VIEW';
spool off

spool 'c:\mighdc\alert\grants\package_pk_hemo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_HEMO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_HEMO';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_clinical_info.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_CLINICAL_INFO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_CLINICAL_INFO';
spool off

spool 'c:\mighdc\alert\grants\package_pk_alert_er.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_ALERT_ER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_ALERT_ER';

spool off

spool 'c:\mighdc\alert\grants\package_pk_wlbackoffice.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLBACKOFFICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLBACKOFFICE';
spool off

spool 'c:\mighdc\alert\grants\sequence_seq_professional.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PROFESSIONAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PROFESSIONAL';
spool off

spool 'c:\mighdc\alert\grants\sequence_seq_presc_xml_0083.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_XML_0083','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_XML_0083';
spool off


spool 'c:\mighdc\alert\grants\synonym_table_number.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TABLE_NUMBER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TABLE_NUMBER';
spool off

spool 'c:\mighdc\alert\grants\table_allergy_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ALLERGY_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ALLERGY_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_analy_parm_limit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALY_PARM_LIMIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALY_PARM_LIMIT';
spool off


spool 'c:\mighdc\alert\grants\table_analysis_alias.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_ALIAS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_ALIAS';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_ext_sys_delete.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_EXT_SYS_DELETE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_EXT_SYS_DELETE';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_param_instit.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PARAM_INSTIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PARAM_INSTIT';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_protocols_old.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PROTOCOLS_OLD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PROTOCOLS_OLD';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\table_bed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BED';

spool off

spool 'c:\mighdc\alert\grants\table_diet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIET';
spool off

spool 'c:\mighdc\alert\grants\table_discharge.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\table_doc_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_CRITERIA';
spool off


spool 'c:\mighdc\alert\grants\table_doc_element_quantif.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_QUANTIF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_QUANTIF';
spool off

spool 'c:\mighdc\alert\grants\table_doc_original.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ORIGINAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ORIGINAL';
spool off

spool 'c:\mighdc\alert\grants\table_doc_qualification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_QUALIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_QUALIFICATION';
spool off


spool 'c:\mighdc\alert\grants\table_doc_template_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TEMPLATE_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TEMPLATE_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_doc_type_soft.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TYPE_SOFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TYPE_SOFT';
spool off

spool 'c:\mighdc\alert\grants\table_document_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_drug_despachos.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_DESPACHOS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_DESPACHOS';
spool off

spool 'c:\mighdc\alert\grants\table_drug_form.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_FORM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_FORM';
spool off

spool 'c:\mighdc\alert\grants\table_drug_instit_justification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_INSTIT_JUSTIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_INSTIT_JUSTIFICATION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_diet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DIET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DIET';

spool off

spool 'c:\mighdc\alert\grants\table_epis_hidrics.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_HIDRICS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_HIDRICS';
spool off

spool 'c:\mighdc\alert\grants\table_epis_info.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INFO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INFO';
spool off

spool 'c:\mighdc\alert\grants\table_epis_prof_resp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROF_RESP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROF_RESP';
spool off


spool 'c:\mighdc\alert\grants\table_epis_readmission.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_READMISSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_READMISSION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_type_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TYPE_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TYPE_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_exam.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM';
spool off


spool 'c:\mighdc\alert\grants\table_exam_cat_dcs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_CAT_DCS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_CAT_DCS';
spool off

spool 'c:\mighdc\alert\grants\table_exam_egp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_EGP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_EGP';
spool off

spool 'c:\mighdc\alert\grants\table_external_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXTERNAL_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXTERNAL_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_compo_clin_serv.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_compo_inst_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_INST_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_INST_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_diag_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAG_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAG_INTERV';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_relationship.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_RELATIONSHIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_RELATIONSHIP';

spool off

spool 'c:\mighdc\alert\grants\table_inf_atc_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_ATC_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_ATC_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_inf_dispo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_DISPO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_DISPO';
spool off

spool 'c:\mighdc\alert\grants\table_inf_estado_aim.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_ESTADO_AIM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_ESTADO_AIM';
spool off


spool 'c:\mighdc\alert\grants\table_inf_tipo_diab_mel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_TIPO_DIAB_MEL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_TIPO_DIAB_MEL';
spool off

spool 'c:\mighdc\alert\grants\table_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\table_interv_ext_sys_delete.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_EXT_SYS_DELETE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_EXT_SYS_DELETE';
spool off


spool 'c:\mighdc\alert\grants\table_lixo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','LIXO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'LIXO';
spool off

spool 'c:\mighdc\alert\grants\table_material_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_monitorization_vs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION_VS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION_VS';
spool off

spool 'c:\mighdc\alert\grants\table_nurse_discharge.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\table_nurse_tea_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_TEA_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_TEA_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_pat_child_feed_dev.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CHILD_FEED_DEV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CHILD_FEED_DEV';
spool off

spool 'c:\mighdc\alert\grants\table_pat_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HEALTH_PLAN';

spool off

spool 'c:\mighdc\alert\grants\table_pat_medication.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MEDICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MEDICATION';
spool off

spool 'c:\mighdc\alert\grants\table_pat_pregnancy_risk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGNANCY_RISK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGNANCY_RISK';
spool off

spool 'c:\mighdc\alert\grants\table_pat_tmp_remota.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_TMP_REMOTA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_TMP_REMOTA';
spool off


spool 'c:\mighdc\alert\grants\table_periodic_exam_educ.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PERIODIC_EXAM_EDUC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PERIODIC_EXAM_EDUC';
spool off

spool 'c:\mighdc\alert\grants\table_pregnancy_risk_eval.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PREGNANCY_RISK_EVAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PREGNANCY_RISK_EVAL';
spool off

spool 'c:\mighdc\alert\grants\table_prep_message.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PREP_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PREP_MESSAGE';
spool off


spool 'c:\mighdc\alert\grants\table_prescription_pharm_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_PHARM_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_PHARM_DET';
spool off

spool 'c:\mighdc\alert\grants\table_prescription_xml.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_XML','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_XML';
spool off

spool 'c:\mighdc\alert\grants\table_prof_access_bck1.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS_BCK1','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS_BCK1';
spool off

spool 'c:\mighdc\alert\grants\table_prof_cat.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_CAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_CAT';
spool off

spool 'c:\mighdc\alert\grants\table_prof_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\table_profile_templ_acc_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPL_ACC_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPL_ACC_FUNC';
spool off

spool 'c:\mighdc\alert\grants\table_prof_photo_medicomni.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PHOTO_MEDICOMNI','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PHOTO_MEDICOMNI';

spool off

spool 'c:\mighdc\alert\grants\table_quest_sl_temp_explain1.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','QUEST_SL_TEMP_EXPLAIN1','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'QUEST_SL_TEMP_EXPLAIN1';
spool off

spool 'c:\mighdc\alert\grants\table_rb_sys_button_prop2.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RB_SYS_BUTTON_PROP2','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RB_SYS_BUTTON_PROP2';
spool off

spool 'c:\mighdc\alert\grants\table_rep_destination.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_DESTINATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_DESTINATION';
spool off


spool 'c:\mighdc\alert\grants\table_sample_recipient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_RECIPIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_RECIPIENT';
spool off

spool 'c:\mighdc\alert\grants\table_scales_doc_value.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCALES_DOC_VALUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCALES_DOC_VALUE';
spool off

spool 'c:\mighdc\alert\grants\table_sch_consult_vacancy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_CONSULT_VACANCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_CONSULT_VACANCY';
spool off


spool 'c:\mighdc\alert\grants\table_sch_service.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_SERVICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_SERVICE';
spool off

spool 'c:\mighdc\alert\grants\table_sr_chklist_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_doc_element_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_DOC_ELEMENT_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_DOC_ELEMENT_CRIT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_interv_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERV_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERV_DESC';
spool off

spool 'c:\mighdc\alert\grants\table_sr_prof_team_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PROF_TEAM_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PROF_TEAM_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_receive_proc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC';

spool off

spool 'c:\mighdc\alert\grants\table_sr_receive_proc_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_sr_reserv_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RESERV_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RESERV_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surg_period.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PERIOD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PERIOD';
spool off


spool 'c:\mighdc\alert\grants\table_sr_surg_prot_task_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_TASK_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_TASK_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sys_btn_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BTN_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BTN_CRIT';
spool off

spool 'c:\mighdc\alert\grants\table_sys_button_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON_GROUP';
spool off


spool 'c:\mighdc\alert\grants\table_sys_button_prop.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON_PROP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON_PROP';
spool off

spool 'c:\mighdc\alert\grants\table_sys_domain.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_DOMAIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_DOMAIN';
spool off

spool 'c:\mighdc\alert\grants\table_sys_message_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_MESSAGE_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_MESSAGE_BCK';
spool off

spool 'c:\mighdc\alert\grants\table_sys_shortcut.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SHORTCUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SHORTCUT';
spool off

spool 'c:\mighdc\alert\grants\table_system_organ.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYSTEM_ORGAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYSTEM_ORGAN';
spool off

spool 'c:\mighdc\alert\grants\table_sys_vital_sign.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_VITAL_SIGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_VITAL_SIGN';
spool off

spool 'c:\mighdc\alert\grants\table_triage_disc_vs_valid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_DISC_VS_VALID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_DISC_VS_VALID';

spool off

spool 'c:\mighdc\alert\grants\table_vaccine_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\table_vbz$object_stats.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VBZ$OBJECT_STATS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VBZ$OBJECT_STATS';
spool off

spool 'c:\mighdc\alert\grants\table_vital_sign_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_NOTES';
spool off


spool 'c:\mighdc\alert\grants\table_vital_sign_read_error.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_READ_ERROR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_READ_ERROR';
spool off

spool 'c:\mighdc\alert\grants\table_wl_call_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_CALL_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_CALL_QUEUE';
spool off

spool 'c:\mighdc\alert\grants\table_wl_patient_sonho.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO';
spool off


spool 'c:\mighdc\alert\grants\table_wl_patient_sonho_transfered.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO_TRANSFERED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO_TRANSFERED';
spool off

spool 'c:\mighdc\alert\grants\table_wl_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_STATUS';
spool off

spool 'c:\mighdc\alert\grants\table_wl_waiting_line_0104.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_LINE_0104','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_LINE_0104';
spool off

spool 'c:\mighdc\alert\grants\table_wound_evaluation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_java$options.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','JAVA$OPTIONS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'JAVA$OPTIONS';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_physiatry_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PHYSIATRY_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PHYSIATRY_AREA';
spool off

spool 'c:\mighdc\alert\grants\synonym_instit_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INSTIT_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INSTIT_EXT_SYS';

spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_epis_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_epis_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_cancel_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CANCEL_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CANCEL_REASON';
spool off

spool 'c:\mighdc\alert\grants\synonym_software_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFTWARE_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFTWARE_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_snomed_descriptions.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_DESCRIPTIONS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_DESCRIPTIONS';
spool off


spool 'c:\mighdc\alert\grants\synonym_snomed_concepts.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_CONCEPTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_CONCEPTS';
spool off

spool 'c:\mighdc\alert\grants\synonym_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_text_freq.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_FREQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_FREQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_text.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT';
spool off

spool 'c:\mighdc\alert\grants\synonym_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_team_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_TEAM_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_TEAM_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS';

spool off

spool 'c:\mighdc\alert\grants\synonym_vaccine_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_vaccine_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_transp_req_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_REQ_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_REQ_GROUP';
spool off


spool 'c:\mighdc\alert\grants\synonym_sys_session.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SESSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SESSION';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_error.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ERROR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ERROR';
spool off


spool 'c:\mighdc\alert\grants\synonym_sys_btn_sbg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BTN_SBG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BTN_SBG';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surg_protocol.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROTOCOL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROTOCOL';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_pregnancy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGNANCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGNANCY';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_photo.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PHOTO';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_medication.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MEDICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MEDICATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HEALTH_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_patient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PATIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PATIENT';

spool off

spool 'c:\mighdc\alert\grants\synonym_p1_problem_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PROBLEM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PROBLEM_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_prblm_rec_procedure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PRBLM_REC_PROCEDURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PRBLM_REC_PROCEDURE';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_history.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_HISTORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_HISTORY';
spool off


spool 'c:\mighdc\alert\grants\synonym_p1_ext_req_tracking.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_EXT_REQ_TRACKING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_EXT_REQ_TRACKING';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_doc_external.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOC_EXTERNAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOC_EXTERNAL';
spool off

spool 'c:\mighdc\alert\grants\synonym_movement.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MOVEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MOVEMENT';
spool off


spool 'c:\mighdc\alert\grants\synonym_drug_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_pharma_class.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA_CLASS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA_CLASS';
spool off

spool 'c:\mighdc\alert\grants\synonym_disch_reas_dest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCH_REAS_DEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCH_REAS_DEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_discharge.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_bp_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_clinical_service.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLINICAL_SERVICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLINICAL_SERVICE';
spool off

spool 'c:\mighdc\alert\grants\synonym_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEP_CLIN_SERV';

spool off

spool 'c:\mighdc\alert\grants\synonym_department.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPARTMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPARTMENT';
spool off

spool 'c:\mighdc\alert\grants\synonym_create$java$lob$table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CREATE$JAVA$LOB$TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CREATE$JAVA$LOB$TABLE';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_ROOM';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_chklist_manual.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST_MANUAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST_MANUAL';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_equip_kit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EQUIP_KIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EQUIP_KIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_eval_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_NOTES';
spool off


spool 'c:\mighdc\alert\grants\synonym_doc_element_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_CRIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_action_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ACTION_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ACTION_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\synonym_floors_dep_position.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS_DEP_POSITION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS_DEP_POSITION';
spool off

spool 'c:\mighdc\alert\grants\synonym_vs_soft_inst.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VS_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VS_SOFT_INST';
spool off

spool 'c:\mighdc\alert\grants\package_pk_types.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_TYPES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_TYPES';
spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_med_cs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_MED_CS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_MED_CS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_surg_record.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_SURG_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_SURG_RECORD';

spool off

spool 'c:\mighdc\alert\grants\package_pk_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_VISIT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inpatient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INPATIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INPATIENT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_documentation_new.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DOCUMENTATION_NEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DOCUMENTATION_NEW';
spool off


spool 'c:\mighdc\alert\grants\package_pk_sr_output.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_OUTPUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_OUTPUT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_search.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SEARCH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SEARCH';
spool off

spool 'c:\mighdc\alert\grants\package_pk_save.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SAVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SAVE';
spool off


spool 'c:\mighdc\alert\grants\package_pk_opinion.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_OPINION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_OPINION';
spool off

spool 'c:\mighdc\alert\grants\package_pk_viewer.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_VIEWER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_VIEWER';
spool off

spool 'c:\mighdc\alert\grants\package_pk_diagram.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DIAGRAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DIAGRAM';
spool off

spool 'c:\mighdc\alert\grants\package_pk_presc_fluids.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PRESC_FLUIDS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PRESC_FLUIDS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_icnp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_ICNP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_ICNP';
spool off

spool 'c:\mighdc\alert\grants\synonym_plan_table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PLAN_TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PLAN_TABLE';
spool off

spool 'c:\mighdc\alert\grants\synonym_dimension.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIMENSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIMENSION';

spool off

spool 'c:\mighdc\alert\grants\synonym_table_varchar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TABLE_VARCHAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TABLE_VARCHAR';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_agp_old.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_AGP_OLD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_AGP_OLD';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_parameter.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PARAMETER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PARAMETER';
spool off


spool 'c:\mighdc\alert\grants\table_analysis_param_instit_sample.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PARAM_INSTIT_SAMPLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PARAM_INSTIT_SAMPLE';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_prep_mesg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PREP_MESG';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_ROOM';
spool off


spool 'c:\mighdc\alert\grants\table_bed_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BED_SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BED_SCHEDULE';
spool off

spool 'c:\mighdc\alert\grants\table_beye_view_screen.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BEYE_VIEW_SCREEN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BEYE_VIEW_SCREEN';
spool off

spool 'c:\mighdc\alert\grants\table_body_part.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BODY_PART','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BODY_PART';
spool off

spool 'c:\mighdc\alert\grants\table_clin_serv_ext_sys.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_SERV_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_SERV_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_contra_indic.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONTRA_INDIC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONTRA_INDIC';
spool off

spool 'c:\mighdc\alert\grants\table_dept_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPT_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPT_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_diagram_image.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_IMAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_IMAGE';

spool off

spool 'c:\mighdc\alert\grants\table_diagram_lay_imag.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_LAY_IMAG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_LAY_IMAG';
spool off

spool 'c:\mighdc\alert\grants\table_discriminator_help.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCRIMINATOR_HELP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCRIMINATOR_HELP';
spool off

spool 'c:\mighdc\alert\grants\table_disc_vs_valid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISC_VS_VALID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISC_VS_VALID';
spool off


spool 'c:\mighdc\alert\grants\table_doc_destination.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_DESTINATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_DESTINATION';
spool off

spool 'c:\mighdc\alert\grants\table_doc_element_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_CRIT';
spool off

spool 'c:\mighdc\alert\grants\table_doc_quantification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_QUANTIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_QUANTIFICATION';
spool off


spool 'c:\mighdc\alert\grants\table_doc_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_document_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENT_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENT_AREA';
spool off

spool 'c:\mighdc\alert\grants\table_drug_despachos_soft_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_DESPACHOS_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_DESPACHOS_SOFT_INST';
spool off

spool 'c:\mighdc\alert\grants\table_drug_pharma.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA';
spool off

spool 'c:\mighdc\alert\grants\table_drug_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_drug_take_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_TAKE_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_TAKE_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_epis_anamnesis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_ANAMNESIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_ANAMNESIS';

spool off

spool 'c:\mighdc\alert\grants\table_epis_bartchart_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BARTCHART_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BARTCHART_DET';
spool off

spool 'c:\mighdc\alert\grants\table_epis_diagnosis_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DIAGNOSIS_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DIAGNOSIS_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_epis_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_HEALTH_PLAN';
spool off


spool 'c:\mighdc\alert\grants\table_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\table_epis_interval_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INTERVAL_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INTERVAL_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_epis_man.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_MAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_MAN';
spool off


spool 'c:\mighdc\alert\grants\table_epis_observation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBSERVATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBSERVATION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PHOTO';
spool off

spool 'c:\mighdc\alert\grants\table_epis_report_section.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_REPORT_SECTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_REPORT_SECTION';
spool off

spool 'c:\mighdc\alert\grants\table_exam_drug.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_DRUG';
spool off

spool 'c:\mighdc\alert\grants\table_grid_task_between.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GRID_TASK_BETWEEN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GRID_TASK_BETWEEN';
spool off

spool 'c:\mighdc\alert\grants\table_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEALTH_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_hemo_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ_DET';

spool off

spool 'c:\mighdc\alert\grants\table_hemo_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_hidrics.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HIDRICS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HIDRICS';
spool off

spool 'c:\mighdc\alert\grants\table_hidrics_interval.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HIDRICS_INTERVAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HIDRICS_INTERVAL';
spool off


spool 'c:\mighdc\alert\grants\table_icnp_compo_folder_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_FOLDER_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_FOLDER_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_morph.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_MORPH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_MORPH';
spool off


spool 'c:\mighdc\alert\grants\table_icnp_transition_state_060426.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_TRANSITION_STATE_060426','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_TRANSITION_STATE_060426';
spool off

spool 'c:\mighdc\alert\grants\table_inf_emb_comerc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_EMB_COMERC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_EMB_COMERC';
spool off

spool 'c:\mighdc\alert\grants\table_inf_med.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_MED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_MED';
spool off

spool 'c:\mighdc\alert\grants\table_inf_vias_admin.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_VIAS_ADMIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_VIAS_ADMIN';
spool off

spool 'c:\mighdc\alert\grants\table_interv_dep_clin_serv_migra.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DEP_CLIN_SERV_MIGRA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DEP_CLIN_SERV_MIGRA';
spool off

spool 'c:\mighdc\alert\grants\table_interv_dep_clin_serv_20060303.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DEP_CLIN_SERV_20060303','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DEP_CLIN_SERV_20060303';
spool off

spool 'c:\mighdc\alert\grants\table_manipulated_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANIPULATED_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANIPULATED_GROUP';

spool off

spool 'c:\mighdc\alert\grants\table_matr_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_nurse_activity_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_ACTIVITY_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_ACTIVITY_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_occupation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OCCUPATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OCCUPATION';
spool off


spool 'c:\mighdc\alert\grants\table_opinion.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OPINION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OPINION';
spool off

spool 'c:\mighdc\alert\grants\table_pat_allergy_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_ALLERGY_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_ALLERGY_HIST';
spool off

spool 'c:\mighdc\alert\grants\table_pat_history.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HISTORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HISTORY';
spool off


spool 'c:\mighdc\alert\grants\table_pat_med_decl.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MED_DECL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MED_DECL';
spool off

spool 'c:\mighdc\alert\grants\table_pat_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_pat_pregn_fetus_biom.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS_BIOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS_BIOM';
spool off

spool 'c:\mighdc\alert\grants\table_pat_pregn_measure.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\table_plan_table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PLAN_TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PLAN_TABLE';
spool off

spool 'c:\mighdc\alert\grants\table_postal_code_pt.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','POSTAL_CODE_PT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'POSTAL_CODE_PT';
spool off

spool 'c:\mighdc\alert\grants\table_presc_pat_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESC_PAT_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESC_PAT_PROBLEM';

spool off

spool 'c:\mighdc\alert\grants\table_prescription_type_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_TYPE_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_TYPE_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_prof_access_field_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS_FIELD_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS_FIELD_FUNC';
spool off

spool 'c:\mighdc\alert\grants\table_prof_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_EXT_SYS';
spool off


spool 'c:\mighdc\alert\grants\table_profile_templ_access_bck_agn.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPL_ACCESS_BCK_AGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPL_ACCESS_BCK_AGN';
spool off

spool 'c:\mighdc\alert\grants\table_protoc_diag.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROTOC_DIAG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROTOC_DIAG';
spool off

spool 'c:\mighdc\alert\grants\table_p1_doc_external.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOC_EXTERNAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOC_EXTERNAL';
spool off


spool 'c:\mighdc\alert\grants\table_rb_interv_icd.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RB_INTERV_ICD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RB_INTERV_ICD';
spool off

spool 'c:\mighdc\alert\grants\table_rep_profile_template_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_PROFILE_TEMPLATE_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_PROFILE_TEMPLATE_DET';
spool off

spool 'c:\mighdc\alert\grants\table_rep_prof_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_PROF_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_PROF_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_rep_section_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_SECTION_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_SECTION_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sample_text_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_PROF';
spool off

spool 'c:\mighdc\alert\grants\table_sample_text_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_scales.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCALES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCALES';

spool off

spool 'c:\mighdc\alert\grants\table_sch_default_consult_vacancy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_DEFAULT_CONSULT_VACANCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_DEFAULT_CONSULT_VACANCY';
spool off

spool 'c:\mighdc\alert\grants\table_schedule_alter.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_ALTER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_ALTER';
spool off

spool 'c:\mighdc\alert\grants\table_sch_prof_outp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_PROF_OUTP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_PROF_OUTP';
spool off


spool 'c:\mighdc\alert\grants\table_sch_resource.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_RESOURCE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_RESOURCE';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\table_software.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFTWARE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFTWARE';
spool off


spool 'c:\mighdc\alert\grants\table_sqln_explain_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SQLN_EXPLAIN_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SQLN_EXPLAIN_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_sr_base_diag.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_BASE_DIAG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_BASE_DIAG';
spool off

spool 'c:\mighdc\alert\grants\table_sr_chklist_manual.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST_MANUAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST_MANUAL';
spool off

spool 'c:\mighdc\alert\grants\table_sr_epis_interv.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\table_sr_interv_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERV_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERV_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_sr_pos_eval_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POS_EVAL_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POS_EVAL_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_posit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POSIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POSIT';

spool off

spool 'c:\mighdc\alert\grants\table_sr_pre_eval_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_EVAL_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_EVAL_VISIT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_prof_shift.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PROF_SHIFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PROF_SHIFT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_receive_manual.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_MANUAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_MANUAL';
spool off


spool 'c:\mighdc\alert\grants\table_sys_alert_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sys_application_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_APPLICATION_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_APPLICATION_AREA';
spool off

spool 'c:\mighdc\alert\grants\table_sys_entrance.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ENTRANCE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ENTRANCE';
spool off


spool 'c:\mighdc\alert\grants\table_sys_field.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_FIELD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_FIELD';
spool off

spool 'c:\mighdc\alert\grants\table_sys_login.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_LOGIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_LOGIN';
spool off

spool 'c:\mighdc\alert\grants\table_sys_screen_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SCREEN_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SCREEN_AREA';
spool off

spool 'c:\mighdc\alert\grants\table_temp_portaria.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TEMP_PORTARIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TEMP_PORTARIA';
spool off

spool 'c:\mighdc\alert\grants\table_triage_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_unit_measure_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','UNIT_MEASURE_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'UNIT_MEASURE_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_wound_treat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_TREAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_TREAT';

spool off

spool 'c:\mighdc\alert\grants\table_wound_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_matr_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_ROOM';
spool off


spool 'c:\mighdc\alert\grants\synonym_interv_presc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESC_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_folder.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_FOLDER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_FOLDER';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_composition.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPOSITION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPOSITION';
spool off


spool 'c:\mighdc\alert\grants\synonym_icnp_axis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_AXIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_AXIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_req.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_egp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_EGP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_EGP';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM';

spool off

spool 'c:\mighdc\alert\grants\synonym_epis_type_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TYPE_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TYPE_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_serv_sched_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SERV_SCHED_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SERV_SCHED_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\synonym_room_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_EXT_SYS';
spool off


spool 'c:\mighdc\alert\grants\synonym_profile_templ_acc_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPL_ACC_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPL_ACC_FUNC';
spool off

spool 'c:\mighdc\alert\grants\synonym_profile_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_call_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_CALL_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_CALL_QUEUE';
spool off


spool 'c:\mighdc\alert\grants\synonym_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VISIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_time_unit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TIME_UNIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TIME_UNIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_shortcut.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SHORTCUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SHORTCUT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_screen_area.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SCREEN_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SCREEN_AREA';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_button_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_button.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surg_prot_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_TASK';

spool off

spool 'c:\mighdc\alert\grants\synonym_sr_receive_proc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_receive_proc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC';
spool off

spool 'c:\mighdc\alert\grants\synonym_wound_treat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_TREAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_TREAT';
spool off


spool 'c:\mighdc\alert\grants\synonym_wound_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_wound_charac.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_CHARAC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_CHARAC';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_topics.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_TOPICS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_TOPICS';
spool off


spool 'c:\mighdc\alert\grants\synonym_pat_ginec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_GINEC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_GINEC';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_cntrceptiv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CNTRCEPTIV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CNTRCEPTIV';
spool off

spool 'c:\mighdc\alert\grants\synonym_outlook.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OUTLOOK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OUTLOOK';
spool off

spool 'c:\mighdc\alert\grants\synonym_occupation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OCCUPATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OCCUPATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_form.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_FORM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_FORM';
spool off

spool 'c:\mighdc\alert\grants\synonym_discriminator_help.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCRIMINATOR_HELP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCRIMINATOR_HELP';
spool off

spool 'c:\mighdc\alert\grants\synonym_discriminator.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCRIMINATOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCRIMINATOR';

spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_result.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_RESULT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_RESULT';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ';
spool off


spool 'c:\mighdc\alert\grants\synonym_ch_contents_text.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CH_CONTENTS_TEXT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CH_CONTENTS_TEXT';
spool off

spool 'c:\mighdc\alert\grants\synonym_cli_rec_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_consult_req_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONSULT_REQ_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONSULT_REQ_PROF';
spool off


spool 'c:\mighdc\alert\grants\synonym_adverse_interv_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ADVERSE_INTERV_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ADVERSE_INTERV_ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\synonym_sch_event.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_EVENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_EVENT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_posit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POSIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POSIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surg_period.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PERIOD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PERIOD';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_element.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ELEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ELEMENT';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_component.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_COMPONENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_COMPONENT';
spool off

spool 'c:\mighdc\alert\grants\synonym_complaint.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COMPLAINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COMPLAINT';

spool off

spool 'c:\mighdc\alert\grants\synonym_epis_documentation_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DOCUMENTATION_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DOCUMENTATION_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_documentation_rel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION_REL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION_REL';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_element.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT';
spool off


spool 'c:\mighdc\alert\grants\synonym_doc_action_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ACTION_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ACTION_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_bartchart.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BARTCHART','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BARTCHART';
spool off

spool 'c:\mighdc\alert\grants\synonym_floors.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS';
spool off


spool 'c:\mighdc\alert\grants\synonym_pk_sr_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_nurse.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_NURSE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_NURSE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_reset.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_RESET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_RESET';
spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_proc.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_PROC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_PROC';
spool off

spool 'c:\mighdc\alert\grants\package_pk_demo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DEMO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DEMO';
spool off

spool 'c:\mighdc\alert\grants\package_pk_login_list.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_LOGIN_LIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_LOGIN_LIST';
spool off

spool 'c:\mighdc\alert\grants\package_pk_image_tech.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_IMAGE_TECH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_IMAGE_TECH';

spool off

spool 'c:\mighdc\alert\grants\package_pk_audit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_AUDIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_AUDIT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_hand_off.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_HAND_OFF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_HAND_OFF';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wheel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WHEEL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WHEEL';
spool off


spool 'c:\mighdc\alert\grants\package_pk_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INTERV';
spool off

spool 'c:\mighdc\alert\grants\package_pk_monitorization.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_MONITORIZATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_MONITORIZATION';
spool off

spool 'c:\mighdc\alert\grants\table_dept.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPT';
spool off


spool 'c:\mighdc\alert\grants\sequence_seq_presc_xml_0102.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_XML_0102','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_XML_0102';
spool off

spool 'c:\mighdc\alert\grants\table_abnormality_nature.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ABNORMALITY_NATURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ABNORMALITY_NATURE';
spool off

spool 'c:\mighdc\alert\grants\table_adverse_exam_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ADVERSE_EXAM_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ADVERSE_EXAM_ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\table_allergy.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\table_allocation_bed_10042007.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ALLOCATION_BED_10042007','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ALLOCATION_BED_10042007';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_instit_soft.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_INSTIT_SOFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_INSTIT_SOFT';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_result.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_RESULT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_RESULT';

spool off

spool 'c:\mighdc\alert\grants\table_board.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD';
spool off

spool 'c:\mighdc\alert\grants\table_ch_contents_text.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CH_CONTENTS_TEXT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CH_CONTENTS_TEXT';
spool off

spool 'c:\mighdc\alert\grants\table_child_feed_dev.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CHILD_FEED_DEV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CHILD_FEED_DEV';
spool off


spool 'c:\mighdc\alert\grants\table_clinical_service.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLINICAL_SERVICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLINICAL_SERVICE';
spool off

spool 'c:\mighdc\alert\grants\table_color.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COLOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COLOR';
spool off

spool 'c:\mighdc\alert\grants\table_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGNOSIS';
spool off


spool 'c:\mighdc\alert\grants\table_drug_justification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_JUSTIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_JUSTIFICATION';
spool off

spool 'c:\mighdc\alert\grants\table_element_rel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ELEMENT_REL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ELEMENT_REL';
spool off

spool 'c:\mighdc\alert\grants\table_epis_attending_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_ATTENDING_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_ATTENDING_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_epis_diagnosis.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_epis_drug_usage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DRUG_USAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DRUG_USAGE';
spool off

spool 'c:\mighdc\alert\grants\table_epis_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_epis_obs_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBS_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBS_PHOTO';

spool off

spool 'c:\mighdc\alert\grants\table_epis_positioning_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_POSITIONING_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_POSITIONING_DET';
spool off

spool 'c:\mighdc\alert\grants\table_epis_positioning_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_POSITIONING_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_POSITIONING_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_epis_review_systems.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_REVIEW_SYSTEMS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_REVIEW_SYSTEMS';
spool off


spool 'c:\mighdc\alert\grants\table_equip_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EQUIP_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EQUIP_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_exam_ext_sys_delete.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_EXT_SYS_DELETE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_EXT_SYS_DELETE';
spool off

spool 'c:\mighdc\alert\grants\table_exam_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_REQ_DET';
spool off


spool 'c:\mighdc\alert\grants\table_exam_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_family_relationship.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FAMILY_RELATIONSHIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FAMILY_RELATIONSHIP';
spool off

spool 'c:\mighdc\alert\grants\table_grid_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GRID_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GRID_TASK';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_intervention_060425.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_INTERVENTION_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_INTERVENTION_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_predefined_action.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_PREDEFINED_ACTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_PREDEFINED_ACTION';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_term.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_TERM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_TERM';
spool off

spool 'c:\mighdc\alert\grants\table_import_prof_med.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_PROF_MED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_PROF_MED';

spool off

spool 'c:\mighdc\alert\grants\table_inf_patol_dip_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_PATOL_DIP_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_PATOL_DIP_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_inf_titular_aim.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_TITULAR_AIM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_TITULAR_AIM';
spool off

spool 'c:\mighdc\alert\grants\table_interv_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESCRIPTION';
spool off


spool 'c:\mighdc\alert\grants\table_isencao.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ISENCAO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ISENCAO';
spool off

spool 'c:\mighdc\alert\grants\table_java$options.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','JAVA$OPTIONS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'JAVA$OPTIONS';
spool off

spool 'c:\mighdc\alert\grants\table_matr_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_matr_scheduled.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_SCHEDULED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_SCHEDULED';
spool off

spool 'c:\mighdc\alert\grants\table_parameter_analysis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PARAMETER_ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PARAMETER_ANALYSIS';
spool off

spool 'c:\mighdc\alert\grants\table_pat_family_disease.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_DISEASE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_DISEASE';
spool off

spool 'c:\mighdc\alert\grants\table_pat_habit.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HABIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HABIT';
spool off

spool 'c:\mighdc\alert\grants\table_pat_history_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HISTORY_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HISTORY_HIST';
spool off

spool 'c:\mighdc\alert\grants\table_pat_medication_hist_list.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MEDICATION_HIST_LIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MEDICATION_HIST_LIST';
spool off

spool 'c:\mighdc\alert\grants\table_pat_necessity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_NECESSITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_NECESSITY';

spool off

spool 'c:\mighdc\alert\grants\table_prescription_pharm.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_PHARM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_PHARM';
spool off

spool 'c:\mighdc\alert\grants\table_professional.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFESSIONAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFESSIONAL';
spool off

spool 'c:\mighdc\alert\grants\table_prof_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_INSTITUTION';
spool off


spool 'c:\mighdc\alert\grants\table_prof_preferences.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PREFERENCES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PREFERENCES';
spool off

spool 'c:\mighdc\alert\grants\table_p1_ext_req_tracking.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_EXT_REQ_TRACKING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_EXT_REQ_TRACKING';
spool off

spool 'c:\mighdc\alert\grants\table_rb_sys_shortcut.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RB_SYS_SHORTCUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RB_SYS_SHORTCUT';
spool off


spool 'c:\mighdc\alert\grants\table_reports.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REPORTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REPORTS';
spool off

spool 'c:\mighdc\alert\grants\table_rep_screen.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_SCREEN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_SCREEN';
spool off

spool 'c:\mighdc\alert\grants\table_sch_consult_vacancy_temp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_CONSULT_VACANCY_TEMP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_CONSULT_VACANCY_TEMP';
spool off

spool 'c:\mighdc\alert\grants\table_schedule_sr_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_SR_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_SR_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sch_event.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_EVENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_EVENT';
spool off

spool 'c:\mighdc\alert\grants\table_snomed_concepts.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_CONCEPTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_CONCEPTS';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_diag.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_DIAG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_DIAG';

spool off

spool 'c:\mighdc\alert\grants\table_sr_epis_interv_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EPIS_INTERV_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EPIS_INTERV_DESC';
spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_VISIT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_interv_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERV_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERV_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_sr_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\table_sr_receive_proc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surgery_rec_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_REC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_REC_DET';
spool off


spool 'c:\mighdc\alert\grants\table_sys_documentation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_DOCUMENTATION';
spool off

spool 'c:\mighdc\alert\grants\table_sys_message.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_MESSAGE';
spool off

spool 'c:\mighdc\alert\grants\table_system_apparati.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYSTEM_APPARATI','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYSTEM_APPARATI';
spool off

spool 'c:\mighdc\alert\grants\table_translation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSLATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSLATION';
spool off

spool 'c:\mighdc\alert\grants\table_transp_entity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_ENTITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_ENTITY';
spool off

spool 'c:\mighdc\alert\grants\table_triage_nurse.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_NURSE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_NURSE';
spool off

spool 'c:\mighdc\alert\grants\table_triage_units.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_UNITS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_UNITS';

spool off

spool 'c:\mighdc\alert\grants\table_unit_measure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','UNIT_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'UNIT_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\table_unit_measure_convert.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','UNIT_MEASURE_CONVERT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'UNIT_MEASURE_CONVERT';
spool off

spool 'c:\mighdc\alert\grants\table_vital_sign_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_DESC';
spool off


spool 'c:\mighdc\alert\grants\table_vs_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VS_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VS_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_vs_soft_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VS_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VS_SOFT_INST';
spool off

spool 'c:\mighdc\alert\grants\table_wl_msg_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MSG_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MSG_QUEUE';
spool off


spool 'c:\mighdc\alert\grants\table_wl_topics.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_TOPICS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_TOPICS';
spool off

spool 'c:\mighdc\alert\grants\table_wl_waiting_line.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_LINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_LINE';
spool off

spool 'c:\mighdc\alert\grants\table_wl_waiting_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_wound_charac.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_CHARAC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_CHARAC';
spool off

spool 'c:\mighdc\alert\grants\synonym_material.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_prep_msg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PREP_MSG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PREP_MSG';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_compo_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_INST';

spool off

spool 'c:\mighdc\alert\grants\synonym_harvest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HARVEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HARVEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_ginec_obstet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GINEC_OBSTET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GINEC_OBSTET';
spool off

spool 'c:\mighdc\alert\grants\synonym_external_cause.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXTERNAL_CAUSE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXTERNAL_CAUSE';
spool off


spool 'c:\mighdc\alert\grants\synonym_sch_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_schedule_outp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_OUTP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_OUTP';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TYPE';
spool off


spool 'c:\mighdc\alert\grants\synonym_room_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_team.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_TEAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_TEAM';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_doc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_DOC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_DOC';
spool off

spool 'c:\mighdc\alert\grants\synonym_profile_templ_access.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPL_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPL_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_vaccine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_VACCINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_VACCINE';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_soc_attributes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_SOC_ATTRIBUTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_SOC_ATTRIBUTES';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_msg_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MSG_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MSG_QUEUE';

spool off

spool 'c:\mighdc\alert\grants\synonym_vaccine_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_transp_ent_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_ENT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_ENT_INST';
spool off

spool 'c:\mighdc\alert\grants\synonym_transp_entity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_ENTITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_ENTITY';
spool off


spool 'c:\mighdc\alert\grants\synonym_transport_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSPORT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSPORT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_button_prop.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON_PROP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON_PROP';
spool off

spool 'c:\mighdc\alert\grants\synonym_system_apparati.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYSTEM_APPARATI','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYSTEM_APPARATI';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_prof_team_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PROF_TEAM_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PROF_TEAM_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_prob_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROB_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROB_VISIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_pregn_fetus.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_child_feed_dev.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CHILD_FEED_DEV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CHILD_FEED_DEV';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_recomended_procedure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_RECOMENDED_PROCEDURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_RECOMENDED_PROCEDURE';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_doc_external_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOC_EXTERNAL_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOC_EXTERNAL_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_documents_done.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOCUMENTS_DONE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOCUMENTS_DONE';

spool off

spool 'c:\mighdc\alert\grants\synonym_monitorization_vs_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION_VS_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION_VS_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_monitorization_vs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION_VS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION_VS';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INTERV';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_HEALTH_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_route.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_ROUTE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_ROUTE';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG';
spool off


spool 'c:\mighdc\alert\grants\synonym_disc_vs_valid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISC_VS_VALID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISC_VS_VALID';
spool off

spool 'c:\mighdc\alert\grants\synonym_disch_prep_mesg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCH_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCH_PREP_MESG';
spool off

spool 'c:\mighdc\alert\grants\synonym_discharge_dest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_DEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_DEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_color.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COLOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COLOR';
spool off

spool 'c:\mighdc\alert\grants\synonym_clin_serv_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_SERV_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_SERV_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\synonym_board.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD';
spool off

spool 'c:\mighdc\alert\grants\synonym_birds_eye_view.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BIRDS_EYE_VIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BIRDS_EYE_VIEW';

spool off

spool 'c:\mighdc\alert\grants\synonym_anesthesia_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANESTHESIA_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANESTHESIA_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sch_event_dcs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_EVENT_DCS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_EVENT_DCS';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVALUATION';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_posit_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POSIT_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POSIT_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_nurse_rec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_NURSE_REC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_NURSE_REC';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_room_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_ROOM_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_ROOM_STATUS';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_pre_anest_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_ANEST_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_ANEST_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_eval_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_VISIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_eval_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_triage_type.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_template_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TEMPLATE_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TEMPLATE_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_AREA';

spool off

spool 'c:\mighdc\alert\grants\synonym_doc_element_rel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_REL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_REL';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_complaint.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_COMPLAINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_COMPLAINT';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_external.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_EXTERNAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_EXTERNAL';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_prof_resp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROF_RESP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROF_RESP';
spool off

spool 'c:\mighdc\alert\grants\package_pk_translation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_TRANSLATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_TRANSLATION';
spool off

spool 'c:\mighdc\alert\grants\function_sr_act_schedule_date.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_ACT_SCHEDULE_DATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_ACT_SCHEDULE_DATE';
spool off


spool 'c:\mighdc\alert\grants\package_pk_tools.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_TOOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_TOOLS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_procedures.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_PROCEDURES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_PROCEDURES';
spool off

spool 'c:\mighdc\alert\grants\package_pk_discharge.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_util.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_UTIL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_UTIL';
spool off

spool 'c:\mighdc\alert\grants\package_pk_print_tool.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PRINT_TOOL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PRINT_TOOL';
spool off

spool 'c:\mighdc\alert\grants\package_pk_problems.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PROBLEMS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PROBLEMS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_barcode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BARCODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BARCODE';

spool off

spool 'c:\mighdc\alert\grants\package_pk_sample_text.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SAMPLE_TEXT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SAMPLE_TEXT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wlsession.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLSESSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLSESSION';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wlpatient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLPATIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLPATIENT';
spool off


spool 'c:\mighdc\alert\grants\package_pk_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\table_adverse_interv_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ADVERSE_INTERV_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ADVERSE_INTERV_ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\table_allocation_bed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ALLOCATION_BED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ALLOCATION_BED';
spool off


spool 'c:\mighdc\alert\grants\table_analysis_param.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PARAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PARAM';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_result_par.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_RESULT_PAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_RESULT_PAR';
spool off

spool 'c:\mighdc\alert\grants\table_board_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_category_sub.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CATEGORY_SUB','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CATEGORY_SUB';
spool off

spool 'c:\mighdc\alert\grants\table_cli_rec_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\table_country.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COUNTRY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COUNTRY';
spool off

spool 'c:\mighdc\alert\grants\table_dependency.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPENDENCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPENDENCY';

spool off

spool 'c:\mighdc\alert\grants\table_diagram_detail_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_DETAIL_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_DETAIL_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_dietary_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIETARY_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIETARY_DRUG';
spool off

spool 'c:\mighdc\alert\grants\table_diet_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIET_SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIET_SCHEDULE';
spool off


spool 'c:\mighdc\alert\grants\table_discharge_detail.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_DETAIL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_DETAIL';
spool off

spool 'c:\mighdc\alert\grants\table_disch_reas_dest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCH_REAS_DEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCH_REAS_DEST';
spool off

spool 'c:\mighdc\alert\grants\table_doc_dimension.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_DIMENSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_DIMENSION';
spool off


spool 'c:\mighdc\alert\grants\table_doc_element_qualif.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_QUALIF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_QUALIF';
spool off

spool 'c:\mighdc\alert\grants\table_doc_element_rel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_REL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_REL';
spool off

spool 'c:\mighdc\alert\grants\table_doc_ori_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ORI_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ORI_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_doc_type.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_drug_pharma_class.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA_CLASS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA_CLASS';
spool off

spool 'c:\mighdc\alert\grants\table_drug_route.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_ROUTE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_ROUTE';
spool off

spool 'c:\mighdc\alert\grants\table_epis_hidrics_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_HIDRICS_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_HIDRICS_DET';

spool off

spool 'c:\mighdc\alert\grants\table_epis_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_report.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_REPORT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_REPORT';
spool off

spool 'c:\mighdc\alert\grants\table_exam_cat_dcs_bck1.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_CAT_DCS_BCK1','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_CAT_DCS_BCK1';
spool off


spool 'c:\mighdc\alert\grants\table_family_monetary.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FAMILY_MONETARY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FAMILY_MONETARY';
spool off

spool 'c:\mighdc\alert\grants\table_graffar_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GRAFFAR_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GRAFFAR_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\table_hemo_req_supply.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ_SUPPLY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ_SUPPLY';
spool off


spool 'c:\mighdc\alert\grants\table_hidrics_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HIDRICS_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HIDRICS_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_axis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_AXIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_AXIS';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_composition_term.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPOSITION_TERM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPOSITION_TERM';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_diag_interv_060425.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAG_INTERV_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAG_INTERV_060425';
spool off

spool 'c:\mighdc\alert\grants\table_import_prof_admin.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_PROF_ADMIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_PROF_ADMIN';
spool off

spool 'c:\mighdc\alert\grants\table_ine_location.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INE_LOCATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INE_LOCATION';
spool off

spool 'c:\mighdc\alert\grants\table_inf_class_estup.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_CLASS_ESTUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_CLASS_ESTUP';

spool off

spool 'c:\mighdc\alert\grants\table_inf_patol_esp_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_PATOL_ESP_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_PATOL_ESP_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_interv_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_interv_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DRUG';
spool off


spool 'c:\mighdc\alert\grants\table_material_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\table_mdm_prof_coding.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MDM_PROF_CODING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MDM_PROF_CODING';
spool off

spool 'c:\mighdc\alert\grants\table_monitorization_vs_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION_VS_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION_VS_PLAN';
spool off


spool 'c:\mighdc\alert\grants\table_necessity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NECESSITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NECESSITY';
spool off

spool 'c:\mighdc\alert\grants\table_origin_soft.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ORIGIN_SOFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ORIGIN_SOFT';
spool off

spool 'c:\mighdc\alert\grants\table_outlook.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OUTLOOK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OUTLOOK';
spool off

spool 'c:\mighdc\alert\grants\table_param_analysis_ext_sys_delete.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PARAM_ANALYSIS_EXT_SYS_DELETE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PARAM_ANALYSIS_EXT_SYS_DELETE';
spool off

spool 'c:\mighdc\alert\grants\table_pat_child_clin_rec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CHILD_CLIN_REC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CHILD_CLIN_REC';
spool off

spool 'c:\mighdc\alert\grants\table_pat_cntrceptiv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CNTRCEPTIV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CNTRCEPTIV';
spool off

spool 'c:\mighdc\alert\grants\table_pat_delivery.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_DELIVERY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_DELIVERY';

spool off

spool 'c:\mighdc\alert\grants\table_pat_doc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_DOC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_DOC';
spool off

spool 'c:\mighdc\alert\grants\table_pat_ginec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_GINEC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_GINEC';
spool off

spool 'c:\mighdc\alert\grants\table_pat_graffar_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_GRAFFAR_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_GRAFFAR_CRIT';
spool off


spool 'c:\mighdc\alert\grants\table_pat_history_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HISTORY_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HISTORY_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_patient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PATIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PATIENT';
spool off

spool 'c:\mighdc\alert\grants\table_pat_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PHOTO';
spool off


spool 'c:\mighdc\alert\grants\table_pat_pregn_fetus.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS';
spool off

spool 'c:\mighdc\alert\grants\table_pat_problem_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROBLEM_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROBLEM_HIST';
spool off

spool 'c:\mighdc\alert\grants\table_pat_sick_leave.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_SICK_LEAVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_SICK_LEAVE';
spool off

spool 'c:\mighdc\alert\grants\table_presc_attention_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESC_ATTENTION_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESC_ATTENTION_DET';
spool off

spool 'c:\mighdc\alert\grants\table_prescription_number_seq.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_NUMBER_SEQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_NUMBER_SEQ';
spool off

spool 'c:\mighdc\alert\grants\table_prof_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_prof_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_FUNC';

spool off

spool 'c:\mighdc\alert\grants\table_prof_profile_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PROFILE_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PROFILE_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_records_review.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RECORDS_REVIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RECORDS_REVIEW';
spool off

spool 'c:\mighdc\alert\grants\table_religion.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RELIGION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RELIGION';
spool off


spool 'c:\mighdc\alert\grants\table_room_scheduled.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_SCHEDULED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_SCHEDULED';
spool off

spool 'c:\mighdc\alert\grants\table_sch_event_dcs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_EVENT_DCS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_EVENT_DCS';
spool off

spool 'c:\mighdc\alert\grants\table_sch_schedule_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_SCHEDULE_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_SCHEDULE_REQUEST';
spool off


spool 'c:\mighdc\alert\grants\table_serv_sched_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SERV_SCHED_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SERV_SCHED_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_discharge.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_situation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_SITUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_SITUATION';
spool off

spool 'c:\mighdc\alert\grants\table_soft_inst_services.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFT_INST_SERVICES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFT_INST_SERVICES';
spool off

spool 'c:\mighdc\alert\grants\table_spec_sys_appar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SPEC_SYS_APPAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SPEC_SYS_APPAR';
spool off

spool 'c:\mighdc\alert\grants\table_sr_equip_kit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EQUIP_KIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EQUIP_KIT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_equip_period.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EQUIP_PERIOD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EQUIP_PERIOD';

spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_summ.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_SUMM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_SUMM';
spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_sr_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVALUATION';
spool off


spool 'c:\mighdc\alert\grants\table_sr_room_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_ROOM_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_ROOM_STATUS';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surgery_time_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_TIME_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_TIME_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sys_alert_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_PROF';
spool off


spool 'c:\mighdc\alert\grants\table_sys_element.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ELEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ELEMENT';
spool off

spool 'c:\mighdc\alert\grants\table_sys_element_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ELEMENT_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ELEMENT_CRIT';
spool off

spool 'c:\mighdc\alert\grants\table_sys_screen_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SCREEN_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SCREEN_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_sys_time_event_group.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_TIME_EVENT_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_TIME_EVENT_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_transp_ent_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_ENT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_ENT_INST';
spool off

spool 'c:\mighdc\alert\grants\table_transp_req_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_REQ_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_REQ_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VISIT';

spool off

spool 'c:\mighdc\alert\grants\table_wl_mach_prof_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MACH_PROF_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MACH_PROF_QUEUE';
spool off

spool 'c:\mighdc\alert\grants\synonym_matr_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_material_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_REQ';
spool off


spool 'c:\mighdc\alert\grants\synonym_interv_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DRUG';
spool off


spool 'c:\mighdc\alert\grants\synonym_implementation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPLEMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPLEMENTATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_relationship.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_RELATIONSHIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_RELATIONSHIP';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_morph.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_MORPH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_MORPH';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_result.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_RESULT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_RESULT';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_prep_mesg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_PREP_MESG';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_sqln_explain_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SQLN_EXPLAIN_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SQLN_EXPLAIN_PLAN';

spool off

spool 'c:\mighdc\alert\grants\synonym_soft_inst_impl.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFT_INST_IMPL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFT_INST_IMPL';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_text_type_cat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_TYPE_CAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_TYPE_CAT';
spool off

spool 'c:\mighdc\alert\grants\synonym_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM';
spool off


spool 'c:\mighdc\alert\grants\synonym_protoc_diag.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROTOC_DIAG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROTOC_DIAG';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_soft_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_SOFT_INST';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_access_field_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS_FIELD_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS_FIELD_FUNC';
spool off


spool 'c:\mighdc\alert\grants\synonym_wl_patient_sonho_imp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO_IMP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO_IMP';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_mach_prof_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MACH_PROF_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MACH_PROF_QUEUE';
spool off

spool 'c:\mighdc\alert\grants\synonym_vbz$object_stats.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VBZ$OBJECT_STATS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VBZ$OBJECT_STATS';
spool off

spool 'c:\mighdc\alert\grants\synonym_vaccine_presc_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESC_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_functionality.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_FUNCTIONALITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_FUNCTIONALITY';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_domain.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_DOMAIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_DOMAIN';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_application_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_APPLICATION_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_APPLICATION_AREA';

spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surg_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_TASK';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_family_disease.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_DISEASE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_DISEASE';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_ALLERGY';
spool off


spool 'c:\mighdc\alert\grants\synonym_p1_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PROBLEM';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_external_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_EXTERNAL_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_EXTERNAL_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROBLEM';
spool off


spool 'c:\mighdc\alert\grants\synonym_drug_take_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_TAKE_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_TAKE_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_brand.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_BRAND','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_BRAND';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_result_par.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_RESULT_PAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_RESULT_PAR';
spool off

spool 'c:\mighdc\alert\grants\synonym_category.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CATEGORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CATEGORY';
spool off

spool 'c:\mighdc\alert\grants\synonym_board_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_clin_srv_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_SRV_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_SRV_TYPE';

spool off

spool 'c:\mighdc\alert\grants\synonym_dep_clin_serv_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEP_CLIN_SERV_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEP_CLIN_SERV_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\synonym_country.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COUNTRY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COUNTRY';
spool off


spool 'c:\mighdc\alert\grants\synonym_contraceptive.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONTRACEPTIVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONTRACEPTIVE';
spool off

spool 'c:\mighdc\alert\grants\synonym_unit_measure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','UNIT_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'UNIT_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_receive_manual.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_MANUAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_MANUAL';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surgery_rec_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_REC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_REC_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_element_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ELEMENT_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ELEMENT_CRIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_qualification.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_QUALIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_QUALIFICATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_triage_color.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_COLOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_COLOR';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_bartchart_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BARTCHART_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BARTCHART_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_floors_department.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS_DEPARTMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS_DEPARTMENT';

spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_adm_hs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_ADM_HS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_ADM_HS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_med_hs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_MED_HS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_MED_HS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_reset.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_RESET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_RESET';
spool off


spool 'c:\mighdc\alert\grants\package_pk_grid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_GRID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_GRID';
spool off

spool 'c:\mighdc\alert\grants\package_pk_bird_eye_view.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BIRD_EYE_VIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BIRD_EYE_VIEW';
spool off

spool 'c:\mighdc\alert\grants\package_pk_bed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BED';
spool off


spool 'c:\mighdc\alert\grants\package_pk_exam.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EXAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EXAM';
spool off

spool 'c:\mighdc\alert\grants\package_pk_analysis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_ANALYSIS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_interface_report_er_outp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INTERFACE_REPORT_ER_OUTP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INTERFACE_REPORT_ER_OUTP';
spool off

spool 'c:\mighdc\alert\grants\package_pk_waitinglinesonho.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WAITINGLINESONHO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WAITINGLINESONHO';
spool off

spool 'c:\mighdc\alert\grants\package_pk_patient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PATIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PATIENT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_screen_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SCREEN_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SCREEN_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_lab_tech.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_LAB_TECH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_LAB_TECH';

spool off

spool 'c:\mighdc\alert\grants\package_pk_vaccine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_VACCINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_VACCINE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_profphoto.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PROFPHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PROFPHOTO';
spool off

spool 'c:\mighdc\alert\grants\sequence_seq_presc_xml_0124.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_XML_0124','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_XML_0124';
spool off


spool 'c:\mighdc\alert\grants\type_table_number.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TABLE_NUMBER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TABLE_NUMBER';
spool off

spool 'c:\mighdc\alert\grants\table_abnormality.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ABNORMALITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ABNORMALITY';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_loinc_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_LOINC_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_LOINC_TEMPLATE';
spool off


spool 'c:\mighdc\alert\grants\table_analysis_req_par.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ_PAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ_PAR';
spool off

spool 'c:\mighdc\alert\grants\table_building.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BUILDING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BUILDING';
spool off

spool 'c:\mighdc\alert\grants\table_clin_record.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_RECORD';
spool off

spool 'c:\mighdc\alert\grants\table_cli_rec_req.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_complete_history.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COMPLETE_HISTORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COMPLETE_HISTORY';
spool off

spool 'c:\mighdc\alert\grants\table_contraceptive.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONTRACEPTIVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONTRACEPTIVE';
spool off

spool 'c:\mighdc\alert\grants\table_critical_care_read.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CRITICAL_CARE_READ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CRITICAL_CARE_READ';

spool off

spool 'c:\mighdc\alert\grants\table_department.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPARTMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPARTMENT';
spool off

spool 'c:\mighdc\alert\grants\table_diagram_layout.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_LAYOUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_LAYOUT';
spool off

spool 'c:\mighdc\alert\grants\table_diagram_tools_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_TOOLS_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_TOOLS_GROUP';
spool off


spool 'c:\mighdc\alert\grants\table_discharge_dest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_DEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_DEST';
spool off

spool 'c:\mighdc\alert\grants\table_discharge_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_disch_prep_mesg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCH_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCH_PREP_MESG';
spool off


spool 'c:\mighdc\alert\grants\table_drug_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_BCK';
spool off

spool 'c:\mighdc\alert\grants\table_drug_pharma_class_link.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA_CLASS_LINK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA_CLASS_LINK';
spool off

spool 'c:\mighdc\alert\grants\table_drug_pharma_interaction.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA_INTERACTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA_INTERACTION';
spool off

spool 'c:\mighdc\alert\grants\table_drug_protocols.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_drug_take_time.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_TAKE_TIME','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_TAKE_TIME';
spool off

spool 'c:\mighdc\alert\grants\table_epis_bartchart.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BARTCHART','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BARTCHART';
spool off

spool 'c:\mighdc\alert\grants\table_epis_documentation_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DOCUMENTATION_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DOCUMENTATION_DET';

spool off

spool 'c:\mighdc\alert\grants\table_epis_recomend.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_RECOMEND','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_RECOMEND';
spool off

spool 'c:\mighdc\alert\grants\table_epis_triage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TRIAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TRIAGE';
spool off

spool 'c:\mighdc\alert\grants\table_exam_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_family_relationship_relat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FAMILY_RELATIONSHIP_RELAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FAMILY_RELATIONSHIP_RELAT';
spool off

spool 'c:\mighdc\alert\grants\table_floors.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS';
spool off

spool 'c:\mighdc\alert\grants\table_floors_dep_position.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS_DEP_POSITION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS_DEP_POSITION';
spool off


spool 'c:\mighdc\alert\grants\table_geo_location.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GEO_LOCATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GEO_LOCATION';
spool off

spool 'c:\mighdc\alert\grants\table_graffar_crit_value.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GRAFFAR_CRIT_VALUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GRAFFAR_CRIT_VALUE';
spool off

spool 'c:\mighdc\alert\grants\table_harvest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HARVEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HARVEST';
spool off

spool 'c:\mighdc\alert\grants\table_health_plan_instit.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEALTH_PLAN_INSTIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEALTH_PLAN_INSTIT';
spool off

spool 'c:\mighdc\alert\grants\table_hemo_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_composition.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPOSITION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPOSITION';
spool off

spool 'c:\mighdc\alert\grants\table_identification_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IDENTIFICATION_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IDENTIFICATION_NOTES';

spool off

spool 'c:\mighdc\alert\grants\table_inf_diabetes_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_DIABETES_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_DIABETES_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_inf_emb_unit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_EMB_UNIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_EMB_UNIT';
spool off

spool 'c:\mighdc\alert\grants\table_inf_form_farm.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_FORM_FARM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_FORM_FARM';
spool off


spool 'c:\mighdc\alert\grants\table_inf_grupo_hom.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_GRUPO_HOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_GRUPO_HOM';
spool off

spool 'c:\mighdc\alert\grants\table_inf_subst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_SUBST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_SUBST';
spool off

spool 'c:\mighdc\alert\grants\table_inf_tipo_preco.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_TIPO_PRECO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_TIPO_PRECO';
spool off


spool 'c:\mighdc\alert\grants\table_inp_error.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INP_ERROR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INP_ERROR';
spool off

spool 'c:\mighdc\alert\grants\table_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\table_java$class$md5$table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','JAVA$CLASS$MD5$TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'JAVA$CLASS$MD5$TABLE';
spool off

spool 'c:\mighdc\alert\grants\table_mcdt_req_diagnosis.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MCDT_REQ_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MCDT_REQ_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_pat_medication_list.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MEDICATION_LIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MEDICATION_LIST';
spool off

spool 'c:\mighdc\alert\grants\table_pat_pregn_fetus_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS_DET';
spool off

spool 'c:\mighdc\alert\grants\table_pat_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROBLEM';

spool off

spool 'c:\mighdc\alert\grants\table_prescription_print.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_PRINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_PRINT';
spool off

spool 'c:\mighdc\alert\grants\table_prof_access_bck2.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS_BCK2','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS_BCK2';
spool off

spool 'c:\mighdc\alert\grants\table_prof_doc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_DOC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_DOC';
spool off


spool 'c:\mighdc\alert\grants\table_profile_templ_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPL_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPL_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_profile_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_prof_in_out.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_IN_OUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_IN_OUT';
spool off


spool 'c:\mighdc\alert\grants\table_prof_team_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_TEAM_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_TEAM_DET';
spool off

spool 'c:\mighdc\alert\grants\table_p1_doc_external_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOC_EXTERNAL_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOC_EXTERNAL_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\table_records_review_read.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RECORDS_REVIEW_READ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RECORDS_REVIEW_READ';
spool off

spool 'c:\mighdc\alert\grants\table_room.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_rotation_interval.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROTATION_INTERVAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROTATION_INTERVAL';
spool off

spool 'c:\mighdc\alert\grants\table_sample_text_freq.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_FREQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_FREQ';
spool off

spool 'c:\mighdc\alert\grants\table_sample_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TYPE';

spool off

spool 'c:\mighdc\alert\grants\table_sch_cancel_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_CANCEL_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_CANCEL_REASON';
spool off

spool 'c:\mighdc\alert\grants\table_schedule_sr.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_SR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_SR';
spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_rule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_RULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_RULE';
spool off


spool 'c:\mighdc\alert\grants\table_sr_pat_status_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PAT_STATUS_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PAT_STATUS_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_sr_pos_eval_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POS_EVAL_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POS_EVAL_VISIT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_posit_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POSIT_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POSIT_REQ';
spool off


spool 'c:\mighdc\alert\grants\table_sr_pre_anest_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_ANEST_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_ANEST_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_pre_eval_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_EVAL_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_EVAL_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surgery_record.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_RECORD';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surgery_time.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_TIME','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_TIME';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surg_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_TASK';
spool off

spool 'c:\mighdc\alert\grants\table_sys_alert.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT';
spool off

spool 'c:\mighdc\alert\grants\table_sys_alert_software.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_SOFTWARE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_SOFTWARE';

spool off

spool 'c:\mighdc\alert\grants\table_sys_alert_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_sys_application_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_APPLICATION_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_APPLICATION_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_translation_bck_20061214.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSLATION_BCK_20061214','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSLATION_BCK_20061214';
spool off


spool 'c:\mighdc\alert\grants\table_vaccine_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\index_vbz$object_stats.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VBZ$OBJECT_STATS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VBZ$OBJECT_STATS';
spool off

spool 'c:\mighdc\alert\grants\table_vital_sign.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN';
spool off


spool 'c:\mighdc\alert\grants\table_vital_sign_read.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_READ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_READ';
spool off

spool 'c:\mighdc\alert\grants\table_vital_sign_unit_measure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_UNIT_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_UNIT_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\table_white_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WHITE_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WHITE_REASON';
spool off

spool 'c:\mighdc\alert\grants\table_wl_demo.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_DEMO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_DEMO';
spool off

spool 'c:\mighdc\alert\grants\table_wl_demo_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_DEMO_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_DEMO_BCK';
spool off

spool 'c:\mighdc\alert\grants\table_wound_eval_charac.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_EVAL_CHARAC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_EVAL_CHARAC';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_term.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_TERM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_TERM';

spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_classification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_CLASSIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_CLASSIFICATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_hemo_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEALTH_PLAN';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_epis_interv_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EPIS_INTERV_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EPIS_INTERV_DESC';
spool off

spool 'c:\mighdc\alert\grants\synonym_soft_inst_services.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFT_INST_SERVICES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFT_INST_SERVICES';
spool off

spool 'c:\mighdc\alert\grants\synonym_software.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFTWARE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFTWARE';
spool off


spool 'c:\mighdc\alert\grants\synonym_sch_resource.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_RESOURCE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_RESOURCE';
spool off

spool 'c:\mighdc\alert\grants\synonym_school.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHOOL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHOOL';
spool off

spool 'c:\mighdc\alert\grants\synonym_room_scheduled.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_SCHEDULED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_SCHEDULED';
spool off

spool 'c:\mighdc\alert\grants\synonym_quest_sl_temp_explain1.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','QUEST_SL_TEMP_EXPLAIN1','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'QUEST_SL_TEMP_EXPLAIN1';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_profile_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PROFILE_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PROFILE_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_in_out.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_IN_OUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_IN_OUT';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_FUNC';

spool off

spool 'c:\mighdc\alert\grants\synonym_wl_demo_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_DEMO_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_DEMO_BCK';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_demo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_DEMO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_DEMO';
spool off

spool 'c:\mighdc\alert\grants\synonym_vs_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VS_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VS_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\synonym_translation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSLATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSLATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_toad_plan_sql.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TOAD_PLAN_SQL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TOAD_PLAN_SQL';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_time_event_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_TIME_EVENT_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_TIME_EVENT_GROUP';
spool off


spool 'c:\mighdc\alert\grants\synonym_sys_message.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_MESSAGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_config.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_CONFIG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_CONFIG';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_btn_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BTN_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BTN_CRIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert_profile.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_PROFILE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_PROFILE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_prof_recov_schd.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PROF_RECOV_SCHD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PROF_RECOV_SCHD';
spool off

spool 'c:\mighdc\alert\grants\synonym_wound_eval_charac.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_EVAL_CHARAC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_EVAL_CHARAC';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_waiting_line_0104.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_LINE_0104','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_LINE_0104';

spool off

spool 'c:\mighdc\alert\grants\synonym_wl_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_STATUS';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_sick_leave.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_SICK_LEAVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_SICK_LEAVE';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_pregn_fetus_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS_DET';
spool off


spool 'c:\mighdc\alert\grants\synonym_pat_pregn_fetus_biom.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS_BIOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS_BIOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_pregnancy_risk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGNANCY_RISK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGNANCY_RISK';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_NOTES';
spool off


spool 'c:\mighdc\alert\grants\synonym_pat_med_decl.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MED_DECL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MED_DECL';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_documents.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOCUMENTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOCUMENTS';
spool off

spool 'c:\mighdc\alert\grants\synonym_opinion_prof.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OPINION_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OPINION_PROF';
spool off

spool 'c:\mighdc\alert\grants\synonym_monitorization.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_readmission.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_READMISSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_READMISSION';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROTOCOLS';

spool off

spool 'c:\mighdc\alert\grants\synonym_epis_observation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBSERVATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBSERVATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_man.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_MAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_MAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_body_painting_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BODY_PAINTING_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BODY_PAINTING_DET';
spool off


spool 'c:\mighdc\alert\grants\synonym_episode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPISODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPISODE';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_pharma_interaction.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA_INTERACTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA_INTERACTION';
spool off


spool 'c:\mighdc\alert\grants\synonym_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_req_par.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ_PAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ_PAR';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_harvest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_HARVEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_HARVEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_beye_view_screen.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BEYE_VIEW_SCREEN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BEYE_VIEW_SCREEN';
spool off

spool 'c:\mighdc\alert\grants\synonym_bed_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BED_SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BED_SCHEDULE';
spool off

spool 'c:\mighdc\alert\grants\synonym_origin_soft.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ORIGIN_SOFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ORIGIN_SOFT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERVENTION';

spool off

spool 'c:\mighdc\alert\grants\synonym_sr_equip.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EQUIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EQUIP';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_dimension.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_DIMENSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_DIMENSION';
spool off

spool 'c:\mighdc\alert\grants\synonym_document_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENT_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENT_AREA';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_documentation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DOCUMENTATION';
spool off

spool 'c:\mighdc\alert\grants\view_v_disch_reas_dest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','V_DISCH_REAS_DEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'V_DISCH_REAS_DEST';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sysconfig.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SYSCONFIG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SYSCONFIG';
spool off


spool 'c:\mighdc\alert\grants\package_pk_date_utils.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DATE_UTILS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DATE_UTILS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_adm_cs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_ADM_CS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_ADM_CS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_tools.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_TOOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_TOOLS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_positioning.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_POSITIONING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_POSITIONING';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_planning.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_PLANNING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_PLANNING';
spool off

spool 'c:\mighdc\alert\grants\package_pk_alerts.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_ALERTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_ALERTS';

spool off

spool 'c:\mighdc\alert\grants\package_pk_wlnur.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLNUR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLNUR';
spool off

spool 'c:\mighdc\alert\grants\package_pk_infarmed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INFARMED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INFARMED';
spool off

spool 'c:\mighdc\alert\grants\package_pk_woman_health.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WOMAN_HEALTH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WOMAN_HEALTH';
spool off


spool 'c:\mighdc\alert\grants\package_pk_edis_triage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_TRIAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_TRIAGE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_list.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_LIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_LIST';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_grid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_GRID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_GRID';
spool off


spool 'c:\mighdc\alert\grants\package_pk_nurse_activity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_NURSE_ACTIVITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_NURSE_ACTIVITY';
spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_core.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_CORE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_CORE';
spool off

spool 'c:\mighdc\alert\grants\trigger_manipulated_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANIPULATED_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANIPULATED_GROUP';
spool off

spool 'c:\mighdc\alert\grants\sequence_seq_presc_number_0102.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_NUMBER_0102','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_NUMBER_0102';
spool off

spool 'c:\mighdc\alert\grants\sequence_seq_presc_number_0124.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_NUMBER_0124','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_NUMBER_0124';
spool off

spool 'c:\mighdc\alert\grants\table_action_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ACTION_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ACTION_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ';

spool off

spool 'c:\mighdc\alert\grants\table_birds_eye_view.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BIRDS_EYE_VIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BIRDS_EYE_VIEW';
spool off

spool 'c:\mighdc\alert\grants\table_ch_contents.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CH_CONTENTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CH_CONTENTS';
spool off

spool 'c:\mighdc\alert\grants\table_complaint.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COMPLAINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COMPLAINT';
spool off


spool 'c:\mighdc\alert\grants\table_complaint_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COMPLAINT_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COMPLAINT_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_complaint_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COMPLAINT_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COMPLAINT_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_diagnosis_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGNOSIS_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGNOSIS_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_diagram.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM';
spool off

spool 'c:\mighdc\alert\grants\table_discharge_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_REASON';
spool off

spool 'c:\mighdc\alert\grants\table_disch_rea_transp_ent_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCH_REA_TRANSP_ENT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCH_REA_TRANSP_ENT_INST';
spool off

spool 'c:\mighdc\alert\grants\table_doc_action_criteria.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ACTION_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ACTION_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\table_doc_component.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_COMPONENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_COMPONENT';
spool off

spool 'c:\mighdc\alert\grants\table_doc_external.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_EXTERNAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_EXTERNAL';
spool off

spool 'c:\mighdc\alert\grants\table_doc_image.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_IMAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_IMAGE';

spool off

spool 'c:\mighdc\alert\grants\table_documentation_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG';
spool off

spool 'c:\mighdc\alert\grants\table_drug_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_drug_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_drug_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\table_epis_diagnosis_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DIAGNOSIS_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DIAGNOSIS_HIST';
spool off


spool 'c:\mighdc\alert\grants\table_epis_documentation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DOCUMENTATION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_obs_exam.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBS_EXAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBS_EXAM';
spool off

spool 'c:\mighdc\alert\grants\table_epis_positioning.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_POSITIONING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_POSITIONING';
spool off

spool 'c:\mighdc\alert\grants\table_epis_problem.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROBLEM';
spool off

spool 'c:\mighdc\alert\grants\table_epis_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_exam_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_exam_prep_mesg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_PREP_MESG';

spool off

spool 'c:\mighdc\alert\grants\table_exam_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_exam_result.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_RESULT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_RESULT';
spool off

spool 'c:\mighdc\alert\grants\table_ginec_obstet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GINEC_OBSTET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GINEC_OBSTET';
spool off


spool 'c:\mighdc\alert\grants\table_habit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HABIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HABIT';
spool off

spool 'c:\mighdc\alert\grants\table_hidrics_relation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HIDRICS_RELATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HIDRICS_RELATION';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_compo_folder.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_FOLDER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_FOLDER';
spool off


spool 'c:\mighdc\alert\grants\table_icnp_compo_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_INST';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_dictionary.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_DICTIONARY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_DICTIONARY';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_predefined_action_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_PREDEFINED_ACTION_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_PREDEFINED_ACTION_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_transition_state.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_TRANSITION_STATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_TRANSITION_STATE';
spool off

spool 'c:\mighdc\alert\grants\table_implementation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPLEMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPLEMENTATION';
spool off

spool 'c:\mighdc\alert\grants\table_import_analysis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_ANALYSIS';
spool off

spool 'c:\mighdc\alert\grants\table_import_mcdt_migra.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_MCDT_MIGRA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_MCDT_MIGRA';

spool off

spool 'c:\mighdc\alert\grants\table_import_mcdt_20060303.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_MCDT_20060303','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_MCDT_20060303';
spool off

spool 'c:\mighdc\alert\grants\table_inf_preco.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_PRECO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_PRECO';
spool off

spool 'c:\mighdc\alert\grants\table_instit_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INSTIT_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INSTIT_EXT_SYS';
spool off


spool 'c:\mighdc\alert\grants\table_interv_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_interv_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_match_epis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATCH_EPIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATCH_EPIS';
spool off


spool 'c:\mighdc\alert\grants\table_mdm_coding.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MDM_CODING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MDM_CODING';
spool off

spool 'c:\mighdc\alert\grants\table_movement.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MOVEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MOVEMENT';
spool off

spool 'c:\mighdc\alert\grants\table_nurse_actv_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_ACTV_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_ACTV_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\table_opinion_prof.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OPINION_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OPINION_PROF';
spool off

spool 'c:\mighdc\alert\grants\table_origin.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ORIGIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ORIGIN';
spool off

spool 'c:\mighdc\alert\grants\table_pat_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\table_pat_blood_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_BLOOD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_BLOOD_GROUP';

spool off

spool 'c:\mighdc\alert\grants\table_pat_family_member.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_MEMBER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_MEMBER';
spool off

spool 'c:\mighdc\alert\grants\table_pat_family_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_PROF';
spool off

spool 'c:\mighdc\alert\grants\table_pat_fam_soc_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAM_SOC_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAM_SOC_HIST';
spool off


spool 'c:\mighdc\alert\grants\table_pat_job.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_JOB','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_JOB';
spool off

spool 'c:\mighdc\alert\grants\table_pat_permission.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PERMISSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PERMISSION';
spool off

spool 'c:\mighdc\alert\grants\table_pat_pregnancy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGNANCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGNANCY';
spool off


spool 'c:\mighdc\alert\grants\table_pat_prob_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROB_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROB_VISIT';
spool off

spool 'c:\mighdc\alert\grants\table_pat_soc_attributes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_SOC_ATTRIBUTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_SOC_ATTRIBUTES';
spool off

spool 'c:\mighdc\alert\grants\table_positioning_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','POSITIONING_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'POSITIONING_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_prescription_type.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_prescription_xml_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_XML_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_XML_DET';
spool off

spool 'c:\mighdc\alert\grants\table_prof_access_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS_BCK';
spool off

spool 'c:\mighdc\alert\grants\table_profile_template_bck_agn.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPLATE_BCK_AGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPLATE_BCK_AGN';

spool off

spool 'c:\mighdc\alert\grants\table_prof_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PHOTO';
spool off

spool 'c:\mighdc\alert\grants\table_prof_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_p1_documents_done.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOCUMENTS_DONE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOCUMENTS_DONE';
spool off


spool 'c:\mighdc\alert\grants\table_p1_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PROBLEM';
spool off

spool 'c:\mighdc\alert\grants\table_p1_problem_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PROBLEM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PROBLEM_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_quest_temp_explain.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','QUEST_TEMP_EXPLAIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'QUEST_TEMP_EXPLAIN';
spool off


spool 'c:\mighdc\alert\grants\table_rb_profile_templ_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RB_PROFILE_TEMPL_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RB_PROFILE_TEMPL_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_rb_sys_button_prop.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RB_SYS_BUTTON_PROP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RB_SYS_BUTTON_PROP';
spool off

spool 'c:\mighdc\alert\grants\table_rep_prof_exception.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_PROF_EXCEPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_PROF_EXCEPTION';
spool off

spool 'c:\mighdc\alert\grants\table_rep_prof_templ_access.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_PROF_TEMPL_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_PROF_TEMPL_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_room_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_sample_text.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT';
spool off

spool 'c:\mighdc\alert\grants\table_scales_class.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCALES_CLASS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCALES_CLASS';

spool off

spool 'c:\mighdc\alert\grants\table_sch_action.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_ACTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_ACTION';
spool off

spool 'c:\mighdc\alert\grants\table_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE';
spool off

spool 'c:\mighdc\alert\grants\table_schedule_outp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_OUTP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_OUTP';
spool off


spool 'c:\mighdc\alert\grants\table_sch_log.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_LOG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_LOG';
spool off

spool 'c:\mighdc\alert\grants\table_sch_permission.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_PERMISSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_PERMISSION';
spool off

spool 'c:\mighdc\alert\grants\table_screen_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCREEN_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCREEN_TEMPLATE';
spool off


spool 'c:\mighdc\alert\grants\table_slot.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SLOT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SLOT';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_solution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_SOLUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_SOLUTION';
spool off

spool 'c:\mighdc\alert\grants\table_social_intervention.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\table_software_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFTWARE_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFTWARE_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\table_speciality.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SPECIALITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SPECIALITY';
spool off

spool 'c:\mighdc\alert\grants\table_sr_doc_element.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_DOC_ELEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_DOC_ELEMENT';

spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_sr_nurse_rec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_NURSE_REC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_NURSE_REC';
spool off

spool 'c:\mighdc\alert\grants\table_sr_receive.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE';
spool off


spool 'c:\mighdc\alert\grants\table_sys_alert_profile.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_PROFILE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_PROFILE';
spool off

spool 'c:\mighdc\alert\grants\table_sys_btn_sbg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BTN_SBG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BTN_SBG';
spool off

spool 'c:\mighdc\alert\grants\table_sys_button.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON';
spool off


spool 'c:\mighdc\alert\grants\table_sys_config.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_CONFIG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_CONFIG';
spool off

spool 'c:\mighdc\alert\grants\table_sys_functionality.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_FUNCTIONALITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_FUNCTIONALITY';
spool off

spool 'c:\mighdc\alert\grants\table_tests_review.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TESTS_REVIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TESTS_REVIEW';
spool off

spool 'c:\mighdc\alert\grants\table_tmp_nurse_summary.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TMP_NURSE_SUMMARY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TMP_NURSE_SUMMARY';
spool off

spool 'c:\mighdc\alert\grants\table_triage_board_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_BOARD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_BOARD_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_triage_color.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_COLOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_COLOR';
spool off

spool 'c:\mighdc\alert\grants\table_vaccine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE';

spool off

spool 'c:\mighdc\alert\grants\table_vaccine_presc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESC_DET';
spool off

spool 'c:\mighdc\alert\grants\table_viewer_refresh.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VIEWER_REFRESH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VIEWER_REFRESH';
spool off

spool 'c:\mighdc\alert\grants\table_viewer_synch_param.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VIEWER_SYNCH_PARAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VIEWER_SYNCH_PARAM';
spool off


spool 'c:\mighdc\alert\grants\table_vital_sign_relation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_RELATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_RELATION';
spool off

spool 'c:\mighdc\alert\grants\table_wl_patient_sonho_imp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO_IMP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO_IMP';
spool off

spool 'c:\mighdc\alert\grants\table_wl_prof_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PROF_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PROF_ROOM';
spool off


spool 'c:\mighdc\alert\grants\synonym_manchester.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANCHESTER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANCHESTER';
spool off

spool 'c:\mighdc\alert\grants\synonym_java$class$md5$table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','JAVA$CLASS$MD5$TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'JAVA$CLASS$MD5$TABLE';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_dep_clin_serv.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_predefined_action.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_PREDEFINED_ACTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_PREDEFINED_ACTION';

spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_compo_folder.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_FOLDER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_FOLDER';
spool off

spool 'c:\mighdc\alert\grants\synonym_home.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HOME','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HOME';
spool off

spool 'c:\mighdc\alert\grants\synonym_hemo_req_supply.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ_SUPPLY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ_SUPPLY';
spool off


spool 'c:\mighdc\alert\grants\synonym_grid_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GRID_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GRID_TASK';
spool off

spool 'c:\mighdc\alert\grants\synonym_external_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXTERNAL_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXTERNAL_SYS';
spool off

spool 'c:\mighdc\alert\grants\synonym_estate.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ESTATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ESTATE';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_chklist_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_slot.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SLOT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SLOT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sch_service.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_SERVICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_SERVICE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sch_prof_outp.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_PROF_OUTP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_PROF_OUTP';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_text_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_text_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_PROF';
spool off

spool 'c:\mighdc\alert\grants\synonym_religion.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RELIGION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RELIGION';

spool off

spool 'c:\mighdc\alert\grants\synonym_quest_temp_explain.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','QUEST_TEMP_EXPLAIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'QUEST_TEMP_EXPLAIN';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_professional.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFESSIONAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFESSIONAL';
spool off


spool 'c:\mighdc\alert\grants\synonym_prep_message.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PREP_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PREP_MESSAGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_pregnancy_risk_eval.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PREGNANCY_RISK_EVAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PREGNANCY_RISK_EVAL';
spool off

spool 'c:\mighdc\alert\grants\synonym_periodic_exam_educ.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PERIODIC_EXAM_EDUC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PERIODIC_EXAM_EDUC';
spool off


spool 'c:\mighdc\alert\grants\synonym_wl_machine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MACHINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MACHINE';
spool off

spool 'c:\mighdc\alert\grants\synonym_white_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WHITE_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WHITE_REASON';
spool off

spool 'c:\mighdc\alert\grants\synonym_vital_sign_relation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_RELATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_RELATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_transportation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSPORTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSPORTATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_toolbar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_TOOLBAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_TOOLBAR';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_message_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_MESSAGE_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_MESSAGE_BCK';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_field.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_FIELD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_FIELD';

spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert_software.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_SOFTWARE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_SOFTWARE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_PROF';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surg_prot_task_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_TASK_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_TASK_DET';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_surg_prot_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_waiting_line.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_LINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_LINE';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_QUEUE';
spool off


spool 'c:\mighdc\alert\grants\synonym_wl_patient_sonho_transfered.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO_TRANSFERED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO_TRANSFERED';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_permission.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PERMISSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PERMISSION';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_family.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_cli_attributes.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CLI_ATTRIBUTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CLI_ATTRIBUTES';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_blood_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_BLOOD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_BLOOD_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_allergy_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_ALLERGY_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_ALLERGY_HIST';
spool off

spool 'c:\mighdc\alert\grants\synonym_parameter_analysis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PARAMETER_ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PARAMETER_ANALYSIS';

spool off

spool 'c:\mighdc\alert\grants\synonym_nurse_actv_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_ACTV_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_ACTV_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_nurse_activity_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_ACTIVITY_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_ACTIVITY_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_obs_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBS_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBS_PHOTO';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_drug_usage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DRUG_USAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DRUG_USAGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DIAGNOSIS';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_anamnesis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_ANAMNESIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_ANAMNESIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_take_time.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_TAKE_TIME','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_TAKE_TIME';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_req_supply.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ_SUPPLY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ_SUPPLY';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_protocols.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_pharma.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_disc_help.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISC_HELP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISC_HELP';

spool off

spool 'c:\mighdc\alert\grants\synonym_diagnosis_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGNOSIS_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGNOSIS_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_param.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PARAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PARAM';
spool off

spool 'c:\mighdc\alert\grants\synonym_ch_contents.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CH_CONTENTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CH_CONTENTS';
spool off


spool 'c:\mighdc\alert\grants\synonym_body_part_image.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BODY_PART_IMAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BODY_PART_IMAGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_body_part.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BODY_PART','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BODY_PART';
spool off

spool 'c:\mighdc\alert\grants\synonym_board_grouping.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD_GROUPING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD_GROUPING';
spool off


spool 'c:\mighdc\alert\grants\synonym_analysis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_documentation_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_quantification.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_QUANTIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_QUANTIFICATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_element_quantif.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_QUANTIF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_QUANTIF';
spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_sync.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_SYNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_SYNC';
spool off

spool 'c:\mighdc\alert\grants\package_pk_episode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EPISODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EPISODE';

spool off

spool 'c:\mighdc\alert\grants\package_pk_movement.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_MOVEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_MOVEMENT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_login.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_LOGIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_LOGIN';
spool off

spool 'c:\mighdc\alert\grants\package_pk_documentation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DOCUMENTATION';
spool off


spool 'c:\mighdc\alert\grants\package_pk_inp_hidrics.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_HIDRICS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_HIDRICS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_episode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_EPISODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_EPISODE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_utils.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_UTILS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_UTILS';
spool off


spool 'c:\mighdc\alert\grants\package_pk_edis_summary.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_SUMMARY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_SUMMARY';
spool off

spool 'c:\mighdc\alert\grants\package_pk_doc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DOC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DOC';
spool off

spool 'c:\mighdc\alert\grants\package_pk_match.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_MATCH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_MATCH';
spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_grid.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_GRID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_GRID';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wlfinger_print.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLFINGER_PRINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLFINGER_PRINT';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_agp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_AGP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_AGP';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_old.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_OLD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_OLD';

spool off

spool 'c:\mighdc\alert\grants\table_anesthesia_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANESTHESIA_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANESTHESIA_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_board_grouping.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD_GROUPING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD_GROUPING';
spool off

spool 'c:\mighdc\alert\grants\table_category.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CATEGORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CATEGORY';
spool off


spool 'c:\mighdc\alert\grants\table_clin_srv_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_SRV_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_SRV_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_cli_rec_req_mov.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ_MOV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ_MOV';
spool off

spool 'c:\mighdc\alert\grants\table_consult_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONSULT_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONSULT_REQ';
spool off


spool 'c:\mighdc\alert\grants\table_consult_req_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONSULT_REQ_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONSULT_REQ_PROF';
spool off

spool 'c:\mighdc\alert\grants\table_create$java$lob$table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CREATE$JAVA$LOB$TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CREATE$JAVA$LOB$TABLE';
spool off

spool 'c:\mighdc\alert\grants\table_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\table_critical_care.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CRITICAL_CARE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CRITICAL_CARE';
spool off

spool 'c:\mighdc\alert\grants\table_critical_care_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CRITICAL_CARE_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CRITICAL_CARE_DET';
spool off

spool 'c:\mighdc\alert\grants\table_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_diagram_detail.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_DETAIL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_DETAIL';

spool off

spool 'c:\mighdc\alert\grants\table_diagram_tools.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_TOOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_TOOLS';
spool off

spool 'c:\mighdc\alert\grants\table_disc_help.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISC_HELP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISC_HELP';
spool off

spool 'c:\mighdc\alert\grants\table_district.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISTRICT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISTRICT';
spool off


spool 'c:\mighdc\alert\grants\table_doc_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_AREA';
spool off

spool 'c:\mighdc\alert\grants\table_doc_element.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT';
spool off

spool 'c:\mighdc\alert\grants\table_drug_brand.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_BRAND','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_BRAND';
spool off


spool 'c:\mighdc\alert\grants\table_drug_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_body_painting_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BODY_PAINTING_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BODY_PAINTING_DET';
spool off

spool 'c:\mighdc\alert\grants\table_epis_complaint.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_COMPLAINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_COMPLAINT';
spool off

spool 'c:\mighdc\alert\grants\table_estate.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ESTATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ESTATE';
spool off

spool 'c:\mighdc\alert\grants\table_exam_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_external_cause.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXTERNAL_CAUSE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXTERNAL_CAUSE';
spool off

spool 'c:\mighdc\alert\grants\table_home.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HOME','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HOME';

spool off

spool 'c:\mighdc\alert\grants\table_icnp_classification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_CLASSIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_CLASSIFICATION';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_diagnosis_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAGNOSIS_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAGNOSIS_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_folder_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_FOLDER_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_FOLDER_060425';
spool off


spool 'c:\mighdc\alert\grants\table_inf_atc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_ATC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_ATC';
spool off

spool 'c:\mighdc\alert\grants\table_inf_cft.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_CFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_CFT';
spool off

spool 'c:\mighdc\alert\grants\table_inf_dcipt.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_DCIPT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_DCIPT';
spool off


spool 'c:\mighdc\alert\grants\table_inf_diploma.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_DIPLOMA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_DIPLOMA';
spool off

spool 'c:\mighdc\alert\grants\table_inf_tratamento.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_TRATAMENTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_TRATAMENTO';
spool off

spool 'c:\mighdc\alert\grants\table_interv_physiatry_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PHYSIATRY_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PHYSIATRY_AREA';
spool off

spool 'c:\mighdc\alert\grants\table_interv_presc_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESC_DET';
spool off

spool 'c:\mighdc\alert\grants\table_interv_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_language.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','LANGUAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'LANGUAGE';
spool off

spool 'c:\mighdc\alert\grants\table_manchester.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANCHESTER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANCHESTER';

spool off

spool 'c:\mighdc\alert\grants\table_manipulated.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANIPULATED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANIPULATED';
spool off

spool 'c:\mighdc\alert\grants\table_manipulated_ingredient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANIPULATED_INGREDIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANIPULATED_INGREDIENT';
spool off

spool 'c:\mighdc\alert\grants\table_material.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL';
spool off


spool 'c:\mighdc\alert\grants\table_material_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_mdm_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MDM_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MDM_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\table_monitorization.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION';
spool off


spool 'c:\mighdc\alert\grants\table_pat_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_pat_vaccine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_VACCINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_VACCINE';
spool off

spool 'c:\mighdc\alert\grants\table_positioning.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','POSITIONING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'POSITIONING';
spool off

spool 'c:\mighdc\alert\grants\table_prof_access.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_prof_soft_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_SOFT_INST';
spool off

spool 'c:\mighdc\alert\grants\table_prof_team.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_TEAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_TEAM';
spool off

spool 'c:\mighdc\alert\grants\table_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROTOCOLS';

spool off

spool 'c:\mighdc\alert\grants\table_p1_history.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_HISTORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_HISTORY';
spool off

spool 'c:\mighdc\alert\grants\table_p1_prblm_rec_procedure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PRBLM_REC_PROCEDURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PRBLM_REC_PROCEDURE';
spool off

spool 'c:\mighdc\alert\grants\table_p1_recomended_procedure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_RECOMENDED_PROCEDURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_RECOMENDED_PROCEDURE';
spool off


spool 'c:\mighdc\alert\grants\table_recm.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RECM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RECM';
spool off

spool 'c:\mighdc\alert\grants\table_rep_section.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_SECTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_SECTION';
spool off

spool 'c:\mighdc\alert\grants\table_room_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_snomed_descriptions.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_DESCRIPTIONS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_DESCRIPTIONS';
spool off

spool 'c:\mighdc\alert\grants\table_social_class.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_CLASS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_CLASS';
spool off

spool 'c:\mighdc\alert\grants\table_social_episode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPISODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPISODE';
spool off

spool 'c:\mighdc\alert\grants\table_soft_lang.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFT_LANG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFT_LANG';
spool off

spool 'c:\mighdc\alert\grants\table_sr_chklist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST';
spool off

spool 'c:\mighdc\alert\grants\table_sr_interv_group_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERV_GROUP_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERV_GROUP_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_pat_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PAT_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PAT_STATUS';

spool off

spool 'c:\mighdc\alert\grants\table_sr_pre_eval.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_EVAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_EVAL';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surg_protocol.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROTOCOL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROTOCOL';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surg_prot_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_TASK';
spool off


spool 'c:\mighdc\alert\grants\table_sys_session.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SESSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SESSION';
spool off

spool 'c:\mighdc\alert\grants\table_sys_toolbar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_TOOLBAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_TOOLBAR';
spool off

spool 'c:\mighdc\alert\grants\table_time_unit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TIME_UNIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TIME_UNIT';
spool off


spool 'c:\mighdc\alert\grants\table_toad_plan_table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TOAD_PLAN_TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TOAD_PLAN_TABLE';
spool off

spool 'c:\mighdc\alert\grants\table_transp_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_treatment_management.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TREATMENT_MANAGEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TREATMENT_MANAGEMENT';
spool off

spool 'c:\mighdc\alert\grants\table_viewer_synchronize.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VIEWER_SYNCHRONIZE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VIEWER_SYNCHRONIZE';
spool off

spool 'c:\mighdc\alert\grants\table_wl_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_QUEUE';
spool off

spool 'c:\mighdc\alert\grants\synonym_adverse_exam_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ADVERSE_EXAM_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ADVERSE_EXAM_ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\synonym_material_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_TYPE';

spool off

spool 'c:\mighdc\alert\grants\synonym_material_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_isencao.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ISENCAO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ISENCAO';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_dictionary.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_DICTIONARY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_DICTIONARY';
spool off


spool 'c:\mighdc\alert\grants\synonym_icnp_composition_term.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPOSITION_TERM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPOSITION_TERM';
spool off

spool 'c:\mighdc\alert\grants\synonym_hemo_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_hemo_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_PROTOCOLS';
spool off


spool 'c:\mighdc\alert\grants\synonym_exam_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_DRUG';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_recipient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_RECIPIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_RECIPIENT';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_photo.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PHOTO';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_cat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_CAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_CAT';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_patient_sonho.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO';
spool off

spool 'c:\mighdc\alert\grants\synonym_vital_sign.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN';

spool off

spool 'c:\mighdc\alert\grants\synonym_vaccine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE';
spool off

spool 'c:\mighdc\alert\grants\synonym_transp_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_toad_plan_table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TOAD_PLAN_TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TOAD_PLAN_TABLE';
spool off


spool 'c:\mighdc\alert\grants\synonym_sys_application_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_APPLICATION_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_APPLICATION_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surgery_record.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_RECORD';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_receive_proc_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC_NOTES';
spool off


spool 'c:\mighdc\alert\grants\synonym_wound_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_waiting_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_necessity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_NECESSITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_NECESSITY';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_job.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_JOB','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_JOB';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_ginec_obstet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_GINEC_OBSTET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_GINEC_OBSTET';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_family_member.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_MEMBER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_MEMBER';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_doc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_DOC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_DOC';

spool off

spool 'c:\mighdc\alert\grants\synonym_pat_delivery.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_DELIVERY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_DELIVERY';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_child_clin_rec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CHILD_CLIN_REC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CHILD_CLIN_REC';
spool off

spool 'c:\mighdc\alert\grants\synonym_necessity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NECESSITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NECESSITY';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TASK';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_recomend.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_RECOMEND','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_RECOMEND';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_obs_exam.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBS_EXAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBS_EXAM';
spool off


spool 'c:\mighdc\alert\grants\synonym_drug_presc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESC_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_discharge_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_REASON';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_prep_mesg.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PREP_MESG';
spool off

spool 'c:\mighdc\alert\grants\synonym_consult_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONSULT_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONSULT_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_dependency.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPENDENCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPENDENCY';
spool off

spool 'c:\mighdc\alert\grants\synonym_bed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BED';

spool off

spool 'c:\mighdc\alert\grants\synonym_analy_parm_limit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALY_PARM_LIMIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALY_PARM_LIMIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ALLERGY';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_pos_eval_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POS_EVAL_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POS_EVAL_VISIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_pos_eval_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POS_EVAL_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POS_EVAL_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_reserv_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RESERV_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RESERV_REQ';
spool off


spool 'c:\mighdc\alert\grants\synonym_documentation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_triage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TRIAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TRIAGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_triage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_evaluation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\package_pk_reset.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_RESET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_RESET';
spool off

spool 'c:\mighdc\alert\grants\package_pk_patphoto.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PATPHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PATPHOTO';
spool off

spool 'c:\mighdc\alert\grants\package_pk_vital_sign.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_VITAL_SIGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_VITAL_SIGN';

spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_reset.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_RESET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_RESET';
spool off

spool 'c:\mighdc\alert\grants\package_pk_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_clinical_info.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_CLINICAL_INFO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_CLINICAL_INFO';
spool off


spool 'c:\mighdc\alert\grants\package_pk_history.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_HISTORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_HISTORY';
spool off

spool 'c:\mighdc\alert\grants\package_pk_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sysdomain.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SYSDOMAIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SYSDOMAIN';
spool off


spool 'c:\mighdc\alert\grants\package_pk_wlmed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLMED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLMED';
spool off

spool 'c:\mighdc\alert\grants\package_pk_consult_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_CONSULT_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_CONSULT_REQ';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_grid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_GRID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_GRID';
spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_discharge.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\package_rpe_experiencias.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RPE_EXPERIENCIAS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RPE_EXPERIENCIAS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wladm.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLADM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLADM';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wlcore.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLCORE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLCORE';

spool off

spool 'c:\mighdc\alert\grants\package_pk_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DRUG';
spool off

spool 'c:\mighdc\alert\grants\package_pk_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SCHEDULE';
spool off


spool 'c:\mighdc\alert\grants\sequence_seq_presc_number_0083.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_NUMBER_0083','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_NUMBER_0083';
spool off

spool 'c:\mighdc\alert\grants\type_table_varchar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TABLE_VARCHAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TABLE_VARCHAR';
spool off

spool 'c:\mighdc\alert\grants\type_profissional.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFISSIONAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFISSIONAL';
spool off

spool 'c:\mighdc\alert\grants\table_analysis.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_dep_clin_serv_old.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_DEP_CLIN_SERV_OLD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_DEP_CLIN_SERV_OLD';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_DESC';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_GROUP';

spool off

spool 'c:\mighdc\alert\grants\table_analysis_harvest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_HARVEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_HARVEST';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_loinc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_LOINC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_LOINC';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PROTOCOLS';
spool off


spool 'c:\mighdc\alert\grants\table_analysis_unit_measure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_UNIT_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_UNIT_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\table_body_part_image.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BODY_PART_IMAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BODY_PART_IMAGE';
spool off

spool 'c:\mighdc\alert\grants\table_bp_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_dep_clin_serv_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEP_CLIN_SERV_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEP_CLIN_SERV_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_dimension.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIMENSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIMENSION';
spool off

spool 'c:\mighdc\alert\grants\table_discriminator.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCRIMINATOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCRIMINATOR';
spool off

spool 'c:\mighdc\alert\grants\table_documentation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION';
spool off

spool 'c:\mighdc\alert\grants\table_documentation_rel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION_REL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION_REL';
spool off

spool 'c:\mighdc\alert\grants\table_drug_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_drug_presc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESC_DET';

spool off

spool 'c:\mighdc\alert\grants\table_drug_req_supply.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ_SUPPLY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ_SUPPLY';
spool off

spool 'c:\mighdc\alert\grants\table_emb_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EMB_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EMB_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_epis_body_painting.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BODY_PAINTING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BODY_PAINTING';
spool off


spool 'c:\mighdc\alert\grants\table_epis_hidrics_balance.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_HIDRICS_BALANCE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_HIDRICS_BALANCE';
spool off

spool 'c:\mighdc\alert\grants\table_episode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPISODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPISODE';
spool off

spool 'c:\mighdc\alert\grants\table_epis_prof_rec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROF_REC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROF_REC';
spool off


spool 'c:\mighdc\alert\grants\table_epis_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TASK';
spool off

spool 'c:\mighdc\alert\grants\table_epis_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_exam_cat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_CAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_CAT';
spool off

spool 'c:\mighdc\alert\grants\table_floors_department.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS_DEPARTMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS_DEPARTMENT';
spool off

spool 'c:\mighdc\alert\grants\table_floors_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\table_hemo_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_compo_dcs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_DCS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_DCS';

spool off

spool 'c:\mighdc\alert\grants\table_icnp_composition_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPOSITION_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPOSITION_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_folder.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_FOLDER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_FOLDER';
spool off


spool 'c:\mighdc\alert\grants\table_import_mcdt.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_MCDT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_MCDT';
spool off

spool 'c:\mighdc\alert\grants\table_inf_cft_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_CFT_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_CFT_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_inf_class_disp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_CLASS_DISP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_CLASS_DISP';
spool off


spool 'c:\mighdc\alert\grants\table_inf_comerc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_COMERC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_COMERC';
spool off

spool 'c:\mighdc\alert\grants\table_inf_emb.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_EMB','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_EMB';
spool off

spool 'c:\mighdc\alert\grants\table_inf_patol_esp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_PATOL_ESP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_PATOL_ESP';
spool off

spool 'c:\mighdc\alert\grants\table_inf_subst_lnk.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_SUBST_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_SUBST_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_inf_tipo_prod.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_TIPO_PROD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_TIPO_PROD';
spool off

spool 'c:\mighdc\alert\grants\table_inf_vias_admin_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_VIAS_ADMIN_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_VIAS_ADMIN_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_ingredient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INGREDIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INGREDIENT';

spool off

spool 'c:\mighdc\alert\grants\table_inp_log.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INP_LOG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INP_LOG';
spool off

spool 'c:\mighdc\alert\grants\table_interv_prep_msg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PREP_MSG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PREP_MSG';
spool off

spool 'c:\mighdc\alert\grants\table_material_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_REQ';
spool off


spool 'c:\mighdc\alert\grants\table_pat_cli_attributes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CLI_ATTRIBUTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CLI_ATTRIBUTES';
spool off

spool 'c:\mighdc\alert\grants\table_pat_family.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY';
spool off

spool 'c:\mighdc\alert\grants\table_pat_ginec_obstet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_GINEC_OBSTET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_GINEC_OBSTET';
spool off


spool 'c:\mighdc\alert\grants\table_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\table_prev_episodes_temp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PREV_EPISODES_TEMP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PREV_EPISODES_TEMP';
spool off

spool 'c:\mighdc\alert\grants\table_p1_documents.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOCUMENTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOCUMENTS';
spool off

spool 'c:\mighdc\alert\grants\table_p1_external_request.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_EXTERNAL_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_EXTERNAL_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\table_reports_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REPORTS_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REPORTS_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_rep_profile_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_PROFILE_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_PROFILE_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_room_dep_position.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_DEP_POSITION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_DEP_POSITION';

spool off

spool 'c:\mighdc\alert\grants\table_sample_text_type_cat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_TYPE_CAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_TYPE_CAT';
spool off

spool 'c:\mighdc\alert\grants\table_sch_cancel_reason_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_CANCEL_REASON_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_CANCEL_REASON_INST';
spool off

spool 'c:\mighdc\alert\grants\table_sch_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_GROUP';
spool off


spool 'c:\mighdc\alert\grants\table_scholarship.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHOLARSHIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHOLARSHIP';
spool off

spool 'c:\mighdc\alert\grants\table_school.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHOOL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHOOL';
spool off

spool 'c:\mighdc\alert\grants\table_sch_permission_temp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_PERMISSION_TEMP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_PERMISSION_TEMP';
spool off


spool 'c:\mighdc\alert\grants\table_sch_service_dcs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_SERVICE_DCS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_SERVICE_DCS';
spool off

spool 'c:\mighdc\alert\grants\table_snomed_relationships.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_RELATIONSHIPS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_RELATIONSHIPS';
spool off

spool 'c:\mighdc\alert\grants\table_social_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_soft_inst_impl.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFT_INST_IMPL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFT_INST_IMPL';
spool off

spool 'c:\mighdc\alert\grants\table_software_dept.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFTWARE_DEPT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFTWARE_DEPT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_cancel_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CANCEL_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CANCEL_REASON';
spool off

spool 'c:\mighdc\alert\grants\table_sr_equip.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EQUIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EQUIP';

spool off

spool 'c:\mighdc\alert\grants\table_sr_pat_status_period.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PAT_STATUS_PERIOD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PAT_STATUS_PERIOD';
spool off

spool 'c:\mighdc\alert\grants\table_sr_pre_anest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_ANEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_ANEST';
spool off

spool 'c:\mighdc\alert\grants\table_sr_prof_recov_schd.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PROF_RECOV_SCHD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PROF_RECOV_SCHD';
spool off


spool 'c:\mighdc\alert\grants\table_sr_surg_prot_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sys_appar_organ.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_APPAR_ORGAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_APPAR_ORGAN';
spool off

spool 'c:\mighdc\alert\grants\table_sys_error.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ERROR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ERROR';
spool off


spool 'c:\mighdc\alert\grants\table_sys_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\table_toad_plan_sql.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TOAD_PLAN_SQL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TOAD_PLAN_SQL';
spool off

spool 'c:\mighdc\alert\grants\table_transportation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSPORTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSPORTATION';
spool off

spool 'c:\mighdc\alert\grants\table_transport_type.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSPORT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSPORT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_triage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE';
spool off

spool 'c:\mighdc\alert\grants\table_triage_discriminator.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_DISCRIMINATOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_DISCRIMINATOR';
spool off

spool 'c:\mighdc\alert\grants\table_unit_mea_soft_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','UNIT_MEA_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'UNIT_MEA_SOFT_INST';

spool off

spool 'c:\mighdc\alert\grants\table_vaccine_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_viewer.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VIEWER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VIEWER';
spool off

spool 'c:\mighdc\alert\grants\table_wl_machine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MACHINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MACHINE';
spool off


spool 'c:\mighdc\alert\grants\synonym_matr_scheduled.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_SCHEDULED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_SCHEDULED';
spool off

spool 'c:\mighdc\alert\grants\synonym_material_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\synonym_language.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','LANGUAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'LANGUAGE';
spool off


spool 'c:\mighdc\alert\grants\synonym_icnp_epis_diag_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAG_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAG_INTERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_hemo_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_habit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HABIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HABIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_interv_desc.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERV_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERV_DESC';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_chklist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST';
spool off

spool 'c:\mighdc\alert\grants\synonym_spec_sys_appar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SPEC_SYS_APPAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SPEC_SYS_APPAR';
spool off

spool 'c:\mighdc\alert\grants\synonym_speciality.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SPECIALITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SPECIALITY';

spool off

spool 'c:\mighdc\alert\grants\synonym_snomed_relationships.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_RELATIONSHIPS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_RELATIONSHIPS';
spool off

spool 'c:\mighdc\alert\grants\synonym_scholarship.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHOLARSHIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHOLARSHIP';
spool off

spool 'c:\mighdc\alert\grants\synonym_schedule_sr.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_SR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_SR';
spool off


spool 'c:\mighdc\alert\grants\synonym_schedule_alter.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_ALTER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_ALTER';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_preferences.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PREFERENCES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PREFERENCES';
spool off


spool 'c:\mighdc\alert\grants\synonym_prof_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_vital_sign_read.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_READ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_READ';
spool off

spool 'c:\mighdc\alert\grants\synonym_vital_sign_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_DESC';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_DET';

spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_prof_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PROF_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PROF_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_problem_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROBLEM_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROBLEM_HIST';
spool off


spool 'c:\mighdc\alert\grants\synonym_pat_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROBLEM';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_pregn_measure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_habit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HABIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HABIT';
spool off


spool 'c:\mighdc\alert\grants\synonym_pat_fam_soc_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAM_SOC_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAM_SOC_HIST';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_family_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_PROF';
spool off

spool 'c:\mighdc\alert\grants\synonym_origin.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ORIGIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ORIGIN';
spool off

spool 'c:\mighdc\alert\grants\synonym_opinion.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OPINION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OPINION';
spool off

spool 'c:\mighdc\alert\grants\synonym_nurse_tea_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_TEA_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_TEA_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_nurse_discharge.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PHOTO';

spool off

spool 'c:\mighdc\alert\grants\synonym_epis_info.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INFO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INFO';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_body_painting.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BODY_PAINTING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BODY_PAINTING';
spool off


spool 'c:\mighdc\alert\grants\synonym_drug_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PROTOCOLS';
spool off


spool 'c:\mighdc\alert\grants\synonym_child_feed_dev.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CHILD_FEED_DEV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CHILD_FEED_DEV';
spool off

spool 'c:\mighdc\alert\grants\synonym_cli_rec_req_mov.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ_MOV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ_MOV';
spool off

spool 'c:\mighdc\alert\grants\synonym_cli_rec_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_clin_record.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_RECORD';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_agp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_AGP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_AGP';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_pat_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PAT_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PAT_STATUS';

spool off

spool 'c:\mighdc\alert\grants\synonym_sr_pat_status_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PAT_STATUS_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PAT_STATUS_NOTES';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_pre_anest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_ANEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_ANEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_document_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENT_TYPE';
spool off


spool 'c:\mighdc\alert\grants\synonym_doc_element_qualif.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_QUALIF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_QUALIF';
spool off

spool 'c:\mighdc\alert\grants\synonym_triage_board_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_BOARD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_BOARD_GROUP';
spool off

spool 'c:\mighdc\alert\grants\package_pk_message.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_MESSAGE';
spool off


spool 'c:\mighdc\alert\grants\package_pk_biztalk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BIZTALK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BIZTALK';
spool off

spool 'c:\mighdc\alert\grants\package_pk_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_diet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_DIET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_DIET';
spool off

spool 'c:\mighdc\alert\grants\package_pk_login_message.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_LOGIN_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_LOGIN_MESSAGE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_backoffice.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BACKOFFICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BACKOFFICE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_VISIT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_clinical_record.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_CLINICAL_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_CLINICAL_RECORD';

spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_list.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_LIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_LIST';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_search.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_SEARCH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_SEARCH';
spool off

spool 'c:\mighdc\alert\grants\package_pk_medical_decision.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_MEDICAL_DECISION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_MEDICAL_DECISION';
spool off


spool 'c:\mighdc\alert\grants\package_pk_family.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_FAMILY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_FAMILY';
spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_tv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_TV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_TV';
spool off

spool 'c:\mighdc\alert\grants\package_pk_dmgr_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DMGR_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DMGR_HIST';
spool off


spool 'c:\mighdc\alert\grants\package_pk_diagram_new.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DIAGRAM_NEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DIAGRAM_NEW';
spool off

spool 'c:\mighdc\alert\grants\package_pk_doc_attach.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DOC_ATTACH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DOC_ATTACH';
spool off

spool 'c:\mighdc\alert\grants\package_pk_systracking.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SYSTRACKING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SYSTRACKING';
spool off

spool 'c:\mighdc\alert\grants\package_pk_beye_view.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BEYE_VIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BEYE_VIEW';
spool off

spool 'c:\mighdc\alert\grants\package_pk_hemo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_HEMO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_HEMO';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_clinical_info.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_CLINICAL_INFO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_CLINICAL_INFO';
spool off

spool 'c:\mighdc\alert\grants\package_pk_alert_er.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_ALERT_ER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_ALERT_ER';

spool off

spool 'c:\mighdc\alert\grants\package_pk_wlbackoffice.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLBACKOFFICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLBACKOFFICE';
spool off

spool 'c:\mighdc\alert\grants\sequence_seq_professional.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PROFESSIONAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PROFESSIONAL';
spool off

spool 'c:\mighdc\alert\grants\sequence_seq_presc_xml_0083.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_XML_0083','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_XML_0083';
spool off


spool 'c:\mighdc\alert\grants\synonym_table_number.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TABLE_NUMBER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TABLE_NUMBER';
spool off

spool 'c:\mighdc\alert\grants\table_allergy_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ALLERGY_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ALLERGY_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_analy_parm_limit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALY_PARM_LIMIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALY_PARM_LIMIT';
spool off


spool 'c:\mighdc\alert\grants\table_analysis_alias.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_ALIAS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_ALIAS';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_ext_sys_delete.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_EXT_SYS_DELETE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_EXT_SYS_DELETE';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_param_instit.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PARAM_INSTIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PARAM_INSTIT';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_protocols_old.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PROTOCOLS_OLD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PROTOCOLS_OLD';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\table_bed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BED';

spool off

spool 'c:\mighdc\alert\grants\table_diet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIET';
spool off

spool 'c:\mighdc\alert\grants\table_discharge.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\table_doc_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_CRITERIA';
spool off


spool 'c:\mighdc\alert\grants\table_doc_element_quantif.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_QUANTIF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_QUANTIF';
spool off

spool 'c:\mighdc\alert\grants\table_doc_original.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ORIGINAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ORIGINAL';
spool off

spool 'c:\mighdc\alert\grants\table_doc_qualification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_QUALIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_QUALIFICATION';
spool off


spool 'c:\mighdc\alert\grants\table_doc_template_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TEMPLATE_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TEMPLATE_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_doc_type_soft.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TYPE_SOFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TYPE_SOFT';
spool off

spool 'c:\mighdc\alert\grants\table_document_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_drug_despachos.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_DESPACHOS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_DESPACHOS';
spool off

spool 'c:\mighdc\alert\grants\table_drug_form.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_FORM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_FORM';
spool off

spool 'c:\mighdc\alert\grants\table_drug_instit_justification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_INSTIT_JUSTIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_INSTIT_JUSTIFICATION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_diet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DIET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DIET';

spool off

spool 'c:\mighdc\alert\grants\table_epis_hidrics.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_HIDRICS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_HIDRICS';
spool off

spool 'c:\mighdc\alert\grants\table_epis_info.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INFO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INFO';
spool off

spool 'c:\mighdc\alert\grants\table_epis_prof_resp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROF_RESP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROF_RESP';
spool off


spool 'c:\mighdc\alert\grants\table_epis_readmission.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_READMISSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_READMISSION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_type_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TYPE_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TYPE_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_exam.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM';
spool off


spool 'c:\mighdc\alert\grants\table_exam_cat_dcs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_CAT_DCS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_CAT_DCS';
spool off

spool 'c:\mighdc\alert\grants\table_exam_egp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_EGP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_EGP';
spool off

spool 'c:\mighdc\alert\grants\table_external_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXTERNAL_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXTERNAL_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_compo_clin_serv.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_compo_inst_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_INST_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_INST_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_diag_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAG_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAG_INTERV';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_relationship.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_RELATIONSHIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_RELATIONSHIP';

spool off

spool 'c:\mighdc\alert\grants\table_inf_atc_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_ATC_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_ATC_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_inf_dispo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_DISPO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_DISPO';
spool off

spool 'c:\mighdc\alert\grants\table_inf_estado_aim.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_ESTADO_AIM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_ESTADO_AIM';
spool off


spool 'c:\mighdc\alert\grants\table_inf_tipo_diab_mel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_TIPO_DIAB_MEL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_TIPO_DIAB_MEL';
spool off

spool 'c:\mighdc\alert\grants\table_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\table_interv_ext_sys_delete.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_EXT_SYS_DELETE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_EXT_SYS_DELETE';
spool off


spool 'c:\mighdc\alert\grants\table_lixo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','LIXO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'LIXO';
spool off

spool 'c:\mighdc\alert\grants\table_material_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_monitorization_vs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION_VS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION_VS';
spool off

spool 'c:\mighdc\alert\grants\table_nurse_discharge.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\table_nurse_tea_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_TEA_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_TEA_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_pat_child_feed_dev.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CHILD_FEED_DEV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CHILD_FEED_DEV';
spool off

spool 'c:\mighdc\alert\grants\table_pat_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HEALTH_PLAN';

spool off

spool 'c:\mighdc\alert\grants\table_pat_medication.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MEDICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MEDICATION';
spool off

spool 'c:\mighdc\alert\grants\table_pat_pregnancy_risk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGNANCY_RISK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGNANCY_RISK';
spool off

spool 'c:\mighdc\alert\grants\table_pat_tmp_remota.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_TMP_REMOTA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_TMP_REMOTA';
spool off


spool 'c:\mighdc\alert\grants\table_periodic_exam_educ.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PERIODIC_EXAM_EDUC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PERIODIC_EXAM_EDUC';
spool off

spool 'c:\mighdc\alert\grants\table_pregnancy_risk_eval.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PREGNANCY_RISK_EVAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PREGNANCY_RISK_EVAL';
spool off

spool 'c:\mighdc\alert\grants\table_prep_message.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PREP_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PREP_MESSAGE';
spool off


spool 'c:\mighdc\alert\grants\table_prescription_pharm_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_PHARM_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_PHARM_DET';
spool off

spool 'c:\mighdc\alert\grants\table_prescription_xml.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_XML','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_XML';
spool off

spool 'c:\mighdc\alert\grants\table_prof_access_bck1.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS_BCK1','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS_BCK1';
spool off

spool 'c:\mighdc\alert\grants\table_prof_cat.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_CAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_CAT';
spool off

spool 'c:\mighdc\alert\grants\table_prof_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\table_profile_templ_acc_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPL_ACC_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPL_ACC_FUNC';
spool off

spool 'c:\mighdc\alert\grants\table_prof_photo_medicomni.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PHOTO_MEDICOMNI','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PHOTO_MEDICOMNI';

spool off

spool 'c:\mighdc\alert\grants\table_quest_sl_temp_explain1.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','QUEST_SL_TEMP_EXPLAIN1','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'QUEST_SL_TEMP_EXPLAIN1';
spool off

spool 'c:\mighdc\alert\grants\table_rb_sys_button_prop2.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RB_SYS_BUTTON_PROP2','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RB_SYS_BUTTON_PROP2';
spool off

spool 'c:\mighdc\alert\grants\table_rep_destination.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_DESTINATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_DESTINATION';
spool off


spool 'c:\mighdc\alert\grants\table_sample_recipient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_RECIPIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_RECIPIENT';
spool off

spool 'c:\mighdc\alert\grants\table_scales_doc_value.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCALES_DOC_VALUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCALES_DOC_VALUE';
spool off

spool 'c:\mighdc\alert\grants\table_sch_consult_vacancy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_CONSULT_VACANCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_CONSULT_VACANCY';
spool off


spool 'c:\mighdc\alert\grants\table_sch_service.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_SERVICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_SERVICE';
spool off

spool 'c:\mighdc\alert\grants\table_sr_chklist_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_doc_element_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_DOC_ELEMENT_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_DOC_ELEMENT_CRIT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_interv_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERV_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERV_DESC';
spool off

spool 'c:\mighdc\alert\grants\table_sr_prof_team_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PROF_TEAM_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PROF_TEAM_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_receive_proc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC';

spool off

spool 'c:\mighdc\alert\grants\table_sr_receive_proc_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_sr_reserv_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RESERV_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RESERV_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surg_period.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PERIOD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PERIOD';
spool off


spool 'c:\mighdc\alert\grants\table_sr_surg_prot_task_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_TASK_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_TASK_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sys_btn_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BTN_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BTN_CRIT';
spool off

spool 'c:\mighdc\alert\grants\table_sys_button_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON_GROUP';
spool off


spool 'c:\mighdc\alert\grants\table_sys_button_prop.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON_PROP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON_PROP';
spool off

spool 'c:\mighdc\alert\grants\table_sys_domain.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_DOMAIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_DOMAIN';
spool off

spool 'c:\mighdc\alert\grants\table_sys_message_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_MESSAGE_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_MESSAGE_BCK';
spool off

spool 'c:\mighdc\alert\grants\table_sys_shortcut.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SHORTCUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SHORTCUT';
spool off

spool 'c:\mighdc\alert\grants\table_system_organ.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYSTEM_ORGAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYSTEM_ORGAN';
spool off

spool 'c:\mighdc\alert\grants\table_sys_vital_sign.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_VITAL_SIGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_VITAL_SIGN';
spool off

spool 'c:\mighdc\alert\grants\table_triage_disc_vs_valid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_DISC_VS_VALID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_DISC_VS_VALID';

spool off

spool 'c:\mighdc\alert\grants\table_vaccine_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\table_vbz$object_stats.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VBZ$OBJECT_STATS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VBZ$OBJECT_STATS';
spool off

spool 'c:\mighdc\alert\grants\table_vital_sign_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_NOTES';
spool off


spool 'c:\mighdc\alert\grants\table_vital_sign_read_error.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_READ_ERROR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_READ_ERROR';
spool off

spool 'c:\mighdc\alert\grants\table_wl_call_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_CALL_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_CALL_QUEUE';
spool off

spool 'c:\mighdc\alert\grants\table_wl_patient_sonho.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO';
spool off


spool 'c:\mighdc\alert\grants\table_wl_patient_sonho_transfered.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO_TRANSFERED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO_TRANSFERED';
spool off

spool 'c:\mighdc\alert\grants\table_wl_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_STATUS';
spool off

spool 'c:\mighdc\alert\grants\table_wl_waiting_line_0104.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_LINE_0104','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_LINE_0104';
spool off

spool 'c:\mighdc\alert\grants\table_wound_evaluation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_java$options.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','JAVA$OPTIONS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'JAVA$OPTIONS';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_physiatry_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PHYSIATRY_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PHYSIATRY_AREA';
spool off

spool 'c:\mighdc\alert\grants\synonym_instit_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INSTIT_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INSTIT_EXT_SYS';

spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_epis_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_epis_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_cancel_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CANCEL_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CANCEL_REASON';
spool off

spool 'c:\mighdc\alert\grants\synonym_software_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFTWARE_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFTWARE_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_snomed_descriptions.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_DESCRIPTIONS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_DESCRIPTIONS';
spool off


spool 'c:\mighdc\alert\grants\synonym_snomed_concepts.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_CONCEPTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_CONCEPTS';
spool off

spool 'c:\mighdc\alert\grants\synonym_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_text_freq.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_FREQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_FREQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_text.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT';
spool off

spool 'c:\mighdc\alert\grants\synonym_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_team_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_TEAM_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_TEAM_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS';

spool off

spool 'c:\mighdc\alert\grants\synonym_vaccine_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_vaccine_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_transp_req_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_REQ_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_REQ_GROUP';
spool off


spool 'c:\mighdc\alert\grants\synonym_sys_session.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SESSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SESSION';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_error.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ERROR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ERROR';
spool off


spool 'c:\mighdc\alert\grants\synonym_sys_btn_sbg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BTN_SBG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BTN_SBG';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surg_protocol.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROTOCOL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROTOCOL';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_pregnancy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGNANCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGNANCY';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_photo.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PHOTO';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_medication.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MEDICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MEDICATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HEALTH_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_patient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PATIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PATIENT';

spool off

spool 'c:\mighdc\alert\grants\synonym_p1_problem_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PROBLEM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PROBLEM_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_prblm_rec_procedure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PRBLM_REC_PROCEDURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PRBLM_REC_PROCEDURE';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_history.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_HISTORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_HISTORY';
spool off


spool 'c:\mighdc\alert\grants\synonym_p1_ext_req_tracking.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_EXT_REQ_TRACKING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_EXT_REQ_TRACKING';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_doc_external.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOC_EXTERNAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOC_EXTERNAL';
spool off

spool 'c:\mighdc\alert\grants\synonym_movement.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MOVEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MOVEMENT';
spool off


spool 'c:\mighdc\alert\grants\synonym_drug_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_pharma_class.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA_CLASS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA_CLASS';
spool off

spool 'c:\mighdc\alert\grants\synonym_disch_reas_dest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCH_REAS_DEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCH_REAS_DEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_discharge.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_bp_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_clinical_service.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLINICAL_SERVICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLINICAL_SERVICE';
spool off

spool 'c:\mighdc\alert\grants\synonym_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEP_CLIN_SERV';

spool off

spool 'c:\mighdc\alert\grants\synonym_department.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPARTMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPARTMENT';
spool off

spool 'c:\mighdc\alert\grants\synonym_create$java$lob$table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CREATE$JAVA$LOB$TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CREATE$JAVA$LOB$TABLE';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_ROOM';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_chklist_manual.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST_MANUAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST_MANUAL';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_equip_kit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EQUIP_KIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EQUIP_KIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_eval_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_NOTES';
spool off


spool 'c:\mighdc\alert\grants\synonym_doc_element_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_CRIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_action_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ACTION_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ACTION_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\synonym_floors_dep_position.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS_DEP_POSITION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS_DEP_POSITION';
spool off

spool 'c:\mighdc\alert\grants\synonym_vs_soft_inst.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VS_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VS_SOFT_INST';
spool off

spool 'c:\mighdc\alert\grants\package_pk_types.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_TYPES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_TYPES';
spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_med_cs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_MED_CS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_MED_CS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_surg_record.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_SURG_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_SURG_RECORD';

spool off

spool 'c:\mighdc\alert\grants\package_pk_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_VISIT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inpatient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INPATIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INPATIENT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_documentation_new.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DOCUMENTATION_NEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DOCUMENTATION_NEW';
spool off


spool 'c:\mighdc\alert\grants\package_pk_sr_output.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_OUTPUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_OUTPUT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_search.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SEARCH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SEARCH';
spool off

spool 'c:\mighdc\alert\grants\package_pk_save.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SAVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SAVE';
spool off


spool 'c:\mighdc\alert\grants\package_pk_opinion.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_OPINION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_OPINION';
spool off

spool 'c:\mighdc\alert\grants\package_pk_viewer.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_VIEWER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_VIEWER';
spool off

spool 'c:\mighdc\alert\grants\package_pk_diagram.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DIAGRAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DIAGRAM';
spool off

spool 'c:\mighdc\alert\grants\package_pk_presc_fluids.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PRESC_FLUIDS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PRESC_FLUIDS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_icnp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_ICNP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_ICNP';
spool off

spool 'c:\mighdc\alert\grants\synonym_plan_table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PLAN_TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PLAN_TABLE';
spool off

spool 'c:\mighdc\alert\grants\synonym_dimension.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIMENSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIMENSION';

spool off

spool 'c:\mighdc\alert\grants\synonym_table_varchar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TABLE_VARCHAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TABLE_VARCHAR';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_agp_old.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_AGP_OLD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_AGP_OLD';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_parameter.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PARAMETER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PARAMETER';
spool off


spool 'c:\mighdc\alert\grants\table_analysis_param_instit_sample.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PARAM_INSTIT_SAMPLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PARAM_INSTIT_SAMPLE';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_prep_mesg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PREP_MESG';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_ROOM';
spool off


spool 'c:\mighdc\alert\grants\table_bed_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BED_SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BED_SCHEDULE';
spool off

spool 'c:\mighdc\alert\grants\table_beye_view_screen.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BEYE_VIEW_SCREEN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BEYE_VIEW_SCREEN';
spool off

spool 'c:\mighdc\alert\grants\table_body_part.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BODY_PART','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BODY_PART';
spool off

spool 'c:\mighdc\alert\grants\table_clin_serv_ext_sys.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_SERV_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_SERV_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_contra_indic.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONTRA_INDIC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONTRA_INDIC';
spool off

spool 'c:\mighdc\alert\grants\table_dept_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPT_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPT_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_diagram_image.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_IMAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_IMAGE';

spool off

spool 'c:\mighdc\alert\grants\table_diagram_lay_imag.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_LAY_IMAG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_LAY_IMAG';
spool off

spool 'c:\mighdc\alert\grants\table_discriminator_help.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCRIMINATOR_HELP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCRIMINATOR_HELP';
spool off

spool 'c:\mighdc\alert\grants\table_disc_vs_valid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISC_VS_VALID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISC_VS_VALID';
spool off


spool 'c:\mighdc\alert\grants\table_doc_destination.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_DESTINATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_DESTINATION';
spool off

spool 'c:\mighdc\alert\grants\table_doc_element_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_CRIT';
spool off

spool 'c:\mighdc\alert\grants\table_doc_quantification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_QUANTIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_QUANTIFICATION';
spool off


spool 'c:\mighdc\alert\grants\table_doc_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_document_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENT_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENT_AREA';
spool off

spool 'c:\mighdc\alert\grants\table_drug_despachos_soft_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_DESPACHOS_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_DESPACHOS_SOFT_INST';
spool off

spool 'c:\mighdc\alert\grants\table_drug_pharma.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA';
spool off

spool 'c:\mighdc\alert\grants\table_drug_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_drug_take_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_TAKE_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_TAKE_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_epis_anamnesis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_ANAMNESIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_ANAMNESIS';

spool off

spool 'c:\mighdc\alert\grants\table_epis_bartchart_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BARTCHART_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BARTCHART_DET';
spool off

spool 'c:\mighdc\alert\grants\table_epis_diagnosis_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DIAGNOSIS_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DIAGNOSIS_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_epis_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_HEALTH_PLAN';
spool off


spool 'c:\mighdc\alert\grants\table_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\table_epis_interval_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INTERVAL_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INTERVAL_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_epis_man.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_MAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_MAN';
spool off


spool 'c:\mighdc\alert\grants\table_epis_observation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBSERVATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBSERVATION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PHOTO';
spool off

spool 'c:\mighdc\alert\grants\table_epis_report_section.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_REPORT_SECTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_REPORT_SECTION';
spool off

spool 'c:\mighdc\alert\grants\table_exam_drug.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_DRUG';
spool off

spool 'c:\mighdc\alert\grants\table_grid_task_between.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GRID_TASK_BETWEEN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GRID_TASK_BETWEEN';
spool off

spool 'c:\mighdc\alert\grants\table_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEALTH_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_hemo_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ_DET';

spool off

spool 'c:\mighdc\alert\grants\table_hemo_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_hidrics.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HIDRICS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HIDRICS';
spool off

spool 'c:\mighdc\alert\grants\table_hidrics_interval.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HIDRICS_INTERVAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HIDRICS_INTERVAL';
spool off


spool 'c:\mighdc\alert\grants\table_icnp_compo_folder_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_FOLDER_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_FOLDER_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_morph.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_MORPH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_MORPH';
spool off


spool 'c:\mighdc\alert\grants\table_icnp_transition_state_060426.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_TRANSITION_STATE_060426','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_TRANSITION_STATE_060426';
spool off

spool 'c:\mighdc\alert\grants\table_inf_emb_comerc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_EMB_COMERC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_EMB_COMERC';
spool off

spool 'c:\mighdc\alert\grants\table_inf_med.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_MED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_MED';
spool off

spool 'c:\mighdc\alert\grants\table_inf_vias_admin.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_VIAS_ADMIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_VIAS_ADMIN';
spool off

spool 'c:\mighdc\alert\grants\table_interv_dep_clin_serv_migra.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DEP_CLIN_SERV_MIGRA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DEP_CLIN_SERV_MIGRA';
spool off

spool 'c:\mighdc\alert\grants\table_interv_dep_clin_serv_20060303.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DEP_CLIN_SERV_20060303','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DEP_CLIN_SERV_20060303';
spool off

spool 'c:\mighdc\alert\grants\table_manipulated_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANIPULATED_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANIPULATED_GROUP';

spool off

spool 'c:\mighdc\alert\grants\table_matr_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_nurse_activity_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_ACTIVITY_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_ACTIVITY_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_occupation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OCCUPATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OCCUPATION';
spool off


spool 'c:\mighdc\alert\grants\table_opinion.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OPINION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OPINION';
spool off

spool 'c:\mighdc\alert\grants\table_pat_allergy_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_ALLERGY_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_ALLERGY_HIST';
spool off

spool 'c:\mighdc\alert\grants\table_pat_history.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HISTORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HISTORY';
spool off


spool 'c:\mighdc\alert\grants\table_pat_med_decl.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MED_DECL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MED_DECL';
spool off

spool 'c:\mighdc\alert\grants\table_pat_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_pat_pregn_fetus_biom.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS_BIOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS_BIOM';
spool off

spool 'c:\mighdc\alert\grants\table_pat_pregn_measure.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\table_plan_table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PLAN_TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PLAN_TABLE';
spool off

spool 'c:\mighdc\alert\grants\table_postal_code_pt.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','POSTAL_CODE_PT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'POSTAL_CODE_PT';
spool off

spool 'c:\mighdc\alert\grants\table_presc_pat_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESC_PAT_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESC_PAT_PROBLEM';

spool off

spool 'c:\mighdc\alert\grants\table_prescription_type_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_TYPE_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_TYPE_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_prof_access_field_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS_FIELD_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS_FIELD_FUNC';
spool off

spool 'c:\mighdc\alert\grants\table_prof_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_EXT_SYS';
spool off


spool 'c:\mighdc\alert\grants\table_profile_templ_access_bck_agn.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPL_ACCESS_BCK_AGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPL_ACCESS_BCK_AGN';
spool off

spool 'c:\mighdc\alert\grants\table_protoc_diag.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROTOC_DIAG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROTOC_DIAG';
spool off

spool 'c:\mighdc\alert\grants\table_p1_doc_external.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOC_EXTERNAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOC_EXTERNAL';
spool off


spool 'c:\mighdc\alert\grants\table_rb_interv_icd.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RB_INTERV_ICD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RB_INTERV_ICD';
spool off

spool 'c:\mighdc\alert\grants\table_rep_profile_template_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_PROFILE_TEMPLATE_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_PROFILE_TEMPLATE_DET';
spool off

spool 'c:\mighdc\alert\grants\table_rep_prof_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_PROF_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_PROF_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_rep_section_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_SECTION_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_SECTION_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sample_text_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_PROF';
spool off

spool 'c:\mighdc\alert\grants\table_sample_text_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_scales.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCALES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCALES';

spool off

spool 'c:\mighdc\alert\grants\table_sch_default_consult_vacancy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_DEFAULT_CONSULT_VACANCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_DEFAULT_CONSULT_VACANCY';
spool off

spool 'c:\mighdc\alert\grants\table_schedule_alter.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_ALTER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_ALTER';
spool off

spool 'c:\mighdc\alert\grants\table_sch_prof_outp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_PROF_OUTP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_PROF_OUTP';
spool off


spool 'c:\mighdc\alert\grants\table_sch_resource.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_RESOURCE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_RESOURCE';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\table_software.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFTWARE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFTWARE';
spool off


spool 'c:\mighdc\alert\grants\table_sqln_explain_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SQLN_EXPLAIN_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SQLN_EXPLAIN_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_sr_base_diag.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_BASE_DIAG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_BASE_DIAG';
spool off

spool 'c:\mighdc\alert\grants\table_sr_chklist_manual.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST_MANUAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST_MANUAL';
spool off

spool 'c:\mighdc\alert\grants\table_sr_epis_interv.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\table_sr_interv_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERV_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERV_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_sr_pos_eval_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POS_EVAL_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POS_EVAL_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_posit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POSIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POSIT';

spool off

spool 'c:\mighdc\alert\grants\table_sr_pre_eval_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_EVAL_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_EVAL_VISIT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_prof_shift.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PROF_SHIFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PROF_SHIFT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_receive_manual.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_MANUAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_MANUAL';
spool off


spool 'c:\mighdc\alert\grants\table_sys_alert_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sys_application_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_APPLICATION_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_APPLICATION_AREA';
spool off

spool 'c:\mighdc\alert\grants\table_sys_entrance.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ENTRANCE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ENTRANCE';
spool off


spool 'c:\mighdc\alert\grants\table_sys_field.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_FIELD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_FIELD';
spool off

spool 'c:\mighdc\alert\grants\table_sys_login.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_LOGIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_LOGIN';
spool off

spool 'c:\mighdc\alert\grants\table_sys_screen_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SCREEN_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SCREEN_AREA';
spool off

spool 'c:\mighdc\alert\grants\table_temp_portaria.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TEMP_PORTARIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TEMP_PORTARIA';
spool off

spool 'c:\mighdc\alert\grants\table_triage_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_unit_measure_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','UNIT_MEASURE_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'UNIT_MEASURE_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_wound_treat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_TREAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_TREAT';

spool off

spool 'c:\mighdc\alert\grants\table_wound_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_matr_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_ROOM';
spool off


spool 'c:\mighdc\alert\grants\synonym_interv_presc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESC_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_folder.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_FOLDER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_FOLDER';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_composition.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPOSITION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPOSITION';
spool off


spool 'c:\mighdc\alert\grants\synonym_icnp_axis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_AXIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_AXIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_req.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_egp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_EGP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_EGP';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM';

spool off

spool 'c:\mighdc\alert\grants\synonym_epis_type_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TYPE_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TYPE_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_serv_sched_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SERV_SCHED_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SERV_SCHED_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\synonym_room_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_EXT_SYS';
spool off


spool 'c:\mighdc\alert\grants\synonym_profile_templ_acc_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPL_ACC_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPL_ACC_FUNC';
spool off

spool 'c:\mighdc\alert\grants\synonym_profile_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_call_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_CALL_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_CALL_QUEUE';
spool off


spool 'c:\mighdc\alert\grants\synonym_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VISIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_time_unit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TIME_UNIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TIME_UNIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_shortcut.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SHORTCUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SHORTCUT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_screen_area.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SCREEN_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SCREEN_AREA';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_button_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_button.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surg_prot_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_TASK';

spool off

spool 'c:\mighdc\alert\grants\synonym_sr_receive_proc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_receive_proc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC';
spool off

spool 'c:\mighdc\alert\grants\synonym_wound_treat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_TREAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_TREAT';
spool off


spool 'c:\mighdc\alert\grants\synonym_wound_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_wound_charac.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_CHARAC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_CHARAC';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_topics.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_TOPICS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_TOPICS';
spool off


spool 'c:\mighdc\alert\grants\synonym_pat_ginec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_GINEC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_GINEC';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_cntrceptiv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CNTRCEPTIV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CNTRCEPTIV';
spool off

spool 'c:\mighdc\alert\grants\synonym_outlook.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OUTLOOK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OUTLOOK';
spool off

spool 'c:\mighdc\alert\grants\synonym_occupation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OCCUPATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OCCUPATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_form.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_FORM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_FORM';
spool off

spool 'c:\mighdc\alert\grants\synonym_discriminator_help.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCRIMINATOR_HELP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCRIMINATOR_HELP';
spool off

spool 'c:\mighdc\alert\grants\synonym_discriminator.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCRIMINATOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCRIMINATOR';

spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_result.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_RESULT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_RESULT';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ';
spool off


spool 'c:\mighdc\alert\grants\synonym_ch_contents_text.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CH_CONTENTS_TEXT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CH_CONTENTS_TEXT';
spool off

spool 'c:\mighdc\alert\grants\synonym_cli_rec_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_consult_req_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONSULT_REQ_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONSULT_REQ_PROF';
spool off


spool 'c:\mighdc\alert\grants\synonym_adverse_interv_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ADVERSE_INTERV_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ADVERSE_INTERV_ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\synonym_sch_event.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_EVENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_EVENT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_posit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POSIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POSIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surg_period.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PERIOD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PERIOD';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_element.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ELEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ELEMENT';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_component.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_COMPONENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_COMPONENT';
spool off

spool 'c:\mighdc\alert\grants\synonym_complaint.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COMPLAINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COMPLAINT';

spool off

spool 'c:\mighdc\alert\grants\synonym_epis_documentation_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DOCUMENTATION_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DOCUMENTATION_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_documentation_rel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION_REL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION_REL';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_element.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT';
spool off


spool 'c:\mighdc\alert\grants\synonym_doc_action_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ACTION_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ACTION_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_bartchart.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BARTCHART','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BARTCHART';
spool off

spool 'c:\mighdc\alert\grants\synonym_floors.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS';
spool off


spool 'c:\mighdc\alert\grants\synonym_pk_sr_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_nurse.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_NURSE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_NURSE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_reset.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_RESET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_RESET';
spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_proc.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_PROC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_PROC';
spool off

spool 'c:\mighdc\alert\grants\package_pk_demo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DEMO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DEMO';
spool off

spool 'c:\mighdc\alert\grants\package_pk_login_list.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_LOGIN_LIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_LOGIN_LIST';
spool off

spool 'c:\mighdc\alert\grants\package_pk_image_tech.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_IMAGE_TECH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_IMAGE_TECH';

spool off

spool 'c:\mighdc\alert\grants\package_pk_audit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_AUDIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_AUDIT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_hand_off.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_HAND_OFF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_HAND_OFF';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wheel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WHEEL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WHEEL';
spool off


spool 'c:\mighdc\alert\grants\package_pk_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INTERV';
spool off

spool 'c:\mighdc\alert\grants\package_pk_monitorization.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_MONITORIZATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_MONITORIZATION';
spool off

spool 'c:\mighdc\alert\grants\table_dept.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPT';
spool off


spool 'c:\mighdc\alert\grants\sequence_seq_presc_xml_0102.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_XML_0102','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_XML_0102';
spool off

spool 'c:\mighdc\alert\grants\table_abnormality_nature.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ABNORMALITY_NATURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ABNORMALITY_NATURE';
spool off

spool 'c:\mighdc\alert\grants\table_adverse_exam_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ADVERSE_EXAM_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ADVERSE_EXAM_ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\table_allergy.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\table_allocation_bed_10042007.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ALLOCATION_BED_10042007','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ALLOCATION_BED_10042007';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_instit_soft.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_INSTIT_SOFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_INSTIT_SOFT';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_result.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_RESULT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_RESULT';

spool off

spool 'c:\mighdc\alert\grants\table_board.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD';
spool off

spool 'c:\mighdc\alert\grants\table_ch_contents_text.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CH_CONTENTS_TEXT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CH_CONTENTS_TEXT';
spool off

spool 'c:\mighdc\alert\grants\table_child_feed_dev.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CHILD_FEED_DEV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CHILD_FEED_DEV';
spool off


spool 'c:\mighdc\alert\grants\table_clinical_service.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLINICAL_SERVICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLINICAL_SERVICE';
spool off

spool 'c:\mighdc\alert\grants\table_color.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COLOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COLOR';
spool off

spool 'c:\mighdc\alert\grants\table_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGNOSIS';
spool off


spool 'c:\mighdc\alert\grants\table_drug_justification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_JUSTIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_JUSTIFICATION';
spool off

spool 'c:\mighdc\alert\grants\table_element_rel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ELEMENT_REL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ELEMENT_REL';
spool off

spool 'c:\mighdc\alert\grants\table_epis_attending_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_ATTENDING_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_ATTENDING_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_epis_diagnosis.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_epis_drug_usage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DRUG_USAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DRUG_USAGE';
spool off

spool 'c:\mighdc\alert\grants\table_epis_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_epis_obs_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBS_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBS_PHOTO';

spool off

spool 'c:\mighdc\alert\grants\table_epis_positioning_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_POSITIONING_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_POSITIONING_DET';
spool off

spool 'c:\mighdc\alert\grants\table_epis_positioning_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_POSITIONING_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_POSITIONING_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_epis_review_systems.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_REVIEW_SYSTEMS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_REVIEW_SYSTEMS';
spool off


spool 'c:\mighdc\alert\grants\table_equip_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EQUIP_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EQUIP_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_exam_ext_sys_delete.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_EXT_SYS_DELETE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_EXT_SYS_DELETE';
spool off

spool 'c:\mighdc\alert\grants\table_exam_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_REQ_DET';
spool off


spool 'c:\mighdc\alert\grants\table_exam_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_family_relationship.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FAMILY_RELATIONSHIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FAMILY_RELATIONSHIP';
spool off

spool 'c:\mighdc\alert\grants\table_grid_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GRID_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GRID_TASK';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_intervention_060425.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_INTERVENTION_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_INTERVENTION_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_predefined_action.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_PREDEFINED_ACTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_PREDEFINED_ACTION';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_term.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_TERM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_TERM';
spool off

spool 'c:\mighdc\alert\grants\table_import_prof_med.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_PROF_MED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_PROF_MED';

spool off

spool 'c:\mighdc\alert\grants\table_inf_patol_dip_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_PATOL_DIP_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_PATOL_DIP_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_inf_titular_aim.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_TITULAR_AIM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_TITULAR_AIM';
spool off

spool 'c:\mighdc\alert\grants\table_interv_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESCRIPTION';
spool off


spool 'c:\mighdc\alert\grants\table_isencao.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ISENCAO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ISENCAO';
spool off

spool 'c:\mighdc\alert\grants\table_java$options.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','JAVA$OPTIONS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'JAVA$OPTIONS';
spool off

spool 'c:\mighdc\alert\grants\table_matr_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_matr_scheduled.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_SCHEDULED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_SCHEDULED';
spool off

spool 'c:\mighdc\alert\grants\table_parameter_analysis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PARAMETER_ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PARAMETER_ANALYSIS';
spool off

spool 'c:\mighdc\alert\grants\table_pat_family_disease.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_DISEASE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_DISEASE';
spool off

spool 'c:\mighdc\alert\grants\table_pat_habit.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HABIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HABIT';
spool off

spool 'c:\mighdc\alert\grants\table_pat_history_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HISTORY_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HISTORY_HIST';
spool off

spool 'c:\mighdc\alert\grants\table_pat_medication_hist_list.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MEDICATION_HIST_LIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MEDICATION_HIST_LIST';
spool off

spool 'c:\mighdc\alert\grants\table_pat_necessity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_NECESSITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_NECESSITY';

spool off

spool 'c:\mighdc\alert\grants\table_prescription_pharm.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_PHARM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_PHARM';
spool off

spool 'c:\mighdc\alert\grants\table_professional.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFESSIONAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFESSIONAL';
spool off

spool 'c:\mighdc\alert\grants\table_prof_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_INSTITUTION';
spool off


spool 'c:\mighdc\alert\grants\table_prof_preferences.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PREFERENCES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PREFERENCES';
spool off

spool 'c:\mighdc\alert\grants\table_p1_ext_req_tracking.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_EXT_REQ_TRACKING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_EXT_REQ_TRACKING';
spool off

spool 'c:\mighdc\alert\grants\table_rb_sys_shortcut.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RB_SYS_SHORTCUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RB_SYS_SHORTCUT';
spool off


spool 'c:\mighdc\alert\grants\table_reports.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REPORTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REPORTS';
spool off

spool 'c:\mighdc\alert\grants\table_rep_screen.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_SCREEN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_SCREEN';
spool off

spool 'c:\mighdc\alert\grants\table_sch_consult_vacancy_temp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_CONSULT_VACANCY_TEMP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_CONSULT_VACANCY_TEMP';
spool off

spool 'c:\mighdc\alert\grants\table_schedule_sr_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_SR_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_SR_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sch_event.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_EVENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_EVENT';
spool off

spool 'c:\mighdc\alert\grants\table_snomed_concepts.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_CONCEPTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_CONCEPTS';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_diag.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_DIAG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_DIAG';

spool off

spool 'c:\mighdc\alert\grants\table_sr_epis_interv_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EPIS_INTERV_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EPIS_INTERV_DESC';
spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_VISIT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_interv_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERV_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERV_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_sr_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\table_sr_receive_proc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surgery_rec_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_REC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_REC_DET';
spool off


spool 'c:\mighdc\alert\grants\table_sys_documentation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_DOCUMENTATION';
spool off

spool 'c:\mighdc\alert\grants\table_sys_message.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_MESSAGE';
spool off

spool 'c:\mighdc\alert\grants\table_system_apparati.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYSTEM_APPARATI','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYSTEM_APPARATI';
spool off

spool 'c:\mighdc\alert\grants\table_translation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSLATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSLATION';
spool off

spool 'c:\mighdc\alert\grants\table_transp_entity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_ENTITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_ENTITY';
spool off

spool 'c:\mighdc\alert\grants\table_triage_nurse.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_NURSE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_NURSE';
spool off

spool 'c:\mighdc\alert\grants\table_triage_units.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_UNITS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_UNITS';

spool off

spool 'c:\mighdc\alert\grants\table_unit_measure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','UNIT_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'UNIT_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\table_unit_measure_convert.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','UNIT_MEASURE_CONVERT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'UNIT_MEASURE_CONVERT';
spool off

spool 'c:\mighdc\alert\grants\table_vital_sign_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_DESC';
spool off


spool 'c:\mighdc\alert\grants\table_vs_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VS_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VS_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_vs_soft_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VS_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VS_SOFT_INST';
spool off

spool 'c:\mighdc\alert\grants\table_wl_msg_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MSG_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MSG_QUEUE';
spool off


spool 'c:\mighdc\alert\grants\table_wl_topics.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_TOPICS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_TOPICS';
spool off

spool 'c:\mighdc\alert\grants\table_wl_waiting_line.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_LINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_LINE';
spool off

spool 'c:\mighdc\alert\grants\table_wl_waiting_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_wound_charac.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_CHARAC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_CHARAC';
spool off

spool 'c:\mighdc\alert\grants\synonym_material.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_prep_msg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PREP_MSG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PREP_MSG';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_compo_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_INST';

spool off

spool 'c:\mighdc\alert\grants\synonym_harvest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HARVEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HARVEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_ginec_obstet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GINEC_OBSTET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GINEC_OBSTET';
spool off

spool 'c:\mighdc\alert\grants\synonym_external_cause.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXTERNAL_CAUSE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXTERNAL_CAUSE';
spool off


spool 'c:\mighdc\alert\grants\synonym_sch_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_schedule_outp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_OUTP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_OUTP';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TYPE';
spool off


spool 'c:\mighdc\alert\grants\synonym_room_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_team.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_TEAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_TEAM';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_doc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_DOC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_DOC';
spool off

spool 'c:\mighdc\alert\grants\synonym_profile_templ_access.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPL_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPL_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_vaccine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_VACCINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_VACCINE';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_soc_attributes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_SOC_ATTRIBUTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_SOC_ATTRIBUTES';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_msg_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MSG_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MSG_QUEUE';

spool off

spool 'c:\mighdc\alert\grants\synonym_vaccine_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_transp_ent_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_ENT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_ENT_INST';
spool off

spool 'c:\mighdc\alert\grants\synonym_transp_entity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_ENTITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_ENTITY';
spool off


spool 'c:\mighdc\alert\grants\synonym_transport_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSPORT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSPORT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_button_prop.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON_PROP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON_PROP';
spool off

spool 'c:\mighdc\alert\grants\synonym_system_apparati.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYSTEM_APPARATI','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYSTEM_APPARATI';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_prof_team_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PROF_TEAM_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PROF_TEAM_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_prob_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROB_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROB_VISIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_pregn_fetus.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_child_feed_dev.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CHILD_FEED_DEV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CHILD_FEED_DEV';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_recomended_procedure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_RECOMENDED_PROCEDURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_RECOMENDED_PROCEDURE';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_doc_external_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOC_EXTERNAL_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOC_EXTERNAL_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_documents_done.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOCUMENTS_DONE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOCUMENTS_DONE';

spool off

spool 'c:\mighdc\alert\grants\synonym_monitorization_vs_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION_VS_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION_VS_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_monitorization_vs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION_VS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION_VS';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INTERV';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_HEALTH_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_route.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_ROUTE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_ROUTE';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG';
spool off


spool 'c:\mighdc\alert\grants\synonym_disc_vs_valid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISC_VS_VALID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISC_VS_VALID';
spool off

spool 'c:\mighdc\alert\grants\synonym_disch_prep_mesg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCH_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCH_PREP_MESG';
spool off

spool 'c:\mighdc\alert\grants\synonym_discharge_dest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_DEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_DEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_color.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COLOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COLOR';
spool off

spool 'c:\mighdc\alert\grants\synonym_clin_serv_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_SERV_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_SERV_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\synonym_board.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD';
spool off

spool 'c:\mighdc\alert\grants\synonym_birds_eye_view.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BIRDS_EYE_VIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BIRDS_EYE_VIEW';

spool off

spool 'c:\mighdc\alert\grants\synonym_anesthesia_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANESTHESIA_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANESTHESIA_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sch_event_dcs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_EVENT_DCS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_EVENT_DCS';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVALUATION';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_posit_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POSIT_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POSIT_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_nurse_rec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_NURSE_REC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_NURSE_REC';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_room_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_ROOM_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_ROOM_STATUS';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_pre_anest_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_ANEST_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_ANEST_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_eval_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_VISIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_eval_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_triage_type.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_template_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TEMPLATE_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TEMPLATE_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_AREA';

spool off

spool 'c:\mighdc\alert\grants\synonym_doc_element_rel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_REL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_REL';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_complaint.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_COMPLAINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_COMPLAINT';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_external.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_EXTERNAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_EXTERNAL';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_prof_resp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROF_RESP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROF_RESP';
spool off

spool 'c:\mighdc\alert\grants\package_pk_translation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_TRANSLATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_TRANSLATION';
spool off

spool 'c:\mighdc\alert\grants\function_sr_act_schedule_date.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_ACT_SCHEDULE_DATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_ACT_SCHEDULE_DATE';
spool off


spool 'c:\mighdc\alert\grants\package_pk_tools.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_TOOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_TOOLS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_procedures.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_PROCEDURES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_PROCEDURES';
spool off

spool 'c:\mighdc\alert\grants\package_pk_discharge.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_util.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_UTIL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_UTIL';
spool off

spool 'c:\mighdc\alert\grants\package_pk_print_tool.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PRINT_TOOL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PRINT_TOOL';
spool off

spool 'c:\mighdc\alert\grants\package_pk_problems.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PROBLEMS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PROBLEMS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_barcode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BARCODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BARCODE';

spool off

spool 'c:\mighdc\alert\grants\package_pk_sample_text.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SAMPLE_TEXT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SAMPLE_TEXT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wlsession.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLSESSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLSESSION';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wlpatient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLPATIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLPATIENT';
spool off


spool 'c:\mighdc\alert\grants\package_pk_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\table_adverse_interv_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ADVERSE_INTERV_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ADVERSE_INTERV_ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\table_allocation_bed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ALLOCATION_BED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ALLOCATION_BED';
spool off


spool 'c:\mighdc\alert\grants\table_analysis_param.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PARAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PARAM';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_result_par.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_RESULT_PAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_RESULT_PAR';
spool off

spool 'c:\mighdc\alert\grants\table_board_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_category_sub.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CATEGORY_SUB','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CATEGORY_SUB';
spool off

spool 'c:\mighdc\alert\grants\table_cli_rec_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\table_country.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COUNTRY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COUNTRY';
spool off

spool 'c:\mighdc\alert\grants\table_dependency.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPENDENCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPENDENCY';

spool off

spool 'c:\mighdc\alert\grants\table_diagram_detail_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_DETAIL_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_DETAIL_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_dietary_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIETARY_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIETARY_DRUG';
spool off

spool 'c:\mighdc\alert\grants\table_diet_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIET_SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIET_SCHEDULE';
spool off


spool 'c:\mighdc\alert\grants\table_discharge_detail.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_DETAIL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_DETAIL';
spool off

spool 'c:\mighdc\alert\grants\table_disch_reas_dest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCH_REAS_DEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCH_REAS_DEST';
spool off

spool 'c:\mighdc\alert\grants\table_doc_dimension.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_DIMENSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_DIMENSION';
spool off


spool 'c:\mighdc\alert\grants\table_doc_element_qualif.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_QUALIF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_QUALIF';
spool off

spool 'c:\mighdc\alert\grants\table_doc_element_rel.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_REL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_REL';
spool off

spool 'c:\mighdc\alert\grants\table_doc_ori_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ORI_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ORI_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_doc_type.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_drug_pharma_class.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA_CLASS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA_CLASS';
spool off

spool 'c:\mighdc\alert\grants\table_drug_route.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_ROUTE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_ROUTE';
spool off

spool 'c:\mighdc\alert\grants\table_epis_hidrics_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_HIDRICS_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_HIDRICS_DET';

spool off

spool 'c:\mighdc\alert\grants\table_epis_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_report.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_REPORT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_REPORT';
spool off

spool 'c:\mighdc\alert\grants\table_exam_cat_dcs_bck1.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_CAT_DCS_BCK1','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_CAT_DCS_BCK1';
spool off


spool 'c:\mighdc\alert\grants\table_family_monetary.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FAMILY_MONETARY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FAMILY_MONETARY';
spool off

spool 'c:\mighdc\alert\grants\table_graffar_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GRAFFAR_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GRAFFAR_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\table_hemo_req_supply.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ_SUPPLY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ_SUPPLY';
spool off


spool 'c:\mighdc\alert\grants\table_hidrics_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HIDRICS_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HIDRICS_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_axis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_AXIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_AXIS';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_composition_term.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPOSITION_TERM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPOSITION_TERM';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_diag_interv_060425.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAG_INTERV_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAG_INTERV_060425';
spool off

spool 'c:\mighdc\alert\grants\table_import_prof_admin.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_PROF_ADMIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_PROF_ADMIN';
spool off

spool 'c:\mighdc\alert\grants\table_ine_location.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INE_LOCATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INE_LOCATION';
spool off

spool 'c:\mighdc\alert\grants\table_inf_class_estup.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_CLASS_ESTUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_CLASS_ESTUP';

spool off

spool 'c:\mighdc\alert\grants\table_inf_patol_esp_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_PATOL_ESP_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_PATOL_ESP_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_interv_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_interv_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DRUG';
spool off


spool 'c:\mighdc\alert\grants\table_material_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\table_mdm_prof_coding.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MDM_PROF_CODING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MDM_PROF_CODING';
spool off

spool 'c:\mighdc\alert\grants\table_monitorization_vs_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION_VS_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION_VS_PLAN';
spool off


spool 'c:\mighdc\alert\grants\table_necessity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NECESSITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NECESSITY';
spool off

spool 'c:\mighdc\alert\grants\table_origin_soft.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ORIGIN_SOFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ORIGIN_SOFT';
spool off

spool 'c:\mighdc\alert\grants\table_outlook.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OUTLOOK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OUTLOOK';
spool off

spool 'c:\mighdc\alert\grants\table_param_analysis_ext_sys_delete.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PARAM_ANALYSIS_EXT_SYS_DELETE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PARAM_ANALYSIS_EXT_SYS_DELETE';
spool off

spool 'c:\mighdc\alert\grants\table_pat_child_clin_rec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CHILD_CLIN_REC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CHILD_CLIN_REC';
spool off

spool 'c:\mighdc\alert\grants\table_pat_cntrceptiv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CNTRCEPTIV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CNTRCEPTIV';
spool off

spool 'c:\mighdc\alert\grants\table_pat_delivery.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_DELIVERY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_DELIVERY';

spool off

spool 'c:\mighdc\alert\grants\table_pat_doc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_DOC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_DOC';
spool off

spool 'c:\mighdc\alert\grants\table_pat_ginec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_GINEC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_GINEC';
spool off

spool 'c:\mighdc\alert\grants\table_pat_graffar_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_GRAFFAR_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_GRAFFAR_CRIT';
spool off


spool 'c:\mighdc\alert\grants\table_pat_history_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_HISTORY_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_HISTORY_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_patient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PATIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PATIENT';
spool off

spool 'c:\mighdc\alert\grants\table_pat_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PHOTO';
spool off


spool 'c:\mighdc\alert\grants\table_pat_pregn_fetus.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS';
spool off

spool 'c:\mighdc\alert\grants\table_pat_problem_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROBLEM_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROBLEM_HIST';
spool off

spool 'c:\mighdc\alert\grants\table_pat_sick_leave.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_SICK_LEAVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_SICK_LEAVE';
spool off

spool 'c:\mighdc\alert\grants\table_presc_attention_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESC_ATTENTION_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESC_ATTENTION_DET';
spool off

spool 'c:\mighdc\alert\grants\table_prescription_number_seq.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_NUMBER_SEQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_NUMBER_SEQ';
spool off

spool 'c:\mighdc\alert\grants\table_prof_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_prof_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_FUNC';

spool off

spool 'c:\mighdc\alert\grants\table_prof_profile_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PROFILE_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PROFILE_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_records_review.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RECORDS_REVIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RECORDS_REVIEW';
spool off

spool 'c:\mighdc\alert\grants\table_religion.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RELIGION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RELIGION';
spool off


spool 'c:\mighdc\alert\grants\table_room_scheduled.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_SCHEDULED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_SCHEDULED';
spool off

spool 'c:\mighdc\alert\grants\table_sch_event_dcs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_EVENT_DCS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_EVENT_DCS';
spool off

spool 'c:\mighdc\alert\grants\table_sch_schedule_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_SCHEDULE_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_SCHEDULE_REQUEST';
spool off


spool 'c:\mighdc\alert\grants\table_serv_sched_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SERV_SCHED_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SERV_SCHED_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_discharge.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_situation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_SITUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_SITUATION';
spool off

spool 'c:\mighdc\alert\grants\table_soft_inst_services.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFT_INST_SERVICES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFT_INST_SERVICES';
spool off

spool 'c:\mighdc\alert\grants\table_spec_sys_appar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SPEC_SYS_APPAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SPEC_SYS_APPAR';
spool off

spool 'c:\mighdc\alert\grants\table_sr_equip_kit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EQUIP_KIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EQUIP_KIT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_equip_period.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EQUIP_PERIOD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EQUIP_PERIOD';

spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_summ.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_SUMM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_SUMM';
spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_sr_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVALUATION';
spool off


spool 'c:\mighdc\alert\grants\table_sr_room_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_ROOM_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_ROOM_STATUS';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surgery_time_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_TIME_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_TIME_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sys_alert_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_PROF';
spool off


spool 'c:\mighdc\alert\grants\table_sys_element.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ELEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ELEMENT';
spool off

spool 'c:\mighdc\alert\grants\table_sys_element_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ELEMENT_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ELEMENT_CRIT';
spool off

spool 'c:\mighdc\alert\grants\table_sys_screen_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SCREEN_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SCREEN_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_sys_time_event_group.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_TIME_EVENT_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_TIME_EVENT_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_transp_ent_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_ENT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_ENT_INST';
spool off

spool 'c:\mighdc\alert\grants\table_transp_req_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_REQ_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_REQ_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VISIT';

spool off

spool 'c:\mighdc\alert\grants\table_wl_mach_prof_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MACH_PROF_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MACH_PROF_QUEUE';
spool off

spool 'c:\mighdc\alert\grants\synonym_matr_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATR_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATR_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_material_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_REQ';
spool off


spool 'c:\mighdc\alert\grants\synonym_interv_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DRUG';
spool off


spool 'c:\mighdc\alert\grants\synonym_implementation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPLEMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPLEMENTATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_relationship.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_RELATIONSHIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_RELATIONSHIP';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_morph.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_MORPH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_MORPH';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_result.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_RESULT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_RESULT';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_prep_mesg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_PREP_MESG';
spool off

spool 'c:\mighdc\alert\grants\synonym_exam_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_sqln_explain_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SQLN_EXPLAIN_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SQLN_EXPLAIN_PLAN';

spool off

spool 'c:\mighdc\alert\grants\synonym_soft_inst_impl.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFT_INST_IMPL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFT_INST_IMPL';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_text_type_cat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_TYPE_CAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_TYPE_CAT';
spool off

spool 'c:\mighdc\alert\grants\synonym_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM';
spool off


spool 'c:\mighdc\alert\grants\synonym_protoc_diag.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROTOC_DIAG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROTOC_DIAG';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_soft_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_SOFT_INST';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_access_field_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS_FIELD_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS_FIELD_FUNC';
spool off


spool 'c:\mighdc\alert\grants\synonym_wl_patient_sonho_imp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO_IMP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO_IMP';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_mach_prof_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MACH_PROF_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MACH_PROF_QUEUE';
spool off

spool 'c:\mighdc\alert\grants\synonym_vbz$object_stats.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VBZ$OBJECT_STATS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VBZ$OBJECT_STATS';
spool off

spool 'c:\mighdc\alert\grants\synonym_vaccine_presc_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESC_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_functionality.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_FUNCTIONALITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_FUNCTIONALITY';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_domain.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_DOMAIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_DOMAIN';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_application_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_APPLICATION_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_APPLICATION_AREA';

spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surg_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_TASK';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_family_disease.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_DISEASE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_DISEASE';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_ALLERGY';
spool off


spool 'c:\mighdc\alert\grants\synonym_p1_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PROBLEM';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_external_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_EXTERNAL_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_EXTERNAL_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROBLEM';
spool off


spool 'c:\mighdc\alert\grants\synonym_drug_take_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_TAKE_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_TAKE_PLAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_brand.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_BRAND','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_BRAND';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_result_par.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_RESULT_PAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_RESULT_PAR';
spool off

spool 'c:\mighdc\alert\grants\synonym_category.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CATEGORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CATEGORY';
spool off

spool 'c:\mighdc\alert\grants\synonym_board_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_clin_srv_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_SRV_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_SRV_TYPE';

spool off

spool 'c:\mighdc\alert\grants\synonym_dep_clin_serv_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEP_CLIN_SERV_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEP_CLIN_SERV_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\synonym_country.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COUNTRY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COUNTRY';
spool off


spool 'c:\mighdc\alert\grants\synonym_contraceptive.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONTRACEPTIVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONTRACEPTIVE';
spool off

spool 'c:\mighdc\alert\grants\synonym_unit_measure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','UNIT_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'UNIT_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_receive_manual.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_MANUAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_MANUAL';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_epis_interv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EPIS_INTERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EPIS_INTERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surgery_rec_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_REC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_REC_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_element_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ELEMENT_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ELEMENT_CRIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_qualification.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_QUALIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_QUALIFICATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_triage_color.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_COLOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_COLOR';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_bartchart_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BARTCHART_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BARTCHART_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_floors_department.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS_DEPARTMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS_DEPARTMENT';

spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_adm_hs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_ADM_HS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_ADM_HS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_med_hs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_MED_HS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_MED_HS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_reset.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_RESET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_RESET';
spool off


spool 'c:\mighdc\alert\grants\package_pk_grid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_GRID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_GRID';
spool off

spool 'c:\mighdc\alert\grants\package_pk_bird_eye_view.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BIRD_EYE_VIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BIRD_EYE_VIEW';
spool off

spool 'c:\mighdc\alert\grants\package_pk_bed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_BED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_BED';
spool off


spool 'c:\mighdc\alert\grants\package_pk_exam.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EXAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EXAM';
spool off

spool 'c:\mighdc\alert\grants\package_pk_analysis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_ANALYSIS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_interface_report_er_outp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INTERFACE_REPORT_ER_OUTP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INTERFACE_REPORT_ER_OUTP';
spool off

spool 'c:\mighdc\alert\grants\package_pk_waitinglinesonho.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WAITINGLINESONHO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WAITINGLINESONHO';
spool off

spool 'c:\mighdc\alert\grants\package_pk_patient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PATIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PATIENT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_screen_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SCREEN_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SCREEN_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_lab_tech.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_LAB_TECH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_LAB_TECH';

spool off

spool 'c:\mighdc\alert\grants\package_pk_vaccine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_VACCINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_VACCINE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_profphoto.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PROFPHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PROFPHOTO';
spool off

spool 'c:\mighdc\alert\grants\sequence_seq_presc_xml_0124.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_XML_0124','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_XML_0124';
spool off


spool 'c:\mighdc\alert\grants\type_table_number.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TABLE_NUMBER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TABLE_NUMBER';
spool off

spool 'c:\mighdc\alert\grants\table_abnormality.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ABNORMALITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ABNORMALITY';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_loinc_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_LOINC_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_LOINC_TEMPLATE';
spool off


spool 'c:\mighdc\alert\grants\table_analysis_req_par.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ_PAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ_PAR';
spool off

spool 'c:\mighdc\alert\grants\table_building.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BUILDING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BUILDING';
spool off

spool 'c:\mighdc\alert\grants\table_clin_record.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_RECORD';
spool off

spool 'c:\mighdc\alert\grants\table_cli_rec_req.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_complete_history.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COMPLETE_HISTORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COMPLETE_HISTORY';
spool off

spool 'c:\mighdc\alert\grants\table_contraceptive.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONTRACEPTIVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONTRACEPTIVE';
spool off

spool 'c:\mighdc\alert\grants\table_critical_care_read.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CRITICAL_CARE_READ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CRITICAL_CARE_READ';

spool off

spool 'c:\mighdc\alert\grants\table_department.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPARTMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPARTMENT';
spool off

spool 'c:\mighdc\alert\grants\table_diagram_layout.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_LAYOUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_LAYOUT';
spool off

spool 'c:\mighdc\alert\grants\table_diagram_tools_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_TOOLS_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_TOOLS_GROUP';
spool off


spool 'c:\mighdc\alert\grants\table_discharge_dest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_DEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_DEST';
spool off

spool 'c:\mighdc\alert\grants\table_discharge_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_disch_prep_mesg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCH_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCH_PREP_MESG';
spool off


spool 'c:\mighdc\alert\grants\table_drug_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_BCK';
spool off

spool 'c:\mighdc\alert\grants\table_drug_pharma_class_link.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA_CLASS_LINK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA_CLASS_LINK';
spool off

spool 'c:\mighdc\alert\grants\table_drug_pharma_interaction.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA_INTERACTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA_INTERACTION';
spool off

spool 'c:\mighdc\alert\grants\table_drug_protocols.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_drug_take_time.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_TAKE_TIME','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_TAKE_TIME';
spool off

spool 'c:\mighdc\alert\grants\table_epis_bartchart.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BARTCHART','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BARTCHART';
spool off

spool 'c:\mighdc\alert\grants\table_epis_documentation_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DOCUMENTATION_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DOCUMENTATION_DET';

spool off

spool 'c:\mighdc\alert\grants\table_epis_recomend.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_RECOMEND','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_RECOMEND';
spool off

spool 'c:\mighdc\alert\grants\table_epis_triage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TRIAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TRIAGE';
spool off

spool 'c:\mighdc\alert\grants\table_exam_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_family_relationship_relat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FAMILY_RELATIONSHIP_RELAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FAMILY_RELATIONSHIP_RELAT';
spool off

spool 'c:\mighdc\alert\grants\table_floors.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS';
spool off

spool 'c:\mighdc\alert\grants\table_floors_dep_position.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','FLOORS_DEP_POSITION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'FLOORS_DEP_POSITION';
spool off


spool 'c:\mighdc\alert\grants\table_geo_location.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GEO_LOCATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GEO_LOCATION';
spool off

spool 'c:\mighdc\alert\grants\table_graffar_crit_value.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GRAFFAR_CRIT_VALUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GRAFFAR_CRIT_VALUE';
spool off

spool 'c:\mighdc\alert\grants\table_harvest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HARVEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HARVEST';
spool off

spool 'c:\mighdc\alert\grants\table_health_plan_instit.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEALTH_PLAN_INSTIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEALTH_PLAN_INSTIT';
spool off

spool 'c:\mighdc\alert\grants\table_hemo_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_composition.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPOSITION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPOSITION';
spool off

spool 'c:\mighdc\alert\grants\table_identification_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IDENTIFICATION_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IDENTIFICATION_NOTES';

spool off

spool 'c:\mighdc\alert\grants\table_inf_diabetes_lnk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_DIABETES_LNK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_DIABETES_LNK';
spool off

spool 'c:\mighdc\alert\grants\table_inf_emb_unit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_EMB_UNIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_EMB_UNIT';
spool off

spool 'c:\mighdc\alert\grants\table_inf_form_farm.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_FORM_FARM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_FORM_FARM';
spool off


spool 'c:\mighdc\alert\grants\table_inf_grupo_hom.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_GRUPO_HOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_GRUPO_HOM';
spool off

spool 'c:\mighdc\alert\grants\table_inf_subst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_SUBST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_SUBST';
spool off

spool 'c:\mighdc\alert\grants\table_inf_tipo_preco.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_TIPO_PRECO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_TIPO_PRECO';
spool off


spool 'c:\mighdc\alert\grants\table_inp_error.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INP_ERROR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INP_ERROR';
spool off

spool 'c:\mighdc\alert\grants\table_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\table_java$class$md5$table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','JAVA$CLASS$MD5$TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'JAVA$CLASS$MD5$TABLE';
spool off

spool 'c:\mighdc\alert\grants\table_mcdt_req_diagnosis.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MCDT_REQ_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MCDT_REQ_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_pat_medication_list.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MEDICATION_LIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MEDICATION_LIST';
spool off

spool 'c:\mighdc\alert\grants\table_pat_pregn_fetus_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS_DET';
spool off

spool 'c:\mighdc\alert\grants\table_pat_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROBLEM';

spool off

spool 'c:\mighdc\alert\grants\table_prescription_print.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_PRINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_PRINT';
spool off

spool 'c:\mighdc\alert\grants\table_prof_access_bck2.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS_BCK2','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS_BCK2';
spool off

spool 'c:\mighdc\alert\grants\table_prof_doc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_DOC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_DOC';
spool off


spool 'c:\mighdc\alert\grants\table_profile_templ_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPL_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPL_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_profile_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_prof_in_out.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_IN_OUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_IN_OUT';
spool off


spool 'c:\mighdc\alert\grants\table_prof_team_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_TEAM_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_TEAM_DET';
spool off

spool 'c:\mighdc\alert\grants\table_p1_doc_external_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOC_EXTERNAL_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOC_EXTERNAL_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\table_records_review_read.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RECORDS_REVIEW_READ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RECORDS_REVIEW_READ';
spool off

spool 'c:\mighdc\alert\grants\table_room.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_rotation_interval.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROTATION_INTERVAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROTATION_INTERVAL';
spool off

spool 'c:\mighdc\alert\grants\table_sample_text_freq.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_FREQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_FREQ';
spool off

spool 'c:\mighdc\alert\grants\table_sample_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TYPE';

spool off

spool 'c:\mighdc\alert\grants\table_sch_cancel_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_CANCEL_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_CANCEL_REASON';
spool off

spool 'c:\mighdc\alert\grants\table_schedule_sr.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_SR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_SR';
spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_rule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_RULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_RULE';
spool off


spool 'c:\mighdc\alert\grants\table_sr_pat_status_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PAT_STATUS_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PAT_STATUS_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_sr_pos_eval_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POS_EVAL_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POS_EVAL_VISIT';
spool off

spool 'c:\mighdc\alert\grants\table_sr_posit_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POSIT_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POSIT_REQ';
spool off


spool 'c:\mighdc\alert\grants\table_sr_pre_anest_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_ANEST_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_ANEST_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_pre_eval_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_EVAL_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_EVAL_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surgery_record.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_RECORD';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surgery_time.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_TIME','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_TIME';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surg_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_TASK';
spool off

spool 'c:\mighdc\alert\grants\table_sys_alert.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT';
spool off

spool 'c:\mighdc\alert\grants\table_sys_alert_software.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_SOFTWARE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_SOFTWARE';

spool off

spool 'c:\mighdc\alert\grants\table_sys_alert_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_sys_application_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_APPLICATION_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_APPLICATION_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_translation_bck_20061214.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSLATION_BCK_20061214','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSLATION_BCK_20061214';
spool off


spool 'c:\mighdc\alert\grants\table_vaccine_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\index_vbz$object_stats.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VBZ$OBJECT_STATS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VBZ$OBJECT_STATS';
spool off

spool 'c:\mighdc\alert\grants\table_vital_sign.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN';
spool off


spool 'c:\mighdc\alert\grants\table_vital_sign_read.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_READ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_READ';
spool off

spool 'c:\mighdc\alert\grants\table_vital_sign_unit_measure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_UNIT_MEASURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_UNIT_MEASURE';
spool off

spool 'c:\mighdc\alert\grants\table_white_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WHITE_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WHITE_REASON';
spool off

spool 'c:\mighdc\alert\grants\table_wl_demo.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_DEMO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_DEMO';
spool off

spool 'c:\mighdc\alert\grants\table_wl_demo_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_DEMO_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_DEMO_BCK';
spool off

spool 'c:\mighdc\alert\grants\table_wound_eval_charac.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_EVAL_CHARAC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_EVAL_CHARAC';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_term.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_TERM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_TERM';

spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_classification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_CLASSIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_CLASSIFICATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_hemo_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_health_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEALTH_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEALTH_PLAN';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_epis_interv_desc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EPIS_INTERV_DESC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EPIS_INTERV_DESC';
spool off

spool 'c:\mighdc\alert\grants\synonym_soft_inst_services.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFT_INST_SERVICES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFT_INST_SERVICES';
spool off

spool 'c:\mighdc\alert\grants\synonym_software.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFTWARE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFTWARE';
spool off


spool 'c:\mighdc\alert\grants\synonym_sch_resource.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_RESOURCE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_RESOURCE';
spool off

spool 'c:\mighdc\alert\grants\synonym_school.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHOOL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHOOL';
spool off

spool 'c:\mighdc\alert\grants\synonym_room_scheduled.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_SCHEDULED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_SCHEDULED';
spool off

spool 'c:\mighdc\alert\grants\synonym_quest_sl_temp_explain1.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','QUEST_SL_TEMP_EXPLAIN1','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'QUEST_SL_TEMP_EXPLAIN1';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_profile_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PROFILE_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PROFILE_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_in_out.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_IN_OUT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_IN_OUT';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_func.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_FUNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_FUNC';

spool off

spool 'c:\mighdc\alert\grants\synonym_wl_demo_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_DEMO_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_DEMO_BCK';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_demo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_DEMO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_DEMO';
spool off

spool 'c:\mighdc\alert\grants\synonym_vs_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VS_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VS_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\synonym_translation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSLATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSLATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_toad_plan_sql.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TOAD_PLAN_SQL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TOAD_PLAN_SQL';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_time_event_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_TIME_EVENT_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_TIME_EVENT_GROUP';
spool off


spool 'c:\mighdc\alert\grants\synonym_sys_message.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_MESSAGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_config.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_CONFIG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_CONFIG';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_btn_crit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BTN_CRIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BTN_CRIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert_profile.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_PROFILE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_PROFILE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_prof_recov_schd.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PROF_RECOV_SCHD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PROF_RECOV_SCHD';
spool off

spool 'c:\mighdc\alert\grants\synonym_wound_eval_charac.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_EVAL_CHARAC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_EVAL_CHARAC';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_waiting_line_0104.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_LINE_0104','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_LINE_0104';

spool off

spool 'c:\mighdc\alert\grants\synonym_wl_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_STATUS';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_sick_leave.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_SICK_LEAVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_SICK_LEAVE';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_pregn_fetus_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS_DET';
spool off


spool 'c:\mighdc\alert\grants\synonym_pat_pregn_fetus_biom.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGN_FETUS_BIOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGN_FETUS_BIOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_pregnancy_risk.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGNANCY_RISK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGNANCY_RISK';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_NOTES';
spool off


spool 'c:\mighdc\alert\grants\synonym_pat_med_decl.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_MED_DECL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_MED_DECL';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\synonym_p1_documents.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOCUMENTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOCUMENTS';
spool off

spool 'c:\mighdc\alert\grants\synonym_opinion_prof.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OPINION_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OPINION_PROF';
spool off

spool 'c:\mighdc\alert\grants\synonym_monitorization.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_readmission.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_READMISSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_READMISSION';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROTOCOLS';

spool off

spool 'c:\mighdc\alert\grants\synonym_epis_observation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBSERVATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBSERVATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_man.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_MAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_MAN';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_body_painting_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BODY_PAINTING_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BODY_PAINTING_DET';
spool off


spool 'c:\mighdc\alert\grants\synonym_episode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPISODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPISODE';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_pharma_interaction.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA_INTERACTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA_INTERACTION';
spool off


spool 'c:\mighdc\alert\grants\synonym_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_req_par.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ_PAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ_PAR';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_harvest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_HARVEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_HARVEST';
spool off

spool 'c:\mighdc\alert\grants\synonym_beye_view_screen.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BEYE_VIEW_SCREEN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BEYE_VIEW_SCREEN';
spool off

spool 'c:\mighdc\alert\grants\synonym_bed_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BED_SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BED_SCHEDULE';
spool off

spool 'c:\mighdc\alert\grants\synonym_origin_soft.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ORIGIN_SOFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ORIGIN_SOFT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERVENTION';

spool off

spool 'c:\mighdc\alert\grants\synonym_sr_equip.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EQUIP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EQUIP';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_dimension.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_DIMENSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_DIMENSION';
spool off

spool 'c:\mighdc\alert\grants\synonym_document_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENT_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENT_AREA';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_documentation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DOCUMENTATION';
spool off

spool 'c:\mighdc\alert\grants\view_v_disch_reas_dest.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','V_DISCH_REAS_DEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'V_DISCH_REAS_DEST';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sysconfig.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SYSCONFIG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SYSCONFIG';
spool off


spool 'c:\mighdc\alert\grants\package_pk_date_utils.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DATE_UTILS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DATE_UTILS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_adm_cs.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_ADM_CS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_ADM_CS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_tools.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_TOOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_TOOLS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_positioning.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_POSITIONING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_POSITIONING';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_planning.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_PLANNING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_PLANNING';
spool off

spool 'c:\mighdc\alert\grants\package_pk_alerts.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_ALERTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_ALERTS';

spool off

spool 'c:\mighdc\alert\grants\package_pk_wlnur.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLNUR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLNUR';
spool off

spool 'c:\mighdc\alert\grants\package_pk_infarmed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INFARMED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INFARMED';
spool off

spool 'c:\mighdc\alert\grants\package_pk_woman_health.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WOMAN_HEALTH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WOMAN_HEALTH';
spool off


spool 'c:\mighdc\alert\grants\package_pk_edis_triage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_TRIAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_TRIAGE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_list.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_LIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_LIST';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_grid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_GRID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_GRID';
spool off


spool 'c:\mighdc\alert\grants\package_pk_nurse_activity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_NURSE_ACTIVITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_NURSE_ACTIVITY';
spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_core.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_CORE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_CORE';
spool off

spool 'c:\mighdc\alert\grants\trigger_manipulated_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANIPULATED_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANIPULATED_GROUP';
spool off

spool 'c:\mighdc\alert\grants\sequence_seq_presc_number_0102.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_NUMBER_0102','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_NUMBER_0102';
spool off

spool 'c:\mighdc\alert\grants\sequence_seq_presc_number_0124.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SEQ_PRESC_NUMBER_0124','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SEQ_PRESC_NUMBER_0124';
spool off

spool 'c:\mighdc\alert\grants\table_action_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ACTION_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ACTION_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_REQ';

spool off

spool 'c:\mighdc\alert\grants\table_birds_eye_view.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BIRDS_EYE_VIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BIRDS_EYE_VIEW';
spool off

spool 'c:\mighdc\alert\grants\table_ch_contents.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CH_CONTENTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CH_CONTENTS';
spool off

spool 'c:\mighdc\alert\grants\table_complaint.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COMPLAINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COMPLAINT';
spool off


spool 'c:\mighdc\alert\grants\table_complaint_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COMPLAINT_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COMPLAINT_DIAGNOSIS';
spool off

spool 'c:\mighdc\alert\grants\table_complaint_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','COMPLAINT_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'COMPLAINT_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\table_diagnosis_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGNOSIS_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGNOSIS_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_diagram.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM';
spool off

spool 'c:\mighdc\alert\grants\table_discharge_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_REASON';
spool off

spool 'c:\mighdc\alert\grants\table_disch_rea_transp_ent_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCH_REA_TRANSP_ENT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCH_REA_TRANSP_ENT_INST';
spool off

spool 'c:\mighdc\alert\grants\table_doc_action_criteria.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ACTION_CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ACTION_CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\table_doc_component.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_COMPONENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_COMPONENT';
spool off

spool 'c:\mighdc\alert\grants\table_doc_external.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_EXTERNAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_EXTERNAL';
spool off

spool 'c:\mighdc\alert\grants\table_doc_image.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_IMAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_IMAGE';

spool off

spool 'c:\mighdc\alert\grants\table_documentation_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG';
spool off

spool 'c:\mighdc\alert\grants\table_drug_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_drug_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_drug_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\table_epis_diagnosis_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DIAGNOSIS_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DIAGNOSIS_HIST';
spool off


spool 'c:\mighdc\alert\grants\table_epis_documentation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DOCUMENTATION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_obs_exam.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBS_EXAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBS_EXAM';
spool off

spool 'c:\mighdc\alert\grants\table_epis_positioning.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_POSITIONING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_POSITIONING';
spool off

spool 'c:\mighdc\alert\grants\table_epis_problem.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROBLEM';
spool off

spool 'c:\mighdc\alert\grants\table_epis_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_exam_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_exam_prep_mesg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_PREP_MESG';

spool off

spool 'c:\mighdc\alert\grants\table_exam_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_exam_result.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_RESULT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_RESULT';
spool off

spool 'c:\mighdc\alert\grants\table_ginec_obstet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GINEC_OBSTET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GINEC_OBSTET';
spool off


spool 'c:\mighdc\alert\grants\table_habit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HABIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HABIT';
spool off

spool 'c:\mighdc\alert\grants\table_hidrics_relation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HIDRICS_RELATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HIDRICS_RELATION';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_compo_folder.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_FOLDER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_FOLDER';
spool off


spool 'c:\mighdc\alert\grants\table_icnp_compo_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_INST';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_dictionary.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_DICTIONARY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_DICTIONARY';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_predefined_action_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_PREDEFINED_ACTION_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_PREDEFINED_ACTION_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_transition_state.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_TRANSITION_STATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_TRANSITION_STATE';
spool off

spool 'c:\mighdc\alert\grants\table_implementation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPLEMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPLEMENTATION';
spool off

spool 'c:\mighdc\alert\grants\table_import_analysis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_ANALYSIS';
spool off

spool 'c:\mighdc\alert\grants\table_import_mcdt_migra.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_MCDT_MIGRA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_MCDT_MIGRA';

spool off

spool 'c:\mighdc\alert\grants\table_import_mcdt_20060303.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','IMPORT_MCDT_20060303','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'IMPORT_MCDT_20060303';
spool off

spool 'c:\mighdc\alert\grants\table_inf_preco.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_PRECO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_PRECO';
spool off

spool 'c:\mighdc\alert\grants\table_instit_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INSTIT_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INSTIT_EXT_SYS';
spool off


spool 'c:\mighdc\alert\grants\table_interv_presc_plan.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESC_PLAN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESC_PLAN';
spool off

spool 'c:\mighdc\alert\grants\table_interv_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_match_epis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATCH_EPIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATCH_EPIS';
spool off


spool 'c:\mighdc\alert\grants\table_mdm_coding.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MDM_CODING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MDM_CODING';
spool off

spool 'c:\mighdc\alert\grants\table_movement.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MOVEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MOVEMENT';
spool off

spool 'c:\mighdc\alert\grants\table_nurse_actv_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_ACTV_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_ACTV_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\table_opinion_prof.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','OPINION_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'OPINION_PROF';
spool off

spool 'c:\mighdc\alert\grants\table_origin.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ORIGIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ORIGIN';
spool off

spool 'c:\mighdc\alert\grants\table_pat_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\table_pat_blood_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_BLOOD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_BLOOD_GROUP';

spool off

spool 'c:\mighdc\alert\grants\table_pat_family_member.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_MEMBER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_MEMBER';
spool off

spool 'c:\mighdc\alert\grants\table_pat_family_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_PROF';
spool off

spool 'c:\mighdc\alert\grants\table_pat_fam_soc_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAM_SOC_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAM_SOC_HIST';
spool off


spool 'c:\mighdc\alert\grants\table_pat_job.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_JOB','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_JOB';
spool off

spool 'c:\mighdc\alert\grants\table_pat_permission.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PERMISSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PERMISSION';
spool off

spool 'c:\mighdc\alert\grants\table_pat_pregnancy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PREGNANCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PREGNANCY';
spool off


spool 'c:\mighdc\alert\grants\table_pat_prob_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PROB_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PROB_VISIT';
spool off

spool 'c:\mighdc\alert\grants\table_pat_soc_attributes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_SOC_ATTRIBUTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_SOC_ATTRIBUTES';
spool off

spool 'c:\mighdc\alert\grants\table_positioning_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','POSITIONING_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'POSITIONING_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_prescription_type.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_prescription_xml_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PRESCRIPTION_XML_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PRESCRIPTION_XML_DET';
spool off

spool 'c:\mighdc\alert\grants\table_prof_access_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS_BCK';
spool off

spool 'c:\mighdc\alert\grants\table_profile_template_bck_agn.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFILE_TEMPLATE_BCK_AGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFILE_TEMPLATE_BCK_AGN';

spool off

spool 'c:\mighdc\alert\grants\table_prof_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PHOTO';
spool off

spool 'c:\mighdc\alert\grants\table_prof_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_p1_documents_done.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_DOCUMENTS_DONE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_DOCUMENTS_DONE';
spool off


spool 'c:\mighdc\alert\grants\table_p1_problem.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PROBLEM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PROBLEM';
spool off

spool 'c:\mighdc\alert\grants\table_p1_problem_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PROBLEM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PROBLEM_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_quest_temp_explain.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','QUEST_TEMP_EXPLAIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'QUEST_TEMP_EXPLAIN';
spool off


spool 'c:\mighdc\alert\grants\table_rb_profile_templ_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RB_PROFILE_TEMPL_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RB_PROFILE_TEMPL_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_rb_sys_button_prop.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RB_SYS_BUTTON_PROP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RB_SYS_BUTTON_PROP';
spool off

spool 'c:\mighdc\alert\grants\table_rep_prof_exception.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_PROF_EXCEPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_PROF_EXCEPTION';
spool off

spool 'c:\mighdc\alert\grants\table_rep_prof_templ_access.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_PROF_TEMPL_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_PROF_TEMPL_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_room_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_sample_text.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT';
spool off

spool 'c:\mighdc\alert\grants\table_scales_class.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCALES_CLASS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCALES_CLASS';

spool off

spool 'c:\mighdc\alert\grants\table_sch_action.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_ACTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_ACTION';
spool off

spool 'c:\mighdc\alert\grants\table_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE';
spool off

spool 'c:\mighdc\alert\grants\table_schedule_outp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCHEDULE_OUTP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCHEDULE_OUTP';
spool off


spool 'c:\mighdc\alert\grants\table_sch_log.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_LOG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_LOG';
spool off

spool 'c:\mighdc\alert\grants\table_sch_permission.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_PERMISSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_PERMISSION';
spool off

spool 'c:\mighdc\alert\grants\table_screen_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCREEN_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCREEN_TEMPLATE';
spool off


spool 'c:\mighdc\alert\grants\table_slot.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SLOT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SLOT';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_request.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_REQUEST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_REQUEST';
spool off

spool 'c:\mighdc\alert\grants\table_social_epis_solution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPIS_SOLUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPIS_SOLUTION';
spool off

spool 'c:\mighdc\alert\grants\table_social_intervention.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\table_software_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFTWARE_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFTWARE_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\table_speciality.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SPECIALITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SPECIALITY';
spool off

spool 'c:\mighdc\alert\grants\table_sr_doc_element.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_DOC_ELEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_DOC_ELEMENT';

spool off

spool 'c:\mighdc\alert\grants\table_sr_eval_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_EVAL_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_EVAL_NOTES';
spool off

spool 'c:\mighdc\alert\grants\table_sr_nurse_rec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_NURSE_REC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_NURSE_REC';
spool off

spool 'c:\mighdc\alert\grants\table_sr_receive.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE';
spool off


spool 'c:\mighdc\alert\grants\table_sys_alert_profile.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_PROFILE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_PROFILE';
spool off

spool 'c:\mighdc\alert\grants\table_sys_btn_sbg.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BTN_SBG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BTN_SBG';
spool off

spool 'c:\mighdc\alert\grants\table_sys_button.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_BUTTON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_BUTTON';
spool off


spool 'c:\mighdc\alert\grants\table_sys_config.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_CONFIG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_CONFIG';
spool off

spool 'c:\mighdc\alert\grants\table_sys_functionality.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_FUNCTIONALITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_FUNCTIONALITY';
spool off

spool 'c:\mighdc\alert\grants\table_tests_review.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TESTS_REVIEW','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TESTS_REVIEW';
spool off

spool 'c:\mighdc\alert\grants\table_tmp_nurse_summary.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TMP_NURSE_SUMMARY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TMP_NURSE_SUMMARY';
spool off

spool 'c:\mighdc\alert\grants\table_triage_board_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_BOARD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_BOARD_GROUP';
spool off

spool 'c:\mighdc\alert\grants\table_triage_color.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE_COLOR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE_COLOR';
spool off

spool 'c:\mighdc\alert\grants\table_vaccine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE';

spool off

spool 'c:\mighdc\alert\grants\table_vaccine_presc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE_PRESC_DET';
spool off

spool 'c:\mighdc\alert\grants\table_viewer_refresh.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VIEWER_REFRESH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VIEWER_REFRESH';
spool off

spool 'c:\mighdc\alert\grants\table_viewer_synch_param.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VIEWER_SYNCH_PARAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VIEWER_SYNCH_PARAM';
spool off


spool 'c:\mighdc\alert\grants\table_vital_sign_relation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_RELATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_RELATION';
spool off

spool 'c:\mighdc\alert\grants\table_wl_patient_sonho_imp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO_IMP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO_IMP';
spool off

spool 'c:\mighdc\alert\grants\table_wl_prof_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PROF_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PROF_ROOM';
spool off


spool 'c:\mighdc\alert\grants\synonym_manchester.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANCHESTER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANCHESTER';
spool off

spool 'c:\mighdc\alert\grants\synonym_java$class$md5$table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','JAVA$CLASS$MD5$TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'JAVA$CLASS$MD5$TABLE';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\synonym_interv_dep_clin_serv.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_intervention.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERVENTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERVENTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_predefined_action.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_PREDEFINED_ACTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_PREDEFINED_ACTION';

spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_compo_folder.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPO_FOLDER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPO_FOLDER';
spool off

spool 'c:\mighdc\alert\grants\synonym_home.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HOME','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HOME';
spool off

spool 'c:\mighdc\alert\grants\synonym_hemo_req_supply.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ_SUPPLY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ_SUPPLY';
spool off


spool 'c:\mighdc\alert\grants\synonym_grid_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','GRID_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'GRID_TASK';
spool off

spool 'c:\mighdc\alert\grants\synonym_external_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXTERNAL_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXTERNAL_SYS';
spool off

spool 'c:\mighdc\alert\grants\synonym_estate.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ESTATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ESTATE';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_chklist_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_slot.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SLOT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SLOT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sch_service.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_SERVICE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_SERVICE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sch_prof_outp.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SCH_PROF_OUTP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SCH_PROF_OUTP';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_text_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_text_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_TEXT_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_TEXT_PROF';
spool off

spool 'c:\mighdc\alert\grants\synonym_religion.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RELIGION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RELIGION';

spool off

spool 'c:\mighdc\alert\grants\synonym_quest_temp_explain.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','QUEST_TEMP_EXPLAIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'QUEST_TEMP_EXPLAIN';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_professional.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROFESSIONAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROFESSIONAL';
spool off


spool 'c:\mighdc\alert\grants\synonym_prep_message.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PREP_MESSAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PREP_MESSAGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_pregnancy_risk_eval.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PREGNANCY_RISK_EVAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PREGNANCY_RISK_EVAL';
spool off

spool 'c:\mighdc\alert\grants\synonym_periodic_exam_educ.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PERIODIC_EXAM_EDUC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PERIODIC_EXAM_EDUC';
spool off


spool 'c:\mighdc\alert\grants\synonym_wl_machine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_MACHINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_MACHINE';
spool off

spool 'c:\mighdc\alert\grants\synonym_white_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WHITE_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WHITE_REASON';
spool off

spool 'c:\mighdc\alert\grants\synonym_vital_sign_relation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN_RELATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN_RELATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_transportation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSPORTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSPORTATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_toolbar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_TOOLBAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_TOOLBAR';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_message_bck.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_MESSAGE_BCK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_MESSAGE_BCK';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_field.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_FIELD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_FIELD';

spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert_software.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_SOFTWARE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_SOFTWARE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sys_alert_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_ALERT_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_ALERT_PROF';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surg_prot_task_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_TASK_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_TASK_DET';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_surg_prot_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_waiting_line.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_LINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_LINE';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_QUEUE';
spool off


spool 'c:\mighdc\alert\grants\synonym_wl_patient_sonho_transfered.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO_TRANSFERED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO_TRANSFERED';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_permission.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_PERMISSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_PERMISSION';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_family.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_cli_attributes.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CLI_ATTRIBUTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CLI_ATTRIBUTES';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_blood_group.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_BLOOD_GROUP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_BLOOD_GROUP';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_allergy_hist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_ALLERGY_HIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_ALLERGY_HIST';
spool off

spool 'c:\mighdc\alert\grants\synonym_parameter_analysis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PARAMETER_ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PARAMETER_ANALYSIS';

spool off

spool 'c:\mighdc\alert\grants\synonym_nurse_actv_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_ACTV_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_ACTV_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_nurse_activity_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NURSE_ACTIVITY_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NURSE_ACTIVITY_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_obs_photo.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBS_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBS_PHOTO';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_institution.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_INSTITUTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_INSTITUTION';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_drug_usage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DRUG_USAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DRUG_USAGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_diagnosis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_DIAGNOSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_DIAGNOSIS';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_anamnesis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_ANAMNESIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_ANAMNESIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_take_time.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_TAKE_TIME','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_TAKE_TIME';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_req_supply.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_REQ_SUPPLY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_REQ_SUPPLY';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_protocols.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_pharma.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PHARMA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PHARMA';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_disc_help.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISC_HELP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISC_HELP';

spool off

spool 'c:\mighdc\alert\grants\synonym_diagnosis_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGNOSIS_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGNOSIS_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_param.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PARAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PARAM';
spool off

spool 'c:\mighdc\alert\grants\synonym_ch_contents.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CH_CONTENTS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CH_CONTENTS';
spool off


spool 'c:\mighdc\alert\grants\synonym_body_part_image.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BODY_PART_IMAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BODY_PART_IMAGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_body_part.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BODY_PART','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BODY_PART';
spool off

spool 'c:\mighdc\alert\grants\synonym_board_grouping.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD_GROUPING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD_GROUPING';
spool off


spool 'c:\mighdc\alert\grants\synonym_analysis.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS';
spool off

spool 'c:\mighdc\alert\grants\synonym_documentation_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_template.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_TEMPLATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_TEMPLATE';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_quantification.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_QUANTIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_QUANTIFICATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_doc_element_quantif.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT_QUANTIF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT_QUANTIF';
spool off

spool 'c:\mighdc\alert\grants\package_pk_p1_sync.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_P1_SYNC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_P1_SYNC';
spool off

spool 'c:\mighdc\alert\grants\package_pk_episode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EPISODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EPISODE';

spool off

spool 'c:\mighdc\alert\grants\package_pk_movement.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_MOVEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_MOVEMENT';
spool off

spool 'c:\mighdc\alert\grants\package_pk_login.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_LOGIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_LOGIN';
spool off

spool 'c:\mighdc\alert\grants\package_pk_documentation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DOCUMENTATION';
spool off


spool 'c:\mighdc\alert\grants\package_pk_inp_hidrics.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_HIDRICS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_HIDRICS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_episode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_EPISODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_EPISODE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_utils.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_UTILS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_UTILS';
spool off


spool 'c:\mighdc\alert\grants\package_pk_edis_summary.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_SUMMARY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_SUMMARY';
spool off

spool 'c:\mighdc\alert\grants\package_pk_doc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DOC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DOC';
spool off

spool 'c:\mighdc\alert\grants\package_pk_match.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_MATCH','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_MATCH';
spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_grid.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_GRID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_GRID';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wlfinger_print.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLFINGER_PRINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLFINGER_PRINT';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_agp.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_AGP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_AGP';
spool off

spool 'c:\mighdc\alert\grants\table_analysis_old.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_OLD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_OLD';

spool off

spool 'c:\mighdc\alert\grants\table_anesthesia_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANESTHESIA_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANESTHESIA_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_board_grouping.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BOARD_GROUPING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BOARD_GROUPING';
spool off

spool 'c:\mighdc\alert\grants\table_category.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CATEGORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CATEGORY';
spool off


spool 'c:\mighdc\alert\grants\table_clin_srv_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLIN_SRV_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLIN_SRV_TYPE';
spool off

spool 'c:\mighdc\alert\grants\table_cli_rec_req_mov.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CLI_REC_REQ_MOV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CLI_REC_REQ_MOV';
spool off

spool 'c:\mighdc\alert\grants\table_consult_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONSULT_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONSULT_REQ';
spool off


spool 'c:\mighdc\alert\grants\table_consult_req_prof.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONSULT_REQ_PROF','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONSULT_REQ_PROF';
spool off

spool 'c:\mighdc\alert\grants\table_create$java$lob$table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CREATE$JAVA$LOB$TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CREATE$JAVA$LOB$TABLE';
spool off

spool 'c:\mighdc\alert\grants\table_criteria.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CRITERIA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CRITERIA';
spool off

spool 'c:\mighdc\alert\grants\table_critical_care.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CRITICAL_CARE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CRITICAL_CARE';
spool off

spool 'c:\mighdc\alert\grants\table_critical_care_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CRITICAL_CARE_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CRITICAL_CARE_DET';
spool off

spool 'c:\mighdc\alert\grants\table_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\table_diagram_detail.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_DETAIL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_DETAIL';

spool off

spool 'c:\mighdc\alert\grants\table_diagram_tools.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DIAGRAM_TOOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DIAGRAM_TOOLS';
spool off

spool 'c:\mighdc\alert\grants\table_disc_help.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISC_HELP','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISC_HELP';
spool off

spool 'c:\mighdc\alert\grants\table_district.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISTRICT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISTRICT';
spool off


spool 'c:\mighdc\alert\grants\table_doc_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_AREA';
spool off

spool 'c:\mighdc\alert\grants\table_doc_element.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOC_ELEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOC_ELEMENT';
spool off

spool 'c:\mighdc\alert\grants\table_drug_brand.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_BRAND','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_BRAND';
spool off


spool 'c:\mighdc\alert\grants\table_drug_prescription.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESCRIPTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESCRIPTION';
spool off

spool 'c:\mighdc\alert\grants\table_epis_body_painting_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_BODY_PAINTING_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_BODY_PAINTING_DET';
spool off

spool 'c:\mighdc\alert\grants\table_epis_complaint.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_COMPLAINT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_COMPLAINT';
spool off

spool 'c:\mighdc\alert\grants\table_estate.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ESTATE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ESTATE';
spool off

spool 'c:\mighdc\alert\grants\table_exam_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_external_cause.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXTERNAL_CAUSE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXTERNAL_CAUSE';
spool off

spool 'c:\mighdc\alert\grants\table_home.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HOME','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HOME';

spool off

spool 'c:\mighdc\alert\grants\table_icnp_classification.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_CLASSIFICATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_CLASSIFICATION';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_epis_diagnosis_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_EPIS_DIAGNOSIS_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_EPIS_DIAGNOSIS_060425';
spool off

spool 'c:\mighdc\alert\grants\table_icnp_folder_060425.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_FOLDER_060425','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_FOLDER_060425';
spool off


spool 'c:\mighdc\alert\grants\table_inf_atc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_ATC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_ATC';
spool off

spool 'c:\mighdc\alert\grants\table_inf_cft.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_CFT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_CFT';
spool off

spool 'c:\mighdc\alert\grants\table_inf_dcipt.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_DCIPT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_DCIPT';
spool off


spool 'c:\mighdc\alert\grants\table_inf_diploma.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_DIPLOMA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_DIPLOMA';
spool off

spool 'c:\mighdc\alert\grants\table_inf_tratamento.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INF_TRATAMENTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INF_TRATAMENTO';
spool off

spool 'c:\mighdc\alert\grants\table_interv_physiatry_area.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PHYSIATRY_AREA','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PHYSIATRY_AREA';
spool off

spool 'c:\mighdc\alert\grants\table_interv_presc_det.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_PRESC_DET';
spool off

spool 'c:\mighdc\alert\grants\table_interv_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','INTERV_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'INTERV_ROOM';
spool off

spool 'c:\mighdc\alert\grants\table_language.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','LANGUAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'LANGUAGE';
spool off

spool 'c:\mighdc\alert\grants\table_manchester.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANCHESTER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANCHESTER';

spool off

spool 'c:\mighdc\alert\grants\table_manipulated.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANIPULATED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANIPULATED';
spool off

spool 'c:\mighdc\alert\grants\table_manipulated_ingredient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MANIPULATED_INGREDIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MANIPULATED_INGREDIENT';
spool off

spool 'c:\mighdc\alert\grants\table_material.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL';
spool off


spool 'c:\mighdc\alert\grants\table_material_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\table_mdm_evaluation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MDM_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MDM_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\table_monitorization.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MONITORIZATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MONITORIZATION';
spool off


spool 'c:\mighdc\alert\grants\table_pat_ext_sys.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_EXT_SYS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_EXT_SYS';
spool off

spool 'c:\mighdc\alert\grants\table_pat_vaccine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_VACCINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_VACCINE';
spool off

spool 'c:\mighdc\alert\grants\table_positioning.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','POSITIONING','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'POSITIONING';
spool off

spool 'c:\mighdc\alert\grants\table_prof_access.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\table_prof_soft_inst.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_SOFT_INST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_SOFT_INST';
spool off

spool 'c:\mighdc\alert\grants\table_prof_team.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_TEAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_TEAM';
spool off

spool 'c:\mighdc\alert\grants\table_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROTOCOLS';

spool off

spool 'c:\mighdc\alert\grants\table_p1_history.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_HISTORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_HISTORY';
spool off

spool 'c:\mighdc\alert\grants\table_p1_prblm_rec_procedure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_PRBLM_REC_PROCEDURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_PRBLM_REC_PROCEDURE';
spool off

spool 'c:\mighdc\alert\grants\table_p1_recomended_procedure.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','P1_RECOMENDED_PROCEDURE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'P1_RECOMENDED_PROCEDURE';
spool off


spool 'c:\mighdc\alert\grants\table_recm.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RECM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RECM';
spool off

spool 'c:\mighdc\alert\grants\table_rep_section.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','REP_SECTION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'REP_SECTION';
spool off

spool 'c:\mighdc\alert\grants\table_room_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ROOM_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ROOM_DEP_CLIN_SERV';
spool off


spool 'c:\mighdc\alert\grants\table_snomed_descriptions.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SNOMED_DESCRIPTIONS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SNOMED_DESCRIPTIONS';
spool off

spool 'c:\mighdc\alert\grants\table_social_class.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_CLASS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_CLASS';
spool off

spool 'c:\mighdc\alert\grants\table_social_episode.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOCIAL_EPISODE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOCIAL_EPISODE';
spool off

spool 'c:\mighdc\alert\grants\table_soft_lang.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SOFT_LANG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SOFT_LANG';
spool off

spool 'c:\mighdc\alert\grants\table_sr_chklist.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_CHKLIST','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_CHKLIST';
spool off

spool 'c:\mighdc\alert\grants\table_sr_interv_group_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_INTERV_GROUP_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_INTERV_GROUP_DET';
spool off

spool 'c:\mighdc\alert\grants\table_sr_pat_status.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PAT_STATUS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PAT_STATUS';

spool off

spool 'c:\mighdc\alert\grants\table_sr_pre_eval.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_PRE_EVAL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_PRE_EVAL';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surg_protocol.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROTOCOL','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROTOCOL';
spool off

spool 'c:\mighdc\alert\grants\table_sr_surg_prot_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURG_PROT_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURG_PROT_TASK';
spool off


spool 'c:\mighdc\alert\grants\table_sys_session.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_SESSION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_SESSION';
spool off

spool 'c:\mighdc\alert\grants\table_sys_toolbar.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_TOOLBAR','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_TOOLBAR';
spool off

spool 'c:\mighdc\alert\grants\table_time_unit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TIME_UNIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TIME_UNIT';
spool off


spool 'c:\mighdc\alert\grants\table_toad_plan_table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TOAD_PLAN_TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TOAD_PLAN_TABLE';
spool off

spool 'c:\mighdc\alert\grants\table_transp_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_REQ';
spool off

spool 'c:\mighdc\alert\grants\table_treatment_management.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TREATMENT_MANAGEMENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TREATMENT_MANAGEMENT';
spool off

spool 'c:\mighdc\alert\grants\table_viewer_synchronize.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VIEWER_SYNCHRONIZE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VIEWER_SYNCHRONIZE';
spool off

spool 'c:\mighdc\alert\grants\table_wl_queue.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_QUEUE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_QUEUE';
spool off

spool 'c:\mighdc\alert\grants\synonym_adverse_exam_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ADVERSE_EXAM_ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ADVERSE_EXAM_ALLERGY';
spool off

spool 'c:\mighdc\alert\grants\synonym_material_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_TYPE';

spool off

spool 'c:\mighdc\alert\grants\synonym_material_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','MATERIAL_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'MATERIAL_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_isencao.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ISENCAO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ISENCAO';
spool off

spool 'c:\mighdc\alert\grants\synonym_icnp_dictionary.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_DICTIONARY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_DICTIONARY';
spool off


spool 'c:\mighdc\alert\grants\synonym_icnp_composition_term.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ICNP_COMPOSITION_TERM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ICNP_COMPOSITION_TERM';
spool off

spool 'c:\mighdc\alert\grants\synonym_hemo_req_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_REQ_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_REQ_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_hemo_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','HEMO_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'HEMO_PROTOCOLS';
spool off


spool 'c:\mighdc\alert\grants\synonym_exam_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EXAM_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EXAM_DRUG';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sample_recipient.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SAMPLE_RECIPIENT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SAMPLE_RECIPIENT';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_photo.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_PHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_PHOTO';
spool off

spool 'c:\mighdc\alert\grants\synonym_prof_cat.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PROF_CAT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PROF_CAT';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_patient_sonho.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_PATIENT_SONHO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_PATIENT_SONHO';
spool off

spool 'c:\mighdc\alert\grants\synonym_vital_sign.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VITAL_SIGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VITAL_SIGN';

spool off

spool 'c:\mighdc\alert\grants\synonym_vaccine.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','VACCINE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'VACCINE';
spool off

spool 'c:\mighdc\alert\grants\synonym_transp_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRANSP_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRANSP_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_toad_plan_table.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TOAD_PLAN_TABLE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TOAD_PLAN_TABLE';
spool off


spool 'c:\mighdc\alert\grants\synonym_sys_application_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SYS_APPLICATION_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SYS_APPLICATION_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_surgery_record.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_SURGERY_RECORD','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_SURGERY_RECORD';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_receive_proc_notes.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RECEIVE_PROC_NOTES','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RECEIVE_PROC_NOTES';
spool off


spool 'c:\mighdc\alert\grants\synonym_wound_type.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WOUND_TYPE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WOUND_TYPE';
spool off

spool 'c:\mighdc\alert\grants\synonym_wl_waiting_room.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','WL_WAITING_ROOM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'WL_WAITING_ROOM';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_necessity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_NECESSITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_NECESSITY';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_job.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_JOB','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_JOB';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_ginec_obstet.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_GINEC_OBSTET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_GINEC_OBSTET';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_family_member.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_FAMILY_MEMBER','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_FAMILY_MEMBER';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_doc.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_DOC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_DOC';

spool off

spool 'c:\mighdc\alert\grants\synonym_pat_delivery.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_DELIVERY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_DELIVERY';
spool off

spool 'c:\mighdc\alert\grants\synonym_pat_child_clin_rec.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PAT_CHILD_CLIN_REC','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PAT_CHILD_CLIN_REC';
spool off

spool 'c:\mighdc\alert\grants\synonym_necessity.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','NECESSITY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'NECESSITY';
spool off


spool 'c:\mighdc\alert\grants\synonym_epis_task.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TASK','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TASK';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_recomend.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_RECOMEND','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_RECOMEND';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_obs_exam.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_OBS_EXAM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_OBS_EXAM';
spool off


spool 'c:\mighdc\alert\grants\synonym_drug_presc_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_PRESC_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_PRESC_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_drug_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DRUG_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DRUG_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_discharge_reason.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DISCHARGE_REASON','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DISCHARGE_REASON';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_prep_mesg.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_PREP_MESG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_PREP_MESG';
spool off

spool 'c:\mighdc\alert\grants\synonym_consult_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','CONSULT_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'CONSULT_REQ';
spool off

spool 'c:\mighdc\alert\grants\synonym_dependency.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DEPENDENCY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DEPENDENCY';
spool off

spool 'c:\mighdc\alert\grants\synonym_bed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','BED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'BED';

spool off

spool 'c:\mighdc\alert\grants\synonym_analy_parm_limit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALY_PARM_LIMIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALY_PARM_LIMIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_analysis_dep_clin_serv.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ANALYSIS_DEP_CLIN_SERV','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ANALYSIS_DEP_CLIN_SERV';
spool off

spool 'c:\mighdc\alert\grants\synonym_allergy.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','ALLERGY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'ALLERGY';
spool off


spool 'c:\mighdc\alert\grants\synonym_sr_pos_eval_visit.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POS_EVAL_VISIT','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POS_EVAL_VISIT';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_pos_eval_det.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_POS_EVAL_DET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_POS_EVAL_DET';
spool off

spool 'c:\mighdc\alert\grants\synonym_sr_reserv_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','SR_RESERV_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'SR_RESERV_REQ';
spool off


spool 'c:\mighdc\alert\grants\synonym_documentation.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','DOCUMENTATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'DOCUMENTATION';
spool off

spool 'c:\mighdc\alert\grants\synonym_epis_triage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','EPIS_TRIAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'EPIS_TRIAGE';
spool off

spool 'c:\mighdc\alert\grants\synonym_triage.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','TRIAGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'TRIAGE';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_evaluation.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_EVALUATION','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_EVALUATION';
spool off

spool 'c:\mighdc\alert\grants\package_pk_reset.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_RESET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_RESET';
spool off

spool 'c:\mighdc\alert\grants\package_pk_patphoto.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PATPHOTO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PATPHOTO';
spool off

spool 'c:\mighdc\alert\grants\package_pk_vital_sign.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_VITAL_SIGN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_VITAL_SIGN';

spool off

spool 'c:\mighdc\alert\grants\package_pk_sr_reset.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SR_RESET','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SR_RESET';
spool off

spool 'c:\mighdc\alert\grants\package_pk_protocols.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_PROTOCOLS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_PROTOCOLS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_clinical_info.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_CLINICAL_INFO','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_CLINICAL_INFO';
spool off


spool 'c:\mighdc\alert\grants\package_pk_history.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_HISTORY','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_HISTORY';
spool off

spool 'c:\mighdc\alert\grants\package_pk_access.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_ACCESS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_ACCESS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_sysdomain.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SYSDOMAIN','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SYSDOMAIN';
spool off


spool 'c:\mighdc\alert\grants\package_pk_wlmed.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLMED','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLMED';
spool off

spool 'c:\mighdc\alert\grants\package_pk_consult_req.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_CONSULT_REQ','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_CONSULT_REQ';
spool off

spool 'c:\mighdc\alert\grants\package_pk_inp_grid.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_INP_GRID','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_INP_GRID';
spool off

spool 'c:\mighdc\alert\grants\package_pk_edis_discharge.sql'

select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_EDIS_DISCHARGE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_EDIS_DISCHARGE';
spool off

spool 'c:\mighdc\alert\grants\package_rpe_experiencias.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','RPE_EXPERIENCIAS','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'RPE_EXPERIENCIAS';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wladm.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLADM','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLADM';
spool off

spool 'c:\mighdc\alert\grants\package_pk_wlcore.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_WLCORE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_WLCORE';

spool off

spool 'c:\mighdc\alert\grants\package_pk_drug.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_DRUG','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_DRUG';
spool off

spool 'c:\mighdc\alert\grants\package_pk_schedule.sql'
select replace(dbms_metadata.get_dependent_ddl('OBJECT_GRANT','PK_SCHEDULE','ALERT'),'"','') text from dba_objects where owner = 'ALERT' and object_name = 'PK_SCHEDULE';
spool off


spool 'c:\mighdc\alert\grants\execute_grants.sql'
select '@@' || lower(do.object_type) || '_' || lower(table_name) || '.sql' from dba_tab_privs dtp, dba_objects do where dtp.owner = 'ALERT' and do.object_name = dtp.table_name and do.object_type not in ('PACKAGE BODY');
spool off


spool 'c:\mighdc\alert\grants\execute_grants.sql'
select '@@' || lower(do.object_type) || '_' || lower(table_name) || '.sql' from dba_tab_privs dtp, dba_objects do where dtp.owner = 'ALERT' and do.object_name = dtp.table_name and do.object_type not in ('PACKAGE BODY');
spool off

