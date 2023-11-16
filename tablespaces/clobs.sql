-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 27/10/2009 16:39
-- CHANGE REASON: Case Manager
alter table EPIS_ENCOUNTER move lob(notes) store as ( tablespace ALERT_LOB );
alter table MANAGEMENT_PLAN move lob(ADMISSION_NOTES,IMMEDIATE_NEEDS,GOALS,PLAN) store as ( tablespace ALERT_LOB );
alter table MANAGEMENT_FOLLOW_UP move lob(notes) store as ( tablespace ALERT_LOB );
-- CHANGE END: Elisabete Bugalho

-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 27/10/2009 16:42
-- CHANGE REASON: Case Manager
alter table EPIS_ENCOUNTER move lob(notes) store as ( tablespace ALERT_LOB );
alter table MANAGEMENT_PLAN move lob(ADMISSION_NOTES,IMMEDIATE_NEEDS,GOALS,PLAN) store as ( tablespace ALERT_LOB );
alter table MANAGEMENT_FOLLOW_UP move lob(notes) store as ( tablespace ALERT_LOB );
-- CHANGE END: Elisabete Bugalho

-- CHANGED BY:  Álvaro Vasconcelos
-- CHANGE DATE: 19/03/2010 17:39
-- CHANGE REASON: [ALERT-1215] [CRISIS_MACHINE] - Crisis Machine OUTP, PP e CARE Revision
alter table crisis_xml move lob(XML_VALUE) store as ( tablespace ALERT_LOB );
-- CHANGE END:  Álvaro Vasconcelos

-- CHANGED BY: orlando.antunes
-- CHANGE DATE: 22/03/2010 16:26
-- CHANGE REASON: [ALERT-69945] 
alter table CANCEL_INFO_DET move lob(notes_cancel_long) store as ( tablespace ALERT_LOB );
-- CHANGE END: orlando.antunes

-- CHANGED BY: Jorge Canossa
-- CHANGE DATE: 12/07/2010 18:58
-- CHANGE REASON: [ALERT-100943] 
alter table REP_LAYOUT_SECTION move lob(LAYOUT_SAMPLE) store as ( tablespace ALERT_LOB );
-- CHANGE END: Jorge Canossa

-- CHANGED BY: orlando.antunes
-- CHANGE DATE: 12/01/2011 09:54
-- CHANGE REASON: [ALERT-154804] 
ALTER TABLE pat_cit MOVE LOB(accident_cause) STORE AS (tablespace ALERT_LOB);
ALTER TABLE pat_cit_hist MOVE LOB(accident_cause) STORE AS (tablespace ALERT_LOB);
-- CHANGE END: orlando.antunes

-- CHANGED BY:  carlos.guilherme
-- CHANGE DATE: 04/02/2011 16:20
-- CHANGE REASON: [ALERT-126939] 
alter table epis_report move lob(TEMPORARY_SIGNED_BINARY_FILE) store as ( tablespace ALERT_LOB );
alter table epis_report move lob(REP_BINARY_FILE) store as ( tablespace ALERT_LOB );
alter table epis_report move lob(SIGNED_BINARY_FILE) store as ( tablespace ALERT_LOB );
alter table epis_report move lob(epis_report_thumbnail) store as ( tablespace ALERT_LOB );
alter table doc_image move lob(DOC_IMG) store as ( tablespace ALERT_LOB );
alter table doc_image move lob(DOC_IMG_THUMBNAIL) store as ( tablespace ALERT_LOB );
-- CHANGE END:  carlos.guilherme

-- CHANGED BY:  Álvaro Vasconcelos
-- CHANGE DATE: 23/02/2011 08:27
-- CHANGE REASON: [ALERT-158645] Release Notes DDL
alter table TRANSLATION_LOB move lob(desc_lang_1) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_2) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_3) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_4) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_5) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_6) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_7) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_8) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_9) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_10) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_11) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_12) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_13) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_14) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_15) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_16) store as ( tablespace ALERT_LOB );
alter table TRANSLATION_LOB move lob(desc_lang_17) store as ( tablespace ALERT_LOB );
-- CHANGE END:  Álvaro Vasconcelos

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 27/01/2011 11:50
-- CHANGE REASON: [ALERT_129745] 
alter table EPIS_PN_SIGNOFF move lob(PN_SIGNOFF_NOTE) store as ( tablespace ALERT_LOB );
alter table EPIS_PN_SIGNOFF_HIST move lob(PN_SIGNOFF_NOTE) store as ( tablespace ALERT_LOB );

