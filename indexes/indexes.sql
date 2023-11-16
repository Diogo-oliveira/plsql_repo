set feedback off
set termout off
set echo off
set heading off
set verify off
set pau off
set long 10000
set trims on
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SEGMENT_ATTRIBUTES', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'STORAGE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'TABLESPACE', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'PRETTY', true)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'CONSTRAINTS_AS_ALTER', false)
execute dbms_metadata.set_transform_param(dbms_metadata.session_transform, 'SQLTERMINATOR', true)
col text format A5000 word wrap

spool 'c:\mighdc\alert\indexes\abnormality.aby_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ABY_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\abnormality_nature.abn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ABN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\action_criteria.actc_eql_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ACTC_EQL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\action_criteria.actc_syec_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ACTC_SYEC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\action_criteria.actc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ACTC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\action_criteria.actc_doca_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ACTC_DOCA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\adverse_exam_allergy.eay_alg_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EAY_ALG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\adverse_exam_allergy.eay_exam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EAY_EXAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\adverse_exam_allergy.eay_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EAY_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\adverse_interv_allergy.aia_int_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AIA_INT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\adverse_interv_allergy.aia_alg_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AIA_ALG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\adverse_interv_allergy.aia_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AIA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\allergy.alg_alg_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALG_ALG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\allergy.alg_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALG_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\allergy.alg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\allergy_ext_sys.aes_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AES_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\allergy_ext_sys.aes_ess_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','AES_ESS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\allocation_bed.all_bed_bed_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALL_BED_BED_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\allocation_bed.all_bed_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALL_BED_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\allocation_bed.all_bed_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALL_BED_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\allocation_bed.all_bed_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALL_BED_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analy_parm_limit.apl_pany_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APL_PANY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analy_parm_limit.apl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis.analy_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ANALY_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis.analy_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ANALY_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis.analy_srt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ANALY_SRT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis.analy_ste_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ANALY_STE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis.analy_ect_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ANALY_ECT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_agp.anlg_agp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ANLG_AGP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_agp.anlg_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ANLG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_agp.anlg_analy_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ANLG_ANALY_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_alias.aas_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AAS_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_alias.aas_analy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AAS_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\analysis_alias.aas_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AAS_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_alias.aas_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AAS_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_alias.aas_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AAS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_dep_clin_serv.acst_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ACST_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_dep_clin_serv.acst_analy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ACST_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_dep_clin_serv.acst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ACST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_dep_clin_serv.acst_agp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ACST_AGP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_dep_clin_serv.acst_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ACST_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_dep_clin_serv.acst_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ACST_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_dep_clin_serv.acst_s_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ACST_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_desc.adc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ADC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_ext_sys_delete.aes_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_ext_sys_delete.aes_analy_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AES_ANALY_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\analysis_ext_sys_delete.aes_ess_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AES_ESS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_ext_sys_delete.aes_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AES_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_group.agp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AGP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_harvest.aht_harv_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AHT_HARV_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_harvest.aht_ard_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AHT_ARD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_harvest.aht_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AHT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_instit_soft.ais_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AIS_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_instit_soft.ais_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AIS_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_instit_soft.ais_ect_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AIS_ECT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_instit_soft.ais_analy_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','AIS_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_instit_soft.ais_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AIS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_loinc.alc_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALC_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_loinc.alc_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALC_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\analysis_loinc.alc_analy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALC_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_loinc.alc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_loinc_template.alt_analy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALT_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_loinc_template.alt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ALT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_param.apm_analy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APM_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_param.apm_pany_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APM_PANY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_param.apm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_param.apm_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APM_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_param.apm_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APM_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_parameter.apr_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','APR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_param_instit.api_apr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','API_APR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_param_instit.api_ais_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','API_AIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_param_instit.api_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','API_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\analysis_param_instit_sample.apis_api_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APIS_API_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_param_instit_sample.apis_srt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APIS_SRT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_param_instit_sample.apis_ste_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APIS_STE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_param_instit_sample.apis_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APIS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_prep_mesg.apg_pme_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APG_PME_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_prep_mesg.apg_analy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APG_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_prep_mesg.apg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_prep_mesg.apg_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APG_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_protocols.aps_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_protocols.aps_analy_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','APS_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_protocols.aps_prt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','APS_PRT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_schd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_schd_consult_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_SCHD_CONSULT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_req.art_prof_writes_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_PROF_WRITES_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_prof_authz_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_PROF_AUTHZ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_req.art_prof_app_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_PROF_APP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_flg_time_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_FLG_TIME_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_epis_status_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_EPIS_STATUS_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_epis_dest_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ART_EPIS_DEST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_epis_origin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_EPIS_ORIGIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_prt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_PRT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req.art_epis_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ART_EPIS_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\analysis_req_det.ard_ard_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARD_ARD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req_det.ard_mov_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARD_MOV_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req_det.ard_art_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARD_ART_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_req_det.ard_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARD_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req_det.ard_analy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARD_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req_det.ard_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_req_det.ard_flg_status_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARD_FLG_STATUS_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req_det.ard_room_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARD_ROOM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req_par.arp_ard_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARP_ARD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req_par.arp_pany_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ARP_PANY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_req_par.arp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_result.ares_ard_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARES_ARD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_result.ares_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARES_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\analysis_result.ares_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARES_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_result.ares_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARES_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_result.ares_analy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARES_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_result.ares_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_result.ares_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARES_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_result.ares_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARES_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\analysis_result_par.arlp_arp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARLP_ARP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_result_par.arlp_ares_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARLP_ARES_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_result_par.arlp_pany_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARLP_PANY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_result_par.arlp_prof_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ARLP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_result_par.arlp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARLP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_result_par.arlp_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARLP_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_room.arm_analy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARM_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\analysis_room.arm_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARM_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\analysis_room.arm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ARM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\anesthesia_type.anest_type_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ANEST_TYPE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\bed.bed_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BED_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\bed.bed_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BED_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\bed.bed_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BED_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\bed_schedule.bed_schd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BED_SCHD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\bed_schedule.bed_schd_bed_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BED_SCHD_BED_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\bed_schedule.bed_schd_schd_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BED_SCHD_SCHD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\beye_view_screen.bev_screen_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','BEV_SCREEN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\birds_eye_view.beyeview_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BEYEVIEW_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\birds_eye_view.beyeview_bed_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BEYEVIEW_BED_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\birds_eye_view.beyeview_bev_screen_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BEYEVIEW_BEV_SCREEN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\birds_eye_view.beyeview_cats_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BEYEVIEW_CATS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\birds_eye_view.beyeview_room_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BEYEVIEW_ROOM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\birds_eye_view.beyeview_si_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BEYEVIEW_SI_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\board.brd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BRD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\board_group.bgp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BGP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\board_grouping.bgg_brd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BGG_BRD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\board_grouping.bgg_bgp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BGG_BGP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\board_grouping.bgg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BGG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\body_part.bpt_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BPT_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\body_part.bpt_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','BPT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\body_part_image.bpi_int_name_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BPI_INT_NAME_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\body_part_image.bpi_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BPI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\bp_clin_serv.bcs_bpi_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BCS_BPI_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\bp_clin_serv.bcs_cse_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BCS_CSE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\building.building_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BUILDING_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\category.cat_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CAT_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\category.cat_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CAT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\category_sub.cats_cat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CATS_CAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\category_sub.cats_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CATS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\ch_contents.cct_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CCT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\ch_contents_text.ch_cct_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CH_CCT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\child_feed_dev.cfd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CFD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\clinical_service.cse_code_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','CSE_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\clinical_service.cse_cse_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CSE_CSE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\clinical_service.cse_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CSE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\clin_record.crn_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRN_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\clin_record.crn_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRN_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\clin_record.crn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\clin_record.crn_ptfam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRN_PTFAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\clin_serv_ext_sys.cses_cse_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CSES_CSE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\clin_serv_ext_sys.cses_ess_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CSES_ESS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\clin_serv_ext_sys.cses_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CSES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\clin_serv_ext_sys.cses_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CSES_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\clin_srv_type.cst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\clin_srv_type.cst_cse_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CST_CSE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req.crr_schd_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','CRR_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req.crr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req.crr_epis_dest_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRR_EPIS_DEST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req.crr_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRR_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req.crr_epis_origin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRR_EPIS_ORIGIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req.crr_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRR_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req.crr_prof_req_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRR_PROF_REQ_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\cli_rec_req.crr_room_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRR_ROOM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req_det.crrd_crn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRRD_CRN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req_det.crrd_crr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRRD_CRR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\cli_rec_req_det.crrd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRRD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req_det.crrd_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRRD_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req_mov.crm_crrd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRM_CRRD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req_mov.crm_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','CRM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req_mov.crm_prof_begin_mov_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRM_PROF_BEGIN_MOV_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req_mov.crm_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRM_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req_mov.crm_prof_end_mov_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRM_PROF_END_MOV_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req_mov.crm_prof_get_file_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRM_PROF_GET_FILE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\cli_rec_req_mov.crm_prof_req_transp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRM_PROF_REQ_TRANSP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\color.col_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','COL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\complaint.cmplt_doctemp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CMPLT_DOCTEMP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\complaint_triage_board.ctb_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CTB_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\complete_history.cmpl_hist_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CMPL_HIST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\complete_history.cmpl_hist_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CMPL_HIST_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\complete_history.cmpl_hist_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CMPL_HIST_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\complete_history.cmpl_hist_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CMPL_HIST_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req.crq_pat_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req.crq_prof_auth_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_PROF_AUTH_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req.crq_cse_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_CSE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req.crq_inst_requests_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_INST_REQUESTS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\consult_req.crq_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req.crq_prof_req_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_PROF_REQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req.crq_inst_requested_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_INST_REQUESTED_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\consult_req.crq_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req.crq_prof_appr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_PROF_APPR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req.crq_prof_proc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_PROF_PROC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\consult_req.crq_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req.crq_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req.crq_prof_requested_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRQ_PROF_REQUESTED_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req_prof.crp_prof_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','CRP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req_prof.crp_crq_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRP_CRQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\consult_req_prof.crp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\contraceptive.cpe_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CPE_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\contra_indic.cic_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CIC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\contra_indic.cic_iac_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CIC_IAC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\country.ctr_code_fk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CTR_CODE_FK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\country.ctr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CTR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\create$java$lob$table.sys_c005585.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_C005585','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\criteria.crt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CRT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\critical_care_read.ccrr_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CCRR_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\critical_care_read.ccrr_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CCRR_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\critical_care_read.ccrr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','CCRR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\department.dep_inst_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DEP_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\department.dep_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEP_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\department.dep_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\department.dep_dpt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEP_DPT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\department.dep_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEP_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dep_clin_serv.dcs_cse_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DCS_CSE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dep_clin_serv.dcs_dep_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DCS_DEP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\dep_clin_serv.dcs_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DCS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dep_clin_serv_type.depcst_dcst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEPCST_DCST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dep_clin_serv_type.depcst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEPCST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\dep_clin_serv_type.dcst_sft_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DCST_SFT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dependency.dpd_exam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPD_EXAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dependency.dpd_analy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPD_ANALY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dependency.dpd_int_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DPD_INT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dependency.dpd_matr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPD_MATR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dependency.dpd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dependency.dpd_cat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPD_CAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\dependency.dpd_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPD_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dept.dpt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dept.dpt_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPT_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\diagnosis.diag_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAG_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagnosis.diag_diag_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAG_DIAG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagnosis.diag_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\diagnosis.dia_flgs_search_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIA_FLGS_SEARCH_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagnosis_dep_clin_serv.dsc_diag_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DSC_DIAG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagnosis_dep_clin_serv.dsc_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DSC_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagnosis_dep_clin_serv.dsc_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DSC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagnosis_dep_clin_serv.dcs_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DCS_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagnosis_dep_clin_serv.dsc_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DSC_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagnosis_dep_clin_serv.dsc_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DSC_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\diagram.diagr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram.diagr_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGR_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_detail.diagd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\diagram_detail.diagd_diagr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGD_DIAGR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_detail.diagd_diagt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGD_DIAGT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_detail.diagd_diagli_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGD_DIAGLI_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\diagram_detail.diagd_prof_fk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGD_PROF_FK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_detail.diagd_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGD_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_detail_notes.diagdn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGDN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_detail_notes.diagdn_diagd_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGDN_DIAGD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_detail_notes.diagdn_prof_fk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGDN_PROF_FK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_image.diagim_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGIM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_lay_imag.diagli_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGLI_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\diagram_lay_imag.diagli_uk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGLI_UK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_lay_imag.diagli_diagim_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGLI_DIAGIM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_lay_imag.diagli_diagl_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGLI_DIAGL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\diagram_layout.diagl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_tools.diagt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diagram_tools.diagt_diagtg_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGT_DIAGTG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\diagram_tools_group.diagtg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIAGTG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diet.dit_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dietary_drug.ddg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DDG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\diet_schedule.dse_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DSE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dimension.dim_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge.dis_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIS_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge.dis_drd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIS_DRD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\discharge.dis_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIS_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge.dis_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge.dis_prof_admin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIS_PROF_ADMIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\discharge.dis_prof_med_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIS_PROF_MED_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge.dis_trp_adm_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIS_TRP_ADM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge_dest.ddst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DDST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\discharge_detail.dsch_dtl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DSCH_DTL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge_detail.dsch_dtl_trp_typ_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DSCH_DTL_TRP_TYP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge_detail.dsch_dtl_dsch_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DSCH_DTL_DSCH_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge_detail.dsch_dtl_prf_admit_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DSCH_DTL_PRF_ADMIT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge_detail.dsch_dtl_dcs_admit_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DSCH_DTL_DCS_ADMIT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge_detail.dsch_dtl_dttei_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DSCH_DTL_DTTEI_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge_notes.dnt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DNT_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\discharge_notes.dnt_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DNT_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge_notes.dnt_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DNT_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discharge_notes.dnt_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DNT_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\discharge_reason.drn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disc_help.dhp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DHP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disch_prep_mesg.dpm_pme_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPM_PME_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\disch_prep_mesg.dpm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disch_prep_mesg.dpm_dis_fk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPM_DIS_FK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disch_reas_dest.drd_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRD_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disch_reas_dest.drd_drn_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DRD_DRN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disch_reas_dest.drd_ddst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRD_DDST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disch_reas_dest.drd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disch_reas_dest.drd_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRD_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\disch_reas_dest.drd_inst_param_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRD_INST_PARAM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disch_reas_dest.drd_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRD_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disch_reas_dest.drd_ete_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRD_ETE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\disch_reas_dest.drd_dep_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRD_DEP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disch_rea_transp_ent_inst.dttei_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DTTEI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disch_rea_transp_ent_inst.dttei_dsch_rea_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DTTEI_DSCH_REA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\disch_rea_transp_ent_inst.dttei_tei_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DTTEI_TEI_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discriminator.disc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DISC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discriminator_help.dihp_dhp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIHP_DHP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discriminator_help.dihp_disc_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DIHP_DISC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\discriminator_help.dihp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIHP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disc_vs_valid.dvv_disc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DVV_DISC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\disc_vs_valid.dvv_vsn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DVV_VSN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\disc_vs_valid.dvv_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DVV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\district.dst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_action_criteria.docactc_doceql_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCACTC_DOCEQL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\doc_action_criteria.docactc_docec_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCACTC_DOCEC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_action_criteria.docactc_docarea_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCACTC_DOCAREA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_action_criteria.docactc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCACTC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\doc_action_criteria.docactc_docec_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCACTC_DOCEC_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_area.docarea_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCAREA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_component.doccomp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCCOMP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_criteria.doccrit_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DOCCRIT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_destination.ddn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DDN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_destination.doc_destination_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_DESTINATION_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_dimension.docdim_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCDIM_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\doc_element.doce_docdim_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCE_DOCDIM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element.doce_doc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCE_DOC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element.doce_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\doc_element_crit.docec_doccrit_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCEC_DOCCRIT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element_crit.docec_doce_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCEC_DOCE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element_crit.docec_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCEC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\doc_element_qualif.doceql_docec_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCEQL_DOCEC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element_qualif.doceql_docqual_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCEQL_DOCQUAL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element_qualif.doceql_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCEQL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element_quantif.doceqn_doceql_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DOCEQN_DOCEQL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element_quantif.doceqn_docquant_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCEQN_DOCQUANT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element_quantif.doceqn_docec_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCEQN_DOCEC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element_quantif.doceqn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCEQN_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\doc_element_rel.docer_doce_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCER_DOCE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element_rel.docer_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCER_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_element_rel.docer_docer_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCER_DOCER_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\doc_external.del_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEL_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_external.del_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEL_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_external.de_extr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DE_EXTR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\doc_external.del_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEL_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_external.del_ddn_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEL_DDN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_external.del_doe_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEL_DOE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_external.del_dte_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DEL_DTE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_external.del_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DEL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_image.dig_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_image.di_doce_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DI_DOCE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\doc_original.dog_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_ori_type.doe_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_ori_type.doc_ori_type_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_ORI_TYPE_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\doc_qualification.docqual_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCQUAL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_quantification.docquant_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCQUANT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_template.doctemp_doct_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCTEMP_DOCT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\doc_template.doctemp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCTEMP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_template_diagnosis.doctd_doctemp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCTD_DOCTEMP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_template_diagnosis.doctd_diag_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCTD_DIAG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_template_diagnosis.doctd_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DOCTD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_type.dte_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DTE_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_type.dte_doe_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DTE_DOE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_type.dte_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DTE_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\doc_type_soft.ddt_dte_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DDT_DTE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_type_soft.dtt_s_fk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DTT_S_FK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\doc_type_soft.dtt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DTT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\document_area.doca_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\documentation.doc_docarea_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_DOCAREA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\documentation.doc_docdim_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_DOCDIM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\documentation.doc_doc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_DOC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\documentation.doc_doctemp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_DOCTEMP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\documentation.doc_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\documentation.doc_inst_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\documentation.doc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\documentation.doc_doccomp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_DOCCOMP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\documentation_rel.docrel_doc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCREL_DOC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\documentation_rel.docrel_doc_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCREL_DOC_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\documentation_rel.docrel_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCREL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\documentation_type.docty_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCTY_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\document_type.doct_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug.drug_drbra_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRUG_DRBRA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug.drug_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRUG_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug.drug_drpha_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRUG_DRPHA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug.drug_drfrm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRUG_DRFRM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug.drug_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRUG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug.drug_drrte_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DRUG_DRRTE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_bolus.dbu_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DBU_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_brand.drbra_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRBRA_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_brand.drbra_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRBRA_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\drug_dep_clin_serv.dcst_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DCST_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_dep_clin_serv.dcst_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DCST_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_dep_clin_serv.dcst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DCST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_dep_clin_serv.dcst_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DCST_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_dep_clin_serv.dcst_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DCST_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_dep_clin_serv.dcst_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DCST_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_despachos.drdp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRDP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_despachos.drdp_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRDP_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_despachos_soft_inst.ddsi_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DDSI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_despachos_soft_inst.ddsi_inst_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DDSI_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_despachos_soft_inst.ddsi_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DDSI_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_despachos_soft_inst.ddsi_drdp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DDSI_DRDP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_despachos_soft_inst.ddsi_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DDSI_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\drug_drip.ddp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DDP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_form.drfrm_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRFRM_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_form.drfrm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRFRM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_instit_justification.din_drug_justif_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIN_DRUG_JUSTIF_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_instit_justification.din_type_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIN_TYPE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_instit_justification.din_instit_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIN_INSTIT_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_instit_justification.din_softw_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIN_SOFTW_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_instit_justification.din_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DIN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_justification.djn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DJN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_pharma.drpha_drphc_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DRPHA_DRPHC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_pharma.drpha_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPHA_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_pharma.drpha_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPHA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_pharma_class.drphc_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPHC_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\drug_pharma_class.drphc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPHC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_pharma_class_link.dpcl_drphc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPCL_DRPHC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_pharma_class_link.dpcl_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPCL_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_pharma_class_link.dpcl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPCL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_pharma_interaction.dpin_drpha_interact_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPIN_DRPHA_INTERACT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_pharma_interaction.dpin_drpha_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPIN_DRPHA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_pharma_interaction.drpha_drph_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPHA_DRPH_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_plan.drpla_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPLA_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_plan.drpla_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPLA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_presc_det.dpdt_drug_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DPDT_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_presc_det.dpdt_dpn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPDT_DPN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_presc_det.dpdt_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPDT_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_presc_det.dpdt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPDT_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\drug_presc_det.dpdt_djn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPDT_DJN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_presc_det.dpdt_drdp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPDT_DRDP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_presc_plan.drprp_prof_writes_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPRP_PROF_WRITES_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_presc_plan.drprp_drtkt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPRP_DRTKT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_presc_plan.drprp_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPRP_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_presc_plan.drprp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPRP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_presc_plan.dpp_flg_status_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPP_FLG_STATUS_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_presc_plan.drprp_drgpr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPRP_DRGPR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_presc_plan.drprp_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRPRP_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_prescription.dpn_prof_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DPN_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_prescription.dpn_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPN_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_prescription.dpn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_prescription.dpn_epis_dest_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPN_EPIS_DEST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\drug_prescription.dpn_epis_origin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPN_EPIS_ORIGIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_prescription.dpn_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPN_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_prescription.dpn_prt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPN_PRT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_prescription.dpn_epis_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPN_EPIS_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_protocols.dps_prt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPS_PRT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_protocols.dps_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPS_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_protocols.dps_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DPS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req.drq_dpn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRQ_DPN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req.drq_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRQ_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req.drq_prof_req_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DRQ_PROF_REQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req.drq_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req.drq_epis_status_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRQ_EPIS_STATUS_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req.drq_prof_print_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRQ_PROF_PRINT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\drug_req.drq_room_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRQ_ROOM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req.drq_prof_pending_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRQ_PROF_PENDING_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_det.drdt_drq_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRDT_DRQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_req_det.drdt_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRDT_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_det.drdt_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRDT_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_det.drdt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRDT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_req_det.drdt_drdp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRDT_DRDP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_det.drdt_dcs_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRDT_DCS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_det.drdt_prof_pending_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRDT_PROF_PENDING_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_supply.drs_drdt_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DRS_DRDT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_supply.drs_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_supply.drs_prof_bgsupl_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRS_PROF_BGSUPL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_supply.drs_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRS_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\drug_req_supply.drs_prof_endsupl_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRS_PROF_ENDSUPL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_supply.drs_prof_mov_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRS_PROF_MOV_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_supply.drs_prof_receive_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRS_PROF_RECEIVE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_req_supply.drs_prof_give_aux_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRS_PROF_GIVE_AUX_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_supply.drs_prof_utente_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRS_PROF_UTENTE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_req_supply.drs_prof_end_aux_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRS_PROF_END_AUX_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\drug_route.drrte_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRRTE_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_route.drrte_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRRTE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_take_plan.drtkp_drtkt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRTKP_DRTKT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_take_plan.drtkp_drpla_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','DRTKP_DRPLA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_take_plan.drtkp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRTKP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\drug_take_time.drtkt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DRTKT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\emb_dep_clin_serv.edv_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDV_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\emb_dep_clin_serv.edv_ddg_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDV_DDG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\emb_dep_clin_serv.edv_mad_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDV_MAD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\emb_dep_clin_serv.edv_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDV_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\emb_dep_clin_serv.edv_ieb_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDV_IEB_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\emb_dep_clin_serv.edv_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDV_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\emb_dep_clin_serv.edv_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDV_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_anamnesis.comp_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','COMP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_anamnesis.comp_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','COMP_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_anamnesis.comp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','COMP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_anamnesis.epis_anam_temp_prof_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_ANAM_TEMP_PROF_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_anamnesis.comp_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','COMP_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_anamnesis.comp_diag_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','COMP_DIAG_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_anamnesis.comp_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','COMP_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_anamnesis.comp_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','COMP_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_attending_notes.ean_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EAN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_attending_notes.ean_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EAN_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_attending_notes.ean_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EAN_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_attending_notes.ean_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EAN_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_bartchart.ebar_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EBAR_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_bartchart.ebar_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EBAR_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_bartchart.ebar_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EBAR_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_bartchart.ebar_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EBAR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_bartchart.ebar_ecomp_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EBAR_ECOMP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_bartchart_det.ebard_syec_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EBARD_SYEC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_bartchart_det.ebard_syse_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EBARD_SYSE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_bartchart_det.ebard_ebar_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EBARD_EBAR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_bartchart_det.ebard_sysd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EBARD_SYSD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_bartchart_det.ebard_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EBARD_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_bartchart_det.ebard_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EBARD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_body_painting.bpg_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BPG_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_body_painting.bpg_bpi_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BPG_BPI_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_body_painting.bpg_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BPG_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_body_painting.bpg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BPG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_body_painting_det.bpd_bpg_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BPD_BPG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_body_painting_det.bpd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BPD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_complaint.ecomp_prof_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ECOMP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_complaint.ecomp_cmplt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECOMP_CMPLT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_complaint.ecomp_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECOMP_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_complaint.ecomp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECOMP_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_diagnosis.eds_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDS_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diagnosis.eds_diag_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDS_DIAG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diagnosis.eds_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDS_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_diagnosis.eds_prof_diag_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDS_PROF_DIAG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diagnosis.eds_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diagnosis.eds_edn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDS_EDN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_diagnosis_hist.edh_eds_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDH_EDS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diagnosis_hist.edh_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDH_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diagnosis_hist.edh_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDH_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diagnosis_hist.edh_edn_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EDH_EDN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diagnosis_notes.edn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diet.edt_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDT_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diet.edt_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDT_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_diet.edt_dit_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDT_DIT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diet.edt_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDT_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diet.edt_prof_fk3_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDT_PROF_FK3_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_diet.edt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_diet.edt_dse_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDT_DSE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_documentation.episd_prof_fk3_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISD_PROF_FK3_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_documentation.episd_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISD_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_documentation.episd_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISD_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_documentation.episd_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISD_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_documentation.episd_ecomp_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EPISD_ECOMP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_documentation.episd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_documentation.episd_doc_area_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISD_DOC_AREA_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_documentation_det.episdd_doc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISDD_DOC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_documentation_det.episdd_doce_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISDD_DOCE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_documentation_det.episdd_docec_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISDD_DOCEC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_documentation_det.episdd_episd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISDD_EPISD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_documentation_det.episdd_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISDD_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_documentation_det.episdd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPISDD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_drug_usage.due_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DUE_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_drug_usage.due_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DUE_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_drug_usage.due_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DUE_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_drug_usage.due_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DUE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_ext_sys.ees_epis_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EES_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_ext_sys.ees_ess_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EES_ESS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_ext_sys.ees_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_ext_sys.ees_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EES_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_health_plan.ehp_php_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHP_PHP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_health_plan.ehp_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHP_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_health_plan.ehp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_hidrics.ehid_hidin_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHID_HIDIN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics.ehid_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHID_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics.ehid_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHID_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_hidrics.ehid_hidt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHID_HIDT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics.ehid_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHID_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics.ehid_prof_fk3_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHID_PROF_FK3_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics.ehid_prof_fk2_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EHID_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics_balance.ehbe_ehid_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHBE_EHID_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics_balance.ehbe_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHBE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics_balance.ehbe_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHBE_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics_det.ehidd_hid_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHIDD_HID_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics_det.ehidd_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHIDD_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics_det.ehidd_ehid_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHIDD_EHID_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_hidrics_det.ehidd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHIDD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics_det.ehidd_ehbe_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHIDD_EHBE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_hidrics_det.ehidd_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EHIDD_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_info.eio_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIO_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_info.eio_bed_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIO_BED_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_info.eio_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIO_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_info.eio_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EIO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_info.eio_schd_episode_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIO_SCHD_EPISODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_info.eio_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIO_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_info.eio_schd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIO_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_info.eio_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIO_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_info.eio_nurse_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIO_NURSE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_info.eio_dcs_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIO_DCS_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_institution.ein_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_institution.ein_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIN_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_institution.ein_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIN_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_interv.eiv_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_interv.eiv_int_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIV_INT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_interv.eiv_ipn_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIV_IPN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_interv.eiv_room_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EIV_ROOM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_interval_notes.einotes_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EINOTES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_interval_notes.einotes_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EINOTES_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_interval_notes.einotes_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EINOTES_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_man.emn_org_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMN_ORG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_man.emn_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMN_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_man.emn_wrn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMN_WRN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_man.emn_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMN_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_man.emn_col_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMN_COL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_man.emn_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMN_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_man.emn_man_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMN_MAN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_man.emn_nss_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMN_NSS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_man.emn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_observation.obv_epis_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','OBV_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_observation.obv_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OBV_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_observation.obv_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OBV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_observation.obv_epis_temp_prof_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OBV_EPIS_TEMP_PROF_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_observation.obv_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OBV_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_observation.obv_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OBV_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_obs_exam.eoe_pem_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EOE_PEM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_obs_exam.eoe_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EOE_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_obs_exam.eoe_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EOE_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_obs_exam.eoe_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EOE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_obs_photo.eop_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EOP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_obs_photo.eop_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EOP_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_obs_photo.eop_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EOP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\episode.epis_vis_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_VIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\episode.epis_cse_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_CSE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\episode.epis_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\episode.epis_ete_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_ETE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\episode.epis_dt_begin_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_DT_BEGIN_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\episode.epis_dt_end_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_DT_END_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\episode.epis_status_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_STATUS_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\episode.epis_episode_info_ui.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_EPISODE_INFO_UI','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\episode.epis_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_photo.epo_eop_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPO_EOP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_photo.epo_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_positioning.epg_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPG_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_positioning.epg_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPG_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_positioning.epg_prof_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EPG_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_positioning.epg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_positioning.epg_prof_fk3_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPG_PROF_FK3_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_positioning_det.epgd_pog_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPGD_POG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_positioning_det.epgd_epg_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPGD_EPG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_positioning_det.epgd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPGD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_positioning_plan.epgp_epgd_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPGP_EPGD_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_positioning_plan.epgp_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPGP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_positioning_plan.epgp_epgd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPGP_EPGD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_positioning_plan.epgp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPGP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_problem.epp_ppm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPP_PPM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_problem.epp_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_problem.epp_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPP_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_problem.epp_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EPP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_rec.eprc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPRC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_prof_fk4_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_PROF_FK4_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_prof_fk3_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_PROF_FK3_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_dep_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_DEP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_spc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_SPC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_prof_fk6_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_PROF_FK6_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_bed_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_BED_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_prof_fk7_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_PROF_FK7_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_prof_fk5_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_PROF_FK5_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_dep_fk2_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_DEP_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_prof_resp.epr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_protocols.epis_prot_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_PROT_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_protocols.epis_prot_prof_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_PROT_PROF_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_protocols.epis_prot_prt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_PROT_PRT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_protocols.epis_prot_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPIS_PROT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_readmission.ern_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERN_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_readmission.ern_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_recomend.ernd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERND_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_recomend.ernd_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERND_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_recomend.ernd_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERND_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_report.erept_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREPT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_report_section.erns_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ERNS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_review_systems.ersy_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERSY_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_review_systems.ersy_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERSY_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_review_systems.ersy_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERSY_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_review_systems.ersy_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERSY_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_task.etk_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETK_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_task.etk_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETK_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_triage.etrg_org_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETRG_ORG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_triage.etrg_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETRG_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_triage.etrg_twrn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETRG_TWRN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_triage.etrg_tcol_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETRG_TCOL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_triage.etrg_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETRG_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_triage.etrg_tri_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETRG_TRI_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_triage.etrg_prof_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ETRG_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_triage.etrg_nss_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETRG_NSS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_triage.etrg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETRG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_triage.etrg_tnsr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETRG_TNSR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\epis_triage.etrg_comp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETRG_COMP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_type.ete_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_type.ete_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETE_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_type_room.etr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_type_room.etr_ete_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETR_ETE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\epis_type_room.etr_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETR_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\epis_type_room.etr_room_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETR_ROOM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\equip_protocols.epl_ssd_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPL_SSD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\equip_protocols.epl_prt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPL_PRT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\equip_protocols.epl_sep_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EPL_SEP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\estate.est_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EST_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\estate.est_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EST_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\estate.est_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EST_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\event_group.eg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\event_group_soft_inst.egsi_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EGSI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam.exam_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EXAM_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam.exam_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EXAM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam.exam_type_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EXAM_TYPE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam.ex_flg_type_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EX_FLG_TYPE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam.exam_ect_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EXAM_ECT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_cat.ect_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_cat_dcs.ecc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_cat_dcs.ecc_dcs_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ECC_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_cat_dcs.ecc_ect_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECC_ECT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_cat_dcs_ext_sys.eces_ess_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECES_ESS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_cat_dcs_ext_sys.eces_ecc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECES_ECC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\exam_cat_dcs_ext_sys.eces_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_dep_clin_serv.ecst_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECST_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_dep_clin_serv.ecst_exam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECST_EXAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam_dep_clin_serv.ecst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_dep_clin_serv.ecst_egp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECST_EGP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_dep_clin_serv.ecst_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECST_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam_dep_clin_serv.ecst_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECST_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_dep_clin_serv.ecst_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ECST_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_drug.edg_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDG_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_drug.edg_exam_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EDG_EXAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_drug.edg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_drug.edg_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EDG_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_egp.exmg_egp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EXMG_EGP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\exam_egp.exmg_exam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EXMG_EXAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_egp.exmg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EXMG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_ext_sys_delete.emes_ess_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMES_ESS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam_ext_sys_delete.emes_exam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMES_EXAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_ext_sys_delete.emes_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EMES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_group.egp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EGP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam_prep_mesg.epmg_pme_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPMG_PME_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_prep_mesg.epmg_exam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPMG_EXAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_prep_mesg.epmg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPMG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_prep_mesg.epmg_inst_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EPMG_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_protocols.eps_exam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPS_EXAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_protocols.eps_prt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPS_PRT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_protocols.eps_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EPS_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_schd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam_req.ereq_prof_req_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_PROF_REQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_schd_consult_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_SCHD_CONSULT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam_req.ereq_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_prof_app_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_PROF_APP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_prof_authz_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_PROF_AUTHZ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_flg_time_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_FLG_TIME_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_epis_status_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_EPIS_STATUS_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_epis_dest_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_EPIS_DEST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_epis_origin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_EPIS_ORIGIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_prof_resched_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_PROF_RESCHED_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_prt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_PRT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req.ereq_epis_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EREQ_EPIS_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam_req_det.erd_mov_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERD_MOV_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req_det.erd_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERD_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req_det.erd_ereq_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERD_EREQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam_req_det.erd_exam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERD_EXAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req_det.erd_erd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERD_ERD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req_det.erd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req_det.exam_req_det_status_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EXAM_REQ_DET_STATUS_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_req_det.erd_room_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERD_ROOM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_result.eres_exam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERES_EXAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_result.eres_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERES_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\exam_result.eres_erd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERES_ERD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_result.eres_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERES_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_result.eres_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERES_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam_result.eres_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_result.exam_result_i_id_episode.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EXAM_RESULT_I_ID_EPISODE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_result.exam_result_alert_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EXAM_RESULT_ALERT_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\exam_result.er_exam_req_det_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ER_EXAM_REQ_DET_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_result.eres_prof_mov_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERES_PROF_MOV_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_result.eres_prof_receive_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERES_PROF_RECEIVE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_result.eres_epis_write_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ERES_EPIS_WRITE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_room.erm_exam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERM_EXAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_room.erm_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERM_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\exam_room.erm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERM_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\external_cause.extc_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EXTC_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\external_cause.extc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EXTC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\external_sys.ess_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ESS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\family_monetary.fmy_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FMY_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\family_monetary.fmy_ptfam_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FMY_PTFAM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\family_relationship.frp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FRP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\family_relationship_relat.frn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FRN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\family_relationship_relat.frn_frp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FRN_FRP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\family_relationship_relat.frn_frp_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FRN_FRP_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\floors.flo_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','FLO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\floors_department.flsdep_dep_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FLSDEP_DEP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\floors_department.flsdep_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FLSDEP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\floors_department.flsdep_finst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FLSDEP_FINST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\floors_dep_position.flsdepp_flsdep_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FLSDEPP_FLSDEP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\floors_dep_position.flsdepp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FLSDEPP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\floors_institution.finst_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FINST_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\floors_institution.finst_flo_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FINST_FLO_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\floors_institution.finst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FINST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\floors_institution.finst_building_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FINST_BUILDING_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\geo_location.gln_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','GLN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\geo_location.gln_ctr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','GLN_CTR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\ginec_obstet.oce_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OCE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\graffar_criteria.gca_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','GCA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\graffar_crit_value.gcv_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','GCV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\graffar_crit_value.gcv_gca_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','GCV_GCA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\grid_task.gtk_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','GTK_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\grid_task.gtk_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','GTK_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\grid_task_between.gtn_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','GTN_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\grid_task_between.gtn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','GTN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\habit.hat_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HAT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\harvest.harv_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\harvest.harv_prof_receive_tube_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_PROF_RECEIVE_TUBE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\harvest.harv_bpt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_BPT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\harvest.harv_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\harvest.harv_room_harvest_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_ROOM_HARVEST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\harvest.harv_room_receive_tube_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_ROOM_RECEIVE_TUBE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\harvest.harv_prof_mov_tube_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_PROF_MOV_TUBE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\harvest.harv_prof_harvest_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_PROF_HARVEST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\harvest.harv_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\harvest.harv_flg_status_dt_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_FLG_STATUS_DT_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\harvest.harv_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\harvest.harv_epis_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HARV_EPIS_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\hcn_def_crit.hcn_def_crit_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HCN_DEF_CRIT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\health_plan.hpn_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HPN_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\health_plan.hpn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HPN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\health_plan_instit.hpi_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HPI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\health_plan_instit.hpi_hpn_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HPI_HPN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\health_plan_instit.hpi_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HPI_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_protocols.hemo_prot_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_PROT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_protocols.hemo_prot_hemo_type_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_PROT_HEMO_TYPE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_protocols.hemo_prot_prt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_PROT_PRT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req.hemo_req_prof_req_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_REQ_PROF_REQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\hemo_req.hemo_req_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_REQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req.hemo_req_id_schedule_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_REQ_ID_SCHEDULE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req.hemo_req_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_REQ_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\hemo_req.hemo_req_prof_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_REQ_PROF_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req_det.hemo_rd_hemo_req_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RD_HEMO_REQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req_det.hemo_rd_hemo_type_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RD_HEMO_TYPE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\hemo_req_det.hemo_rd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req_det.hemo_rd_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RD_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req_supply.hemo_rs_hemo_rd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RS_HEMO_RD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req_supply.hemo_rs_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req_supply.hemo_rs_drbra_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RS_DRBRA_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req_supply.hemo_rs_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RS_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req_supply.hemo_rs_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RS_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\hemo_req_supply.hemo_rs_prof_mov_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RS_PROF_MOV_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req_supply.hemo_rs_prof_receive_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RS_PROF_RECEIVE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hemo_req_supply.hemo_rs_prof_supply_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_RS_PROF_SUPPLY_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\hemo_type.hemo_type_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HEMO_TYPE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hidrics.hid_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HID_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hidrics.hid_unitm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HID_UNITM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\hidrics_interval.hidin_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HIDIN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hidrics_relation.hrn_hidt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HRN_HIDT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hidrics_relation.hrn_hid_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HRN_HID_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hidrics_relation.hrn_s_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','HRN_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hidrics_relation.hrn_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HRN_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\hidrics_type.hidt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HIDT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\home.home_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HOME_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\home.home_ptfam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HOME_PTFAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\home.home_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HOME_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_axis.ias_icln_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IAS_ICLN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\icnp_axis.ias_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IAS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_classification.icln_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICLN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_compo_clin_serv.icv_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\icnp_compo_clin_serv.icv_uk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICV_UK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_compo_dcs.icc_pk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICC_PK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_compo_dcs.icc_uk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICC_UK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_compo_dcs.icc_dcs_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ICC_DCS_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_compo_folder.icf_nu_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICF_NU_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_compo_folder.icr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_compo_folder.icr_icn_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICR_ICN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\icnp_compo_folder.icr_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICR_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_compo_inst.ici_u_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICI_U_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_compo_inst.ici_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\icnp_compo_inst.ici_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICI_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_composition.icn_nu_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICN_NU_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_composition.icn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\icnp_composition_term.ict_itm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICT_ITM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_composition_term.ict_icn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICT_ICN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_composition_term.ict_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_dictionary.idy_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','IDY_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_diag_interv.iedi_eipd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IEDI_EIPD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_diag_interv.iedi_eipi_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IEDI_EIPI_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_diag_interv.iedi_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IEDI_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_diagnosis.eipd_nu_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPD_NU_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_diagnosis.eipd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_diagnosis.eipd_eipd_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPD_EIPD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\icnp_epis_diagnosis.eipd_icn_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPD_ICN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_diagnosis.eipd_pat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPD_PAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_diagnosis.eipd_prof_canc_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPD_PROF_CANC_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\icnp_epis_diagnosis.eipd_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPD_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_intervention.eipi_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPI_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_intervention.eipi_icn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPI_ICN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_intervention.eipi_epis_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','EIPI_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_intervention.eipi_prof_canc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPI_PROF_CANC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_intervention.eipi_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_intervention.eipi_eipi_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPI_EIPI_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\icnp_epis_intervention.eipi_pat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','EIPI_PAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_folder.if_nu_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IF_NU_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_folder.ifr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IFR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\icnp_folder.ifr_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IFR_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_morph.ilc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ILC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_morph.ilc_idy_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ILC_IDY_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\icnp_morph.ilc_idy_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ILC_IDY_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_morph.ilc_idy_fk3_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ILC_IDY_FK3_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_morph.ilc_idy_fk4_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ILC_IDY_FK4_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_morph.ilc_idy_fk5_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ILC_IDY_FK5_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_predefined_action.ipa_nu_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPA_NU_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_predefined_action.ida_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_predefined_action.ida_icn_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDA_ICN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\icnp_predefined_action.ida_icn_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDA_ICN_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_relationship.irp_itm_rel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IRP_ITM_REL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_relationship.irp_itm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IRP_ITM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\icnp_relationship.irp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IRP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_term.itm_ias_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ITM_IAS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_term.itm_itm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ITM_ITM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\icnp_term.itm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ITM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\icnp_transition_state.ite_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ITE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\identification_notes.inotes_docarea_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INOTES_DOCAREA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\identification_notes.inotes_pat_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','INOTES_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\identification_notes.inotes_doca_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INOTES_DOCA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\identification_notes.inotes_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INOTES_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\identification_notes.inotes_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INOTES_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\identification_notes.inotes_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INOTES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\implementation.impl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IMPL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\ine_location.iln_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ILN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\inf_atc.iac_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IAC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_atc_lnk.ial_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IAL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_atc_lnk.ial_imd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IAL_IMD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\inf_atc_lnk.ial_iac_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IAL_IAC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_cft.icf_idcode_ui.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICF_IDCODE_UI','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_cft.icf_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICF_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_cft.icf_parent_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ICF_PARENT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_cft.icf_cftid_ui.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICF_CFTID_UI','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_cft.icf_level2_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICF_LEVEL2_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_cft.icf_level4_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICF_LEVEL4_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\inf_cft.icf_level5_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICF_LEVEL5_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_cft.icf_level1_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICF_LEVEL1_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_cft.icf_level3_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICF_LEVEL3_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\inf_cft_lnk.icl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_cft_lnk.icl_icf_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICL_ICF_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_cft_lnk.icl_imd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICL_IMD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\inf_class_disp.icd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_class_estup.ice_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_comerc.icc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_comerc.icc_ieb_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ICC_IEB_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_comerc.icc_ido_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICC_IDO_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_dcipt.idt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_diabetes_lnk.idk_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDK_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\inf_diabetes_lnk.idk_imd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDK_IMD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_diabetes_lnk.idk_itl_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDK_ITL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_diploma.idm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\inf_dispo.ido_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_emb.ieb_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IEB_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_emb.ieb_imd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IEB_IMD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\inf_emb.ieb_igm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IEB_IGM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_emb.ieb_iet_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IEB_IET_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_emb.ieb_ito_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IEB_ITO_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_emb_comerc.iec_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','IEC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_emb_unit.iet_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IET_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_estado_aim.iem_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IEM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_form_farm.iff_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IFF_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\inf_grupo_hom.igm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IGM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_med.imd_itd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IMD_ITD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_med.imd_iff_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IMD_IFF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\inf_med.imd_idt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IMD_IDT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_med.imd_icd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IMD_ICD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_med.imd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IMD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\inf_med.imd_iem_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IMD_IEM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_med.imd_ita_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IMD_ITA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_med.imd_ice_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IMD_ICE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_patol_dip_lnk.ipdl_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','IPDL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_patol_dip_lnk.ipdl_ida_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPDL_IDA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_patol_dip_lnk.ipdl_ipp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPDL_IPP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_patol_esp.ipe_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPE_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\inf_patol_esp_lnk.ipel_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPEL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_patol_esp_lnk.ipel_ipdl_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPEL_IPDL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_patol_esp_lnk.ipel_ieb_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPEL_IEB_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\inf_preco.ipo_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_preco.ipo_iebdata_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPO_IEBDATA_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_preco.ipo_ieb_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPO_IEB_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\inf_preco.ipo_ito_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPO_ITO_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_subst.ist_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_subst_lnk.isk_imd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ISK_IMD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_subst_lnk.isk_ist_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ISK_IST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_tipo_diab_mel.itl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ITL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_tipo_preco.itp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ITP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_tipo_prod.itd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ITD_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\inf_titular_aim.ita_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ITA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_tratamento.ito_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ITO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_vias_admin.iva_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IVA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\inf_vias_admin_lnk.ivk_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IVK_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_vias_admin_lnk.ivk_imd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IVK_IMD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inf_vias_admin_lnk.ivk_iva_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IVK_IVA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\ingredient.ing_type_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ING_TYPE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\ingredient.ing_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ING_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inp_error.err_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\inp_log.log_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','LOG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\instit_ext_sys.iess_ess_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IESS_ESS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\instit_ext_sys.iess_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IESS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\instit_ext_sys.iess_dcs_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IESS_DCS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\instit_ext_sys.iess_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IESS_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\institution.inst_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INST_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\institution.inst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\interv_dep_clin_serv.ics_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICS_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_dep_clin_serv.ics_int_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICS_INT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_dep_clin_serv.ics_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\interv_dep_clin_serv.ics_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICS_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_dep_clin_serv.ics_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICS_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_dep_clin_serv.ics_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ICS_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_drug.idg_drug_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','IDG_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_drug.idg_int_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDG_INT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_drug.idg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_drug.idg_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IDG_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\intervention.int_int_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INT_INT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\intervention.int_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INT_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\intervention.int_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\intervention.int_bpt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INT_BPT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\intervention.int_ipa_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INT_IPA_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\intervention.int_ssar_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','INT_SSAR_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\interv_ext_sys_delete.ies_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_ext_sys_delete.ies_ess_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IES_ESS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_ext_sys_delete.ies_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IES_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_ext_sys_delete.ies_int_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','IES_INT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_physiatry_area.ipa_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_prep_msg.ipm_pme_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPM_PME_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_prep_msg.ipm_int_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPM_INT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\interv_prep_msg.ipm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_prep_msg.ipm_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPM_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_presc_det.ipd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\interv_presc_det.ipd_interv_id_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPD_INTERV_ID_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_presc_det.ipp_status_interv_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPP_STATUS_INTERV_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_presc_det.ipd_int_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPD_INT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\interv_presc_det.ipd_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPD_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_presc_det.ipn_dpdt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPN_DPDT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_presc_det.ipn_mov_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPN_MOV_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_presc_det.nard_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','NARD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_presc_plan.ipp_ipn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPP_IPN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_presc_plan.ipp_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_presc_plan.ipp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPP_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\interv_presc_plan.ipp_status_dt_plan_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPP_STATUS_DT_PLAN_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_presc_plan.ipp_prof_take_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPP_PROF_TAKE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_presc_plan.ipp_wtt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPP_WTT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\interv_presc_plan.ipp_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPP_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_prescription.presc_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRESC_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_prescription.presc_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRESC_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\interv_prescription.presc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRESC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_prescription.ip_flg_time_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IP_FLG_TIME_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_prescription.presc_epis_dest_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRESC_EPIS_DEST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_prescription.presc_epis_origin_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PRESC_EPIS_ORIGIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_prescription.presc_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRESC_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_prescription.presc_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRESC_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_prescription.presc_prt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRESC_PRT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\interv_prescription.presc_epis_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRESC_EPIS_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_protocols.ips_int_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPS_INT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_protocols.ips_prt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPS_PRT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\interv_protocols.ips_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IPS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_room.irm_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IRM_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\interv_room.irm_int_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IRM_INT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\interv_room.irm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','IRM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\isencao.i_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','I_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\java$class$md5$table.sys_c007208.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_C007208','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\language.lang_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','LANG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\manchester.man_disc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MAN_DISC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\manchester.man_col_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MAN_COL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\manchester.man_brd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MAN_BRD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\manchester.man_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MAN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\manipulated.mad_type_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MAD_TYPE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\manipulated.mdg_mgp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MDG_MGP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\manipulated.mdg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MDG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\manipulated_group.mgp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MGP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\manipulated_ingredient.mit_mad_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MIT_MAD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\manipulated_ingredient.mit_ing_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MIT_ING_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\manipulated_ingredient.mit_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MIT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\match_epis.mtch_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MTCH_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\material.matr_mte_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','MATR_MTE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\material.matr_matr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MATR_MATR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\material.matr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MATR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\material_protocols.mat_prot_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MAT_PROT_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\material_req.mreq_schd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MREQ_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\material_req.mreq_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MREQ_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\material_req.mreq_prof_request_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MREQ_PROF_REQUEST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\material_req.mreq_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MREQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\material_req_det.mrd_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRD_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\material_req_det.mrd_mreq_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRD_MREQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\material_req_det.mrd_matr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRD_MATR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\material_req_det.mrd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\material_type.mte_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MTE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\matr_dep_clin_serv.mcst_dcs_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','MCST_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\matr_dep_clin_serv.mcst_matr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MCST_MATR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\matr_dep_clin_serv.mcst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MCST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\matr_dep_clin_serv.mcst_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MCST_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\matr_dep_clin_serv.mcst_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MCST_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\matr_room.mrm_matr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRM_MATR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\matr_room.mrm_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRM_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\matr_room.mrm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\matr_scheduled.msd_schd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MSD_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\matr_scheduled.msd_matr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MSD_MATR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\matr_scheduled.msd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MSD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\mcdt_req_diagnosis.mrd_diag_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRD_DIAG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\mcdt_req_diagnosis.mrd_art_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRD_ART_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\mcdt_req_diagnosis.mrd_ereq_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','MRD_EREQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\mcdt_req_diagnosis.mrd_presc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRD_PRESC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\mcdt_req_diagnosis.mrd_eds_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRD_EDS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\mcdt_req_diagnosis.mrd_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MRD_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\mdm_prof_coding.mpc_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MPC_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\mdm_prof_coding.mpc_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MPC_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\mdm_prof_coding.mpc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MPC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\monitorization.mont_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MONT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\monitorization.mont_epis_dest_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MONT_EPIS_DEST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\monitorization.mont_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MONT_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\monitorization.mont_epis_origin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MONT_EPIS_ORIGIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\monitorization.mont_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MONT_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\monitorization.mont_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MONT_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\monitorization_vs.mvs_mont_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','MVS_MONT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\monitorization_vs.mvs_vsn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MVS_VSN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\monitorization_vs.mvs_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MVS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\monitorization_vs.mvs_status_dt_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MVS_STATUS_DT_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\monitorization_vs.mvs_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MVS_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\monitorization_vs_plan.mvsp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MVSP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\monitorization_vs_plan.mvsp_mvs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MVSP_MVS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\movement.mov_prof_receive_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MOV_PROF_RECEIVE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\movement.mov_prof_request_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MOV_PROF_REQUEST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\movement.mov_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MOV_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\movement.mov_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MOV_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\movement.mov_prof_move_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MOV_PROF_MOVE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\movement.mov_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MOV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\movement.mov_status_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','MOV_STATUS_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\movement.mov_room_from_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MOV_ROOM_FROM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\movement.mov_room_to_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MOV_ROOM_TO_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\movement.mov_epis_write_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','MOV_EPIS_WRITE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\necessity.nss_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NSS_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\necessity.nss_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NSS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_activity_req.nar_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NAR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\nurse_activity_req.nar_epis_dest_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NAR_EPIS_DEST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_activity_req.nar_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NAR_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_activity_req.nar_epis_origin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NAR_EPIS_ORIGIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\nurse_activity_req.nar_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NAR_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_activity_req.nar_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NAR_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_activity_req.nar_schd_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NAR_SCHD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_actv_req_det.nard_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','NARD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_actv_req_det.nard_nar_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NARD_NAR_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_actv_req_det.nard_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NARD_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_actv_req_det.nard_wte_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NARD_WTE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\nurse_discharge.nde_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NDE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_discharge.nde_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NDE_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_discharge.nde_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NDE_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\nurse_discharge.nde_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NDE_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_tea_req.ntr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NTR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_tea_req.ntr_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NTR_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\nurse_tea_req.ntr_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NTR_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_tea_req.ntr_prof_exec_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NTR_PROF_EXEC_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\nurse_tea_req.ntr_prof_req_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','NTR_PROF_REQ_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\occupation.occ_code_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','OCC_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\occupation.occ_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OCC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\opinion.opn_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OPN_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\opinion.opn_prof_questions_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OPN_PROF_QUESTIONS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\opinion.opn_prof_questioned_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OPN_PROF_QUESTIONED_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\opinion.opn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OPN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\opinion.opn_spc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OPN_SPC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\opinion.opn_flg_state_p_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OPN_FLG_STATE_P_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\opinion.opn_flg_state_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OPN_FLG_STATE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\opinion_prof.opf_opn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OPF_OPN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\opinion_prof.opf_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OPF_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\opinion_prof.opf_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OPF_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\opinion_prof.opf_prof_opn_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OPF_PROF_OPN_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\origin.org_code_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ORG_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\origin.org_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ORG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\origin_soft.ost_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\origin_soft.ost_org_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OST_ORG_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\origin_soft.ost_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','OST_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\outlook.pk_outlook.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PK_OUTLOOK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\param_analysis_ext_sys_delete.paes_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\param_analysis_ext_sys_delete.paes_ess_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAES_ESS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\param_analysis_ext_sys_delete.paes_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAES_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\param_analysis_ext_sys_delete.paes_pany_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAES_PANY_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\parameter_analysis.pany_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PANY_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\parameter_analysis.pany_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PANY_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_allergy.pal_prof_write_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAL_PROF_WRITE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_allergy.pal_pat_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PAL_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_allergy.pal_alg_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAL_ALG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_allergy.pal_drpha_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAL_DRPHA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_allergy.pal_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAL_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_allergy.pal_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAL_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_allergy.pal_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAL_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_allergy_hist.pah_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAH_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_allergy_hist.pah_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAH_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_allergy_hist.pah_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAH_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_allergy_hist.pah_pal_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAH_PAL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_blood_group.pbg_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PBG_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_blood_group.pbg_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PBG_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_blood_group.pbg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PBG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_blood_group.pbg_epis_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PBG_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_blood_group.pbg_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PBG_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_child_clin_rec.pccr_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCCR_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_child_clin_rec.pccr_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCCR_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_child_clin_rec.pccr_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCCR_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_child_clin_rec.pccr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCCR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_child_feed_dev.pcf_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCF_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_child_feed_dev.pcf_fdp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCF_FDP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_child_feed_dev.pcf_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCF_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_child_feed_dev.pcf_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCF_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_cli_attributes.ptcat_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTCAT_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_cli_attributes.ptcat_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTCAT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_cli_attributes.ptcat_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTCAT_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_cli_attributes.ptcat_recm_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PTCAT_RECM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_cntrceptiv.pce_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCE_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_cntrceptiv.pce_cpe_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCE_CPE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_cntrceptiv.pce_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCE_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_cntrceptiv.pce_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_delivery.pdy_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDY_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_delivery.pdy_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDY_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_delivery.pdy_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDY_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_delivery.pdy_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDY_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_delivery.pdy_ppy_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDY_PPY_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_dmgr_hist.pdt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_dmgr_hist.pdt_professional_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDT_PROFESSIONAL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_dmgr_hist.pdt_institution_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDT_INSTITUTION_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_dmgr_hist.pdt_country_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PDT_COUNTRY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_dmgr_hist.pdt_scholarship_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDT_SCHOLARSHIP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_dmgr_hist.pdt_recm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDT_RECM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_dmgr_hist.pdt_occupations_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDT_OCCUPATIONS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_dmgr_hist.pdt_isencao_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDT_ISENCAO_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_doc.pdoc_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDOC_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_doc.pdoc_dte_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDOC_DTE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_doc.pdoc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDOC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_doc.pdoc_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDOC_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_ext_sys.pes_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PES_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_ext_sys.pes_ess_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PES_ESS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_ext_sys.pes_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_ext_sys.pes_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PES_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family.ptfam_name_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PTFAM_NAME_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family.ptfam_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFAM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family.ptfam_inst_enroled_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFAM_INST_ENROLED_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family.ptfam_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFAM_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_family.ptfam_scs_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFAM_SCS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_disease.ptfdi_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFDI_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_disease.ptfdi_ptfmm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFDI_PTFMM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_family_disease.ptfdi_diag_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFDI_DIAG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_disease.ptfdi_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFDI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_disease.ptfdi_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFDI_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_family_member.ptfmm_ptfam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFMM_PTFAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_member.ptfmm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFMM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_member.ptfmm_frp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFMM_FRP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_member.ptfmm_inst_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PTFMM_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_member.ptfmm_pat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTFMM_PAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_prof.pfp_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_prof.pfp_ptfam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFP_PTFAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_family_prof.pfp_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFP_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_prof.pfp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_family_prof.pfp_pat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFP_PAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_fam_soc_hist.pfsh_ptfam_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFSH_PTFAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_fam_soc_hist.pfsh_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFSH_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_fam_soc_hist.pfsh_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFSH_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_fam_soc_hist.pfsh_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFSH_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_fam_soc_hist.pfsh_pat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFSH_PAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_fam_soc_hist.pfsh_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFSH_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_fam_soc_hist.pfsh_prof_write_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PFSH_PROF_WRITE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_ginec.ptgc_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTGC_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_ginec.ptgc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTGC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_ginec_obstet.pgc_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGC_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_ginec_obstet.pgc_oce_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGC_OCE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_ginec_obstet.pgc_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGC_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_ginec_obstet.pgc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_graffar_crit.pgct_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGCT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_graffar_crit.pgct_gcv_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGCT_GCV_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_graffar_crit.pgct_pat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGCT_PAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_graffar_crit.pgct_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGCT_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_habit.ptnot_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTNOT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_habit.ptnot_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTNOT_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_habit.ptnot_prof_writes_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PTNOT_PROF_WRITES_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_habit.ptnot_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTNOT_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_habit.ptnot_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTNOT_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_habit.ptnot_hat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTNOT_HAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_habit.ptnot_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTNOT_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_health_plan.php_hpn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PHP_HPN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_health_plan.php_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PHP_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_health_plan.php_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PHP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_health_plan.php_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PHP_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\patient.pat_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\patient.pat_ptfam_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAT_PTFAM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_job.ptjob_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTJOB_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_job.ptjob_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTJOB_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_job.ptjob_occ_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PTJOB_OCC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_job.ptjob_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTJOB_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_med_decl.pmd_prof_writes_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMD_PROF_WRITES_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_med_decl.pmd_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMD_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_med_decl.pmd_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMD_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_med_decl.pmd_diag_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMD_DIAG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_med_decl.pmd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_med_decl.pmd_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMD_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication.pmn_prof_upd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMN_PROF_UPD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication.pmn_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMN_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_medication.pmn_prof_writes_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMN_PROF_WRITES_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication.pmn_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMN_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication.pmn_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMN_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication.pmn_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PMN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication.pmn_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMN_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication.pmn_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMN_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_hist_list.pmhl_ieb_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMHL_IEB_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_medication_hist_list.pmhl_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMHL_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_hist_list.pmhl_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMHL_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_hist_list.pmhl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMHL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_medication_hist_list.pmhl_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMHL_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_hist_list.pmhl_imd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMHL_IMD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_hist_list.pmhl_pml_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMHL_PML_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_medication_hist_list.pmhl_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMHL_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_hist_list.pmhl_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMHL_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_hist_list.pmhl_ppn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PMHL_PPN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_hist_list.pmhl_softw_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PMHL_SOFTW_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_list.pml_ieb_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PML_IEB_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_list.pml_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PML_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_list.pml_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PML_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_medication_list.pml_imd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PML_IMD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_list.pml_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PML_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_list.pml_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PML_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_medication_list.pml_ppn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PML_PPN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_list.pml_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PML_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_medication_list.pml_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PML_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_medication_list.pml_softw_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PML_SOFTW_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_necessity.pny_nss_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNY_NSS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_necessity.pny_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNY_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_necessity.pny_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PNY_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_necessity.pny_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNY_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_notes.pns_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNS_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_notes.pns_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNS_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_notes.pns_prof_writes_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNS_PROF_WRITES_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_notes.pns_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_notes.pns_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNS_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_notes.pns_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNS_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_permission.ppn_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPN_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_permission.ppn_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPN_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_permission.ppn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_permission.ppn_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPN_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_photo.ppo_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPO_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_photo.ppo_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PPO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregnancy.ppy_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPY_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregnancy.ppy_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPY_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregnancy.ppy_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPY_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_pregnancy_risk.pgr_gre_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGR_GRE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregnancy_risk.pgr_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGR_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregnancy_risk.pgr_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGR_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_pregnancy_risk.pgr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PGR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregn_fetus.ppf_ppy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPF_PPY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregn_fetus.ppf_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPF_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_pregn_fetus_biom.ppfb_ppf_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPFB_PPF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregn_fetus_biom.ppfb_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPFB_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregn_fetus_biom.ppfb_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPFB_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregn_fetus_biom.ppfb_vsd_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PPFB_VSD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregn_fetus_biom.ppfb_vsn_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPFB_VSN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregn_fetus_det.ppfd_ppf_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPFD_PPF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregn_fetus_det.ppfd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPFD_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_pregn_fetus_det.ppfd_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPFD_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregn_measure.ppme_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPME_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_pregn_measure.ppme_ppy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPME_PPY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_problem.ppm_diag_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPM_DIAG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem.ppm_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPM_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem.ppm_prof_ins_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPM_PROF_INS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_problem.ppm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem.ppm_comp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPM_COMP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem.ppm_eds_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPM_EDS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem.ppm_epis_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PPM_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem.ppm_hat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPM_HAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem.ppm_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPM_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem.ppm_ptnot_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPM_PTNOT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_problem_hist.pph_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPH_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem_hist.pph_comp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPH_COMP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem_hist.pph_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPH_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_problem_hist.pph_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPH_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem_hist.pph_ppm_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPH_PPM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_problem_hist.pph_ptnot_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPH_PTNOT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_prob_visit.ppv_ppm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPV_PPM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_prob_visit.ppv_vis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPV_VIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_prob_visit.ppv_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_sick_leave.pba_prof_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PBA_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_sick_leave.pba_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PBA_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_sick_leave.pba_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PBA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_sick_leave.pba_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PBA_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_soc_attributes.ptsat_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTSAT_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_soc_attributes.ptsat_sch_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTSAT_SCH_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_soc_attributes.ptsat_ctr_address_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTSAT_CTR_ADDRESS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_soc_attributes.ptsat_ctr_nation_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTSAT_CTR_NATION_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_soc_attributes.ptsat_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTSAT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_soc_attributes.ptsat_rel_fk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTSAT_REL_FK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\pat_soc_attributes.ptsat_i_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTSAT_I_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_soc_attributes.ptsat_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTSAT_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_soc_attributes.ptsat_lang_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTSAT_LANG_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_tmp_remota.sys_c007687.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_C007687','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_vaccine.pve_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PVE_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_vaccine.pve_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PVE_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_vaccine.pve_vcc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PVE_VCC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\pat_vaccine.pve_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PVE_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pat_vaccine.pve_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PVE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\periodic_exam_educ.pee_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PEE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\periodic_exam_educ.pee_pee_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PEE_PEE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\periodic_exam_educ.pee_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PEE_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\periodic_exam_educ.pee_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PEE_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\periodic_exam_educ.pee_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PEE_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\positioning.posi_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','POSI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\positioning_type.ptype_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTYPE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\postal_code_pt.pct_pt_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PCT_PT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pregnancy_risk_eval.gre_gre_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','GRE_GRE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\pregnancy_risk_eval.gre_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','GRE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prep_message.pme_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PME_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\prep_message.pme_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PME_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\presc_attention_det.pad_ppn_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAD_PPN_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\presc_attention_det.pad_flg_attention_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAD_FLG_ATTENTION_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\presc_attention_det.pad_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\presc_attention_det.pad_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAD_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\presc_attention_det.pad_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAD_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\presc_attention_det.pad_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAD_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\presc_pat_problem.ppp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\presc_pat_problem.ppp_pal_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPP_PAL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\presc_pat_problem.ppp_ppm_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PPP_PPM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\presc_pat_problem.ppp_ppn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPP_PPN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\presc_pat_problem.ppp_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\presc_pat_problem.ppp_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPP_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\prescription.prn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription.prn_inst_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRN_INST_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription.prn_s_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRN_S_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prescription.prn_prof_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRN_PROF_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription.prn_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRN_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription.prn_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRN_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prescription.prn_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRN_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription.prn_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRN_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription.prn_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRN_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription.prn_prof_fk3.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PRN_PROF_FK3','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription.prn_epis_fk2_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRN_EPIS_FK2_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_number_seq.pnq_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_number_seq.pnq_ete_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNQ_ETE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\prescription_number_seq.pnq_cse_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PNQ_CSE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_pharm.ppn_ida_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPN_IDA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_pharm.ppn_ieb_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPN_IEB_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prescription_pharm.prm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_pharm.ppn_mad_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPN_MAD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_pharm.ppn_ddg_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPN_DDG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prescription_pharm.ppn_prn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPN_PRN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_pharm.ppn_drug_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPN_DRUG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_pharm.ppn_iva_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPN_IVA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_pharm_det.ppt_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PPT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_pharm_det.ppt_ppn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPT_PPN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_pharm_det.ppt_ing_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPT_ING_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_print.ppr_prn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPR_PRN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\prescription_print.ppr_pxl_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPR_PXL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_print.ppr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_type.pty_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTY_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prescription_type.pty_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTY_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_type_access.ptya_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTYA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_xml.pxl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PXL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prescription_xml.pxl_xml_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PXL_XML_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prescription_xml_det.pdl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_access.pass_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PASS_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_access.pass_dcs_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PASS_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_access.pass_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PASS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_access.pass_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PASS_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_access.pass_sbpp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PASS_SBPP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\prof_access.pass_s_context_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PASS_S_CONTEXT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_access.pass_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PASS_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_access.pass_ssst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PASS_SSST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_access_field_func.paff_sfy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAFF_SFY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_access_field_func.paff_sfd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAFF_SFD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_access_field_func.paff_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAFF_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_access_field_func.paff_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PAFF_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_cat.pct_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCT_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_cat.pct_cat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCT_CAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_cat.pct_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PCT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_cat.pct_cats_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCT_CATS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_cat.pct_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCT_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_cat.pct_uk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCT_UK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\prof_dep_clin_serv.pcst_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCST_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_dep_clin_serv.pcst_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCST_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_dep_clin_serv.pcst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PCST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_doc.pdc_dte_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDC_DTE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_doc.pdc_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDC_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_doc.pdc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_doc.pdc_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDC_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_epis_interv.pei_eiv_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PEI_EIV_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_epis_interv.pei_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PEI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_epis_interv.pei_cat_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PEI_CAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_epis_interv.pei_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PEI_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\professional.prof_spc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PROF_SPC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\professional.prof_sch_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PROF_SCH_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\professional.prof_ctr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PROF_CTR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\professional.prof_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PROF_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_ext_sys.pess_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PESS_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_ext_sys.pess_ess_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PESS_ESS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_ext_sys.pess_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PESS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_ext_sys.pess_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PESS_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_func.pfc_sfy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFC_SFY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_func.pfc_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFC_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_func.pfc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_func.pfc_dcs_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PFC_DCS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_func.pfc_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFC_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\profile_templ_access.pta_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\profile_templ_access.pta_sbpp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTA_SBPP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\profile_templ_access.pta_s_context_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTA_S_CONTEXT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\profile_templ_access.pta_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTA_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\profile_templ_access.pta_spt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTA_SPT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\profile_templ_access.pta_ssst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTA_SSST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\profile_templ_acc_func.ptaf_sfd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTAF_SFD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\profile_templ_acc_func.ptaf_spt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTAF_SPT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\profile_templ_acc_func.ptaf_sfy_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTAF_SFY_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\profile_templ_acc_func.ptaf_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTAF_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\profile_template.spt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\profile_template.spt_inst_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SPT_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\profile_template.spt_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPT_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\profile_template.spt_spt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPT_SPT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_in_out.pio_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PIO_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\prof_in_out.pio_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PIO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_in_out.pio_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PIO_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_in_out.pio_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PIO_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_institution.prins_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRINS_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_institution.prins_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRINS_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_institution.prins_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRINS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_institution.prins_uk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRINS_UK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_photo.pfpo_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFPO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_photo.pfpo_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PFPO_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_preferences.pps_prof_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PPS_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_preferences.pps_lang_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPS_LANG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_preferences.pps_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_preferences.pps_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPS_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\prof_preferences.pps_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPS_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_preferences.pps_uk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PPS_UK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_profile_template.pte_spt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTE_SPT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_profile_template.pte_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTE_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_profile_template.pte_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_profile_template.pte_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTE_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_profile_template.pte_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTE_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_profile_template.pte_uk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PTE_UK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_room.spr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_room.spr_id_prof_fk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SPR_ID_PROF_FK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_room.spr_cats_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPR_CATS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_room.spr_room_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPR_ROOM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_room.spr_spt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPR_SPT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\prof_soft_inst.psit_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PSIT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_soft_inst.psit_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PSIT_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_soft_inst.psit_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PSIT_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_soft_inst.psit_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PSIT_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_soft_inst.psit_uk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PSIT_UK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_team.prof_team_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PROF_TEAM_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\prof_team.prof_team_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PROF_TEAM_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_team.prof_team_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PROF_TEAM_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_team.prof_team_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PROF_TEAM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_team_det.prf_team_d_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PRF_TEAM_D_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_team_det.prf_team_d_prof_team_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRF_TEAM_D_PROF_TEAM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_team_det.prf_team_d_cats_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRF_TEAM_D_CATS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\prof_team_det.prf_team_d_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRF_TEAM_D_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\prof_team_det.prf_team_d_prof_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRF_TEAM_D_PROF_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\protoc_diag.pdig_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDIG_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\protoc_diag.pdig_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDIG_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\protoc_diag.pdig_prt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDIG_PRT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\protoc_diag.pdig_diag_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDIG_DIAG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\protoc_diag.pdig_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDIG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\protocols.prt_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRT_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\protocols.prt_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRT_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\protocols.prt_sipg_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRT_SIPG_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\protocols.prt_code_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PRT_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\protocols.prt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_doc_external.doc_ext_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_EXT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_doc_external_request.doc_req_doc_ext_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_REQ_DOC_EXT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\p1_doc_external_request.doc_req_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOC_REQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_documents.docs_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_documents_done.docs_done_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCS_DONE_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\p1_documents_done.docs_done_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DOCS_DONE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_external_request.ertx_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERTX_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_external_request.ertx_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERTX_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\p1_external_request.ertx_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERTX_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_external_request.ertx_prof__fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERTX_PROF__FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_external_request.ertx_inst___fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERTX_INST___FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_external_request.ertx_schd_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ERTX_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_external_request.ertx_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERTX_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_external_request.ertx_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERTX_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_ext_req_tracking.ert_ertx_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERT_ERTX_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\p1_ext_req_tracking.ert_prins_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERT_PRINS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_ext_req_tracking.ert_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ERT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_history.hst_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HST_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\p1_history.hst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','HST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_prblm_rec_procedure.prp_rec_proc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRP_REC_PROC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_prblm_rec_procedure.prp_prblm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRP_PRBLM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\p1_prblm_rec_procedure.prp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_problem.prblm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PRBLM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_problem_dep_clin_serv.pdcs_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDCS_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_problem_dep_clin_serv.pdcs_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','PDCS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_recomended_procedure.rec_proc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','REC_PROC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\recm.recm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RECM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\records_review.rrw_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RRW_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\records_review_read.rrwr_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RRWR_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\records_review_read.rrwr_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RRWR_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\records_review_read.rrwr_rrw_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RRWR_RRW_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\records_review_read.rrwr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RRWR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\religion.rel_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','REL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\rep_destination.rdn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RDN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\reports.rep_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','REP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\reports_group.repgp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','REPGP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\rep_prof_exception.rpnx_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RPNX_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\rep_profile_template.rpte_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','RPTE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\rep_profile_template_det.rpe_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RPE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\rep_prof_templ_access.rpsac_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RPSAC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\rep_prof_template.rpepr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RPEPR_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\rep_screen.sfc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SFC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\rep_section.rsn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RSN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\rep_section_det.rgp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RGP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\result_status.rss_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RSS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\room.room_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ROOM_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\room.room_dep_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ROOM_DEP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\room.room_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ROOM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\room_dep_clin_serv.rcst_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RCST_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\room_dep_clin_serv.rcst_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RCST_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\room_dep_clin_serv.rcst_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','RCST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\room_dep_position.rdepp_room_fk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RDEPP_ROOM_FK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\room_dep_position.rdepp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RDEPP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\room_ext_sys.res_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RES_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\room_ext_sys.res_ess_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RES_ESS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\room_ext_sys.res_room_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RES_ROOM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\room_scheduled.rsd_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RSD_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\room_scheduled.rsd_schd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RSD_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\room_scheduled.rsd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RSD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\rotation_interval.ril_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','RIL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sample_recipient.srt_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRT_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_recipient.srt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_recipient.srt_id_code_sample_ui.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRT_ID_CODE_SAMPLE_UI','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text.sstt_sst_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SSTT_SST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text.sstt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSTT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text.sstt_diag_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSTT_DIAG_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text_freq.fst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FST_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sample_text_freq.fst_sstt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','FST_SSTT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text_prof.stt_sst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','STT_SST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text_prof.stt_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','STT_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sample_text_prof.stt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','STT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text_prof.stt_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','STT_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text_type.sst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sample_text_type.sst_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SST_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text_type_cat.sttc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','STTC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text_type_cat.sttc_cat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','STTC_CAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text_type_cat.sttc_inst_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','STTC_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_text_type_cat.sttc_sst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','STTC_SST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_type.ste_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','STE_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sample_type.ste_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','STE_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\scales.sce_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\scales_class.scsc_sce_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCSC_SCE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\scales_class.scsc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCSC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\scales_doc_value.sde_sce_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SDE_SCE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\scales_doc_value.sde_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SDE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_action.san_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sch_cancel_reason.slr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_cancel_reason_inst.sli_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_consult_vacancy.scv_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule.schd_prof_requests_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SCHD_PROF_REQUESTS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule.schd_inst_requested_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHD_INST_REQUESTED_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule.schd_dcs_requests_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHD_DCS_REQUESTS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule.schd_dcs_requested_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHD_DCS_REQUESTED_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\schedule.schd_inst_requests_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHD_INST_REQUESTS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule.schd_prof_schedules_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHD_PROF_SCHEDULES_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule.schd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\schedule.schd_dt_begin_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHD_DT_BEGIN_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule.schd_dt_dcs_requested.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHD_DT_DCS_REQUESTED','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_alter.sar_schd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAR_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\schedule_alter.sar_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAR_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_alter.sar_prof_requests_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAR_PROF_REQUESTS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_alter.sar_prof_requested_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAR_PROF_REQUESTED_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_alter.sar_dcs_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SAR_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_alter.sar_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_outp.sop_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SOP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_outp.sop_flg_sched.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SOP_FLG_SCHED','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\schedule_outp.sop_flg_state_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SOP_FLG_STATE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_outp.sop_schd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SOP_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr.sched_sr_id_schedule.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHED_SR_ID_SCHEDULE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\schedule_sr.sched_sr_can_rea_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHED_SR_CAN_REA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr.sr_sched_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SCHED_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr.sr_sched_dtarget_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SCHED_DTARGET_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\schedule_sr.sr_sched_prof_reg.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SCHED_PROF_REG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr.sched_sr_dep_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHED_SR_DEP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr.sched_sr_diag_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHED_SR_DIAG_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr.sched_sr_prof_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SCHED_SR_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr.sr_sched_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SCHED_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr.sr_sched_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SCHED_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr.sr_sched_pat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SCHED_PAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\schedule_sr_det.ssrtd_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSRTD_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr_det.ssrtd_sr_sched_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSRTD_SR_SCHED_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr_det.ssrtd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSRTD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sch_event.sct_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_event_dcs.sec_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_event_inst.sch_event_inst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCH_EVENT_INST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sch_group.sgp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SGP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_group.sgp_patient_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SGP_PATIENT_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_log.slg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\scholarship.sch_code_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SCH_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\scholarship.sch_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCH_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\school.scl_sch_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCL_SCH_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\school.scl_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCL_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\school.scl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_permission.scn_prof_flg.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCN_PROF_FLG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_permission.scn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sch_permission.scn_prof_prof_dcs_event.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCN_PROF_PROF_DCS_EVENT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_prof_outp.spo_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_prof_outp.spo_schd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPO_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sch_prof_outp.spo_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPO_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_resource.sre_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_resource.sre_id_prof.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRE_ID_PROF','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_schedule_request.ssr_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SSR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_service.sse_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sch_service_dcs.ssc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\screen_template.step_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','STEP_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\serv_sched_access.ssa_inst_accesses_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSA_INST_ACCESSES_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\serv_sched_access.ssa_dcs_accessed_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSA_DCS_ACCESSED_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\serv_sched_access.ssa_inst_accessed_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSA_INST_ACCESSED_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\serv_sched_access.ssa_dcs_accesses_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSA_DCS_ACCESSES_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\serv_sched_access.ssa_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\slot.slt_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLT_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\slot.slt_dcs_availto_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLT_DCS_AVAILTO_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\slot.slt_matr_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLT_MATR_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\slot.slt_prof_writes_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLT_PROF_WRITES_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\slot.slt_dcs_avail_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SLT_DCS_AVAIL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\slot.slt_prof_avail_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLT_PROF_AVAIL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\slot.slt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\snomed_concepts.sc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SC_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\snomed_descriptions.sd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\snomed_descriptions.i_concept.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','I_CONCEPT','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\snomed_relationships.sr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\snomed_relationships.i_concept1.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','I_CONCEPT1','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\snomed_relationships.i_concept2.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','I_CONCEPT2','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_class.scs_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\social_diagnosis.sds_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SDS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_diagnosis.sds_sds_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SDS_SDS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_diag.esd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ESD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_diag.esd_see_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ESD_SEE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_diag.esd_sds_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ESD_SDS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_diag.esd_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ESD_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_diag.esd_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ESD_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\social_epis_discharge.sed_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SED_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_discharge.sed_see_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SED_SEE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_discharge.sed_drd_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SED_DRD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\social_epis_discharge.sed_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SED_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_discharge.sed_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SED_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_discharge.sed_trp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SED_TRP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\social_epis_interv.esi_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ESI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_interv.esi_see_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ESI_SEE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_interv.esi_sin_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ESI_SIN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_interv.esi_prof_cancel_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','ESI_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_interv.esi_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ESI_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_episode.see_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_episode.see_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEE_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\social_episode.see_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEE_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_request.sert_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SERT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_request.sert_see_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SERT_SEE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\social_epis_request.sert_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SERT_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_situation.sesi_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SESI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_situation.sesi_see_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SESI_SEE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\social_epis_solution.seso_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SESO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_solution.seso_see_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SESO_SEE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_solution.seso_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SESO_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_intervention.sin_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SIN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\soft_inst_impl.sii_impl_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SII_IMPL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\soft_inst_impl.sii_dcs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SII_DCS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\soft_inst_impl.sii_si_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SII_SI_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\soft_inst_impl.sii_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SII_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\soft_inst_services.sis_sii_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SIS_SII_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\soft_inst_services.sis_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SIS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\soft_lang.slng_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLNG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\soft_lang.slng_lae_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLNG_LAE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\soft_lang.slng_sft_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SLNG_SFT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\software.s_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','S_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\software_dept.sdt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SDT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\software_dept.sdt_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SDT_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\software_dept.sdt_dpt_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SDT_DPT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\software_institution.si_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\software_institution.si_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SI_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\software_institution.si_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SI_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\speciality.spc_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPC_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\speciality.spc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\spec_sys_appar.ssar_spc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSAR_SPC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\spec_sys_appar.ssar_sai_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSAR_SAI_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\spec_sys_appar.ssar_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSAR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_base_diag.sbgd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBGD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_base_diag.sbg_diag_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBG_DIAG_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_base_diag.sbg_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBG_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_base_diag.sbg_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBG_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_cancel_reason.sr_can_rea_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SR_CAN_REA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_chklist.sr_cklist_ssd_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_CKLIST_SSD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_chklist.sr_cklist_sr_cklist_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_CKLIST_SR_CKLIST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_chklist.sr_cklist_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_CKLIST_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_chklist_det.sr_cklst_d_sr_cklist_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_CKLST_D_SR_CKLIST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_chklist_det.sr_cklst_d_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_CKLST_D_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_chklist_det.sr_cklst_d_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_CKLST_D_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_chklist_det.sr_cklst_d_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_CKLST_D_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_chklist_det.sr_cklst_d_prof_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_CKLST_D_PROF_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_chklist_manual.sclm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCLM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_chklist_manual.scl_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCL_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_chklist_manual.scl_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCL_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_epis_interv.sev_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_epis_interv.sev_interv_epis_uk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SEV_INTERV_EPIS_UK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_epis_interv.sev_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEV_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_epis_interv.sev_prof_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEV_PROF_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_epis_interv.sev_sin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEV_SIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_epis_interv.sev_sr_can_rea_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEV_SR_CAN_REA_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_epis_interv_desc.sr_int_des_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_INT_DES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_epis_interv_desc.sr_int_des_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_INT_DES_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_epis_interv_desc.sr_int_des_prof_can_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_INT_DES_PROF_CAN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_epis_interv_desc.sr_int_des_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_INT_DES_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_epis_interv_desc.sr_int_des_sin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_INT_DES_SIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_equip.sep_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_equip.sep_sep_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEP_SEP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_equip_kit.setk_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SETK_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_equip_kit.setk_sep_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SETK_SEP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_equip_kit.setk_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SETK_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_equip_kit.setk_sep_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SETK_SEP_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_equip_kit.setk_spc_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SETK_SPC_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_equip_period.sqpd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SQPD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_equip_period.sqpd_sep_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SQPD_SEP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_equip_period.sqpd_ssd_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SQPD_SSD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_eval_det.sed_spev_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SED_SPEV_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_det.sevd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEVD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_det.sevd_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEVD_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_eval_det.sevd_sen_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEVD_SEN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_notes.seen_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEEN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_notes.seen_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEEN_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_notes.seen_spev_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SEEN_SPEV_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_rule.sr_ev_rl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_EV_RL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_rule.sr_ev_rl_docarea_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_EV_RL_DOCAREA_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_rule.sr_ev_rl_docec_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_EV_RL_DOCEC_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_eval_summ.sevm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEVM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_type.seet_docarea_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEET_DOCAREA_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_type.seet_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEET_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_eval_type.seet_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEET_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_type.seet_ssd_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEET_SSD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_type.seet_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEET_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_evaluation.sen_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_evaluation.sen_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEN_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_evaluation.sen_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SEN_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_visit.spvs_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SPVS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_visit.spev_seet_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPEV_SEET_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_visit.spvs_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPVS_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_eval_visit.spvs_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPVS_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_eval_visit.spvs_prof_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPVS_PROF_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_interv_dep_clin_serv.siv_dcs_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SIV_DCS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_interv_dep_clin_serv.siv_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SIV_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_interv_dep_clin_serv.siv_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SIV_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_interv_dep_clin_serv.siv_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SIV_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_interv_dep_clin_serv.siv_sin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SIV_SIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_interv_desc.sr_itv_des_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_ITV_DES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_interv_desc.sr_itv_des_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_ITV_DES_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_interv_desc.sr_itv_des_lang_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_ITV_DES_LANG_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_interv_desc.sr_itv_des_s_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SR_ITV_DES_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_interv_desc.sr_itv_des_sin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_ITV_DES_SIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_intervention.sint_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SINT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_intervention.sin_sin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SIN_SIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_intervention.sin_spc_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SIN_SPC_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_intervention.sin_sys_org_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SIN_SYS_ORG_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_interv_group.sipg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SIPG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_interv_group_det.sitgd_sin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SITGD_SIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_interv_group_det.sitgd_sipg_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SITGD_SIPG_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_nurse_rec.snc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SNC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_nurse_rec.snc_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SNC_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_nurse_rec.snc_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SNC_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pat_status.spu_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPU_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pat_status.spu_epis_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SPU_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pat_status.spu_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPU_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pat_status_notes.spsn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPSN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pat_status_notes.spsn_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPSN_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_pat_status_notes.spsn_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPSN_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pat_status_period.sr_sts_per_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_STS_PER_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pat_status_period.sr_sts_per_ssd_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_STS_PER_SSD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_pos_eval_det.sposed_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPOSED_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pos_eval_det.sposed_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPOSED_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pos_eval_det.sposed_sposev_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPOSED_SPOSEV_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_pos_eval_visit.sposev_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPOSEV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pos_eval_visit.sposev_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPOSEV_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pos_eval_visit.sposev_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPOSEV_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pos_eval_visit.sposev_prof_fk2_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SPOSEV_PROF_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_posit.sr_pos_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_POS_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_posit.sr_pos_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_POS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_posit_req.spq_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPQ_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_posit_req.spq_prof_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPQ_PROF_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_posit_req.spq_prof_fk3_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPQ_PROF_FK3_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_posit_req.spq_prof_fk4_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPQ_PROF_FK4_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_posit_req.spq_sr_pos_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPQ_SR_POS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_posit_req.spq_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPQ_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_posit_req.spq_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_pre_anest.spta_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPTA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pre_anest.spta_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPTA_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pre_anest.spta_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPTA_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pre_anest.spta_spt_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SPTA_SPT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pre_anest_det.spand_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPAND_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pre_anest_det.spand_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPAND_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pre_anest_det.spand_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPAND_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_pre_anest_det.spand_spt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPAND_SPT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pre_eval.spe_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pre_eval.spe_inst_soft_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPE_INST_SOFT_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_pre_eval_det.sped_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPED_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pre_eval_det.sped_epis_visit_ui.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPED_EPIS_VISIT_UI','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_pre_eval_visit.spev_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPEV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_prof_recov_schd.sr_prsch_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PRSCH_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_prof_recov_schd.sr_prsch_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PRSCH_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_prof_recov_schd.sr_prsch_room_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PRSCH_ROOM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_prof_shift.spsht_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SPSHT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_prof_shift.spsht_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPSHT_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_prof_shift.spsht_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SPSHT_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_prof_team_det.sr_pf_team_cats_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PF_TEAM_CATS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_prof_team_det.sr_pf_team_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PF_TEAM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_prof_team_det.sr_pf_team_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PF_TEAM_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_prof_team_det.sr_pf_team_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PF_TEAM_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_prof_team_det.sr_pf_team_prof_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PF_TEAM_PROF_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_prof_team_det.sr_pf_team_prof_fk3_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PF_TEAM_PROF_FK3_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_prof_team_det.sr_pf_team_prof_fk4_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PF_TEAM_PROF_FK4_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_prof_team_det.sr_pf_team_prof_team_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PF_TEAM_PROF_TEAM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_receive.sr_recv_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_RECV_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_receive.sr_recv_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_RECV_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_receive.sr_recv_prof_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SR_RECV_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_receive_manual.srl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_receive_manual.srl_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRL_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_receive_manual.srl_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRL_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_receive_proc.sr_rec_pro_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_REC_PRO_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_receive_proc_det.sr_rcv_det_sr_rec_pro_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_RCV_DET_SR_REC_PRO_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_receive_proc_det.sr_rcv_det_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_RCV_DET_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_receive_proc_det.sr_rcv_det_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_RCV_DET_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_receive_proc_det.sr_rcv_det_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_RCV_DET_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_receive_proc_notes.sr_rcv_not_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_RCV_NOT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_receive_proc_notes.sr_rcv_not_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_RCV_NOT_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_receive_proc_notes.sr_rcv_not_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_RCV_NOT_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_reserv_req.srq_sep_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRQ_SEP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_reserv_req.srq_epis_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SRQ_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_reserv_req.srq_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRQ_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_reserv_req.srq_prof_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRQ_PROF_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_reserv_req.srq_prof_fk3_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRQ_PROF_FK3_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_reserv_req.srq_prt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRQ_PRT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_reserv_req.srq_sep_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRQ_SEP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_reserv_req.srq_sin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRQ_SIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_reserv_req.srq_ssd_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRQ_SSD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_room_status.sru_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRU_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_room_status.sru_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRU_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_room_status.sru_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRU_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_room_status.sru_room_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRU_ROOM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_rec_det.sstd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSTD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_rec_det.sst_prof_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SST_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_rec_det.sst_sr_rec_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SST_SR_REC_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_record.sr_rec_cse_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_REC_CSE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_record.sr_rec_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_REC_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_record.sr_rec_pat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_REC_PAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_record.sr_rec_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_REC_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_record.sr_rec_prof_team_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_REC_PROF_TEAM_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_surgery_record.sr_rec_sin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_REC_SIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_record.sr_rec_id_schedule.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_REC_ID_SCHEDULE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_record.sr_rec_anest_type_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_REC_ANEST_TYPE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_surgery_record.sr_rec_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_REC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_time.sr_times_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_TIMES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_time.sr_times_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_TIMES_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_time.sr_times_s_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SR_TIMES_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_time_det.sr_tim_det_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_TIM_DET_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_time_det.sr_tim_det_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_TIM_DET_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_time_det.sr_tim_det_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_TIM_DET_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_time_det.sr_tim_det_prof_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_TIM_DET_PROF_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surgery_time_det.sr_tim_det_sr_times_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_TIM_DET_SR_TIMES_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surg_period.ssd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_surg_prot_det.sr_sp_det_sr_sp_task_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SP_DET_SR_SP_TASK_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surg_prot_det.sr_sp_det_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SP_DET_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surg_protocol.sr_prot_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_PROT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sr_surg_prot_task.sr_sp_task_sr_su_task_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SP_TASK_SR_SU_TASK_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surg_prot_task.sr_sp_task_sr_prot_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SP_TASK_SR_PROT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surg_prot_task.sr_sp_task_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SP_TASK_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surg_prot_task_det.sr_spt_det_sr_sp_task_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SPT_DET_SR_SP_TASK_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surg_prot_task_det.sr_spt_det_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SPT_DET_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sr_surg_task.sr_su_task_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SR_SU_TASK_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert.sa_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SA_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sys_alert.sa_sys_alt_tp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SA_SYS_ALT_TP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_det.sad_id_alert_flg_new_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAD_ID_ALERT_FLG_NEW_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_det.sad_prof_alert_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAD_PROF_ALERT_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_alert_det.at_alert_det_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AT_ALERT_DET_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_det.at_ide_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AT_IDE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_det.at_ii_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AT_II_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_alert_det.at_is_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AT_IS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_prof.sap_sa_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAP_SA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_prof.sap_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_prof.sap_inst_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SAP_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_prof.sap_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_prof.sap_prof_template.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAP_PROF_TEMPLATE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_prof.sap_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAP_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sys_alert_profile.sapr_spt_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAPR_SPT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_profile.sapr_sa_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAPR_SA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_profile.sapr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAPR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_alert_profile.sapr_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAPR_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_software.sys_alt_sw_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_ALT_SW_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_software.sys_alt_ssst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_ALT_SSST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_alert_software.sys_alt_sw_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_ALT_SW_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_software.sys_alt_sw_sa_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_ALT_SW_SA_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_software.sys_alt_sw_sw_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_ALT_SW_SW_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_alert_type.sys_alt_tp_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_ALT_TP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_appar_organ.sys_aporg_sai_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_APORG_SAI_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_appar_organ.sys_aporg_sys_org_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_APORG_SYS_ORG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_appar_organ.sys_aporg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_APORG_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sys_application_area.aaa_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','AAA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_application_type.sat_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_btn_crit.sbt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_btn_crit.sbt_btn_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBT_BTN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_btn_crit.sbt_crt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBT_CRT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_btn_sbg.sbs_sbg_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBS_SBG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_btn_sbg.sbs_btn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBS_BTN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_btn_sbg.sbs_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_btn_sbg.sbs_aaa_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBS_AAA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_btn_sbg.sbs_saa_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SBS_SAA_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_btn_sbg.sbs_btn_parent_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBS_BTN_PARENT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_button.btn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BTN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_button_group.sbg_stb_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBG_STB_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sys_button_group.sbg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_button_prop.sbpp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBPP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_button_prop.sbpp_aaa_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBPP_AAA_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_button_prop.sbpp_btn_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBPP_BTN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_button_prop.sbpp_saa_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBPP_SAA_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_button_prop.sbpp_sat_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBPP_SAT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_button_prop.sbpp_sbpp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SBPP_SBPP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_config.pk_sys_config.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PK_SYS_CONFIG','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_config.sc_id_config_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SC_ID_CONFIG_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_config.sc_instsw_ui.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SC_INSTSW_UI','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_config.scg_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCG_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_config.scg_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCG_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_domain.sdn_lang_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SDN_LANG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sys_domain.sdn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SDN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_element.syse_dim_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYSE_DIM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_element.syse_sysd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYSE_SYSD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_element.syse_elem_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYSE_ELEM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_element.syse_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYSE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_element_crit.syec_syse_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYEC_SYSE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_element_crit.syec_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYEC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_element_crit.syec_elemc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYEC_ELEMC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_entrance.pk_sys_entrance.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PK_SYS_ENTRANCE','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_error.ser_srqt_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SER_SRQT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_error.ser_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SER_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_field.sfd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SFD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_functionality.sfy_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SFY_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sys_functionality.sfy_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SFY_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_login.pk_sys_login.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PK_SYS_LOGIN','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_message.sme_lang_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SME_LANG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_message.sme_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SME_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_message.sme_langsw_ui.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SME_LANGSW_UI','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_message.sme_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SME_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_message.sme_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SME_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_request.srqt_ssn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRQT_SSN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_request.srqt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SRQT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_request.srqt_dt_day.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','SRQT_DT_DAY','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_screen_area.saa_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAA_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_screen_template.sste_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSTE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_session.ssn_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSN_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\sys_session.ssn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_shortcut.ssst_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSST_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_shortcut.ssst_uk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSST_UK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\sys_shortcut.ssst_sbpp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSST_SBPP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_shortcut.ssst_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSST_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_shortcut.ssst_ssst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SSST_SSST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\system_apparati.sai_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SAI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\system_organ.sys_org_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SYS_ORG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_time_event_group.tgm_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TGM_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_time_event_group.tgm_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','TGM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\sys_toolbar.stb_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','STB_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\tests_review.trw_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRW_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\tests_review.trw_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRW_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\time_unit.tut_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TUT_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\time_unit.tut_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TUT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\toad_plan_sql.tpsql_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TPSQL_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\toad_plan_table.tptbl_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TPTBL_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\translation.trl_lang_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRL_LANG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\translation.trl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\translation.trl_lang_codetrans_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRL_LANG_CODETRANS_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_ent_inst.tei_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TEI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_ent_inst.tei_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TEI_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_ent_inst.tei_trp_fk_idx.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','TEI_TRP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_entity.trp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_entity.trp_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRP_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transportation.etp_trp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETP_TRP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\transportation.etp_trq_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETP_TRQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transportation.etp_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transportation.etp_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETP_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\transportation.etp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','ETP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transport_type.tte_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TTE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_req.trq_inst_dest_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRQ_INST_DEST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\transp_req.trq_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRQ_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_req.trq_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRQ_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_req.trq_inst_req_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRQ_INST_REQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_req.trq_trg_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','TRQ_TRG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_req.trq_tte_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRQ_TTE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_req.trq_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_req.trq_crq_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRQ_CRQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\transp_req.trq_ereq_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRQ_EREQ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_req.trq_art_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRQ_ART_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_req_group.trg_tte_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRG_TTE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\transp_req_group.trg_trp_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRG_TRP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\transp_req_group.trg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\treatment_management.tman_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TMAN_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\treatment_management.tman_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TMAN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage.tri_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage.tri_tdisc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRI_TDISC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage.tri_tcol_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','TRI_TCOL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage.tri_typ_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRI_TYP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage.tri_tbrd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRI_TBRD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_board.tbrd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TBRD_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\triage_board_group.tbgp_typ_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TBGP_TYP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_board_group.tbgp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TBGP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_board_grouping.tbgg_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TBGG_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\triage_color.tcol_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TCOL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_color.tcol_typ_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TCOL_TYP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_considerations.tc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\triage_disc_help.tdhp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TDHP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_discriminator.trdisc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TRDISC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_discriminator_help.tdihp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TDIHP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_n_consid.tnc_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','TNC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_nurse.tnsr_typ_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TNSR_TYP_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_nurse.tnsr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TNSR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_nurse.tnsr_tcol_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TNSR_TCOL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\triage_type.typ_tunits_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TYP_TUNITS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_type.typ_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TYP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\triage_units.tunits_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TUNITS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\triage_white_reason.twrn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','TWRN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\unit_mea_soft_inst.umsi_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','UMSI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\unit_mea_soft_inst.umsi_unitm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','UMSI_UNITM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\unit_mea_soft_inst.umsi_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','UMSI_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\unit_mea_soft_inst.umsi_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','UMSI_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\unit_measure.unitm_umtype_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','UNITM_UMTYPE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\unit_measure.unitm_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','UNITM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\unit_measure_type.umtype_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','UMTYPE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine.vcc_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VCC_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine.vcc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VCC_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\vaccine_dep_clin_serv.vdcs_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VDCS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_dep_clin_serv.vdcs_dcs_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VDCS_DCS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_dep_clin_serv.vdcs_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VDCS_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\vaccine_dep_clin_serv.vdcs_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VDCS_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_dep_clin_serv.vdcs_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VDCS_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_dep_clin_serv.vdcs_vcc_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VDCS_VCC_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\vaccine_presc_det.vpc_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPC_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_presc_det.vpc_vpn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPC_VPN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_presc_det.vpc_vcc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPC_VCC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_presc_det.vpc_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','VPC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_presc_plan.vpp_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPP_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_presc_plan.vpp_vpc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPP_VPC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_presc_plan.vpp_schd_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPP_SCHD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\vaccine_presc_plan.vpp_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPP_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_prescription.vpn_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPN_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_prescription.vpn_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPN_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\vaccine_prescription.vpn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_prescription.vpn_epis_dest_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPN_EPIS_DEST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_prescription.vpn_epis_origin_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPN_EPIS_ORIGIN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\vaccine_prescription.vpn_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPN_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vaccine_prescription.vpn_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VPN_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vbz$object_stats.vbz$object_stats.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VBZ$OBJECT_STATS','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\viewer.vir_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','VIR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\viewer_refresh.vrh_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VRH_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\viewer_refresh.vrh_vir_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VRH_VIR_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\viewer_synch_param.vsm_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSM_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\viewer_synch_param.vsm_vse_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSM_VSE_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\viewer_synchronize.vse_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\viewer_synchronize.vse_btn_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSE_BTN_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\viewer_synchronize.vse_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSE_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\viewer_synchronize.vse_pt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSE_PT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\viewer_synchronize.vse_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSE_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\viewer_synchronize.vse_vir_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSE_VIR_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\visit.vis_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VIS_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\visit.vis_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VIS_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\visit.vis_org_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','VIS_ORG_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\visit.vis_extc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VIS_EXTC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\visit.vis_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VIS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign.vsn_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSN_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\vital_sign.vsn_inter_name_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSN_INTER_NAME_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign.vsn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_desc.vsd_svs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSD_SVS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\vital_sign_desc.vsd_code_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSD_CODE_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_desc.vsd_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSD_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_notes.vsnotes_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSNOTES_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\vital_sign_notes.vsnotes_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSNOTES_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_svs_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_SVS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_prof_cancel_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_PROF_CANCEL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_vsd_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_VSD_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_prof_read_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_PROF_READ_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_PK','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_inst_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_INST_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_inst_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_INST_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_mvsp_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_MVSP_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_s_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_S_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_read.vsr_s_fk2_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSR_S_FK2_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\vital_sign_relation.vsrn_vsn_detail_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSRN_VSN_DETAIL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_relation.vsrn_disc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSRN_DISC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_relation.vsrn_vsn_parent_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSRN_VSN_PARENT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_relation.vsrn_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','VSRN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_unit_measure.vsum_unitm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSUM_UNITM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_unit_measure.vsum_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSUM_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_unit_measure.vsum_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSUM_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\vital_sign_unit_measure.vsum_vsn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSUM_VSN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vital_sign_unit_measure.vsum_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSUM_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vs_clin_serv.vcs_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VCS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\vs_clin_serv.vcs_dcs_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VCS_DCS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vs_clin_serv.vcs_svs_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VCS_SVS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vs_soft_inst.vssi_vsn_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSSI_VSN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\vs_soft_inst.vssi_inst_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSSI_INST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vs_soft_inst.vssi_unitm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSSI_UNITM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vs_soft_inst.vssi_s_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','VSSI_S_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\vs_soft_inst.vssi_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','VSSI_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\white_reason.wrn_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WRN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_call_queue.wcq_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WCQ_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_call_queue.wcq_wwl_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WCQ_WWL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\wl_call_queue.wcq_wme_dest_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WCQ_WME_DEST_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_call_queue.wcq_wme_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WCQ_WME_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_call_queue.wcq_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WCQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\wl_machine.wme_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WME_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_machine.wme_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WME_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_mach_prof_queue.wmpq_wme_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WMPQ_WME_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\wl_mach_prof_queue.wmpq_wqe_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WMPQ_WQE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_mach_prof_queue.wmpq_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WMPQ_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_mach_prof_queue.wmpq_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WMPQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_msg_queue.wmq_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','WMQ_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_msg_queue.wmq_wme_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WMQ_WME_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_msg_queue.wmq_wqe_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WMQ_WQE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_prof_room.wpr_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WPR_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\wl_prof_room.wpr_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WPR_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_prof_room.wpr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WPR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_queue.wqe_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WQE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\wl_queue.wqe_dpt_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WQE_DPT_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_status.wss_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WSS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_waiting_line.wwl_pat_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WWL_PAT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\wl_waiting_line.wwl_wss_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WWL_WSS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_waiting_line.wwl_cse_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WWL_CSE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_waiting_line.wwl_prof_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WWL_PROF_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_waiting_line.wwl_wqe_fk_i.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','WWL_WQE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_waiting_line.wwl_room_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WWL_ROOM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_waiting_line.wwl_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WWL_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_waiting_line.wwl_wwl_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WWL_WWL_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\wl_waiting_line.wwl_epis_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WWL_EPIS_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_waiting_room.wwr_room_wait_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WWR_ROOM_WAIT_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wl_waiting_room.wwr_room_cons_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WWR_ROOM_CONS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\wl_waiting_room.wwr_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WWR_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_charac.wcc_wcc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WCC_WCC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_charac.wcc_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WCC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\wound_eval_charac.wec_wcc_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WEC_WCC_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_eval_charac.wec_wen_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WEC_WEN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_eval_charac.wec_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WEC_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_evaluation.wen_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','WEN_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_evaluation.wen_nard_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WEN_NARD_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_evaluation.wen_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WEN_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_treat.wtt_wen_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WTT_WEN_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;

