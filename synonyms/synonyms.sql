set feedback off
set termout off
set echo off
set heading off
set verify off
set pau off
set lines 1000
set long 10000
set trims on
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SEGMENT_ATTRIBUTES', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'STORAGE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'TABLESPACE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'PRETTY', true)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'CONSTRAINTS_AS_ALTER', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SQLTERMINATOR', true)
col text format A1000 word wrap

spool 'c:\mighdc\alert\synonyms\table_number.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TABLE_NUMBER','PUBLIC'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\table_varchar.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TABLE_VARCHAR','PUBLIC'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\adverse_exam_allergy.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ADVERSE_EXAM_ALLERGY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\matr_scheduled.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','MATR_SCHEDULED','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\matr_room.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MATR_ROOM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\matr_dep_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MATR_DEP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\material_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MATERIAL_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\material_req_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MATERIAL_REQ_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\material_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MATERIAL_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\material_protocols.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MATERIAL_PROTOCOLS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\material.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MATERIAL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\manchester.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MANCHESTER','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\language.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','LANGUAGE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\java$options.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','JAVA$OPTIONS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\java$class$md5$table.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','JAVA$CLASS$MD5$TABLE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\isencao.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ISENCAO','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\interv_room.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','INTERV_ROOM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\interv_protocols.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INTERV_PROTOCOLS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\interv_presc_plan.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INTERV_PRESC_PLAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\interv_presc_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INTERV_PRESC_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\interv_prescription.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INTERV_PRESCRIPTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\interv_prep_msg.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INTERV_PREP_MSG','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\interv_physiatry_area.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INTERV_PHYSIATRY_AREA','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\interv_ext_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INTERV_EXT_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\interv_drug.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INTERV_DRUG','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\interv_dep_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INTERV_DEP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\intervention.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INTERVENTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\instit_ext_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INSTIT_EXT_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\institution.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','INSTITUTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\implementation.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','IMPLEMENTATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_term.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_TERM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_relationship.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_RELATIONSHIP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_predefined_action.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_PREDEFINED_ACTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\icnp_morph.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_MORPH','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_folder.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_FOLDER','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_epis_interv_plan.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_EPIS_INTERV_PLAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\icnp_epis_intervention.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_EPIS_INTERVENTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_epis_diag_interv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_EPIS_DIAG_INTERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_epis_diagnosis.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_EPIS_DIAGNOSIS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\icnp_dictionary.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_DICTIONARY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_compo_inst.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_COMPO_INST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_compo_folder.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_COMPO_FOLDER','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_composition_term.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_COMPOSITION_TERM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_composition.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_COMPOSITION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_classification.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_CLASSIFICATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\icnp_axis.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ICNP_AXIS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\home.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','HOME','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\hemo_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','HEMO_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\hemo_req_supply.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','HEMO_REQ_SUPPLY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\hemo_req_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','HEMO_REQ_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\hemo_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','HEMO_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\hemo_protocols.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','HEMO_PROTOCOLS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\health_plan.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','HEALTH_PLAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\harvest.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','HARVEST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\habit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','HABIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\grid_task.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','GRID_TASK','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\ginec_obstet.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','GINEC_OBSTET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\external_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXTERNAL_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\external_cause.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXTERNAL_CAUSE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\exam_room.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_ROOM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\exam_result.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_RESULT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\exam_req_ext_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_REQ_EXT_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\exam_req_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_REQ_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\exam_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\exam_protocols.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_PROTOCOLS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\exam_prep_mesg.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_PREP_MESG','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\exam_group.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_GROUP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\exam_ext_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_EXT_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\exam_egp.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_EGP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\exam_drug.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_DRUG','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\exam_dep_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM_DEP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\exam.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EXAM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\event.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EVENT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\estate.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ESTATE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_type_room.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_TYPE_ROOM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\epis_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_interv_desc.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_INTERV_DESC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_epis_interv_desc.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_EPIS_INTERV_DESC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sr_chklist_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_CHKLIST_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_chklist.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_CHKLIST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_cancel_reason.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_CANCEL_REASON','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sqln_explain_plan.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','SQLN_EXPLAIN_PLAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\spec_sys_appar.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SPEC_SYS_APPAR','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\speciality.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SPECIALITY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\soft_inst_services.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SOFT_INST_SERVICES','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\soft_inst_impl.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SOFT_INST_IMPL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\software_institution.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SOFTWARE_INSTITUTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\software.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SOFTWARE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\snomed_relationships.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SNOMED_RELATIONSHIPS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\snomed_descriptions.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SNOMED_DESCRIPTIONS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\snomed_concepts.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SNOMED_CONCEPTS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\slot.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SLOT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\serv_sched_access.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SERV_SCHED_ACCESS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sch_service.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCH_SERVICE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sch_resource.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCH_RESOURCE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sch_prof_outp.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCH_PROF_OUTP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sch_group.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCH_GROUP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\school.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCHOOL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\scholarship.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCHOLARSHIP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\schedule_sr2.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCHEDULE_SR2','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\schedule_sr.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCHEDULE_SR','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\schedule_outp.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCHEDULE_OUTP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\schedule_alter.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCHEDULE_ALTER','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\schedule.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCHEDULE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sample_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SAMPLE_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sample_text_type_cat.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SAMPLE_TEXT_TYPE_CAT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sample_text_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SAMPLE_TEXT_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sample_text_prof.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','SAMPLE_TEXT_PROF','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sample_text_freq.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SAMPLE_TEXT_FREQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sample_text.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SAMPLE_TEXT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sample_recipient.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SAMPLE_RECIPIENT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\room_scheduled.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ROOM_SCHEDULED','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\room_ext_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ROOM_EXT_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\room_dep_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ROOM_DEP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\room.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ROOM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\religion.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','RELIGION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\rb_grid_doctor.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','RB_GRID_DOCTOR','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\quest_temp_explain.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','QUEST_TEMP_EXPLAIN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\quest_sl_temp_explain1.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','QUEST_SL_TEMP_EXPLAIN1','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\protoc_diag.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROTOC_DIAG','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\protocols.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROTOCOLS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_team_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_TEAM_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_team.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_TEAM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_soft_inst.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_SOFT_INST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\prof_scheduled.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_SCHEDULED','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_room.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_ROOM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_profile_template.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_PROFILE_TEMPLATE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\prof_preferences.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_PREFERENCES','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_photo.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_PHOTO','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_in_out.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_IN_OUT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\prof_institution.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_INSTITUTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_func.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_FUNC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_ext_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_EXT_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_epis_interv.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_EPIS_INTERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_doc.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_DOC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_dep_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_DEP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_cat.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_CAT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\prof_access_field_func.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_ACCESS_FIELD_FUNC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\prof_access.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROF_ACCESS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\profile_templ_acc_func.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROFILE_TEMPL_ACC_FUNC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\profile_templ_access.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROFILE_TEMPL_ACCESS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\profile_template.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROFILE_TEMPLATE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\professional.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PROFESSIONAL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\prep_message.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PREP_MESSAGE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pregnancy_risk_eval.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PREGNANCY_RISK_EVAL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\plan_table.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PLAN_TABLE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\periodic_exam_educ.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','PERIODIC_EXAM_EDUC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_vaccine.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_VACCINE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_soc_attributes.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_SOC_ATTRIBUTES','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wl_patient_sonho_imp.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_PATIENT_SONHO_IMP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\wl_patient_sonho.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_PATIENT_SONHO','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wl_msg_queue.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_MSG_QUEUE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wl_mach_prof_queue.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_MACH_PROF_QUEUE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\wl_machine.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_MACHINE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wl_demo_bck.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_DEMO_BCK','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wl_demo.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_DEMO','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\wl_call_queue.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_CALL_QUEUE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\white_reason.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WHITE_REASON','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\vs_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VS_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\vital_sign_relation.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','VITAL_SIGN_RELATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\vital_sign_read.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VITAL_SIGN_READ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\vital_sign_desc.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VITAL_SIGN_DESC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\vital_sign.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VITAL_SIGN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\visit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VISIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\vbz$object_stats.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VBZ$OBJECT_STATS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\vaccine_presc_plan.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VACCINE_PRESC_PLAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\vaccine_presc_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VACCINE_PRESC_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\vaccine_prescription.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VACCINE_PRESCRIPTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\vaccine_dep_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VACCINE_DEP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\vaccine.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VACCINE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\transp_req_group.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TRANSP_REQ_GROUP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\transp_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TRANSP_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\transp_ent_inst.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','TRANSP_ENT_INST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\transp_entity.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TRANSP_ENTITY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\transport_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TRANSPORT_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\transportation.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TRANSPORTATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\translation.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TRANSLATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\toad_plan_table.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TOAD_PLAN_TABLE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\toad_plan_sql.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TOAD_PLAN_SQL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\time_unit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TIME_UNIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\time_event_group.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TIME_EVENT_GROUP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\time.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TIME','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sys_toolbar.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_TOOLBAR','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_time_event_group.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_TIME_EVENT_GROUP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_shortcut.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_SHORTCUT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_session.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_SESSION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_screen_area.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_SCREEN_AREA','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_request.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_REQUEST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_message_bck.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_MESSAGE_BCK','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\sys_message.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_MESSAGE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_functionality.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_FUNCTIONALITY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_field.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_FIELD','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sys_error.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_ERROR','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_domain.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_DOMAIN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_config.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_CONFIG','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sys_button_prop_bck.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_BUTTON_PROP_BCK','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_button_prop.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_BUTTON_PROP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_button_group.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_BUTTON_GROUP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_button.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_BUTTON','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_btn_sbg.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_BTN_SBG','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_btn_crit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_BTN_CRIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_application_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_APPLICATION_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\sys_application_area.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_APPLICATION_AREA','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_alert_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_ALERT_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_alert_software.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_ALERT_SOFTWARE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sys_alert_prof_deny.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_ALERT_PROF_DENY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_alert_profile.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_ALERT_PROFILE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_alert_prof.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_ALERT_PROF','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sys_alert_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_ALERT_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_alert.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_ALERT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\system_apparati.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYSTEM_APPARATI','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_surg_task.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_SURG_TASK','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_surg_prot_task_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_SURG_PROT_TASK_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_surg_prot_task.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_SURG_PROT_TASK','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_surg_prot_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_SURG_PROT_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\sr_surg_protocol.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_SURG_PROTOCOL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_surgery_record.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_SURGERY_RECORD','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_receive_proc_notes.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_RECEIVE_PROC_NOTES','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sr_receive_proc_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_RECEIVE_PROC_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_receive_proc.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_RECEIVE_PROC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_prof_team_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_PROF_TEAM_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sr_prof_recov_schd.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_PROF_RECOV_SCHD','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\xxx.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','XXX','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wound_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WOUND_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wound_treat.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','WOUND_TREAT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wound_eval_charac.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WOUND_EVAL_CHARAC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wound_evaluation.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WOUND_EVALUATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wound_charac.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WOUND_CHARAC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\wl_waiting_room.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_WAITING_ROOM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wl_waiting_line_0104.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_WAITING_LINE_0104','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wl_waiting_line.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_WAITING_LINE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\wl_topics.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_TOPICS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wl_status.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_STATUS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wl_queue.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_QUEUE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\wl_prof_room.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_PROF_ROOM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\wl_patient_sonho_transfered.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','WL_PATIENT_SONHO_TRANSFERED','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_sick_leave.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_SICK_LEAVE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_prob_visit.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_PROB_VISIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_problem_hist.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_PROBLEM_HIST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_problem.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_PROBLEM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_pregn_measure.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_PREGN_MEASURE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\pat_pregn_fetus_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_PREGN_FETUS_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_pregn_fetus_biom.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_PREGN_FETUS_BIOM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_pregn_fetus.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_PREGN_FETUS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\pat_pregnancy_risk.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_PREGNANCY_RISK','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_pregnancy.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_PREGNANCY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_photo.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_PHOTO','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\pat_permission.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_PERMISSION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_notes.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_NOTES','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_necessity.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_NECESSITY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_med_decl.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_MED_DECL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_medication.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_MEDICATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_job.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_JOB','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_health_plan.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_HEALTH_PLAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\pat_habit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_HABIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_ginec_obstet.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_GINEC_OBSTET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_ginec.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_GINEC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\pat_fam_soc_hist.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_FAM_SOC_HIST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_family_prof.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_FAMILY_PROF','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_family_member.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_FAMILY_MEMBER','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\pat_family_disease.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_FAMILY_DISEASE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_family.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_FAMILY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_ext_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_EXT_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_doc.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_DOC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_delivery.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_DELIVERY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_cntrceptiv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_CNTRCEPTIV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_cli_attributes.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_CLI_ATTRIBUTES','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\pat_child_feed_dev.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_CHILD_FEED_DEV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_child_clin_rec.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_CHILD_CLIN_REC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_blood_group.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_BLOOD_GROUP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\pat_allergy_hist.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_ALLERGY_HIST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pat_allergy.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PAT_ALLERGY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\patient.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PATIENT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\param_analysis_ext_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PARAM_ANALYSIS_EXT_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\parameter_analysis.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','PARAMETER_ANALYSIS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\p1_recomended_procedure.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','P1_RECOMENDED_PROCEDURE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\p1_problem_dep_clin_serv.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','P1_PROBLEM_DEP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\p1_problem.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','P1_PROBLEM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\p1_prblm_rec_procedure.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','P1_PRBLM_REC_PROCEDURE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\p1_history.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','P1_HISTORY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\p1_ext_req_tracking.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','P1_EXT_REQ_TRACKING','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\p1_external_request.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','P1_EXTERNAL_REQUEST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\p1_doc_external_request.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','P1_DOC_EXTERNAL_REQUEST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\p1_doc_external.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','P1_DOC_EXTERNAL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\p1_documents_done.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','P1_DOCUMENTS_DONE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\p1_documents.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','P1_DOCUMENTS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\outlook.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','OUTLOOK','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\origin.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ORIGIN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\opinion_prof.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','OPINION_PROF','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\opinion.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','OPINION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\occupation.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','OCCUPATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\nurse_tea_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','NURSE_TEA_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\nurse_discharge.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','NURSE_DISCHARGE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\nurse_actv_req_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','NURSE_ACTV_REQ_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\nurse_activity_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','NURSE_ACTIVITY_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\necessity.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','NECESSITY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\movement.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MOVEMENT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\monitorization_vs_plan.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MONITORIZATION_VS_PLAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\monitorization_vs.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MONITORIZATION_VS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\monitorization.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','MONITORIZATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_task.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_TASK','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_recomend.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_RECOMEND','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_readmission.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_READMISSION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_protocols.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_PROTOCOLS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_problem.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_PROBLEM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_photo.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_PHOTO','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\epis_obs_photo.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_OBS_PHOTO','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_obs_exam.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_OBS_EXAM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_observation.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_OBSERVATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\epis_man.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_MAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_interv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_INTERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_institution.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_INSTITUTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\epis_info.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_INFO','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_health_plan.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_HEALTH_PLAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_ext_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_EXT_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_drug_usage.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_DRUG_USAGE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_diagnosis.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_DIAGNOSIS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_body_painting_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_BODY_PAINTING_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_body_painting.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_BODY_PAINTING','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\epis_anamnesis.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_ANAMNESIS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\episode.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPISODE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_take_time.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_TAKE_TIME','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\drug_take_plan.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_TAKE_PLAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_route.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_ROUTE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_req_supply.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_REQ_SUPPLY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\drug_req_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_REQ_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_protocols.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_PROTOCOLS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_presc_plan.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_PRESC_PLAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_presc_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_PRESC_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_prescription.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_PRESCRIPTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_plan.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_PLAN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\drug_pharma_interaction.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_PHARMA_INTERACTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_pharma_class.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_PHARMA_CLASS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_pharma.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_PHARMA','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\drug_form.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_FORM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_dep_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_DEP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\drug_brand.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG_BRAND','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\drug.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DRUG','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\dr$d_idx$r.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DR$D_IDX$R','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\dr$d_idx$n.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DR$D_IDX$N','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\dr$d_idx$k.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','DR$D_IDX$K','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\dr$d_idx$i.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DR$D_IDX$I','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\disc_vs_valid.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DISC_VS_VALID','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\disc_help.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DISC_HELP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\discriminator_help.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DISCRIMINATOR_HELP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\discriminator.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DISCRIMINATOR','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\disch_reas_dest.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DISCH_REAS_DEST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\disch_prep_mesg.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DISCH_PREP_MESG','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\discharge_reason.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DISCHARGE_REASON','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\discharge_dest.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DISCHARGE_DEST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\discharge.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DISCHARGE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\diagnosis_dep_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DIAGNOSIS_DEP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\diagnosis.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','DIAGNOSIS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\analysis_result_par.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_RESULT_PAR','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\analysis_result.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_RESULT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\analysis_req_par.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_REQ_PAR','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\analysis_req_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_REQ_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\analysis_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\analysis_protocols.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_PROTOCOLS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\analysis_prep_mesg.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_PREP_MESG','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\analysis_param.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_PARAM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\analysis_harvest.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_HARVEST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\ch_contents_text.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CH_CONTENTS_TEXT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\ch_contents.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CH_CONTENTS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\child_feed_dev.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CHILD_FEED_DEV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\category.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','CATEGORY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\bp_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','BP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\body_part_image.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','BODY_PART_IMAGE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\body_part.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','BODY_PART','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\board_grouping.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','BOARD_GROUPING','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\board_group.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','BOARD_GROUP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\consult_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CONSULT_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\color.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','COLOR','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\cli_rec_req_mov.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CLI_REC_REQ_MOV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\cli_rec_req_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CLI_REC_REQ_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\cli_rec_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CLI_REC_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\clin_srv_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CLIN_SRV_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\clin_serv_ext_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CLIN_SERV_EXT_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\clin_record.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','CLIN_RECORD','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\clinical_service.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CLINICAL_SERVICE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\dep_clin_serv_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DEP_CLIN_SERV_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\dep_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DEP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\dependency.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DEPENDENCY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\department.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DEPARTMENT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\criteria.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CRITERIA','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\create$java$lob$table.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CREATE$JAVA$LOB$TABLE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\country.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','COUNTRY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\contraceptive.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CONTRACEPTIVE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\consult_req_prof.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','CONSULT_REQ_PROF','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\board.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','BOARD','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\birds_eye_view.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','BIRDS_EYE_VIEW','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\beye_view_screen.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','BEYE_VIEW_SCREEN','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\bed_schedule.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','BED_SCHEDULE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\bed.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','BED','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\anesthesia_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANESTHESIA_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\analy_parm_limit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALY_PARM_LIMIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\analysis_room.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_ROOM','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\analysis.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\analysis_agp.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_AGP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\analysis_dep_clin_serv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_DEP_CLIN_SERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\analysis_group.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_GROUP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\analysis_ext_sys.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ANALYSIS_EXT_SYS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\allergy.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ALLERGY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\adverse_interv_allergy.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ADVERSE_INTERV_ALLERGY','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\unit_measure.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','UNIT_MEASURE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sch_event_dcs.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCH_EVENT_DCS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sch_event.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SCH_EVENT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\origin_soft.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ORIGIN_SOFT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\sr_chklist_manual.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_CHKLIST_MANUAL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_evaluation.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_EVALUATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_equip_kit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_EQUIP_KIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sr_intervention.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_INTERVENTION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_pat_status.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_PAT_STATUS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_pat_status_notes.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_PAT_STATUS_NOTES','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sr_pos_eval_visit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_POS_EVAL_VISIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_posit_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_POSIT_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_nurse_rec.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_NURSE_REC','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_equip.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_EQUIP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_posit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_POSIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_pre_anest.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_PRE_ANEST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_receive_manual.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_RECEIVE_MANUAL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\sr_room_status.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_ROOM_STATUS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_surg_period.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_SURG_PERIOD','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_pre_anest_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_PRE_ANEST_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sr_epis_interv.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_EPIS_INTERV','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_eval_visit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_EVAL_VISIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_pos_eval_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_POS_EVAL_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\sr_surgery_rec_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_SURGERY_REC_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_reserv_req.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_RESERV_REQ','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_eval_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_EVAL_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sr_eval_notes.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','SR_EVAL_NOTES','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\documentation_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOCUMENTATION_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\triage_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TRIAGE_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\sys_element_crit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_ELEMENT_CRIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\sys_element.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','SYS_ELEMENT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_template_diagnosis.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_TEMPLATE_DIAGNOSIS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_template.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_TEMPLATE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\doc_quantification.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_QUANTIFICATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_qualification.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_QUALIFICATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_dimension.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_DIMENSION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\doc_criteria.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_CRITERIA','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_component.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_COMPONENT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\document_type.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOCUMENT_TYPE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_area.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_AREA','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\document_area.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOCUMENT_AREA','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\complaint.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','COMPLAINT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_element_rel.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_ELEMENT_REL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\triage_color.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TRIAGE_COLOR','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_documentation_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_DOCUMENTATION_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_documentation.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_DOCUMENTATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\epis_complaint.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_COMPLAINT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_element_quantif.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_ELEMENT_QUANTIF','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\documentation_rel.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOCUMENTATION_REL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\doc_element.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_ELEMENT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_element_crit.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_ELEMENT_CRIT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_element_qualif.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_ELEMENT_QUALIF','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\documentation.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOCUMENTATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_action_criteria.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_ACTION_CRITERIA','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_triage.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_TRIAGE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\triage.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TRIAGE','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\synonyms\epis_bartchart_det.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_BARTCHART_DET','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_bartchart.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_BARTCHART','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\action_criteria.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','ACTION_CRITERIA','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\floors.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','FLOORS','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\floors_dep_position.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','FLOORS_DEP_POSITION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\floors_department.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','FLOORS_DEPARTMENT','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\dimension.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DIMENSION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\vs_soft_inst.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','VS_SOFT_INST','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\doc_external.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','DOC_EXTERNAL','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\pk_sr_evaluation.syn'

select replace(replace(dbms_metadata.get_ddl('SYNONYM','PK_SR_EVALUATION','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\epis_prof_resp.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','EPIS_PROF_RESP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\synonyms\triage_board_group.syn'
select replace(replace(dbms_metadata.get_ddl('SYNONYM','TRIAGE_BOARD_GROUP','ALERT_VIEWER'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\synonyms\execute_synonyms.sql'
select '@@' || lower(synonym_name) || '.syn' from dba_synonyms where table_owner = 'ALERT';
spool off