alter table EPIS_PN_ADDENDUM move lob(PN_ADDENDUM) store as ( tablespace ALERT_LOB );
alter table EPIS_PN_ADDENDUM_HIST move lob(PN_ADDENDUM) store as ( tablespace ALERT_LOB );

alter table EPIS_PN_DET move lob(PN_NOTE) store as ( tablespace ALERT_LOB );
alter table EPIS_PN_DET_HIST move lob(PN_NOTE) store as ( tablespace ALERT_LOB );

alter table EPIS_PN_DET_TEMPL move lob(PN_NOTE) store as (tablespace ALERT_LOB );
alter table EPIS_PN_DET_TEMPL_HIST move lob(PN_NOTE) store as (tablespace ALERT_LOB );

alter table EPIS_PN_DET_WORK move lob(PN_NOTE) store as (tablespace ALERT_LOB );
alter table EPIS_PN_DET_TEMPL_WORK move lob(PN_NOTE) store as (tablespace ALERT_LOB );
-- CHANGE END: Rui Spratley




-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 07/04/2011 14:38
-- CHANGE REASON: [ALERT-171724] Trials
ALTER TABLE trial_hist MOVE LOB(notes) STORE AS (tablespace ALERT_LOB);
ALTER TABLE trial MOVE LOB(notes) STORE AS (tablespace ALERT_LOB);
ALTER TABLE PAT_TRIAL_FOLLOW_UP MOVE LOB(notes) STORE AS (tablespace ALERT_LOB);
ALTER TABLE PAT_TRIAL_FOLLOW_UP_HIST MOVE LOB(notes) STORE AS (tablespace ALERT_LOB);
-- CHANGE END: Elisabete Bugalho

-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 06/05/2011 11:27
-- CHANGE REASON: [ALERT-176644] cdr data model (changes_ddl.sql)
alter table cdr_event move lob(notes_answer) store as (tablespace alert_lob);
alter table cdr_inst_par_action move lob(message) store as (tablespace alert_lob);
alter table cdr_param_action move lob(message) store as (tablespace alert_lob);
-- CHANGE END: Pedro Carneiro

-- CHANGED BY: António Neto
-- CHANGE DATE: 02/01/2012
-- CHANGE REASON: [ALERT-211833] Fix findings - Solve findings identified by Technical Arq. BD

begin
execute immediate ('Alter table EPIS_PN_DET_TASK_WORK move lob(PN_NOTE) store as ( tablespace ALERT_LOB)');
exception
when others then
null;
end;
/