spool off

spool 'c:\mighdc\alert\indexes\wound_treat.wtt_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WTT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_treat.wtt_prof_cancel_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WTT_PROF_CANCEL_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_treat.wtt_prof_exec_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WTT_PROF_EXEC_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\wound_treat.wtt_epis_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WTT_EPIS_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_type.wte_wte_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WTE_WTE_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\wound_type.wte_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','WTE_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off


spool 'c:\mighdc\alert\indexes\dr$d_idx$i.dr$d_idx$x.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DR$D_IDX$X','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\dr$snomed_idx$i.dr$snomed_idx$x.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','DR$SNOMED_IDX$X','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\bp_clin_serv.bcs_pk.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','BCS_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\complaint.cmplt_pk.idx'

select replace(replace(dbms_metadata.get_ddl('INDEX','CMPLT_PK','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\p1_problem_dep_clin_serv.pdcs_prblm_fk_i.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','PDCS_PRBLM_FK_I','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\schedule_sr.sched_sr_spc_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SCHED_SR_SPC_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;
spool off

spool 'c:\mighdc\alert\indexes\social_epis_situation.sesi_prof_fk_idx.idx'
select replace(replace(dbms_metadata.get_ddl('INDEX','SESI_PROF_FK_IDX','ALERT'),'"',''),'ALERT.','') text from dual;

spool off


spool 'c:\mighdc\alert\indexes\execute_indexes.sql'
select '@@' || lower(table_name) || '.' || lower(index_name) || '.idx' from all_indexes  where owner = 'ALERT' and index_type = 'NORMAL';
spool off

