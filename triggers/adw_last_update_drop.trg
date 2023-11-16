-- cmf 26-06-2019
DECLARE
	tbl_triggers table_varchar := table_varchar(
			'B_UI_AUDIT_QUEST_ANSWER',
			'B_UI_AUDIT_REQ',
			'B_UI_AUDIT_REQ_COMMENT',
			'B_UI_AUDIT_REQ_PROF',
			'B_UI_AUDIT_REQ_PROF_EPIS',
			'B_UI_AUDIT_TYPE_TRIAGE_TYPE',
			'B_IU_VS_CLIN_SERV',
			'B_IU_TRIAGE_DISC_VS_VALID',
			'B_IU_TRIAGE_BOARD_GROUPING',
			'B_IU_TRIAGE',
			'B_IU_SYS_MESSAGE',
			'B_IU_SYS_DOMAIN',
			'B_IU_SR_SURG_TIM_DET',
			'B_IU_SR_SURGERY_RECORD',
			'B_IU_SR_PROF_TEAM_DET',
			'B_IU_SR_INTERV_DPCLIN_SERV',
			'B_IU_SR_INTERV_DESC',
			'B_IU_SR_EQUIP_PERIOD',
			'B_IU_SR_EQUIP_KIL',
			'B_IU_REP_SECTION_DET',
			'B_IU_REP_SCREEN',
			'B_IU_REP_PROF_TEMPLATE',
			'B_IU_REP_PROF_EXCEPTION',
			'B_IU_REP_PROFILE_TEMPLATE_DET',
			'B_IU_REP_PROFILE_TEMPLATE',
			'B_IU_PROTOC_DIAG',
			'B_IU_PROF_TEAM_DET',
			'B_IU_PROF_TEAM',
			'B_IU_PROFESSIONAL',
			'B_IU_PAT_CLI_ATTRIBUTES',
			'B_IU_MANCHESTER',
			'B_IU_INTERV_PROTOCOLS',
			'B_IU_INTERV_PREP_MSG',
			'B_IU_INTERV_DEP_CLIN_SERV',
			'B_IU_HEMO_REQ_SUPPLY',
			'B_IU_HEMO_REQ',
			'B_IU_DOC_AREA_INST_SOFT_PROF',
			'B_IU_SUMMARY_PAGE_ACCESS',
			'B_IU_EXAM_TYPE',
			'B_IU_DOC_AREA_INST_SOFT',
			'B_IU_EXAM_PROTOCOLS',
			'B_IU_EXAM_PREP_MESG',
			'B_IU_EXAM_DRUG',
			'B_IU_EXAM_DEP_CLIN_SERV',
			'B_IU_EQUIP_PROTOCOLS',
			'B_IU_EPIS_REPORT_SECTION',
			'B_IU_EPIS_REPORT',
			'B_IU_EPIS_PROTOCOLS',
			'B_IU_EPIS_DIAGRAM_LAYOUT',
			'B_IU_EPIS_DIAGRAM_DETAIL_NOTES',
			'B_IU_EPIS_DIAGRAM_DETAIL',
			'B_IU_EPIS_DIAGRAM',
			'B_IU_DRUG_PROTOCOLS',
			'B_IU_DISC_VS_VALID',
			'B_IU_DIAG_LAY_DEP_CLIN_SERV',
			'B_IU_DIAGRAM_LAY_IMAG',
			'B_IU_DIAGNOSIS_DEP_CLIN_SERV',
			'B_IU_DEP_CLIN_SERV',
			'B_IU_BOARD_GROUPING',
			'B_IU_ANALYSIS_PROTOCOLS',
			'B_IU_ANALYSIS_PARAM_INSTIT',
			'B_IU_ANALYSIS_PARAM',
			'B_IU_ANALYSIS_DEP_CLIN_SERV',
			'B_IU_ADVERSE_INTERV_ALLERGY',
			'B_IU_ADVERSE_EXAM_ALLERGY',
			'BIU_SR_PRE_EVAL_DET',
			'B_IU_HCN_DEF_CRIT',
			'B_IU_HCN_DEF_POINTS',
			'B_IU_INST_ATTRIBUTES',
			'B_IU_CHILD_FEED_DEV_INST',
			'B_IU_ANALYSIS_PARAM_FUNC',
			'B_IU_EPIS_CO_SIGNER',
			'B_IU_COUNTRY_CURRENCY',
			'B_IU_EVAL_MNG',
			'B_IU_CPT_CODE',
			'B_IU_ALLERGY_INST_SOFT',
			'B_IU_INTERV_CATEGORY',
			'B_IU_INTERV_INT_CAT',
			'B_IU_SYS_CONFIG_TRANSLATION',
			'B_IU_DEP_CLIN_SERV_PERM',
			'B_IU_DRUG_DEP_CLIN_SERV',
			'B_IU_ANALYSIS_INSTIT_SOFT'
			);

BEGIN

	FOR I IN 1..TBL_TRIGGERS.COUNT LOOP
	
		DECLARE
			L_SQL VARCHAR2(4000);
		BEGIN

		L_SQL := 'DROP TRIGGER ALERT.'||TBL_TRIGGERS(I);
		PK_VERSIONING.RUN( l_sql );
		
		EXCEPTION
			WHEN OTHERS THEN
				DBMS_OUTPUT.PUT_LINE( SQLERRM );
		END;
	
	END LOOP;

END;
/