begin
execute immediate ('Alter table EPIS_PN_DET_TASK move lob(PN_NOTE) store as ( tablespace ALERT_LOB)');
exception
when others then
null;
end;
/
--CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 04/01/2012 16:15
-- CHANGE REASON: [ALERT-212044] Fix findings - Solve findings identified by Technical Arq. BD for H&P v.1
begin
execute immediate ('Alter table EPIS_PN_DET_WORK move lob(PN_NOTE) store as ( tablespace ALERT_LOB)');
exception
when others then
null;
end;
/
-- CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 04/01/2012 16:15
-- CHANGE REASON: [ALERT-212044] Fix findings - Solve findings identified by Technical Arq. BD for H&P v.1
begin
execute immediate ('Alter table EPIS_PN_DET_HIST move lob(PN_NOTE) store as ( tablespace ALERT_LOB)');
exception
when others then
null;
end;
/
-- CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 04/01/2012 16:15
-- CHANGE REASON: [ALERT-212044] Fix findings - Solve findings identified by Technical Arq. BD for H&P v.1
begin
execute immediate ('Alter table EPIS_PN_ADDENDUM_HIST move lob(PN_ADDENDUM) store as ( tablespace ALERT_LOB)');
exception
when others then
null;
end;
/
-- CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 04/01/2012 16:15
-- CHANGE REASON: [ALERT-212044] Fix findings - Solve findings identified by Technical Arq. BD for H&P v.1
begin
execute immediate ('Alter table EPIS_PN_ADDENDUM move lob(PN_ADDENDUM) store as ( tablespace ALERT_LOB)');
exception
when others then
null;
end;
/
-- CHANGE END: António Neto

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 03/04/2012 11:06
-- CHANGE REASON: [ALERT-221292] 
alter table discharge_detail_hist move lob(sched_notes) store as ( tablespace ALERT_LOB );
alter table discharge_detail move lob(sched_notes) store as ( tablespace ALERT_LOB );
alter table discharge_detail_hist move lob(reason_for_visit_fw) store as ( tablespace ALERT_LOB );
alter table discharge_detail move lob(reason_for_visit_fw) store as ( tablespace ALERT_LOB );
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 05/09/2012 14:28
-- CHANGE REASON: [ALERT-239422] 
alter table group_note move lob(notes) store as ( tablespace ALERT_LOB );
alter table group_note_hist move lob(notes) store as ( tablespace ALERT_LOB );
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Jorge Silva
-- CHANGE DATE: 27/12/2012 10:55
-- CHANGE REASON: [ALERT-247816] 
alter table PAT_CIT_HIST move lob(notes_desc) store as ( tablespace ALERT_LOB );
alter table PAT_CIT move lob(notes_desc) store as ( tablespace ALERT_LOB );
-- CHANGE END: Jorge Silva

-- CHANGED BY: mario.mineiro
-- CHANGE DATE: 26/08/2013 14:52
-- CHANGE REASON: [ALERT-263008] 
alter table PO_PARAM_REG move lob (NOTES_CANCEL) store as (tablespace alert_lob);
-- CHANGE END: mario.mineiro

-- CHANGED BY: mario.mineiro
-- CHANGE DATE: 26/08/2013 14:52
-- CHANGE REASON: [ALERT-263008] 
alter table po_param_reg move lob(free_text) store as ( tablespace ALERT_LOB );DECLARE
    l_ret    BOOLEAN;
    l_trg    VARCHAR2(32000);
    l_tables table_varchar;

    CURSOR c_tables IS
        SELECT ut.table_name
          FROM user_tables ut
         WHERE ut.table_name IN ('PO_PARAM_UM',
                                 'PO_PARAM_REG_MC',
                                 'PO_PARAM_REG',
                                 'PO_PARAM_RANK',
                                 'PO_PARAM_MC',
                                 'PO_PARAM_HPG',
                                 'PO_PARAM_CS',
                                 'PO_PARAM_ALIAS',
                                 'PO_PARAM',
                                 'PREG_PO_PARAM',																 
                                 'PAT_PO_PARAM');
BEGIN
    OPEN c_tables;
    FETCH c_tables BULK COLLECT
        INTO l_tables;
    CLOSE c_tables;

    FOR i IN 1 .. l_tables.count
    LOOP
        l_ret := pk_dev.create_audit_trigger(i_table => l_tables(i), i_owner => 'ALERT', o_trigger => l_trg);
    END LOOP;
END;
/
-- CHANGE END: mario.mineiro

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 02/12/2013 09:32
-- CHANGE REASON: [ALERT-270040] 
alter table VS_READ_ATTRIBUTE move lob(free_text) store as ( tablespace ALERT_LOB );
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 02/12/2013 09:32
-- CHANGE REASON: [ALERT-270040] 
alter table VS_READ_HIST_ATTRIBUTE move lob(free_text) store as ( tablespace ALERT_LOB );
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 18/02/2014 11:51
-- CHANGE REASON: [ALERT-275609] 
alter table vital_sign_read_hist move lob(notes_edit) store as ( tablespace ALERT_LOB );
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 17/04/2014 11:22
-- CHANGE REASON: [ALERT-275664] 
alter table COMM_ORDER_REQ_HIST move lob(notes) store as ( tablespace ALERT_LOB );
alter table COMM_ORDER_REQ_HIST move lob(prn_condition) store as ( tablespace ALERT_LOB );
alter table COMM_ORDER_REQ_HIST move lob(clinical_indication) store as ( tablespace ALERT_LOB );
alter table COMM_ORDER_REQ_HIST move lob(notes_co_sign) store as ( tablespace ALERT_LOB );
alter table COMM_ORDER_REQ_HIST move lob(notes_cancel) store as ( tablespace ALERT_LOB );
alter table COMM_ORDER_REQ_HIST move lob(desc_concept_term) store as ( tablespace ALERT_LOB );

alter table COMM_ORDER_instr_def_msi move lob(notes) store as ( tablespace ALERT_LOB );
alter table COMM_ORDER_instr_def_msi move lob(prn_condition) store as ( tablespace ALERT_LOB );
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 21/05/2014 15:21
-- CHANGE REASON: [ALERT-285475] 
ALTER TABLE ANALYSIS_RESULT_PAR MOVE LOB(DESC_ANALYSIS_RESULT) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE ANALYSIS_RESULT_PAR MOVE LOB(INTERFACE_NOTES) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE ANALYSIS_RESULT_PAR MOVE LOB(NOTES_DOCTOR_REGISTRY) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE ANALYSIS_RESULT_PAR MOVE LOB(PARAMETER_NOTES) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE ANALYSIS_RESULT_PAR MOVE LOB(VALUE) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE ANALYSIS_RESULT_PAR_HIST MOVE LOB(DESC_ANALYSIS_RESULT) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE ANALYSIS_RESULT_PAR_HIST MOVE LOB(INTERFACE_NOTES) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE ANALYSIS_RESULT_PAR_HIST MOVE LOB(NOTES_DOCTOR_REGISTRY) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE ANALYSIS_RESULT_PAR_HIST MOVE LOB(PARAMETER_NOTES) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE ANALYSIS_RESULT_PAR_HIST MOVE LOB(VALUE) STORE AS (TABLESPACE ALERT_LOB);
-- CHANGE END: Ana Matos

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 17/10/2014 13:36
-- CHANGE REASON: [ALERT-298852] 
alter table PRINT_LIST_JOB move lob(CONTEXT_DATA) store as ( tablespace ALERT_LOB);
alter table PRINT_LIST_JOB_HIST move lob(CONTEXT_DATA) store as ( tablespace ALERT_LOB);
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 11/05/2016 16:18
-- CHANGE REASON: [ALERT-320555] Move indexes table space: ALERT_DATA to ALERT_LOB
 ALTER TABLE CO_SIGN_HIST MOVE LOB (CO_SIGN_NOTES) STORE AS (TABLESPACE ALERT_LOB);
 ALTER TABLE EPIS_DIAG_NOTES_HIST MOVE LOB (NOTES) STORE AS (TABLESPACE ALERT_LOB);
-- CHANGE END: Elisabete Bugalho

-- CHANGED BY: Lillian Lu
-- CHANGE DATE: 19/12/2017
-- CHANGE REASON: [CALER-10] 
ALTER TABLE EPIS_PROB_GROUP MOVE LOB(assessment_note) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE EPIS_PROB_GROUP MOVE LOB(plan_note) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE EPIS_PROB_GROUP MOVE LOB(dteg_note) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE EPIS_PROB_GROUP_HIST MOVE LOB(assessment_note) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE EPIS_PROB_GROUP_HIST MOVE LOB(plan_note) STORE AS (TABLESPACE ALERT_LOB);
ALTER TABLE EPIS_PROB_GROUP_HIST MOVE LOB(dteg_note) STORE AS (TABLESPACE ALERT_LOB);
-- CHANGE END: Lillian Lu


-- CHANGED BY: Alexander Camilo
-- CHANGE DATE: 20/04/2018 09:48
-- CHANGE REASON: [EMR-2257] EMR-2257, Import data into cat_clues (Drop table, Create table, Import data)
ALTER TABLE CAT_CLUES MOVE LOB(AREAS_Y_SERVICIOS) STORE AS (TABLESPACE ALERT_LOB);
-- CHANGE END: Alexander Camilo