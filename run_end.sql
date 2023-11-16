-- CHANGED BY: Nuno Guerreiro
-- CHANGE REASON: Removed temporary columns that were used to fix column precision.
-- CHANGE DATE: 2007/08/14
UPDATE SCH_ANALYSIS_DCS SET ID_ANALYSIS = ID_ANALYSIS_AUX;
ALTER TABLE SCH_ANALYSIS_DCS MODIFY ID_ANALYSIS NOT NULL;
ALTER TABLE SCH_ANALYSIS_DCS DROP COLUMN ID_ANALYSIS_AUX;

UPDATE SCH_COLOR SET ID_INSTITUTION = ID_INSTITUTION_AUX;
ALTER TABLE SCH_COLOR MODIFY ID_INSTITUTION NOT NULL;
ALTER TABLE SCH_COLOR DROP COLUMN ID_INSTITUTION_AUX;

UPDATE SCH_CONSULT_VAC_ANALYSIS SET ID_ANALYSIS = ID_ANALYSIS_AUX;
ALTER TABLE SCH_CONSULT_VAC_ANALYSIS MODIFY ID_ANALYSIS NOT NULL;
ALTER TABLE SCH_CONSULT_VAC_ANALYSIS DROP COLUMN ID_ANALYSIS_AUX;

UPDATE SCH_CONSULT_VAC_EXAM SET ID_EXAM = ID_EXAM_AUX;
ALTER TABLE SCH_CONSULT_VAC_EXAM MODIFY ID_EXAM NOT NULL;
ALTER TABLE SCH_CONSULT_VAC_EXAM DROP COLUMN ID_EXAM_AUX;

UPDATE SCH_DEFAULT_CONSULT_VACANCY SET ID_ANALYSIS = ID_ANALYSIS_AUX;
ALTER TABLE SCH_DEFAULT_CONSULT_VACANCY DROP COLUMN ID_ANALYSIS_AUX;
UPDATE SCH_DEFAULT_CONSULT_VACANCY SET ID_EXAM = ID_EXAM_AUX;
ALTER TABLE SCH_DEFAULT_CONSULT_VACANCY DROP COLUMN ID_EXAM_AUX;

UPDATE SCHEDULE_ANALYSIS SET ID_ANALYSIS = ID_ANALYSIS_AUX;
ALTER TABLE SCHEDULE_ANALYSIS DROP COLUMN ID_ANALYSIS_AUX;

UPDATE SCHEDULE_EXAM SET ID_EXAM = ID_EXAM_AUX;
ALTER TABLE SCHEDULE_EXAM DROP COLUMN ID_EXAM_AUX;

UPDATE SCHEDULE_OUTP SET ID_EPIS_TYPE = ID_EPIS_TYPE_AUX;
ALTER TABLE SCHEDULE_OUTP MODIFY ID_EPIS_TYPE NOT NULL;
ALTER TABLE SCHEDULE_OUTP DROP COLUMN ID_EPIS_TYPE_AUX;

UPDATE SCH_EVENT SET ID_SOFTWARE = ID_SOFTWARE_AUX;
ALTER TABLE SCH_EVENT MODIFY ID_SOFTWARE NOT NULL;
ALTER TABLE SCH_EVENT DROP COLUMN ID_SOFTWARE_AUX;

UPDATE SCH_EXAM_DCS SET ID_EXAM = ID_EXAM_AUX;
ALTER TABLE SCH_EXAM_DCS MODIFY ID_EXAM NOT NULL;
ALTER TABLE SCH_EXAM_DCS DROP COLUMN ID_EXAM_AUX;

UPDATE SCH_SCHEDULE_REQUEST SET ID_EPIS_TYPE = ID_EPIS_TYPE_AUX;
ALTER TABLE SCH_SCHEDULE_REQUEST DROP COLUMN ID_EPIS_TYPE_AUX;

UPDATE SCH_VACANCY_USAGE SET ID_INSTITUTION = ID_INSTITUTION_AUX;
ALTER TABLE SCH_VACANCY_USAGE MODIFY ID_INSTITUTION NOT NULL;
ALTER TABLE SCH_VACANCY_USAGE DROP COLUMN ID_INSTITUTION_AUX;
-- CHANGE END

-- CHANGED BY: Rui Spratley
-- CHANGE REASON: Timezone
-- CHANGE DATE: 2007/08/17
alter table harvest modify dt_harvest_tstz not null enable;
alter table analysis_req modify dt_req_tstz not null enable;
alter table analysis_result modify dt_analysis_result_tstz not null enable;
alter table analysis_result_par modify dt_analysis_result_par_tstz not null enable;
alter table analysis_result_par_hist modify dt_analysis_result_par_tstz not null enable;
alter table analysis_req_temp modify dt_result_tstz not null enable;
-- CHANGE END


-- CHANGED BY: Rui Spratley
-- CHANGE REASON: Timezone - Refazer todos os indices
-- CHANGE DATE: 2007/09/11
drop index ALERT.ETRG_ID_EP_DT_BG_ID_TCOL_IDX;
create index ALERT.ETRG_ID_EP_DT_BG_ID_TCOL_IDX on ALERT.EPIS_TRIAGE(ID_EPISODE, DT_BEGIN_TSTZ, ID_TRIAGE_COLOR) tablespace TABLE_M;                 
drop index ALERT.ETRG_DTEND_FK_I;                                               
create index ALERT.ETRG_DTEND_FK_I on ALERT.EPIS_TRIAGE( DT_END_TSTZ) tablespace TABLE_M;                                                                        
drop index ALERT.DIS_DT_MED_IDX;                                                
create index ALERT.DIS_DT_MED_IDX on ALERT.DISCHARGE( DT_MED_TSTZ) tablespace INDEX_M;                                                                        
drop index ALERT.DIS_DT_ADMIN_IDX;                                              
create index ALERT.DIS_DT_ADMIN_IDX on ALERT.DISCHARGE( DT_ADMIN_TSTZ) tablespace INDEX_M;                                                             
drop index ALERT.ART_FLG_TIME_I;                                                
create index ALERT.ART_FLG_TIME_I on ALERT.ANALYSIS_REQ( FLG_TIME, DT_REQ_TSTZ, ID_ANALYSIS_REQ, ID_EPISODE) tablespace INDEX_M;                                
drop index ALERT.HARV_FLG_STATUS_DT_I;                                          
create index ALERT.HARV_FLG_STATUS_DT_I on ALERT.HARVEST( ID_HARVEST, FLG_STATUS, DT_HARVEST_TSTZ) tablespace INDEX_L;                                
drop index ALERT.SR_SCHED_DTARGET_I;                                            
create index ALERT.SR_SCHED_DTARGET_I on ALERT.SCHEDULE_SR( DT_TARGET_TSTZ, ID_INSTITUTION, FLG_STATUS) tablespace INDEX_M;                                 
--drop index ALERT.SSE_II;                                                        
--create index ALERT.SSE_II on ALERT.SCH_CONSULT_VACANCY( DT_BEGIN_TSTZ, ID_INSTITUTION, ID_PROF) tablespace INDEX_M;                                    
--drop index ALERT.SSE_I;                                                         
--create index ALERT.SSE_I on ALERT.SCH_CONSULT_VACANCY( DT_BEGIN_TSTZ, ID_INSTITUTION) tablespace INDEX_M;                                             
--drop index ALERT.SDCV_DT_INST_DCS_I;                                            
--create index ALERT.SDCV_DT_INST_DCS_I on ALERT.SCH_DEFAULT_CONSULT_VACANCY(ID_INSTITUTION, DT_BEGIN_TSTZ) tablespace INDEX_M;                              
drop index ALERT.IPP_STATUS_DT_PLAN_I;                                          
create index ALERT.IPP_STATUS_DT_PLAN_I on ALERT.INTERV_PRESC_PLAN( FLG_STATUS, DT_PLAN_TSTZ, ID_INTERV_PRESC_DET) tablespace INDEX_M;                          
drop index ALERT.MVS_STATUS_DT_I;                                               
create index ALERT.MVS_STATUS_DT_I on ALERT.MONITORIZATION_VS( FLG_STATUS, DT_MONITORIZATION_VS_TSTZ) tablespace INDEX_M;                                  
--drop index ALERT.SMRA_DTBEGIN_I;                                                
--create index ALERT.SMRA_DTBEGIN_I on ALERT.SCH_MULT_RESCHEDULE_AUX(DT_BEGIN_TSTZ) ;                                                     
drop index ALERT.MOV_STATUS_I;                                                  
create index ALERT.MOV_STATUS_I on ALERT.MOVEMENT( FLG_STATUS, DT_REQ_TSTZ) tablespace INDEX_L;                                                             
drop index ALERT.NDE_DT_IDX;                                                    
create index ALERT.NDE_DT_IDX on ALERT.NURSE_DISCHARGE( DT_NURSE_DISCHARGE_TSTZ) tablespace INDEX_M;                                                             
drop index ALERT.OPN_FLG_STATE_I;                                               
create index ALERT.OPN_FLG_STATE_I on ALERT.OPINION( FLG_STATE, ID_PROF_QUESTIONS, ID_EPISODE, ID_OPINION, DT_PROBLEM_TSTZ) tablespace INDEX_M; 
drop index ALERT.ERT_DT_TRACKING;                                               
create index ALERT.ERT_DT_TRACKING on ALERT.P1_TRACKING( DT_TRACKING_TSTZ) tablespace INDEX_L;                                                             
-- CHANGE END


-- CHANGED BY: Rui Spratley
-- CHANGE REASON: Apagar a função temporária
-- CHANGE DATE: 2007/09/11
drop FUNCTION convert_grid_task;
-- CHANGE END

-- CHANGED BY: João Sá
-- CHANGE REASON: Colunas obrigatórias
-- CHANGE DATE: 2007/09/12
alter table P1_EXTERNAL_REQUEST modify DT_STATUS_TSTZ not null;

alter table P1_TRACKING modify DT_TRACKING not null;
alter table P1_TRACKING modify DT_TRACKING_TSTZ not null;

alter table P1_DETAIL modify DT_INSERT not null;
alter table P1_DETAIL modify DT_INSERT_TSTZ not null;
 
alter table PAT_REFERRAL modify REF_DATE_TSTZ not null;
alter table PAT_REFERRAL modify DT_STATUS_TSTZ not null;

alter table P1_EXR_DIAGNOSIS modify DT_INSERT not null;
alter table P1_EXR_DIAGNOSIS modify DT_INSERT_TSTZ not null;

alter table P1_EXR_SAMPLE_TEXT modify DT_INSERT not null;
alter table P1_EXR_SAMPLE_TEXT modify DT_INSERT_TSTZ not null;

alter table P1_MATCH modify DT_CREATE not null;
alter table P1_MATCH modify DT_CREATE_TSTZ not null;

alter table P1_TASK_DONE modify DT_INSERTED not null;
alter table P1_TASK_DONE modify DT_INSERTED_TSTZ not null;
-- CHANGE END

-- CHANGED BY: Rui de Sousa Neves
-- CHANGE REASON: Increment sequence to differ from the pat_problem ID
-- CHANGE DATE: 2007/09/24

ALTER SEQUENCE seq_pat_history_diagnosis INCREMENT BY 100000;
select seq_pat_history_diagnosis.nextval from dual;
ALTER SEQUENCE seq_pat_history_diagnosis INCREMENT BY 1;

-- CHANGE END




-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-OCT-15
-- CHANGE REASON: columns EMB_ID and VIAS_ADMIN_ID modify from NUMBER to VARCHAR2

alter table prescription_pharm 
drop constraint ppn_ieb_fk;

alter table prescription_pharm 
drop constraint ppn_iva_fk;

create table prescription_pharm_bck as select * from prescription_pharm;

alter table prescription_pharm rename column emb_id to emb_id2;
alter table prescription_pharm rename column vias_admin_id to vias_admin_id2;

alter table prescription_pharm
add (emb_id varchar2(11),
     vias_admin_id varchar2(3)); 

update prescription_pharm
set emb_id = to_char(emb_id2), vias_admin_id = to_char(vias_admin_id2);

alter table prescription_pharm drop (emb_id2, vias_admin_id2);

COMMENT ON COLUMN prescription_pharm.emb_id IS 'ID da embalagem.' ;
COMMENT ON COLUMN prescription_pharm.vias_admin_id IS 'ID da via de administração.' ;

create index PPN_IEB_FK_I on PRESCRIPTION_PHARM (EMB_ID) tablespace INDEX_M;   
create index PPN_IVA_FK_I on PRESCRIPTION_PHARM (VIAS_ADMIN_ID) tablespace INDEX_S;   

-- CHANGE END


-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-OCT-15
-- CHANGE REASON: column EMB_ID modified from NUMBER to VARCHAR2

alter table pat_medication_list 
drop constraint pml_ieb_fk;

alter table pat_medication_list 
drop constraint pml_imd_fk;

create table pat_medication_list_bck as select * from pat_medication_list;

alter table pat_medication_list rename column emb_id to emb_id2;

alter table pat_medication_list
add (emb_id varchar2(11)); 

update pat_medication_list
set emb_id = to_char(emb_id2);

alter table pat_medication_list drop (emb_id2);

COMMENT ON COLUMN pat_medication_list.emb_id IS 'ID da embalagem.' ;

create index PML_IEB_FK_I on pat_medication_list (EMB_ID) tablespace INDEX_M;   



alter table pat_medication_hist_list 
drop constraint pmhl_ieb_fk;

alter table pat_medication_hist_list 
drop constraint pmhl_imd_fk;

create table pat_medication_hist_list_bck as select * from pat_medication_hist_list;

alter table pat_medication_hist_list rename column emb_id to emb_id2;

alter table pat_medication_hist_list
add (emb_id varchar2(11)); 

update pat_medication_hist_list
set emb_id = to_char(emb_id2);

alter table pat_medication_hist_list drop (emb_id2);

COMMENT ON COLUMN pat_medication_hist_list.emb_id IS 'ID da embalagem.' ;

create index PMHL_IEB_FK_I on pat_medication_hist_list (EMB_ID) tablespace INDEX_M;   
   
-- CHANGE END

-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-OCT-18
-- CHANGE REASON: constraint dropped
alter table EMB_DEP_CLIN_SERV drop constraint EDV_IEB_FK;
-- CHANGE END



-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-OCT-18
-- CHANGE REASON: column EMB_ID modified from NUMBER to VARCHAR2
create table emb_dep_clin_serv_bck as select * from emb_dep_clin_serv;

alter table emb_dep_clin_serv rename column emb_id to emb_id2;

alter table emb_dep_clin_serv
add (emb_id varchar2(11)); 

update emb_dep_clin_serv
set emb_id = to_char(emb_id2);

alter table emb_dep_clin_serv drop (emb_id2);

COMMENT ON COLUMN emb_dep_clin_serv.emb_id IS 'ID da embalagem.' ;

create index EDV_IEB_FK_I on emb_dep_clin_serv (EMB_ID) tablespace INDEX_M;   
-- CHANGE END

--João Eiras, 26-10-2007
--Actualizar códigos para a translation
UPDATE software SET code_software = 'SOFTWARE.CODE_SOFTWARE.'||id_software,code_icon = 'SOFTWARE.CODE_ICON.'||id_software;






-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-OCT-26
-- CHANGE REASON: columns modified from NUMBER to VARCHAR2

alter table prescription_pharm 
drop constraint PPN_IDA_FK;

alter table prescription_pharm rename column diploma_id to diploma_id2;

alter table prescription_pharm
add (diploma_id varchar2(11)); 

update prescription_pharm
set diploma_id = to_char(diploma_id2);

alter table prescription_pharm drop (diploma_id2);

COMMENT ON COLUMN prescription_pharm.emb_id IS 'ID do diploma.' ;

create index PPN_IDA_FK_I on PRESCRIPTION_PHARM (diploma_id) tablespace INDEX_S;  


create table drug_presc_det_bck as select * from drug_presc_det;

alter table DRUG_PRESC_DET drop constraint DPDT_DRUG_FK;

alter table DRUG_PRESC_DET rename column id_drug to id_drug2;

alter table DRUG_PRESC_DET
add (id_drug varchar2(11)); 

update DRUG_PRESC_DET
set id_drug = to_char(id_drug2);

alter table DRUG_PRESC_DET drop (id_drug2);

COMMENT ON COLUMN DRUG_PRESC_DET.id_drug IS 'ID do medicamento.' ;

create index DPDT_DRUG_FK_I on DRUG_PRESC_DET (id_drug) tablespace INDEX_M;  
-- CHANGE END


-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-OCT-29
-- CHANGE REASON: new column
ALTER TABLE EMB_DEP_CLIN_SERV 
 ADD (FLG_TYPE VARCHAR2(1));

COMMENT ON COLUMN EMB_DEP_CLIN_SERV.FLG_TYPE IS 'M - mais frequentes; P - pesquisáveis';

UPDATE EMB_DEP_CLIN_SERV
SET FLG_TYPE='M';

ALTER TABLE EMB_DEP_CLIN_SERV add CONSTRAINT flg_type_domain CHECK(FLG_TYPE IN ('P', 'M'));

ALTER TABLE EMB_DEP_CLIN_SERV 
 MODIFY (FLG_TYPE VARCHAR2(1) NOT NULL);
 -- CHANGE END
 

-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-OCT-31
-- CHANGE REASON: columns modified from NUMBER to VARCHAR2
create table drug_req_det_bck as select * from drug_req_det;

alter table DRUG_REQ_DET drop constraint DRDT_DRUG_FK;
alter table DRUG_REQ_DET drop constraint DRDT_DRDP_FK;

alter table DRUG_REQ_DET rename column id_drug to id_drug2;
alter table DRUG_REQ_DET rename column id_drug_despachos to id_drug_despachos2;

alter table DRUG_REQ_DET
add (id_drug varchar2(11),
     id_drug_despachos varchar2(255)); 

update DRUG_REQ_DET
set id_drug = to_char(id_drug2), id_drug_despachos = to_char(id_drug_despachos2);

alter table DRUG_REQ_DET drop (id_drug2, id_drug_despachos2);

COMMENT ON COLUMN DRUG_REQ_DET.id_drug IS 'ID do medicamento.' ;
COMMENT ON COLUMN DRUG_REQ_DET.id_drug_despachos IS 'Despacho associado a esta requisição.';

create index DRDT_DRUG_FK_I on DRUG_REQ_DET (id_drug) tablespace INDEX_M;  

create index DRDT_DRDP_FK_I on DRUG_REQ_DET (ID_DRUG_DESPACHOS) tablespace INDEX_M;

 -- CHANGE END
 
 
 
 -- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-NOV-02
-- CHANGE REASON: column ID_DRUG_JUSTIFICATION modified from NUMBER to VARCHAR2
create table drug_instit_justification_bck as select * from drug_instit_justification;

alter table drug_instit_justification rename column id_drug_justification to id_drug_justification2;

alter table drug_instit_justification
add (id_drug_justification varchar2(24)); 

update drug_instit_justification
set id_drug_justification = to_char(id_drug_justification2);

alter table drug_instit_justification drop (id_drug_justification2);

COMMENT ON COLUMN drug_instit_justification.id_drug_justification IS 'ID da justificação.' ;

create index DIN_DRUG_JUSTIF_I on drug_instit_justification (id_drug_justification) tablespace INDEX_M;   
-- CHANGE END


-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-NOV-02
-- CHANGE REASON: column ID_DRUG_JUSTIFICATION modified from NUMBER to VARCHAR2
alter table DRUG_PRESC_DET drop constraint DPDT_DJN_FK;

alter table DRUG_PRESC_DET rename column id_drug_justification to id_drug_justification2;

alter table DRUG_PRESC_DET
add (id_drug_justification varchar2(11)); 

update DRUG_PRESC_DET
set id_drug_justification = to_char(id_drug_justification2);

alter table DRUG_PRESC_DET drop (id_drug_justification2);

COMMENT ON COLUMN DRUG_PRESC_DET.id_drug_justification IS 'ID do medicamento.' ;

create index DPDT_DJN_FK_I on DRUG_PRESC_DET (id_drug_justification) tablespace INDEX_M;  
-- CHANGE END



-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-NOV-07
-- CHANGE REASON: columns modified from NUMBER to VARCHAR2
alter table DRUG_PRESC_DET drop constraint DPDT_DGRT_FK;

alter table DRUG_PRESC_DET rename column id_drug_route to id_drug_route2;

alter table DRUG_PRESC_DET
add (id_drug_route varchar2(11)); 

update DRUG_PRESC_DET
set id_drug_route = to_char(id_drug_route2);

alter table DRUG_PRESC_DET drop (id_drug_route2);

COMMENT ON COLUMN DRUG_PRESC_DET.id_drug_route IS 'Via de administração.' ;

create index DPDT_DGRT_FK_I on DRUG_PRESC_DET (id_drug_route) tablespace INDEX_M;  


alter table PAT_MEDICATION_LIST drop constraint PML_DRUG_FK;

alter table PAT_MEDICATION_LIST rename column id_drug to id_drug2;
alter table PAT_MEDICATION_LIST rename column med_id to med_id2;

alter table PAT_MEDICATION_LIST
add (id_drug varchar2(11),
med_id varchar2(11)); 

update PAT_MEDICATION_LIST
set id_drug = to_char(id_drug2), med_id = to_char(med_id2);

alter table PAT_MEDICATION_LIST drop (id_drug2);
alter table PAT_MEDICATION_LIST drop (med_id2);

COMMENT ON COLUMN PAT_MEDICATION_LIST.id_drug IS 'ID do medicamento.' ;
COMMENT ON COLUMN PAT_MEDICATION_LIST.med_id IS 'ID do medicamento. Só é preenchido, se não for relatado através do histórico.' ;

create index PML_DRUG_FK_I on PAT_MEDICATION_LIST (id_drug) tablespace INDEX_M;  


alter table PAT_MEDICATION_HIST_LIST drop constraint PMHL_DRUG_FK;

alter table PAT_MEDICATION_HIST_LIST rename column id_drug to id_drug2;
alter table PAT_MEDICATION_HIST_LIST rename column med_id to med_id2;

alter table PAT_MEDICATION_HIST_LIST
add (id_drug varchar2(11),
med_id varchar2(11)); 
 
update PAT_MEDICATION_HIST_LIST
set id_drug = to_char(id_drug2), med_id = to_char(med_id2);

alter table PAT_MEDICATION_HIST_LIST drop (id_drug2);
alter table PAT_MEDICATION_HIST_LIST drop (med_id2);

COMMENT ON COLUMN PAT_MEDICATION_HIST_LIST.id_drug IS 'ID do medicamento.' ;
COMMENT ON COLUMN PAT_MEDICATION_HIST_LIST.med_id IS 'ID do medicamento. Só é preenchido, se não for relatado através do histórico.' ;

create index PMHL_DRUG_FK_I on PAT_MEDICATION_HIST_LIST (id_drug) tablespace INDEX_M;  
create index PMHL_MED_FK_I on PAT_MEDICATION_HIST_LIST (med_id) tablespace INDEX_M;


create table FLUIDS_PRESC_DET_BCK as select * from FLUIDS_PRESC_DET;
alter table FLUIDS_PRESC_DET rename column id_drug to id_drug2;

alter table FLUIDS_PRESC_DET
add (id_drug varchar2(11)); 

update FLUIDS_PRESC_DET
set id_drug = to_char(id_drug2);

alter table FLUIDS_PRESC_DET drop (id_drug2);

COMMENT ON COLUMN FLUIDS_PRESC_DET.id_drug IS 'ID do medicamento.' ;

create index FPD_DRUG_FK_I on FLUIDS_PRESC_DET (id_drug) tablespace INDEX_M;  
-- CHANGE END




-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-NOV-12
-- CHANGE REASON: columns renamed and new columns
alter table DRUG_PRESC_DET drop constraint DPD_RINT_IDR_FK;
alter table DRUG_PRESC_DET drop constraint DPD_JINT_IDJ_FK;

alter table DRUG_PRESC_DET
add (route_id varchar2(11),
id_justification varchar2(11)); 

update DRUG_PRESC_DET
set route_id = id_drug_route, id_justification = id_drug_justification;

alter table DRUG_PRESC_DET drop (id_drug_route, id_drug_justification);

COMMENT ON COLUMN DRUG_PRESC_DET.route_id IS 'Via de administração.' ;
COMMENT ON COLUMN DRUG_PRESC_DET.id_justification IS 'Justificação.' ;

alter table DRUG_PRESC_DET
  add constraint DPD_JINT_IDJ_FK foreign key (ID_JUSTIFICATION, VERS)
  references MI_JUSTIFICATION (ID_JUSTIFICATION, VERS);

alter table DRUG_PRESC_DET
  add constraint DPD_RINT_IDR_FK foreign key (ROUTE_ID, VERS)
  references MI_ROUTE (ROUTE_ID, VERS);
    
create index DPD_JINT_IDJ_FK_I on DRUG_PRESC_DET (route_id) tablespace INDEX_M;  
create index DPD_RINT_IDR_FK_I on DRUG_PRESC_DET (id_justification) tablespace INDEX_M;  



alter table DRUG_REQ_DET drop constraint DRQD_MED_INT_IDD_FK;

alter table DRUG_REQ_DET
add (regulation_id varchar2(11)); 

update DRUG_REQ_DET
set regulation_id = ID_DRUG_DESPACHOS;

alter table DRUG_REQ_DET drop (ID_DRUG_DESPACHOS);

COMMENT ON COLUMN DRUG_REQ_DET.regulation_id IS 'ID do despacho.' ;

alter table DRUG_REQ_DET
  add constraint DRQD_MED_INT_IDD_FK foreign key (REGULATION_ID, VERS)
  references MI_REGULATION (REGULATION_ID, VERS);
  
create index DRQD_MED_INT_IDD_FK_I on DRUG_REQ_DET (REGULATION_ID) tablespace INDEX_M;  




alter table PRESCRIPTION_PHARM drop constraint PP_PH_RI_FK;
alter table PRESCRIPTION_PHARM drop constraint PP_PR_DI_FK;

alter table PRESCRIPTION_PHARM
add (route_id varchar2(11),
regulation_id varchar2(11)); 

update PRESCRIPTION_PHARM
set route_id = vias_admin_id, regulation_id = diploma_id;

alter table PRESCRIPTION_PHARM drop (vias_admin_id, diploma_id);

COMMENT ON COLUMN PRESCRIPTION_PHARM.route_id IS 'Via de administração.' ;
COMMENT ON COLUMN PRESCRIPTION_PHARM.regulation_id IS 'Justificação.' ;

alter table PRESCRIPTION_PHARM
  add constraint PP_PH_RI_FK foreign key (ROUTE_ID, VERS)
  references ME_ROUTE (ROUTE_ID, VERS);

alter table PRESCRIPTION_PHARM
  add constraint PP_PR_DI_FK foreign key (REGULATION_ID, VERS)
  references ME_REGULATION (REGULATION_ID, VERS);
  
create index PP_PH_RI_FK_I on PRESCRIPTION_PHARM (route_id) tablespace INDEX_M;  
create index PP_PR_DI_FK_I on PRESCRIPTION_PHARM (regulation_id) tablespace INDEX_M;  



-------VERS
ALTER TABLE DRUG_REQ_DET 
 ADD (VERS VARCHAR2(10));

COMMENT ON COLUMN DRUG_REQ_DET.VERS IS 'Versão: PT, USA, etc';

UPDATE DRUG_REQ_DET
SET VERS = 'PT';

alter table DRUG_REQ_DET
modify (VERS VARCHAR2(10) NOT NULL);

--
ALTER TABLE PRESCRIPTION_PHARM 
 ADD (VERS VARCHAR2(10));

COMMENT ON COLUMN PRESCRIPTION_PHARM.VERS IS 'Versão: PT, USA, etc';

UPDATE PRESCRIPTION_PHARM
SET VERS = 'PT'; 
 
alter table PRESCRIPTION_PHARM
modify (VERS VARCHAR2(10) NOT NULL);

--
ALTER TABLE DRUG_PRESC_DET 
 ADD (VERS VARCHAR2(10));

COMMENT ON COLUMN drug_presc_det.VERS IS 'Versão: PT, USA, etc';

UPDATE drug_presc_det
SET VERS = 'PT';

alter table drug_presc_det
modify (VERS VARCHAR2(10) NOT NULL);

--
ALTER TABLE PAT_MEDICATION_LIST 
 ADD (VERS VARCHAR2(10));

COMMENT ON COLUMN pat_medication_list.VERS IS 'Versão: PT, USA, etc';

UPDATE pat_medication_list
SET VERS = 'PT';

alter table pat_medication_list
modify (VERS VARCHAR2(10) NOT NULL);

--
ALTER TABLE PAT_MEDICATION_HIST_LIST 
 ADD (VERS VARCHAR2(10));

COMMENT ON COLUMN pat_medication_hist_list.VERS IS 'Versão: PT, USA, etc';

UPDATE pat_medication_hist_list
SET VERS = 'PT';

alter table pat_medication_hist_list
modify (VERS VARCHAR2(10) NOT NULL);

--
ALTER TABLE FLUIDS_PRESC_DET 
 ADD (VERS VARCHAR2(10));

COMMENT ON COLUMN fluids_presc_det.VERS IS 'Versão: PT, USA, etc';

UPDATE fluids_presc_det
SET VERS = 'PT';
 
alter table fluids_presc_det
modify (VERS VARCHAR2(10) NOT NULL);
-- CHANGE END



-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-NOV-13
-- CHANGE REASON: FK
alter table DRUG_REQ_DET
  add constraint DRQD_MED_INT_FK foreign key (ID_DRUG,VERS)
  references MI_MED (ID_DRUG,VERS);

alter table DRUG_REQ_DET
  add constraint DRQD_MED_INT_IDD_FK foreign key (ID_DRUG_DESPACHOS,VERS)
  references MI_REGULATION (regulation_id,VERS);

alter table prescription_pharm
  add constraint PP_MED_EI_FK foreign key (EMB_ID,VERS)
  references ME_MED (EMB_ID,VERS);

alter table prescription_pharm
  add constraint PP_PH_RI_FK foreign key (vias_admin_id,VERS)
  references ME_ROUTE (route_id,VERS);

alter table prescription_pharm
  add constraint PP_PR_DI_FK foreign key (diploma_id,VERS)
  references ME_REGULATION (regulation_id,VERS);

alter table drug_presc_det
  add constraint DPD_MED_INT_ID_FK foreign key (id_drug,VERS)
  references MI_MED (id_drug,VERS);

alter table drug_presc_det
  add constraint DPD_RINT_IDR_FK foreign key (id_drug_route,VERS)
  references  MI_ROUTE (route_id,VERS);

alter table drug_presc_det
  add constraint DPD_JINT_IDJ_FK foreign key (id_drug_justification,VERS)
  references  MI_JUSTIFICATION (id_justification,VERS);

alter table pat_medication_list
  add constraint PML_MED_EI_FK foreign key (emb_id,VERS)
  references ME_MED (emb_id,VERS);

alter table pat_medication_list
  add constraint PML_MED_INT_ID_FK foreign key (id_drug,VERS)
  references MI_MED (id_drug,VERS);

alter table pat_medication_hist_list
  add constraint PMLH_MED_EI_FK foreign key (emb_id,VERS)
  references ME_MED (emb_id,VERS);

alter table pat_medication_hist_list 
  add constraint PMLH_MED_INT_ID_FK foreign key (id_drug,VERS)
  references MI_MED (id_drug,VERS);

alter table fluids_presc_det
  add constraint FPD_MED_INT_ID_FK foreign key (id_drug,VERS)
  references MI_MED (id_drug,VERS);
-- CHANGE END


-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-NOV-13
-- CHANGE REASON: new columns for interactions                      
alter table prescription_pharm 
add (flg_interac_med VARCHAR2(1), 
flg_interac_allergy VARCHAR2(1));

comment on column PRESCRIPTION_PHARM.flg_interac_med
  is 'Chamada de atenção de interacções entre medicamentos: Y - sim; N - não; R - lida.';
comment on column PRESCRIPTION_PHARM.flg_interac_allergy
  is 'Chamada de atenção de interacções entre medicamentos e alergias: Y - sim; N - não; R - lida.';

update prescription_pharm
set  flg_interac_med = 'N', flg_interac_allergy = 'N';
                      
alter table prescription_pharm 
modify (flg_interac_med VARCHAR2(1) NOT NULL,
flg_interac_allergy VARCHAR2(1) NOT NULL);
-- CHANGE END
 
 
-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-NOV-13
-- CHANGE REASON: columns modified from NUMBER to VARCHAR2   
alter table PRESCRIPTION_PHARM drop constraint PPN_DDG_FK;
alter table PRESCRIPTION_PHARM drop constraint PPN_MAD_FK;

alter table prescription_pharm rename column id_dietary_drug to id_dietary_drug2;
alter table prescription_pharm rename column id_manipulated to id_manipulated2;

alter table prescription_pharm
add (id_dietary_drug varchar2(11),
id_manipulated varchar2(11)); 

update prescription_pharm
set id_dietary_drug = to_char(id_dietary_drug2),
id_manipulated = to_char(id_manipulated2);

alter table prescription_pharm drop (id_dietary_drug2, id_manipulated2);

COMMENT ON COLUMN prescription_pharm.id_dietary_drug IS 'ID do dietético.' ;
COMMENT ON COLUMN prescription_pharm.id_manipulated IS 'ID do manipulado (se a prescrição for feita através dos mais frequentes).' ;

create index PPN_DDG_FK_I on PRESCRIPTION_PHARM (id_dietary_drug) tablespace INDEX_M;  
create index PPN_MAD_FK_I on PRESCRIPTION_PHARM (id_manipulated) tablespace INDEX_M;  
-- CHANGE END


-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-NOV-14
-- CHANGE REASON: FK
alter table PRESCRIPTION_PHARM
  add constraint PP_DIET_IV_FK foreign key (id_dietary_drug,VERS)
  references ME_DIETARY (id_dietary_drug,VERS);
   
alter table PRESCRIPTION_PHARM
  add constraint PP_MANIP_IV_FK foreign key (id_manipulated,VERS)
  references ME_MANIP (id_manipulated,VERS);
-- CHANGE END
  
  
-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-NOV-20
-- CHANGE REASON: column NOT NULL
  
update drug_prescription dp
set id_patient = (select id_patient 
                  from visit v, episode e
                           where e.id_episode = dp.id_episode 
                             and v.id_visit = e.id_visit);
                                                            
alter table drug_prescription 
  modify (id_patient number(24) not null);
-- CHANGE END



-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-NOV-20
-- CHANGE REASON: column NOT NULL
update drug_req dp
set id_patient = (select id_patient 
                  from visit v, episode e
                  where e.id_episode = dp.id_episode 
                    and v.id_visit = e.id_visit)
where id_patient is null;
                                        
alter table drug_req 
  modify (id_patient number(24) not null);
-- CHANGE END


-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-NOV-27
-- CHANGE REASON: new columns for interactions               
alter table drug_presc_det 
add (flg_interac_med VARCHAR2(1), 
flg_interac_allergy VARCHAR2(1));

comment on column drug_presc_det.flg_interac_med
  is 'Chamada de atenção de interacções entre medicamentos: Y - sim; N - não; R - lida.';
comment on column drug_presc_det.flg_interac_allergy
  is 'Chamada de atenção de interacções entre medicamentos e alergias: Y - sim; N - não; R - lida.';

update drug_presc_det
set  flg_interac_med = 'N', flg_interac_allergy = 'N';
               
alter table drug_presc_det 
modify (flg_interac_med VARCHAR2(1) NOT NULL,
flg_interac_allergy VARCHAR2(1) NOT NULL);


alter table drug_req_det 
add (flg_interac_med VARCHAR2(1), 
flg_interac_allergy VARCHAR2(1));

comment on column drug_req_det.flg_interac_med
  is 'Chamada de atenção de interacções entre medicamentos: Y - sim; N - não; R - lida.';
comment on column drug_req_det.flg_interac_allergy
  is 'Chamada de atenção de interacções entre medicamentos e alergias: Y - sim; N - não; R - lida.';

update drug_req_det
set  flg_interac_med = 'N', flg_interac_allergy = 'N';
               
alter table drug_req_det 
modify (flg_interac_med VARCHAR2(1) NOT NULL,
flg_interac_allergy VARCHAR2(1) NOT NULL);
-- CHANGE END

-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 2007-DEC-06
-- CHANGE REASON: Column Varchar    
ALTER TABLE drug_therapeutic_protocols ADD id_drug_route_c VARCHAR2(255);
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 1;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 2;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 3;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10048' WHERE z.id_drug_therapeutic_protocols = 4;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10048' WHERE z.id_drug_therapeutic_protocols = 5;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10073' WHERE z.id_drug_therapeutic_protocols = 6;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 10;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 12;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10048' WHERE z.id_drug_therapeutic_protocols = 13;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10030' WHERE z.id_drug_therapeutic_protocols = 14;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10048' WHERE z.id_drug_therapeutic_protocols = 15;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 16;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10048' WHERE z.id_drug_therapeutic_protocols = 18;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 19;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 20;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 21;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 22;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 23;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 24;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 25;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 26;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 27;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 28;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 29;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 30;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 31;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 32;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10067' WHERE z.id_drug_therapeutic_protocols = 33;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10048' WHERE z.id_drug_therapeutic_protocols = 34;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 36;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10067' WHERE z.id_drug_therapeutic_protocols = 37;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10067' WHERE z.id_drug_therapeutic_protocols = 38;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10067' WHERE z.id_drug_therapeutic_protocols = 39;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10067' WHERE z.id_drug_therapeutic_protocols = 40;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10067' WHERE z.id_drug_therapeutic_protocols = 41;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10067' WHERE z.id_drug_therapeutic_protocols = 42;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10067' WHERE z.id_drug_therapeutic_protocols = 43;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10067' WHERE z.id_drug_therapeutic_protocols = 44;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10030' WHERE z.id_drug_therapeutic_protocols = 48;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10054' WHERE z.id_drug_therapeutic_protocols = 49;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 50;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 51;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10054' WHERE z.id_drug_therapeutic_protocols = 52;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 53;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 54;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10058' WHERE z.id_drug_therapeutic_protocols = 56;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10054' WHERE z.id_drug_therapeutic_protocols = 61;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 62;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 63;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10030' WHERE z.id_drug_therapeutic_protocols = 64;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 65;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 66;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 67;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 68;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 69;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 70;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 71;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 72;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 73;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 74;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 75;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 76;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 77;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10048' WHERE z.id_drug_therapeutic_protocols = 78;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 79;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 80;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 81;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10048' WHERE z.id_drug_therapeutic_protocols = 82;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 84;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 85;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 86;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 87;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 88;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 89;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 90;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 91;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 93;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 94;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10008' WHERE z.id_drug_therapeutic_protocols = 95;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10008' WHERE z.id_drug_therapeutic_protocols = 96;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10008' WHERE z.id_drug_therapeutic_protocols = 97;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 98;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10008' WHERE z.id_drug_therapeutic_protocols = 99;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10008' WHERE z.id_drug_therapeutic_protocols = 100;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10008' WHERE z.id_drug_therapeutic_protocols = 101;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 102;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10008' WHERE z.id_drug_therapeutic_protocols = 103;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10008' WHERE z.id_drug_therapeutic_protocols = 104;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 105;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 106;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10008' WHERE z.id_drug_therapeutic_protocols = 107;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10008' WHERE z.id_drug_therapeutic_protocols = 108;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 109;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 110;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10037' WHERE z.id_drug_therapeutic_protocols = 111;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10037' WHERE z.id_drug_therapeutic_protocols = 112;
UPDATE drug_therapeutic_protocols SET id_drug_route_c = '10042' WHERE z.id_drug_therapeutic_protocols = 113;

ALTER TABLE drug_therapeutic_protocols DROP COLUMN id_drug_route;
ALTER TABLE drug_therapeutic_protocols ADD id_drug_route VARCHAR2(255);

UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 1;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 2;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 3;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10048' WHERE z.id_drug_therapeutic_protocols = 4;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10048' WHERE z.id_drug_therapeutic_protocols = 5;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10073' WHERE z.id_drug_therapeutic_protocols = 6;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 10;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 12;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10048' WHERE z.id_drug_therapeutic_protocols = 13;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10030' WHERE z.id_drug_therapeutic_protocols = 14;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10048' WHERE z.id_drug_therapeutic_protocols = 15;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 16;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10048' WHERE z.id_drug_therapeutic_protocols = 18;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 19;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 20;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 21;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 22;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 23;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 24;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 25;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 26;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 27;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 28;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 29;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 30;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 31;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 32;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10067' WHERE z.id_drug_therapeutic_protocols = 33;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10048' WHERE z.id_drug_therapeutic_protocols = 34;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 36;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10067' WHERE z.id_drug_therapeutic_protocols = 37;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10067' WHERE z.id_drug_therapeutic_protocols = 38;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10067' WHERE z.id_drug_therapeutic_protocols = 39;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10067' WHERE z.id_drug_therapeutic_protocols = 40;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10067' WHERE z.id_drug_therapeutic_protocols = 41;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10067' WHERE z.id_drug_therapeutic_protocols = 42;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10067' WHERE z.id_drug_therapeutic_protocols = 43;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10067' WHERE z.id_drug_therapeutic_protocols = 44;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10030' WHERE z.id_drug_therapeutic_protocols = 48;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10054' WHERE z.id_drug_therapeutic_protocols = 49;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 50;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 51;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10054' WHERE z.id_drug_therapeutic_protocols = 52;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 53;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 54;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10058' WHERE z.id_drug_therapeutic_protocols = 56;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10054' WHERE z.id_drug_therapeutic_protocols = 61;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 62;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 63;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10030' WHERE z.id_drug_therapeutic_protocols = 64;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 65;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 66;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 67;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 68;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 69;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 70;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 71;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 72;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 73;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 74;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 75;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 76;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 77;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10048' WHERE z.id_drug_therapeutic_protocols = 78;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 79;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 80;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 81;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10048' WHERE z.id_drug_therapeutic_protocols = 82;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 84;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 85;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 86;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 87;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 88;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 89;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 90;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 91;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 93;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 94;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10008' WHERE z.id_drug_therapeutic_protocols = 95;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10008' WHERE z.id_drug_therapeutic_protocols = 96;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10008' WHERE z.id_drug_therapeutic_protocols = 97;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 98;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10008' WHERE z.id_drug_therapeutic_protocols = 99;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10008' WHERE z.id_drug_therapeutic_protocols = 100;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10008' WHERE z.id_drug_therapeutic_protocols = 101;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 102;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10008' WHERE z.id_drug_therapeutic_protocols = 103;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10008' WHERE z.id_drug_therapeutic_protocols = 104;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 105;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 106;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10008' WHERE z.id_drug_therapeutic_protocols = 107;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10008' WHERE z.id_drug_therapeutic_protocols = 108;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 109;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 110;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10037' WHERE z.id_drug_therapeutic_protocols = 111;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10037' WHERE z.id_drug_therapeutic_protocols = 112;
UPDATE drug_therapeutic_protocols SET id_drug_route = '10042' WHERE z.id_drug_therapeutic_protocols = 113;

ALTER TABLE drug_therapeutic_protocols DROP COLUMN id_drug_route_c;
-- CHANGE END

-- CHANGED BY: Tércio Soares
-- CHANGE DATE: 2007-DEC-06
-- CHANGE REASON: Column Varchar    
ALTER TABLE drug_therapeutic_protocols DROP COLUMN id_drug_route;
ALTER TABLE drug_therapeutic_protocols ADD id_drug_route VARCHAR2(255);
-- CHANGE END


-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-DEC-15
-- CHANGE REASON: data for medication tables    
INSERT into MI_PHARM_GROUP (GROUP_ID,GROUP_DESCR,FLG_AVAILABLE,VERS)
SELECT GROUP_ID,GROUP_DESCR,FLG_AVAILABLE,VERS FROM MI_PHARM_GROUP_PT;

INSERT into MI_JUSTIFICATION (ID_JUSTIFICATION,JUSTIFICATION_DESCR,VERS)
SELECT ID_JUSTIFICATION,JUSTIFICATION_DESCR,VERS FROM MI_JUSTIFICATION_PT;

INSERT into MI_ROUTE (ROUTE_ID,ROUTE_DESCR,GENDER,AGE_MIN,AGE_MAX,FLG_AVAILABLE,VERS)
SELECT ROUTE_ID,ROUTE_DESCR,GENDER,AGE_MIN,AGE_MAX,FLG_AVAILABLE,VERS FROM MI_ROUTE_PT;

INSERT into MI_REGULATION (REGULATION_ID,REGULATION_DESCR,VERS)
SELECT REGULATION_ID,REGULATION_DESCR,VERS FROM MI_REGULATION_PT;

INSERT into MI_MED ( ID_DRUG,MED_DESCR_FORMATED,MED_DESCR,SHORT_MED_DESCR,FLG_TYPE,FLG_AVAILABLE,FLG_JUSTIFY,ID_DRUG_BRAND,DCI_ID,DCI_DESCR,FORM_FARM_ID,FORM_FARM_DESCR,ROUTE_ID,ROUTE_DESCR,QT_DOS_COMP,UNIT_DOS_COMP,DOSAGEM,GENDER,AGE_MIN,AGE_MAX,MDM_CODING,CHNM_ID,FLG_MIX_FLUID,ID_UNIT_MEASURE,NOTES,VERS)
SELECT ID_DRUG,MED_DESCR_FORMATED,MED_DESCR,SHORT_MED_DESCR,FLG_TYPE,FLG_AVAILABLE,FLG_JUSTIFY,ID_DRUG_BRAND,DCI_ID,DCI_DESCR,FORM_FARM_ID,FORM_FARM_DESCR,ROUTE_ID,ROUTE_DESCR,QT_DOS_COMP,UNIT_DOS_COMP,DOSAGEM,GENDER,AGE_MIN,AGE_MAX,MDM_CODING,CHNM_ID,FLG_MIX_FLUID,ID_UNIT_MEASURE,NOTES,VERS FROM MI_MED_PT; 

INSERT into MI_MED_PHARM_GROUP (ID_DRUG,GROUP_ID,VERS)
SELECT ID_DRUG,GROUP_ID,VERS FROM MI_MED_PHARM_GROUP_PT;

INSERT into MI_MED_REGULATION (ID_DRUG,REGULATION_ID,COMPART,REGULATION_DESCR,VERS)
SELECT ID_DRUG,REGULATION_ID,COMPART,REGULATION_DESCR,VERS FROM MI_MED_REGULATION_PT;

INSERT into MI_MED_ATC (ID_DRUG,ATC_ID,ATC_DESCR,VERS)
SELECT ID_DRUG,ATC_ID,ATC_DESCR,VERS FROM MI_MED_ATC_PT;

INSERT into ME_PHARM_GROUP (GROUP_ID,GROUP_DESCR,PARENT_ID,PARENT_DESCR,LEVEL_NUM,RANK,VERS)
SELECT GROUP_ID,GROUP_DESCR,PARENT_ID,PARENT_DESCR,LEVEL_NUM,RANK,VERS FROM ME_PHARM_GROUP_PT;

INSERT into ME_ROUTE (ROUTE_ID,ROUTE_DESCR,VERS)
SELECT ROUTE_ID,ROUTE_DESCR,VERS FROM ME_ROUTE_PT;

INSERT into ME_REGULATION (REGULATION_ID,REGULATION_DESCR,VERS)
SELECT REGULATION_ID,REGULATION_DESCR,VERS FROM ME_REGULATION_PT;

INSERT into ME_MED (EMB_ID,MED_ID,MED_NAME,MED_DESCR_FORMATED,MED_DESCR,SHORT_MED_DESCR,EMB_DESCR,PRICE_PVP,PRICE_REF,PRICE_PENS,OTC_DESCR,GENERICO,GENERICO_DESCR,DCI_ID,DCI_DESCR,FORM_FARM_ID,FORM_FARM_DESCR,TIPO_PROD_ID,QT_DOS_COMP,UNIT_DOS_COMP,N_UNITS,QT_PER_UNIT,DOSAGEM,TITULAR_ID,TITULAR_DESCR,DATA_AIM,ESTADO_ID,ESTADO_DESCR,DISP_ID,DISP_DESCR,ESTUP_ID,ESTUP_DESCR,TRAT_ID,TRAT_DESCR,EMB_UNIT_ID,EMB_UNIT_DESCR,GRUPO_HOM_ID,GRUPO_HOM_DESCR,N_REGISTO,COMPART,FLG_COMERC,FLG_AVAILABLE,DISPO_ID,DISPO_DATA,VERS)
SELECT EMB_ID,MED_ID,MED_NAME,MED_DESCR_FORMATED,MED_DESCR,SHORT_MED_DESCR,EMB_DESCR,PRICE_PVP,PRICE_REF,PRICE_PENS,OTC_DESCR,GENERICO,GENERICO_DESCR,DCI_ID,DCI_DESCR,FORM_FARM_ID,FORM_FARM_DESCR,TIPO_PROD_ID,QT_DOS_COMP,UNIT_DOS_COMP,N_UNITS,QT_PER_UNIT,DOSAGEM,TITULAR_ID,TITULAR_DESCR,DATA_AIM,ESTADO_ID,ESTADO_DESCR,DISP_ID,DISP_DESCR,ESTUP_ID,ESTUP_DESCR,TRAT_ID,TRAT_DESCR,EMB_UNIT_ID,EMB_UNIT_DESCR,GRUPO_HOM_ID,GRUPO_HOM_DESCR,N_REGISTO,COMPART,FLG_COMERC,FLG_AVAILABLE,DISPO_ID,DISPO_DATA,VERS FROM ME_MED_PT;

INSERT into ME_MED_ROUTE (EMB_ID,ROUTE_ID,ROUTE_DESCR,VERS)
SELECT EMB_ID,ROUTE_ID,ROUTE_DESCR,VERS FROM ME_MED_ROUTE_PT;

INSERT into ME_MED_PHARM_GROUP (EMB_ID,GROUP_ID,GROUP_ID_L2,VERS)
SELECT EMB_ID,GROUP_ID,GROUP_ID_L2,VERS FROM ME_MED_PHARM_GROUP_PT;

INSERT into ME_MED_SUBST (EMB_ID,SUBST_ID,SUBST_DESCR,SUBST_QUANT,VERS)
SELECT EMB_ID,SUBST_ID,SUBST_DESCR,SUBST_QUANT,VERS FROM ME_MED_SUBST_PT;

INSERT into ME_MED_ATC (EMB_ID,ATC_ID,ATC_DESCR,VERS)
SELECT EMB_ID,ATC_ID,ATC_DESCR,VERS FROM ME_MED_ATC_PT;

INSERT into ME_MED_REGULATION (EMB_ID,REGULATION_ID,COMPART,REGULATION_DESCR,VERS)
SELECT EMB_ID,REGULATION_ID,COMPART,REGULATION_DESCR,VERS FROM ME_MED_REGULATION_PT;

INSERT into ME_MANIP_GROUP (ID_MANIPULATED_GROUP,GROUP_DESCR,VERS)
SELECT ID_MANIPULATED_GROUP,GROUP_DESCR,VERS FROM ME_MANIP_GROUP_PT;

INSERT into ME_INGRED (ID_INGREDIENT,FLG_TYPE,INGRED_DESCR,VERS)
SELECT ID_INGREDIENT,FLG_TYPE,INGRED_DESCR,VERS FROM ME_INGRED_PT;

INSERT into ME_MANIP (ID_MANIPULATED,ID_MANIPULATED_GROUP,FLG_TYPE,MANIP_DESCR,VERS)
SELECT ID_MANIPULATED,ID_MANIPULATED_GROUP,FLG_TYPE,MANIP_DESCR,VERS FROM ME_MANIP_PT;

INSERT into ME_MANIP_INGRED (ID_INGREDIENT,ID_MANIPULATED,PERCENT,VERS)
SELECT ID_INGREDIENT,ID_MANIPULATED,PERCENT,VERS FROM ME_MANIP_INGRED_PT;

INSERT into ME_DIETARY (ID_DIETARY_DRUG,QTY,MEASURE_UNIT,FLG_TYPE,DIETARY_DESCR,VERS)
SELECT ID_DIETARY_DRUG,QTY,MEASURE_UNIT,FLG_TYPE,DIETARY_DESCR,VERS FROM ME_DIETARY_PT;

-- CHANGE END


-- CHANGED BY: Joao Sa
-- CHANGE DATE: 2007-DEC-21
-- CHANGE REASON: Mudanca de tipo de p1_match.sequential_number
ALTER TABLE P1_MATCH MODIFY (sequential_number NOT NULL ENABLE);



-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2007-DEC-26
-- CHANGE REASON: modify column to not null
update pat_family_member
set flg_status = 'A'
where flg_status is null;

alter table pat_family_member
 modify (flg_status varchar2(1) not null);
-- CHANGE END

--João Eiras, 07-01-2007, nova coluna code_units
update follow_up_type set code_units = 'FOLLOW_UP_TYPE.CODE_UNITS.'||id_follow_up_type;



-- CHANGED BY: Susana Seixas
-- CHANGE DATE: 2008-JAN-10
-- CHANGE REASON: modify column to not null
update social_episode s
set id_institution = (select id_institution 
                      from episode e, visit v
                                 where e.id_episode = s.id_episode
                                   and v.id_visit = e.id_visit)
WHERE id_institution IS NULL;

alter table social_episode
modify (id_institution number(12) not null);
-- CHANGE END


-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 2008-JAN-20
-- CHANGE REASON: recreate indexes
drop index ART_FLG_TIME_I;
create index ART_FLG_TIME_I on ANALYSIS_REQ (flg_time, dt_req_tstz, id_analysis_req, id_episode, id_visit);

drop index AR_DTBG_IAR_IPW_IE_IDX;
create index AR_DTBG_IAR_IPW_IE_IDX on ANALYSIS_REQ (id_episode, id_prof_writes, id_analysis_req, dt_begin, id_visit);

create index ARQ_VIT_FK_I on ANALYSIS_REQ (id_visit);

drop index HARV_FLG_STATUS_DT_I;
create index HARV_FLG_STATUS_DT_I on HARVEST (id_harvest, flg_status, dt_harvest_tstz, id_visit, id_patient);

-- CHANGE END

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 2008-JAN-20
-- CHANGE REASON: recreate indexes
alter index ART_FLG_TIME_I rebuild tablespace INDEX_M;
alter index AR_DTBG_IAR_IPW_IE_IDX rebuild tablespace INDEX_M;
alter index ARQ_VIT_FK_I rebuild tablespace INDEX_M;
-- CHANGE END

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 2008-JAN-21
-- CHANGE REASON: recreate indexes
create index HAT_VIT_FK_I on HARVEST (ID_VISIT);
alter index HAT_VIT_FK_I rebuild tablespace INDEX_M;
-- CHANGE END

-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 2008-JAN-22
-- CHANGE REASON: correct grid_task
UPDATE grid_task
   SET analysis_d = '8|'||analysis_d
 WHERE analysis_d = 'xxxxxxxxxxxxxx|I|X|AnalysisExecutingIcon';

UPDATE grid_task
   SET analysis_n = '8|'||analysis_n
 WHERE analysis_n = 'xxxxxxxxxxxxxx|I|X|AnalysisExecutingIcon';
-- CHANGE END

-- CHANGED BY: Patrícia Neto
-- CHANGED DATE: 2008-JAN-28
-- CHANGING REASON: alteração da estrutura das tabelas
-- DRUG_PRESC_DET

-- 1. BCKP TABLE CRIATION
CREATE TABLE drug_presc_det_bk20080125 AS (SELECT * FROM drug_presc_det);

-- 2. SET TO NULL QTY_BASIS FROM DRUG
UPDATE drug_presc_det D SET D.frequency = NULL,
d.duration = null;


-- 3. ALTER TABLE
alter table drug_presc_det modify frequency NUMBER(24,4);
alter table drug_presc_det modify duration NUMBER(24,4);

-- 4. CREATE SCRIPTS TO UPDATE DRUG
update drug_presc_det a set a.frequency = (select frequency from drug_presc_det_bk20080125 b where b.id_drug_presc_det = a.id_drug_presc_det),
a.duration = (select duration from drug_presc_det_bk20080125 b where b.id_drug_presc_det = a.id_drug_presc_det);


-- DRUG_REQ_DET

-- 1. BCKP TABLE CRIATION
CREATE TABLE drug_req_det_bk20080125 AS (SELECT * FROM drug_req_det);

-- 2. SET TO NULL QTY_BASIS FROM DRUG
UPDATE drug_req_det D SET D.frequency = NULL,
d.duration = null;

-- 3. ALTER TABLE
alter table drug_req_det modify frequency NUMBER(24,4);
alter table drug_req_det modify duration NUMBER(24,4);

-- 4. CREATE SCRIPTS TO UPDATE DRUG
update drug_req_det a set a.frequency = (select frequency from drug_req_det_bk20080125 b where b.id_drug_req_det = a.id_drug_req_det),
a.duration = (select duration from drug_req_det_bk20080125 b where b.id_drug_req_det = a.id_drug_req_det);


-- PRESCRIPTION_PHARM

-- 1. BCKP TABLE CRIATION
CREATE TABLE prescription_pharm_bk20080125 AS (SELECT * FROM prescription_pharm);

-- 2. SET TO NULL QTY_BASIS FROM DRUG
UPDATE prescription_pharm D SET D.Frequency = NULL,
d.duration = null;

-- 3. ALTER TABLE
alter table prescription_pharm modify frequency NUMBER(24,4);
alter table prescription_pharm modify duration NUMBER(24,4);

-- 4. CREATE SCRIPTS TO UPDATE DRUG
update prescription_pharm a set a.frequency = (select frequency from prescription_pharm_bk20080125 b where b.id_prescription_pharm = a.id_prescription_pharm),
a.duration = (select duration from prescription_pharm_bk20080125 b where b.id_prescription_pharm = a.id_prescription_pharm);

-- PAT_MEDICATION_LIST

-- 1. BCKP TABLE CRIATION
CREATE TABLE pat_medication_list_bk20080125 AS (SELECT * FROM pat_medication_list);

-- 2. SET TO NULL QTY_BASIS FROM DRUG
UPDATE pat_medication_list D SET D.Freq = NULL,
d.duration = null;

-- 3. ALTER TABLE
alter table pat_medication_list modify freq NUMBER(24,4);
alter table pat_medication_list modify duration NUMBER(24,4);

-- 4. CREATE SCRIPTS TO UPDATE DRUG
update pat_medication_list a set a.freq = (select freq from pat_medication_list_bk20080125 b where b.id_pat_medication_list = a.id_pat_medication_list),
a.duration = (select duration from pat_medication_list_bk20080125 b where b.id_pat_medication_list = a.id_pat_medication_list);

-- PAT_MEDICATION_HIST_LIST

-- 1. BCKP TABLE CRIATION
CREATE TABLE pat_medication_hist_list_B AS (SELECT * FROM pat_medication_hist_list);

-- 2. SET TO NULL QTY_BASIS FROM DRUG
UPDATE pat_medication_hist_list D SET D.Freq = NULL,
d.duration = null;

-- 3. ALTER TABLE
alter table pat_medication_hist_list modify freq NUMBER(24,4);
alter table pat_medication_hist_list modify duration NUMBER(24,4);

-- 4. CREATE SCRIPTS TO UPDATE DRUG
update pat_medication_hist_list a set a.freq = (select freq from pat_medication_hist_list_B b where b.id_pat_medication_hist_list = a.id_pat_medication_hist_list),
a.duration = (select duration from pat_medication_hist_list_B b where b.id_pat_medication_hist_list = a.id_pat_medication_hist_list);

-- PRESCRIPTION_INSTR_HIST

-- 1. BCKP TABLE CRIATION
CREATE TABLE PRESCRIPTION_INSTR_HIST_080125 AS (SELECT * FROM PRESCRIPTION_INSTR_HIST);

-- 2. SET TO NULL QTY_BASIS FROM DRUG
UPDATE PRESCRIPTION_INSTR_HIST D SET D.FREQUENCY = NULL,
d.Duration = null;


-- 3. ALTER TABLE
alter table PRESCRIPTION_INSTR_HIST modify FREQUENCY NUMBER(24,4);
alter table PRESCRIPTION_INSTR_HIST modify duration NUMBER(24,4);

-- 4. CREATE SCRIPTS TO UPDATE DRUG
update PRESCRIPTION_INSTR_HIST a set a.FREQUENCY = (select FREQUENCY from PRESCRIPTION_INSTR_HIST_080125 b where b.ID_PRESCRIPTION_INSTR_HIST = a.id_PRESCRIPTION_INSTR_HIST
AND A.ID_PRESC = B.ID_PRESC AND A.FLG_TYPE_PRESC = B.FLG_TYPE_PRESC),
a.duration = (select duration from PRESCRIPTION_INSTR_HIST_080125 b where  b.ID_PRESCRIPTION_INSTR_HIST = a.id_PRESCRIPTION_INSTR_HIST
AND A.ID_PRESC = B.ID_PRESC AND A.FLG_TYPE_PRESC = B.FLG_TYPE_PRESC);
-- CHANGE END Patrícia Neto

--Rui Spratley 2008/01/30
--Reformulação das análises: id_analysis_group
drop index ARD_IDX;
create index ARD_IDX on ANALYSIS_REQ_DET (id_analysis_req_det, id_analysis, id_analysis_req, flg_status, id_room, id_exam_cat, id_room_req, id_analysis_group);
alter index ARD_IDX rebuild tablespace INDEX_M;

--Rui Spratley 2008/03/24
--Performance
alter table GRID_TASK_OTH_EXM add PAT_AGE_TMP VARCHAR2(30);
update GRID_TASK_OTH_EXM set PAT_AGE_TMP = PAT_AGE;
update GRID_TASK_OTH_EXM set PAT_AGE = null;
alter table GRID_TASK_OTH_EXM modify PAT_AGE VARCHAR2(30);
update GRID_TASK_OTH_EXM set PAT_AGE = PAT_AGE_TMP;
alter table GRID_TASK_OTH_EXM drop column PAT_AGE_TMP;

--Sérgio Santos 2008/05/29 - Pending issues 2.4.3
--Migração de dados
insert into issue_prof_assigned (ID_ISSUE, ID_PROF, FLG_STATUS, DT_ASSIGN, ID_PROF_DELETION, DT_DELETION)
(select i.id_issue, i.id_prof_assigned, 'A', i.dt_creation, null, null from issue i);
--Eliminação de colunas
alter table issue drop constraint ISSUE_PROF_ASSIGNED;
drop index i_f_pa_idx;
alter table issue drop column id_prof_assigned;

alter table issue_message drop constraint ISSUE_MESSAGE_PROF_ASSIGNED;
drop index im_f_pa_idx;
alter table issue_message drop column id_prof_assigned;
--END




-- CHANGED BY: Thiago Brito
-- CHANGED DATE: 2008-MAY-30
-- CHANGING REASON: NOVA API
-- GRANT

GRANT execute ON ALERT.PK_API_ANALYSIS TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_ANALYSIS TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_DIAGNOSIS TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_DIAGNOSIS TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_DRUG TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_DRUG TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_EXAM TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_EXAM TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_FAMILY TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_FAMILY TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_MOVEMENT TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_MOVEMENT TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_PATIENT TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_PATIENT TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_PRESCRIPTION TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_PRESCRIPTION TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_SR_VISIT TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_SR_VISIT TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_UNIT_MEASURE TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_UNIT_MEASURE TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_VITAL_SIGN TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_VITAL_SIGN TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_WAITINGLINESONHO TO inter_alert_v2;
/

GRANT execute ON ALERT.PK_API_WAITINGLINESONHO TO inter_alert_v2;
/


-- REVOKE

REVOKE execute ON ALERT.PK_ANALYSIS FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_ANALYSIS FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_DIAGNOSIS FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_DIAGNOSIS FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_DRUG FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_DRUG FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_EXAM FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_EXAM FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_FAMILY FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_FAMILY FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_MOVEMENT FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_MOVEMENT FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_PATIENT FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_PATIENT FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_PRESCRIPTION FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_PRESCRIPTION FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_SR_VISIT FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_SR_VISIT FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_UNIT_MEASURE FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_UNIT_MEASURE FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_VITAL_SIGN FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_VITAL_SIGN FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_WAITINGLINESONHO FROM inter_alert_v2;
/

REVOKE execute ON ALERT.PK_WAITINGLINESONHO FROM inter_alert_v2;
/

-- CHANGE END

--CHANGED BY: Rui Spratley
--CHANGE DATE: 2008/06/04
--CHANGE REASON: Remove unused column
update PROFESSIONAL
set flg_migration = 'T'
where FLG_PROF_TEST = 'Y';

ALTER TABLE PROFESSIONAL drop column FLG_PROF_TEST;
-- CHANGE END

-- JSILVA 13-06-2008
DECLARE

 CURSOR c_pat_pregnancy IS
 SELECT pp.id_pat_pregnancy, pp.n_children, pp.flg_childbirth_type
 FROM pat_pregnancy pp;
 
 CURSOR c_pregn_fetus(i_pat_pregnancy pat_pregnancy.id_pat_pregnancy%TYPE, i_n_fetus pat_pregn_fetus.fetus_number%TYPE) IS
 SELECT pf.id_pat_pregn_fetus
 FROM pat_pregn_fetus pf
 WHERE pf.id_pat_pregnancy = i_pat_pregnancy
   AND pf.fetus_number = i_n_fetus;
    
 l_pat_pregn_fetus pat_pregn_fetus.id_pat_pregn_fetus%TYPE;

BEGIN

 FOR r_pp IN c_pat_pregnancy
 LOOP
     IF r_pp.n_children IS NOT NULL
       THEN
         FOR i IN 1 .. r_pp.n_children
          LOOP
            l_pat_pregn_fetus := NULL;
          
            OPEN c_pregn_fetus(r_pp.id_pat_pregnancy, i);
             FETCH c_pregn_fetus INTO l_pat_pregn_fetus;
             CLOSE c_pregn_fetus;
             
             IF l_pat_pregn_fetus IS NOT NULL
             THEN
               UPDATE pat_pregn_fetus pf SET pf.flg_status = 'A', pf.flg_childbirth_type = r_pp.flg_childbirth_type WHERE pf.id_pat_pregn_fetus = l_pat_pregn_fetus;
             ELSE
               INSERT INTO pat_pregn_fetus (id_pat_pregn_fetus, id_pat_pregnancy, flg_gender, fetus_number, flg_childbirth_type, flg_status, weight)
                VALUES (seq_pat_pregn_fetus.nextval, r_pp.id_pat_pregnancy, NULL, i, r_pp.flg_childbirth_type, 'A', NULL);
             END IF;
          END LOOP;
       ELSIF r_pp.flg_childbirth_type IS NOT NULL
       THEN
       
            l_pat_pregn_fetus := NULL;       
            OPEN c_pregn_fetus(r_pp.id_pat_pregnancy, 1);
             FETCH c_pregn_fetus INTO l_pat_pregn_fetus;
             CLOSE c_pregn_fetus;
             
             IF l_pat_pregn_fetus IS NOT NULL
             THEN
               UPDATE pat_pregn_fetus pf SET pf.flg_status = 'A', pf.flg_childbirth_type = r_pp.flg_childbirth_type WHERE pf.id_pat_pregn_fetus = l_pat_pregn_fetus;
             ELSE
               INSERT INTO pat_pregn_fetus (id_pat_pregn_fetus, id_pat_pregnancy, flg_gender, fetus_number, flg_childbirth_type, flg_status, weight)
                VALUES (seq_pat_pregn_fetus.nextval, r_pp.id_pat_pregnancy, NULL, 1, r_pp.flg_childbirth_type, 'A', NULL);
             END IF;
       END IF;
 
 END LOOP;
END;
/
-- end

-- JSILVA 13-06-2008
DECLARE

     CURSOR c_pat_pregnancy IS 
     SELECT p.id_pat_pregnancy, p.flg_ectopic_pregnancy, p.flg_abbort, p.flg_abortion_type
     FROM pat_pregnancy p;

BEGIN
     FOR r_pp IN c_pat_pregnancy
       LOOP
         IF r_pp.flg_ectopic_pregnancy = 'Y' OR r_pp.flg_abbort = 'E'
          THEN
              UPDATE pat_pregnancy pp
                SET pp.flg_status = 'GE' WHERE pp.id_pat_pregnancy = r_pp.id_pat_pregnancy;
          ELSIF r_pp.flg_abortion_type = 'N' OR r_pp.flg_abbort = 'N'
          THEN
              UPDATE pat_pregnancy pp
                SET pp.flg_status = 'N' WHERE pp.id_pat_pregnancy = r_pp.id_pat_pregnancy;
          ELSIF r_pp.flg_abortion_type IS NULL AND r_pp.flg_abbort = 'A'
          THEN          
              UPDATE pat_pregnancy pp
                SET pp.flg_status = 'AB' WHERE pp.id_pat_pregnancy = r_pp.id_pat_pregnancy;
          ELSIF r_pp.flg_abortion_type = 'P'
          THEN          
              UPDATE pat_pregnancy pp
                SET pp.flg_status = 'AP' WHERE pp.id_pat_pregnancy = r_pp.id_pat_pregnancy;                
          ELSIF r_pp.flg_abortion_type = 'E'
          THEN          
              UPDATE pat_pregnancy pp
                SET pp.flg_status = 'E' WHERE pp.id_pat_pregnancy = r_pp.id_pat_pregnancy;                
          END IF;
       END LOOP;
END;
/

-- END

-- JSILVA 13-06-2008
UPDATE pat_pregnancy pp SET pp.dt_intervention = nvl(pp.dt_childbirth, pp.dt_abortion);
UPDATE pat_pregnancy pp SET pp.num_gest_weeks = pp.gestation_time;

ALTER TABLE pat_pregnancy drop column dt_childbirth;
ALTER TABLE pat_pregnancy drop column dt_abortion;
ALTER TABLE pat_pregnancy drop column gestation_time;
ALTER TABLE pat_pregnancy drop column FLG_CHILDBIRTH_TYPE;
ALTER TABLE pat_pregnancy drop column FLG_ABBORT;
ALTER TABLE pat_pregnancy drop column FLG_ABORTION_TYPE;
ALTER TABLE pat_pregnancy drop column FLG_ECTOPIC_PREGNANCY;
-- END

--CHANGED BY: Rui Spratley
--CHANGE DATE: 2008/06/04
--CHANGE REASON: Change default value in column
update episode 
set flg_migration = 'A' 
where flg_migration is null;

update visit 
set flg_migration = 'A' 
where flg_migration is null;

update professional 
set flg_migration = 'A' 
where flg_migration is null;

update patient 
set flg_migration = 'A' 
where flg_migration is null;

alter table episode modify flg_migration not null;
alter table visit modify flg_migration not null;
alter table professional modify flg_migration not null;
alter table patient modify flg_migration not null;
-- CHANGE END

-- CHANGED BY: Thiago Brito
-- CHANGED DATE: 2008-MAY-30
-- CHANGING REASON: NOVA API
-- REVOKE

REVOKE all ON ALERT.PK_ANALYSIS FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_ANALYSIS FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_DIAGNOSIS FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_DIAGNOSIS FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_DRUG FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_DRUG FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_EXAM FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_EXAM FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_FAMILY FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_FAMILY FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_MOVEMENT FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_MOVEMENT FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_PATIENT FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_PATIENT FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_PRESCRIPTION FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_PRESCRIPTION FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_SR_VISIT FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_SR_VISIT FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_UNIT_MEASURE FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_UNIT_MEASURE FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_VITAL_SIGN FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_VITAL_SIGN FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_WAITINGLINESONHO FROM inter_alert_v2;
/

REVOKE all ON ALERT.PK_WAITINGLINESONHO FROM inter_alert_v2;
/

-- CHANGE END


-- CHANGED BY: Fábio Oliveira 
-- CHANGE DATE: 2008-JUL-26
-- CHANGE REASON: [WO15997] Inserção do nome do exame na pesquisa de activos dos técnicos de exames de imagem e de outros exames
drop type t_coll_episactiveitech force;
CREATE OR REPLACE TYPE t_rec_episactiveitech AS OBJECT
(
    rank         NUMBER,
    acuity       VARCHAR2(240),
    rank_acuity  NUMBER,
    epis_type    VARCHAR2(4000),
    dt_first_obs VARCHAR2(4000),
    desc_patient VARCHAR2(200),
    id_patient   NUMBER(24),
    id_episode   NUMBER(24),
    dt_server    VARCHAR2(4000),
    desc_exam    VARCHAR2(200),
    col_execute  VARCHAR2(4000),
    col_complete VARCHAR2(4000)
);
CREATE OR REPLACE TYPE t_coll_episactiveitech AS TABLE OF t_rec_episactiveitech;
-- CHANGE END

-- JSILVA 27-07-2008
drop type t_coll_patcriteriaactiveadmin force;
CREATE OR REPLACE TYPE t_rec_patcriteriaactiveadmin AS OBJECT
(
    origem                   VARCHAR2(4000),
    acuity                   VARCHAR2(240),
    color_text               VARCHAR2(200),
    rank_acuity              NUMBER,
    id_episode               NUMBER(24),
    id_patient               NUMBER(24),
    dt_server                VARCHAR2(32),
    pat_age                  VARCHAR2(50),
    gender                   VARCHAR2(200),
    photo                    VARCHAR2(4000),
    name_pat                 VARCHAR2(200),
    num_clin_record          VARCHAR2(12),
    attaches                 NUMBER,
    transfer_req_time        VARCHAR2(4000),
    dt_begin                 VARCHAR2(4000),
    inp_admission_time       VARCHAR2(4000),
    disch_pend_time          VARCHAR2(4000),
    disch_time               VARCHAR2(4000),
    dt_follow_up_date        VARCHAR2(4000),
    label_follow_up_date     VARCHAR2(4000),
    hour_mask_follow_up_date VARCHAR2(4000),
    date_mask_follow_up_date VARCHAR2(4000),
    rank                     VARCHAR2(4000),
    flg_cancel               VARCHAR2(1),
    color_dt_begin           VARCHAR2(10)
);
CREATE OR REPLACE TYPE t_coll_patcriteriaactiveadmin AS TABLE OF t_rec_patcriteriaactiveadmin;
-- END



-- CHANGED BY: Thiago Brito
-- CHANGE DATE: 29-JUL-2008
-- CHANGE REASON: WO-14892

GRANT SELECT ON ALERT.PAT_PHOTO TO ALERT_VIEWER;

GRANT UPDATE ON ALERT.PAT_PHOTO TO ALERT_VIEWER;

GRANT INSERT ON ALERT.PAT_PHOTO TO ALERT_VIEWER;

GRANT DELETE ON ALERT.PAT_PHOTO TO ALERT_VIEWER;

-- END

-- CHANGED BY: Orlando Antunes
-- CHANGED DATE: 2008-AUG-06
-- CHANGING REASON:  alteração da coluna da quantidade requisitada nos relatos
create table pat_medication_list_bckp as (select * from pat_medication_list);

alter table pat_medication_list add quantity_2 number(24,4);

update pat_medication_list p set p.quantity_2 = p.quantity; 

alter table pat_medication_list drop column quantity;

alter table pat_medication_list rename column quantity_2 to quantity;
-- CHANGE END

-- CHANGED BY: Fábio Oliveira 
-- CHANGE DATE: 2008-AGO-27
-- CHANGE REASON: [WO16593] Mostrar informação de via verde para os vários resultados da pesquisa dos técnicos de imagem e de outros exames
drop type t_coll_episactiveitech force;
CREATE OR REPLACE TYPE t_rec_episactiveitech AS OBJECT
(
    rank              NUMBER,
    acuity            VARCHAR2(240),
    rank_acuity       NUMBER,
    epis_type         VARCHAR2(4000),
    dt_first_obs      VARCHAR2(4000),
    desc_patient      VARCHAR2(200),
    id_patient        NUMBER(24),
    id_episode        NUMBER(24),
    dt_server         VARCHAR2(4000),
    desc_exam         VARCHAR2(200),
    col_execute       VARCHAR2(4000),
    col_complete      VARCHAR2(4000),
    fast_track_icon   VARCHAR2(100),
    fast_track_color  VARCHAR2(240),
    fast_track_status VARCHAR2(1),
    fast_track_desc   VARCHAR2(4000)
);
CREATE OR REPLACE TYPE t_coll_episactiveitech AS TABLE OF t_rec_episactiveitech;
-- CHANGE END

-- CHANGED BY: Fábio Oliveira 
-- CHANGE DATE: 2008-AGO-27
-- CHANGE REASON: [WO15997] Adaptar o ecrã de pesquisa do técnico de outros exames para se comportar como o ecrã principal desse perfil
drop type t_coll_episactiveitech force;
CREATE OR REPLACE TYPE t_rec_episactiveitech AS OBJECT
(
    rank              NUMBER,
    acuity            VARCHAR2(240),
    rank_acuity       NUMBER,
    epis_type         VARCHAR2(4000),
    dt_first_obs      VARCHAR2(4000),
    desc_patient      VARCHAR2(200),
    id_patient        NUMBER(24),
    gender            VARCHAR2(200),
    pat_age           VARCHAR2(50),
    photo             VARCHAR2(4000),
    num_clin_record   VARCHAR2(12),
    id_episode        NUMBER(24),
    dt_server         VARCHAR2(4000),
    dt_target         VARCHAR2(4000),
    desc_exam         VARCHAR2(200),
    col_execute       VARCHAR2(4000),
    col_complete      VARCHAR2(4000),
    flg_result        VARCHAR2(1),
    dept              VARCHAR2(4000),
    fast_track_icon   VARCHAR2(100),
    fast_track_color  VARCHAR2(240),
    fast_track_status VARCHAR2(1),
    fast_track_desc   VARCHAR2(4000)
);
CREATE OR REPLACE TYPE t_coll_episactiveitech AS TABLE OF t_rec_episactiveitech;
-- CHANGE END

--INPATIENT Ricardo Nuno Almeida 2008-09-30
-- Tabelas desnecessárias
DROP TABLE WL_DEMO_MOVIE;
DROP TABLE WL_PATIENT_SONHO_IMP;
-- END


-- INPATIENT LMAIA 30-09-2008
-- Apagada a tabela depracated "bed_schedule"
DROP table bed_schedule;
-- END


-- Preenche campo ID_VISIT e ID_PATIENT da tabela NURSE_TEA_REQ.
-- Desnormalização
-- Created on 29/09/2008 by Luís.Maia
DECLARE
    l_error_title      VARCHAR2(4000);
    l_num_rows         NUMBER;

BEGIN
    
    l_num_rows := 0;
      
      FOR c_ntr IN (SELECT ntr.id_nurse_tea_req, epi.id_episode, vis.id_visit, vis.id_patient
                                   FROM nurse_tea_req ntr, episode epi, visit vis
                                  WHERE ntr.id_episode = epi.id_episode
                                                         AND epi.id_visit = vis.id_visit
                                                   order by ntr.id_nurse_tea_req
                                                   )
    LOOP
        l_error_title := 'UPDATE NURSE_TEA_REQ id_nurse_tea_req = ' || c_ntr.id_nurse_tea_req;
    
        UPDATE nurse_tea_req ntr
           SET ntr.id_visit = c_ntr.id_visit, ntr.id_patient = c_ntr.id_patient
         WHERE ntr.id_nurse_tea_req = c_ntr.id_nurse_tea_req
           AND ntr.id_episode = c_ntr.id_episode;
            
            l_num_rows := l_num_rows + 1;
    
    END LOOP;
      
      DBMS_OUTPUT.put_line('Rows actualizadas = ' || l_num_rows);

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Incident 10203 - ' || l_error_title || ' - ' || SQLERRM);
END;
/
-- END


-- INPATIENT LMAIA 30-09-2008
-- Depois de executado o script de migração de dados é possível colocar as 2 colunas criadas a "NOT NULL"
alter table nurse_tea_req modify id_visit not null;
alter table nurse_tea_req modify id_patient not null;
-- END

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 08-10-2008
-- CHANGE REASON: preencher nova coluna dep_type a partir da sch_event_type e drop desta
update sch_event e
set dep_type = (select flg_dep_type from sch_event_type where id_sch_event = e.id_sch_event and rownum = 1);

drop table sch_event_type;
--END


-- CHANGED BY: Joana Barroso
-- CHANGED DATE: 2008-OCT-15
-- CHANGED REASON: Desnormalização Diagnósticos de Enfermagem

DECLARE
    l_ret BOOLEAN;
BEGIN
    l_ret := pk_data_gov_admin.admin_icnp_epis_diagnosis(i_validate_table => FALSE, i_recreate_table => TRUE);
END;
/

ALTER TABLE icnp_epis_diagnosis modify id_visit NOT NULL;
ALTER TABLE icnp_epis_diagnosis modify id_patient NOT NULL;
ALTER TABLE icnp_epis_diagnosis modify id_epis_type NOT NULL;
ALTER TABLE icnp_epis_diagnosis modify flg_executions NOT NULL;

-- CHANGE END


-- Preenche campo ID_VISIT e ID_PATIENT da tabela NURSE_TEA_REQ.
-- Desnormalização dos Ensinos de Enfermagem
-- Created on 15/10/2008 by Luís.Maia
DECLARE
    l_ret BOOLEAN;
BEGIN
    l_ret := pk_data_gov_admin.admin_nurse_tea_req(i_validate_table => FALSE, i_recreate_table => TRUE);
END;
/

-- Depois de executado o script de migração de dados é possível colocar as 2 colunas criadas a "NOT NULL"
alter table nurse_tea_req modify id_visit not null;
alter table nurse_tea_req modify id_patient not null;
-- END

-- CHANGED BY: THIAGO BRITO
-- CHANGE DATE: 2008-OCT-21
CREATE OR REPLACE FUNCTION IS_DATE(I_DATE VARCHAR2) RETURN BOOLEAN IS
    dt DATE;
BEGIN
    dt := to_date(I_DATE);
    RETURN TRUE;
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
--
-- CHANGE END
--


-- CHANGED BY: Joao Sa 
-- CHANGE DATE: 2008-10-22
-- CHANGE REASON: Denormalization: Drop columns 
alter table P1_EXTERNAL_REQUEST drop column ID_PROF_REDIRECTED;
alter table P1_EXTERNAL_REQUEST drop column DT_EFECTIV_TSTZ;
alter table P1_EXTERNAL_REQUEST drop column DT_SCHEDULE_TSTZ;
alter table P1_EXTERNAL_REQUEST drop column ID_PROF_SCHEDULE;



-- CHANGED BY: THIAGO BRITO
-- CHANGE DATE: 11-11-2008
-- CHANGE REASON: ALERT-8622

ALTER TABLE patient drop CONSTRAINT gender_domain;

ALTER TABLE patient add CONSTRAINT gender_domain CHECK(gender IN ('M', 'F', 'I') OR gender IS NULL);

-- CHANGE END


-- Preenche campo ID_VISIT e ID_PATIENT da tabela NURSE_TEA_REQ.
-- Desnormalização dos Ensinos de Enfermagem
-- Created on 15/10/2008 by Luís.Maia
ALTER TABLE icnp_epis_diagnosis modify id_visit NOT NULL;
ALTER TABLE icnp_epis_diagnosis modify id_patient NOT NULL;
ALTER TABLE icnp_epis_diagnosis modify id_epis_type NOT NULL;
ALTER TABLE icnp_epis_diagnosis modify flg_executions NOT NULL;

-- Depois de executado o script de migração de dados é possível colocar as 2 colunas criadas a "NOT NULL"
alter table nurse_tea_req modify id_visit not null;
alter table nurse_tea_req modify id_patient not null;
-- CHANGE END

-- CHANGED BY: Patrícia Neto
-- CHANGED DATE: 2009-JAN-15
-- CHANGING REASON: CASO O ID_PROFESIONAL ESTEJA A NULL AS ACÇÕES DA ACTION SURGEM IMCOMPLETAS
UPDATE PRESCRIPTION_TYPE_ACCESS SET ID_PROFESSIONAL =0
WHERE ID_PREFESSIONAL IS NULL;
/
alter table PRESCRIPTION_TYPE_ACCESS modify ID_PROFESSIONAL null;  
/
-- CHANGE END Patrícia Neto

-- CHANGED BY: Patrícia Neto
-- CHANGED DATE: 2009-JAN-15
-- CHANGING REASON: CASO O ID_PROFESIONAL ESTEJA A NULL AS ACÇÕES DA ACTION SURGEM IMCOMPLETAS
UPDATE PRESCRIPTION_TYPE_ACCESS SET ID_PROFESSIONAL =0
WHERE ID_PREFESSIONAL IS NULL;
/
alter table PRESCRIPTION_TYPE_ACCESS modify ID_PROFESSIONAL not null;  
/
-- CHANGE END Patrícia Neto

-- CHANGED BY: Patrícia Neto
-- CHANGED DATE: 2009-JAN-15
-- CHANGING REASON: CASO O ID_PROFESIONAL ESTEJA A NULL AS ACÇÕES DA ACTION SURGEM IMCOMPLETAS
UPDATE PRESCRIPTION_TYPE_ACCESS SET ID_PROFESSIONAL =0
WHERE ID_PROFESSIONAL IS NULL;
/
alter table PRESCRIPTION_TYPE_ACCESS modify ID_PROFESSIONAL not null;  
/
-- CHANGE END Patrícia Neto         


-- RicardoNunoAlmeida
-- 04-02-2009
-- ALERT-16420 : Refactoring epis_type_soft_inst's logic
ALTER TABLE epis_type_soft_inst 
add CONSTRAINT ETSI_ID_SOFTWARE_CHK CHECK ( id_software != 0 );
/
--END RNA;




-- RicardoNunoAlmeida
-- 05-02-2009
-- ALERT-16420 : Refactoring epis_type_soft_inst's logic
BEGIN
        DELETE FROM epis_type_soft_inst;
                
        insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
        values (1, 1, 0);

        insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
        values (2, 8, 0);

        insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
        values (4, 2, 0);

        insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
        values (5, 11, 0);

        insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
        values (8, 3, 0);

        insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
        values (9, 29, 0);

        insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
        values (10, 3, 0);

        insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
        values (11, 12, 0);

        insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
        values (14, 3, 0);

        insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
        values (15, 36, 0);

        insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
            values (16, 1, 0);

            insert into epis_type_soft_inst (ID_EPIS_TYPE, ID_SOFTWARE, ID_INSTITUTION)
            values (17, 12, 0);
END;
/
--END RNA



-- RicardoNunoAlmeida
-- 05-02-2009
-- ALERT-16420 : Refactoring epis_type_soft_inst's logic
ALTER TABLE epis_type_soft_inst 
add CONSTRAINT ETSI_ID_SOFTWARE_CHK CHECK ( id_software != 0 );
/
--END RNA;

-- CHANGED BY: Patrícia Neto
-- CHANGED DATE: 2009-FEV-02
-- CHANGING REASON:  CONTRA-INDICAÇÕES E INTERACÇÕES MEDICAMENTOSAS
---------------- mi_med_atc_interaction  
-- 1
CREATE TABLE MI_MED_ATC_INTERACTION_0210 AS (SELECT * FROM MI_MED_ATC_INTERACTION where vers ='USA');
-- 2
delete MI_MED_ATC_INTERACTION;
-- 3
alter table MI_MED_ATC_INTERACTION
  drop constraint MI_MED_ATC_INTERACTION_PK cascade;
drop index MI_MED_ATC_INTERACTION_PK;
alter table MI_MED_ATC_INTERACTION
  add constraint MI_MED_ATC_INTERACTION_PK primary key (ID_DRUG, DDI, VERS);
-- 4  
alter table MI_MED_ATC_INTERACTION modify ATCD null; 
alter table MI_MED_ATC_INTERACTION modify ATCDESCD null;  

   
---------------------------------------------------------------------------------------------------------------------------------------------------------  
---------------- me_med_atc_interaction  
-- 1
CREATE TABLE ME_MED_ATC_INTERACTION_0210 AS (SELECT * FROM ME_MED_ATC_INTERACTION where vers = 'USA');
-- 2  
delete ME_MED_ATC_INTERACTION;
-- 3
alter table ME_MED_ATC_INTERACTION
  drop constraint ME_MED_ATC_INTERACTION_PK cascade;
 drop index ME_MED_ATC_INTERACTION_PK; 
alter table ME_MED_ATC_INTERACTION
  add constraint ME_MED_ATC_INTERACTION_PK primary key (EMB_ID, DDI, VERS);  
-- 4
alter table ME_MED_ATC_INTERACTION modify ATCD null; 
alter table ME_MED_ATC_INTERACTION modify ATCDESCD null;  

---------------------------------------------------------------------------------------------------------------------------------------------------------      
------------- mi_dxid_atc_contra  
-- 1
CREATE TABLE MI_DXID_ATC_CONTRA_0210 AS (SELECT * FROM MI_DXID_ATC_CONTRA where vers = 'USA');
-- 2
DELETE MI_DXID_ATC_CONTRA;
-- 3
alter table MI_DXID_ATC_CONTRA
  drop constraint MI_DXID_ATC_CONTRA_PK cascade;
drop index MI_DXID_ATC_CONTRA_PK;
alter table MI_DXID_ATC_CONTRA
  add constraint MI_DXID_ATC_CONTRA_PK primary key (DXID, ID_DRUG, DDXCN_SL, DDXCN_SN, VERS);
-- 4
alter table MI_DXID_ATC_CONTRA modify ATC null; 
alter table MI_DXID_ATC_CONTRA modify ATC_DESC null;

---------------------------------------------------------------------------------------------------------------------------------------------------------      
------------- me_dxid_atc_contra  
-- 1
CREATE TABLE ME_DXID_ATC_CONTRA_0210 AS (SELECT * FROM ME_DXID_ATC_CONTRA where vers ='USA');
-- 2 
DELETE ME_DXID_ATC_CONTRA;
-- 3 
alter table ME_DXID_ATC_CONTRA
  drop constraint ME_DXID_ATC_CONTRA_PK cascade;
drop index ME_DXID_ATC_CONTRA_PK;
alter table ME_DXID_ATC_CONTRA
  add constraint ME_DXID_ATC_CONTRA_PK primary key (DXID, EMB_ID, DDXCN_SL, DDXCN_SN, VERS); 
  
alter table ME_DXID_ATC_CONTRA modify ATC null; 
alter table ME_DXID_ATC_CONTRA modify ATC_DESC null;  
-- CHANGE END Patrícia Neto


-- CHANGED BY: Patrícia Neto
-- CHANGED DATE: 2009-JAN-13
-- CHANGING REASON:  CONTRA-INDICAÇÕES E INTERACÇÕES MEDICAMENTOSAS
---------------- mi_med_atc_interaction  
-- 1
CREATE TABLE MI_MED_ATC_INTERACTION_0210 AS (SELECT * FROM MI_MED_ATC_INTERACTION where vers ='USA');
-- 2
delete MI_MED_ATC_INTERACTION;
-- 3
alter table MI_MED_ATC_INTERACTION
  add constraint MI_MED_ATC_INTERACTION_PK primary key (ID_DRUG, DDI, VERS);
-- 4  
alter table MI_MED_ATC_INTERACTION modify ATCD null; 
alter table MI_MED_ATC_INTERACTION modify ATCDESCD null;  

   
---------------------------------------------------------------------------------------------------------------------------------------------------------  
---------------- me_med_atc_interaction  
-- 1
CREATE TABLE ME_MED_ATC_INTERACTION_0210 AS (SELECT * FROM ME_MED_ATC_INTERACTION where vers = 'USA');
-- 2  
delete ME_MED_ATC_INTERACTION;
COMMIT;
/
-- 3
alter table ME_MED_ATC_INTERACTION
  drop constraint ME_MED_ATC_INTERACTION_PK cascade;
 --drop index ME_MED_ATC_INTERACTION_PK; 
alter table ME_MED_ATC_INTERACTION
  add constraint ME_MED_ATC_INTERACTION_PK primary key (EMB_ID, DDI, VERS);  
-- 4
alter table ME_MED_ATC_INTERACTION modify ATCD null; 
alter table ME_MED_ATC_INTERACTION modify ATCDESCD null;  

---------------------------------------------------------------------------------------------------------------------------------------------------------      
------------- mi_dxid_atc_contra  
-- 1
CREATE TABLE MI_DXID_ATC_CONTRA_0210 AS (SELECT * FROM MI_DXID_ATC_CONTRA where vers = 'USA');
-- 2
DELETE MI_DXID_ATC_CONTRA;
COMMIT;
/
-- 3
alter table MI_DXID_ATC_CONTRA
  drop constraint MI_DXID_ATC_CONTRA_PK cascade;
--drop index MI_DXID_ATC_CONTRA_PK;
alter table MI_DXID_ATC_CONTRA
  add constraint MI_DXID_ATC_CONTRA_PK primary key (DXID, ID_DRUG, DDXCN_SL, DDXCN_SN, VERS);
-- 4
alter table MI_DXID_ATC_CONTRA modify ATC null; 
alter table MI_DXID_ATC_CONTRA modify ATC_DESC null;

---------------------------------------------------------------------------------------------------------------------------------------------------------      
------------- me_dxid_atc_contra  
-- 1
CREATE TABLE ME_DXID_ATC_CONTRA_0210 AS (SELECT * FROM ME_DXID_ATC_CONTRA where vers ='USA');
-- 2 
DELETE ME_DXID_ATC_CONTRA;
COMMIT;
/
-- 3 
alter table ME_DXID_ATC_CONTRA
  drop constraint ME_DXID_ATC_CONTRA_PK cascade;
--drop index ME_DXID_ATC_CONTRA_PK;
alter table ME_DXID_ATC_CONTRA
  add constraint ME_DXID_ATC_CONTRA_PK primary key (DXID, EMB_ID, DDXCN_SL, DDXCN_SN, VERS); 
  
alter table ME_DXID_ATC_CONTRA modify ATC null; 
alter table ME_DXID_ATC_CONTRA modify ATC_DESC null;  
-- CHANGE END Patrícia Neto


-- CHANGED BY: Pedro Santos
-- CHANGED DATE: 2009-FEB-12
-- CHANGE REASON: ALERT-17114
begin
delete from sys_alert_prof sap where sap.id_profile_template =100 and sap.id_sys_alert in (7,8,11,16,17);
delete from sys_alert_prof sap where sap.id_profile_template =105 and sap.id_sys_alert in (7,8,11,16,17);
delete from sys_alert_config sac where sac.id_software = 2 and sac.id_profile_template=100 and sac.id_sys_alert in (7,8,11,16,17);
delete from sys_alert_config sac where sac.id_software = 2 and sac.id_profile_template=105 and sac.id_sys_alert in (7,8,11,16,17);
end;
/
-- CHANGE END

-- CHANGED BY: Pedro Santos
-- CHANGE DATE: 2009-FEB-27
-- CHANGE REASON: ALERT-16467 - acrescentar id_sr_epis_interv à sr_epis_interv_desc
DECLARE
    l_count       NUMBER := 0;
    l_error_title VARCHAR2(4000);
    l_count_total NUMBER := 0;
    CURSOR c_sr_epis_interv IS
        SELECT sei.id_sr_epis_interv       id_sr_epis_interv,
               seid.id_sr_epis_interv_desc id_sr_epis_interv_desc,
               sei.id_sr_intervention      sei_id_sr_intervention,
               seid.id_sr_intervention     seid_id_sr_intervention,
               sei.id_episode              sei_id_episode,
               seid.id_episode             seid_id_episode,
               sei.flg_status              sei_status,
               seid.flg_status             seid_status,
               sei.dt_cancel_tstz          sei_cancel,
               seid.dt_cancel_tstz         seid_cancel,
               seid.id_sr_epis_interv      seid_id_sr_epis_interv
          FROM sr_epis_interv_desc seid, sr_epis_interv sei
         WHERE sei.id_episode = seid.id_episode
           AND sei.id_sr_intervention = seid.id_sr_intervention;

BEGIN

    SELECT COUNT(*)
      INTO l_count_total
      FROM sr_epis_interv_desc seid;

    FOR r_srei IN c_sr_epis_interv
    LOOP
        l_error_title := 'UPDATE SR_EPIS_INTERV_DESC id_sr_epis_interv_desc = ' || r_srei.id_sr_epis_interv_desc;
        CASE
            WHEN r_srei.seid_id_sr_epis_interv IS NOT NULL THEN
                NULL;
            ELSE
                CASE
                    WHEN (r_srei.seid_status = 'A' AND r_srei.sei_status != 'C') THEN
                        UPDATE sr_epis_interv_desc seid
                           SET seid.id_sr_epis_interv = r_srei.id_sr_epis_interv
                         WHERE seid.id_sr_epis_interv_desc = r_srei.id_sr_epis_interv_desc;
                        l_count := l_count + 1;
                    WHEN (r_srei.seid_status = 'C' AND r_srei.sei_status = 'C') THEN
                        IF r_srei.seid_cancel = r_srei.sei_cancel
                        THEN
                            UPDATE sr_epis_interv_desc seid
                               SET seid.id_sr_epis_interv = r_srei.id_sr_epis_interv
                             WHERE seid.id_sr_epis_interv_desc = r_srei.id_sr_epis_interv_desc;
                            l_count := l_count + 1;
                        END IF;
                    ELSE
                        NULL;
                END CASE;
        END CASE; END LOOP;

    dbms_output.put_line('Updated rows - ' || l_count || '/' || l_count_total);
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error - ' || l_error_title || ' - ' || SQLERRM);
END;
/

-- colocar flag na SR_EPIS_INTERV

DECLARE
    l_count       NUMBER := 0;
    l_error_title VARCHAR2(4000);
    l_count_total NUMBER := 0;
    CURSOR c_sr_epis_interv IS
        SELECT sei.id_sr_epis_interv  id_sr_epis_interv,
               sei.id_sr_intervention id_sr_intervention,
               sei.name_interv        name_interv,
               sei.flg_code_type      flg_code_type
          FROM sr_epis_interv sei;

BEGIN
    SELECT COUNT(*)
      INTO l_count_total
      FROM sr_epis_interv sei;

    FOR r_srei IN c_sr_epis_interv
    LOOP
        l_error_title := 'UPDATE SR_EPIS_INTERV id_sr_epis_interv = ' || r_srei.id_sr_epis_interv;
        CASE
            WHEN (r_srei.flg_code_type IS NOT NULL) THEN
                NULL;
            ELSE
            
                CASE
                    WHEN (r_srei.id_sr_intervention IS NOT NULL) THEN
                        UPDATE sr_epis_interv sei
                           SET sei.flg_code_type = 'C'
                         WHERE sei.id_sr_epis_interv = r_srei.id_sr_epis_interv;
                        l_count := l_count + 1;
                    WHEN (r_srei.id_sr_intervention IS NULL AND r_srei.name_interv IS NOT NULL) THEN
                        UPDATE sr_epis_interv sei
                           SET sei.flg_code_type = 'U'
                         WHERE sei.id_sr_epis_interv = r_srei.id_sr_epis_interv;
                        l_count := l_count + 1;
                    
                    ELSE
                        UPDATE sr_epis_interv sei
                           SET sei.flg_code_type = 'C'
                         WHERE sei.id_sr_epis_interv = r_srei.id_sr_epis_interv;
                        l_count := l_count + 1;
                END CASE;
        END CASE; END LOOP;

    dbms_output.put_line('Updated rows - ' || l_count || '/' || l_count_total);
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('Error - ' || l_error_title || ' - ' || SQLERRM);
END;
/
-- CHANGE END

-- CHANGED BY: Alexandre Santos
-- CHANGED DATE: 2009-Mar-18
-- JIRA: ALERT-18472

CREATE TABLE TRIAGE_N_CONSID_20090227 AS
      SELECT *
         FROM triage_n_consid tnc
       WHERE tnc.id_triage_board IN (SELECT t.id_triage_board
                                                       FROM triage t
                                                      WHERE t.id_triage_type = 4);

DELETE FROM triage_n_consid tnc
 WHERE tnc.id_triage_board IN (SELECT t.id_triage_board
                                 FROM triage t
                                WHERE t.id_triage_type = 4);

--CHANGE END

-- CHANGED BY: Alexandre Santos
-- CHANGED DATE: 2009-Mar-18
-- JIRA: ALERT-18996

CREATE TABLE TRIAGE_N_CONSID_20090227 AS
      SELECT *
         FROM triage_n_consid tnc
       WHERE tnc.id_triage_board IN (SELECT t.id_triage_board
                                                       FROM triage t
                                                      WHERE t.id_triage_type = 4);

DELETE FROM triage_n_consid tnc
 WHERE tnc.id_triage_board IN (SELECT t.id_triage_board
                                 FROM triage t
                                WHERE t.id_triage_type = 4);

--CHANGE END

-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 20-03-2009
-- CHANGE REASON: [ALERT-18455] Patient tracking development
CREATE OR REPLACE TYPE t_rec_patcriteriaactiveclin AS OBJECT
(
    acuity               VARCHAR2(240),
    color_text           VARCHAR2(200),
    rank_acuity          NUMBER,
    num_clin_record      VARCHAR2(100),
    id_episode           NUMBER(24),
    id_patient           NUMBER(24),
    name_pat             VARCHAR2(200),
    gender               VARCHAR2(200),
    pat_age              VARCHAR2(50),
    pat_age_for_order_by NUMBER(24),
    photo                VARCHAR2(4000),
    care_stage           VARCHAR2(4000),
    prof_team            VARCHAR2(4000),
    cons_type            VARCHAR2(4000),
    name_prof            VARCHAR2(200),
    name_nurse           VARCHAR2(200),
    dt_server            VARCHAR2(32),
    dt_begin             VARCHAR2(4000),
    dt_first_obs         VARCHAR2(4000),
    date_send            VARCHAR2(4000),
    dt_efectiv           VARCHAR2(4000),
    flg_temp             VARCHAR2(1),
    desc_temp            VARCHAR2(1),
    img_transp           VARCHAR2(200),
    desc_room            VARCHAR2(4000),
    desc_drug_presc      VARCHAR2(200),
    desc_interv_presc    VARCHAR2(200),
    desc_monitorization  VARCHAR2(200),
    desc_movement        VARCHAR2(200),
    desc_analysis_req    VARCHAR2(200),
    desc_exam_req        VARCHAR2(200),
    desc_harvest         VARCHAR2(200),
    desc_drug_transp     VARCHAR2(200),
    desc_epis_anamnesis  VARCHAR2(4000),
    desc_spec_prof       VARCHAR2(4000),
    desc_spec_nurse      VARCHAR2(4000),
    desc_disch_pend_time VARCHAR2(200),
    flg_cancel           VARCHAR2(1),
    fast_track_icon      VARCHAR2(100),
    fast_track_color     VARCHAR2(240),
    fast_track_status    VARCHAR2(1),
    fast_track_desc      VARCHAR2(4000)
);
CREATE OR REPLACE TYPE t_coll_patcriteriaactiveclin AS TABLE OF t_rec_patcriteriaactiveclin;

-- CHANGE END: Fábio Oliveira

-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2009-JAN-25
-- CHANGED REASON: ALERT-19420
CREATE OR REPLACE TYPE t_coll_p1_export_data AS table of t_rec_p1_export_data;
/
-- CHANGE END: Ana Monteiro


-- José Brito 19/02/2009 ALERT-13986
-- Verificação dos acessos aos botões da barra inferior
CREATE TABLE profile_templ_access_20090219 AS(
    SELECT pta.*
      FROM profile_template p, profile_templ_access pta, sys_button_prop sbp, sys_button sb
     WHERE pta.id_profile_template = p.id_profile_template
       AND sb.id_sys_button = sbp.id_sys_button
       AND pta.id_sys_button_prop = sbp.id_sys_button_prop
       AND p.id_software IN (8, 29, 32, 33, 35)
       AND p.id_profile_template NOT IN (404, 407, 454)
       AND (sbp.id_sys_screen_area IN (4, 5) OR
           (sbp.id_sys_screen_area = 3 AND NOT EXISTS
            (SELECT 0
                FROM sys_button_prop s1
               WHERE s1.id_btn_prp_parent = sbp.id_sys_button_prop)))
       AND sbp.action IS NULL
       AND (sbp.id_btn_prp_parent IS NOT NULL AND
           'Y' = (SELECT sbp2.flg_visible
                     FROM sys_button_prop sbp2
                    WHERE sbp2.id_sys_button_prop = sbp.id_btn_prp_parent) OR sbp.id_btn_prp_parent IS NULL)
       AND (pta.flg_create IS NULL OR pta.flg_cancel IS NULL OR pta.flg_ok IS NULL OR pta.flg_detail IS NULL OR
           pta.flg_help IS NULL));
-- END


-- CHANGED BY: Sérgio Cunha
-- CHANGED DATE: 2009-MAR-26
-- CHANGED REASON: ALERT-19156

DECLARE

    CURSOR c_user_pass IS
        SELECT f.id_user, f.pass_user, f.pass_user_2, f.pass_user_3, f.pass_user_4, f.pass_user_5
          FROM finger_db.sys_user f;

    l_error_title VARCHAR2(4000);
    l_counter     NUMBER;

BEGIN

    FOR fc IN c_user_pass
    LOOP
        l_counter := 0;
        IF fc.pass_user_5 IS NOT NULL
        THEN
            l_counter     := l_counter + 1;
            l_error_title := 'INSERT PASSWD_HIST PASS_5';
            INSERT INTO passwd_hist
                (id_user, entry_seq, password, create_time)
            VALUES
                (fc.id_user, l_counter, fc.pass_user_5, current_timestamp);
        END IF;
    
        IF fc.pass_user_4 IS NOT NULL
        THEN
            l_counter     := l_counter + 1;
            l_error_title := 'INSERT PASSWD_HIST PASS_4';
            INSERT INTO passwd_hist
                (id_user, entry_seq, password, create_time)
            VALUES
                (fc.id_user, l_counter, fc.pass_user_4, current_timestamp);
        END IF;
    
        IF fc.pass_user_3 IS NOT NULL
        THEN
            l_counter     := l_counter + 1;
            l_error_title := 'INSERT PASSWD_HIST PASS_3';
            INSERT INTO passwd_hist
                (id_user, entry_seq, password, create_time)
            VALUES
                (fc.id_user, l_counter, fc.pass_user_3, current_timestamp);
        END IF;
    
        IF fc.pass_user_2 IS NOT NULL
        THEN
            l_counter     := l_counter + 1;
            l_error_title := 'INSERT PASSWD_HIST PASS_2';
            INSERT INTO passwd_hist
                (id_user, entry_seq, password, create_time)
            VALUES
                (fc.id_user, l_counter, fc.pass_user_2, current_timestamp);
        END IF;
    
        IF fc.pass_user IS NOT NULL
        THEN
            l_counter     := l_counter + 1;
            l_error_title := 'INSERT PASSWD_HIST PASS';
            INSERT INTO passwd_hist
                (id_user, entry_seq, password, create_time)
            VALUES
                (fc.id_user, l_counter, fc.pass_user, current_timestamp);
        END IF;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line(l_error_title || ' - ' || SQLERRM);
    
END;
/

-- CHANGE END: Sérgio Cunha


-- CHANGED BY: Rui Marante
-- CHANGED DATE: 2009-MAR-30
-- CHANGED REASON: ALERT-21602

alter table drug_req_det
add id_state number(4) default 0 not null;

update drug_req_det drd
set drd.id_state = pk_medication_workflow.get_id_state_from_old_flag(1, drd.flg_status);

commit;

--FK
alter table drug_req_det
add constraint drug_req_det_state_fk foreign key (id_state)
references wfl_state (id_state);


alter table drug_req_supply
add id_state number(4) default 0 not null;

update drug_req_supply drs
set drs.id_state = pk_medication_workflow.get_id_state_from_old_flag(2, drs.flg_status);

commit;

--FK
alter table drug_req_supply
add constraint drug_req_sup_state_fk foreign key (id_state)
references wfl_state (id_state);


--popular a tabela de transicoes
insert into drug_req_det_state_transition (id_drug_req_det, id_state, id_prof, dt_state, notes, old_flg_status)
--canceled
select drd.id_drug_req_det, pk_medication_workflow.get_id_state_from_old_flag(1, 'C'), drd.id_prof_cancel, drd.dt_cancel_tstz, drd.notes_cancel, 'C'
from drug_req_det drd
where drd.id_prof_cancel is not null
union all
--pending
select drd.id_drug_req_det, pk_medication_workflow.get_id_state_from_old_flag(1, 'D'), drd.id_prof_pending, drd.dt_pending_tstz, drd.notes_pending, 'D'
from drug_req_det drd
where drd.id_prof_pending is not null
union all
--requested
select drd.id_drug_req_det, pk_medication_workflow.get_id_state_from_old_flag(1, 'R'), drd.id_prof_order, drd.dt_order, drd.notes, 'R'
from drug_req_det drd
where drd.id_prof_order is not null and drd.flg_status != 'T';

commit;

-- CHANGE END: Rui Marante


--Ricardo Nuno Almeida
--24-03-2009
--ALERT-21226
ALTER TABLE WL_PATIENT_SONHO_TRANSFERED
ADD ID_WL_PATIENT_SONHO_TRANSFERED NUMBER;

UPDATE wl_patient_sonho_transfered w
SET w.id_wl_patient_sonho_transfered = seq_wl_pat_sonho_transfered.nextval;

--END;


-- CHANGED BY: Rui Spratley
-- CHANGED DATE: 2009-APR-15
-- CHANGED REASON: ALERT-21602
drop table ALERT_DIAGNOSIS_BCK_20080409 cascade constraints;
drop table ANALYSIS_AGP_OLD cascade constraints;
drop table ANALYSIS_DEP_CLIN_SERV_OLD cascade constraints;
drop table ANALYSIS_OLD cascade constraints;
drop table ANALYSIS_PROTOCOLS_OLD cascade constraints;
drop table AQUA_EXPLAIN_TABLE cascade constraints;
drop table COMPLAINT_DIAGNOSIS cascade constraints;
drop table COMPLAINT_TEMPLATE cascade constraints;
drop table CONC_SESSION_TEMP cascade constraints;
drop table DIAGNOSIS_BCK_20080409 cascade constraints;
drop table DIAGNOSIS_DCS_BCK_20080409 cascade constraints;
drop table DIAG_MAP_LOG cascade constraints;
drop table DIF_DRUG_UNIT cascade constraints;
drop table DIF_FORM_FARM_UNIT cascade constraints;
drop table DIF_ICD9_DXID cascade constraints;
drop table DIF_ME_DIETARY cascade constraints;
drop table DIF_ME_DXID_ATC_CONTRA cascade constraints;
drop table DIF_ME_INGRED cascade constraints;
drop table DIF_ME_MANIP cascade constraints;
drop table DIF_ME_MANIP_GROUP cascade constraints;
drop table DIF_ME_MANIP_INGRED cascade constraints;
drop table DIF_ME_MED cascade constraints;
drop table DIF_ME_MED_ATC cascade constraints;
drop table DIF_ME_MED_ATC_INTERACTION cascade constraints;
drop table DIF_ME_MED_PHARM_GROUP cascade constraints;
drop table DIF_ME_MED_REGULATION cascade constraints;
drop table DIF_ME_MED_ROUTE cascade constraints;
drop table DIF_ME_MED_SUBST cascade constraints;
drop table DIF_ME_PHARM_GROUP cascade constraints;
drop table DIF_ME_REGULATION cascade constraints;
drop table DIF_ME_ROUTE cascade constraints;
drop table DIF_MI_DXID_ATC_CONTRA cascade constraints;
drop table DIF_MI_JUSTIFICATION cascade constraints;
drop table DIF_MI_MED cascade constraints;
drop table DIF_MI_MED_ATC cascade constraints;
drop table DIF_MI_MED_ATC_INTERACTION cascade constraints;
drop table DIF_MI_MED_COMMERC cascade constraints;
drop table DIF_MI_MED_PHARM_GROUP cascade constraints;
drop table DIF_MI_MED_REGULATION cascade constraints;
drop table DIF_MI_PHARM_GROUP cascade constraints;
drop table DIF_MI_REGULATION cascade constraints;
drop table DIF_MI_ROUTE cascade constraints;
drop table DOCUMENTATION_TEMP cascade constraints;
drop table DOC_EXTERNAL_BCK_20080208 cascade constraints;
drop table DOC_TEMPLATE_CONTEXT_BCK_242 cascade constraints;
drop table DOC_TEMPLATE_DIAG_BCK_20080409 cascade constraints;
drop table DRUG_070920 cascade constraints;
drop table DRUG_BCKP_PN_20080124 cascade constraints;
drop table DRUG_BK_24_SET cascade constraints;
drop table DRUG_BRAND_070920 cascade constraints;
drop table DRUG_BRAND_NEW cascade constraints;
drop table DRUG_COMPOSITION_BCKP_PN_3004 cascade constraints;
drop table DRUG_DEP_CLIN_SERV_BCKUP cascade constraints;
drop table DRUG_DEP_CLIN_SERV_BK_24_SET cascade constraints;
drop table DRUG_DIPLOMA cascade constraints;
drop table DRUG_EMB cascade constraints;
drop table DRUG_FORM_070920 cascade constraints;
drop table DRUG_FORM_NEW cascade constraints;
drop table DRUG_NEW cascade constraints;
drop table DRUG_PATOL_DIP_LNK cascade constraints;
drop table DRUG_PATOL_ESP cascade constraints;
drop table DRUG_PATOL_ESP_LNK cascade constraints;
drop table DRUG_PHARMA_070920 cascade constraints;
drop table DRUG_PHARMA_CLASS_070920 cascade constraints;
drop table DRUG_PHARMA_CLASS_LINK_NEW cascade constraints;
drop table DRUG_PHARMA_CLASS_LNK_070920 cascade constraints;
drop table DRUG_PHARMA_CLASS_NEW cascade constraints;
drop table DRUG_PHARMA_NEW cascade constraints;
drop table DRUG_PRESC_DET_BK20080125 cascade constraints;
drop table DRUG_REQ_DET_BK20080125 cascade constraints;
drop table DRUG_ROUTE_070920 cascade constraints;
drop table DRUG_ROUTE_NEW cascade constraints;
drop table DRUG_UNIT_260808 cascade constraints;
drop table DRUG_UNIT_26_08_08 cascade constraints;
drop table EMB_DEP_CLIN_SERV_20080514 cascade constraints;
drop table EMB_DEP_CLIN_SERV_IT cascade constraints;
drop table EMB_DEP_CLIN_SERV_USA cascade constraints;
drop table EPISODE_20080814 cascade constraints;
drop table EPISODE_20081125152950 cascade constraints;
drop table EPISODE_20081125153726 cascade constraints;
drop table EPISODE_20081125153909 cascade constraints;
drop table EPISODE_20081125153911 cascade constraints;
drop table EPISODE_20081125153931 cascade constraints;
drop table EPISODE_20081125160418 cascade constraints;
drop table EPISODE_20081125163314 cascade constraints;
drop table EPISODE_20081125174902 cascade constraints;
drop table EPISODE_20081126152955 cascade constraints;
drop table EPIS_DIAGNOSIS_BCK_20080409 cascade constraints;
drop table EPIS_DOCUMENTATION_QUALIF_BCK cascade constraints;
drop table EPIS_INFO_20080814 cascade constraints;
drop table EPIS_INFO_20081125 cascade constraints;
drop table EPIS_INFO_20081126 cascade constraints;
drop table EPIS_INFO_20090107 cascade constraints;
drop table EPIS_INFO_20090109 cascade constraints;
drop table EPIS_INFO_20090112 cascade constraints;
drop table EXAM_TYPE_TEMPLATE_BCK cascade constraints;
drop table EXCEPTIONS_240 cascade constraints;
drop table FORM_FARM_UNIT_20090210 cascade constraints;
drop table GRID_TASK_LAB_20080606 cascade constraints;
drop table GUIDELINE_LINK_BCK_20080409 cascade constraints;
drop table GUIDE_CRIT_LINK_BCK_20080409 cascade constraints;
drop table ICD9_DXID_08072008 cascade constraints;
drop table ICD9_DXID_1703 cascade constraints;
drop table ICD9_DXID_20080702 cascade constraints;
drop table ICD9_DXID_20090210 cascade constraints;
drop table ICNP_COMPOSITION_060425 cascade constraints;
drop table ICNP_COMPO_FOLDER_060425 cascade constraints;
drop table ICNP_COMPO_INST_060425 cascade constraints;
drop table ICNP_EPIS_DIAGNOSIS_060425 cascade constraints;
drop table ICNP_EPIS_DIAGNOSIS_20081125 cascade constraints;
drop table ICNP_EPIS_DIAGNOSIS_20081126 cascade constraints;
drop table ICNP_EPIS_DIAGNOSIS_20081127 cascade constraints;
drop table ICNP_EPIS_DIAGNOSIS_20081130 cascade constraints;
drop table ICNP_EPIS_DIAG_INTERV_060425 cascade constraints;
drop table ICNP_EPIS_INTERVENTION_060425 cascade constraints;
drop table ICNP_FOLDER_060425 cascade constraints;
drop table ICNP_HELP cascade constraints;
drop table ICNP_PREDEFINED_ACTION_060425 cascade constraints;
drop table ICNP_TRANSITION_STATE_060426 cascade constraints;
drop table IMPORT_ANALYSIS cascade constraints;
drop table IMPORT_MCDT cascade constraints;
drop table IMPORT_MCDT_20060303 cascade constraints;
drop table IMPORT_MCDT_MIGRA cascade constraints;
drop table IMPORT_PROF_ADMIN cascade constraints;
drop table IMPORT_PROF_MED cascade constraints;
drop table INF_ATC_LNK_IT cascade constraints;
drop table INF_ATC_LNK_NEW cascade constraints;
drop table INF_ATC_NEW cascade constraints;
drop table INF_CFT_IT cascade constraints;
drop table INF_CFT_LNK_IT cascade constraints;
drop table INF_CFT_LNK_NEW cascade constraints;
drop table INF_CFT_NEW cascade constraints;
drop table INF_CLASS_DISP_NEW cascade constraints;
drop table INF_CLASS_ESTUP_NEW cascade constraints;
drop table INF_COMERC_NEW cascade constraints;
drop table INF_DCIPT_IT cascade constraints;
drop table INF_DCIPT_NEW cascade constraints;
drop table INF_DCIPT_USA cascade constraints;
drop table INF_DIABETES_LNK_NEW cascade constraints;
drop table INF_DIPLOMA_NEW cascade constraints;
drop table INF_DISPO_NEW cascade constraints;
drop table INF_EMB_IT cascade constraints;
drop table INF_EMB_NEW cascade constraints;
drop table INF_EMB_UNIT_NEW cascade constraints;
drop table INF_EMB_USA cascade constraints;
drop table INF_ESTADO_AIM_NEW cascade constraints;
drop table INF_FORM_FARM_NEW cascade constraints;
drop table INF_FORM_FARM_USA cascade constraints;
drop table INF_GRUPO_HOM_NEW cascade constraints;
drop table INF_MED_IT cascade constraints;
drop table INF_MED_NEW cascade constraints;
drop table INF_MED_USA cascade constraints;
drop table INF_PATOL_DIP_LNK_NEW cascade constraints;
drop table INF_PATOL_ESP_LNK_NEW cascade constraints;
drop table INF_PATOL_ESP_NEW cascade constraints;
drop table INF_PRECO_IT cascade constraints;
drop table INF_PRECO_NEW cascade constraints;
drop table INF_SUBST_LNK_NEW cascade constraints;
drop table INF_SUBST_NEW cascade constraints;
drop table INF_TIPO_DIAB_MEL_NEW cascade constraints;
drop table INF_TIPO_PRECO_NEW cascade constraints;
drop table INF_TIPO_PROD_NEW cascade constraints;
drop table INF_TITULAR_AIM_IT cascade constraints;
drop table INF_TITULAR_AIM_NEW cascade constraints;
drop table INF_TITULAR_AIM_USA cascade constraints;
drop table INF_VIAS_ADMIN_IT cascade constraints;
drop table INF_VIAS_ADMIN_LNK_IT cascade constraints;
drop table INF_VIAS_ADMIN_LNK_NEW cascade constraints;
drop table INF_VIAS_ADMIN_NEW cascade constraints;
drop table INP_ERROR cascade constraints;
drop table INP_LOG cascade constraints;
drop table INTERV_DEP_CLIN_SERV_20060303 cascade constraints;
drop table INTERV_DEP_CLIN_SERV_MIGRA cascade constraints;
drop table JAN_PROF_TEMPL_ACCESS cascade constraints;
drop table JAN_PROF_TEMPL_ACCESS_DEL cascade constraints;
drop table JAN_PROF_TEMPL_ACCESS_RID cascade constraints;
drop table JAN_PROF_TEMPL_ACCESS_UNIQUE cascade constraints;
drop table JAN_SYS_BTN_SBG cascade constraints;
drop table JAN_VIEWER_SYNCHRONIZE cascade constraints;
drop table JAN_VIEWER_SYNCH_PARAM cascade constraints;
drop table JAN_VIEW_REFRESH cascade constraints;
drop table LIXO cascade constraints;
drop table MCDT_REQ_DIAG_BCK_20080409 cascade constraints;
drop table ME_DIETARY_1703 cascade constraints;
drop table ME_DIETARY_20080226 cascade constraints;
drop table ME_DXID_ATC_CONTRA_0210 cascade constraints;
drop table ME_DXID_ATC_CONTRA_08072008 cascade constraints;
drop table ME_DXID_ATC_CONTRA_1703 cascade constraints;
drop table ME_DXID_ATC_CONTRA_20080226 cascade constraints;
drop table ME_DXID_ATC_CONTRA_20080702 cascade constraints;
drop table ME_DXID_ATC_CONTRA_20090210 cascade constraints;
drop table ME_INGRED_1703 cascade constraints;
drop table ME_INGRED_20080226 cascade constraints;
drop table ME_MANIP_1703 cascade constraints;
drop table ME_MANIP_20080226 cascade constraints;
drop table ME_MANIP_20090108 cascade constraints;
drop table ME_MANIP_GROUP_1703 cascade constraints;
drop table ME_MANIP_GROUP_20080226 cascade constraints;
drop table ME_MANIP_GROUP_20090108 cascade constraints;
drop table ME_MANIP_INGRED_1703 cascade constraints;
drop table ME_MANIP_INGRED_20080226 cascade constraints;
drop table ME_MED_08072008 cascade constraints;
drop table ME_MED_1703 cascade constraints;
drop table ME_MED_20080226 cascade constraints;
drop table ME_MED_20080702 cascade constraints;
drop table ME_MED_20090210 cascade constraints;
drop table ME_MED_ATC_08072008 cascade constraints;
drop table ME_MED_ATC_1703 cascade constraints;
drop table ME_MED_ATC_20080226 cascade constraints;
drop table ME_MED_ATC_20080702 cascade constraints;
drop table ME_MED_ATC_20090210 cascade constraints;
drop table ME_MED_ATC_INTERACTION_0210 cascade constraints;
drop table ME_MED_ATC_INTERACT_08072008 cascade constraints;
drop table ME_MED_ATC_INTERACT_1703 cascade constraints;
drop table ME_MED_ATC_INTERACT_20080226 cascade constraints;
drop table ME_MED_ATC_INTERACT_20080702 cascade constraints;
drop table ME_MED_ATC_INTERACT_20090210 cascade constraints;
drop table ME_MED_BCKP_PT cascade constraints;
drop table ME_MED_ICD9_ATC_CONTRA cascade constraints;
drop table ME_MED_PHARM_GROUP_08072008 cascade constraints;
drop table ME_MED_PHARM_GROUP_1703 cascade constraints;
drop table ME_MED_PHARM_GROUP_20080226 cascade constraints;
drop table ME_MED_PHARM_GROUP_20080702 cascade constraints;
drop table ME_MED_PHARM_GROUP_20090210 cascade constraints;
drop table ME_MED_REGULATION_08072008 cascade constraints;
drop table ME_MED_REGULATION_1703 cascade constraints;
drop table ME_MED_REGULATION_20080226 cascade constraints;
drop table ME_MED_REGULATION_20080702 cascade constraints;
drop table ME_MED_REGULATION_20090210 cascade constraints;
drop table ME_MED_ROUTE_08072008 cascade constraints;
drop table ME_MED_ROUTE_1703 cascade constraints;
drop table ME_MED_ROUTE_20080226 cascade constraints;
drop table ME_MED_ROUTE_20080702 cascade constraints;
drop table ME_MED_ROUTE_20090210 cascade constraints;
drop table ME_MED_SUBST_08072008 cascade constraints;
drop table ME_MED_SUBST_1703 cascade constraints;
drop table ME_MED_SUBST_20080226 cascade constraints;
drop table ME_MED_SUBST_20080702 cascade constraints;
drop table ME_MED_SUBST_20090210 cascade constraints;
drop table ME_PHARM_GROUP_08072008 cascade constraints;
drop table ME_PHARM_GROUP_1703 cascade constraints;
drop table ME_PHARM_GROUP_20080226 cascade constraints;
drop table ME_PHARM_GROUP_20080702 cascade constraints;
drop table ME_PHARM_GROUP_20090210 cascade constraints;
drop table ME_REGULATION_08072008 cascade constraints;
drop table ME_REGULATION_1703 cascade constraints;
drop table ME_REGULATION_20080226 cascade constraints;
drop table ME_REGULATION_20080702 cascade constraints;
drop table ME_REGULATION_20090210 cascade constraints;
drop table ME_ROUTE_08072008 cascade constraints;
drop table ME_ROUTE_1703 cascade constraints;
drop table ME_ROUTE_20080226 cascade constraints;
drop table ME_ROUTE_20080702 cascade constraints;
drop table ME_ROUTE_20090210 cascade constraints;
drop table MI_DXID_ATC_CONTRA_0210 cascade constraints;
drop table MI_DXID_ATC_CONTRA_08072008 cascade constraints;
drop table MI_DXID_ATC_CONTRA_20080226 cascade constraints;
drop table MI_DXID_ATC_CONTRA_20080702 cascade constraints;
drop table MI_JUSTIFICATION_08072008 cascade constraints;
drop table MI_JUSTIFICATION_1703 cascade constraints;
drop table MI_JUSTIFICATION_20080226 cascade constraints;
drop table MI_JUSTIFICATION_20080702 cascade constraints;
drop table MI_JUSTIFICATION_20090210 cascade constraints;
drop table MI_MED_08072008 cascade constraints;
drop table MI_MED_20080226 cascade constraints;
drop table MI_MED_20080702 cascade constraints;
drop table MI_MED_20090210 cascade constraints;
drop table MI_MED_ATC_08072008 cascade constraints;
drop table MI_MED_ATC_20080226 cascade constraints;
drop table MI_MED_ATC_20080702 cascade constraints;
drop table MI_MED_ATC_20090210 cascade constraints;
drop table MI_MED_ATC_INTERACTION_0210 cascade constraints;
drop table MI_MED_ATC_INTERACT_08072008 cascade constraints;
drop table MI_MED_ATC_INTERACT_20080702 cascade constraints;
drop table MI_MED_COMMERC08072008 cascade constraints;
drop table MI_MED_COMMERC1703 cascade constraints;
drop table MI_MED_COMMERC20080226 cascade constraints;
drop table MI_MED_COMMERC20080702 cascade constraints;
drop table MI_MED_COMMERC20090210 cascade constraints;
drop table MI_MED_PHARM_GROUP_08072008 cascade constraints;
drop table MI_MED_PHARM_GROUP_1703 cascade constraints;
drop table MI_MED_PHARM_GROUP_20080226 cascade constraints;
drop table MI_MED_PHARM_GROUP_20080702 cascade constraints;
drop table MI_MED_PHARM_GROUP_20090210 cascade constraints;
drop table MI_MED_PHARM_GROUP_BK cascade constraints;
drop table MI_MED_REGULATION_08072008 cascade constraints;
drop table MI_MED_REGULATION_1703 cascade constraints;
drop table MI_MED_REGULATION_20080226 cascade constraints;
drop table MI_MED_REGULATION_20080702 cascade constraints;
drop table MI_MED_REGULATION_20090210 cascade constraints;
drop table MI_PHARM_GROUP_08072008 cascade constraints;
drop table MI_PHARM_GROUP_1703 cascade constraints;
drop table MI_PHARM_GROUP_20080226 cascade constraints;
drop table MI_PHARM_GROUP_20080702 cascade constraints;
drop table MI_PHARM_GROUP_20090210 cascade constraints;
drop table MI_PHARM_GROUP_BK cascade constraints;
drop table MI_REGULATION_08072008 cascade constraints;
drop table MI_REGULATION_1703 cascade constraints;
drop table MI_REGULATION_20080226 cascade constraints;
drop table MI_REGULATION_20080702 cascade constraints;
drop table MI_REGULATION_20090210 cascade constraints;
drop table MI_ROUTE_08072008 cascade constraints;
drop table MI_ROUTE_1703 cascade constraints;
drop table MI_ROUTE_20080226 cascade constraints;
drop table MI_ROUTE_20080702 cascade constraints;
drop table MI_ROUTE_20090210 cascade constraints;
drop table NURSE_TEA_REQ_20081125 cascade constraints;
drop table NURSE_TEA_REQ_20081126 cascade constraints;
drop table P1_EXR_DIAGNOSIS_BCK_20080409 cascade constraints;
drop table PATIENT_WL_DEMO cascade constraints;
drop table PAT_MEDICATION_HIST_LIST_B cascade constraints;
drop table PAT_MEDICATION_HIST_LIST_IT cascade constraints;
drop table PAT_MEDICATION_LIST_BCKP cascade constraints;
drop table PAT_MEDICATION_LIST_BK20080125 cascade constraints;
drop table PAT_MEDICATION_LIST_IT cascade constraints;
drop table PAT_PREGNANCY_BCK243 cascade constraints;
drop table PAT_PROBLEM_HIST_PHD_BCK cascade constraints;
drop table PAT_PROBLEM_PHD_BCK cascade constraints;
drop table PRESCRIPTION_CHAVES_XML cascade constraints;
drop table PRESCRIPTION_CM cascade constraints;
drop table PRESCRIPTION_DET_CHAVES_XML cascade constraints;
drop table PRESCRIPTION_INSTR_HIST_080125 cascade constraints;
drop table PRESCRIPTION_IT cascade constraints;
drop table PRESCRIPTION_PHARM_BCKP_2 cascade constraints;
drop table PRESCRIPTION_PHARM_BK20080125 cascade constraints;
drop table PRESCRIPTION_PHARM_CM cascade constraints;
drop table PRESCRIPTION_PHARM_DET_IT cascade constraints;
drop table PRESCRIPTION_PHARM_IT cascade constraints;
drop table PRESCRIPTION_USA cascade constraints;
drop table PRESCRIPTION_XML_CM cascade constraints;
drop table PRESC_ATTENTION_DET_IT cascade constraints;
drop table PRESC_PAT_PROBLEM_IT cascade constraints;
drop table PRODUCT_PURCHASABLE_COST cascade constraints;
drop table PROTOCOL_CRIT_LNK_BCK_20080409 cascade constraints;
drop table PROTOCOL_LINK_BCK_20080409 cascade constraints;
drop table RB_INTERV_ICD cascade constraints;
drop table RB_PROFILE_TEMPL_ACCESS cascade constraints;
drop table RB_SYS_BUTTON_PROP cascade constraints;
drop table RB_SYS_BUTTON_PROP2 cascade constraints;
drop table RB_SYS_SHORTCUT cascade constraints;
drop table RUI cascade constraints;
drop table SAP_BCK_20080313_2 cascade constraints;
drop table SAP_BCK_20080313_22 cascade constraints;
drop table SCH_PERMISSION_BCK243 cascade constraints;
drop table SOCIAL_EPISODE_20080814 cascade constraints;
drop table SQLN_EXPLAIN_PLAN cascade constraints;
drop table SYS_CFG_HTTPS_BCK cascade constraints;
drop table SYS_CONFIG_BCK_RUI_BAETA cascade constraints;
drop table TMPLT_TRANSLATION_BKP cascade constraints;
drop table TRANSLATION_CHNM_NEW cascade constraints;
drop table TZB_EPIS_POSITIONING_PLAN cascade constraints;
drop table TZB_INTERV_PRESC_PLAN cascade constraints;
drop table TZB_MONITORIZATION_VS_PLAN cascade constraints;
drop table UNIT_MEASURE_070920 cascade constraints;
drop table UNIT_MEASURE_NEW cascade constraints;
drop table USA_EMB_DEP_CLIN_SERV cascade constraints;
drop table USA_PAT_MEDICATION_HIST_LIST cascade constraints;
drop table USA_PAT_MEDICATION_LIST cascade constraints;
drop table USA_PRESCRIPTION cascade constraints;
drop table USA_PRESCRIPTION_PHARM cascade constraints;
drop table USA_PRESCRIPTION_PHARM_DET cascade constraints;
drop table USA_PRESC_ATTENTION_DET cascade constraints;
drop table USA_PRESC_INTERACTIONS cascade constraints;
drop table USA_PRESC_PAT_PROBLEM cascade constraints;
drop table VBZ$OBJECT_STATS cascade constraints;
drop table VISIT_20080814 cascade constraints;
drop table VITAL_SIGNS_EA_BCK cascade constraints;
drop table VITAL_SIGN_READ_BCK cascade constraints;
drop table VITAL_SIGN_READ_ERROR cascade constraints;
drop table WL_WAITING_LINE_0104 cascade constraints;
-- CHANGE END: Rui Spratley

-- CHANGED BY: Rui Spratley
-- CHANGED DATE: 2009-APR-15
-- CHANGED REASON: ALERT-21602
DECLARE
  CURSOR C_TABLES is
    SELECT TABLE_NAME
    FROM user_tables
    WHERE TABLE_NAME NOT LIKE '%TMP%'
      AND TABLE_NAME NOT LIKE '%TEMP%'
      AND TABLE_NAME NOT LIKE '%BCK%'
      AND TABLE_NAME NOT LIKE '%200%'
      AND TABLE_NAME NOT LIKE 'BIN$'
      AND TABLE_NAME NOT LIKE 'DOCUMENTATION_REL_DOC'
      AND TABLE_NAME NOT LIKE 'DOCUMENTATION_REL_ELEM_CRIT'
      AND TABLE_NAME NOT LIKE 'MV\_%' escape '\';


    l_trg_name VARCHAR2(30);
    l_ck_name VARCHAR2(30);
    l_alias VARCHAR2(30);
    l_passo NUMBER(3):=1;
    l_aux NUMBER(5) := 0;

    l_tab_name varchar2(4000);

    /**/

    FUNCTION VALIDATE_DUPLICATED (i_table_name VARCHAR2, i_alias VARCHAR2, i_aux IN OUT number) RETURN VARCHAR2 IS
      L_OBJ VARCHAR2(30);
    BEGIN
      BEGIN
        SELECT OBJECT_NAME
        INTO L_OBJ
        FROM USER_OBJECTS
        WHERE OBJECT_NAME = 'B_IU_'||Upper(i_alias)||'_AUDIT'
        OR OBJECT_NAME = Upper(i_alias)||'_AD_CK';
      EXCEPTION WHEN OTHERS THEN
        L_OBJ := NULL;
      END;

      IF  L_OBJ IS NULL
      THEN
        RETURN i_alias;
      ELSE
        i_aux := i_aux +1;
        RETURN REPLACE(i_alias||SubStr(i_table_name, -1), '_', '')||i_aux;
      END IF;

    EXCEPTION WHEN OTHERS THEN
      Dbms_Output.PUT_LINE('VALIDATE_DUPLICATED->'||sqlerrm);
    END;

    /**/
    FUNCTION get_alias(i_table_name VARCHAR2, i_aux IN OUT NUMBER) RETURN VARCHAR2 is
      CURSOR c_tables is
        Select table_name, (length(TABLE_NAME)-length(replace(TABLE_NAME,'_','')))/length('_') as theCount
        FROM user_tables
        WHERE table_name = i_table_name;

      l_alias VARCHAR2(30);
      CURSOR c_primary_key IS
        SELECT REPLACE(REPLACE(constraint_name, '_PK', ''), 'PK_', '')
        FROM user_constraints
        WHERE constraint_type = 'P'
        AND TABLE_NAME = i_table_name;

    BEGIN
      FOR r_tables IN c_tables
      loop
        OPEN c_primary_key;
        FETCH c_primary_key INTO l_alias;
        CLOSE c_primary_key;

        IF l_alias IS NOT NULL AND Length(l_alias) < 19
        THEN
            RETURN VALIDATE_DUPLICATED(r_tables.table_name, L_ALIAS, i_aux);
        else

          IF r_tables.theCount = 0
          THEN
            L_ALIAS :=  (SubStr(r_tables.table_name,1,4));
          elsIF r_tables.theCount = 1
          THEN
            L_ALIAS :=   (SubStr(r_tables.table_name,1,2)||SubStr(r_tables.table_name,InStr(r_tables.table_name,'_', 1)+1,2));
          elsIF r_tables.theCount = 2
          THEN
            L_ALIAS :=   (SubStr(r_tables.table_name,1,2)||/**/
                    SubStr(r_tables.table_name,InStr(r_tables.table_name,'_', 1)+1,1)||/**/
                    SubStr(r_tables.table_name,InStr(r_tables.table_name,'_', InStr(r_tables.table_name,'_', 1)+1)+1,1));
          elsIF r_tables.theCount >= 3
          THEN
            L_ALIAS :=   (SubStr(r_tables.table_name,1,1)||/**/
                    SubStr(r_tables.table_name,InStr(r_tables.table_name,'_', 1)+1,1)||/**/
                    SubStr(r_tables.table_name,InStr(r_tables.table_name,'_', InStr(r_tables.table_name,'_', 1)+1)+1,1)||/**/
                    SubStr(r_tables.table_name,InStr(r_tables.table_name,'_', InStr(r_tables.table_name,'_', InStr(r_tables.table_name,'_', 1)+1)+1)+1,1)/**/
                    );
          END IF;

          RETURN VALIDATE_DUPLICATED(r_tables.table_name, L_ALIAS, i_aux);
        END IF;

      END LOOP;
    EXCEPTION WHEN OTHERS THEN
      Dbms_Output.PUT_LINE('GET_ALIAS->'||sqlerrm);
      RETURN NULL;
    END;

BEGIN
  FOR R_TABLES IN C_TABLES
  LOOP
    l_alias := get_alias(R_TABLES.TABLE_NAME, l_aux);

    l_tab_name := R_TABLES.TABLE_NAME;

    l_passo:=1;
    SELECT 'B_IU_'||l_alias||'_AUDIT'
    INTO l_trg_name
    FROM dual;

    l_passo:=2;
    SELECT l_alias||'_AD_CK'
    INTO l_ck_name
    FROM dual;

    --Dbms_Output.PUT_LINE(R_TABLES.TABLE_NAME||' --> '||l_alias);
    --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD CREATE_USER VARCHAR2(24)');
    l_passo:=3;
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD CREATE_USER VARCHAR2(24)';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.CREATE_USER is ''Creation User''');
    l_passo:=4;
    EXECUTE IMMEDIATE 'COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.CREATE_USER is ''Creation User''';
    --
    --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD CREATE_TIME TIMESTAMP WITH LOCAL TIME ZONE');
    l_passo:=5;
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD CREATE_TIME TIMESTAMP WITH LOCAL TIME ZONE';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.CREATE_TIME is ''Creation Time''');
    l_passo:=6;
    EXECUTE IMMEDIATE 'COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.CREATE_TIME is ''Creation Time''';
    --
    --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD CREATE_INSTITUTION NUMBER(24)');
    l_passo:=7;
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD CREATE_INSTITUTION NUMBER(24)';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.CREATE_INSTITUTION is ''Creation Institution''');
    l_passo:=8;
    EXECUTE IMMEDIATE 'COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.CREATE_INSTITUTION is ''Creation Institution''';
    --

    --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD UPDATE_USER VARCHAR2(24)');
    l_passo:=9;
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD UPDATE_USER VARCHAR2(24)';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.UPDATE_USER is ''Update User''');
    l_passo:=10;
    EXECUTE IMMEDIATE 'COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.UPDATE_USER is ''Update User''';
    --
    --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD UPDATE_TIME TIMESTAMP WITH LOCAL TIME ZONE');
    l_passo:=11;
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD UPDATE_TIME TIMESTAMP WITH LOCAL TIME ZONE';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.UPDATE_TIME is ''Update Time''');
    l_passo:=12;
    EXECUTE IMMEDIATE 'COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.UPDATE_TIME is ''Update Time''';
    --
    --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD UPDATE_INSTITUTION NUMBER(24)');
    l_passo:=13;
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD UPDATE_INSTITUTION NUMBER(24)';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
    --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.UPDATE_INSTITUTION is ''Update Institution''');
    l_passo:=14;
    EXECUTE IMMEDIATE 'COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.UPDATE_INSTITUTION is ''Update Institution''';
    --

    --Dbms_Output.PUT_LINE('alter table '||R_TABLES.TABLE_NAME||' add constraint '||R_TABLES.TABLE_NAME||'_AD_CK '||
    --              ' check (CREATE_USER IS NOT NULL AND CREATE_TIME IS NOT NULL AND CREATE_INSTITUTION IS NOT NULL) NOVALIDATE');
    l_passo:=15;
    /*
    EXECUTE IMMEDIATE 'alter table '||R_TABLES.TABLE_NAME||' add constraint '||l_ck_name||
                  ' check (nvl(pk_utils.str_token(pk_utils.get_client_id, 1, '';''),''@'') =  ''@'' OR CREATE_USER IS NOT NULL OR CREATE_TIME IS NOT NULL OR CREATE_INSTITUTION IS NOT NULL) NOVALIDATE';
    */

    --Dbms_Output.PUT_LINE('CREATE TRIGGER');
    l_passo:=16;
    EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER '||l_trg_name||' '||'
BEFORE INSERT OR UPDATE ON '||R_TABLES.TABLE_NAME||'
FOR EACH ROW
DECLARE
BEGIN
    IF pk_utils.str_token(pk_utils.get_client_id, 1, '';'') is null
    then
        pk_alertlog.log_error(''CLIENT INFO IS NULL'');
    ELSE
      IF inserting
      THEN
          :NEW.create_user        := pk_utils.str_token(pk_utils.get_client_id, 1, '';'');
          :NEW.create_time        := current_timestamp;
          :NEW.create_institution := pk_utils.str_token(pk_utils.get_client_id, 2, '';'');
      ELSIF updating
      THEN
          :NEW.create_user        := nvl(:NEW.create_user, pk_utils.str_token(pk_utils.get_client_id, 1, '';''));
          :NEW.create_time        := nvl(:NEW.create_time, current_timestamp);
          :NEW.create_institution := nvl(:NEW.create_institution, pk_utils.str_token(pk_utils.get_client_id, 2, '';''));
          --
          :NEW.update_user        := pk_utils.str_token(pk_utils.get_client_id, 1, '';'');
          :NEW.update_time        := current_timestamp;
          :NEW.update_institution := pk_utils.str_token(pk_utils.get_client_id, 2, '';'');
      END IF;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END '||l_trg_name||';';
                       l_passo:=18;

  END LOOP;

EXCEPTION WHEN OTHERS THEN
  Dbms_Output.PUT_LINE('ERRO('||l_passo||'):'||l_tab_name||'-'||l_trg_name||'-'||SQLERRM);
END;
/
-- CHANGE END: Rui Spratley

-- CHANGED BY: Ariel Geraldo Machado
-- CHANGED DATE: 2009-APR-20
-- CHANGED REASON: ALERT-10398 - New flag on epis_documentation for enable/disable component at startup (by default: Yes)
UPDATE documentation SET flg_enabled = 'Y';
-- CHANGE END Ariel Machado


-- CHANGED BY: Rui Spratley
-- CHANGED DATE: 2009-APR-21
-- CHANGED REASON: ALERT-24856
DECLARE
    CURSOR c_tables IS
        SELECT trigger_name, ut.table_name
          FROM user_triggers ut
         WHERE ut.trigger_name LIKE 'B_IU_%AUDIT';

    l_passo    VARCHAR2(30);
    l_tab_name VARCHAR2(30);
    l_trg_name VARCHAR2(30);

BEGIN
    FOR r_tables IN c_tables
    LOOP
    
        l_tab_name := r_tables.table_name;
        l_trg_name := r_tables.trigger_name;
    
        EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER ' || r_tables.trigger_name || '  
BEFORE INSERT OR UPDATE ON ' || upper(r_tables.table_name) || '
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, '';''), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, '';''), '','', ''.''), ''999999999999999999999999D999'', ''NLS_NUMERIC_CHARACTERS = ''''. '''''');
   
   IF inserting
   THEN
         :NEW.create_user        := l_str1;
         :NEW.create_time        := current_timestamp;
         :NEW.create_institution := l_str2;
         --
         :NEW.update_user        := NULL;
         :NEW.update_time        := cast(NULL as timestamp with local time zone);
         :NEW.update_institution := NULL;
   ELSIF updating
   THEN
         :NEW.create_user        := :OLD.create_user;
         :NEW.create_time        := :OLD.create_time;
         :NEW.create_institution := :OLD.create_institution;
         --
         :NEW.update_user        := l_str1;
         :NEW.update_time        := current_timestamp;
         :NEW.update_institution := l_str2;
   END IF;

EXCEPTION
    WHEN OTHERS THEN
        PK_ALERTLOG.log_error('''||r_tables.trigger_name||'-''||sqlerrm);
END ' || r_tables.trigger_name || ';
';
    
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('ERRO(' || l_passo || '):' || l_tab_name || '-' || l_trg_name || '-' || SQLERRM);
END;
/

-- CHANGE END: Rui Spratley

-- CHANGED BY: Rui Spratley
-- CHANGED DATE: 2009-APR-25
-- CHANGED REASON: ALERT-25344
DECLARE
    CURSOR c_tables IS
        SELECT table_name
          FROM user_tables
         WHERE table_name in (
                'ANALYSIS_LOINC_TEMPLATE',
                'ANALYSIS_REQ_TEMP',
                'DEPT_TEMPLATE',
                'DOC_TEMPLATE',
                'DOC_TEMPLATE_AREA',
                'DOC_TEMPLATE_CONTEXT',
                'DOC_TEMPLATE_DIAGNOSIS',
                'EPIS_DOC_TEMPLATE',
                'EXAM_TYPE_TEMPLATE',
                'EXTERNAL_DOC_TMP',
                'P1_EXR_TEMP',
                'PHYSIATRY_AREA_TEMPLATE',
                'PROFILE_TEMPLATE',
                'PROFILE_TEMPLATE_CATEGORY',
                'PROFILE_TEMPLATE_DESC',
                'PROFILE_TEMPLATE_INST',
                'PROFILE_TEMPL_ACCESS',
                'PROFILE_TEMPL_ACCESS_EXCEPTION',
                'PROFILE_TEMPL_ACC_FUNC',
                'PROF_PROFILE_TEMPLATE',
                'REP_PROFILE_TEMPLATE',
                'REP_PROFILE_TEMPLATE_DET',
                'REP_PROF_TEMPLATE',
                'REP_PROF_TEMPL_ACCESS',
                'SCREEN_TEMPLATE',
                'SYS_SCREEN_TEMPLATE');

    l_trg_name VARCHAR2(30);
    l_ck_name  VARCHAR2(30);
    l_alias    VARCHAR2(30);
    l_passo    NUMBER(3) := 1;
    l_aux      NUMBER(5) := 0;
    l_tab_name VARCHAR2(4000);

    /**/

    FUNCTION validate_duplicated
    (
        i_table_name VARCHAR2,
        i_alias      VARCHAR2,
        i_aux        IN OUT NUMBER
    ) RETURN VARCHAR2 IS
        l_obj VARCHAR2(30);
    BEGIN
        BEGIN
            SELECT object_name
              INTO l_obj
              FROM user_objects
             WHERE object_name = 'B_IU_' || upper(i_alias) || '_AUDIT'
                OR object_name = upper(i_alias) || '_AD_CK';
        EXCEPTION
            WHEN OTHERS THEN
                l_obj := NULL;
        END;
    
        IF l_obj IS NULL
        THEN
            RETURN i_alias;
        ELSE
            i_aux := i_aux + 1;
            RETURN REPLACE(i_alias || substr(i_table_name, -1), '_', '') || i_aux;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('VALIDATE_DUPLICATED->' || SQLERRM);
    END;

    /**/
    FUNCTION get_alias
    (
        i_table_name VARCHAR2,
        i_aux        IN OUT NUMBER
    ) RETURN VARCHAR2 IS
        CURSOR c_tables IS
            SELECT table_name, (length(table_name) - length(REPLACE(table_name, '_', ''))) / length('_') AS thecount
              FROM user_tables
             WHERE table_name = i_table_name;
    
        l_alias VARCHAR2(30);
        CURSOR c_primary_key IS
            SELECT REPLACE(REPLACE(constraint_name, '_PK', ''), 'PK_', '')
              FROM user_constraints
             WHERE constraint_type = 'P'
               AND table_name = i_table_name;
    
    BEGIN
        FOR r_tables IN c_tables
        LOOP
            OPEN c_primary_key;
            FETCH c_primary_key
                INTO l_alias;
            CLOSE c_primary_key;
        
            IF l_alias IS NOT NULL
               AND length(l_alias) < 19
            THEN
                RETURN validate_duplicated(r_tables.table_name, l_alias, i_aux);
            ELSE
            
                IF r_tables.thecount = 0
                THEN
                    l_alias := (substr(r_tables.table_name, 1, 4));
                ELSIF r_tables.thecount = 1
                THEN
                    l_alias := (substr(r_tables.table_name, 1, 2) ||
                               substr(r_tables.table_name, instr(r_tables.table_name, '_', 1) + 1, 2));
                ELSIF r_tables.thecount = 2
                THEN
                    l_alias := (substr(r_tables.table_name, 1, 2) || /**/
                               substr(r_tables.table_name, instr(r_tables.table_name, '_', 1) + 1, 1) || /**/
                               substr(r_tables.table_name,
                                       instr(r_tables.table_name, '_', instr(r_tables.table_name, '_', 1) + 1) + 1,
                                       1));
                ELSIF r_tables.thecount >= 3
                THEN
                    l_alias := (substr(r_tables.table_name, 1, 1) || /**/
                               substr(r_tables.table_name, instr(r_tables.table_name, '_', 1) + 1, 1) || /**/
                               substr(r_tables.table_name,
                                       instr(r_tables.table_name, '_', instr(r_tables.table_name, '_', 1) + 1) + 1,
                                       1) || /**/
                               substr(r_tables.table_name,
                                       instr(r_tables.table_name,
                                             '_',
                                             instr(r_tables.table_name, '_', instr(r_tables.table_name, '_', 1) + 1) + 1) + 1,
                                       1) /**/
                               );
                END IF;
            
                RETURN validate_duplicated(r_tables.table_name, l_alias, i_aux);
            END IF;
        
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('GET_ALIAS->' || SQLERRM);
            RETURN NULL;
    END;

BEGIN
    FOR r_tables IN c_tables
    LOOP
        l_alias := get_alias(r_tables.table_name, l_aux);
    
        l_tab_name := r_tables.table_name;
    
        l_passo := 1;
        SELECT 'B_IU_' || l_alias || '_AUDIT'
          INTO l_trg_name
          FROM dual;
    
        l_passo := 2;
        SELECT l_alias || '_AD_CK'
          INTO l_ck_name
          FROM dual;
    
        --Dbms_Output.PUT_LINE(R_TABLES.TABLE_NAME||' --> '||l_alias);
        --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD CREATE_USER VARCHAR2(24)');
        l_passo := 3;
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || r_tables.table_name || ' ADD CREATE_USER VARCHAR2(24)';
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.CREATE_USER is ''Creation User''');
        l_passo := 4;
        EXECUTE IMMEDIATE 'COMMENT ON COLUMN ' || r_tables.table_name || '.CREATE_USER is ''Creation User''';
        --
        --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD CREATE_TIME TIMESTAMP WITH LOCAL TIME ZONE');
        l_passo := 5;
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || r_tables.table_name ||
                              ' ADD CREATE_TIME TIMESTAMP WITH LOCAL TIME ZONE';
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.CREATE_TIME is ''Creation Time''');
        l_passo := 6;
        EXECUTE IMMEDIATE 'COMMENT ON COLUMN ' || r_tables.table_name || '.CREATE_TIME is ''Creation Time''';
        --
        --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD CREATE_INSTITUTION NUMBER(24)');
        l_passo := 7;
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || r_tables.table_name || ' ADD CREATE_INSTITUTION NUMBER(24)';
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.CREATE_INSTITUTION is ''Creation Institution''');
        l_passo := 8;
        EXECUTE IMMEDIATE 'COMMENT ON COLUMN ' || r_tables.table_name ||
                          '.CREATE_INSTITUTION is ''Creation Institution''';
        --
    
        --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD UPDATE_USER VARCHAR2(24)');
        l_passo := 9;
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || r_tables.table_name || ' ADD UPDATE_USER VARCHAR2(24)';
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.UPDATE_USER is ''Update User''');
        l_passo := 10;
        EXECUTE IMMEDIATE 'COMMENT ON COLUMN ' || r_tables.table_name || '.UPDATE_USER is ''Update User''';
        --
        --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD UPDATE_TIME TIMESTAMP WITH LOCAL TIME ZONE');
        l_passo := 11;
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || r_tables.table_name ||
                              ' ADD UPDATE_TIME TIMESTAMP WITH LOCAL TIME ZONE';
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.UPDATE_TIME is ''Update Time''');
        l_passo := 12;
        EXECUTE IMMEDIATE 'COMMENT ON COLUMN ' || r_tables.table_name || '.UPDATE_TIME is ''Update Time''';
        --
        --Dbms_Output.PUT_LINE('ALTER TABLE '||R_TABLES.TABLE_NAME||' ADD UPDATE_INSTITUTION NUMBER(24)');
        l_passo := 13;
        BEGIN
            EXECUTE IMMEDIATE 'ALTER TABLE ' || r_tables.table_name || ' ADD UPDATE_INSTITUTION NUMBER(24)';
        EXCEPTION
            WHEN OTHERS THEN
                NULL;
        END;
        --Dbms_Output.PUT_LINE('COMMENT ON COLUMN '||R_TABLES.TABLE_NAME||'.UPDATE_INSTITUTION is ''Update Institution''');
        l_passo := 14;
        EXECUTE IMMEDIATE 'COMMENT ON COLUMN ' || r_tables.table_name ||
                          '.UPDATE_INSTITUTION is ''Update Institution''';
        --
    
        --Dbms_Output.PUT_LINE('alter table '||R_TABLES.TABLE_NAME||' add constraint '||R_TABLES.TABLE_NAME||'_AD_CK '||
        --              ' check (CREATE_USER IS NOT NULL AND CREATE_TIME IS NOT NULL AND CREATE_INSTITUTION IS NOT NULL) NOVALIDATE');
        l_passo := 15;
        /*
        EXECUTE IMMEDIATE 'alter table '||R_TABLES.TABLE_NAME||' add constraint '||l_ck_name||
                      ' check (nvl(pk_utils.str_token(pk_utils.get_client_id, 1, '';''),''@'') =  ''@'' OR CREATE_USER IS NOT NULL OR CREATE_TIME IS NOT NULL OR CREATE_INSTITUTION IS NOT NULL) NOVALIDATE';
        */
    
        --Dbms_Output.PUT_LINE('CREATE TRIGGER');
        l_passo := 16;
        EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER ' || l_trg_name || ' ' || '
BEFORE INSERT OR UPDATE ON ' || r_tables.table_name || '
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, '';''), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, '';''), '','', ''.''), ''999999999999999999999999D999'', ''NLS_NUMERIC_CHARACTERS = ''''. '''''');
  
  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        PK_ALERTLOG.log_error(''' || l_trg_name || '-''||sqlerrm);
END ' || l_trg_name || ';';
        l_passo := 18;
    
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('ERRO(' || l_passo || '):' || l_tab_name || '-' || l_trg_name || '-' || SQLERRM);
END;
/
-- CHANGE END: Rui Spratley

-- CHANGED BY: Rui Marante
-- CHANGED DATE: 2009-APR-27
-- CHANGED REASON: ALERT-10027


alter table drug_req_det_refill
modify refill varchar2(100);

alter table prescription_pharm_refill
modify refill varchar2(100);

-- CHANGE END: Rui Marante


-- JSILVA 18-05-2009
DECLARE 
	 
   l_id_epis_triage epis_triage.id_epis_triage%TYPE;
	 l_exception      EXCEPTION;

	 CURSOR c_fast_track IS
	  SELECT id_fast_track, id_episode
		  FROM episode
		 WHERE id_fast_track is not null;

   CURSOR c_epis_triage(i_episode episode.id_episode%TYPE) IS
	   SELECT id_epis_triage
		   FROM epis_triage et
			WHERE et.id_episode = i_episode
		  ORDER BY et.dt_end_tstz DESC;

BEGIN

    BEGIN
				SELECT ef.id_epis_triage
					INTO l_id_epis_triage
					FROM epis_fast_track ef
					WHERE rownum < 2;
	  EXCEPTION
		  WHEN no_data_found THEN
		    NULL;
		END;
		
		IF l_id_epis_triage IS NOT NULL
		THEN
		    RAISE l_exception;
		END IF;
		
		FOR r_ft IN c_fast_track
		LOOP
		    OPEN c_epis_triage(r_ft.id_episode);
				FETCH c_epis_triage
				  INTO l_id_epis_triage;
				CLOSE c_epis_triage;
				
				IF l_id_epis_triage IS NOT NULL
				THEN
						INSERT INTO epis_fast_track(id_epis_triage, id_fast_track, flg_status)
						VALUES (l_id_epis_triage, r_ft.id_fast_track, 'A');
				END IF;
		
		END LOOP;

EXCEPTION
  WHEN l_exception THEN
	  NULL;
END;
/
-- END



-- CHANGED BY: Rui Spratley
-- CHANGED DATE: 2009-JUN-01
-- CHANGED REASON: ALERT-31050
declare
begin
delete from tbl_temp;

insert into tbl_temp(VC_1, VC_2) values ('ABNORMALITY','B_IU_ABY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ABNORMALITY_NATURE','B_IU_ABN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ACCOUNTS','B_IU_ACC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ACCOUNTS_CATEGORY','B_IU_ACCCAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ACCOUNTS_COUNTRY','B_IU_ACCCTR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ACTION','B_IU_ACTION_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ACTION_MAP','B_IU_AMP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ACTION_PERMISSION','B_IU_APN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADMISSION_TYPE','B_IU_ATY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADM_INDICATION','B_IU_AIN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADM_IND_DEP_CLIN_SERV','B_IU_AIDCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADM_PREPARATION','B_IU_APREP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADM_PREPARATION_INST','B_IU_APRPI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADM_REQUEST','B_IU_AREQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADM_REQUEST_HIST','B_IU_AREQH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADM_REQ_DIAGNOSIS','B_IU_ADRD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADVANCED_INPUT','B_IU_AI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADVANCED_INPUT_FIELD','B_IU_AIF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADVANCED_INPUT_FIELD_DET','B_IU_AIFD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADVANCED_INPUT_FIELD_UNIT','B_IU_AIFU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADVANCED_INPUT_MULTI_FIELD','B_IU_AIMF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADVANCED_INPUT_SOFT_INST','B_IU_AISI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADVANCE_DIRECTIVE','B_IU_ADVDIR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADVERSE_EXAM_ALLERGY','B_IU_EAY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADVERSE_INTERV_ALLERGY','B_IU_AIA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ADW_PRM_STATUS_ORDER','B_IU_APSO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALERT_ALL_FLAGS','B_IU_ALAF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALERT_ALL_FLAGS_VALUES','B_IU_AAFV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALERT_ALL_FUNCTIONS','B_IU_ALAFS21_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALERT_DIAGNOSIS','B_IU_ADI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALLERGY','B_IU_ALG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALLERGY_EXT_SYS','B_IU_AES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALLERGY_INST_SOFT','B_IU_ALIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALLERGY_SEVERITY','B_IU_ALSE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALLERGY_SYMPTOMS','B_IU_ALSY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALLERGY_UNAWARENESS','B_IU_AU_ID_AU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALLOCATION_BED','B_IU_ALL_BED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ALT_DRUG_UNIT','B_IU_ADU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS','B_IU_ANALY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_ABN_PRINT','B_IU_AAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_AGP','B_IU_ANLG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_ALIAS','B_IU_AAS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_DEP_CLIN_SERV','B_IU_ACST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_DESC','B_IU_ADC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_GROUP','B_IU_AGP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_HARVEST','B_IU_AHT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_INSTIT_RECIPIENT','B_IU_AIR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_INSTIT_SOFT','B_IU_AIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_LOINC','B_IU_ALC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_LOINC_TEMPLATE','B_IU_ALT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_MARKET','B_IU_ANALY_MRK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_PARAM','B_IU_APM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_PARAMETER','B_IU_APR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_PARAM_FUNCIONALITY','B_IU_APRF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_PARAM_INSTIT','B_IU_API_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_PARAM_INSTIT_SAMPLE','B_IU_APIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_PREP_MESG','B_IU_APG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_PROTOCOLS','B_IU_APS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_QUESTIONNAIRE','B_IU_AQE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_QUESTION_RESPONSE','B_IU_AQR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_QUESTION_RESP_HIST','B_IU_AQRH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_REQ','B_IU_ART_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_REQ_DET','B_IU_ARD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_REQ_DET_HIST','B_IU_ARDH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_REQ_PAR','B_IU_ARP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_RESULT','B_IU_ARES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_RESULT_HIST','B_IU_ANRH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_RESULT_PAR','B_IU_ARLP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_RESULT_PAR_HIST','B_IU_ARPH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_ROOM','B_IU_ARM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALYSIS_UNIT_MEASURE','B_IU_AUE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANALY_PARM_LIMIT','B_IU_APL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANESTHESIA_TYPE','B_IU_ANEST_TYPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANNOUNCED_ARRIVAL','B_IU_ANN_ARR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ANNOUNCED_ARRIVAL_HIST','B_IU_ANN_ARRH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AREA_CONF_BUTTON_BLOCK','B_IU_ACBB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AREA_KEY_NEXTVAL','B_IU_AKNV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AUDIT_CRITERIA','B_IU_ADT_QUEST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AUDIT_QUEST_ANSWER','B_IU_ADT_QT_ANS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AUDIT_REQ','B_IU_ADT_REQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AUDIT_REQ_COMMENT','B_IU_ADT_REQ_CMT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AUDIT_REQ_PROF','B_IU_ADT_REQ_PROF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AUDIT_REQ_PROF_EPIS','B_IU_ADT_REQ_PROF_EPIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AUDIT_TYPE','B_IU_AUDIT_TYPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AUDIT_TYPE_TRIAGE_TYPE','B_IU_ADT_TR_TP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AUX_NUMBER_SS','B_IU_AUNS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AUX_PERIODIC_OBSERVATION','B_IU_AUPO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('AWARENESS','B_IU_AWAR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BBB','B_IU_BBB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BD_AGE_GRP_SOFT_INST','B_IU_BASI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BED','B_IU_BED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BED_DEP_CLIN_SERV','B_IU_BED_DEP_CLIN_SERV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BED_TYPE','B_IU_BTY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BEYE_VIEW_SCREEN','B_IU_BEV_SCREEN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BIBLIOGRAPHY','B_IU_BIY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BIBLIOGRAPHY_AUTHOR','B_IU_BAR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BIBLIOGRAPHY_CATEGORY','B_IU_BCY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BIBLIOGRAPHY_CAT_CONT_TYPE','B_IU_BCCE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BIBLIOGRAPHY_CONTENT_TYPE','B_IU_BCE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BIBLIOGRAPHY_DEPT','B_IU_BDC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BIBLIOGRAPHY_IMAGE','B_IU_BIE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BIBLIOGRAPHY_KEYWORDS','B_IU_BKD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BIBLIOGRAPHY_TRANSLATION','B_IU_BITN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BIRDS_EYE_VIEW','B_IU_BEYEVIEW_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BODY_DIAG_AGE_GRP','B_IU_BDAG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BODY_LAYER','B_IU_BODY_LAYER_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BODY_PART','B_IU_BPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BODY_PART_IMAGE','B_IU_BPI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BODY_SIDE','B_IU_BODY_SIDE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BO_ANALYSIS_PARAM','B_IU_BAP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BO_PARAM','B_IU_BPA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BP_CLIN_SERV','B_IU_BCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('BUILDING','B_IU_BUILDING_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CALCULATOR','B_IU_CALC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CALC_FIELD','B_IU_CFLD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CALC_FIELD_SOFT_INST','B_IU_CFT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CALC_SOFT_INST','B_IU_CSIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CALENDAR','B_IU_CALE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CANCEL_REASON','B_IU_CRE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CANCEL_REA_AREA','B_IU_CRA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CANCEL_REA_SOFT_INST','B_IU_CRTI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_PLAN','B_IU_CPN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_PLAN_HIST','B_IU_CPNH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_PLAN_TASK','B_IU_CPK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_PLAN_TASK_COUNT','B_IU_CTC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_PLAN_TASK_HIST','B_IU_CPKH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_PLAN_TASK_LINK','B_IU_CPL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_PLAN_TASK_REQ','B_IU_CPQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_PLAN_TASK_SOFT_INST','B_IU_CPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_PLAN_TYPE','B_IU_CPY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_STAGE','B_IU_CS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_STAGE_SET_PERMISSIONS','B_IU_CSSP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CARE_STAGE_WARN','B_IU_CSW_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CATEGORY','B_IU_CAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CATEGORY_SUB','B_IU_CATS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CHILD_FEED_DEV','B_IU_CFD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CHILD_FEED_DEV_INST','B_IU_CFDI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CITY','B_IU_CIY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CLINICAL_SERVICE','B_IU_CSE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CLIN_RECORD_HISTORY','B_IU_CRNH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CLIN_SERV_ALERT_DIAGNOSIS','B_IU_CSAD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CLIN_SERV_EXT_SYS','B_IU_CSES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CLIN_SRV_TYPE','B_IU_CST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CLI_REC_REQ','B_IU_CRR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CLI_REC_REQ_DET','B_IU_CRRD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CLI_REC_REQ_MOV','B_IU_CRM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMBINATION_COMPOUND','B_IU_CC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMBINATION_COMPOUND_UNIT_MEA','B_IU_CCUM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMBINATION_COMP_DET','B_IU_CCD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMB_DEP_CLIN_SERV','B_IU_CDCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMB_DRUG_DEP_CLIN_SERV','B_IU_CDDC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMB_UNIT_MEA_DEP_CLIN_SERV','B_IU_CUMDCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMPANY','B_IU_CMP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMPANY_DESC','B_IU_CMPD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMPLAINT','B_IU_CMPLT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMPLAINT_ALERT_DIAGNOSIS','B_IU_CAI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMPLAINT_SR_INTERV','B_IU_CSV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMPLAINT_TRIAGE_BOARD','B_IU_CTB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COMPLETE_HISTORY','B_IU_CMPL_HIST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CONF_BUTTON_BLOCK','B_IU_CBB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CONF_BUTTON_BLOCK_SOFT_INST','B_IU_CBBSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CONSULT_REQ','B_IU_CRQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CONSULT_REQ_PROF','B_IU_CRP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CONTAINER_CONFIG','B_IU_CONTAINER_CONFIG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CONTAINER_CONFIG_DETAIL','B_IU_COCD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CONTRACEPTIVE','B_IU_CPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CONTRA_INDIC','B_IU_CIC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CON_MED_ESP','B_IU_I_CON_MED_ESP_2_1_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CORE_DEV_LOG','B_IU_CODL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COUNTRY','B_IU_CTR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COUNTRY_COMPANY','B_IU_CNTCMP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COUNTRY_CURRENCY','B_IU_CNTRCURR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('COUNTRY_MARKET','B_IU_CTR_MRK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CO_SIGN_TASK','B_IU_CTK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CPT_CODE','B_IU_CPT_CODE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CPT_DIAG_COVERAGE','B_IU_CDC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CPT_DIAG_COVERAGE_HIST','B_IU_CDCH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRISIS_EPIS','B_IU_CEP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRISIS_LOG','B_IU_CLOG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRISIS_MACHINE','B_IU_CRISIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRISIS_MACHINE_DET','B_IU_CDET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRISIS_REPORT','B_IU_CREP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRISIS_SOFT_DETAILS','B_IU_CSD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRISIS_XML','B_IU_CXML_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRITERIA','B_IU_CRT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRITICAL_CARE','B_IU_CRC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRITICAL_CARE_DET','B_IU_CCRD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRITICAL_CARE_READ','B_IU_CCRR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CRIT_REL','B_IU_CRT_R_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('CURRENCY','B_IU_CUY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DATA_GOV_EVENT','B_IU_DGEV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DATA_GOV_INVALID_RECS','B_IU_DGIR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DCI_COLOR','B_IU_DCIC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DEMO_USER_NAMES','B_IU_DMPNM_PAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DEPARTMENT','B_IU_DEP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DEPENDENCY','B_IU_DPD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DEPT','B_IU_DPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DEPT_TEMPLATE','B_IU_DPT_TMPL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DEP_CLIN_SERV','B_IU_DCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DEP_CLIN_SERV_PERM','B_IU_DCSP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIAGNOSIS','B_IU_DIAG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIAGNOSIS_DEP_CLIN_SERV','B_IU_DSC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIAGNOSIS_EDIS','B_IU_DIED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIAGNOSIS_MARKET','B_IU_DIAG_MRK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIAGRAM_IMAGE','B_IU_DIAGIM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIAGRAM_LAYOUT','B_IU_DIAGL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIAGRAM_LAY_IMAG','B_IU_DIAGLI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIAGRAM_TOOLS','B_IU_DIAGT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIAGRAM_TOOLS_GROUP','B_IU_DIAGTG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIAG_LAY_DEP_CLIN_SERV','B_IU_DLDCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIET','B_IU_DIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIETARY_DRUG','B_IU_DDG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIET_INSTIT_SOFT','B_IU_DIST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIET_PROF_INSTIT','B_IU_DPI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIET_PROF_INSTIT_DET','B_IU_DPID_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIET_PROF_PREF','B_IU_DPP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIET_SCHEDULE','B_IU_DSE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIET_SCHEDULE_TIME','B_IU_DISE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DIET_TYPE','B_IU_DT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCHARGE','B_IU_DIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCHARGE_DEST','B_IU_DDST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCHARGE_DETAIL','B_IU_DSCH_DTL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCHARGE_DETAIL_HIST','B_IU_DISDH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCHARGE_FLASH_FILES','B_IU_DISFF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCHARGE_HIST','B_IU_DISH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCHARGE_NOTES','B_IU_DNT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCHARGE_NOTES_FOLLOW_UP','B_IU_DNU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCHARGE_REASON','B_IU_DRN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCHARGE_SCHEDULE','B_IU_DISCH_SCHED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCH_INSTRUCTIONS','B_IU_DINST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCH_INSTRUCTIONS_GROUP','B_IU_DIGR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCH_INSTR_RELATION','B_IU_DIR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCH_INSTR_SOFT_INST','B_IU_DISINST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCH_PREP_MESG','B_IU_DPM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCH_PROF_NOTES','B_IU_DPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCH_REAS_DEST','B_IU_DRD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISCH_REA_TRANSP_ENT_INST','B_IU_DTTEI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DISTRICT','B_IU_DST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DML_LOG','B_IU_DMLO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOCUMENTATION','B_IU_DOC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOCUMENTATION_BACK','B_IU_DOBA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOCUMENTATION_EXT','B_IU_DEXT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOCUMENTATION_REL','B_IU_DOCREL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOCUMENTATION_TYPE','B_IU_DOCTY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_ACTION','B_IU_DAN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_ACTION_CRITERIA','B_IU_DOCACTC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_ACTION_DOCUMENTATION','B_IU_DAD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_AREA','B_IU_DOCAREA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_AREA_INST_SOFT','B_IU_DOC_AREA_INST_SOFT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_AREA_INST_SOFT_PROF','B_IU_DAIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_AREA_SOFTWARE','B_IU_DASFT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_COMMENTS','B_IU_DC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_COMPONENT','B_IU_DOCCOMP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_CONFIG','B_IU_DOCCG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_CRITERIA','B_IU_DOCCRIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_DESTINATION','B_IU_DDN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_DIMENSION','B_IU_DOCDIM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_ELEMENT','B_IU_DOCE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_ELEMENT_CRIT','B_IU_DOCEC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_ELEMENT_DOMAIN','B_IU_DED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_ELEMENT_FUNCTION_PARAM','B_IU_DEFP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_ELEMENT_QUALIF','B_IU_DOCEQL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_ELEMENT_REL','B_IU_DOCER_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_EXAM_REPORT','B_IU_DER_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_EXTERNAL','B_IU_DEL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_FILE_TYPE','B_IU_DFE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_FUNCTION','B_IU_DOCF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_IMAGE','B_IU_DIG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_INFORMED_CONSENT','B_IU_DIC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_ORIGINAL','B_IU_DOG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_ORI_TYPE','B_IU_DOE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_QUALIFICATION','B_IU_DOCQUAL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_QUALIFICATION_REL','B_IU_DQR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_QUANTIFICATION','B_IU_DOCQUANT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_SPECIFICATION','B_IU_DSN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_TEMPLATE','B_IU_DOCTEMP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_TEMPLATE_AREA','B_IU_DTA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_TEMPLATE_CONTEXT','B_IU_DOTC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_TEMPLATE_DIAGNOSIS','B_IU_DOCTD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_TYPE','B_IU_DTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_TYPES_CONFIG','B_IU_DCG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DOC_TYPES_CONFIG_PROF','B_IU_DTCP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG','B_IU_DRUG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_BOLUS','B_IU_DBU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_BRAND','B_IU_DRBRA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_COMPOSITION','B_IU_DRUG_COMPOSITION_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_DEP_CLIN_SERV','B_IU_DCST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_DESPACHOS','B_IU_DRDP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_DESPACHOS_SOFT_INST','B_IU_DDSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_DRIP','B_IU_DDP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_EXPORT','B_IU_DREX_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_FORM','B_IU_DRFRM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_INSTIT_JUSTIFICATION','B_IU_DIN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_JUSTIFICATION','B_IU_DJN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PHARMA','B_IU_DRPHA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PHARMA_CLASS','B_IU_DRPHC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PHARMA_CLASS_LINK','B_IU_DPCL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PHARMA_INTERACTION','B_IU_DRPHA_DRPH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PLAN','B_IU_DRPLA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_POSOLOGIA','B_IU_DP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PRESCRIPTION','B_IU_DPN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PRESC_DET','B_IU_DPDT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PRESC_PLAN','B_IU_DRPRP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PRESC_PLAN_HIST','B_IU_DPPH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PRESC_PLAN_INTERV','B_IU_DPPI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PRESC_PLAN_SUPPLIES','B_IU_DPPS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PRESC_RESULT','B_IU_DRPR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_PROTOCOLS','B_IU_DPS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_REQ','B_IU_DRQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_REQ_DET','B_IU_DRDT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_REQ_DET_REFILL','B_IU_DRDR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_REQ_DET_STATE_TRANSITION','B_IU_DRDS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_REQ_DET_UNIDOSE','B_IU_DRDTU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_REQ_SUPPLY','B_IU_DRS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_REQ_SUP_STATE_TRANSITION','B_IU_DRSS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_REQ_UNIDOSE','B_IU_DRQU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_ROUTE','B_IU_DRRTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_TAKE_PLAN','B_IU_DRTKP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_TAKE_TIME','B_IU_DRTKT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_THERAPEUTIC_PROTOCOLS','B_IU_DTP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_UNIT','B_IU_DRUG_UNIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_UNIT_DEP_CLIN_SERV','B_IU_DUDCLS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('DRUG_UNIT_TESTE','B_IU_DRUT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EA_EPIS_INFO_EA','B_IU_EEIE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EA_IMP_EPISODE_EA','B_IU_EIEE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EA_IMP_MONITORIZATION_EA','B_IU_EIME_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EA_IMP_REFERRAL_EA','B_IU_EIRE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EA_IMP_VITAL_SIGN_EA','B_IU_EIVS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EA_LAB_TEST_EA','B_IU_ELTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EA_WOUNDS_EA','B_IU_EAWE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EBM','B_IU_GEBM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ECG_DOC','B_IU_ECG_DOC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EHR_ACCESS_AREA_DEF','B_IU_EAAD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EHR_ACCESS_CATEGORY','B_IU_EACY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EHR_ACCESS_CONTEXT','B_IU_EAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EHR_ACCESS_CONTEXT_SOFT','B_IU_EACS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EHR_ACCESS_FUNCTION','B_IU_EAF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EHR_ACCESS_LOG','B_IU_EAG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EHR_ACCESS_LOG_REASON','B_IU_EANR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EHR_ACCESS_PROFILE_RULE','B_IU_EAPR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EHR_ACCESS_PROF_RULE','B_IU_EAPF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EHR_ACCESS_REASON','B_IU_EARN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EHR_ACCESS_RULE','B_IU_EAE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EMB_DEP_CLIN_SERV','B_IU_EDV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPISODE','B_IU_EPIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_ANAMNESIS','B_IU_COMP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_ATTENDING_NOTES','B_IU_EAN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_BARTCHART','B_IU_EBAR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_BARTCHART_DET','B_IU_EBARD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_BODY_PAINTING','B_IU_BPG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_BODY_PAINTING_DET','B_IU_BPD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_COMPLAINT','B_IU_ECOMP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_CO_SIGNER','B_IU_EPIS_CO_SIGNER_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DIAGNOSIS','B_IU_EDS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DIAGNOSIS_HIST','B_IU_EDH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DIAGNOSIS_NOTES','B_IU_EDN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DIAGRAM','B_IU_EPD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DIAGRAM_DETAIL','B_IU_EDD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DIAGRAM_DETAIL_NOTES','B_IU_EDDN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DIAGRAM_LAYOUT','B_IU_EDL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DIET','B_IU_EDT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DIET_DET','B_IU_EDTD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DIET_REQ','B_IU_EDR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DOCUMENTATION','B_IU_EPISD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DOCUMENTATION_BACK','B_IU_EPDB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DOCUMENTATION_DET','B_IU_EPISDD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DOCUMENTATION_QUALIF','B_IU_EDQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DOC_DELIVERY','B_IU_EDDY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DOC_TEMPLATE','B_IU_EPID_DOC_TEMPLATE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_DRUG_USAGE','B_IU_DUE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_EXT_SYS','B_IU_EES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_FAST_TRACK','B_IU_EFT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_HIDRICS','B_IU_EHID_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_HIDRICS_BALANCE','B_IU_EHBE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_HIDRICS_DET','B_IU_EHIDD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_INFO','B_IU_EPIS_INFO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_INSTITUTION','B_IU_EIN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_INTERV','B_IU_EIV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_INTERVAL_NOTES','B_IU_EINOTES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_OBSERVATION','B_IU_OBV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_OBS_EXAM','B_IU_EOE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_OBS_PHOTO','B_IU_EOP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_PHOTO','B_IU_EPO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_POSITIONING','B_IU_EPG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_POSITIONING_DET','B_IU_EPGD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_POSITIONING_PLAN','B_IU_EPGP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_PREGNANCY','B_IU_EPRE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_PROBLEM','B_IU_EPP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_PROF_DCS','B_IU_EPIS_PDCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_PROF_REC','B_IU_EPRC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_PROF_RESP','B_IU_EPR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_PROTOCOLS','B_IU_EPIS_PROT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_READMISSION','B_IU_ERN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_RECOMEND','B_IU_ERND_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_REPORT','B_IU_EREPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_REPORT_SECTION','B_IU_ERNS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_REVIEW_SYSTEMS','B_IU_ERSY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_RISK_FACTOR','B_IU_ERF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_SIGN_OFF','B_IU_EPIS_SIGN_OFF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_STATUS_ACCESS','B_IU_EPIS_STATUS_ACCESS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_SUPPLIES','B_IU_EPIS_SUPPL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_SUPPLIES_DET','B_IU_EPIS_SUPPLD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_TASK_DEPRECATED','B_IU_ETK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_TRIAGE','B_IU_ETRG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_TYPE','B_IU_ETE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_TYPE_ACCESS','B_IU_ETA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_TYPE_ROOM','B_IU_ETR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPIS_TYPE_SOFT_INST','B_IU_ETSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EPR_TEST','B_IU_EPTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EQUIP_PROTOCOLS','B_IU_EQPR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ESCAPE_DEPARTMENT','B_IU_ED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ESTATE','B_IU_EST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EVAL_MNG','B_IU_EVAL_MNG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EVENT','B_IU_EVT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EVENT_GROUP','B_IU_EG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EVENT_GROUP_SOFT_INST','B_IU_EGSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EVENT_MOST_FREQ','B_IU_EMQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EVENT_QUEUE_TAB','B_IU_SYS_C00374779_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM','B_IU_EXAM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAMS_EA','B_IU_EEA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_ALIAS','B_IU_EAS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_CAT','B_IU_ECT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_CAT_DCS','B_IU_ECC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_CAT_DCS_EXT_SYS','B_IU_ECES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_DEP_CLIN_SERV','B_IU_ECST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_DRUG','B_IU_EDG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_EGP','B_IU_EXMG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_GROUP','B_IU_EGP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_MARKET','B_IU_EXAM_MRK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_PREP_MESG','B_IU_EPMG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_PROTOCOLS','B_IU_EPS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_REQ','B_IU_EREQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_REQ_DET','B_IU_ERD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_RESULT','B_IU_ERES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_RESULT_PREGNANCY','B_IU_ERY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_RES_FETUS_BIOM','B_IU_ERB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_RES_FETUS_BIOM_IMG','B_IU_ERG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_RES_PREGN_FETUS','B_IU_ERU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_ROOM','B_IU_ERM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_SCHEDULE_DCS','B_IU_ESC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_TYPE','B_IU_ET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_TYPE_GROUP','B_IU_ETG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_TYPE_TEMPLATE','B_IU_ETL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXAM_TYPE_VS','B_IU_ETVS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXTERNAL_CAUSE','B_IU_EXTC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXTERNAL_DOC','B_IU_EDOC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXTERNAL_DOC_CANCEL','B_IU_EXDC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('EXTERNAL_DOC_TMP','B_IU_EXDT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FAMILY_MONETARY','B_IU_FMY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FAMILY_MONETARY_HIST','B_IU_FMH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FAMILY_RELATIONSHIP','B_IU_FRP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FAMILY_RELATIONSHIP_RELAT','B_IU_FRN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FAST_TRACK','B_IU_FT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FAST_TRACK_DISABLE','B_IU_FTD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FAST_TRACK_INSTITUTION','B_IU_FTINST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_DOSAGE_FORM','B_IU_FDDF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_FIRM_NAME_DATA','B_IU_FFND_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_FORMULATIONS_DATA','B_IU_FDFD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_LISTINGS_DATA','B_IU_FDLD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_NEW_DRUG','B_IU_FDND_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_PACKAGES_DATA','B_IU_FDPD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_REG_SITES','B_IU_FDRS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_ROUTE_DATA','B_IU_FDRD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_SCHEDULE','B_IU_FDSC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_TBLDOSAG','B_IU_FDTB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_TBLROUTE','B_IU_FDTBE235_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FDA_TBLUNIT','B_IU_FDTBT236_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FHELP_TREE','B_IU_FHTR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FLOORS','B_IU_FLO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FLOORS_DEPARTMENT','B_IU_FLSDEP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FLOORS_DEP_POSITION','B_IU_FLSDEPP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FLOORS_INSTITUTION','B_IU_FINST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FLUIDS_PRESC_DET','B_IU_FLUIDS_PRESC_DET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FOLLOW_UP_ENTITY','B_IU_FUE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FOLLOW_UP_ENTITY_SOFT_INST','B_IU_FUSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FOLLOW_UP_TYPE','B_IU_F_UP_TY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FORM_FARM_AUX','B_IU_FOFA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FORM_FARM_UNIT','B_IU_FFU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FORM_FARM_UNIT_TESTE','B_IU_FFUT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FUNCTIONALITY','B_IU_FUNC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('FUNCTIONALITY_STEP','B_IU_FUST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GEN_AREA','B_IU_GA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GEN_AREA_RANK','B_IU_GAR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GEN_AREA_RANK_CRITERIA','B_IU_GARC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GEO_LOCATION','B_IU_GLN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GEO_STATE','B_IU_GSE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GINEC_OBSTET','B_IU_OCE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRAFFAR_CRITERIA','B_IU_GCA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRAFFAR_CRIT_VALUE','B_IU_GCV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRAPHIC','B_IU_GRAPHIC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRAPHIC_LINE','B_IU_GPH_LINE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRAPHIC_LINE_POINT','B_IU_GPH_LINE_POINT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRAPHIC_SOFT_INST','B_IU_GSO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRAPH_SCALE','B_IU_GS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRAPH_SCALE_CELL','B_IU_GSC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRID_TASK','B_IU_GTK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRID_TASK_BETWEEN','B_IU_GTN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRID_TASK_IMG','B_IU_GTI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRID_TASK_LAB','B_IU_GTLAB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GRID_TASK_OTH_EXM','B_IU_GTOE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GROUPS','B_IU_GRP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GROUPS_DEPT','B_IU_GDPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GROUPS_DEPT_HIST','B_IU_GDPTH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GROUPS_HIST','B_IU_GRPH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GROUP_PENDING_ISSUES','B_IU_GPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GROUP_PENDING_ISSUES_HIST','B_IU_GPT_HIST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GTT_EPIS_DOCUMENT_VAL','B_IU_GEDV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE','B_IU_GUE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_ACTION_CATEGORY','B_IU_GAY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_ADV_INPUT_VALUE','B_IU_GAIV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_BATCH','B_IU_GBH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_CONTEXT_AUTHOR','B_IU_GCTR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_CONTEXT_IMAGE','B_IU_GCE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_CRITERIA','B_IU_GCR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_CRITERIA_LINK','B_IU_GCK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_CRITERIA_TYPE','B_IU_GCTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_FREQUENT','B_IU_GFT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_ITEM_SOFT_INST','B_IU_GIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_LINK','B_IU_GLK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_PROCESS','B_IU_GPS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_PROCESS_TASK','B_IU_GPK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_PROCESS_TASK_DET','B_IU_GPTD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_PROCESS_TASK_HIST','B_IU_GPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_TASK_LINK','B_IU_GTL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('GUIDELINE_TYPE','B_IU_GTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HABIT','B_IU_HAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HARVEST','B_IU_HARV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HCN_DEF_CRIT','B_IU_HCN_DEF_CRIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HCN_DEF_POINTS','B_IU_HCN_DEF_POINTS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HCN_DOCAREA_DEPT','B_IU_HCN_DOCAREA_DEPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HCN_EVAL','B_IU_HCN_EVAL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HCN_EVAL_DET','B_IU_HCN_EVAL_DET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HCN_PAT_DET','B_IU_HCN_PAT_DET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEADER','B_IU_HEADER_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEADER_CFG','B_IU_HEADER_CFG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEADER_TAG','B_IU_HEADER_TAG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEADER_TAG_GRP','B_IU_HEADER_TAG_GRP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEADER_XML','B_IU_HEXM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEALTH_PROGRAM','B_IU_HPG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEALTH_PROGRAM_EVENT','B_IU_HPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEALTH_PROGRAM_SOFT_INST','B_IU_HPSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEA_HEADER_TAG','B_IU_HEA_HEADER_TAG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEMO_PROTOCOLS','B_IU_HEMO_PROT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEMO_REQ','B_IU_HEMO_REQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEMO_REQ_DET','B_IU_HEMO_RD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEMO_REQ_SUPPLY','B_IU_HEMO_RS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HEMO_TYPE','B_IU_HEMO_TYPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HIDRICS','B_IU_HID_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HIDRICS_INTERVAL','B_IU_HIDIN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HIDRICS_RELATION','B_IU_HRN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HIDRICS_TYPE','B_IU_HIDT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HIST_ANALYSIS_REQ','B_IU_HIAR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HIST_ANALYSIS_REQ_DET','B_IU_HARD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('HOME','B_IU_HOME_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICD','B_IU_ICD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICD9_DXID','B_IU_ICD9_DXID_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICF','B_IU_ICF2_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICF_QUALIFICATION','B_IU_ICFQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICF_QUALIFICATION_REL','B_IU_IQR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICF_QUALIFICATION_SCALE','B_IU_IQS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICF_QUALIF_SCALE_REL','B_IU_IQL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICF_SOFT_INST','B_IU_IIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_APPLICATION_AREA','B_IU_IAA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_AXIS','B_IU_IA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_AXIS_DCS','B_IU_IADCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_COMPOSITION','B_IU_ICN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_COMPOSITION_HIST','B_IU_ICH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_COMPOSITION_TERM','B_IU_ICT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_COMPO_CLIN_SERV','B_IU_ICV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_COMPO_DCS','B_IU_ICC_I_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_COMPO_FOLDER','B_IU_ICR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_COMPO_INST','B_IU_ICI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_DEFAULT_COMPO_FOLDER','B_IU_IHR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_DEFAULT_PREDIFINED_ACTION','B_IU_IDN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_DICTIONARY','B_IU_IDY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_EPIS_DIAGNOSIS','B_IU_EIPD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_EPIS_DIAG_INTERV','B_IU_IEDI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_EPIS_INTERVENTION','B_IU_EIPI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_EPIS_INTERVENTION_HIST','B_IU_IEIH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_EPIS_TASK','B_IU_ICNP_EPIS_TASK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_FOLDER','B_IU_IFR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_INTERV_PLAN','B_IU_IIP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_MORPH','B_IU_ILC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_PREDEFINED_ACTION','B_IU_IDA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_PREDEFINED_ACTION_HIST','B_IU_IPAH_HST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_TERM','B_IU_IT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICNP_TRANSITION_STATE','B_IU_ITE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ICPC','B_IU_ICPC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('IDENTIFICATION_NOTES','B_IU_INOTES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('IMPLEMENTATION','B_IU_IMPL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INE_LOCATION','B_IU_ILN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_ATC','B_IU_IAC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_ATC_LNK','B_IU_IAL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_CFT','B_IU_ICF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_CFT_LNK','B_IU_ICL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_CLASS_DISP','B_IU_ICDP237_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_CLASS_ESTUP','B_IU_ICE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_COMERC','B_IU_ICC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_COMERC_ERRO','B_IU_INCE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_DCIPT','B_IU_IDT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_DIABETES_LNK','B_IU_IDK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_DIPLOMA','B_IU_IDM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_DISPO','B_IU_IDO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_EMB','B_IU_IEB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_EMB_COMERC','B_IU_IEC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_EMB_NEW_ERRO','B_IU_IENE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_EMB_UNIT','B_IU_IET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_ESTADO_AIM','B_IU_IEM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_FORM_FARM','B_IU_IFF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_GRUPO_HOM','B_IU_IGM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_MED','B_IU_IMD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_PATOL_DIP_LNK','B_IU_IPDL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_PATOL_ESP','B_IU_IPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_PATOL_ESP_LNK','B_IU_IPEL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_PRECO','B_IU_IPO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_SUBST','B_IU_IST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_SUBST_LNK','B_IU_INSL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_TIPO_DIAB_MEL','B_IU_ITL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_TIPO_PRECO','B_IU_ITP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_TIPO_PROD','B_IU_ITD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_TITULAR_AIM','B_IU_ITA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_TRATAMENTO','B_IU_ITO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_TRATAMENTO_NEW','B_IU_INTN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_VIAS_ADMIN','B_IU_IVA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INF_VIAS_ADMIN_LNK','B_IU_IVK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INGREDIENT','B_IU_ING_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INSTITUTION','B_IU_INST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INSTITUTION_ACCOUNTS','B_IU_IACC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INSTITUTION_EXT','B_IU_INSTEX_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INSTITUTION_EXT_ACCOUNTS','B_IU_IEACC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INSTITUTION_EXT_HIST','B_IU_INSTEXH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INSTITUTION_HIST','B_IU_INSH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INSTITUTION_LANGUAGE','B_IU_ITLG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INSTITUTION_LOGO','B_IU_ILO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INSTIT_EXT_CLIN_SERV','B_IU_INEXCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INSTIT_EXT_CLIN_SERV_HIST','B_IU_INEXCSH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INSTIT_EXT_SYS','B_IU_IESS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INST_ATTRIBUTES','B_IU_ISE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INST_TYPE','B_IU_INSTTP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERVAL_CONDITIONS','B_IU_INTC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERVENTION','B_IU_INT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERVENTION_ALIAS','B_IU_INTA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERVENTION_MARKET','B_IU_INT_MRK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERVENTION_TIMES','B_IU_ITI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_CATEGORY','B_IU_ICY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_CONDITION','B_IU_ICN2_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_CONDITION_ICF','B_IU_ICI2_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_DEP_CLIN_SERV','B_IU_ICS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_DRUG','B_IU_IDG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_EVALUATION','B_IU_IEND_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_EVALUATION_ICF','B_IU_IEI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_EVAL_ICF_QUALIF','B_IU_IEIQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_ICNP_EA','B_IU_IIA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_INT_CAT','B_IU_IIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PAT_PROBLEM','B_IU_IPATP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PHYSIATRY_AREA','B_IU_IPA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PREP_MSG','B_IU_IPM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PRESCRIPTION','B_IU_PRESC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PRESC_DET','B_IU_IPD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PRESC_DET_CHANGE','B_IU_IPDC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PRESC_DET_CONTEXT','B_IU_IPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PRESC_DET_HIST','B_IU_IPDH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PRESC_PLAN','B_IU_IPP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PRESC_PLAN_HIST','B_IU_IPPH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PROF_ALLOC','B_IU_IPC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_PROTOCOLS','B_IU_IPS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_ROOM','B_IU_IRM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('INTERV_TIME_OUT','B_IU_INTO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('IRREGULAR_DIRECTIONS','B_IU_ID_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('IRREGULAR_DIRECTIONS_DCS_REL','B_IU_IDDCSR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('IRREGULAR_DIRECTIONS_TIME','B_IU_IDTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('IRREGULAR_FREQUENCY','B_IU_IF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('IRREGULAR_INTERVAL','B_IU_II_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ISSUE','B_IU_ISSUE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ISSUE_MESSAGE','B_IU_ISSUE_MESSAGE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ISSUE_PROF_ASSIGNED','B_IU_IPRD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('IV_FLUIDS_GROUP','B_IU_IV_FLUIDS_GROUP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LAB_TESTS_EA','B_IU_LTA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LAB_TEST_PARAMETER_LOINC','B_IU_LTC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LANGUAGE','B_IU_LANG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LENS','B_IU_LEN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LENS_ADVANCED_INPUT','B_IU_LAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LENS_PRESC','B_IU_LPC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LENS_PRESC_DET','B_IU_LPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LENS_PRESC_HIST','B_IU_LPH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LENS_SOFT_INST','B_IU_LST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LICENSE','B_IU_LICEN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LOCATION','B_IU_LOCATION_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LOCATION_TAX','B_IU_LOCTAX_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('LOG_ERROR','B_IU_LOER_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MANIPULATED','B_IU_MDG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MANIPULATED_GROUP','B_IU_MGP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MANIPULATED_INGREDIENT','B_IU_MIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MARKET','B_IU_MRK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MATCH_EPIS','B_IU_MTCH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MATERIAL','B_IU_MATR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MATR_DEP_CLIN_SERV','B_IU_MCST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MATR_ROOM','B_IU_MRM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MATR_SCHEDULED','B_IU_MSD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MCDT_REQ_DIAGNOSIS','B_IU_MRD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MCS_CONCEPT','B_IU_CON_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MCS_RELATION','B_IU_MCSREL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MCS_SOURCE','B_IU_SRC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MCS_TRANSLATION','B_IU_MTN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MDM_CODING','B_IU_MDMC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MDM_EVALUATION','B_IU_MDME_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MDM_PROF_CODING','B_IU_MPC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MED_ALRGN_ALLERGY_LINK','B_IU_MAA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MED_ALRGN_CROSS','B_IU_MCN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MED_ALRGN_CROSS_GRP','B_IU_MCGN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MED_ALRGN_GRP','B_IU_MGN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MED_ALRGN_GRP_INGRED','B_IU_MGD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MED_ALRGN_PICK_LIST','B_IU_MAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MED_ALRGN_PICK_LIST_TYP','B_IU_MAE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MED_INGRED','B_IU_MID_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MED_UNITS_INFO','B_IU_MEUI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MENU','B_IU_SYS_C00382289_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_DIETARY','B_IU_ME_DIETARY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_DXID_ATC_CONTRA','B_IU_ME_DXID_ATC_CONTRA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_INGRED','B_IU_ME_INGRED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MANIP','B_IU_ME_MANIP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MANIP_GROUP','B_IU_ME_MANIP_GROUP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MANIP_INGRED','B_IU_ME_MANIP_INGRED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MED','B_IU_ME_MED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MED_ATC','B_IU_ME_MED_ATC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MED_ATC_INTERACTION','B_IU_MMAI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MED_DRCM','B_IU_MEMM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MED_INGRED','B_IU_MEMD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MED_PHARM_GROUP','B_IU_ME_MED_PHARM_GROUP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MED_PRICE_HIST_DET','B_IU_MMPH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MED_REGULATION','B_IU_ME_MED_REGULATION_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MED_ROUTE','B_IU_ME_MED_ROUTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_MED_SUBST','B_IU_ME_MED_SUBST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_PHARM_GROUP','B_IU_ME_PHARM_GROUP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_PRICE_TYPE','B_IU_ID_ME_PRICE_TYPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_REGULATION','B_IU_ME_REGULATION_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ME_ROUTE','B_IU_ME_ROUTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MFR_SCHEDULE_INTV','B_IU_MFSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_DXID_ATC_CONTRA','B_IU_MI_DXID_ATC_CONTRA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_JUSTIFICATION','B_IU_MI_JUSTIFICATION_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_MED','B_IU_MI_MED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_MED_ATC','B_IU_MI_MED_ATC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_MED_ATC_INTERACTION','B_IU_MMAIN239_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_MED_COMMERC','B_IU_MMC_CMM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_MED_DRCM','B_IU_MMM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_MED_INGRED','B_IU_MIMI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_MED_PHARM_GROUP','B_IU_MI_MED_PHARM_GROUP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_MED_REGULATION','B_IU_MI_MED_REGULATION_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_PHARM_GROUP','B_IU_MI_PHARM_GROUP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_REGULATION','B_IU_MI_REGULATION_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MI_ROUTE','B_IU_MI_ROUTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MONITORIZATION','B_IU_MONT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MONITORIZATIONS_EA','B_IU_MEA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MONITORIZATION_EA_SAMPLE','B_IU_MES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MONITORIZATION_VS','B_IU_MVS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MONITORIZATION_VS_PLAN','B_IU_MVSP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MOVEMENT','B_IU_MOV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('MV_AUDITRECORD','B_IU_MVAU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('NCH_LEVEL','B_IU_NCHL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('NECESSITY','B_IU_NSS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('NOTES_CONFIG','B_IU_NOTES_CFG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('NOTES_GROUP','B_IU_NGP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('NOTES_GRP_CFG','B_IU_NGG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('NOTES_PROFILE_INST','B_IU_NOTES_PI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('NURSE_ACTIVITY_REQ','B_IU_NAR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('NURSE_ACTV_REQ_DET','B_IU_NARD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('NURSE_DISCHARGE','B_IU_NDE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('NURSE_TEA_REQ','B_IU_NTR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ON_CALL_PHYSICIAN','B_IU_OCP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('OPINION','B_IU_OPN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('OPINION_PROF','B_IU_OPF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_SET','B_IU_ODST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_SET_FREQUENT','B_IU_OSF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_SET_LINK','B_IU_OSL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_SET_PROCESS','B_IU_OSP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_SET_PROCESS_TASK','B_IU_OSPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_SET_PROCESS_TASK_DET','B_IU_OSPD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_SET_PROCESS_TASK_LINK','B_IU_OSPL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_SET_TASK','B_IU_OSTK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_SET_TASK_DETAIL','B_IU_OSTD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_SET_TASK_LINK','B_IU_OSTL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_SET_TASK_SOFT_INST','B_IU_OSTS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORDER_TYPE','B_IU_OTP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ORIGIN_SOFT_INST','B_IU_ORSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('OTHER_PRODUCT','B_IU_OP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('OTHER_PRODUCT_PRESCRIPTION','B_IU_OPP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('OTHER_PRODUCT_SOFT_INST','B_IU_OPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_ANALYSIS_DEFAULT_DEST','B_IU_PAT_DEF_DEST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_DATA_EXPORT_CONFIG','B_IU_PDG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_DEST_INSTITUTION','B_IU_PDN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_DEST_INSTITUTION_DENY','B_IU_PDIY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_DETAIL','B_IU_PEL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_EXAM_DEFAULT_DEST','B_IU_PET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_EXR_ANALYSIS','B_IU_PEY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_EXR_DIAGNOSIS','B_IU_PEI_DIAG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_EXR_EXAM','B_IU_PEM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_EXR_INTERVENTION','B_IU_PEN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_EXR_TEMP','B_IU_PEP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_EXTERNAL_REQUEST','B_IU_ERTX_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_GRID_CONFIG','B_IU_PGG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_INTERV_DEFAULT_DEST','B_IU_PINTDD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_MATCH','B_IU_P1MATCH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_ORIGIN_APPROVAL_CONFIG','B_IU_POAG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_REASON_CODE','B_IU_PRE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_SPECIALITY','B_IU_PSY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_SPEC_DCS_HELP','B_IU_PSP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_SPEC_DEP_CLIN_SERV','B_IU_PSV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_SPEC_HELP','B_IU_PSH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_TASK','B_IU_P1_TASK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_TASK_DONE','B_IU_P1_TASK_DONE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_TRACKING','B_IU_ERT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('P1_WORKFLOW_CONFIG','B_IU_PWG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PASSWD_HIST','B_IU_PH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PATIENT_CARE_INST','B_IU_PCI_PTF_INST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PATIENT_CARE_INST_HISTORY','B_IU_PCIH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_ADVANCE_DIRECTIVE','B_IU_PATADVDIR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_ADVANCE_DIRECTIVE_DET','B_IU_PDVDDT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_ADV_DIRECTIVE_DOC','B_IU_PDVDDOC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_ALLERGY','B_IU_PAL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_ALLERGY_HIST','B_IU_PAH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_ALLERGY_SYMPTOMS','B_IU_PAAS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_ALLERGY_SYMPTOMS_HIST','B_IU_PASH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_ALLERGY_UNAWARENESS','B_IU_PAU_ID_AU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_BLOOD_GROUP','B_IU_PBG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_CHILD_CLIN_REC','B_IU_PCCR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_CHILD_FEED_DEV','B_IU_PCF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_CIT','B_IU_PCIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_CIT_HIST','B_IU_PCITH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_CLI_ATTRIBUTES','B_IU_PTCAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_CNTRCEPTIV','B_IU_PCE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_DELIVERY','B_IU_PDY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_FAMILY','B_IU_PTFAM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_FAMILY_DISEASE','B_IU_PTFDI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_FAMILY_MEMBER','B_IU_PTFMM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_FAMILY_PROF','B_IU_PFP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_FAM_SOC_HIST','B_IU_PFSH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_FKS','B_IU_PAFK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_GINEC','B_IU_PTGC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_GINEC_OBSTET','B_IU_PGC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_GRAFFAR_CRIT','B_IU_PGCT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_HABIT','B_IU_PTNOT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_HEALTH_PROGRAM','B_IU_PHPG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_HEALTH_PROGRAM_HIST','B_IU_PHPH_PK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_HISTORY','B_IU_PHY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_HISTORY_DIAGNOSIS','B_IU_PHI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_HISTORY_HIST','B_IU_PHH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_HISTORY_TYPE','B_IU_PHE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_MEDICATION','B_IU_PMN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_MEDICATION_DET','B_IU_PMDET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_MEDICATION_HIST_LIST','B_IU_PMHL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_MEDICATION_LIST','B_IU_PML_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_MED_DECL','B_IU_PMD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_NOTES','B_IU_PNS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PERIODIC_OBSERVATION','B_IU_PPO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PERIODIC_OBS_HIST','B_IU_PPOH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PERMISSION','B_IU_PPN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PREGNANCY','B_IU_PPY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PREGNANCY_HIST','B_IU_PPYH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PREGNANCY_RH_HIST','B_IU_PPYRH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PREGNANCY_RISK','B_IU_PGR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PREGN_FETUS','B_IU_PPF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PREGN_FETUS_BIOM','B_IU_PPFB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PREGN_FETUS_DET','B_IU_PPFD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PREGN_FETUS_HIST','B_IU_PPFH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PREGN_INST_ASSIST','B_IU_PPINST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PREGN_MEASURE','B_IU_PPME_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PROBLEM','B_IU_PPM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PROBLEM_HIST','B_IU_PPH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_PROB_VISIT','B_IU_PPV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_REFERRAL','B_IU_PRL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_SICK_LEAVE','B_IU_PBA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_VACC','B_IU_PV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_VACCINE','B_IU_PVE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_VACC_ADM','B_IU_PAVAA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PAT_VACC_ADM_DET','B_IU_PAVAAD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PENDING_ISSUE','B_IU_PI_ID_PI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PENDING_ISSUE_INVOLVED','B_IU_PEII_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PENDING_ISSUE_MESSAGE','B_IU_PIM_ID_PIM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PENDING_ISSUE_PROF','B_IU_PIP_ID_PIP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PENDING_ISSUE_TITLE','B_IU_PITT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PENDING_ISSUE_TITLE_DEPT','B_IU_PITD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PENDING_ISSUE_TITLE_DEPT_HIST','B_IU_PTDH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PENDING_ISSUE_TITLE_HIST','B_IU_PITH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PERIODIC_EXAM_EDUC','B_IU_PEE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PERIODIC_OBSERVATION_DESC','B_IU_POD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PERIODIC_OBSERVATION_PARAM','B_IU_PEOP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PERIODIC_OBSERVATION_REG','B_IU_POR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PERIODIC_PARAM_TYPE','B_IU_PEPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PHARMACY_STATUS','B_IU_PSU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PHYSIATRY_AREA','B_IU_PA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PHYSIATRY_AREA_TEMPLATE','B_IU_PHAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PLANT','B_IU_PLANT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PML_DEP_CLIN_SERV','B_IU_PML_DCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('POSITIONING','B_IU_POG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('POSITIONING_TYPE','B_IU_PTYPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PREFERRED_TIME','B_IU_PRTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PREGNANCY_REGISTER','B_IU_PR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PREGNANCY_RISK_EVAL','B_IU_GRE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PREP_MESSAGE','B_IU_PME_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC','B_IU_PRES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION','B_IU_PRN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_INSTR_HIST','B_IU_PIH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_MATCH','B_IU_PRESCRIPTION_MATCH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_NUMBER_SEQ','B_IU_PNQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_PHARM','B_IU_PRM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_PHARM_DET','B_IU_PPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_PHARM_REFILL','B_IU_PRPR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_PRINT','B_IU_PRPRT243_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_STD_INSTR','B_IU_PREC_STC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_TYPE','B_IU_PTY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_TYPE_ACCESS','B_IU_PTYA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_WORKFLOW','B_IU_PRWO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_XML','B_IU_PXL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESCRIPTION_XML_DET','B_IU_PRXD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_ADVERSE_DOSAGE','B_IU_PDK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_ADVERSE_DOSAGE_HIST','B_IU_PATH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_ATTENTION_DET','B_IU_PAD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_HOSP_PHARMACY','B_IU_PRESC_HOS_PHARMACY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_INTERACTIONS','B_IU_PRIN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_INTERACTIONS_HIST','B_IU_PINH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_P','B_IU_PRP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_PAT_PROBLEM','B_IU_PPP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_PAT_PROBLEM_HIST','B_IU_PPPH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_P_XML','B_IU_PRPX_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_WARN_READ_NOTES','B_IU_PWN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRESC_XML','B_IU_PRXM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRE_HOSP_ACCIDENT','B_IU_PR_HSP_ACC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRE_HOSP_VS_READ','B_IU_PR_HSP_VSR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROCEDURES_EA','B_IU_PROCEDURES_EA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRODUCT_PURCHASABLE','B_IU_PRDPRCH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PRODUCT_PURCHASABLE_DESC','B_IU_PRDPRCHD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFESSIONAL','B_IU_PROF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFESSIONAL_EXT','B_IU_PREX_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFESSIONAL_EXT_HIST','B_IU_PREXH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFILE_CONTEXT','B_IU_PROF_CONT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFILE_DISCH_REASON','B_IU_PDR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFILE_TEMPLATE','B_IU_SPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFILE_TEMPLATE_CATEGORY','B_IU_PTC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFILE_TEMPLATE_DESC','B_IU_PTD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFILE_TEMPLATE_INST','B_IU_PTI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFILE_TEMPL_ACCESS','B_IU_PTA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFILE_TEMPL_ACCESS_EXCEPTION','B_IU_PTAE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROFILE_TEMPL_ACC_FUNC','B_IU_PTAF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_ACCESS','B_IU_PASS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_ACCESS_FIELD_FUNC','B_IU_PAFF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_ACCOUNTS','B_IU_PACC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_CAT','B_IU_PCT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_CONF_BUTTON_BLOCK','B_IU_PCBB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_DEP_CLIN_SERV','B_IU_PCST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_DEP_CLIN_SERV_HIST','B_IU_PCSTH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_DOC','B_IU_PDC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_DONT_SHOW_AGAIN','B_IU_PDSA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_EPIS_INTERV','B_IU_PEI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_EXT_ACCOUNTS','B_IU_PEACC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_EXT_SYS','B_IU_PESS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_FUNC','B_IU_PFC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_GROUPS','B_IU_PG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_GROUPS_HIST','B_IU_PGRPH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_GROUP_PENDING_ISSUES','B_IU_PGE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_GROUP_PENDING_ISSUES_HIST','B_IU_PGH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_INSTITUTION','B_IU_PRINS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_IN_OUT','B_IU_PIO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_PHOTO','B_IU_PFPO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_PHYSIATRY_AREA','B_IU_PPA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_PREFERENCES','B_IU_PPS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_PROFILE_TEMPLATE','B_IU_PTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_ROOM','B_IU_SPR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_SOFT_INST','B_IU_PSIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_TEAM','B_IU_PROF_TEAM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_TEAM_BED','B_IU_PROF_TEAMB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_TEAM_CATEGORY','B_IU_PRTCAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_TEAM_CLIN_SERV','B_IU_PRTCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_TEAM_DET','B_IU_PRF_TEAM_D_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_TEAM_DET_EA','B_IU_PRF_TEAM_DEA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_TEAM_DET_HIST','B_IU_PRF_TEAM_DH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_TEAM_EA','B_IU_PROF_TEAMEA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_TEAM_HIST','B_IU_PROF_TEAMH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROF_TEAM_ROOM','B_IU_PROF_TEAMR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROGRESS_NOTES','B_IU_PRNO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL','B_IU_PTL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOLS','B_IU_PRT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOLS_TASKS','B_IU_PRTAS245_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_ACTION_CATEGORY','B_IU_PAY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_ADV_INPUT_VALUE','B_IU_PAIV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_BATCH','B_IU_PBH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_CONNECTOR','B_IU_PTLC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_CONTEXT_AUTHOR','B_IU_PCR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_CONTEXT_IMAGE','B_IU_PCET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_CRITERIA','B_IU_PCA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_CRITERIA_LINK','B_IU_PCK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_CRITERIA_TYPE','B_IU_PCTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_ELEMENT','B_IU_PTLE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_FREQUENT','B_IU_PFT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_ITEM_SOFT_INST','B_IU_PIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_LINK','B_IU_PLK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_PROCESS','B_IU_PPTS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_PROCESS_ELEMENT','B_IU_PPK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_PROCESS_ELEMENT_HIST','B_IU_PPTHIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_PROCESS_TASK_DET','B_IU_PPTD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_PROTOCOL','B_IU_PPL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_QUESTION','B_IU_PTK_1_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_RELATION','B_IU_PTLR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_TASK','B_IU_PTK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_TEXT','B_IU_PTK_TXT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOCOL_TYPE','B_IU_PROTTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PROTOC_DIAG','B_IU_PDIG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PURGE_SYS_ALERT_EVENT','B_IU_PSAE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('PURGE_SYS_ALERT_READ','B_IU_PSAR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('RECM','B_IU_RECM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('RECORDS_REVIEW','B_IU_RRW_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('RECORDS_REVIEW_READ','B_IU_RRWR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REFERRAL_DEPENDENCY','B_IU_RDT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REFERRAL_EA','B_IU_REA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REL_PAT_CLIN_SERV','B_IU_RPCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REPORTS','B_IU_REP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REPORTS_DOC','B_IU_REDO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REPORTS_GEN_PARAM','B_IU_REPGPAR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REPORTS_GEN_PARAM_INTERVAL','B_IU_REPGPARINT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REPORTS_GEN_PARAM_PROFS','B_IU_REPGPARPRF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REPORTS_GROUP','B_IU_REPGP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REPORTS_INST_SOFT','B_IU_RIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_DESTINATION','B_IU_RDN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_EDIT_REPORT','B_IU_REP_EDIT_REPORT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_MFR_NOTIFICATION','B_IU_RMN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_ORDER_TYPE','B_IU_ROT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_ORDER_TYPE_REPORT','B_IU_ROTR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_PROFILE_TEMPLATE','B_IU_RPTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_PROFILE_TEMPLATE_DET','B_IU_RPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_PROF_EXCEPTION','B_IU_RPNX_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_PROF_TEMPLATE','B_IU_RPEPR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_PROF_TEMPL_ACCESS','B_IU_RPSAC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_SCREEN','B_IU_SFC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_SECTION','B_IU_RSN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_SECTION_DET','B_IU_RGP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_SECTION_GROUP','B_IU_RSP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('REP_SOFT','B_IU_RSFT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('RESET_EPIS_PRESERVE','B_IU_SYS_C00261005_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('RESET_GUIDELINE_PROTOCOL','B_IU_REGP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('RESULT_STATUS','B_IU_RSS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('RISK_FACTOR','B_IU_RF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('RISK_FACTOR_HELP','B_IU_RFH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('RISK_FACTOR_SCALE','B_IU_RFS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('RISK_FACTOR_SCALE_DET','B_IU_RFSD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ROOM','B_IU_ROOM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ROOM_BACKUP','B_IU_ROBA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ROOM_DEP_CLIN_SERV','B_IU_RCST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ROOM_DEP_POSITION','B_IU_RDEPP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ROOM_EXT_SYS','B_IU_RES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ROOM_SCHEDULED','B_IU_RSD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ROOM_TYPE','B_IU_RTY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ROTATION_INTERVAL','B_IU_RIL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ROUNDS','B_IU_RND_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ROUNDS_HIST','B_IU_RNDH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('ROUTE','B_IU_ROUTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('RS_UPD_ANALYSIS','B_IU_RSUA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SAMPLE_RECIPIENT','B_IU_SRT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SAMPLE_TEXT','B_IU_SSTT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SAMPLE_TEXT_FREQ','B_IU_FST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SAMPLE_TEXT_PROF','B_IU_STT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SAMPLE_TEXT_TYPE','B_IU_SST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SAMPLE_TEXT_TYPE_CAT','B_IU_STTC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SAMPLE_TYPE','B_IU_STE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCALES','B_IU_SCE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCALES_CLASS','B_IU_SCSC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCALES_DOC_VALUE','B_IU_SDE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCHEDULE','B_IU_SCHD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCHEDULE_ANALYSIS','B_IU_SCHA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCHEDULE_BED','B_IU_SCHEDULE_BED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCHEDULE_EXAM','B_IU_SCHE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCHEDULE_INP','B_IU_SIP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCHEDULE_INTERVENTION','B_IU_SCHI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCHEDULE_OUTP','B_IU_SOP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCHEDULE_RECURSION','B_IU_SCHREC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCHEDULE_SR','B_IU_SR_SCHED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_ABSENCE','B_IU_SAB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_ANALYSIS_DCS','B_IU_SCAD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_AUTOPICK_CRIT','B_IU_SCH_AUTOPICK_CRIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_BED_SLOT','B_IU_SCH_BED_SLOT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_CANCEL_REASON','B_IU_SLR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_CANCEL_REASON_INST','B_IU_SLI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_CLIPBOARD','B_IU_SCH_CLIPBOARD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_COLOR','B_IU_SCH_COLOR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_CONSULT_VACANCY','B_IU_SCV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_CONSULT_VAC_ANALYSIS','B_IU_SCVA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_CONSULT_VAC_EXAM','B_IU_SCVE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_CONSULT_VAC_MFR','B_IU_SCVM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_CONSULT_VAC_MFR_SLOT','B_IU_SCVMS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_CONSULT_VAC_ORIS','B_IU_SCVO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_CONSULT_VAC_ORIS_SLOT','B_IU_SCVOS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_DCS_NOTIFICATION','B_IU_SCDN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_DEFAULT_CONSULT_VACANCY','B_IU_SDCV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_DEPARTMENT','B_IU_SCH_DEPARTMENT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_DEP_TYPE','B_IU_SDTY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_EVENT','B_IU_SCT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_EVENT_DCS','B_IU_SEC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_EVENT_INST','B_IU_SCH_EVENT_INST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_EVENT_SOFT','B_IU_SES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_GROUP','B_IU_SGP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_INP_DEP_TIME','B_IU_SCH_INP_DEP_TIME_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_MULT_RESCHEDULE_AUX','B_IU_SMRA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_MULT_RESCHED_MSG_AUX','B_IU_SMRM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_PERMISSION','B_IU_SCN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_PERMISSION_DEPT','B_IU_SPD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_PROF_OUTP','B_IU_SPO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_REPRULES','B_IU_SRR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_RESOURCE','B_IU_SRE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_ROOM_STATS','B_IU_SCH_ROOM_STATS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_SCHEDULE_REQUEST','B_IU_SSR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCH_VACANCY_USAGE','B_IU_SVU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCREEN','B_IU_SCRE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCREEN_TEMPLATE','B_IU_STEP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SCREEN_XML','B_IU_SCXM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SEARCH_SCREEN','B_IU_SSCR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SERV_SCHED_ACCESS','B_IU_SSA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SNOMED_ALL','B_IU_SNAL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SNOMED_TRANSLATION','B_IU_SNTR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOCIAL_CLASS','B_IU_SCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOCIAL_DIAGNOSIS','B_IU_SDS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOCIAL_EPISODE','B_IU_SEE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOCIAL_EPIS_DIAG','B_IU_ESD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOCIAL_EPIS_DISCHARGE','B_IU_SED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOCIAL_EPIS_INTERV','B_IU_ESI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOCIAL_EPIS_REQUEST','B_IU_SERT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOCIAL_EPIS_SITUATION','B_IU_SESI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOCIAL_EPIS_SOLUTION','B_IU_SESO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOCIAL_INTERVENTION','B_IU_SIN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOFTWARE','B_IU_S_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOFTWARE_DEPT','B_IU_SDT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOFTWARE_INSTITUTION','B_IU_SI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SOFT_LANG','B_IU_SLNG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SPECIALITY','B_IU_SPC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SPEC_SYS_APPAR','B_IU_SSAR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_CANCEL_REASON','B_IU_SR_CAN_REA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_DANGER_CONT','B_IU_DACT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_EPIS_INTERV','B_IU_SEV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_EPIS_INTERV_DESC','B_IU_SR_INT_DES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_EQUIP','B_IU_SEP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_EQUIP_KIT','B_IU_SETK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_EQUIP_PERIOD','B_IU_SQPD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_EVAL_RULE','B_IU_SR_EV_RL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_EVAL_SUMM','B_IU_SEVM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_EVAL_TYPE','B_IU_SEET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_INTERFACE_PARAM','B_IU_SRIP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_INTERVENTION','B_IU_SINT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_INTERV_DEP_CLIN_SERV','B_IU_SIDC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_INTERV_DESC','B_IU_SR_ITV_DES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_INTERV_DURATION','B_IU_SIND_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_INTERV_GROUP','B_IU_SIPG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_INTERV_GROUP_DET','B_IU_SIGD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_PAT_STATUS','B_IU_SPU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_PAT_STATUS_NOTES','B_IU_SPSN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_PAT_STATUS_PERIOD','B_IU_SR_STS_PER_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_POSIT','B_IU_SR_POS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_POSIT_REQ','B_IU_SPQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_POS_INST','B_IU_SPIT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_POS_SCHEDULE','B_IU_SPSC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_POS_STATUS','B_IU_SPST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_PROF_RECOV_SCHD','B_IU_SR_PRSCH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_PROF_SHIFT','B_IU_SPSHT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_PROF_TEAM_DET','B_IU_SR_PF_TEAM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_RECEIVE','B_IU_SR_RECV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_RESERV_REQ','B_IU_SRQ_SEP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_ROOM_STATUS','B_IU_SRU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_SURGERY_RECORD','B_IU_SR_REC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_SURGERY_REC_DET','B_IU_SSTD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_SURGERY_TIME','B_IU_SR_TIMES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_SURGERY_TIME_DET','B_IU_SR_TIM_DET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SR_SURG_PERIOD','B_IU_SSD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SSCR_CRIT','B_IU_SCR_C_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SUMMARY_PAGE','B_IU_SUMM_PAGE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SUMMARY_PAGE_ACCESS','B_IU_SUMM_PAGE_ACCESS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SUMMARY_PAGE_SECTION','B_IU_SUMM_PAGE_SECTION_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SUPPLIES','B_IU_SUPPL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SUPPLIES_RELATION','B_IU_SUPPL_REL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SUPPLIES_SOFT_INST','B_IU_SSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SWF_FILE','B_IU_SWFI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYSTEM_APPARATI','B_IU_SAI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYSTEM_ORGAN','B_IU_SYS_ORG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_ALERT','B_IU_SA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_ALERT_CONFIG','B_IU_SAG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_ALERT_DET','B_IU_SYAD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_ALERT_EVENT','B_IU_SAEVT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_ALERT_EVENT_DETAIL','B_IU_SAED_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_ALERT_PROF','B_IU_SAP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_ALERT_READ','B_IU_SYAR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_ALERT_TYPE','B_IU_SYS_ALT_TP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_APPAR_ORGAN','B_IU_SYS_APORG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_APPLICATION_AREA','B_IU_AAA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_APPLICATION_TYPE','B_IU_SAT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_AUDIT_FUNC','B_IU_SYS_AUDIT_DESC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_AUDIT_PARAM','B_IU_SYS_AUDIT_PARAM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_BTN_CRIT','B_IU_SBT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_BUTTON','B_IU_BTN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_BUTTON_PROP','B_IU_SBPP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_CONFIG','B_IU_SYS_CONFIG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_CONFIG_010708','B_IU_SYC0_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_CONFIG_080408','B_IU_SYS_CONFIG_080408_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_CONFIG_TRANSLATION','B_IU_SYCT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_DOMAIN','B_IU_SDN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_DOMAIN_INSTIT_SOFT_DCS','B_IU_SDIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_DOMAIN_MKT','B_IU_SDM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_DOMAIN_REQ','B_IU_SYDR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_ENTRANCE','B_IU_SYS_ENTRANCE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_FIELD','B_IU_SFD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_FUNCTIONALITY','B_IU_SFY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_HELPMESSAGE','B_IU_SYHE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_LOGIN','B_IU_SYS_LOGIN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_MESSAGE','B_IU_SME_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_MESSAGE_TST','B_IU_SYMT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_REQUEST_ATOMIC','B_IU_SRQTA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_SCREEN_AREA','B_IU_SAA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_SCREEN_TEMPLATE','B_IU_SSTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_SESSION_FP_TEST','B_IU_SSFT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_SESSION_V2','B_IU_SSN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_SHORTCUT','B_IU_SSST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_SHORTCUT_180_','B_IU_SS1_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_TIME_EVENT_GROUP','B_IU_TGM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_TOOLBAR_DROP','B_IU_STB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('SYS_VITAL_SIGN','B_IU_SYVS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TAB_TESTE01','B_IU_TATE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TASK_TIMELINE_EA','B_IU_TASK_TIMELINE_EA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TASK_TYPE','B_IU_TTY_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TESTS_REVIEW','B_IU_TRW_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('THERAPEUTIC_PROTOCOLS','B_IU_TP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('THERAPEUTIC_PROTOCOLS_DCS','B_IU_TPDCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TIME','B_IU_TIM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TIMEZONE_REGION','B_IU_TZR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TIME_EVENT_GROUP','B_IU_TEG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TIME_EVENT_READ','B_IU_TER_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TIME_GROUP','B_IU_TG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TIME_GROUP_SOFT_INST','B_IU_TGSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TIME_UNIT','B_IU_TUT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TI_LOG','B_IU_TLOG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TL_SCALE','B_IU_TLSCE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TL_SOFTWARE','B_IU_TSE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TL_TASK','B_IU_TTK_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TL_TASK_TIMELINE','B_IU_TTT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TL_TASK_TIMELINE_EXCEPTION','B_IU_TTTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TL_TIMELINE','B_IU_TLE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TL_TIMELINE_ACCESS','B_IU_TTS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TL_TIMELINE_SCALE','B_IU_TL_TTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TODO_TASK','B_IU_TDT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRACKING_BOARD_EA','B_IU_TBA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSFER_INSTITUTION','B_IU_TINST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSFER_OPTION','B_IU_TOPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSFER_OPT_DCS','B_IU_TOPTDCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSLATION','B_IU_TRANSLATION_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSLATION_SESSION_READ','B_IU_TRSR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSLATION_TOOL_CHANGES','B_IU_TRTC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSLATION_TOOL_STATUS','B_IU_TRSSST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSL_DIAG','B_IU_TRDI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSPORTATION','B_IU_ETP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSPORT_TYPE','B_IU_TTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSP_ENTITY','B_IU_TRP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSP_ENT_INST','B_IU_TEI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSP_REQ','B_IU_TRQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRANSP_REQ_GROUP','B_IU_TRG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TREATMENT_MANAGEMENT','B_IU_TMAN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE','B_IU_TRI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_BOARD','B_IU_TBRD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_BOARD_GROUP','B_IU_TBGP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_BOARD_GROUPING','B_IU_TBGG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_COLOR','B_IU_TCOL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_COLOR_TIME_INST','B_IU_TCI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_CONSIDERATIONS','B_IU_TC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_DISCRIMINATOR','B_IU_TDISC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_DISCRIMINATOR_HELP','B_IU_TDIHP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_DISC_HELP','B_IU_TDHP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_DISC_VS_VALID','B_IU_TDVV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_NURSE','B_IU_TNSR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_N_CONSID','B_IU_TNC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_TYPE','B_IU_TYP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_UNITS','B_IU_TUNITS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRIAGE_WHITE_REASON','B_IU_TWRN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TRL_KEYWORD_MAP','B_IU_TRKM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TV_ACCESS','B_IU_TVA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TV_IMAGE','B_IU_TVIMG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TV_MEDIA','B_IU_TVM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TV_MEDIA_TAG','B_IU_TVMTAG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TV_USER_MEDIA','B_IU_TVUM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('TV_VIDEO_REVIEW_HISTORY','B_IU_TVVRH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIDOSE_BUILD_REQ','B_IU_UNIDOSE_BUILD_REQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIDOSE_CAR','B_IU_UCR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIDOSE_CAR_CURRENT_LOCATION','B_IU_UCCL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIDOSE_CAR_DATES','B_IU_UNCD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIDOSE_CAR_DEPARTMENT','B_IU_UCT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIDOSE_CAR_HIST','B_IU_UNIDOSE_CAR_HIST_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIDOSE_CAR_LOC_HIST','B_IU_UCLH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIDOSE_CAR_PATIENT','B_IU_UNCP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIDOSE_CAR_PATIENT_HIST','B_IU_UCPH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIDOSE_CAR_ROUTE','B_IU_UNIDOSE_CAR_ROUTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNITS_MARKET_CONVERTER','B_IU_UMC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIT_MEASURE','B_IU_UNITM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIT_MEASURE_BEJA','B_IU_UNMB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIT_MEASURE_CONVERT','B_IU_UNITMC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIT_MEASURE_ENUM','B_IU_UNITME_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIT_MEASURE_TYPE','B_IU_UMTYPE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIT_MEASURE_TYPE_BEJA','B_IU_UMTB_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('UNIT_MEA_SOFT_INST','B_IU_UMSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC','B_IU_VACC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACCINE','B_IU_VCC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACCINE_DEP_CLIN_SERV','B_IU_VDCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACCINE_DESC','B_IU_VDC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACCINE_DET','B_IU_VDET_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACCINE_DOSE','B_IU_VD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACCINE_DOSE_ADMIN','B_IU_VDA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACCINE_PRESCRIPTION','B_IU_VPN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACCINE_PRESC_DET','B_IU_VPC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACCINE_PRESC_PLAN','B_IU_VPP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACCINE_STATUS','B_IU_VSU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC_DCI','B_IU_VACC_DCI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC_DEP_CLIN_SERV','B_IU_VACC_DEP_CLIN_SERV_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC_DOSE','B_IU_VACC_DOSE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC_DRUG','B_IU_VACC_DRUG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC_GROUP','B_IU_VACC_GROUP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC_GROUP_SOFT_INST','B_IU_VGSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC_INFO','B_IU_VACC_INFO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC_MED_EXT','B_IU_VACC_MED_EXT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC_OTHER_FREQ','B_IU_VAOF_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC_TYPE_GROUP','B_IU_VACC_TYPE_GROUP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VACC_TYPE_GROUP_SOFT_INST','B_IU_VTGSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VIEWER','B_IU_VIR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VIEWER_EHR_EA','B_IU_VEA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VIEWER_REFRESH','B_IU_VRH_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VIEWER_SYNCHRONIZE','B_IU_VSE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VIEWER_SYNCH_PARAM','B_IU_VSM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VIEW_OPTION','B_IU_VON_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VIEW_OPTION_CONFIG','B_IU_VOC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VISIT','B_IU_VIS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN','B_IU_VSN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGNS_EA','B_IU_VS_EA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN_ALIAS','B_IU_VSA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN_CONDITIONS','B_IU_VSC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN_DESC','B_IU_VSD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN_NOTES','B_IU_VSNOTES_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN_PREGNANCY','B_IU_VSP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN_READ','B_IU_VSR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN_RELATION','B_IU_VSRN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN_SCALES','B_IU_VSS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN_SCALES_ACCESS','B_IU_VSSA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN_SCALES_ELEMENT','B_IU_VSSE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VITAL_SIGN_UNIT_MEASURE','B_IU_VSUM_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VS_CLIN_SERV','B_IU_VCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('VS_SOFT_INST','B_IU_VSSI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WAITING_LIST','B_IU_WGLT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WAITING_LIST_HIST','B_IU_WGHT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WF_STATUS','B_IU_WSU_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WF_STATUS_CONFIG','B_IU_WSC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WF_STATUS_WORKFLOW','B_IU_WSW_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WF_TRANSITION','B_IU_WTS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WF_TRANSITION_CONFIG','B_IU_WTC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WF_WORKFLOW','B_IU_WWW_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WF_WORKFLOW_SOFTWARE','B_IU_WWE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WL_CALL_QUEUE','B_IU_WCQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WL_DEMO','B_IU_WD_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WL_MACHINE','B_IU_WME_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WL_MACH_PROF_QUEUE','B_IU_WMPQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WL_MSG_QUEUE','B_IU_WMQ_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WL_PROF_ROOM','B_IU_WPR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WL_QUEUE','B_IU_WQE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WL_QUEUE_GROUP','B_IU_WLQG_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WL_TOPICS','B_IU_WT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WL_WAITING_LINE','B_IU_WWL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WL_WAITING_ROOM','B_IU_WWR_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WOUNDS_EA','B_IU_WOUNDS_EA_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WOUND_CHARAC','B_IU_WCC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WOUND_EVALUATION','B_IU_WEN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WOUND_EVAL_CHARAC','B_IU_WEC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WOUND_TREAT','B_IU_WTT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WOUND_TYPE','B_IU_WTE_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WTL_DEP_CLIN_SERV','B_IU_WDCS_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WTL_EPIS','B_IU_WEP_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WTL_PREF_TIME','B_IU_WPT_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WTL_PROF','B_IU_WPRO_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WTL_PTREASON','B_IU_WPN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WTL_PTREASON_INST','B_IU_WPI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WTL_PTREASON_WTLIST','B_IU_WPW_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WTL_UNAV','B_IU_WUN_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WTL_URG_LEVEL','B_IU_WUL_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('WTL_URG_LEVEL_INST','B_IU_WULI_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('XDS_CONFIDENTIALITY_CODE','B_IU_XDCC_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('XDS_DETAILS_CONF_CODE','B_IU_XDCCE248_AUDIT');
insert into tbl_temp(VC_1, VC_2) values ('XDS_DOCUMENT_TYPE','B_IU_XDDT_AUDIT');
end;
/

DECLARE
    CURSOR c_tables IS
        SELECT vc_1 table_name, vc_2 trigger_name
          FROM tbl_temp tt
         WHERE tt.vc_1 IN (SELECT utc.table_name
                             FROM user_tab_columns utc
                            WHERE utc.column_name = 'CREATE_USER')
           AND tt.vc_2 NOT IN (SELECT ut.trigger_name
                                 FROM user_triggers ut
                                WHERE trigger_name LIKE 'B\_IU%\_AUDIT' ESCAPE '\');

    l_trg_name VARCHAR2(30);
    l_alias    VARCHAR2(30);
    l_passo    NUMBER(3) := 1;
    l_aux      NUMBER(5) := 0;
    l_tab_name VARCHAR2(4000);

    PROCEDURE validate_trigger(i_table_name IN VARCHAR2, i_trigger_name in varchar2) IS
        CURSOR c_trg IS
            SELECT trigger_name
              FROM user_triggers ut
             WHERE trigger_name LIKE 'B\_IU%\_AUDIT' ESCAPE '\'
               AND table_name = i_table_name
							 AND trigger_name != i_trigger_name;
    BEGIN
        FOR r_trg IN c_trg
        LOOP
            EXECUTE IMMEDIATE 'DROP TRIGGER ' || r_trg.trigger_name;
        END LOOP;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line('ERROR DROP TRIGGER - ' || SQLERRM);
            pk_alertlog.log_error('ERROR DROP TRIGGER - ' || SQLERRM, 'EDIT_TRAIL_TRIGGERS');
    END;

BEGIN
    pk_alertlog.log_init('EDT_TRAIL_TRIGGERS');

    FOR r_tables IN c_tables
    LOOP
        l_tab_name := r_tables.table_name;
        l_trg_name := r_tables.trigger_name;
				
				--Delete trigger if name is different
				validate_trigger(l_tab_name, l_trg_name);
    
        l_passo := 16;
				--Recreate triggers
        BEGIN
            EXECUTE IMMEDIATE 'CREATE OR REPLACE TRIGGER ' || l_trg_name || ' ' || '
BEFORE INSERT OR UPDATE ON ' || r_tables.table_name || '
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, '';''), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, '';''), '','', ''.''), ''999999999999999999999999D999'', ''NLS_NUMERIC_CHARACTERS = ''''. '''''');
  
  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        PK_ALERTLOG.log_error(''' || l_trg_name || '-''||sqlerrm);
END ' || l_trg_name || ';';
            l_passo := 18;
        EXCEPTION
            WHEN OTHERS THEN
                dbms_output.put_line('TRIGGER CREATION - ' || r_tables.table_name || ' - ' || l_trg_name);
                pk_alertlog.log_error('TRIGGER CREATION - ' || r_tables.table_name || ' - ' || l_trg_name,
                                      'EDIT_TRAIL_TRIGGERS');
        END;
    
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('ERRO(' || l_passo || '):' || l_tab_name || '-' || l_trg_name || '-' || SQLERRM);
        pk_alertlog.log_error('ERRO(' || l_passo || '):' || l_tab_name || '-' || l_trg_name || '-' || SQLERRM,
                              'EDIT_TRAIL_TRIGGERS');
END;
/
-- CHANGE END: Rui Spratley


--RicardoNunoAlmeida
--02-06-2009
--ALERT-31059
BEGIN
            EXECUTE IMMEDIATE 'DROP PACKAGE PK_WLFREE_ACCESS';
EXCEPTION
		WHEN OTHERS THEN
				NULL;
END;
/
--END RNA

--Rui Marante
--02-06-2009
--ALERT-31058
-- drop audit triggers and columns from workflow database model
drop trigger B_IU_WFL_LOG_AUDIT;

alter table wfl_log
drop (
	create_user, create_time, create_institution, update_user, update_time, update_institution
);

drop trigger B_IU_WFL_SS_AUDIT;

alter table wfl_state_scope
drop (
	create_user, create_time, create_institution, update_user, update_time, update_institution
);

drop trigger B_IU_WFL_A_AUDIT;

alter table wfl_action
drop (
	create_user, create_time, create_institution, update_user, update_time, update_institution
);

drop trigger B_IU_WFL_CPRA_AUDIT;

alter table wfl_conf_profile_action
drop (
	create_user, create_time, create_institution, update_user, update_time, update_institution
);

drop trigger B_IU_WFL_CPA_AUDIT;

alter table wfl_conf_prof_action
drop (
	create_user, create_time, create_institution, update_user, update_time, update_institution
);

drop trigger B_IU_WFL_ST_AUDIT;

alter table wfl_state
drop (
	create_user, create_time, create_institution, update_user, update_time, update_institution
);

drop trigger B_IU_WFL_ST_DET_AUDIT;

alter table wfl_state_detail
drop (
	create_user, create_time, create_institution, update_user, update_time, update_institution
);

drop trigger B_IU_WFL_STR_AUDIT;

alter table wfl_state_relate
drop (
	create_user, create_time, create_institution, update_user, update_time, update_institution
);

drop trigger B_IU_WFL_STA_AUDIT;

alter table wfl_state_trans_action
drop (
	create_user, create_time, create_institution, update_user, update_time, update_institution
);
--END

-- CHANGED BY: Rui Marante
-- CHANGE DATE: 2009-06-17
-- CHANGE REASON: ALERT-31058

--alter table disable constraint
alter table drug_req_det
disable constraint DRUG_REQ_DET_STATE_FK;

alter table drug_req_det_state_transition
disable constraint DRUG_REQ_ST_TRANS_WFL_ST_FK;

alter table drug_req_supply
disable constraint DRUG_REQ_SUP_STATE_FK;

alter table drug_req_sup_state_transition
disable constraint DRUG_SUP_ST_TRANS_WFL_ST_FK;

--clear
delete from wfl_log;
delete from wfl_conf_prof_action;
delete from wfl_conf_profile_action;
delete from wfl_state_trans_action;
delete from wfl_action;
delete from wfl_state_relate;
delete from wfl_state_detail;
delete from wfl_state;
delete from wfl_state_scope;

-- CHANGE END: Rui Marante

-- CHANGED BY: Rui Marante
-- CHANGED DATE: 2009-06-17
-- CHANGED REASON: ALERT-31058
update sys_button_prop sbp
set sbp.screen_name = 'PharmacistAll.swf'
where sbp.id_sys_button_prop = 12358;

update profile_templ_access a
set a.flg_ok = 'A'
where a.id_sys_button_prop = 12360
	and a.id_profile_template = 24;

update profile_templ_access a
set a.flg_ok = 'A'
where a.id_sys_button_prop = 12362
	and a.id_profile_template = 24;

update profile_templ_access a
set a.flg_ok = 'A'
where a.id_sys_button_prop = 15494
	and a.id_profile_template = 24;

update sys_button_prop a
set a.screen_name = 'PharmacistAllPending.swf'
where a.id_sys_button_prop = 12361;

update profile_templ_access a
set a.flg_ok = 'A'
where a.id_sys_button_prop = 12361
	and a.id_profile_template = 24;
	
update profile_templ_access a
set a.flg_cancel = 'A'
where a.id_sys_button_prop = 11647
	and a.id_profile_template = 24;	
	
update profile_templ_access x
set x.flg_action = 'A'
where x.id_sys_button_prop = 12360;

-- btn actions
insert into profile_templ_access (ID_PROFILE_TEMPL_ACCESS, ID_PROFILE_TEMPLATE, RANK, ID_SYS_BUTTON_PROP, FLG_CREATE, FLG_CANCEL, FLG_SEARCH, FLG_PRINT, FLG_OK, FLG_DETAIL, FLG_CONTENT, FLG_HELP, ID_SYS_SHORTCUT, ID_SOFTWARE, ID_SHORTCUT_PK, ID_SOFTWARE_CONTEXT, FLG_GRAPH, FLG_VISION, FLG_DIGITAL, FLG_FREQ, FLG_NO, POSITION, TOOLBAR_LEVEL, FLG_ACTION, FLG_VIEW, FLG_ADD_REMOVE)
values (102774958, 24, null, 200683, '', '', '', '', '', '', '', '', null, 20, null, 20, '', '', '', '', '', null, null, '', 'N', 'A');

insert into profile_templ_access (ID_PROFILE_TEMPL_ACCESS, ID_PROFILE_TEMPLATE, RANK, ID_SYS_BUTTON_PROP, FLG_CREATE, FLG_CANCEL, FLG_SEARCH, FLG_PRINT, FLG_OK, FLG_DETAIL, FLG_CONTENT, FLG_HELP, ID_SYS_SHORTCUT, ID_SOFTWARE, ID_SHORTCUT_PK, ID_SOFTWARE_CONTEXT, FLG_GRAPH, FLG_VISION, FLG_DIGITAL, FLG_FREQ, FLG_NO, POSITION, TOOLBAR_LEVEL, FLG_ACTION, FLG_VIEW, FLG_ADD_REMOVE)
values (102774959, 32, null, 200683, '', '', '', '', '', '', '', '', null, 20, null, 20, '', '', '', '', '', null, null, '', 'N', 'A');

insert into sys_button_prop (ID_SYS_BUTTON_PROP, ID_SYS_BUTTON, SCREEN_NAME, ID_SYS_APPLICATION_AREA, ID_SYS_SCREEN_AREA, FLG_VISIBLE, RANK, BORDER_COLOR, ALPHA, BACK_COLOR, ID_SYS_APPLICATION_TYPE, ID_BTN_PRP_PARENT, ACTION, FLG_ENABLED, SUB_RANK, CODE_TITLE_HELP, CODE_DESC_HELP, FLG_RESET_CONTEXT, POSITION, TOOLBAR_LEVEL, CODE_MSG_COPYRIGHT, CODE_TOOLTIP_TITLE, CODE_TOOLTIP_DESC)
values (200683, 6361, '', 31, 10, 'Y', 60, '', null, 'c86464', 1, null, '', 'Y', null, 'SYS_BUTTON_PROP.CODE_TITLE_HELP.200683', 'SYS_BUTTON_PROP.CODE_TOOLTIP_DESC.200683', 'N', null, null, '', 'SYS_BUTTON_PROP.CODE_TOOLTIP_TITLE.200683', 'SYS_BUTTON_PROP.CODE_TOOLTIP_DESC.200683');

update sys_button sb
set sb.icon = 'TherapeuticIcon'
where sb.id_sys_button = 6250;

update translation t 
set t.desc_translation = 'TherapeuticIcon'
where t.code_translation = 'SYS_BUTTON.CODE_ICON.6250';

--trocar a order dos botões
update sys_button_prop sbp
set sbp.rank = 51
where sbp.id_sys_button_prop = 11619;

--alter table disable constraint
alter table drug_req_det
disable constraint DRUG_REQ_DET_STATE_FK;

alter table drug_req_det_state_transition
disable constraint DRUG_REQ_ST_TRANS_WFL_ST_FK;

alter table drug_req_supply
disable constraint DRUG_REQ_SUP_STATE_FK;

alter table drug_req_sup_state_transition
disable constraint DRUG_SUP_ST_TRANS_WFL_ST_FK;

--clear
delete from wfl_log;
delete from wfl_conf_prof_action;
delete from wfl_conf_profile_action;
delete from wfl_state_trans_action;
delete from wfl_action;
delete from wfl_state_relate;
delete from wfl_state_detail;
delete from wfl_state;
delete from wfl_state_scope;

-- load data
--@01_wfl_state_scope.sql;
insert into wfl_state_scope (ID_SCOPE, SCOPE_NAME, MARKET, FLG_TYPE)
values (1, 'DRUG_REQ_DET (ADM)', 1, 'A');

insert into wfl_state_scope (ID_SCOPE, SCOPE_NAME, MARKET, FLG_TYPE)
values (2, 'DRUG_REQ_SUPPLY', 1, '');

insert into wfl_state_scope (ID_SCOPE, SCOPE_NAME, MARKET, FLG_TYPE)
values (3, 'DRUG_REQ_DET (INT)', 1, 'I');

--@02_wfl_state.sql;
insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (1, 'requested', 'requested to the hospital pharmacy', 'Y', 1, 'R', 'WFL_STATE.ID_STATE.1', 'WFL_STATE.ID_STATE_DETAIL.1', 'G_DRD_REQUESTED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (2, 'pending', 'request with some pending qty', 'N', 1, 'D', 'WFL_STATE.ID_STATE.2', 'WFL_STATE.ID_STATE_DETAIL.2', 'PENDING_1');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (3, 'temporary', 'temporary request (being formulated)', 'N', 1, 'T', 'WFL_STATE.ID_STATE.3', 'WFL_STATE.ID_STATE_DETAIL.3', 'TEMPORARY_1');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (4, 'executing', 'request being prepared', 'Y', 1, 'E', 'WFL_STATE.ID_STATE.4', 'WFL_STATE.ID_STATE_DETAIL.4', 'G_DRD_EXECUTING_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (5, 'terminated', 'request terminated', 'Y', 1, 'F', 'WFL_STATE.ID_STATE.5', 'WFL_STATE.ID_STATE_DETAIL.5', 'G_DRD_TERMINATED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (6, 'canceled', 'request canceled', 'Y', 1, 'C', 'WFL_STATE.ID_STATE.6', 'WFL_STATE.ID_STATE_DETAIL.6', 'G_DRD_CANCELED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (7, 'rejected to physician', 'request rejected by pharmacist', 'Y', 1, 'J', 'WFL_STATE.ID_STATE.7', 'WFL_STATE.ID_STATE_DETAIL.7', 'G_DRD_REJECTED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (8, 'I ?', '', 'N', 1, 'I', 'WFL_STATE.ID_STATE.8', 'WFL_STATE.ID_STATE_DETAIL.8', 'I_1');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (9, 'L ?', '', 'N', 1, 'L', 'WFL_STATE.ID_STATE.9', 'WFL_STATE.ID_STATE_DETAIL.9', 'L_1');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (10, 'P ?', '', 'N', 1, 'P', 'WFL_STATE.ID_STATE.10', 'WFL_STATE.ID_STATE_DETAIL.10', 'P_1');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (11, 'validated', 'request has been validated by the pharmacist', 'Y', 1, '', 'WFL_STATE.ID_STATE.11', 'WFL_STATE.ID_STATE_DETAIL.11', 'G_DRD_VALIDATED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (12, 'validated (waiting physician approval)', 'request has been validated by the pharmacist but needs to be verified by the physician', 'Y', 1, '', 'WFL_STATE.ID_STATE.12', 'WFL_STATE.ID_STATE_DETAIL.12', 'G_DRD_WAITING_APPROV_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (13, 'validated (co-signed)', 'request has been validated by the pharmacist and co-signed', 'Y', 1, '', 'WFL_STATE.ID_STATE.13', 'WFL_STATE.ID_STATE_DETAIL.13', 'G_DRD_VALIDATED_SIGN_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (14, 'rejected to pharmacist', 'rejected by technician to pharmacist', 'Y', 1, '', 'WFL_STATE.ID_STATE.14', 'WFL_STATE.ID_STATE_DETAIL.14', 'G_DRD_REJECTED2PHARM_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (15, 'rejected to technician', 'rejected by pharmacist to technician -- has to be prepared again', 'Y', 1, '', 'WFL_STATE.ID_STATE.15', 'WFL_STATE.ID_STATE_DETAIL.15', 'G_DRD_REJECTED2PREP_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (101, 'on preparation', '', 'Y', 2, 'E', 'WFL_STATE.ID_STATE.101', 'WFL_STATE.ID_STATE_DETAIL.101', 'G_DRS_PREPARING_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (102, 'ready for transport', '', 'Y', 2, 'O', 'WFL_STATE.ID_STATE.102', 'WFL_STATE.ID_STATE_DETAIL.102', 'G_DRS_READYFORTRANSP_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (103, 'canceled', '', 'Y', 2, 'C', 'WFL_STATE.ID_STATE.103', 'WFL_STATE.ID_STATE_DETAIL.103', 'G_DRS_CANCELED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (104, 'in transit', '', 'Y', 2, 'T', 'WFL_STATE.ID_STATE.104', 'WFL_STATE.ID_STATE_DETAIL.104', 'G_DRS_IN_TRANSIT_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (105, 'supplied', 'finnished', 'Y', 2, 'F', 'WFL_STATE.ID_STATE.105', 'WFL_STATE.ID_STATE_DETAIL.105', 'G_DRS_SUPPLIED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (106, 'ready for pharmacist validation', '', 'Y', 2, '', 'WFL_STATE.ID_STATE.106', 'WFL_STATE.ID_STATE_DETAIL.106', 'G_DRS_READYFORVALID_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (107, 'rejected to technician', 'rejected by pharmacist to technician -- terminal state!!', 'Y', 2, '', 'WFL_STATE.ID_STATE.107', 'WFL_STATE.ID_STATE_DETAIL.107', 'G_DRS_REJECTED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (108, 'delivered to patient', 'delivered to patient', 'Y', 2, 'U', 'WFL_STATE.ID_STATE.108', 'WFL_STATE.ID_STATE_DETAIL.108', 'G_DRS_DELIVERED2PAT_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (201, 'requested', 'requested to the hospital pharmacy', 'Y', 3, 'R', 'WFL_STATE.ID_STATE.201', 'WFL_STATE.ID_STATE_DETAIL.201', 'G_DRD_REQUESTED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (202, 'pending', 'request with some pending qty', 'N', 3, 'D', 'WFL_STATE.ID_STATE.202', 'WFL_STATE.ID_STATE_DETAIL.202', 'PENDING_3');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (203, 'temporary', 'temporary request (being formulated)', 'Y', 3, 'T', 'WFL_STATE.ID_STATE.203', 'WFL_STATE.ID_STATE_DETAIL.203', 'G_DRD_TEMPORARY_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (204, 'executing', 'request being prepared', 'Y', 3, 'E', 'WFL_STATE.ID_STATE.204', 'WFL_STATE.ID_STATE_DETAIL.204', 'G_DRD_EXECUTING_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (205, 'terminated', 'request terminated', 'Y', 3, 'F', 'WFL_STATE.ID_STATE.205', 'WFL_STATE.ID_STATE_DETAIL.205', 'G_DRD_TERMINATED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (206, 'canceled', 'request canceled', 'Y', 3, 'C', 'WFL_STATE.ID_STATE.206', 'WFL_STATE.ID_STATE_DETAIL.206', 'G_DRD_CANCELED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (207, 'rejected to physician', 'request rejected by pharmacist', 'Y', 3, 'J', 'WFL_STATE.ID_STATE.207', 'WFL_STATE.ID_STATE_DETAIL.207', 'G_DRD_REJECTED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (208, 'I ?', '', 'N', 3, 'I', 'WFL_STATE.ID_STATE.208', 'WFL_STATE.ID_STATE_DETAIL.208', 'I_3');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (209, 'L ?', '', 'N', 3, 'L', 'WFL_STATE.ID_STATE.209', 'WFL_STATE.ID_STATE_DETAIL.209', 'L_3');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (210, 'P ?', '', 'N', 3, 'P', 'WFL_STATE.ID_STATE.210', 'WFL_STATE.ID_STATE_DETAIL.210', 'P_3');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (211, 'validated', 'request has been validated by the pharmacist', 'Y', 3, '', 'WFL_STATE.ID_STATE.211', 'WFL_STATE.ID_STATE_DETAIL.211', 'G_DRD_VALIDATED_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (212, 'validated (waiting physician approval)', 'request has been validated by the pharmacist but needs to be verified by the physician', 'Y', 3, '', 'WFL_STATE.ID_STATE.212', 'WFL_STATE.ID_STATE_DETAIL.212', 'G_DRD_WAITING_APPROV_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (213, 'validated (co-signed)', 'request has been validated by the pharmacist and co-signed', 'Y', 3, '', 'WFL_STATE.ID_STATE.213', 'WFL_STATE.ID_STATE_DETAIL.213', 'G_DRD_VALIDATED_SIGN_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (214, 'rejected to pharmacist', 'rejected by technician to pharmacist', 'Y', 3, '', 'WFL_STATE.ID_STATE.214', 'WFL_STATE.ID_STATE_DETAIL.214', 'G_DRD_REJECTED2PHARM_ST');

insert into wfl_state (ID_STATE, STATE_NAME, STATE_DESC, FLG_ACTIVE, SCOPE, OLD_FLG, CODE_STATE, CODE_STATE_DETAIL, GENERIC_NAME)
values (215, 'rejected to technician', 'rejected by pharmacist to technician -- has to be prepared again', 'Y', 3, '', 'WFL_STATE.ID_STATE.215', 'WFL_STATE.ID_STATE_DETAIL.215', 'G_DRD_REJECTED2PREP_ST');


alter table wfl_state_detail
modify (
	icon_color varchar(10) null,
	icon_bg_color varchar(10) null,
	flg_color varchar(1) null
);

--@03_wfl_state_detail.sql;
insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (1, 'P', 'X', 'D', '0xEBEBC8', '0xc86464', 'R', 8800, 10, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (2, 'P', 'WaitingIcon', 'I', '0x787864', '0xC3C3A5', 'X', 8800, 100, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (3, 'P', 'X', 'I', '', '', '', 0, 200, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (4, 'P', 'CheckIcon', 'DI', '0x787864', '0xc86464', 'R', 8800, 40, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (5, 'P', 'PreparedIcon', 'DI', '0xc86464', '0xc86464', 'R', 8800, 30, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (6, 'P', 'CancelIcon', 'I', '0x787864', '0xC3C3A5', 'X', 7200, 180, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (7, 'P', 'DeclinedIcon', 'I', '', '', 'X', 7200, 170, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (11, 'P', 'WorkflowIcon', 'DI', '0x787864', '0xc86464', 'X', 8800, 50, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (12, 'P', 'WaitingIcon', 'DI', '0x787864', '', 'X', 8800, 60, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (13, 'P', 'WorkflowIcon', 'DI', '0x787864', '0xc86464', 'X', 8800, 52, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (14, 'P', 'DeclinedIcon', 'DI', '0x787864', '0xc86464', 'R', 8800, 14, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (15, 'P', 'DeclinedIcon', 'DI', '0x787864', '0xc86464', 'R', 8800, 16, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (101, 'P', 'WaitingIcon', 'I', '0x787864', '', 'X', 8800, 0, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (102, 'P', 'VerifiedIcon', 'I', '', '', 'X', 720, 65, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (103, 'P', 'CancelIcon', 'I', '0x787864', '', 'X', 72, 90, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (104, 'P', 'TransportCart', 'I', '', '', 'X', 72, 95, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (105, 'P', 'UnidoseCartClear', 'I', '', '', 'X', 72, 97, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (106, 'P', 'PreparedIcon', 'DI', '0xc86464', '0xc86464', 'R', 8800, 21, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (108, 'P', 'PreparedDrug', 'I', '', '', 'X', 48, 99, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (201, 'P', 'X', 'D', '0xEBEBC8', '0xc86464', 'R', 8800, 10, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (202, 'P', 'WaitingIcon', 'I', '0x787864', '0xC3C3A5', 'X', 8800, 100, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (203, 'P', 'X', 'I', '', '', '', 0, 200, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (204, 'P', 'CheckIcon', 'DI', '0x787864', '0xc86464', 'R', 8800, 40, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (205, 'P', 'PreparedIcon', 'DI', '0xc86464', '0xc86464', 'R', 8800, 30, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (206, 'P', 'CancelIcon', 'I', '0x787864', '0xC3C3A5', 'X', 7200, 180, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (207, 'P', 'DeclinedIcon', 'I', '', '', 'X', 7200, 170, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (211, 'P', 'WorkflowIcon', 'DI', '0x787864', '0xc86464', 'X', 8800, 50, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (212, 'P', 'WaitingIcon', 'DI', '0x787864', '0xC3C3A5', 'X', 8800, 60, 'N');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (213, 'P', 'WorkflowIcon', 'DI', '0x787864', '0xc86464', 'X', 8800, 52, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (214, 'P', 'DeclinedIcon', 'DI', '0x787864', '0xc86464', 'R', 8800, 14, 'Y');

insert into wfl_state_detail (STATE, PROF_TYPE, ICON_NAME, ICON_TYPE, ICON_COLOR, ICON_BG_COLOR, FLG_COLOR, GRID_TIMEOUT, RANK, STATE_CAN_BE_DELAYED)
values (215, 'P', 'DeclinedIcon', 'DI', '0x787864', '0xc86464', 'R', 8800, 16, 'Y');

--@04_wfl_state_relate.sql;
insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (1, 3, 1, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (2, 14, 11, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (3, 1, 7, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (4, 14, 12, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (5, 14, 13, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (6, 14, 7, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (7, 4, 5, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (9, 101, 103, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (10, 102, 104, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (11, 104, 105, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (12, null, 1, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (14, null, 101, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (16, 3, 6, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (17, 1, 11, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (18, 1, 12, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (19, 1, 13, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (20, 11, 4, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (21, 11, 5, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (22, 106, 102, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (23, 101, 106, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (24, 1, 5, 'N', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (25, 13, 4, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (26, 13, 5, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (27, 11, 14, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (28, 13, 14, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (29, 106, 107, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (30, 4, 15, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (31, 5, 15, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (32, 15, 4, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (33, 15, 5, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (34, 211, 214, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (35, 213, 214, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (36, 203, 201, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (37, 201, 207, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (38, 204, 205, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (39, 203, 206, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (40, 211, 204, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (41, 211, 205, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (42, 201, 205, 'N', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (43, 213, 204, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (44, 213, 205, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (45, 201, 212, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (46, 201, 213, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (47, 214, 211, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (48, 214, 212, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (49, 214, 213, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (50, 214, 207, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (51, 204, 215, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (52, 205, 215, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (53, 215, 204, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (54, 215, 205, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (55, 201, 211, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (56, 102, 108, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (57, 205, 205, 'Y', 0);

insert into wfl_state_relate (ID_STATE_RELATION, STATE, NEXT_STATE, FLG_ACTIVE, RANK)
values (58, 5, 5, 'Y', 0);

--@05_wfl_action.sql;
insert into wfl_action (ID_ACTION, ACTION_NAME, CODE_TRANSLATION, ICON, FLG_ACTIVE, FLG_TYPE)
values (1, 'ADM validate', 'WFL_ACTION.ID_ACTION.1', '', 'Y', 'A');

insert into wfl_action (ID_ACTION, ACTION_NAME, CODE_TRANSLATION, ICON, FLG_ACTIVE, FLG_TYPE)
values (2, 'ADM reject', 'WFL_ACTION.ID_ACTION.2', '', 'Y', 'A');

insert into wfl_action (ID_ACTION, ACTION_NAME, CODE_TRANSLATION, ICON, FLG_ACTIVE, FLG_TYPE)
values (3, 'ADM prepare', 'WFL_ACTION.ID_ACTION.3', '', 'Y', 'A');

insert into wfl_action (ID_ACTION, ACTION_NAME, CODE_TRANSLATION, ICON, FLG_ACTIVE, FLG_TYPE)
values (4, 'ADM double validation', 'WFL_ACTION.ID_ACTION.4', '', 'Y', 'A');

insert into wfl_action (ID_ACTION, ACTION_NAME, CODE_TRANSLATION, ICON, FLG_ACTIVE, FLG_TYPE)
values (5, 'INT deliver to patient', 'WFL_ACTION.ID_ACTION.5', '', 'Y', 'I');

insert into wfl_action (ID_ACTION, ACTION_NAME, CODE_TRANSLATION, ICON, FLG_ACTIVE, FLG_TYPE)
values (6, 'ADM close devolution', 'WFL_ACTION.ID_ACTION.6', '', 'Y', 'A');

insert into wfl_action (ID_ACTION, ACTION_NAME, CODE_TRANSLATION, ICON, FLG_ACTIVE, FLG_TYPE)
values (7, 'INT validate', 'WFL_ACTION.ID_ACTION.7', '', 'Y', 'I');

insert into wfl_action (ID_ACTION, ACTION_NAME, CODE_TRANSLATION, ICON, FLG_ACTIVE, FLG_TYPE)
values (8, 'INT reject', 'WFL_ACTION.ID_ACTION.8', '', 'Y', 'I');

insert into wfl_action (ID_ACTION, ACTION_NAME, CODE_TRANSLATION, ICON, FLG_ACTIVE, FLG_TYPE)
values (9, 'INT prepare', 'WFL_ACTION.ID_ACTION.9', '', 'Y', 'I');

insert into wfl_action (ID_ACTION, ACTION_NAME, CODE_TRANSLATION, ICON, FLG_ACTIVE, FLG_TYPE)
values (10, 'INT double validation', 'WFL_ACTION.ID_ACTION.10', '', 'Y', 'I');

--@06_wfl_conf_profile_action.sql;
insert into wfl_conf_profile_action (ACTION, PROFILE_TEMPL)
values (1, 24);

insert into wfl_conf_profile_action (ACTION, PROFILE_TEMPL)
values (2, 24);

insert into wfl_conf_profile_action (ACTION, PROFILE_TEMPL)
values (3, 24);

insert into wfl_conf_profile_action (ACTION, PROFILE_TEMPL)
values (4, 24);

insert into wfl_conf_profile_action (ACTION, PROFILE_TEMPL)
values (5, 24);

insert into wfl_conf_profile_action (ACTION, PROFILE_TEMPL)
values (6, 24);

insert into wfl_conf_profile_action (ACTION, PROFILE_TEMPL)
values (7, 24);

insert into wfl_conf_profile_action (ACTION, PROFILE_TEMPL)
values (8, 24);

insert into wfl_conf_profile_action (ACTION, PROFILE_TEMPL)
values (9, 24);

insert into wfl_conf_profile_action (ACTION, PROFILE_TEMPL)
values (10, 24);

--@07_wfl_state_trans_action.sql;
insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (2, 1);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (3, 2);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (4, 1);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (5, 1);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (6, 2);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (17, 1);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (18, 1);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (19, 1);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (20, 3);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (21, 3);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (22, 4);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (22, 10);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (23, 3);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (23, 9);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (24, 3);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (25, 3);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (26, 3);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (27, 2);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (28, 2);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (29, 2);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (29, 8);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (30, 2);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (31, 2);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (32, 3);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (33, 3);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (34, 8);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (35, 8);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (37, 8);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (40, 9);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (41, 9);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (42, 9);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (43, 9);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (44, 9);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (45, 7);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (46, 7);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (47, 7);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (48, 7);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (49, 7);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (50, 8);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (51, 8);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (52, 8);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (53, 9);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (54, 9);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (55, 7);

insert into wfl_state_trans_action (STATE_RELATION, ACTION)
values (56, 5);


--data "repair" ************

delete from drug_req_det_state_transition;

--ADM
update drug_req_det drdb
set drdb.id_state = 1,
	drdb.control1 = 'Y'
where drdb.flg_status = 'R'
	and drdb.id_state != 1
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 10,
	drdb.control1 = 'Y'
where drdb.flg_status = 'P'
	and drdb.id_state != 10
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 8,
	drdb.control1 = 'Y'
where drdb.flg_status = 'I'
	and drdb.id_state != 8
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 4,
	drdb.control1 = 'Y'
where drdb.flg_status = 'D'
	and drdb.id_state != 4
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 6,
	drdb.control1 = 'Y'
where drdb.flg_status = 'C'
	and drdb.id_state != 6
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 7,
	drdb.control1 = 'Y'
where drdb.flg_status = 'J'
	and drdb.id_state != 7
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 3,
	drdb.control1 = 'Y'
where drdb.flg_status = 'T'
	and drdb.id_state != 3
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 5,
	drdb.control1 = 'Y'
where drdb.flg_status = 'F'
	and drdb.id_state != 5
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 4,
	drdb.control1 = 'Y'
where drdb.flg_status = 'E'
	and drdb.id_state != 4
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 9,
	drdb.control1 = 'Y'
where drdb.flg_status = 'L'
	and drdb.id_state != 9
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb2
set drdb2.id_state = 1,
	drdb2.control1 = 'Y'
where drdb2.id_drug_req_det in (
	select drdb.id_drug_req_det
	from drug_req_det drdb, drug_req drb
	where 
		drdb.id_drug_req = drb.id_drug_req
		and drdb.id_state = 4
		and drdb.flg_status = 'D'
		and drb.flg_type = 'A'
		and not exists (select 1 from drug_req_supply drsb where drsb.id_drug_req_det = drdb.id_drug_req_det)
	);


--INT
update drug_req_det drdb
set drdb.id_state = 201,
	drdb.control1 = 'Y'
where drdb.flg_status = 'R'
	and drdb.id_state != 201
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 210,
	drdb.control1 = 'Y'
where drdb.flg_status = 'P'
	and drdb.id_state != 210
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 208,
	drdb.control1 = 'Y'
where drdb.flg_status = 'I'
	and drdb.id_state != 208
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 204,
	drdb.control1 = 'Y'
where drdb.flg_status = 'D'
	and drdb.id_state != 204
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 206,
	drdb.control1 = 'Y'
where drdb.flg_status = 'C'
	and drdb.id_state != 206
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 207,
	drdb.control1 = 'Y'
where drdb.flg_status = 'J'
	and drdb.id_state != 207
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 203,
	drdb.control1 = 'Y'
where drdb.flg_status = 'T'
	and drdb.id_state != 203
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 205,
	drdb.control1 = 'Y'
where drdb.flg_status = 'F'
	and drdb.id_state != 205
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 204,
	drdb.control1 = 'Y'
where drdb.flg_status = 'E'
	and drdb.id_state != 204
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 209,
	drdb.control1 = 'Y'
where drdb.flg_status = 'L'
	and drdb.id_state != 209
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb2
set drdb2.id_state = 201,
	drdb2.control1 = 'Y'
where drdb2.id_drug_req_det in (
	select drdb.id_drug_req_det
	from drug_req_det drdb, drug_req drb
	where 
		drdb.id_drug_req = drb.id_drug_req
		and drdb.id_state = 4
		and drdb.flg_status = 'D'
		and drb.flg_type = 'I'
		and not exists (select 1 from drug_req_supply drsb where drsb.id_drug_req_det = drdb.id_drug_req_det)
	);


-- DRS 
delete from drug_req_sup_state_transition;

update drug_req_supply drs
set drs.id_state = pk_medication_workflow.get_id_state_from_old_flag(2, drs.flg_status)
where drs.flg_status is not null;

update drug_req_supply drs
set drs.id_state = 103
where drs.flg_status is null;

--enable constraints
alter table drug_req_det
enable constraint DRUG_REQ_DET_STATE_FK;

alter table drug_req_det_state_transition
enable constraint DRUG_REQ_ST_TRANS_WFL_ST_FK;

alter table drug_req_supply
enable constraint DRUG_REQ_SUP_STATE_FK;

alter table drug_req_sup_state_transition
enable constraint DRUG_SUP_ST_TRANS_WFL_ST_FK;

-- CHANGE END: Rui Marante


-- CHANGED BY: Rui Marante
-- CHANGED DATE: 2009-06-17
-- CHANGED REASON: ALERT-31058

--data "repair" ************

--ADM
update drug_req_det drdb
set drdb.id_state = 1
where drdb.flg_status = 'R'
	and drdb.id_state != 1
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 10
where drdb.flg_status = 'P'
	and drdb.id_state != 10
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 8
where drdb.flg_status = 'I'
	and drdb.id_state != 8
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 4
where drdb.flg_status = 'D'
	and drdb.id_state != 4
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 6
where drdb.flg_status = 'C'
	and drdb.id_state != 6
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 7
where drdb.flg_status = 'J'
	and drdb.id_state != 7
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 3
where drdb.flg_status = 'T'
	and drdb.id_state != 3
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 5
where drdb.flg_status = 'F'
	and drdb.id_state != 5
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 4
where drdb.flg_status = 'E'
	and drdb.id_state != 4
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 9
where drdb.flg_status = 'L'
	and drdb.id_state != 9
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'A'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb2
set drdb2.id_state = 1
where drdb2.id_drug_req_det in (
	select drdb.id_drug_req_det
	from drug_req_det drdb, drug_req drb
	where 
		drdb.id_drug_req = drb.id_drug_req
		and drdb.id_state = 4
		and drdb.flg_status = 'D'
		and drb.flg_type = 'A'
		and not exists (select 1 from drug_req_supply drsb where drsb.id_drug_req_det = drdb.id_drug_req_det)
	);


--INT
update drug_req_det drdb
set drdb.id_state = 201
where drdb.flg_status = 'R'
	and drdb.id_state != 201
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 210
where drdb.flg_status = 'P'
	and drdb.id_state != 210
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 208
where drdb.flg_status = 'I'
	and drdb.id_state != 208
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 204
where drdb.flg_status = 'D'
	and drdb.id_state != 204
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 206
where drdb.flg_status = 'C'
	and drdb.id_state != 206
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 207
where drdb.flg_status = 'J'
	and drdb.id_state != 207
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 203
where drdb.flg_status = 'T'
	and drdb.id_state != 203
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 205
where drdb.flg_status = 'F'
	and drdb.id_state != 205
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 204
where drdb.flg_status = 'E'
	and drdb.id_state != 204
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb
set drdb.id_state = 209
where drdb.flg_status = 'L'
	and drdb.id_state != 209
	and exists (
			select 1 
			from drug_req dr 
			where dr.flg_type = 'I'
				and dr.id_drug_req = drdb.id_drug_req
	);

update drug_req_det drdb2
set drdb2.id_state = 201
where drdb2.id_drug_req_det in (
	select drdb.id_drug_req_det
	from drug_req_det drdb, drug_req drb
	where 
		drdb.id_drug_req = drb.id_drug_req
		and drdb.id_state = 4
		and drdb.flg_status = 'D'
		and drb.flg_type = 'I'
		and not exists (select 1 from drug_req_supply drsb where drsb.id_drug_req_det = drdb.id_drug_req_det)
	);


-- DRS 
delete from drug_req_sup_state_transition;

update drug_req_supply drs
set drs.id_state = pk_medication_workflow.get_id_state_from_old_flag(2, drs.flg_status)
where drs.flg_status is not null;

update drug_req_supply drs
set drs.id_state = 103
where drs.flg_status is null;

--enable constraints
alter table drug_req_det
enable constraint DRUG_REQ_DET_STATE_FK;

alter table drug_req_det_state_transition
enable constraint DRUG_REQ_ST_TRANS_WFL_ST_FK;

alter table drug_req_supply
enable constraint DRUG_REQ_SUP_STATE_FK;

alter table drug_req_sup_state_transition
enable constraint DRUG_SUP_ST_TRANS_WFL_ST_FK;

-- CHANGE END: Rui Marante

-- CHANGED BY: Pedro Lopes
-- CHANGE DATE: 2009-JUN-30
-- CHANGE REASON: ALERT-913

ALTER PACKAGE pk_icnp COMPILE PACKAGE; 

-- CHANGED END


-- CHANGED BY: Pedro Lopes
-- CHANGE DATE: 2009-JUL-03
-- CHANGE REASON: ALERT-913

ALTER TABLE icnp_term enable CONSTRAINT ITM_IAS_FK;

--CHANGE END

-- CHANGED BY: Pedro Lopes
-- CHANGE DATE: 2009-JUL-03
-- CHANGE REASON: ALERT-913

ALTER TABLE icnp_term enable CONSTRAINT ITM_IAS_FK;
ALTER TABLE icnp_term enable CONSTRAINT ICT_ITM_FK;
ALTER TABLE icnp_term enable CONSTRAINT IRP_ITM_FK;
ALTER TABLE icnp_term enable CONSTRAINT IRP_ITM_REL_FK;

--CHANGE END

-- CHANGED BY: Pedro Lopes
-- CHANGE DATE: 2009-JUL-03
-- CHANGE REASON: ALERT-913

ALTER TABLE icnp_term enable CONSTRAINT ITM_IAS_FK;
ALTER TABLE icnp_composition_term enable CONSTRAINT ICT_ITM_FK;
ALTER TABLE icnp_relationship enable CONSTRAINT IRP_ITM_FK;
ALTER TABLE icnp_relationship enable CONSTRAINT IRP_ITM_REL_FK;

--CHANGE END


-- CHANGED BY: Luís Maia
-- CHANGE DATE: 08/06/2009 14:26
-- CHANGE REASON: [ALERT-24599] Script responsable for migrate all tasks to table TASK_TIMELINE_EA.
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_all_task_tl_tables';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_all_task_tl_tables(i_patient                => NULL,
                                                      i_episode                => NULL,
                                                      i_schedule               => NULL,
                                                      i_external_request       => NULL,
                                                      i_institution            => NULL,
                                                      i_start_dt               => NULL,
                                                      i_end_dt                 => NULL,
                                                      i_validate_table         => FALSE,
                                                      i_output_invalid_records => TRUE,
                                                      i_recreate_table         => TRUE,
                                                      i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END: Luís Maia

-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 06-07-2009
-- CHANGE REASON: ALERT-687
ALTER TABLE ROUNDS 
 MODIFY (FLG_EDIT VARCHAR2(1) NOT NULL
 )
/

ALTER TABLE ROUNDS_HIST
 MODIFY (FLG_EDIT VARCHAR2(1) NOT NULL
 )
/
--CHANGE END

-- CHANGED BY: Pedro Lopes
-- CHANGE DATE: 2009-07-22
-- CHANGE REASON: ICNP Builder ALERT-913

ALTER TABLE icnp_term enable CONSTRAINT ITM_ITM_FK;

--CHANGE END

-- CHANGED BY: Ana Matos
-- CHANGED DATE: 2009-JUL-28
-- CHANGED REASON: ALERT-16811

DECLARE

    RESULT BOOLEAN;

    l_result   exam_result.notes%TYPE;
    l_lang     LANGUAGE.id_language%TYPE;
    l_rows_out table_varchar := table_varchar();

    CURSOR c_doc IS
        SELECT ed.id_epis_documentation, er.id_exam_result, er.id_professional, ei.id_software, e.id_institution
          FROM epis_documentation ed
         INNER JOIN exam_result er ON ed.id_epis_context = er.id_exam_result
         INNER JOIN epis_info ei ON ed.id_episode = ei.id_episode
         INNER JOIN episode e ON ed.id_episode = e.id_episode
         WHERE ed.id_doc_area = 1083;

    CURSOR c_lang(id_prof IN NUMBER, id_software IN NUMBER, id_institution IN NUMBER) IS
        SELECT pp.id_language
          FROM prof_preferences pp
         WHERE pp.id_professional = id_prof
           AND pp.id_software = id_software
           AND pp.id_institution = id_institution;
BEGIN

    FOR rec IN c_doc
    LOOP
    
        OPEN c_lang(rec.id_professional, rec.id_software, rec.id_institution);
        FETCH c_lang
            INTO l_lang;
        CLOSE c_lang;
    
        SELECT pk_utils.concatenate_list(CURSOR
                                         (SELECT desc_info
                                            FROM (SELECT t.id_doc_component,
                                                         t.id_episode,
                                                         t.desc_component,
                                                         t.desc_element,
                                                         t.desc_component || ' ' || t.desc_element ||
                                                         decode(desc_element, NULL, NULL, '.') AS desc_info
                                                    FROM (SELECT DISTINCT dc.id_doc_component,
                                                                          ed.id_episode,
                                                                          decode(dc.id_doc_component,
                                                                                 NULL,
                                                                                 ed.notes,
                                                                                 pk_translation.get_translation(l_lang,
                                                                                                                dc.code_doc_component) || ':') desc_component,
                                                                          pk_utils.concatenate_list(CURSOR
                                                                                                    (SELECT nvl2(edd1.VALUE,
                                                                                                                 nvl2(pk_translation.get_translation(l_lang,
                                                                                                                                                     decr.code_element_close),
                                                                                                                      pk_translation.get_translation(l_lang,
                                                                                                                                                     decr.code_element_close) || ': ',
                                                                                                                      NULL) ||
                                                                                                                 
                                                                                                                 pk_touch_option.get_formatted_value(l_lang,
                                                                                                                                                     profissional(rec.id_professional,
                                                                                                                                                                  rec.id_institution,
                                                                                                                                                                  rec.id_software),
                                                                                                                                                     de.flg_type,
                                                                                                                                                     edd1.VALUE,
                                                                                                                                                     edd1.value_properties,
                                                                                                                                                     de.input_mask,
                                                                                                                                                     de.flg_optional_value,
                                                                                                                                                     de.flg_element_domain_type,
                                                                                                                                                     de.code_element_domain),
                                                                                                                 
                                                                                                                 pk_translation.get_translation(l_lang,
                                                                                                                                                decr.code_element_close)) ||
                                                                                                            pk_summary_page.get_epis_doc_qualif(l_lang,
                                                                                                                                                edd1.id_epis_documentation_det) desc_qualification
                                                                                                       FROM epis_documentation     ed1,
                                                                                                            epis_documentation_det edd1,
                                                                                                            documentation          d1,
                                                                                                            doc_element_crit       decr,
                                                                                                            doc_element            de
                                                                                                      WHERE ed1.id_epis_documentation =
                                                                                                            edd1.id_epis_documentation
                                                                                                        AND edd1.id_epis_documentation =
                                                                                                            rec.id_epis_documentation
                                                                                                        AND d1.id_documentation =
                                                                                                            edd1.id_documentation
                                                                                                        AND edd1.id_doc_element_crit =
                                                                                                            decr.id_doc_element_crit
                                                                                                        AND d1.id_doc_component =
                                                                                                            dc.id_doc_component
                                                                                                        AND ed1.flg_status = 'A'
                                                                                                        AND de.id_doc_element =
                                                                                                            edd1.id_doc_element
                                                                                                      ORDER BY ed1.dt_creation_tstz DESC,
                                                                                                               d1.rank,
                                                                                                               de.rank),
                                                                                                    ', ') desc_element,
                                                                          ed.notes,
                                                                          d.rank
                                                            FROM epis_documentation     ed,
                                                                 epis_documentation_det edd,
                                                                 documentation          d,
                                                                 doc_component          dc
                                                           WHERE ed.id_epis_documentation = edd.id_epis_documentation(+)
                                                             AND ed.id_epis_documentation = rec.id_epis_documentation
                                                             AND d.id_documentation(+) = edd.id_documentation
                                                             AND d.id_doc_component = dc.id_doc_component(+)
                                                             AND ed.id_doc_area(+) = 1083
                                                             AND ed.flg_status(+) = 'A'
                                                           ORDER BY d.rank) t)),
                                         chr(10))
          INTO l_result
          FROM dual;
    
        ts_exam_result.upd(id_exam_result_in => rec.id_exam_result, notes_in => l_result, rows_out => l_rows_out);
    END LOOP;

    RESULT := pk_data_gov_admin.admin_exams_ea(i_patient          => NULL,
                                               i_episode          => NULL,
                                               i_schedule         => NULL,
                                               i_external_request => NULL,
                                               i_institution      => NULL,
                                               i_start_dt         => NULL,
                                               i_end_dt           => NULL,
                                               i_validate_table   => FALSE,
                                               i_recreate_table   => TRUE,
                                               i_commit_step      => 1);

END;

-- CHANGED END: Ana Matos

-- CHANGED BY: Ana Monteiro
-- CHANGED DATE: 2009-JUL-02
-- CHANGED REASON: ALERT-18963
CREATE OR REPLACE TYPE t_coll_p1_request as TABLE OF t_rec_p1_request;


-- procedimento tem que estar neste run_end por causa dos commits que faz de 10000 em 10000 registos
DECLARE
    CURSOR c_tracking IS
        SELECT id_prof_dest, id_external_request, ext_req_status
          FROM p1_tracking
         WHERE (ext_req_status = 'R' AND flg_type = 'P')
            OR (ext_req_status = 'T' AND flg_type = 'C') -- pode ter que se limpar o id_prof_redirected por ter tido alt de serv clinico depois do reenc
         ORDER BY id_external_request, dt_tracking_tstz DESC;

    TYPE t_tracking IS TABLE OF c_tracking%ROWTYPE INDEX BY PLS_INTEGER;

    l_tracking_tab t_tracking;
    l_limit        PLS_INTEGER := 10000;

    TYPE t_number_tab IS TABLE OF NUMBER(24) INDEX BY PLS_INTEGER;

    l_ext_req_tab t_number_tab;
    l_prof_tab    t_number_tab;

    l_prev_id p1_tracking.id_external_request%TYPE := -1;
    l_error   VARCHAR2(500);
    l_count   NUMBER := 0;
BEGIN
    l_error := 'OPEN c_tracking';
    OPEN c_tracking;
    LOOP
        l_error := 'FETCH c_tracking';
        FETCH c_tracking BULK COLLECT
            INTO l_tracking_tab LIMIT l_limit;
    
        l_error := 'FOR';
        FOR idx IN 1 .. l_tracking_tab.COUNT
        LOOP
        
            IF l_prev_id != l_tracking_tab(idx).id_external_request
            THEN
            
                l_error := 'new p1';
                -- novo p1, actualizar p1_external_request.id_prof_redirected com p1_tracking.id_prof_dest
                IF l_tracking_tab(idx).ext_req_status = 'R'
                THEN
                    l_count := l_count + 1;
                    l_ext_req_tab(l_count) := l_tracking_tab(idx).id_external_request;
                    l_prof_tab(l_count) := l_tracking_tab(idx).id_prof_dest;

                ELSIF l_tracking_tab(idx).ext_req_status = 'T'
                THEN
                    -- alteracao de servico clinico, tem que limpar o valor
										l_count := l_count + 1;
                    l_ext_req_tab(l_count) := l_tracking_tab(idx).id_external_request;
                    l_prof_tab(l_count) := NULL;
                
                END IF;
            ELSE
                -- p1 ja foi tratado, passar ao seguinte
                NULL;
            END IF;
        
            l_error   := 'l_prev_id';
            l_prev_id := l_tracking_tab(idx).id_external_request;
        
        END LOOP;
    
        -- actualiza os registos em l_track_upd_tab
        FORALL i IN 1 .. l_ext_req_tab.COUNT
            UPDATE p1_external_request
               SET id_prof_redirected = l_prof_tab(i)
             WHERE id_external_request = l_ext_req_tab(i);
    
        COMMIT;								
    
        -- reset vars
        l_count := 0;
        l_ext_req_tab.DELETE;
        l_prof_tab.DELETE;
    
        l_error := 'EXIT';
        EXIT WHEN l_tracking_tab.COUNT < l_limit;
    
    END LOOP;

    l_error := 'CLOSE c_tracking';
    CLOSE c_tracking;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        IF c_tracking%ISOPEN
        THEN
            CLOSE c_tracking;
        END IF;
        dbms_output.put_line('ERR:' || l_error || ' ' || SQLERRM);
END;
/
-- CHANGE END:  Ana Monteiro

-- CHANGED BY: Rui Marante
-- CHANGE REASON: ALERT-32919
-- CHANGE DATE: 2009/07/31

alter table pharm_unidose_car_model
drop constraint PHARM_UCM_UCT_FK;

alter table pharm_unidose_car_model
drop column id_car_type;

drop sequence seq_pharm_unidose_car_type;

drop table pharm_unidose_car_type;

alter table drug_req_supply_dev
modify (
	qty_for_stock number(24,4),
	qty_for_trash number(24,4),
	qty_dev number(24,4)
);

alter table drug_req_supply
modify qty_supply number(24,4);

alter table drug_req_det
modify (
	qty_to_prep number(24,4),
	qty_req number(24,4),
	qty_supplied number(24,4)
);

--pharmacy workflow log -> replace by alertlog.tlog
drop table wfl_log;
drop sequence seq_wfl_log_id;

alter table pharm_unidose_car_slot
drop constraint UCS_ST_FK;

alter table pharm_unidose_car_slot
drop column id_state;


-- create audit columns and triggers
declare
	town	varchar2(30)	:= 'ALERT';

	--pharmacy related tables
	tbls	table_varchar	:= 
				table_varchar(
					'WFL_ACTION',
					'WFL_CONF_PROFILE_ACTION',
					'WFL_CONF_PROF_ACTION',
					'WFL_STATE',
					'WFL_STATE_DETAIL',
					'WFL_STATE_RELATE',
					'WFL_STATE_SCOPE',
					'WFL_STATE_TRANS_ACTION',
					'PHARM_UNIDOSE_CAR',
					'PHARM_UNIDOSE_CAR_MODEL',
					'PHARM_UNIDOSE_CAR_SLOT',
					'PHARM_UNIDOSE_CAR_STATE_TRANS',
					'PHARM_UNIDOSE_EXCEPTION_MEDS',
					'PHARM_UNIDOSE_REQ_GEN',
					'PHARM_UNIDOSE_REQ_GEN_CAR',
					'PHARM_UNIDOSE_SLOT_CONTENT',
					'DRUG_REQ',
					'DRUG_REQ_DET',
					'DRUG_REQ_DET_HIST_MODIF',
					'DRUG_REQ_DET_REFILL',
					'DRUG_REQ_DET_STATE_TRANSITION',
					'DRUG_REQ_SUPPLY',
					'DRUG_REQ_SUPPLY_DEV',
					'DRUG_REQ_SUP_DEV_STATE_TRANS',
					'DRUG_REQ_SUP_STATE_TRANSITION'
				);

	cols table_varchar := table_varchar(
		'CREATE_USER VARCHAR2(24)',
		'CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE',
		'CREATE_INSTITUTION NUMBER(24)',
		'UPDATE_USER VARCHAR2(24)',
		'UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE',
		'UPDATE_INSTITUTION NUMBER(24)'
	);

	error_count		number := 0;
	sql_cmd			varchar2(1000) := '';
	func_out		boolean := false;
	trigger_name	varchar2(100) := '';
begin

	for t in 1 .. tbls.count
	loop
		--columns
		for c in 1 .. cols.count
		loop
			sql_cmd := 'alter table ' || tbls(t) || ' add ' || cols(c) || ' ';

			begin
				dbms_output.put_line(sql_cmd);
				execute immediate sql_cmd;
			exception
			when others then
				--columns already there!
				error_count := error_count + 1;
				dbms_output.put_line('ERROR TABLE-COL:' || tbls(t) || '.' || cols(c));
			end;
		end loop;

		--trigger
		begin
			func_out := pk_dev.create_audit_trigger(tbls(t), town, trigger_name);
			dbms_output.put_line('pk_dev.create_audit_trigger(''' || tbls(t) || ''', ''' || town || ''', ''trigger_name'');');
		exception
		when others then
			--trigger already there!
			error_count := error_count + 1;
			dbms_output.put_line('ERROR TRIGGER:' || tbls(t));
		end;
	end loop;

	dbms_output.put_line('-- ***** -- ***** -- ***** -- ***** -- ***** -- ***** --');
	dbms_output.put_line('DONE! errors: ' || to_char(error_count) || '!');	

exception
when others then
	dbms_output.put_line('CRITICAL ERROR!!');
end;
/

-- CHANGE END:  Rui Marante





--
-- CHANGED BY: THIAGO BRITO
-- CHANGE DATE: 2009-Aug-17
-- CHANGE REASON: ALERT-38425

DECLARE

    l_vital_sign_read      TABLE_NUMBER;
    l_episode              TABLE_NUMBER;
    l_patient              TABLE_NUMBER;
    l_id_vs_scales_element NUMBER(24);
    l_affected_rows        PLS_INTEGER;
    l_total_rows           PLS_INTEGER;

BEGIN

    l_total_rows := 0;

    dbms_output.enable(100000);

    SELECT vsea.id_vital_sign_read, vsea.id_episode, vsea.id_patient BULK COLLECT
      INTO l_vital_sign_read, l_episode, l_patient
      FROM vital_signs_ea vsea;

    FOR i IN l_vital_sign_read.FIRST .. l_vital_sign_read.LAST
    LOOP
    
        SELECT vsr.id_vs_scales_element
          INTO l_id_vs_scales_element
          FROM vital_sign_read vsr
         WHERE vsr.id_vital_sign_read = l_vital_sign_read(i);
    
        UPDATE vital_signs_ea vsea
           SET vsea.id_vs_scales_element = l_id_vs_scales_element
         WHERE vsea.id_vital_sign_read = l_vital_sign_read(i)
           AND vsea.id_episode = l_episode(i)
           AND vsea.id_patient = l_patient(i);
    
        l_affected_rows := SQL%ROWCOUNT;
        l_total_rows    := l_total_rows + SQL%ROWCOUNT;
    
        IF (l_affected_rows > 1)
        THEN
            dbms_output.put_line('ROWS:' || to_char(l_affected_rows));
        END IF;
    
    END LOOP;

    dbms_output.put_line('Total number of affected rows: ' || to_char(l_total_rows));

END;
/

--

-- CHANGED BY: Rui Marante
-- CHANGE REASON: ALERT-32919
-- CHANGE DATE: 2009/08/19

-- 1/25
begin execute immediate 'alter table WFL_ACTION add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_ACTION.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_ACTION add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_ACTION.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_ACTION add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_ACTION.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table WFL_ACTION add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_ACTION.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_ACTION add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_ACTION.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_ACTION add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_ACTION.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: WFL_ACTION
CREATE OR REPLACE TRIGGER ALERT.B_IU_WFL_ACTION_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.WFL_ACTION
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_WFL_ACTION_AUDIT-'||sqlerrm);
END B_IU_WFL_ACTION_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: WFL_ACTION
--
-- 2/25
begin execute immediate 'alter table WFL_CONF_PROFILE_ACTION add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROFILE_ACTION.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_CONF_PROFILE_ACTION add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROFILE_ACTION.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_CONF_PROFILE_ACTION add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROFILE_ACTION.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table WFL_CONF_PROFILE_ACTION add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROFILE_ACTION.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_CONF_PROFILE_ACTION add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROFILE_ACTION.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_CONF_PROFILE_ACTION add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROFILE_ACTION.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: WFL_CONF_PROFILE_ACTION
CREATE OR REPLACE TRIGGER ALERT.B_IU_WFL_CONF_PF_ACT_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.WFL_CONF_PROFILE_ACTION
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_WFL_CONF_PROFILE_ACTION_AUDIT-'||sqlerrm);
END B_IU_WFL_CONF_PF_ACT_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: WFL_CONF_PROFILE_ACTION
--
-- 3/25
begin execute immediate 'alter table WFL_CONF_PROF_ACTION add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROF_ACTION.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_CONF_PROF_ACTION add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROF_ACTION.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_CONF_PROF_ACTION add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROF_ACTION.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table WFL_CONF_PROF_ACTION add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROF_ACTION.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_CONF_PROF_ACTION add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROF_ACTION.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_CONF_PROF_ACTION add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_CONF_PROF_ACTION.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: WFL_CONF_PROF_ACTION
CREATE OR REPLACE TRIGGER ALERT.B_IU_WFL_CONF_PRO_ACT_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.WFL_CONF_PROF_ACTION
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_WFL_CONF_PROF_ACTION_AUDIT-'||sqlerrm);
END B_IU_WFL_CONF_PRO_ACT_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: WFL_CONF_PROF_ACTION
--
-- 4/25
begin execute immediate 'alter table WFL_STATE add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_STATE add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_STATE add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table WFL_STATE add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_STATE add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_STATE add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: WFL_STATE
CREATE OR REPLACE TRIGGER ALERT.B_IU_WFL_STATE_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.WFL_STATE
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_WFL_STATE_AUDIT-'||sqlerrm);
END B_IU_WFL_STATE_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: WFL_STATE
--
-- 5/25
begin execute immediate 'alter table WFL_STATE_DETAIL add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_DETAIL.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_DETAIL add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_DETAIL.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_STATE_DETAIL add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_DETAIL.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_DETAIL add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_DETAIL.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_DETAIL add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_DETAIL.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_STATE_DETAIL add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_DETAIL.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: WFL_STATE_DETAIL
CREATE OR REPLACE TRIGGER ALERT.B_IU_WFL_STATE_DETAIL_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.WFL_STATE_DETAIL
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_WFL_STATE_DETAIL_AUDIT-'||sqlerrm);
END B_IU_WFL_STATE_DETAIL_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: WFL_STATE_DETAIL
--
-- 6/25
begin execute immediate 'alter table WFL_STATE_RELATE add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_RELATE.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_RELATE add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_RELATE.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_STATE_RELATE add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_RELATE.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_RELATE add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_RELATE.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_RELATE add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_RELATE.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_STATE_RELATE add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_RELATE.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: WFL_STATE_RELATE
CREATE OR REPLACE TRIGGER ALERT.B_IU_WFL_STATE_RELATE_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.WFL_STATE_RELATE
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_WFL_STATE_RELATE_AUDIT-'||sqlerrm);
END B_IU_WFL_STATE_RELATE_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: WFL_STATE_RELATE
--
-- 7/25
begin execute immediate 'alter table WFL_STATE_SCOPE add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_SCOPE.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_SCOPE add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_SCOPE.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_STATE_SCOPE add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_SCOPE.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_SCOPE add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_SCOPE.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_SCOPE add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_SCOPE.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_STATE_SCOPE add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_SCOPE.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: WFL_STATE_SCOPE
CREATE OR REPLACE TRIGGER ALERT.B_IU_WFL_STATE_SCOPE_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.WFL_STATE_SCOPE
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_WFL_STATE_SCOPE_AUDIT-'||sqlerrm);
END B_IU_WFL_STATE_SCOPE_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: WFL_STATE_SCOPE
--
-- 8/25
begin execute immediate 'alter table WFL_STATE_TRANS_ACTION add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_TRANS_ACTION.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_TRANS_ACTION add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_TRANS_ACTION.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_STATE_TRANS_ACTION add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_TRANS_ACTION.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_TRANS_ACTION add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_TRANS_ACTION.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table WFL_STATE_TRANS_ACTION add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_TRANS_ACTION.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table WFL_STATE_TRANS_ACTION add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: WFL_STATE_TRANS_ACTION.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: WFL_STATE_TRANS_ACTION
CREATE OR REPLACE TRIGGER ALERT.B_IU_WFL_ST_TR_ACT_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.WFL_STATE_TRANS_ACTION
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_WFL_STATE_TRANS_ACTION_AUDIT-'||sqlerrm);
END B_IU_WFL_ST_TR_ACT_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: WFL_STATE_TRANS_ACTION
--
-- 9/25
begin execute immediate 'alter table PHARM_UNIDOSE_CAR add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: PHARM_UNIDOSE_CAR
CREATE OR REPLACE TRIGGER ALERT.B_IU_PHARM_UNI_CAR_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.PHARM_UNIDOSE_CAR
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_PHARM_UNIDOSE_CAR_AUDIT-'||sqlerrm);
END B_IU_PHARM_UNI_CAR_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: PHARM_UNIDOSE_CAR
--
-- 10/25
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_MODEL add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_MODEL.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_MODEL add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_MODEL.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_MODEL add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_MODEL.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_MODEL add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_MODEL.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_MODEL add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_MODEL.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_MODEL add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_MODEL.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: PHARM_UNIDOSE_CAR_MODEL
CREATE OR REPLACE TRIGGER ALERT.B_IU_PHARM_UNI_CAR_MD_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.PHARM_UNIDOSE_CAR_MODEL
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_PHARM_UNIDOSE_CAR_MODEL_AUDIT-'||sqlerrm);
END B_IU_PHARM_UNI_CAR_MD_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: PHARM_UNIDOSE_CAR_MODEL
--
-- 11/25
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_SLOT add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_SLOT.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_SLOT add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_SLOT.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_SLOT add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_SLOT.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_SLOT add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_SLOT.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_SLOT add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_SLOT.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_SLOT add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_SLOT.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: PHARM_UNIDOSE_CAR_SLOT
CREATE OR REPLACE TRIGGER ALERT.B_IU_PHARM_UNI_CAR_SLOT_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.PHARM_UNIDOSE_CAR_SLOT
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_PHARM_UNIDOSE_CAR_SLOT_AUDIT-'||sqlerrm);
END B_IU_PHARM_UNI_CAR_SLOT_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: PHARM_UNIDOSE_CAR_SLOT
--
-- 12/25
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_STATE_TRANS add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_STATE_TRANS.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_STATE_TRANS add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_STATE_TRANS.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_STATE_TRANS add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_STATE_TRANS.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_STATE_TRANS add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_STATE_TRANS.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_STATE_TRANS add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_STATE_TRANS.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_CAR_STATE_TRANS add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_CAR_STATE_TRANS.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: PHARM_UNIDOSE_CAR_STATE_TRANS
CREATE OR REPLACE TRIGGER ALERT.B_IU_PHARM_UNI_CAR_ST_TR_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.PHARM_UNIDOSE_CAR_STATE_TRANS
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_PHARM_UNIDOSE_CAR_STATE_TRANS_AUDIT-'||sqlerrm);
END B_IU_PHARM_UNI_CAR_ST_TR_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: PHARM_UNIDOSE_CAR_STATE_TRANS
--
-- 13/25
begin execute immediate 'alter table PHARM_UNIDOSE_EXCEPTION_MEDS add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_EXCEPTION_MEDS.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_EXCEPTION_MEDS add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_EXCEPTION_MEDS.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_EXCEPTION_MEDS add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_EXCEPTION_MEDS.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_EXCEPTION_MEDS add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_EXCEPTION_MEDS.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_EXCEPTION_MEDS add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_EXCEPTION_MEDS.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_EXCEPTION_MEDS add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_EXCEPTION_MEDS.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: PHARM_UNIDOSE_EXCEPTION_MEDS
CREATE OR REPLACE TRIGGER ALERT.B_IU_PHARM_UNI_EX_MEDS_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.PHARM_UNIDOSE_EXCEPTION_MEDS
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_PHARM_UNIDOSE_EXCEPTION_MEDS_AUDIT-'||sqlerrm);
END B_IU_PHARM_UNI_EX_MEDS_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: PHARM_UNIDOSE_EXCEPTION_MEDS
--
-- 14/25
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: PHARM_UNIDOSE_REQ_GEN
CREATE OR REPLACE TRIGGER ALERT.B_IU_PHARM_UNI_REQ_GEN_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.PHARM_UNIDOSE_REQ_GEN
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_PHARM_UNIDOSE_REQ_GEN_AUDIT-'||sqlerrm);
END B_IU_PHARM_UNI_REQ_GEN_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: PHARM_UNIDOSE_REQ_GEN
--
-- 15/25
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN_CAR add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN_CAR.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN_CAR add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN_CAR.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN_CAR add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN_CAR.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN_CAR add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN_CAR.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN_CAR add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN_CAR.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_REQ_GEN_CAR add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_REQ_GEN_CAR.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: PHARM_UNIDOSE_REQ_GEN_CAR
CREATE OR REPLACE TRIGGER ALERT.B_IU_PHARM_UNI_RQ_GN_CAR_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.PHARM_UNIDOSE_REQ_GEN_CAR
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_PHARM_UNIDOSE_REQ_GEN_CAR_AUDIT-'||sqlerrm);
END B_IU_PHARM_UNI_RQ_GN_CAR_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: PHARM_UNIDOSE_REQ_GEN_CAR
--
-- 16/25
begin execute immediate 'alter table PHARM_UNIDOSE_SLOT_CONTENT add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_SLOT_CONTENT.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_SLOT_CONTENT add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_SLOT_CONTENT.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_SLOT_CONTENT add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_SLOT_CONTENT.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_SLOT_CONTENT add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_SLOT_CONTENT.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_SLOT_CONTENT add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_SLOT_CONTENT.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table PHARM_UNIDOSE_SLOT_CONTENT add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: PHARM_UNIDOSE_SLOT_CONTENT.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: PHARM_UNIDOSE_SLOT_CONTENT
CREATE OR REPLACE TRIGGER ALERT.B_IU_PHARM_UNI_SLOT_CON_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.PHARM_UNIDOSE_SLOT_CONTENT
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_PHARM_UNIDOSE_SLOT_CONTENT_AUDIT-'||sqlerrm);
END B_IU_PHARM_UNI_SLOT_CON_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: PHARM_UNIDOSE_SLOT_CONTENT
--
-- 17/25
begin execute immediate 'alter table DRUG_REQ add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: DRUG_REQ
CREATE OR REPLACE TRIGGER ALERT.B_IU_DRUG_REQ_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.DRUG_REQ
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_DRUG_REQ_AUDIT-'||sqlerrm);
END B_IU_DRUG_REQ_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: DRUG_REQ
--
-- 18/25
begin execute immediate 'alter table DRUG_REQ_DET add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: DRUG_REQ_DET
CREATE OR REPLACE TRIGGER ALERT.B_IU_DRUG_REQ_DET_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.DRUG_REQ_DET
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_DRUG_REQ_DET_AUDIT-'||sqlerrm);
END B_IU_DRUG_REQ_DET_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: DRUG_REQ_DET
--
-- 19/25
begin execute immediate 'alter table DRUG_REQ_DET_HIST_MODIF add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_HIST_MODIF.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_HIST_MODIF add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_HIST_MODIF.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_HIST_MODIF add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_HIST_MODIF.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_HIST_MODIF add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_HIST_MODIF.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_HIST_MODIF add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_HIST_MODIF.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_HIST_MODIF add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_HIST_MODIF.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: DRUG_REQ_DET_HIST_MODIF
CREATE OR REPLACE TRIGGER ALERT.B_IU_DRD_HIST_MDIF_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.DRUG_REQ_DET_HIST_MODIF
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_DRUG_REQ_DET_HIST_MODIF_AUDIT-'||sqlerrm);
END B_IU_DRD_HIST_MDIF_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: DRUG_REQ_DET_HIST_MODIF
--
-- 20/25
begin execute immediate 'alter table DRUG_REQ_DET_REFILL add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_REFILL.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_REFILL add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_REFILL.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_REFILL add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_REFILL.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_REFILL add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_REFILL.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_REFILL add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_REFILL.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_REFILL add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_REFILL.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: DRUG_REQ_DET_REFILL
CREATE OR REPLACE TRIGGER ALERT.B_IU_DRD_REFILL_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.DRUG_REQ_DET_REFILL
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_DRUG_REQ_DET_REFILL_AUDIT-'||sqlerrm);
END B_IU_DRD_REFILL_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: DRUG_REQ_DET_REFILL
--
-- 21/25
begin execute immediate 'alter table DRUG_REQ_DET_STATE_TRANSITION add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_STATE_TRANSITION.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_STATE_TRANSITION add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_STATE_TRANSITION.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_STATE_TRANSITION add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_STATE_TRANSITION.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_STATE_TRANSITION add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_STATE_TRANSITION.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_STATE_TRANSITION add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_STATE_TRANSITION.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_DET_STATE_TRANSITION add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_DET_STATE_TRANSITION.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: DRUG_REQ_DET_STATE_TRANSITION
CREATE OR REPLACE TRIGGER ALERT.B_IU_DRD_ST_TRANS_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.DRUG_REQ_DET_STATE_TRANSITION
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_DRUG_REQ_DET_STATE_TRANSITION_AUDIT-'||sqlerrm);
END B_IU_DRD_ST_TRANS_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: DRUG_REQ_DET_STATE_TRANSITION
--
-- 22/25
begin execute immediate 'alter table DRUG_REQ_SUPPLY add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUPPLY add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUPPLY add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUPPLY add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUPPLY add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUPPLY add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: DRUG_REQ_SUPPLY
CREATE OR REPLACE TRIGGER ALERT.B_IU_DRUG_REQ_SUPPLY_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.DRUG_REQ_SUPPLY
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_DRUG_REQ_SUPPLY_AUDIT-'||sqlerrm);
END B_IU_DRUG_REQ_SUPPLY_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: DRUG_REQ_SUPPLY
--
-- 23/25
begin execute immediate 'alter table DRUG_REQ_SUPPLY_DEV add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY_DEV.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUPPLY_DEV add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY_DEV.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUPPLY_DEV add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY_DEV.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUPPLY_DEV add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY_DEV.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUPPLY_DEV add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY_DEV.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUPPLY_DEV add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUPPLY_DEV.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: DRUG_REQ_SUPPLY_DEV
CREATE OR REPLACE TRIGGER ALERT.B_IU_DRS_DEV_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.DRUG_REQ_SUPPLY_DEV
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_DRUG_REQ_SUPPLY_DEV_AUDIT-'||sqlerrm);
END B_IU_DRS_DEV_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: DRUG_REQ_SUPPLY_DEV
--
-- 24/25
begin execute immediate 'alter table DRUG_REQ_SUP_DEV_STATE_TRANS add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_DEV_STATE_TRANS.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUP_DEV_STATE_TRANS add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_DEV_STATE_TRANS.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUP_DEV_STATE_TRANS add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_DEV_STATE_TRANS.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUP_DEV_STATE_TRANS add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_DEV_STATE_TRANS.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUP_DEV_STATE_TRANS add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_DEV_STATE_TRANS.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUP_DEV_STATE_TRANS add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_DEV_STATE_TRANS.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: DRUG_REQ_SUP_DEV_STATE_TRANS
CREATE OR REPLACE TRIGGER ALERT.B_IU_DRS_DEV_ST_TR_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.DRUG_REQ_SUP_DEV_STATE_TRANS
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
        END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_DRUG_REQ_SUP_DEV_STATE_TRANS_AUDIT-'||sqlerrm);
END B_IU_DRS_DEV_ST_TR_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: DRUG_REQ_SUP_DEV_STATE_TRANS
--
-- 25/25
begin execute immediate 'alter table DRUG_REQ_SUP_STATE_TRANSITION add CREATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_STATE_TRANSITION.CREATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUP_STATE_TRANSITION add CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_STATE_TRANSITION.CREATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUP_STATE_TRANSITION add CREATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_STATE_TRANSITION.CREATE_INSTITUTION NUMBER(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUP_STATE_TRANSITION add UPDATE_USER VARCHAR2(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_STATE_TRANSITION.UPDATE_USER VARCHAR2(24)'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUP_STATE_TRANSITION add UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_STATE_TRANSITION.UPDATE_TIME TIMESTAMP(6) WITH LOCAL TIME ZONE'); end;
/
begin execute immediate 'alter table DRUG_REQ_SUP_STATE_TRANSITION add UPDATE_INSTITUTION NUMBER(24) '; exception when others then dbms_output.put_line('DUPCOL: DRUG_REQ_SUP_STATE_TRANSITION.UPDATE_INSTITUTION NUMBER(24)'); end;
/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER BEGIN: DRUG_REQ_SUP_STATE_TRANSITION
CREATE OR REPLACE TRIGGER ALERT.B_IU_DRS_ST_TRANS_AUDIT
BEFORE INSERT OR UPDATE ON ALERT.DRUG_REQ_SUP_STATE_TRANSITION
FOR EACH ROW
DECLARE
    l_str1 VARCHAR2(32767);
    l_str2 number(24);
BEGIN
  --if we are directly on the database log with oracle user
  l_str1 := nvl(pk_utils.str_token(pk_utils.get_client_id, 1, ';'), user);
  l_str2 := to_number(REPLACE(pk_utils.str_token(pk_utils.get_client_id, 2, ';'), ',', '.'), '999999999999999999999999D999', 'NLS_NUMERIC_CHARACTERS = ''. ''');

  IF inserting
  THEN
      :NEW.create_user        := l_str1;
      :NEW.create_time        := current_timestamp;
      :NEW.create_institution := l_str2;
      --
      :NEW.update_user        := NULL;
      :NEW.update_time        := cast(NULL as timestamp with local time zone);
      :NEW.update_institution := NULL;
  ELSIF updating
  THEN
      :NEW.create_user        := :OLD.create_user;
      :NEW.create_time        := :OLD.create_time;
      :NEW.create_institution := :OLD.create_institution;
      --
      :NEW.update_user        := l_str1;
      :NEW.update_time        := current_timestamp;
      :NEW.update_institution := l_str2;
  END IF;

EXCEPTION
    WHEN OTHERS THEN
        ALERTLOG.PK_ALERTLOG.log_error('B_IU_DRUG_REQ_SUP_STATE_TRANSITION_AUDIT-'||sqlerrm);
END B_IU_DRS_ST_TRANS_AUDIT;

/
-- ***** - ***** - ***** - ***** - ***** -  TRIGGER END: DRUG_REQ_SUP_STATE_TRANSITION
--
-- END CHANGE: Rui Marante



--
-- CHANGED BY: THIAGO BRITO
-- CHANGE DATE: 2009-Aug-17
-- CHANGE REASON: ALERT-39638

DECLARE

    l_vital_sign_read      TABLE_NUMBER;
    l_episode              TABLE_NUMBER;
    l_patient              TABLE_NUMBER;
    l_id_vs_scales_element NUMBER(24);
    l_affected_rows        PLS_INTEGER;
    l_total_rows           PLS_INTEGER;

BEGIN

    l_total_rows := 0;

    dbms_output.enable(100000);

    SELECT vsea.id_vital_sign_read, vsea.id_episode, vsea.id_patient BULK COLLECT
      INTO l_vital_sign_read, l_episode, l_patient
      FROM vital_signs_ea vsea;

    IF (l_vital_sign_read.COUNT > 0)
    THEN
    
        FOR i IN l_vital_sign_read.FIRST .. l_vital_sign_read.LAST
        LOOP
        
            BEGIN
            
                SELECT vsr.id_vs_scales_element
                  INTO l_id_vs_scales_element
                  FROM vital_sign_read vsr
                 WHERE vsr.id_vital_sign_read = l_vital_sign_read(i);
            
                UPDATE vital_signs_ea vsea
                   SET vsea.id_vs_scales_element = l_id_vs_scales_element
                 WHERE vsea.id_vital_sign_read = l_vital_sign_read(i)
                   AND vsea.id_episode = l_episode(i)
                   AND vsea.id_patient = l_patient(i);
            
                l_affected_rows := SQL%ROWCOUNT;
                l_total_rows    := l_total_rows + SQL%ROWCOUNT;
            
                IF (l_affected_rows > 1)
                THEN
                    dbms_output.put_line('ROWS:' || to_char(l_affected_rows));
                END IF;
            
            EXCEPTION
                WHEN OTHERS THEN
                    NULL; -- NO DATA FOUND OR TOO MANY ROWS EXCEPTIONS WAS LAUNCHED
            END;
        
        END LOOP;
    
    END IF;

    dbms_output.put_line('Total number of affected rows: ' || to_char(l_total_rows));

END;
/

-- CHANGE END
--



-- José Brito 21/09/2009 ALERT-44836 Convert type of column EPIS_MTOS_PARAM.REGISTERED_VALUE to NUMBER
UPDATE epis_mtos_param emp
   SET emp.registered_value = (SELECT e.registered_value
                                 FROM epis_mtos_param_20090921 e
                                WHERE e.id_epis_mtos_score = emp.id_epis_mtos_score
                                  AND e.id_mtos_param = emp.id_mtos_param);
-- END



-- José Brito 21/09/2009 ALERT-44836 Convert type of column EPIS_MTOS_PARAM.REGISTERED_VALUE to NUMBER
UPDATE epis_mtos_param emp
   SET emp.registered_value = (SELECT to_number(e.registered_value)
                                 FROM epis_mtos_param_20090921 e
                                WHERE e.id_epis_mtos_score = emp.id_epis_mtos_score
                                  AND e.id_mtos_param = emp.id_mtos_param);
-- END



-- José Brito 21/09/2009 ALERT-44836 Convert type of column EPIS_MTOS_PARAM.REGISTERED_VALUE to NUMBER
UPDATE epis_mtos_param emp
   SET emp.registered_value = (SELECT to_number(e.registered_value, '9999999999999D9999', 'nls_numeric_characters='',.''')
                                 FROM epis_mtos_param_20090921 e
                                WHERE e.id_epis_mtos_score = emp.id_epis_mtos_score
                                  AND e.id_mtos_param = emp.id_mtos_param);
-- END


-- CHANGED BY: João Ribeiro
-- CHANGE DATE: 2009-Set-26
-- CHANGE REASON: ALERT-42498
set serverout on
DECLARE
    i_validate_table BOOLEAN := TRUE;
    i_recreate_table BOOLEAN := TRUE;
BEGIN
    -- Call the function
    IF pk_data_gov_admin.admin_task_tl_medication_ea(i_validate_table         => TRUE,
                                                     i_output_invalid_records => TRUE,
                                                     i_recreate_table         => TRUE,
                                                     i_commit_step            => 1000)
    THEN
        dbms_output.put_line('OK');
    
    ELSE
        dbms_output.put_line('KO');
    END IF;
END;
--CHANE END: João Ribeiro


-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 29/09/2009 16:22
-- CHANGE REASON: [ALERT-47078] Consulta de Pré-Operatório
ALTER TABLE SCHEDULE_SR ADD (CONSTRAINT
 SCHED_SR_CAN_REA_FK FOREIGN KEY 
  (ID_SR_CANCEL_REASON) REFERENCES CANCEL_REASON
  (ID_CANCEL_REASON));

ALTER TABLE SR_EPIS_INTERV ADD (CONSTRAINT
 SEV_SR_CAN_REA_FK FOREIGN KEY 
  (ID_SR_CANCEL_REASON) REFERENCES CANCEL_REASON
  (ID_CANCEL_REASON));
-- CHANGE END: Gustavo Serrano

-- CHANGED BY: Rui Marante
-- CHANGE DATE: 30/09/2009
-- CHANGE REASON: ALERT-47242
drop table pharm_drug_package;
-- CHANGE END: Rui Marante



-- CHANGED BY: Ana Matos
-- CHANGED DATE: 2009-SET-30
-- CHANGED REASON: ALERT-47325

CREATE OR REPLACE TYPE "T_COLL_EPISACTIVEITECH" AS TABLE OF t_rec_episactiveitech;
CREATE OR REPLACE TYPE "T_COLL_EPISINACTECH" AS TABLE OF t_rec_episinactech;

-- CHANGE END: Ana Matos




-- CHANGED BY: RicardoNunoAlmeida
-- CHANGE DATE: 16/10/2009 16:19
-- CHANGE REASON: [ALERT-50125] 
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_all_task_tl_tables';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_all_task_tl_tables(i_patient                => NULL,
                                                      i_episode                => NULL,
                                                      i_schedule               => NULL,
                                                      i_external_request       => NULL,
                                                      i_institution            => NULL,
                                                      i_start_dt               => NULL,
                                                      i_end_dt                 => NULL,
                                                      i_validate_table         => FALSE,
                                                      i_output_invalid_records => TRUE,
                                                      i_recreate_table         => TRUE,
                                                      i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END: RicardoNunoAlmeida

-- CHANGED BY: RicardoNunoAlmeida
-- CHANGE DATE: 19/10/2009 14:54
-- CHANGE REASON: [ALERT-47832] 
DECLARE 
 l_rows table_varchar := table_varchar();
 l_rows_ba table_varchar := table_varchar();
 l_err t_error_out;
 l_id_bed bed.id_bed%TYPE;
  CURSOR c_old_ab IS
         SELECT ab.id_episode, ab.id_professional, ab.id_bed, ab.desc_bed, ab.notes, ab.id_room,ab.dt_creation_tstz, ep.id_patient, en.id_epis_nch
         FROM allocation_bed ab
         INNER JOIN episode ep ON ep.id_episode = ab.id_episode
         LEFT JOIN epis_nch en ON en.id_episode = ep.id_episode;
BEGIN
  

         
  FOR l_ab IN  c_old_ab
  LOOP 
  
      IF l_ab.id_bed is not null THEN
                        
                  ts_bmng_allocation_bed.ins(id_bmng_allocation_bed_in => ts_bmng_allocation_bed.next_key,
                                                                     id_episode_in => l_ab.id_episode,
                                                                     id_patient_in => l_ab.id_patient,
                                                                     id_bed_in => l_ab.id_bed,
                                                                     allocation_notes_in => l_ab.notes,
                                                                     id_room_in => l_ab.id_room,
                                                                     id_prof_creation_in => l_ab.id_professional,
                                                                     dt_creation_in => l_ab.dt_creation_tstz,
                                                                     id_prof_release_in => null,
                                                                     dt_release_in => null,
                                                                     flg_outdated_in => pk_alert_constant.g_no,
                                                                     id_epis_nch_in => l_ab.id_epis_nch,
                                                                     rows_out => l_rows_ba);
      ELSE 
                 
               l_id_bed :=   ts_bed.next_key;
                ts_bed.ins(id_bed_in => l_id_bed,
                                     code_bed_in => 'BED.CODE_BED.'|| l_id_bed,
                                     id_room_in => l_ab.id_room,
                                     flg_type_in =>   pk_bmng_constant.g_bmng_bed_flg_type_t,
                                     flg_status_in => pk_bmng_constant.g_bmng_bed_flg_status_v,
                                     desc_bed_in => l_ab.desc_bed,
                                     notes_in => l_ab.notes,
                                     rank_in => 0,
                                     flg_available_in => pk_alert_constant.g_no,
                                     rows_out => l_rows);
               
                ts_bmng_allocation_bed.ins(id_bmng_allocation_bed_in => ts_bmng_allocation_bed.next_key,
                                                                     id_episode_in => l_ab.id_episode,
                                                                     id_patient_in => l_ab.id_patient,
                                                                     id_bed_in => l_id_bed,
                                                                     allocation_notes_in => l_ab.notes,
                                                                     id_room_in => l_ab.id_room,
                                                                     id_prof_creation_in => l_ab.id_professional,
                                                                     dt_creation_in => l_ab.dt_creation_tstz,
                                                                     id_prof_release_in => null,
                                                                     dt_release_in => null,
                                                                     flg_outdated_in => pk_alert_constant.g_yes,
                                                                     id_epis_nch_in => l_ab.id_epis_nch,
                                                                     rows_out => l_rows_ba);
                                                                     
                                                                     
                                                                     
                  
      END IF;        
                                        
  END LOOP;
  
    t_data_gov_mnt.process_insert(1, profissional(142,19,11), 'BED', l_rows, l_err);
    t_data_gov_mnt.process_insert(1, profissional(142,19,11), 'BMNG_ALLOCATION_BED', l_rows_ba, l_err);
                              
END;
/

ALTER TABLE allocation_bed RENAME TO allocation_bed_bck;
-- CHANGE END: RicardoNunoAlmeida

-- CHANGED BY: Elisabete Bugalho
-- CHANGE DATE: 27-10-2009
-- CHANGE REASON: Case Manager
begin execute immediate 'create table opinion' || to_char(sysdate,'yyyymmdd') || ' as select * from opinion'; end;

update opinion o set o.id_patient = (select e.id_patient from episode e where e.id_episode = o.id_episode);

alter table opinion modify (id_patient not null);
--CHANGE END

-- JSILVA 28-10-2009
DROP INDEX TRANSLATION_LIDX;

CREATE INDEX TRANSLATION_LIDX ON translation(desc_translation) 
indextype is lucene.LuceneIndex
parameters ('IncludeMasterColumn:false;FormatCols:id_language(NOT_ANALYZED);ExtraCols:translate(upper(desc_translation), ''ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÇÄËÏÖÜÑ'', ''AEIOUAEIOUAEIOUAOCAEIOUN'') "desc_tr",to_char(id_language) "id_language";LobStorageParameters:PCTVERSION 10 ENABLE STORAGE IN ROW CACHE READS NOLOGGING;Analyzer:org.apache.lucene.analysis.standard.StandardAnalyzer;LogLevel:INFO;MergeFactor:500;AutoTuneMemory:true;WhereCondition: code_translation like ''ALERT_DIAGNOSIS.CODE_ALERT_DIAGNOSIS.%'' OR code_translation like ''DIAGNOSIS.CODE_DIAGNOSIS.%'';');

alter index TRANSLATION_LIDX rebuild parameters('MergeFactor:2;MaxBufferedDocs:100;');
-- END


-- José Brito ALERT-52603 28/10/2009
CREATE OR REPLACE TYPE t_coll_patcriteriaactiveclin AS TABLE OF t_rec_patcriteriaactiveclin
/



-- CHANGED BY: RicardoNunoAlmeida
-- CHANGE DATE: 05/11/2009 16:46
-- CHANGE REASON: [ALERT-54305] 
DECLARE 

 l_err t_error_out;
 l_prof profissional := profissional(142,19,11);
 l_epis episode.id_episode%TYPE;
 l_nch bmng_bed_ea.flg_allocation_nch%TYPE;
 l_id_bed bed.id_bed%TYPE;
 l_bmb bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
 l_ds discharge_schedule.id_discharge_schedule%TYPE;
 
 
 
  CURSOR c_old_ab IS
         SELECT ab.id_episode, ab.id_professional, ab.id_bed, ab.desc_bed, ab.notes, ab.id_room,
         pk_date_utils.to_char_timezone(1, ab.dt_creation_tstz, 'yyyymmddhh24miss')  dt_creation_tstz, 
         ep.id_patient, en.id_epis_nch,
                en.nch_value,
                nvl(dcs.id_department, r.id_department)  id_department,
                pk_date_utils.to_char_timezone(1, nvl(ep.dt_end_tstz, current_timestamp), 'yyyymmddhh24miss') dt_end_tstz, 
                pk_date_utils.to_char_timezone(1, ds.dt_discharge_schedule  , 'yyyymmddhh24miss')   dt_discharge_schedule        ,
b.flg_type,
ds.id_discharge_schedule 
         FROM allocation_bed ab
         INNER JOIN episode ep ON ep.id_episode = ab.id_episode
         INNER JOIN epis_info ei ON ei.id_episode = ep.id_episode
         INNER JOIN room r ON r.id_room = ei.id_room
 LEFT JOIN bed b ON ab.id_bed = b.id_bed
         LEFT JOIN dep_clin_serv dcs ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
         LEFT JOIN discharge_schedule ds ON ds.id_episode = ep.id_episode
                                         AND ds.flg_status = 'A'
         LEFT JOIN epis_nch en ON en.id_episode = ep.id_episode
                            AND en.flg_status = 'A'
         ORDER BY ab.id_episode, ab.dt_creation_tstz ASC;
BEGIN
  

         
  FOR l_ab IN  c_old_ab
  LOOP 

-- ID_BED means an active bed allocation (either permanent or temporary).
      IF l_ab.id_bed is not null THEN      
         
               IF l_ab.nch_value IS NULL THEN
                  l_nch := NULL;
                ELSE
                  l_nch := 'D';
                END IF; 
                                    
               IF NOT pk_bmng.set_bed_management(i_lang => 1,
                                                 i_prof => l_prof,
                                                 i_id_bmng_action => table_number(NULL),
                                                 i_id_department => table_number(l_ab.id_department),
                                                 i_id_room => table_number(l_ab.id_room),
                                                 i_id_bed => table_number(l_ab.id_bed),
                                                 i_id_bmng_reason =>    table_number(NULL) ,
                                                 i_id_bmng_allocation_bed => table_number(NULL),
                                                 i_flg_target_action => 'B',
                                                 i_flg_status => 'A',
                                                 i_nch_capacity => table_number(NULL),
                                                 i_action_notes => table_varchar(l_ab.notes),
                                                 i_dt_begin_action => table_varchar(l_ab.dt_creation_tstz),
                                                 i_dt_end_action => table_varchar(l_ab.dt_end_tstz),
                                                 i_id_episode => table_number(l_ab.id_episode),
                                                 i_id_patient => table_number(l_ab.id_patient),
                                                 i_nch_hours => l_ab.nch_value,
                                                 i_flg_allocation_nch => l_nch,
                                                 i_desc_bed => NULL,
                                                 i_id_bed_type => table_number(NULL),
                                                 i_dt_discharge_schedule => l_ab.dt_discharge_schedule,
                                                 i_id_bed_dep_clin_serv => NULL,
                                                 i_flg_origin_action_ux => l_ab.flg_type,
                                                 o_id_bmng_allocation_bed => l_bmb,
                                                 o_error => l_err) THEN
                       dbms_output.put_line(l_err.err_desc);   
                       dbms_output.put_line(l_err.ora_sqlerrm);   
                       dbms_output.put_line(l_err.ora_sqlcode);   
                       return;
                  END IF;
                                                 
                                                 
                                                      
      -- No ID_BED means a past temporary bed allocation.
      ELSE 
                 
                IF l_ab.nch_value IS NULL THEN
                  l_nch := NULL;
                ELSE
                  l_nch := 'D';
                END IF; 
                                        
                
                  IF NOT pk_bmng.set_bed_management(i_lang => 1,
                                                 i_prof => l_prof,
                                                 i_id_bmng_action => table_number(NULL),
                                                 i_id_department => table_number(l_ab.id_department),
                                                 i_id_room => table_number(l_ab.id_room),
                                                 i_id_bed => table_number(NULL),
                                                 i_id_bmng_reason =>    table_number(NULL) ,
                                                 i_id_bmng_allocation_bed => table_number(NULL),
                                                 i_flg_target_action => 'B',
                                                 i_flg_status => 'A',
                                                 i_nch_capacity => table_number(NULL),
                                                 i_action_notes => table_varchar(l_ab.notes),
                                                 i_dt_begin_action => table_varchar(l_ab.dt_creation_tstz),
                                                 i_dt_end_action => table_varchar(l_ab.dt_end_tstz),
                                                 i_id_episode => table_number(l_ab.id_episode),
                                                 i_id_patient => table_number(l_ab.id_patient),
                                                 i_nch_hours => l_ab.nch_value,
                                                 i_flg_allocation_nch => l_nch,
                                                 i_desc_bed => l_ab.desc_bed,
                                                 i_id_bed_type => table_number(NULL),
                                                 i_dt_discharge_schedule => l_ab.dt_discharge_schedule,
                                                 i_id_bed_dep_clin_serv => NULL,
                                                 i_flg_origin_action_ux => pk_bmng_constant.g_bmng_flg_origin_ux_t,
                                                 o_id_bmng_allocation_bed => l_bmb,
                                                 o_error => l_err) THEN
                         dbms_output.put_line(l_err.err_desc);   
                       dbms_output.put_line(l_err.ora_sqlerrm);   
                       dbms_output.put_line(l_err.ora_sqlcode);   
                       return;
                  END IF;                                                   
                                                                     
                                                                     
                  
      END IF;       



--Verification: if a different ID_EPISODE is present, must process previous discharge (if needed)
IF (l_ab.id_episode  != l_epis)  AND (l_epis is not null) THEN

   IF (l_id_bed is NULL) OR (l_ds is not NULL) THEN
    --No Bed means last record is a past temporary allocation
IF NOT pk_bmng.set_bmng_discharge(i_lang => 1,i_prof => l_prof,i_epis => l_epis,o_error => l_err) THEN
   dbms_output.put_line(l_err.err_desc);   
   dbms_output.put_line(l_err.ora_sqlerrm);   
   dbms_output.put_line(l_err.ora_sqlcode);   
   return;
END IF;

 END IF;
      
   l_epis := l_ab.id_episode;
  ELSIF l_epis is  null THEN
   l_epis := l_ab.id_episode;   
END IF;

    -- Save ID BED
      l_id_bed :=  l_ab.id_bed;
l_ds := l_ab.id_discharge_schedule;
                                        
  END LOOP;
  
--Last item
  IF (l_id_bed is NULL) OR (l_ds is not NULL) THEN
IF NOT pk_bmng.set_bmng_discharge(i_lang => 1,i_prof => l_prof,i_epis => l_epis,o_error => l_err) THEN
 dbms_output.put_line(l_err.err_desc);   
 dbms_output.put_line(l_err.ora_sqlerrm);   
 dbms_output.put_line(l_err.ora_sqlcode);   
 return;
END IF;

 END IF;


 ALTER TABLE allocation_bed RENAME TO allocation_bed_bck;
 
END;
/
-- CHANGE END: RicardoNunoAlmeida

-- CHANGED BY: Luís Maia
-- CHANGE DATE: 07/11/2009 12:10
-- CHANGE REASON: [ALERT-55099] Populate task_timeline_ea table
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_all_task_tl_tables';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_all_task_tl_tables(i_patient                => NULL,
                                                      i_episode                => NULL,
                                                      i_schedule               => NULL,
                                                      i_external_request       => NULL,
                                                      i_institution            => NULL,
                                                      i_start_dt               => NULL,
                                                      i_end_dt                 => NULL,
                                                      i_validate_table         => FALSE,
                                                      i_output_invalid_records => TRUE,
                                                      i_recreate_table         => TRUE,
                                                      i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END: Luís Maia


-- CHANGED BY: José Silva
-- CHANGE DATE: 07/11/2009 12:50
-- CHANGE REASON: [ALERT-55202] Populate tracking_board table
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_all_task_tl_tables';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_tracking_board_ea(i_patient                => NULL,
                                                     i_episode                => NULL,
                                                     i_schedule               => NULL,
                                                     i_external_request       => NULL,
                                                     i_institution            => NULL,
                                                     i_start_dt               => NULL,
                                                     i_end_dt                 => NULL,
                                                     i_validate_table         => FALSE,
                                                     i_output_invalid_records => TRUE,
                                                     i_recreate_table         => TRUE,
                                                     i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/

DECLARE g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_all_task_tl_tables';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_grids_ea(i_patient                => NULL,
                                            i_episode                => NULL,
                                            i_schedule               => NULL,
                                            i_external_request       => NULL,
                                            i_institution            => NULL,
                                            i_start_dt               => NULL,
                                            i_end_dt                 => NULL,
                                            i_validate_table         => FALSE,
                                            i_recreate_table         => TRUE,
                                            i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END: José Silva






-- CHANGED BY: RicardoNunoAlmeida
-- CHANGE DATE: 10/11/2009 09:35
-- CHANGE REASON: [ALERT-54305] 
DECLARE 

 l_err t_error_out;
 l_prof profissional := profissional(  pk_sysconfig.get_config('ID_PROF_ALERT', profissional(0, 0, 0)), 0, 0);
 l_epis episode.id_episode%TYPE;
 l_nch bmng_bed_ea.flg_allocation_nch%TYPE;
 l_id_bed bed.id_bed%TYPE;
 l_bmb bmng_allocation_bed.id_bmng_allocation_bed%TYPE;
 l_ds discharge_schedule.id_discharge_schedule%TYPE;
 l_pid professional.id_professional%TYPE;
 l_inst institution.id_institution%TYPE;
 l_ni table_number := table_number();
 l_rows table_varchar;
 
 
  CURSOR c_old_ab IS
         SELECT ab.id_allocation_bed, ab.id_episode, ab.id_professional, ab.id_bed, ab.desc_bed, ab.notes, ab.id_room,
         pk_date_utils.to_char_timezone(1, nvl(ab.dt_creation_tstz, current_timestamp), 'yyyymmddhh24miss')  dt_creation_tstz, 
         ep.id_patient, en.id_epis_nch,
                en.nch_value,
                nvl(dcs.id_department, r.id_department)  id_department,
                pk_date_utils.to_char_timezone(1, nvl(ep.dt_end_tstz, current_timestamp), 'yyyymmddhh24miss') dt_end_tstz, 
                pk_date_utils.to_char_timezone(1, ds.dt_discharge_schedule  , 'yyyymmddhh24miss')   dt_discharge_schedule        ,
                b.flg_type,
                ds.id_discharge_schedule ,
                ab.id_professional create_user,
                d.id_institution create_institution,
ei.id_bed current_allocation,
b.flg_status bed_status
         FROM allocation_bed_bck ab
         INNER JOIN episode ep ON ep.id_episode = ab.id_episode
         INNER JOIN epis_info ei ON ei.id_episode = ep.id_episode
         INNER JOIN room r ON r.id_room = ei.id_room         
         INNER JOIN department d ON d.id_department = r.id_department
         LEFT JOIN bed b ON ab.id_bed = b.id_bed
         LEFT JOIN dep_clin_serv dcs ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
         LEFT JOIN discharge_schedule ds ON ds.id_episode = ep.id_episode
                                         AND ds.flg_status = 'A'
         LEFT JOIN epis_nch en ON en.id_episode = ep.id_episode
                            AND en.flg_status = 'A'
 
         ORDER BY ab.id_episode, ab.dt_creation_tstz ASC;
BEGIN
  
   
         
  FOR l_ab IN  c_old_ab
  LOOP 
      l_bmb := NULL;
      --User
      IF l_ab.create_user is null THEN
         IF l_prof.ID is null THEN
            l_pid := -1;
            l_inst := -1;
          ELSE 
            l_pid := l_prof.ID;
            l_inst := -1;
         END IF;
      ELSE
         l_pid := l_ab.create_user;
         l_inst := l_ab.create_institution;
      END IF;

      -- ID_BED means an active bed allocation (either permanent or temporary).
      IF l_ab.id_bed is not null THEN      
         
               IF l_ab.nch_value IS NULL THEN
                  l_nch := NULL;
                ELSE
                  l_nch := 'D';
                END IF; 
                        
IF l_ab.bed_status != 'V' THEN
--Set Bed Status = V; or else the allocation will never work. 
ts_bed.upd(id_bed_in => l_ab.id_bed,
                              flg_status_in => 'V',
flg_status_nin =>  FALSE,
rows_out => l_rows);
t_data_gov_mnt.process_update(1, profissional( l_pid, l_inst, 11), 'BED', l_rows, l_err);
END IF;
            
               IF NOT pk_bmng.set_bed_management(i_lang => 1,
                                                 i_prof => profissional( l_pid, l_inst, 11),
                                                 i_id_bmng_action => table_number(NULL),
                                                 i_id_department => table_number(l_ab.id_department),
                                                 i_id_room => table_number(l_ab.id_room),
                                                 i_id_bed => table_number(l_ab.id_bed),
                                                 i_id_bmng_reason =>    table_number(NULL) ,
                                                 i_id_bmng_allocation_bed => table_number(NULL),
                                                 i_flg_target_action => 'B',
                                                 i_flg_status => 'A',
                                                 i_nch_capacity => table_number(NULL),
                                                 i_action_notes => table_varchar(l_ab.notes),
                                                 i_dt_begin_action => table_varchar(l_ab.dt_creation_tstz),
                                                 i_dt_end_action => table_varchar(l_ab.dt_end_tstz),
                                                 i_id_episode => table_number(l_ab.id_episode),
                                                 i_id_patient => table_number(l_ab.id_patient),
                                                 i_nch_hours => l_ab.nch_value,
                                                 i_flg_allocation_nch => l_nch,
                                                 i_desc_bed => NULL,
                                                 i_id_bed_type => table_number(NULL),
                                                 i_dt_discharge_schedule => l_ab.dt_discharge_schedule,
                                                 i_id_bed_dep_clin_serv => NULL,
                                                 i_flg_origin_action_ux => l_ab.flg_type,
                                                 o_id_bmng_allocation_bed => l_bmb,
                                                 o_error => l_err) THEN
                      dbms_output.put_line('>1EPIS: '|| l_ab.id_episode);                              
                       dbms_output.put_line(l_err.err_desc);   
                       dbms_output.put_line(l_err.ora_sqlerrm);   
                       dbms_output.put_line(l_err.ora_sqlcode);   
                       return;
                  END IF;
                                                 
                                                 
                                                      
      -- No ID_BED means a past temporary bed allocation.
      ELSE 
                 
                IF l_ab.nch_value IS NULL THEN
                  l_nch := NULL;
                ELSE
                  l_nch := 'D';
                END IF; 
                                        
                
                  IF NOT pk_bmng.set_bed_management(i_lang => 1,
                                                 i_prof => profissional( l_pid, l_inst, 11), 
                                                 i_id_bmng_action => table_number(NULL),
                                                 i_id_department => table_number(l_ab.id_department),
                                                 i_id_room => table_number(l_ab.id_room),
                                                 i_id_bed => table_number(NULL),
                                                 i_id_bmng_reason =>    table_number(NULL) ,
                                                 i_id_bmng_allocation_bed => table_number(NULL),
                                                 i_flg_target_action => 'B',
                                                 i_flg_status => 'A',
                                                 i_nch_capacity => table_number(NULL),
                                                 i_action_notes => table_varchar(l_ab.notes),
                                                 i_dt_begin_action => table_varchar(l_ab.dt_creation_tstz),
                                                 i_dt_end_action => table_varchar(l_ab.dt_end_tstz),
                                                 i_id_episode => table_number(l_ab.id_episode),
                                                 i_id_patient => table_number(l_ab.id_patient),
                                                 i_nch_hours => l_ab.nch_value,
                                                 i_flg_allocation_nch => l_nch,
                                                 i_desc_bed => l_ab.desc_bed,
                                                 i_id_bed_type => table_number(NULL),
                                                 i_dt_discharge_schedule => l_ab.dt_discharge_schedule,
                                                 i_id_bed_dep_clin_serv => NULL,
                                                 i_flg_origin_action_ux => pk_bmng_constant.g_bmng_flg_origin_ux_t,
                                                 o_id_bmng_allocation_bed => l_bmb,
                                                 o_error => l_err) THEN
                        dbms_output.put_line('>2EPIS: '|| l_ab.id_episode);                              
                       dbms_output.put_line(l_err.err_desc);   
                       dbms_output.put_line(l_err.ora_sqlerrm);   
                       dbms_output.put_line(l_err.ora_sqlcode);   
                       return;
                  END IF;                                                   
                                                                     
                                                                     
                  
      END IF;       
      
      
      
      --Verification: if a different ID_EPISODE is present, must process previous discharge (if needed)
      IF (l_ab.id_episode  != l_epis)  AND (l_epis is not null) THEN
        
         IF (l_id_bed is NULL) OR (l_ds is not NULL) THEN
            --No Bed means last record is a past temporary allocation
            IF NOT pk_bmng.set_bmng_discharge(i_lang => 1, 
                                                           i_prof => profissional( l_pid, l_inst, 11), 
                                                           i_epis => l_epis,
                                                           o_error => l_err) THEN
               dbms_output.put_line(l_err.err_desc);   
               dbms_output.put_line(l_err.ora_sqlerrm);   
               dbms_output.put_line(l_err.ora_sqlcode);   
               return;
            END IF;
            
         END IF;
                
         l_epis := l_ab.id_episode;
      ELSIF l_epis is  null THEN
         l_epis := l_ab.id_episode;   
      END IF;
  
      -- Save ID BED
      l_id_bed :=  l_ab.id_bed;
      l_ds := l_ab.id_discharge_schedule;
          
IF l_bmb IS NULL THEN
   l_ni.extend;
   l_ni(l_ni.count) := l_ab.id_allocation_bed;
 dbms_output.put_line('ID NOT INSERTED: ' ||  l_ab.id_allocation_bed); 
END IF;
                              
  END LOOP;
  
  --Last item
  IF (l_id_bed is NULL) OR (l_ds is not NULL) THEN
    IF NOT pk_bmng.set_bmng_discharge(i_lang => 1,i_prof => profissional( l_pid, l_inst, 11), i_epis => l_epis,o_error => l_err) THEN
       dbms_output.put_line(l_err.err_desc);   
       dbms_output.put_line(l_err.ora_sqlerrm);   
       dbms_output.put_line(l_err.ora_sqlcode);   
       return;
    END IF;
            
 END IF;


END;
-- CHANGE END: RicardoNunoAlmeida

-- CHANGED BY: RicardoNunoAlmeida
-- CHANGE DATE: 11/11/2009 10:47
-- CHANGE REASON: [ALERT-56043] 
DECLARE
   l_tabs table_varchar := table_varchar('SCHEDULE_INP_BED', 'SCHEDULE_BED', 'SCH_ALLOCATION', 'SCH_BED_SLOT', 'SCH_ROOM_STATS');
 l_t VARCHAR2(20);
BEGIN
    FOR i IN 1 .. l_tabs.COUNT
LOOP
    l_t := l_tabs(i);

EXECUTE IMMEDIATE '
alter table 
 ' || l_t || '
add 
( 
 create_time_temp    TIMESTAMP(6) WITH LOCAL TIME ZONE,
 update_time_temp    TIMESTAMP(6) WITH LOCAL TIME ZONE
)';

EXECUTE IMMEDIATE '
UPDATE ' || l_t || ' 
SET create_time_temp = create_time,
update_time_temp = update_time';

EXECUTE IMMEDIATE '
alter table
 ' || l_t || '
drop column
 create_time'; 

EXECUTE IMMEDIATE '
alter table
 ' || l_t || '
drop column
 update_time';

EXECUTE IMMEDIATE '
alter table 
 ' || l_t || '
rename column create_time_temp TO CREATE_TIME';

EXECUTE IMMEDIATE '
alter table 
 ' || l_t || '
rename column update_time_temp TO UPDATE_TIME';
END LOOP;
END;
/
-- CHANGE END: RicardoNunoAlmeida

-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 13/11/2009
-- CHANGE REASON: [ALERT-55628] Conflits between Awareness and Image_req tables
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_all_task_tl_tables';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_awareness(i_patient          => NULL,
                                             i_episode          => NULL,
                                             i_schedule         => NULL,
                                             i_external_request => NULL,
                                             i_institution      => NULL,
                                             i_start_dt         => NULL,
                                             i_end_dt           => NULL,
                                             i_validate_table   => FALSE,
                                             i_recreate_table   => TRUE,
                                             i_commit_step      => 1)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END


-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 04/12/2009 15:00
-- CHANGE REASON: [ALERT-55090] 
alter table sr_posit drop column ID_SR_PARENT;
alter table sr_posit drop column FLG_EXCLUSIVE;
alter table sr_posit drop column ID_INSTITUTION;
alter table sr_posit drop column ADW_LAST_UPDATE;
-- CHANGE END: Gustavo Serrano

-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 09/12/2009 
-- CHANGE REASON: [ALERT-61585] 
drop trigger ALERT.b_iu_sr_posit;
--CHANGE END: Filipe Silva


-- CHANGED BY: Pedro Teixeira
-- CHANGE DATE: 10/12/2009
-- CHANGE REASON: ALERT-58995
update ehr_access_context eac set eac.flg_context = 'A' where eac.flg_context is null;
update ehr_access_context eac set eac.flg_available = 'Y' where eac.flg_available is null;
ALTER TABLE ehr_access_context MODIFY flg_context not null;
ALTER TABLE ehr_access_context MODIFY flg_available not null;
--CHANGE END



--
-- CHANGED BY: THIAGO BRITO
-- CHANGE DATE: 2009-Dez-17
-- CHANGE REASON: ALERT-59355

CREATE TABLE phy_discharge_notes_20091217 AS (
    SELECT *
      FROM phy_discharge_notes);

ALTER TABLE phy_discharge_notes add notes_bkp VARCHAR2(4000);

UPDATE phy_discharge_notes pdn
   SET pdn.notes_bkp = pdn.notes;

UPDATE phy_discharge_notes pdn
   SET pdn.notes = NULL;

ALTER TABLE phy_discharge_notes drop column notes;

ALTER TABLE phy_discharge_notes add notes CLOB;

UPDATE phy_discharge_notes pdn
   SET pdn.notes = pdn.notes_bkp;

ALTER TABLE phy_discharge_notes drop column notes_bkp;

-- CHANGE END: THIAGO BRITO
--

-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 2009-DEC-21
-- CHANGE REASON: ALERT-58475 - fix ICPC2 content + to update ICPC2 diagnoses parents + update ICPC2 diagnoses translations + drop diagnoses temporary tables
-- << fix ICPC2 content (diagnoses and synonyms) >>
MERGE INTO diagnosis d
USING diagnosis_tmp_20091221 diag_temp
ON (d.id_diagnosis = diag_temp.id_diagnosis and d.flg_type = diag_temp.flg_type and d.code_icd = diag_temp.code_icd)
WHEN MATCHED THEN
    UPDATE
       SET d.flg_select     = diag_temp.flg_select,
           d.flg_available  = diag_temp.flg_available,
           d.flg_other      = diag_temp.flg_other
WHEN NOT MATCHED THEN
    INSERT
        (d.id_diagnosis,
         d.code_diagnosis,
         d.code_icd,
         d.flg_select,
         d.flg_available,
         d.flg_type,
         d.flg_other,
         d.gender,
         d.age_min,
         d.age_max,
         d.id_content)
    VALUES
        (diag_temp.id_diagnosis,
         diag_temp.code_diagnosis,
         diag_temp.code_icd,
         diag_temp.flg_select,
         diag_temp.flg_available,
         diag_temp.flg_type,
         diag_temp.flg_other,
         diag_temp.gender,
         diag_temp.age_min,
         diag_temp.age_max,
         diag_temp.id_content);
		 
MERGE INTO alert_diagnosis ad
USING alert_diagnosis_tmp_20091221 alert_diag_temp
ON (ad.id_alert_diagnosis = alert_diag_temp.id_alert_diagnosis and ad.id_diagnosis = alert_diag_temp.id_diagnosis)
WHEN MATCHED THEN
    UPDATE
       SET ad.flg_available = alert_diag_temp.flg_available
WHEN NOT MATCHED THEN
    INSERT
        (ad.id_alert_diagnosis,
         ad.id_diagnosis,
         ad.code_alert_diagnosis,
         ad.flg_type,
         ad.flg_icd9,
         ad.flg_available,
         ad.gender,
         ad.age_min,
         ad.age_max,
         ad.id_content)
    VALUES
        (alert_diag_temp.id_alert_diagnosis,
         alert_diag_temp.id_diagnosis,
         alert_diag_temp.code_alert_diagnosis,
         alert_diag_temp.flg_type,
         alert_diag_temp.flg_icd9,
         alert_diag_temp.flg_available,
         alert_diag_temp.gender,
         alert_diag_temp.age_min,
         alert_diag_temp.age_max,
         alert_diag_temp.id_content);

-- << update ICPC2 diagnoses parents >>

MERGE INTO diagnosis d
USING diagnosis_tmp_20091221 diag_temp
ON (d.id_diagnosis = diag_temp.id_diagnosis and d.flg_type = diag_temp.flg_type and d.code_icd = diag_temp.code_icd)
WHEN MATCHED THEN
    UPDATE
       SET d.id_diagnosis_parent = diag_temp.id_diagnosis_parent;
	   
-- << update ICPC2 diagnoses and synonyms translations >>

DECLARE
    CURSOR c_diag_translations IS
        SELECT diag_temp.code_diagnosis, diag_temp.desc_translation
          FROM diagnosis_tmp_20091221 diag_temp, diagnosis d
		  where diag_temp.id_diagnosis = d.id_diagnosis
		  and diag_temp.flg_type = d.flg_type
		  and diag_temp.code_icd = d.code_icd;

	CURSOR c_alert_diag_translations IS
        SELECT alert_diag_temp.code_alert_diagnosis, alert_diag_temp.desc_translation
          FROM alert_diagnosis_tmp_20091221 alert_diag_temp, alert_diagnosis ad
		  where alert_diag_temp.id_alert_diagnosis = ad.id_alert_diagnosis
		  and alert_diag_temp.id_diagnosis = ad.id_diagnosis;

BEGIN
	-- update diagnoses translations
    FOR vrec IN c_diag_translations
    LOOP
        insert_into_translation(i_lang       => 1,
                                i_code_trans => vrec.code_diagnosis,
                                i_desc_trans => vrec.desc_translation);
    END LOOP;
	
	-- update diagnoses synonyms translations
    FOR vrec IN c_alert_diag_translations
    LOOP
        insert_into_translation(i_lang       => 1,
                                i_code_trans => vrec.code_alert_diagnosis,
                                i_desc_trans => vrec.desc_translation);
    END LOOP;	
END;
/

COMMIT;

-- << drop diagnoses temporary tables >>
DROP TABLE DIAGNOSIS_TMP_20091221;
DROP TABLE ALERT_DIAGNOSIS_TMP_20091221;

-- CHANGE END: Tiago Silva

-- CHANGED BY: José Silva
-- CHANGE DATE: 26/02/2010 10:52
-- CHANGE REASON: [ALERT-77771] TRANCKING_BOARD_EA correction
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_all_task_tl_tables';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_tracking_board_ea(i_patient                => NULL,
                                                     i_episode                => NULL,
                                                     i_schedule               => NULL,
                                                     i_external_request       => NULL,
                                                     i_institution            => NULL,
                                                     i_start_dt               => NULL,
                                                     i_end_dt                 => NULL,
                                                     i_validate_table         => FALSE,
                                                     i_output_invalid_records => TRUE,
                                                     i_recreate_table         => TRUE,
                                                     i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END: José Silva

-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 26/02/2010
-- CHANGE REASON: [ALERT-70302] Possible to specify access to each view
DECLARE
    e_already_not_null EXCEPTION;

    PRAGMA EXCEPTION_INIT(e_already_not_null, -01442); -- alter table modify
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'ALTER TABLE VIEW_OPTION_CONFIG MODIFY (FLG_ACCESS NOT NULL ENABLE)';
    EXCEPTION
        WHEN e_already_not_null THEN
            dbms_output.put_line('aviso :operação já executada anteriormente.');
    END;
END;
/
-- CHANGE END

-- CHANGED BY: José Brito
-- CHANGE DATE: 02/03/2010 10:50
-- CHANGE REASON: [ALERT-77123] ESI Triage
CREATE OR REPLACE TYPE t_coll_episcancelled AS TABLE OF t_rec_episcancelled;
CREATE OR REPLACE TYPE t_coll_patcriteriaactiveadmin AS TABLE OF t_rec_patcriteriaactiveadmin;
CREATE OR REPLACE TYPE t_coll_patcriteriaactiveclin AS TABLE OF t_rec_patcriteriaactiveclin;
CREATE OR REPLACE TYPE t_coll_episactiveitech AS TABLE OF t_rec_episactiveitech;
CREATE OR REPLACE TYPE t_coll_episinactech AS TABLE OF t_rec_episinactech;
-- CHANGE END: José Brito

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 08/03/2010 12:18
-- CHANGE REASON: [ALERT-69475] [EDIS Grids]: VIPs: Introduce the notion of VIP patient
CREATE OR REPLACE TYPE t_coll_episinactive AS TABLE OF t_rec_episinactive;
-- CHANGE END: Alexandre Santos

-- CHANGED BY:  NELSON CANASTRO
-- CHANGE DATE: 23/02/2010 14:27
-- CHANGE REASON: [ALERT-75464] 
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_all_task_tl_tables';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_all_task_tl_tables(i_patient                => NULL,
                                                      i_episode                => NULL,
                                                      i_schedule               => NULL,
                                                      i_external_request       => NULL,
                                                      i_institution            => NULL,
                                                      i_start_dt               => NULL,
                                                      i_end_dt                 => NULL,
                                                      i_validate_table         => FALSE,
                                                      i_output_invalid_records => TRUE,
                                                      i_recreate_table         => TRUE,
                                                      i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END:  NELSON CANASTRO


-- CHANGED BY: RicardoNunoAlmeida
-- CHANGE DATE: 16/03/2010 12:16
-- CHANGE REASON: [ALERT-81159] 
DECLARE
        l_code wtl_checklist.code_desc%TYPE;
       
        PROCEDURE replicate_translation(i_code_msg VARCHAR2, i_code_translation VARCHAR2) IS
BEGIN
          FOR l_cur IN (SELECT sm.id_language, sm.desc_message
              FROM sys_message sm
WHERE sm.code_message = i_code_msg
ORDER BY sm.id_language)
LOOP
--         dbms_output.put_line('insert_into_translation(i_lang => ' || l_cur.id_language || ',i_code_trans => ''' || i_code_translation || ''',i_desc_trans => ''' || l_cur.desc_message || ''' )');
insert_into_translation(i_lang => l_cur.id_language ,i_code_trans => i_code_translation,i_desc_trans => l_cur.desc_message );
END LOOP;
END replicate_translation;



BEGIN
   
    l_code := 'WTL_CHECKLIST.CODE_DESC.1';
    replicate_translation('ADM_REQUEST_T001', l_code);

    l_code := 'WTL_CHECKLIST.CODE_DESC.2';
    replicate_translation('ADM_REQUEST_T008', l_code);
 
    l_code := 'WTL_CHECKLIST.CODE_DESC.3';
    replicate_translation('ADM_REQUEST_T009', l_code);

    l_code := 'WTL_CHECKLIST.CODE_DESC.4';
    replicate_translation('ADM_REQUEST_T029', l_code);

    l_code := 'WTL_CHECKLIST.CODE_DESC.5';
    replicate_translation('ADM_REQUEST_T041', l_code);
  
    l_code := 'WTL_CHECKLIST.CODE_DESC.6';
    replicate_translation('SURGERY_REQUEST_T010', l_code);

    l_code := 'WTL_CHECKLIST.CODE_DESC.7';
    replicate_translation('SURGERY_REQUEST_T027', l_code);

l_code := 'WTL_CHECKLIST.CODE_DESC.8';
replicate_translation('SURGERY_REQUEST_T033', l_code);

    l_code := 'WTL_CHECKLIST.CODE_DESC.9';
    replicate_translation('SURGERY_REQUEST_T032', l_code);

    l_code := 'WTL_CHECKLIST.CODE_DESC.10';
    replicate_translation('SURG_ADM_REQUEST_T002', l_code);

    l_code := 'WTL_CHECKLIST.CODE_DESC.11';
    replicate_translation('SURG_ADM_REQUEST_T004', l_code);

    l_code := 'WTL_CHECKLIST.CODE_DESC.12';
replicate_translation('SURG_ADM_REQUEST_T003', l_code);

    l_code := 'WTL_CHECKLIST.CODE_DESC.13';
    replicate_translation('SCALES_T022', l_code);
END;
-- CHANGE END: RicardoNunoAlmeida

-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 12/02/2010
-- CHANGE REASON: [ALERT-74596]  Pk corrections
/*************EXECUTAR NUMA JANELA/SESSÃO DIFERENTE****************/
BEGIN
execute immediate 'ALTER TABLE profile_templ_access DISABLE CONSTRAINT PTA_SBPP_FK';
execute immediate 'ALTER TABLE profile_templ_access DISABLE CONSTRAINT PTA_SSST_FK';
execute immediate 'ALTER TABLE sys_shortcut DISABLE CONSTRAINT SSST_SBPP_FK';
end;
/

UPDATE profile_templ_access SET id_profile_templ_access = 102810150 WHERE id_profile_templ_access = 2500070000000121;
UPDATE profile_templ_access SET id_profile_templ_access = 102810151 WHERE id_profile_templ_access = 2500070000000122;
UPDATE profile_templ_access SET id_profile_templ_access = 102810152 WHERE id_profile_templ_access = 2500070000000123;
UPDATE profile_templ_access SET id_profile_templ_access = 102810153 WHERE id_profile_templ_access = 2500070000000124;
UPDATE profile_templ_access SET id_profile_templ_access = 102810154 WHERE id_profile_templ_access = 2500070000000125;
UPDATE sys_shortcut SET id_shortcut_pk = 168254 WHERE id_shortcut_pk = 2500070000000024;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102810155;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102808508;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102810150;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102810160;
UPDATE sys_shortcut SET id_shortcut_pk = 168255 WHERE id_shortcut_pk = 2500070000000025;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 165903;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 165904;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 102779173;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 102810131;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 102810130;
UPDATE sys_shortcut SET id_shortcut_pk = 168256 WHERE id_shortcut_pk = 2500070000000027;
UPDATE profile_templ_access SET id_shortcut_pk = 168256 WHERE id_profile_templ_access = 48111;

/*************EXECUTAR NUMA JANELA/SESSÃO DIFERENTE****************/
BEGIN
execute immediate 'ALTER TABLE sys_shortcut ENABLE CONSTRAINT SSST_SBPP_FK';
execute immediate 'ALTER TABLE profile_templ_access ENABLE CONSTRAINT PTA_SBPP_FK';
execute immediate 'ALTER TABLE profile_templ_access ENABLE CONSTRAINT PTA_SSST_FK';
end;
/
-- CHANGE END: Gustavo Serrano

-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 12/02/2010
-- CHANGE REASON: [ALERT-74596]  Pk corrections
/*************EXECUTAR NUMA JANELA/SESSÃO DIFERENTE****************/
BEGIN
execute immediate 'ALTER TABLE profile_templ_access DISABLE CONSTRAINT PTA_SBPP_FK';
execute immediate 'ALTER TABLE profile_templ_access DISABLE CONSTRAINT PTA_SSST_FK';
execute immediate 'ALTER TABLE sys_shortcut DISABLE CONSTRAINT SSST_SBPP_FK';
end;
/

UPDATE profile_templ_access SET id_profile_templ_access = 102810150 WHERE id_profile_templ_access = 2500070000000121;
UPDATE profile_templ_access SET id_profile_templ_access = 102810151 WHERE id_profile_templ_access = 2500070000000122;
UPDATE profile_templ_access SET id_profile_templ_access = 102810152 WHERE id_profile_templ_access = 2500070000000123;
UPDATE profile_templ_access SET id_profile_templ_access = 102810153 WHERE id_profile_templ_access = 2500070000000124;
UPDATE profile_templ_access SET id_profile_templ_access = 102810154 WHERE id_profile_templ_access = 2500070000000125;
UPDATE sys_shortcut SET id_shortcut_pk = 168254 WHERE id_shortcut_pk = 2500070000000024;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102810155;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102808508;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102810150;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102810160;
UPDATE sys_shortcut SET id_shortcut_pk = 168255, id_sys_shortcut = 168148 WHERE id_shortcut_pk = 2500070000000025;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 165903;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 165904;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 102779173;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 102810131;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 102810130;
UPDATE sys_shortcut SET id_shortcut_pk = 168256 WHERE id_shortcut_pk = 2500070000000027;
UPDATE profile_templ_access SET id_shortcut_pk = 168256 WHERE id_profile_templ_access = 48111;

/*************EXECUTAR NUMA JANELA/SESSÃO DIFERENTE****************/
BEGIN
execute immediate 'ALTER TABLE sys_shortcut ENABLE CONSTRAINT SSST_SBPP_FK';
execute immediate 'ALTER TABLE profile_templ_access ENABLE CONSTRAINT PTA_SBPP_FK';
execute immediate 'ALTER TABLE profile_templ_access ENABLE CONSTRAINT PTA_SSST_FK';
end;
/
-- CHANGE END: Gustavo Serrano

-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 12/02/2010
-- CHANGE REASON: [ALERT-74596]  Pk corrections
/*************EXECUTAR NUMA JANELA/SESSÃO DIFERENTE****************/
BEGIN
execute immediate 'ALTER TABLE profile_templ_access DISABLE CONSTRAINT PTA_SBPP_FK';
execute immediate 'ALTER TABLE profile_templ_access DISABLE CONSTRAINT PTA_SSST_FK';
execute immediate 'ALTER TABLE sys_shortcut DISABLE CONSTRAINT SSST_SBPP_FK';
end;
/

UPDATE profile_templ_access SET id_profile_templ_access = 102810150 WHERE id_profile_templ_access = 2500070000000121;
UPDATE profile_templ_access SET id_profile_templ_access = 102810151 WHERE id_profile_templ_access = 2500070000000122;
UPDATE profile_templ_access SET id_profile_templ_access = 102810152 WHERE id_profile_templ_access = 2500070000000123;
UPDATE profile_templ_access SET id_profile_templ_access = 102810153 WHERE id_profile_templ_access = 2500070000000124;
UPDATE profile_templ_access SET id_profile_templ_access = 102810154 WHERE id_profile_templ_access = 2500070000000125;
UPDATE sys_shortcut SET id_shortcut_pk = 168254 WHERE id_shortcut_pk = 2500070000000024;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102810155;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102808508;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102810150;
UPDATE profile_templ_access SET id_shortcut_pk = 168254 WHERE id_profile_templ_access = 102810160;
UPDATE sys_shortcut SET id_shortcut_pk = 168255 WHERE id_shortcut_pk = 2500070000000025;
UPDATE profile_templ_access SET id_shortcut_pk = 168255, id_sys_shortcut = 168148 WHERE id_profile_templ_access = 165903;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 165904;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 102779173;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 102810131;
UPDATE profile_templ_access SET id_shortcut_pk = 168255 WHERE id_profile_templ_access = 102810130;
UPDATE sys_shortcut SET id_shortcut_pk = 168256 WHERE id_shortcut_pk = 2500070000000027;
UPDATE profile_templ_access SET id_shortcut_pk = 168256 WHERE id_profile_templ_access = 48111;

/*************EXECUTAR NUMA JANELA/SESSÃO DIFERENTE****************/
BEGIN
execute immediate 'ALTER TABLE sys_shortcut ENABLE CONSTRAINT SSST_SBPP_FK';
execute immediate 'ALTER TABLE profile_templ_access ENABLE CONSTRAINT PTA_SBPP_FK';
execute immediate 'ALTER TABLE profile_templ_access ENABLE CONSTRAINT PTA_SSST_FK';
end;
/
-- CHANGE END: Gustavo Serrano



-- CHANGED BY: Ana Matos
-- CHANGED DATE: 2010-MAR-18
-- CHANGED REASON: ALERT-82125

CREATE OR REPLACE TYPE T_COLL_EPISACTIVEITECH AS TABLE OF t_rec_episactiveitech;

-- CHANGE END: Ana Matos

-- CHANGE END

-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 25/03/2010
-- CHANGE REASON: [ARCHDB-337]
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_awareness';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_awareness(i_patient                => NULL,
                                             i_episode                => NULL,
                                             i_schedule               => NULL,
                                             i_external_request       => NULL,
                                             i_institution            => NULL,
                                             i_start_dt               => NULL,
                                             i_end_dt                 => NULL,
                                             i_validate_table         => FALSE,
                                             i_recreate_table         => TRUE,
                                             i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
alter table AWARENESS modify ID_VISIT not null;
-- CHANGE END: Fábio Oliveira

-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 06-Apr-2010
-- CHANGE REASON: [ARCHDB-337]
DECLARE    
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_awareness';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_awareness(i_patient                => NULL,
                                             i_episode                => NULL,
                                             i_schedule               => NULL,
                                             i_external_request       => NULL,
                                             i_institution            => NULL,
                                             i_start_dt               => NULL,
                                             i_end_dt                 => NULL,
                                             i_validate_table         => FALSE,
                                             i_recreate_table         => TRUE,
                                             i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
  END IF;
END;
/
-- CHANGE END: Fábio Oliveira




-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 06-Apr-2010
-- CHANGE REASON: [ARCHDB-337]
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_awareness';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_awareness(i_patient                => NULL,
                                             i_episode                => NULL,
                                             i_schedule               => NULL,
                                             i_external_request       => NULL,
                                             i_institution            => NULL,
                                             i_start_dt               => NULL,
                                             i_end_dt                 => NULL,
                                             i_validate_table         => FALSE,
                                             i_recreate_table         => TRUE,
                                             i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END: Fábio Oliveira

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 05-03-2010
-- CHANGE REASON: SCH-510
DROP TRIGGER A_IU_ROOM;
DROP TRIGGER A_IU_BED;
DROP TRIGGER A_IU_DEPARTMENT;
DROP TRIGGER A_IU_DEPT;
/
-- CHANGE END: Telmo Castro


-- CHANGED BY: RicardoNunoAlmeida
-- CHANGE DATE: 16/04/2010 18:01
-- CHANGE REASON: [ALERT-90024] 
DECLARE    

l_err  t_error_out;
BEGIN

    FOR l_rec IN ( 
    SELECT data.new, data.old, data.id_prof, data.inst, data.soft
    FROM (

SELECT 
decode(ppt.id_profile_template,
--EDIS
400, 460,
401, 461,
406, 466,
207, 9250,
215, 9251,
235, 9256,
--INP
214,190,
217,191,
220,192,
223,193,
600, 670,
605, 671,
610, 672,
615, 673, 
620, 674,
630, 675,
640, 676,
--ORIS
100,170,
103,171,
105,172,
207, 173,
206, 174,
--OUTP       
34, 150,
33, 151,
6, 152,
91, 153,
90, 154,
208, 160,
200, 161,
203, 162,
ppt.id_profile_template) new, ppt.id_profile_template old,
ppt.id_professional id_prof, ppt.id_institution inst, ppt.id_software soft
FROM prof_profile_template ppt
WHERE ppt.id_institution  IN (SELECT distinct i.id_institution
FROM institution i 
 WHERE i.id_market != 1 )
AND ppt.id_software IN (1, 11, 8, 2)
AND ppt.id_profile_template IN (
--EDIS
400, 401, 406, 207,215, 235,
--INP
214, 217, 220, 223,
600, 605,610, 615, 
620, 630, 640,
--ORIS
100, 103, 105,
207, 206,
--OUTP       
34, 33, 6, 
91, 90, 208,
200, 203)
        ORDER BY ppt.id_professional, ppt.id_software, ppt.id_institution
) data
WHERE data.new != data.old
)
LOOP

      

    BEGIN    
--Change profiles
IF NOT pk_backoffice.set_template_list(i_lang => 1,
 i_id_prof => l_rec.id_prof,
 i_inst => table_number(l_rec.inst),
 i_soft => table_number(l_rec.soft),
 i_id_dep_clin_serv => NULL,
 i_templ => table_number(l_rec.new),
 i_commit_at_end => TRUE,
 o_error => l_err) THEN
dbms_output.put_line('>>ERROR @ ' || l_rec.id_prof || ': ' || l_rec.inst || '-' || l_rec.soft 
|| '///' || l_err.err_instance_id_out || '\\\' || l_err.err_desc);

END IF;
EXCEPTION
    when no_data_found then 
     null; 
    END; 

END LOOP;


dbms_output.put_line('>>SUCCESS!!');

END;
/
-- CHANGE END: RicardoNunoAlmeida

-- CHANGED BY: RicardoNunoAlmeida
-- CHANGE DATE: 20/04/2010 12:19
-- CHANGE REASON: [ALERT-90024] 
DECLARE    

l_err  t_error_out;
BEGIN

    FOR l_rec IN ( 
    SELECT data.new, data.old, data.id_prof, data.inst, data.soft
    FROM (

SELECT 
decode(ppt.id_profile_template,
--EDIS
400, 460,
401, 461,
406, 466,
--INP
600, 670,
605, 671,
610, 672,
615, 673, 
620, 674,
630, 675,
640, 676,
--ORIS
100,170,
103,171,
105,172,
--OUTP       
34, 150,
33, 151,
6, 152,
91, 153,
90, 154,
ppt.id_profile_template) new, ppt.id_profile_template old,
ppt.id_professional id_prof, ppt.id_institution inst, ppt.id_software soft
FROM prof_profile_template ppt
WHERE ppt.id_institution  IN (SELECT distinct i.id_institution
FROM institution i 
 WHERE i.id_market != 1 )
AND ppt.id_software IN (1, 11, 8, 2)
AND ppt.id_profile_template IN (
--EDIS
400, 401, 406, 
--INP
600, 605,610, 615, 
620, 630, 640,
--ORIS
100, 103, 105,
--OUTP       
34, 33, 6, 
91, 90)
        ORDER BY ppt.id_professional, ppt.id_software, ppt.id_institution
) data
WHERE data.new != data.old
)
LOOP

      

    BEGIN    
--Change profiles
IF NOT pk_backoffice.set_template_list(i_lang => 1,
 i_id_prof => l_rec.id_prof,
 i_inst => table_number(l_rec.inst),
 i_soft => table_number(l_rec.soft),
 i_id_dep_clin_serv => NULL,
 i_templ => table_number(l_rec.new),
 i_commit_at_end => TRUE,
 o_error => l_err) THEN
dbms_output.put_line('>>ERROR @ ' || l_rec.id_prof || ': ' || l_rec.inst || '-' || l_rec.soft 
|| '///' || l_err.err_instance_id_out || '\\\' || l_err.err_desc);

END IF;
EXCEPTION
    when no_data_found then 
     null; 
    END; 

END LOOP;


dbms_output.put_line('>>SUCCESS!!');

END;
/
-- CHANGE END: RicardoNunoAlmeida

-- CHANGED BY: Eduardo Reis
-- CHANGE DATE: 27/04/2010
-- CHANGE REASON: [ALERT-92954] Add column to save record creation date
update nurse_tea_det set dt_nurse_tea_det_tstz = nvl(nvl(create_time, dt_start), systimestamp);
-- CHANGE END: Eduardo Reis


-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 29/04/2010 18:28
-- CHANGE REASON: [ALERT-93976] 
UPDATE sys_domain sd
   SET sd.img_name = 'CancelIcon', sd.rank = 90
 WHERE sd.code_domain = 'SR_POS_STATUS.FLG_STATUS'
   AND sd.val = 'C';

UPDATE sys_domain sd
   SET sd.img_name = 'ScheduledCheckIcon', sd.rank = 30
 WHERE sd.code_domain = 'SR_POS_STATUS.FLG_STATUS'
   AND sd.val = 'S';

UPDATE sys_domain sd
   SET sd.img_name = 'POSExpiredIcon', sd.rank = 80
 WHERE sd.code_domain = 'SR_POS_STATUS.FLG_STATUS'
   AND sd.val = 'EX';

UPDATE sys_domain sd
   SET sd.img_name = 'WorkflowIcon', sd.rank = 40
 WHERE sd.code_domain = 'SR_POS_STATUS.FLG_STATUS'
   AND sd.val = 'U';

UPDATE sys_domain sd
   SET sd.img_name = 'ScheduledWaitingIcon', sd.rank = 20
 WHERE sd.code_domain = 'SR_POS_STATUS.FLG_STATUS'
   AND sd.val = 'NS';
-- CHANGE END: Filipe Silva
-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 18-Jun-2010
-- CHANGE REASON: [ALERT-96236]
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_awareness';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_awareness(i_patient                => NULL,
                                             i_episode                => NULL,
                                             i_schedule               => NULL,
                                             i_external_request       => NULL,
                                             i_institution            => NULL,
                                             i_start_dt               => NULL,
                                             i_end_dt                 => NULL,
                                             i_validate_table         => FALSE,
                                             i_recreate_table         => TRUE,
                                             i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END: Fábio Oliveira

-- CHANGED BY: Marco Freire
-- CHANGE DATE: 21/06/2010 15:12
-- CHANGE REASON: [ALERT-27380] 
ALTER TABLE ANALYSIS_QUESTIONNAIRE DROP CONSTRAINT AQE_PK;
ALTER TABLE ANALYSIS_QUESTIONNAIRE ADD CONSTRAINT AQE_PK PRIMARY KEY (ID_ROOM_QUESTIONNAIRE, ID_ANALYSIS_ROOM, FLG_TIMING) ENABLE;
-- CHANGE END: Marco Freire

-- CHANGED BY: Luís Maia
-- CHANGE DATE: 28/06/2010 17:42
-- CHANGE REASON: [ALERT-107787] 
BEGIN
  pk_bmng_pbl.bmng_housekeeping;
END;
/
-- CHANGE END: Luís Maia

-- CHANGED BY: Marco Freire
-- CHANGE DATE: 04/07/2010 12:38
-- CHANGE REASON: [ALERT-27380] 
ALTER TABLE ROOM_QUESTIONNAIRE DROP CONSTRAINT RQ_ID_QUESTIONNAIRE_FK;
ALTER TABLE ANALYSIS_QUESTIONNAIRE DROP CONSTRAINT AQE_PK;
ALTER TABLE ANALYSIS_QUESTIONNAIRE ADD CONSTRAINT AQE_PK PRIMARY KEY (ID_ROOM_QUESTIONNAIRE, ID_ANALYSIS_ROOM, FLG_TIMING) ENABLE;
ALTER TABLE ROOM_QUESTIONNAIRE ADD CONSTRAINT RQ_ID_QUESTIONNAIRE_FK FOREIGN KEY(ID_QUESTIONNAIRE) REFERENCES QUESTIONNAIRE(ID_QUESTIONNAIRE) ENABLE;
-- CHANGE END: Marco Freire 

-- CHANGED BY: Marco Freire
-- CHANGE DATE: 04/07/2010 20:04
-- CHANGE REASON: [ALERT-27380]
ALTER TABLE ANALYSIS_QUESTION_RESP_HIST DROP CONSTRAINT AQRH_AQE_FK;
ALTER TABLE ANALYSIS_QUESTION_RESPONSE DROP CONSTRAINT AQR_AQE_FK; 
ALTER TABLE ANALYSIS_QUESTIONNAIRE DROP CONSTRAINT AQE_PK;
ALTER TABLE ANALYSIS_QUESTIONNAIRE ADD CONSTRAINT AQE_PK PRIMARY KEY (ID_ROOM_QUESTIONNAIRE, ID_ANALYSIS_ROOM, FLG_TIMING) ENABLE;
ALTER TABLE ANALYSIS_QUESTION_RESP_HIST ADD CONSTRAINT AQRH_AQE_FK FOREIGN KEY (ID_ANALYSIS_QUESTIONNAIRE)
	  REFERENCES ANALYSIS_QUESTIONNAIRE (ID_ANALYSIS_QUESTIONNAIRE) ENABLE;		
ALTER TABLE ANALYSIS_QUESTION_RESPONSE ADD CONSTRAINT AQR_AQE_FK FOREIGN KEY (ID_ANALYSIS_QUESTIONNAIRE)
	  REFERENCES ANALYSIS_QUESTIONNAIRE (ID_ANALYSIS_QUESTIONNAIRE) ENABLE;
ALTER TABLE ROOM_QUESTIONNAIRE ADD CONSTRAINT RQ_ID_QUESTIONNAIRE_FK FOREIGN KEY(ID_QUESTIONNAIRE) REFERENCES QUESTIONNAIRE(ID_QUESTIONNAIRE) ENABLE;
-- CHANGE END: Marco Freire   

-- CHANGED BY: Luís Maia
-- CHANGE DATE: 08/07/2010 16:14
-- CHANGE REASON: [ALERT-109496] 
DECLARE
    CURSOR c_bed_error IS
        SELECT ba.id_bmng_action,
               ba.id_bed,
               ba.flg_bed_ocupacity_status,
               ba.id_bmng_allocation_bed   ba_id_bmng_allocation_bed,
               bab.id_bmng_allocation_bed  bab_id_bmng_allocation_bed,
               bab2.id_bmng_allocation_bed bab2_id_bmng_allocation_bed --COUNT(1) num
          FROM alert.bmng_action ba
         INNER JOIN bed b ON (b.id_bed = ba.id_bed)
          LEFT JOIN bmng_allocation_bed bab ON (bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed AND
                                               bab.flg_outdated = 'N')
          LEFT JOIN bmng_allocation_bed bab2 ON (bab2.id_bed = ba.id_bed AND bab2.flg_outdated = 'N')
         WHERE ba.flg_status = 'A'
           AND ba.flg_target_action = 'B'
           AND ba.flg_bed_ocupacity_status = 'O'
           AND (ba.id_bmng_allocation_bed <> bab2.id_bmng_allocation_bed OR bab.id_bmng_allocation_bed IS NULL);

BEGIN
    -- UPDATE WRONG BMNG_ALLOCATION_BEDS LINKS
    --dbms_output.put_line('--BEGIN');
    FOR bed IN c_bed_error
    LOOP
        --dbms_output.put_line('UPDATE BMNG_ACTION TO ALLOCATION ' || bed.bab2_id_bmng_allocation_bed);
        UPDATE bmng_action ba
           SET ba.id_bmng_allocation_bed = bed.bab2_id_bmng_allocation_bed
         WHERE ba.id_bmng_action = bed.id_bmng_action;
    END LOOP;
    --dbms_output.put_line('--END');

    -- UPDATE WRONG BED STATUS
    UPDATE bed b
       SET b.flg_status = 'V'
     WHERE b.id_bed IN (SELECT ba.id_bed
                          FROM bmng_action ba
                         INNER JOIN (SELECT b.*
                                      FROM bed b
                                     WHERE b.flg_status = 'O') b ON (b.id_bed = ba.id_bed)
                                                                AND ba.flg_status = 'A'
                                                                AND ba.flg_bed_ocupacity_status <> 'O');

    -- Rebuild BMNG easy access tables
    pk_bmng_pbl.bmng_housekeeping;
END;
/
-- CHANGE END: Luís Maia

-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 13-Jul-2010
-- CHANGE REASON: [ALERT-111414]
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_50_grids_ea';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_50_grids_ea(i_patient                => NULL,
                                             i_episode                => NULL,
                                             i_schedule               => NULL,
                                             i_external_request       => NULL,
                                             i_institution            => NULL,
                                             i_start_dt               => NULL,
                                             i_end_dt                 => NULL,
                                             i_validate_table         => FALSE,
                                             i_recreate_table         => TRUE)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END: Fábio Oliveira

-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 13-Jul-2010
-- CHANGE REASON: [ALERT-111414]
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_50_grids_ea';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_50_grids_ea(i_patient                => NULL,
                                             i_episode                => NULL,
                                             i_schedule               => NULL,
                                             i_external_request       => NULL,
                                             i_institution            => NULL,
                                             i_start_dt               => NULL,
                                             i_end_dt                 => NULL,
                                             i_validate_table         => FALSE,
                                             i_recreate_table         => TRUE)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END: Fábio Oliveira

-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 23/07/2010 15:48
-- CHANGE REASON: [ALERT-114539] 
drop table SR_PRE_EVAL_VISIT;
drop table SR_SURG_PROT_DET;
drop table SR_SURG_PROT_TASK_DET;
-- CHANGE END: Filipe Silva

-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 23/07/2010 16:30
-- CHANGE REASON: [ALERT-114539] 
drop table SR_PRE_EVAL_VISIT cascade constraints;
drop table SR_SURG_PROT_DET cascade constraints;
drop table SR_SURG_PROT_TASK_DET cascade constraints;
-- CHANGE END: Filipe Silva

-- CHANGED BY:  sergio.dias
-- CHANGE DATE: 26/07/2010 10:10
-- CHANGE REASON: [ALERT-114539] 
BEGIN
    ALTER TABLE SR_PRE_EVAL_VISIT DISABLE CONSTRAINT SPEV_EPIS_FK;
    ALTER TABLE SR_PRE_EVAL_VISIT DISABLE CONSTRAINT SPEV_PROF_FK;

    ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_EPIS_FK;
    ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_PROF_CANCEL_FK;
    ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_PROF_FK;
    ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_SCHD_FK;
    ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_SR_SP_TASK_FK;

    ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_EPIS_FK;
    ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_PROF_FK;
    ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_PROF_FK2;
    ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_SCHD_FK;
    ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_SR_SP_TASK_FK;

    drop table SR_PRE_EVAL_VISIT cascade constraints;
    drop table SR_SURG_PROT_DET cascade constraints;
    drop table SR_SURG_PROT_TASK_DET cascade constraints;
END;
/
-- CHANGE END:  sergio.dias

-- CHANGED BY:  sergio.dias
-- CHANGE DATE: 26/07/2010 12:32
-- CHANGE REASON: [114539] 
    ALTER TABLE SR_PRE_EVAL_VISIT DISABLE CONSTRAINT SPEV_EPIS_FK;
    ALTER TABLE SR_PRE_EVAL_VISIT DISABLE CONSTRAINT SPEV_PROF_FK;

    ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_EPIS_FK;
    ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_PROF_CANCEL_FK;
    ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_PROF_FK;
    ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_SCHD_FK;
    ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_SR_SP_TASK_FK;

    ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_EPIS_FK;
    ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_PROF_FK;
    ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_PROF_FK2;
    ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_SCHD_FK;
    ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_SR_SP_TASK_FK;

    drop table SR_PRE_EVAL_VISIT cascade constraints;
    drop table SR_SURG_PROT_DET cascade constraints;
    drop table SR_SURG_PROT_TASK_DET cascade constraints;
-- CHANGE END:  sergio.dias



-- CHANGED BY: Ana Matos
-- CHANGED DATE: 2010-JUL-26
-- CHANGED REASON: ALERT-114871

CREATE OR REPLACE TYPE t_coll_episactiveitech AS TABLE OF t_rec_episactiveitech;
CREATE OR REPLACE TYPE t_coll_episinactech AS TABLE OF t_rec_episinactech;

-- CHANGE END: Ana Matos




-- CHANGED BY:  sergio.dias
-- CHANGE DATE: 26/07/2010 14:26
-- CHANGE REASON: [ALERT-114539] 
ALTER TABLE SR_PRE_EVAL_VISIT DISABLE CONSTRAINT SPEV_EPIS_FK;
ALTER TABLE SR_PRE_EVAL_VISIT DISABLE CONSTRAINT SPEV_PROF_FK;

ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_EPIS_FK;
ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_PROF_CANCEL_FK;
ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_PROF_FK;
ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_SCHD_FK;
ALTER TABLE SR_SURG_PROT_DET DISABLE CONSTRAINT SR_SP_DET_SR_SP_TASK_FK;

ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_EPIS_FK;
ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_PROF_FK;
ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_PROF_FK2;
ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_SCHD_FK;
ALTER TABLE SR_SURG_PROT_TASK_DET DISABLE CONSTRAINT SR_SPT_DET_SR_SP_TASK_FK;

drop table SR_PRE_EVAL_VISIT cascade constraints;
drop table SR_SURG_PROT_DET cascade constraints;
drop table SR_SURG_PROT_TASK_DET cascade constraints;
-- CHANGE END:  sergio.dias

-- CHANGED BY: Fábio Oliveira
-- CHANGE DATE: 30-Jul-2010
-- CHANGE REASON: [ALERT-112195]
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_50_procedures_ea';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_50_procedures_ea(i_patient                => NULL,
                                             i_episode                => NULL,
                                             i_schedule               => NULL,
                                             i_external_request       => NULL,
                                             i_institution            => NULL,
                                             i_start_dt               => NULL,
                                             i_end_dt                 => NULL,
                                             i_validate_table         => FALSE,
                                             i_recreate_table         => TRUE)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END: Fábio Oliveira

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 18/08/2010 17:10
-- CHANGE REASON: [ALERT-118102] Lack of EDIS default profiles: Clinical Nurse Specialist (CNS) and Head Nurse
DECLARE    

l_err  t_error_out;
BEGIN

    FOR l_rec IN ( 
    SELECT data.new, data.old, data.id_prof, data.inst, data.soft
    FROM (

SELECT 
decode(ppt.id_profile_template,
--EDIS
410, 415,
413, 414,
--OUTP
40, 155, 
99, 156,
ppt.id_profile_template) new, ppt.id_profile_template old,
ppt.id_professional id_prof, ppt.id_institution inst, ppt.id_software soft, ppt.id_institution
FROM prof_profile_template ppt
WHERE ppt.id_institution  IN (SELECT distinct i.id_institution
FROM institution i 
 WHERE i.id_market != 1 )
AND ppt.id_software IN (1, 8)
AND ppt.id_profile_template IN (
--EDIS
410, 413,
--OUTP
40, 99)
        ORDER BY ppt.id_professional, ppt.id_software, ppt.id_institution
) data
WHERE data.new != data.old
)
LOOP


      
BEGIN    
--Change profiles
IF NOT pk_backoffice.set_template_list(i_lang => 1,
 i_id_prof => l_rec.id_prof,
 i_inst => table_number(l_rec.inst),
 i_soft => table_number(l_rec.soft),
 i_id_dep_clin_serv => NULL,
 i_templ => table_number(l_rec.new),
 i_commit_at_end => TRUE,
 o_error => l_err) THEN
dbms_output.put_line('>>ERROR @ ' || l_rec.id_prof || ': ' || l_rec.inst || '-' || l_rec.soft 
|| '///' || l_err.err_instance_id_out || '\\\' || l_err.err_desc);

END IF;
EXCEPTION
    when no_data_found then 
     null; 
END;

END LOOP;


dbms_output.put_line('>>SUCCESS!!');

END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 23/08/2010
-- CHANGE REASON: [ALERT-118999] Disable default profiles: 414 and 415
DECLARE    

l_err  t_error_out;
BEGIN

    FOR l_rec IN ( 
    SELECT data.new, data.old, data.id_prof, data.inst, data.soft
    FROM (

SELECT 
decode(ppt.id_profile_template,
--EDIS
415, 410,
414, 413,
ppt.id_profile_template) new, ppt.id_profile_template old,
ppt.id_professional id_prof, ppt.id_institution inst, ppt.id_software soft, ppt.id_institution
FROM prof_profile_template ppt
WHERE ppt.id_software IN (8)
AND ppt.id_profile_template IN (
--EDIS
414 ,415)
        ORDER BY ppt.id_professional, ppt.id_software, ppt.id_institution
) data
WHERE data.new != data.old
)
LOOP


      
BEGIN    
--Change profiles
IF NOT pk_backoffice.set_template_list(i_lang => 1,
 i_id_prof => l_rec.id_prof,
 i_inst => table_number(l_rec.inst),
 i_soft => table_number(l_rec.soft),
 i_id_dep_clin_serv => NULL,
 i_templ => table_number(l_rec.new),
 i_commit_at_end => TRUE,
 o_error => l_err) THEN
dbms_output.put_line('>>ERROR @ ' || l_rec.id_prof || ': ' || l_rec.inst || '-' || l_rec.soft 
|| '///' || l_err.err_instance_id_out || '\\\' || l_err.err_desc);

END IF;
EXCEPTION
    when no_data_found then 
     null; 
END;

END LOOP;


dbms_output.put_line('>>SUCCESS!!');

END;
/
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Luís Maia
-- CHANGE DATE: 26/08/2010 18:56
-- CHANGE REASON: [ALERT-119959] 
DECLARE
    g_error VARCHAR2(4000);
BEGIN
    g_error := 'admin_all_task_tl_tables';
    dbms_output.put_line('');
    dbms_output.put_line(g_error);
    IF NOT pk_data_gov_admin.admin_50_all_bmng_tables(i_patient                => NULL,
                                                      i_episode                => NULL,
                                                      i_schedule               => NULL,
                                                      i_external_request       => NULL,
                                                      i_institution            => NULL,
                                                      i_start_dt               => NULL,
                                                      i_end_dt                 => NULL,
                                                      i_validate_table         => FALSE,
                                                      i_output_invalid_records => TRUE,
                                                      i_recreate_table         => TRUE,
                                                      i_commit_step            => 500)
    THEN
        dbms_output.put_line(g_error || ' - ' || SQLERRM);
    ELSE
        dbms_output.put_line(g_error || ' - Ok');
    END IF;
END;
/
-- CHANGE END: Luís Maia



-- CHANGED BY: Ana Matos
-- CHANGE DATE: 27/08/2010 
-- CHANGE REASON: [ALERT-119202] 
DECLARE

    -- Schema Cursor
    CURSOR c_schema IS
        SELECT username
          FROM dba_users
         WHERE username = 'INTER_ALERT_V2';

    -- Statements
    TYPE t_statements IS TABLE OF VARCHAR2(400) INDEX BY PLS_INTEGER;

    l_statements t_statements;
    
    -- Statement
    l_statement VARCHAR2(400);

BEGIN

    -- Statements Build
    l_statements(1) := 'GRANT select ON alert.questionnaire';
    l_statements(2) := 'GRANT select ON alert.room_questionnaire';

    FOR schema_name IN c_schema
    LOOP
        FOR i IN 1 .. l_statements.COUNT LOOP
        EXECUTE IMMEDIATE l_statements(i) || ' to ' || schema_name.username;
        END LOOP;
    END LOOP;

END;
/
-- CHANGE END: Ana Matos




-- CHANGED BY: José Brito
-- CHANGE DATE: 31/08/2010 15:57
-- CHANGE REASON: [ALERT-121149] Manchester II UK (replication in 2.6)
BEGIN
insert into triage_configuration (ID_INSTITUTION, ID_SOFTWARE, ID_TRIAGE_TYPE, FLG_BUTTONS, FLG_CONSIDERATIONS, NUM_EPIS_TRIAGE_AUDIT, ID_REPORTS, FLG_AUTO_PRINT_TAG, FLG_CHANGE_COLOR, FLG_COMPLAINT, FLG_DEFAULT_VIEW, FLG_CHECK_VITAL_SIGN, FLG_ID_BOARD, FLG_CHECK_AGE_LIMITS)
values (0, 0, 9, 'N', 'N', 5, 58, 'Y', 'N', 'Y', 'V3', 'Y', 'Y', 'Y');
EXCEPTION
WHEN dup_val_on_index THEN
  NULL;
END;
/
-- CHANGE END: José Brito

-- CHANGED BY: Pedro Morais
-- CHANGE DATE: 08/09/2010 10:00
-- CHANGED REASON: ALERT-120208

CREATE OR REPLACE TYPE t_rec_drug_interact AS TABLE OF rec_drug_interact;
/

-- CHANGE END: Pedro Morais


-- CHANGED BY:  Filipe Sousa
-- CHANGE DATE: 01/09/2010 19:35
-- CHANGE REASON: [ALERT-98160] 
begin
update P1_EXTERNAL_REQUEST
set ID_PROF_CREATED = ID_PROF_REQUESTED;
end;
/
-- CHANGE END:  Filipe Sousa

-- CHANGED BY:  Filipe Sousa
-- CHANGE DATE: 01/09/2010 19:35
-- CHANGE REASON: [ALERT-98160] 
PROMPT Creating Foreign Key on 'P1_EXTERNAL_REQUEST'
ALTER TABLE P1_EXTERNAL_REQUEST ADD (CONSTRAINT
 PERT_PL_CR_FK FOREIGN KEY 
  (ID_PROF_CREATED) REFERENCES PROFESSIONAL
  (ID_PROFESSIONAL));
/
-- CHANGE END:  Filipe Sousa


-- CHANGED BY: Filipe Machado
-- CHANGE DATE: 23-Sep-2010 20:43
-- CHANGE REASON: [ALERT-127171] PAST HISTORY [Relevant Notes] - An error occurs when we insert too many information in the relevant notes (v2.6.0.3.3)

ALTER TABLE PAT_NOTES RENAME COLUMN NOTES TO NOTES_TMP;
 
ALTER TABLE PAT_NOTES ADD NOTES CLOB;

COMMENT ON COLUMN PAT_NOTES.NOTES IS 'RELEVANT NOTES';

UPDATE PAT_NOTES PN
   SET PN.NOTES = PN.NOTES_TMP;

ALTER TABLE PAT_NOTES DROP COLUMN NOTES_TMP;

-- CHANGE END: Filipe Machado


-- CHANGED BY: Jose Brito
-- CHANGE DATE: 14/10/2010
-- CHANGE REASON: [ALERT-123624] 
CREATE OR REPLACE TYPE t_coll_episcancelled AS TABLE OF t_rec_episcancelled;
CREATE OR REPLACE TYPE t_coll_patcriteriaactiveadmin AS TABLE OF t_rec_patcriteriaactiveadmin;
CREATE OR REPLACE TYPE t_coll_patcriteriaactiveclin AS TABLE OF t_rec_patcriteriaactiveclin;
CREATE OR REPLACE TYPE t_coll_episinactive AS TABLE OF t_rec_episinactive;
-- CHANGE END: Jose Brito




-- CHANGED BY: Sérgio Santos
-- CHANGE DATE: 14/10/2010 17:56
-- CHANGE REASON: [ALERT-117150] 
update icnp_epis_intervention_hist i set i.flg_status = 'I' where i.flg_status = 'T';
update icnp_epis_intervention i set i.flg_status = 'I' where i.flg_status = 'T';
update interv_icnp_ea i set i.flg_status = 'I' where i.flg_status = 'T';


DECLARE
    l_ret BOOLEAN;

e_error exception;
BEGIN
    l_ret := pk_data_gov_admin.admin_50_interv_icnp_ea(i_recreate_table => true, i_validate_table => true);

    IF NOT l_ret
    THEN
        raise_application_error(-20101, 'Easy access failed to update');
    END IF;
END;
/
-- CHANGE END: Sérgio Santos

-- CHANGED BY: Jorge Canossa
-- CHANGE DATE: 14/10/2010 19:15
-- CHANGE REASON: [ALERT-132125]
ALTER TABLE SR_SURG_PROT_TASK DISABLE CONSTRAINT SR_SP_TASK_SR_PROT_FK;
ALTER TABLE SR_SURG_PROT_TASK DISABLE CONSTRAINT SR_SP_TASK_SR_SU_TASK_FK;

DROP TABLE SR_SURG_PROTOCOL cascade constraints;
DROP TABLE SR_SURG_PROT_TASK cascade constraints;
DROP TABLE SR_SURG_TASK cascade constraints;
-- CHANGE END: Jorge Canossa

-- CHANGED BY: Ariel Machado
-- CHANGE DATE: 14/10/2010 20:35
-- CHANGE REASON: [ALERT-129567] Touch-Option formatting text rules
CREATE OR REPLACE TYPE t_tbl_doc_area_val AS TABLE OF t_rec_doc_area_val;
-- CHANGE END: Ariel Machado


-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 15/10/2010 08:46
-- CHANGE REASON: [ALERT-71181] 
DECLARE
    l_ret BOOLEAN;

e_error exception;
BEGIN
    l_ret := pk_data_gov_admin.admin_98_viewer_ehr_ea(i_recreate_table => true, i_validate_table => true);

    IF NOT l_ret
    THEN
        raise_application_error(-20101, 'Easy access failed to update');
    END IF;
END;
/
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Telmo Castro
-- CHANGE DATE: 19-10-2010
-- CHANGE REASON: ALERT-104816
UPDATE alert.appointment 
SET id_appointment = id_content;

alter table APPOINTMENT modify ID_APPOINTMENT not null;
alter table APPOINTMENT drop column ID_CONTENT;

drop trigger b_iud_appointment;
-- CHANGE END: Telmo Castro

-- CHANGED BY: Rui Marante
-- CHANGE DATE: 22-10-2010
-- CHANGE REASON: ALERT-133630
alter table drug_req_det
modify (
	generico varchar2(1 char) default 'N' not null,
	first_dose varchar2(1 char) default 'N' not null
);
-- CHANGE END: Rui Marante



-- CHANGED BY: Ana Matos
-- CHANGE DATE: 18/10/2010 11:40
-- CHANGE REASON: [ALERT-132607] 
alter table GRID_TASK_LAB enable row movement;
alter table GRID_TASK_LAB shrink space;
alter table GRID_TASK_LAB disable row movement;

alter index GTLAB_PK rebuild online; 
alter index GTL_GRID_IDX rebuild online; 
alter index GTL_ID_PATIENT_IDX rebuild online; 
alter index GTL_INST_FLGTH_IDX rebuild online; 

alter table GRID_TASK_IMG enable row movement;
alter table GRID_TASK_IMG shrink space;
alter table GRID_TASK_IMG disable row movement;

alter index GTI_EPE_FK_I rebuild online;
alter index GTI_SOE_FK_I rebuild online;
alter index GTI_ECT_FK_I rebuild online;
alter index GTI_GRID_IDX rebuild online;
alter index GTI_EXM_FK_I rebuild online;
alter index GTI_ROM_FK_I rebuild online;
alter index GTI_CSE_FK_I rebuild online;
alter index GTI_DET_FK_I rebuild online;
alter index GTI_ERT_FK_I rebuild online;
alter index GTI_PK_I rebuild online;
alter index GTI_PAT_FK_I rebuild online;
alter index GTI_ETE_FK_I rebuild online;
alter index GTI_INN_FK_I rebuild online;
alter index GTI_ERQ_FK_I rebuild online;

alter table GRID_TASK_OTH_EXM enable row movement;
alter table GRID_TASK_OTH_EXM shrink space;
alter table GRID_TASK_OTH_EXM disable row movement;

alter index GTOE_GRID_IDX rebuild online;
alter index GTOE_ERQ_FK_I rebuild online;
alter index GTOE_DET_FK_I rebuild online;
alter index GTOE_PK_I rebuild online;
alter index GTOE_ECT_FK_I rebuild online;
alter index GTOE_PAT_FK_I rebuild online;
alter index GTOE_ETE_FK_I rebuild online;
alter index GTOE_CSE_FK_I rebuild online;
alter index GTOE_EXM_FK_I rebuild online;
alter index GTOE_ERT_FK_I rebuild online;
alter index GTOE_SCE_FK_I rebuild online;
alter index GTOE_SOE_FK_I rebuild online;
alter index GTOE_EPE_FK_I rebuild online;
alter index GTOE_INN_FK_I rebuild online;
-- CHANGE END: Ana Matos


-- CHANGED BY: Ana Matos
-- CHANGE DATE: 25/10/2010
-- CHANGE REASON: [ALERT-131571] 
DECLARE
    sql_str table_varchar;
BEGIN
    SELECT 'alter index alert.' || index_name || ' rebuild online' BULK COLLECT
      INTO sql_str
      FROM all_indexes
     WHERE table_name IN ('GRID_TASK_IMG', 'GRID_TASK_OTH_EXM', 'GRID_TASK_LAB')
       AND owner = 'ALERT';

    FOR i IN 1 .. sql_str.count
    LOOP
        EXECUTE IMMEDIATE sql_str(i);
    END LOOP;
END;
/
-- CHANGE END: Ana Matos


--29/10/2010 Rui Batista
--[ALERT-136492] Database object Cleaning
begin

  execute immediate 'drop table PAT_TMP_REMOTA';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table POSOLOGIAS_FREQ_TEMP';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table ALLOCATION_BED_BCK';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table ANALYSIS_QUESTIONNAIRE_OLD';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table EPIS_HIDRICS_DET_BCK_2603';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table ISENCAO_OLD';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table ME_DXID_ATC_CONTRA_BCKP_2';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table MI_DXID_ATC_CONTRA_BCKP_2';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table OCCUPATION_OLD';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table PAT_FKS';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table RELIGION_OLD';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table ROOM_QUESTIONNAIRE_OLD';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table SCHOLARSHIP_OLD';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table SWF_FILE_OLD';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

begin

  execute immediate 'drop table TEMP_ACTION';
--	
	exception
	when others then --ORA-00942 Table or view does not exists
	     null;
end;
/

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 05/11/2010 12:23
-- CHANGE REASON: [ALERT-137811] ALERT_75390 Possibilidade do médico hospital encaminhar o pedido para o administrativo hospital
drop table ref_wf_actions;
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Alexandre Santos
-- CHANGE DATE: 17/11/2010 17:35
-- CHANGE REASON: [ALERT-142107] [2.6.0.4] Changing and cancelling appointmentsChanging to another physician with the same specialty as the responsible physician. However, the responsible physician remains the same. (ALERT_141739)
--                   DDL - Types, Syn and Grants and HandOff Packages Versioning
CREATE TYPE t_coll_patcriteriaactiveclin AS TABLE OF t_rec_patcriteriaactiveclin;
/
-- CHANGE END: Alexandre Santos

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 22/11/2010 10:35
-- CHANGE REASON: [ALERT-139330] 
DECLARE
    l_ret BOOLEAN;
    e_error EXCEPTION;
BEGIN
    l_ret := pk_data_gov_admin.admin_98_viewer_ehr_ea(i_recreate_table => TRUE, i_validate_table => TRUE);

    IF NOT l_ret
    THEN
        raise_application_error(-20101, 'Easy access failed to update');
    END IF;
END;
/
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Paulo Fonseca
-- CHANGE DATE: 22-Nov-2010
-- CHANGE REASON: ALERT-130845
DECLARE
    l_tabn CONSTANT PLS_INTEGER := 0;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE put_line
    (
        i_tabn IN PLS_INTEGER,
        i_txt  IN VARCHAR2
    ) IS
        l_tab    VARCHAR2(200 CHAR);
        l_dt_chr VARCHAR2(200 CHAR);
    
    BEGIN
        l_dt_chr := to_char(LEFT => current_timestamp, format => 'DD-MM-YYYY HH24:MI:SS');
    
        l_tab := lpad(str1 => ' ', len => i_tabn * 2 + 1, pad => ' ');
    
        dbms_output.put_line(a => l_dt_chr || ':' || l_tab || i_txt);
    
    END put_line;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE drop_tmp_tbl(i_tabn IN PLS_INTEGER) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Drop temporary table');
        EXECUTE IMMEDIATE 'DROP TABLE vs_ea_tmp';
    
    END drop_tmp_tbl;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE create_tmp_tbl(i_tabn IN PLS_INTEGER) IS
        e_obj_exists EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_obj_exists, -00955);
    
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Creating temporary table');
        EXECUTE IMMEDIATE 'CREATE TABLE vs_ea_tmp(' || --
                          '       id_vital_sign_read      NUMBER(24),' || --
                          '       id_vital_sign           NUMBER(12),' || --
                          '       value                   NUMBER(10, 3),' || --
                          '       id_unit_measure         NUMBER(24),' || --
                          '       id_vital_sign_scales    NUMBER(24),' || --
                          '       id_patient              NUMBER(24),' || --
                          '       id_visit                NUMBER(24),' || --
                          '       id_institution_read     NUMBER(12),' || --
                          '       dt_vital_sign_read_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE' || --
                          ') NOLOGGING TABLESPACE table_m';
    
    EXCEPTION
        WHEN e_obj_exists THEN
            put_line(i_txt => 'WARNING: Table already exists', i_tabn => l_tabn);
            drop_tmp_tbl(i_tabn => l_tabn);
            create_tmp_tbl(i_tabn => l_tabn);
        
    END create_tmp_tbl;

    ----------------------------------------------------------------------------------------------------------------

BEGIN
    put_line(i_tabn => l_tabn, i_txt => 'Start');
    create_tmp_tbl(i_tabn => l_tabn);
    put_line(i_tabn => l_tabn, i_txt => 'End');

EXCEPTION
    WHEN OTHERS THEN
        put_line(i_tabn => l_tabn, i_txt => 'ERROR: ' || SQLERRM);
    
END;
/

---------------------------------------------------------------------------------------------------------------------

DECLARE
    l_tabn CONSTANT PLS_INTEGER := 0;

    l_patient patient.id_patient%TYPE;
    l_visit   visit.id_visit%TYPE;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE put_line
    (
        i_tabn IN PLS_INTEGER,
        i_txt  IN VARCHAR2
    ) IS
        l_tab    VARCHAR2(200 CHAR);
        l_dt_chr VARCHAR2(200 CHAR);
    
    BEGIN
        l_dt_chr := to_char(LEFT => current_timestamp, format => 'DD-MM-YYYY HH24:MI:SS');
    
        l_tab := lpad(str1 => ' ', len => i_tabn * 2 + 1, pad => ' ');
    
        dbms_output.put_line(a => l_dt_chr || ':' || l_tab || i_txt);
    
    END put_line;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE insert_tmp_glasgow
    (
        i_tabn    IN PLS_INTEGER,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_visit   IN visit.id_visit%TYPE DEFAULT NULL
    ) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
        l_nrec PLS_INTEGER;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Insert the glasgow total values in the temporary table');
        INSERT /*+append*/
        INTO vs_ea_tmp
            SELECT tg.id_vital_sign_read,
                   tg.id_vital_sign,
                   tg.value,
                   pk_vital_sign.c_without_um AS id_unit_measure,
                   NULL                       AS id_vital_sign_scales,
                   tg.id_patient,
                   tg.id_visit,
                   tg.id_institution_read,
                   tg.dt_vital_sign_read_tstz
              FROM (SELECT vsr.id_vital_sign_read,
                           vrel.id_vital_sign_parent AS id_vital_sign,
                           rank() over(PARTITION BY vsr.dt_vital_sign_read_tstz ORDER BY vsr.id_vital_sign_read ASC) AS rank,
                           SUM(vsd.value) over(PARTITION BY vsr.dt_vital_sign_read_tstz) AS VALUE,
                           vsr.id_patient,
                           e.id_visit,
                           vsr.id_institution_read,
                           vsr.dt_vital_sign_read_tstz
                      FROM vital_sign_read vsr
                     INNER JOIN vital_sign_relation vrel ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                     INNER JOIN vital_sign_desc vsd ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc
                      LEFT OUTER JOIN episode e ON vsr.id_episode = e.id_episode
                     WHERE vsr.flg_state = pk_alert_constant.g_active
                       AND vrel.relation_domain = pk_alert_constant.g_vs_rel_sum
                       AND (vsr.id_episode IS NULL OR e.flg_status != pk_alert_constant.g_cancelled)
                       AND (i_patient IS NULL OR vsr.id_patient = i_patient)
                       AND (i_visit IS NULL OR e.id_visit = i_visit)) tg
             WHERE tg.rank = 1;
    
        l_nrec := SQL%ROWCOUNT;
    
        COMMIT;
        put_line(i_tabn => l_tabn, i_txt => 'Commited records: ' || l_nrec);
    
    EXCEPTION
        WHEN OTHERS THEN
            put_line(i_tabn => l_tabn, i_txt => 'ERROR: ' || SQLERRM);
            ROLLBACK;
        
    END insert_tmp_glasgow;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE insert_tmp_bp
    (
        i_tabn    IN PLS_INTEGER,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_visit   IN visit.id_visit%TYPE DEFAULT NULL
    ) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
        l_nrec PLS_INTEGER;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Insert the blood pressures values in the temporary table');
        INSERT /*+append*/
        INTO vs_ea_tmp
            SELECT bp.id_vital_sign_read,
                   bp.id_vital_sign,
                   NULL AS VALUE,
                   nvl(bp.id_unit_measure, pk_vital_sign.c_without_um) AS id_unit_measure,
                   NULL                       AS id_vital_sign_scales,
                   bp.id_patient,
                   bp.id_visit,
                   bp.id_institution_read,
                   bp.dt_vital_sign_read_tstz
              FROM (SELECT vsr.id_vital_sign_read,
                           vrel.id_vital_sign_parent AS id_vital_sign,
                           vsr.id_unit_measure,
                           rank() over(PARTITION BY vsr.dt_vital_sign_read_tstz ORDER BY vsr.id_vital_sign_read ASC) AS rank,
                           vsr.id_patient,
                           e.id_visit,
                           vsr.id_institution_read,
                           vsr.dt_vital_sign_read_tstz
                      FROM vital_sign_read vsr
                     INNER JOIN vital_sign_relation vrel ON vsr.id_vital_sign = vrel.id_vital_sign_detail
                      LEFT OUTER JOIN episode e ON vsr.id_episode = e.id_episode
                     WHERE vsr.flg_state = pk_alert_constant.g_active
                       AND vrel.relation_domain = pk_alert_constant.g_vs_rel_conc
                       AND (vsr.id_episode IS NULL OR e.flg_status != pk_alert_constant.g_cancelled)
                       AND (i_patient IS NULL OR vsr.id_patient = i_patient)
                       AND (i_visit IS NULL OR e.id_visit = i_visit)) bp
             WHERE bp.rank = 1;
    
        l_nrec := SQL%ROWCOUNT;
    
        COMMIT;
        put_line(i_tabn => l_tabn, i_txt => 'Commited records: ' || l_nrec);
    
    EXCEPTION
        WHEN OTHERS THEN
            put_line(i_tabn => l_tabn, i_txt => 'ERROR: ' || SQLERRM);
            ROLLBACK;
        
    END insert_tmp_bp;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE insert_tmp_scales
    (
        i_tabn    IN PLS_INTEGER,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_visit   IN visit.id_visit%TYPE DEFAULT NULL
    ) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
        l_nrec PLS_INTEGER;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Insert the vital sign scales values in the temporary table');
        INSERT /*+append*/
        INTO vs_ea_tmp
            SELECT vsr.id_vital_sign_read,
                   vsr.id_vital_sign,
                   vsse.value AS VALUE,
                   nvl(vsse.id_unit_measure, pk_vital_sign.c_without_um) AS id_unit_measure,
                   vss.id_vital_sign_scales,
                   vsr.id_patient,
                   e.id_visit,
                   vsr.id_institution_read,
                   vsr.dt_vital_sign_read_tstz
              FROM vital_sign_read vsr
             INNER JOIN vital_sign_scales vss ON vsr.id_vital_sign = vss.id_vital_sign
             INNER JOIN vital_sign_scales_element vsse ON vsr.id_vs_scales_element = vsse.id_vs_scales_element
                                                      AND vss.id_vital_sign_scales = vsse.id_vital_sign_scales
              LEFT OUTER JOIN episode e ON vsr.id_episode = e.id_episode
             WHERE vsr.flg_state = pk_alert_constant.g_active
               AND (vsr.id_episode IS NULL OR e.flg_status != pk_alert_constant.g_cancelled)
               AND (i_patient IS NULL OR vsr.id_patient = i_patient)
               AND (i_visit IS NULL OR e.id_visit = i_visit);
    
        l_nrec := SQL%ROWCOUNT;
    
        COMMIT;
        put_line(i_tabn => l_tabn, i_txt => 'Commited records: ' || l_nrec);
    
    EXCEPTION
        WHEN OTHERS THEN
            put_line(i_tabn => l_tabn, i_txt => 'ERROR: ' || SQLERRM);
            ROLLBACK;
        
    END insert_tmp_scales;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE insert_tmp_mc
    (
        i_tabn    IN PLS_INTEGER,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_visit   IN visit.id_visit%TYPE DEFAULT NULL
    ) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
        l_nrec PLS_INTEGER;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Insert the vital sign multichoices values in the temporary table');
        INSERT /*+append*/
        INTO vs_ea_tmp
            SELECT vsr.id_vital_sign_read,
                   vsr.id_vital_sign,
                   vsd.order_val AS VALUE,
                   pk_vital_sign.c_without_um AS id_unit_measure,
                   NULL                        AS id_vital_sign_scales,
                   vsr.id_patient,
                   e.id_visit,
                   vsr.id_institution_read,
                   vsr.dt_vital_sign_read_tstz
              FROM vital_sign_read vsr
             INNER JOIN vital_sign_desc vsd ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc
                                           AND vsr.id_vital_sign = vsd.id_vital_sign
              LEFT OUTER JOIN episode e ON vsr.id_episode = e.id_episode
             WHERE vsr.flg_state = pk_alert_constant.g_active
               AND (vsr.id_episode IS NULL OR e.flg_status != pk_alert_constant.g_cancelled)
               AND EXISTS (SELECT 1
                      FROM vital_sign vs
                     WHERE vsr.id_vital_sign = vs.id_vital_sign
                       AND vs.flg_fill_type = pk_alert_constant.g_vs_ft_multichoice)
               AND NOT EXISTS (SELECT 1
                      FROM vital_sign_relation vrel
                     WHERE vsr.id_vital_sign = vrel.id_vital_sign_detail
                       AND vrel.relation_domain = pk_alert_constant.g_vs_rel_sum)
               AND (i_patient IS NULL OR vsr.id_patient = i_patient)
               AND (i_visit IS NULL OR e.id_visit = i_visit);
    
        l_nrec := SQL%ROWCOUNT;
    
        COMMIT;
        put_line(i_tabn => l_tabn, i_txt => 'Commited records: ' || l_nrec);
    
    EXCEPTION
        WHEN OTHERS THEN
            put_line(i_tabn => l_tabn, i_txt => 'ERROR: ' || SQLERRM);
            ROLLBACK;
        
    END insert_tmp_mc;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE insert_tmp_numeric
    (
        i_tabn    IN PLS_INTEGER,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_visit   IN visit.id_visit%TYPE DEFAULT NULL
    ) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
        l_nrec PLS_INTEGER;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Insert the vital sign numeric values in the temporary table');
        INSERT /*+append*/
        INTO vs_ea_tmp
            SELECT vsr.id_vital_sign_read,
                   vsr.id_vital_sign,
                   vsr.value,
                   nvl(vsr.id_unit_measure, pk_vital_sign.c_without_um) AS id_unit_measure,
                   NULL                        AS id_vital_sign_scales,
                   vsr.id_patient,
                   e.id_visit,
                   vsr.id_institution_read,
                   vsr.dt_vital_sign_read_tstz
              FROM vital_sign_read vsr
              LEFT OUTER JOIN episode e ON vsr.id_episode = e.id_episode
             WHERE vsr.flg_state = pk_alert_constant.g_active
               AND (vsr.id_episode IS NULL OR e.flg_status != pk_alert_constant.g_cancelled)
               AND vsr.id_vs_scales_element IS NULL
               AND vsr.id_vital_sign_desc IS NULL
               AND EXISTS (SELECT 1
                      FROM vital_sign vs
                     WHERE vsr.id_vital_sign = vs.id_vital_sign
                       AND vs.flg_fill_type = pk_alert_constant.g_vs_ft_keypad)
               AND NOT EXISTS
             (SELECT 1
                      FROM vital_sign_relation vrel
                     WHERE vsr.id_vital_sign = vrel.id_vital_sign_detail
                       AND vrel.relation_domain IN (pk_alert_constant.g_vs_rel_sum, pk_alert_constant.g_vs_rel_conc))
               AND (i_patient IS NULL OR vsr.id_patient = i_patient)
               AND (i_visit IS NULL OR e.id_visit = i_visit);
    
        l_nrec := SQL%ROWCOUNT;
    
        COMMIT;
        put_line(i_tabn => l_tabn, i_txt => 'Commited records: ' || l_nrec);
    
    EXCEPTION
        WHEN OTHERS THEN
            put_line(i_tabn => l_tabn, i_txt => 'ERROR: ' || SQLERRM);
            ROLLBACK;
        
    END insert_tmp_numeric;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE populate_tmp_tbl
    (
        i_tabn    IN PLS_INTEGER,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_visit   IN visit.id_visit%TYPE DEFAULT NULL
    ) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Start populating temporary table');
        insert_tmp_glasgow(i_tabn => l_tabn, i_patient => i_patient, i_visit => i_visit);
        insert_tmp_bp(i_tabn => l_tabn, i_patient => i_patient, i_visit => i_visit);
        insert_tmp_scales(i_tabn => l_tabn, i_patient => i_patient, i_visit => i_visit);
        insert_tmp_mc(i_tabn => l_tabn, i_patient => i_patient, i_visit => i_visit);
        insert_tmp_numeric(i_tabn => l_tabn, i_patient => i_patient, i_visit => i_visit);
        put_line(i_tabn => l_tabn, i_txt => 'End populating temporary table');
    
    END populate_tmp_tbl;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE convert_tmp_um
    (
        i_tabn    IN PLS_INTEGER,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_visit   IN visit.id_visit%TYPE DEFAULT NULL
    ) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
        l_nrec PLS_INTEGER;
    
        l_vs_um_inst vs_unit_measure_inst.id_unit_measure%TYPE;
    
        CURSOR cur_vs_ea
        (
            i_pat IN vs_ea_tmp.id_patient%TYPE DEFAULT NULL,
            i_vis IN vs_ea_tmp.id_visit%TYPE DEFAULT NULL
        ) IS
            SELECT DISTINCT vtmp.id_vital_sign, vtmp.id_unit_measure, vtmp.id_institution_read
              FROM vs_ea_tmp vtmp
             WHERE i_pat IS NOT NULL
               AND vtmp.id_patient = i_pat
               AND vtmp.value IS NOT NULL
               AND vtmp.id_unit_measure IS NOT NULL
               AND vtmp.id_vital_sign_scales IS NULL
            
            UNION ALL
            
            SELECT DISTINCT vtmp.id_vital_sign, vtmp.id_unit_measure, vtmp.id_institution_read
              FROM vs_ea_tmp vtmp
             WHERE i_vis IS NOT NULL
               AND vtmp.id_visit = i_vis
               AND vtmp.value IS NOT NULL
               AND vtmp.id_unit_measure IS NOT NULL
               AND vtmp.id_vital_sign_scales IS NULL;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Start converting temporary table unit measures');
        FOR c IN cur_vs_ea(i_pat => i_patient, i_vis => i_visit)
        LOOP
            l_vs_um_inst := pk_vital_sign.get_vs_um_inst(i_vital_sign  => c.id_vital_sign,
                                                         i_institution => c.id_institution_read);
        
            IF c.id_unit_measure != l_vs_um_inst
               AND pk_unit_measure.are_convertible(i_unit_meas => c.id_unit_measure, i_unit_meas_def => l_vs_um_inst)
            THEN
                IF i_patient IS NOT NULL
                THEN
                    UPDATE vs_ea_tmp vtmp
                       SET vtmp.value           = pk_unit_measure.get_unit_mea_conversion(vtmp.value,
                                                                                          vtmp.id_unit_measure,
                                                                                          l_vs_um_inst),
                           vtmp.id_unit_measure = l_vs_um_inst
                     WHERE vtmp.id_vital_sign = c.id_vital_sign
                       AND vtmp.id_unit_measure = c.id_unit_measure
                       AND vtmp.id_institution_read = c.id_institution_read
                       AND vtmp.id_patient = i_patient;
                END IF;
            
                IF i_visit IS NOT NULL
                THEN
                    UPDATE vs_ea_tmp vtmp
                       SET vtmp.value           = pk_unit_measure.get_unit_mea_conversion(vtmp.value,
                                                                                          vtmp.id_unit_measure,
                                                                                          l_vs_um_inst),
                           vtmp.id_unit_measure = l_vs_um_inst
                     WHERE vtmp.id_vital_sign = c.id_vital_sign
                       AND vtmp.id_unit_measure = c.id_unit_measure
                       AND vtmp.id_institution_read = c.id_institution_read
                       AND vtmp.id_visit = i_visit;
                END IF;
            
                l_nrec := SQL%ROWCOUNT;
            
                COMMIT;
                put_line(i_tabn => l_tabn, i_txt => 'Commited records: ' || l_nrec);
            
            END IF;
        
        END LOOP;
    
        put_line(i_tabn => l_tabn, i_txt => 'End converting temporary table unit measures');
    
    END convert_tmp_um;

    ----------------------------------------------------------------------------------------------------------------

BEGIN
    l_patient := NULL;
    l_visit   := NULL;

    put_line(i_tabn => l_tabn, i_txt => 'Start');
    populate_tmp_tbl(i_tabn => l_tabn, i_patient => l_patient, i_visit => l_visit);
    convert_tmp_um(i_tabn => l_tabn, i_patient => l_patient, i_visit => l_visit);
    put_line(i_tabn => l_tabn, i_txt => 'End');

EXCEPTION
    WHEN OTHERS THEN
        put_line(i_tabn => l_tabn, i_txt => 'ERROR: ' || SQLERRM);
    
END;
/

---------------------------------------------------------------------------------------------------------------------

DECLARE
    l_tabn CONSTANT PLS_INTEGER := 0;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE put_line
    (
        i_tabn IN PLS_INTEGER,
        i_txt  IN VARCHAR2
    ) IS
        l_tab    VARCHAR2(200 CHAR);
        l_dt_chr VARCHAR2(200 CHAR);
    
    BEGIN
        l_dt_chr := to_char(LEFT => current_timestamp, format => 'DD-MM-YYYY HH24:MI:SS');
    
        l_tab := lpad(str1 => ' ', len => i_tabn * 2 + 1, pad => ' ');
    
        dbms_output.put_line(a => l_dt_chr || ':' || l_tab || i_txt);
    
    END put_line;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE create_tmp_idx(i_tabn IN PLS_INTEGER) IS
        e_obj_exists EXCEPTION;
        PRAGMA EXCEPTION_INIT(e_obj_exists, -00955);
    
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Creating temporary indexes');
        EXECUTE IMMEDIATE 'CREATE INDEX vtmp_p_idx ON vs_ea_tmp(id_patient) TABLESPACE index_m';
        EXECUTE IMMEDIATE 'CREATE INDEX vtmp_v_idx ON vs_ea_tmp(id_visit) TABLESPACE index_m';
    
    EXCEPTION
        WHEN e_obj_exists THEN
            put_line(i_txt => 'WARNING: Indexes already exist', i_tabn => l_tabn);
        
    END create_tmp_idx;

    ----------------------------------------------------------------------------------------------------------------

BEGIN
    put_line(i_tabn => l_tabn, i_txt => 'Start');
    create_tmp_idx(i_tabn => l_tabn);
    put_line(i_tabn => l_tabn, i_txt => 'End');

EXCEPTION
    WHEN OTHERS THEN
        put_line(i_tabn => l_tabn, i_txt => 'ERROR: ' || SQLERRM);
    
END;
/

---------------------------------------------------------------------------------------------------------------------

DECLARE
    c_tabn CONSTANT PLS_INTEGER := 0;

    c_commit_step CONSTANT PLS_INTEGER := 500;

    l_patient patient.id_patient%TYPE;
    l_visit   visit.id_visit%TYPE;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE put_line
    (
        i_tabn IN PLS_INTEGER,
        i_txt  IN VARCHAR2
    ) IS
        l_tab    VARCHAR2(200 CHAR);
        l_dt_chr VARCHAR2(200 CHAR);
    
    BEGIN
        l_dt_chr := to_char(LEFT => current_timestamp, format => 'DD-MM-YYYY HH24:MI:SS');
    
        l_tab := lpad(str1 => ' ', len => i_tabn * 2 + 1, pad => ' ');
    
        dbms_output.put_line(a => l_dt_chr || ':' || l_tab || i_txt);
    
    END put_line;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE clean_ea_tbls
    (
        i_tabn    IN PLS_INTEGER,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_visit   IN visit.id_visit%TYPE DEFAULT NULL
    ) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
    
    BEGIN
        IF i_patient IS NOT NULL
        THEN
            put_line(i_tabn => l_tabn, i_txt => 'Cleaning ea patient table');
            DELETE vs_patient_ea vpea
             WHERE vpea.id_patient = i_patient;
        
        ELSE
            put_line(i_tabn => l_tabn, i_txt => 'Truncating ea patient table');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE vs_patient_ea';
        
        END IF;
    
        IF i_visit IS NOT NULL
        THEN
            put_line(i_tabn => l_tabn, i_txt => 'Cleaning ea visit table');
            DELETE vs_visit_ea vvea
             WHERE vvea.id_visit = i_visit;
        
        ELSE
            put_line(i_tabn => l_tabn, i_txt => 'Truncating ea visit table');
            EXECUTE IMMEDIATE 'TRUNCATE TABLE vs_visit_ea';
        
        END IF;
    
    END clean_ea_tbls;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE populate_ea_patient_tbl
    (
        i_tabn    IN PLS_INTEGER,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL
    ) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
        l_nrec PLS_INTEGER;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Start populating ea patient table');
        INSERT INTO vs_patient_ea
            (id_patient,
             id_vital_sign,
             id_unit_measure,
             id_vital_sign_scales,
             n_records,
             id_first_vsr,
             id_min_vsr,
             id_max_vsr,
             id_last_1_vsr,
             id_last_2_vsr,
             id_last_3_vsr)
            SELECT v2.id_patient,
                   v2.id_vital_sign,
                   v2.id_unit_measure,
                   v2.id_vital_sign_scales,
                   MAX(v2.n_records) AS n_records,
                   MAX(v2.id_first_vsr) AS id_first_vsr,
                   MAX(v2.id_min_vsr) AS id_min_vsr,
                   MAX(v2.id_max_vsr) AS id_max_vsr,
                   MAX(v2.id_last_1_vsr) AS id_last_1_vsr,
                   MAX(v2.id_last_2_vsr) AS id_last_2_vsr,
                   MAX(v2.id_last_3_vsr) AS id_last_3_vsr
              FROM (SELECT v.id_patient,
                           v.id_vital_sign,
                           v.id_unit_measure,
                           v.id_vital_sign_scales,
                           v.cnt                  AS n_records,
                           NULL                   AS id_first_vsr,
                           NULL                   AS id_min_vsr,
                           NULL                   AS id_max_vsr,
                           NULL                   AS id_last_1_vsr,
                           NULL                   AS id_last_2_vsr,
                           NULL                   AS id_last_3_vsr
                      FROM (SELECT vt.id_patient,
                                   vt.id_vital_sign,
                                   vt.id_unit_measure,
                                   vt.id_vital_sign_scales,
                                   COUNT(1) over(PARTITION BY vt.id_patient, vt.id_vital_sign, vt.id_unit_measure, vt.id_vital_sign_scales) AS cnt
                              FROM vs_ea_tmp vt
                             WHERE i_patient IS NULL
                                OR vt.id_patient = i_patient) v
                    UNION ALL
                    SELECT v.id_patient,
                           v.id_vital_sign,
                           v.id_unit_measure,
                           v.id_vital_sign_scales,
                           NULL                   AS n_records,
                           v.id_vital_sign_read   AS id_first_vsr,
                           NULL                   AS id_min_vsr,
                           NULL                   AS id_max_vsr,
                           NULL                   AS id_last_1_vsr,
                           NULL                   AS id_last_2_vsr,
                           NULL                   AS id_last_3_vsr
                      FROM (SELECT vt.id_vital_sign_read,
                                   vt.id_patient,
                                   vt.id_vital_sign,
                                   vt.id_unit_measure,
                                   vt.id_vital_sign_scales,
                                   row_number() over(PARTITION BY vt.id_patient, vt.id_vital_sign, vt.id_unit_measure, vt.id_vital_sign_scales ORDER BY vt.dt_vital_sign_read_tstz) AS rk
                              FROM vs_ea_tmp vt
                             WHERE i_patient IS NULL
                                OR vt.id_patient = i_patient) v
                     WHERE rk = 1
                    UNION ALL
                    SELECT v.id_patient,
                           v.id_vital_sign,
                           v.id_unit_measure,
                           v.id_vital_sign_scales,
                           NULL                   AS n_records,
                           NULL                   AS id_first_vsr,
                           v.id_vital_sign_read   AS id_min_vsr,
                           NULL                   AS id_max_vsr,
                           NULL                   AS id_last_1_vsr,
                           NULL                   AS id_last_2_vsr,
                           NULL                   AS id_last_3_vsr
                      FROM (SELECT vt.id_vital_sign_read,
                                   vt.id_patient,
                                   vt.id_vital_sign,
                                   vt.id_unit_measure,
                                   vt.id_vital_sign_scales,
                                   row_number() over(PARTITION BY vt.id_patient, vt.id_vital_sign, vt.id_unit_measure, vt.id_vital_sign_scales ORDER BY vt.value ASC, vt.dt_vital_sign_read_tstz ASC) AS rk
                              FROM vs_ea_tmp vt
                             WHERE i_patient IS NULL
                                OR vt.id_patient = i_patient) v
                     WHERE rk = 1
                    UNION ALL
                    SELECT v.id_patient,
                           v.id_vital_sign,
                           v.id_unit_measure,
                           v.id_vital_sign_scales,
                           NULL                   AS n_records,
                           NULL                   AS id_first_vsr,
                           NULL                   AS id_min_vsr,
                           v.id_vital_sign_read   AS id_max_vsr,
                           NULL                   AS id_last_1_vsr,
                           NULL                   AS id_last_2_vsr,
                           NULL                   AS id_last_3_vsr
                      FROM (SELECT vt.id_vital_sign_read,
                                   vt.id_patient,
                                   vt.id_vital_sign,
                                   vt.id_unit_measure,
                                   vt.id_vital_sign_scales,
                                   row_number() over(PARTITION BY vt.id_patient, vt.id_vital_sign, vt.id_unit_measure, vt.id_vital_sign_scales ORDER BY vt.value DESC, vt.dt_vital_sign_read_tstz ASC) AS rk
                              FROM vs_ea_tmp vt
                             WHERE i_patient IS NULL
                                OR vt.id_patient = i_patient) v
                     WHERE rk = 1
                    UNION ALL
                    SELECT v1.id_patient,
                           v1.id_vital_sign,
                           v1.id_unit_measure,
                           v1.id_vital_sign_scales,
                           NULL AS n_records,
                           NULL AS id_first_vsr,
                           NULL AS id_min_vsr,
                           NULL AS id_max_vsr,
                           MAX(v1.id_last_1_vsr) AS id_last_1_vsr,
                           MAX(v1.id_last_2_vsr) AS id_last_2_vsr,
                           MAX(v1.id_last_3_vsr) AS id_last_3_vsr
                      FROM (SELECT v.id_patient,
                                   v.id_vital_sign,
                                   v.id_unit_measure,
                                   v.id_vital_sign_scales,
                                   CASE
                                        WHEN rk = 1 THEN
                                         v.id_vital_sign_read
                                        ELSE
                                         NULL
                                    END AS id_last_1_vsr,
                                   CASE
                                        WHEN rk = 2 THEN
                                         v.id_vital_sign_read
                                        ELSE
                                         NULL
                                    END AS id_last_2_vsr,
                                   CASE
                                        WHEN rk = 3 THEN
                                         v.id_vital_sign_read
                                        ELSE
                                         NULL
                                    END AS id_last_3_vsr
                              FROM (SELECT vt.id_vital_sign_read,
                                           vt.id_patient,
                                           vt.id_vital_sign,
                                           vt.id_unit_measure,
                                           vt.id_vital_sign_scales,
                                           row_number() over(PARTITION BY vt.id_patient, vt.id_vital_sign, vt.id_unit_measure, vt.id_vital_sign_scales ORDER BY vt.dt_vital_sign_read_tstz DESC) AS rk
                                      FROM vs_ea_tmp vt
                                     WHERE i_patient IS NULL
                                        OR vt.id_patient = i_patient) v
                             WHERE rk <= 3) v1
                     GROUP BY id_patient, id_vital_sign, id_unit_measure, id_vital_sign_scales) v2
             GROUP BY id_patient, id_vital_sign, id_unit_measure, id_vital_sign_scales;
    
        l_nrec := SQL%ROWCOUNT;
    
        COMMIT;
        put_line(i_tabn => l_tabn, i_txt => 'Commited records: ' || l_nrec);
    
        put_line(i_tabn => l_tabn, i_txt => 'End populating ea patient table');
    
    END populate_ea_patient_tbl;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE populate_ea_visit_tbl
    (
        i_tabn  IN PLS_INTEGER,
        i_visit IN visit.id_visit%TYPE DEFAULT NULL
    ) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
        l_nrec PLS_INTEGER;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Start populating ea visit table');
        INSERT INTO vs_visit_ea
            (id_visit,
             id_vital_sign,
             id_unit_measure,
             id_vital_sign_scales,
             n_records,
             id_first_vsr,
             id_min_vsr,
             id_max_vsr,
             id_last_1_vsr,
             id_last_2_vsr,
             id_last_3_vsr)
            SELECT v2.id_visit,
                   v2.id_vital_sign,
                   v2.id_unit_measure,
                   v2.id_vital_sign_scales,
                   MAX(v2.n_records) AS n_records,
                   MAX(v2.id_first_vsr) AS id_first_vsr,
                   MAX(v2.id_min_vsr) AS id_min_vsr,
                   MAX(v2.id_max_vsr) AS id_max_vsr,
                   MAX(v2.id_last_1_vsr) AS id_last_1_vsr,
                   MAX(v2.id_last_2_vsr) AS id_last_2_vsr,
                   MAX(v2.id_last_3_vsr) AS id_last_3_vsr
              FROM (SELECT v.id_visit,
                           v.id_vital_sign,
                           v.id_unit_measure,
                           v.id_vital_sign_scales,
                           v.cnt                  AS n_records,
                           NULL                   AS id_first_vsr,
                           NULL                   AS id_min_vsr,
                           NULL                   AS id_max_vsr,
                           NULL                   AS id_last_1_vsr,
                           NULL                   AS id_last_2_vsr,
                           NULL                   AS id_last_3_vsr
                      FROM (SELECT vt.id_visit,
                                   vt.id_vital_sign,
                                   vt.id_unit_measure,
                                   vt.id_vital_sign_scales,
                                   COUNT(1) over(PARTITION BY vt.id_visit, vt.id_vital_sign, vt.id_unit_measure, vt.id_vital_sign_scales) AS cnt
                              FROM vs_ea_tmp vt
                             WHERE vt.id_visit IS NOT NULL
                               AND (i_visit IS NULL OR vt.id_visit = i_visit)) v
                    UNION ALL
                    SELECT v.id_visit,
                           v.id_vital_sign,
                           v.id_unit_measure,
                           v.id_vital_sign_scales,
                           NULL                   AS n_records,
                           v.id_vital_sign_read   AS id_first_vsr,
                           NULL                   AS id_min_vsr,
                           NULL                   AS id_max_vsr,
                           NULL                   AS id_last_1_vsr,
                           NULL                   AS id_last_2_vsr,
                           NULL                   AS id_last_3_vsr
                      FROM (SELECT vt.id_vital_sign_read,
                                   vt.id_visit,
                                   vt.id_vital_sign,
                                   vt.id_unit_measure,
                                   vt.id_vital_sign_scales,
                                   row_number() over(PARTITION BY vt.id_visit, vt.id_vital_sign, vt.id_unit_measure, vt.id_vital_sign_scales ORDER BY vt.dt_vital_sign_read_tstz) AS rk
                              FROM vs_ea_tmp vt
                             WHERE vt.id_visit IS NOT NULL
                               AND (i_visit IS NULL OR vt.id_visit = i_visit)) v
                     WHERE rk = 1
                    UNION ALL
                    SELECT v.id_visit,
                           v.id_vital_sign,
                           v.id_unit_measure,
                           v.id_vital_sign_scales,
                           NULL                   AS n_records,
                           NULL                   AS id_first_vsr,
                           v.id_vital_sign_read   AS id_min_vsr,
                           NULL                   AS id_max_vsr,
                           NULL                   AS id_last_1_vsr,
                           NULL                   AS id_last_2_vsr,
                           NULL                   AS id_last_3_vsr
                      FROM (SELECT vt.id_vital_sign_read,
                                   vt.id_visit,
                                   vt.id_vital_sign,
                                   vt.id_unit_measure,
                                   vt.id_vital_sign_scales,
                                   row_number() over(PARTITION BY vt.id_visit, vt.id_vital_sign, vt.id_unit_measure, vt.id_vital_sign_scales ORDER BY vt.value ASC, vt.dt_vital_sign_read_tstz ASC) AS rk
                              FROM vs_ea_tmp vt
                             WHERE vt.id_visit IS NOT NULL
                               AND (i_visit IS NULL OR vt.id_visit = i_visit)) v
                     WHERE rk = 1
                    UNION ALL
                    SELECT v.id_visit,
                           v.id_vital_sign,
                           v.id_unit_measure,
                           v.id_vital_sign_scales,
                           NULL                   AS n_records,
                           NULL                   AS id_first_vsr,
                           NULL                   AS id_min_vsr,
                           v.id_vital_sign_read   AS id_max_vsr,
                           NULL                   AS id_last_1_vsr,
                           NULL                   AS id_last_2_vsr,
                           NULL                   AS id_last_3_vsr
                      FROM (SELECT vt.id_vital_sign_read,
                                   vt.id_visit,
                                   vt.id_vital_sign,
                                   vt.id_unit_measure,
                                   vt.id_vital_sign_scales,
                                   row_number() over(PARTITION BY vt.id_visit, vt.id_vital_sign, vt.id_unit_measure, vt.id_vital_sign_scales ORDER BY vt.value DESC, vt.dt_vital_sign_read_tstz ASC) AS rk
                              FROM vs_ea_tmp vt
                             WHERE vt.id_visit IS NOT NULL
                               AND (i_visit IS NULL OR vt.id_visit = i_visit)) v
                     WHERE rk = 1
                    UNION ALL
                    SELECT v1.id_visit,
                           v1.id_vital_sign,
                           v1.id_unit_measure,
                           v1.id_vital_sign_scales,
                           NULL AS n_records,
                           NULL AS id_first_vsr,
                           NULL AS id_min_vsr,
                           NULL AS id_max_vsr,
                           MAX(v1.id_last_1_vsr) AS id_last_1_vsr,
                           MAX(v1.id_last_2_vsr) AS id_last_2_vsr,
                           MAX(v1.id_last_3_vsr) AS id_last_3_vsr
                      FROM (SELECT v.id_visit,
                                   v.id_vital_sign,
                                   v.id_unit_measure,
                                   v.id_vital_sign_scales,
                                   CASE
                                        WHEN rk = 1 THEN
                                         v.id_vital_sign_read
                                        ELSE
                                         NULL
                                    END AS id_last_1_vsr,
                                   CASE
                                        WHEN rk = 2 THEN
                                         v.id_vital_sign_read
                                        ELSE
                                         NULL
                                    END AS id_last_2_vsr,
                                   CASE
                                        WHEN rk = 3 THEN
                                         v.id_vital_sign_read
                                        ELSE
                                         NULL
                                    END AS id_last_3_vsr
                              FROM (SELECT vt.id_vital_sign_read,
                                           vt.id_visit,
                                           vt.id_vital_sign,
                                           vt.id_unit_measure,
                                           vt.id_vital_sign_scales,
                                           row_number() over(PARTITION BY vt.id_visit, vt.id_vital_sign, vt.id_unit_measure, vt.id_vital_sign_scales ORDER BY vt.dt_vital_sign_read_tstz DESC) AS rk
                                      FROM vs_ea_tmp vt
                                     WHERE vt.id_visit IS NOT NULL
                                       AND (i_visit IS NULL OR vt.id_visit = i_visit)) v
                             WHERE rk <= 3) v1
                     GROUP BY id_visit, id_vital_sign, id_unit_measure, id_vital_sign_scales) v2
             GROUP BY id_visit, id_vital_sign, id_unit_measure, id_vital_sign_scales;
    
        l_nrec := SQL%ROWCOUNT;
    
        COMMIT;
        put_line(i_tabn => l_tabn, i_txt => 'Commited records: ' || l_nrec);
    
        put_line(i_tabn => l_tabn, i_txt => 'End populating ea visit table');
    
    END populate_ea_visit_tbl;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE populate_ea_tbls
    (
        i_tabn    IN PLS_INTEGER,
        i_patient IN patient.id_patient%TYPE DEFAULT NULL,
        i_visit   IN visit.id_visit%TYPE DEFAULT NULL
    ) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Start populating ea tables');
        populate_ea_patient_tbl(i_tabn => l_tabn, i_patient => i_patient);
        populate_ea_visit_tbl(i_tabn => l_tabn, i_visit => i_visit);
        put_line(i_tabn => l_tabn, i_txt => 'End populating ea tables');
    
    END populate_ea_tbls;

    ----------------------------------------------------------------------------------------------------------------

BEGIN
    l_patient := NULL;
    l_visit   := NULL;

    put_line(i_tabn => c_tabn, i_txt => 'Start');
    clean_ea_tbls(i_tabn => c_tabn, i_patient => l_patient, i_visit => l_visit);
    populate_ea_tbls(i_tabn => c_tabn, i_patient => l_patient, i_visit => l_visit);
    put_line(i_tabn => c_tabn, i_txt => 'End');

EXCEPTION
    WHEN OTHERS THEN
        put_line(i_tabn => c_tabn, i_txt => 'ERROR: ' || SQLERRM);
    
END;
/

---------------------------------------------------------------------------------------------------------------------

DECLARE
    l_tabn CONSTANT PLS_INTEGER := 0;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE put_line
    (
        i_tabn IN PLS_INTEGER,
        i_txt  IN VARCHAR2
    ) IS
        l_tab    VARCHAR2(200 CHAR);
        l_dt_chr VARCHAR2(200 CHAR);
    
    BEGIN
        l_dt_chr := to_char(LEFT => current_timestamp, format => 'DD-MM-YYYY HH24:MI:SS');
    
        l_tab := lpad(str1 => ' ', len => i_tabn * 2 + 1, pad => ' ');
    
        dbms_output.put_line(a => l_dt_chr || ':' || l_tab || i_txt);
    
    END put_line;

    ----------------------------------------------------------------------------------------------------------------
    PROCEDURE drop_tmp_tbl(i_tabn IN PLS_INTEGER) IS
        l_tabn CONSTANT PLS_INTEGER := i_tabn + 1;
    
    BEGIN
        put_line(i_tabn => l_tabn, i_txt => 'Drop temporary table');
        EXECUTE IMMEDIATE 'DROP TABLE vs_ea_tmp';
    
    END drop_tmp_tbl;

    ----------------------------------------------------------------------------------------------------------------

BEGIN
    put_line(i_tabn => l_tabn, i_txt => 'Start');
    drop_tmp_tbl(i_tabn => l_tabn);
    put_line(i_tabn => l_tabn, i_txt => 'End');

EXCEPTION
    WHEN OTHERS THEN
        put_line(i_tabn => l_tabn, i_txt => 'ERROR: ' || SQLERRM);
    
END;
/
-- CHANGE END: Paulo Fonseca


-- CHANGED BY: Rui Spratley
-- CHANGE DATE: 24/11/2010 09:46
-- CHANGE REASON: [ALERT-127579] 
DECLARE
    CURSOR c_enable_chk IS
        SELECT 'alter table ' || uc.table_name || ' enable constraint ' || uc.constraint_name sql_run,
               'alter table ' || uc.table_name || ' enable novalidate constraint ' || uc.constraint_name sql_run_novalidate
          FROM user_constraints uc
         WHERE uc.status != 'ENABLED'
           AND uc.constraint_type = 'C';

    check_constraint_violated EXCEPTION;
    PRAGMA EXCEPTION_INIT(check_constraint_violated, -02293);

BEGIN
    FOR r_c_enable_chk IN c_enable_chk
    LOOP
        BEGIN
            EXECUTE IMMEDIATE r_c_enable_chk.sql_run;
        EXCEPTION
            WHEN check_constraint_violated THEN
                EXECUTE IMMEDIATE r_c_enable_chk.sql_run_novalidate;
            WHEN OTHERS THEN
                dbms_output.put_line('Unable to run: ' || r_c_enable_chk.sql_run_novalidate || '-' || SQLERRM);
        END;
    END LOOP;
END;
/
-- CHANGE END: Rui Spratley


-- CHANGED BY: Ana Matos
-- CHANGE REASON: ALERT-133180
-- CHANGE DATE: 2010/10/24

ALTER TABLE exam_questionnaire drop constraint EQ_QRE_FK;
/

ALTER TABLE alert.analysis_questionnaire DROP COLUMN id_response;
/

ALTER TABLE alert.exam_questionnaire DROP COLUMN id_response;
/

ALTER TABLE analysis_questionnaire ADD CONSTRAINT AQE_Q_FK FOREIGN KEY (id_questionnaire) REFERENCES questionnaire (id_questionnaire) ENABLE;
/

ALTER TABLE exam_questionnaire ADD CONSTRAINT EQ_Q_FK FOREIGN KEY (id_questionnaire) REFERENCES questionnaire (id_questionnaire) ENABLE;
/

-- CHANGE END: Ana Matos



-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 25/11/2010 11:32
-- CHANGE REASON: [ALERT-137811] 

-----------------
-- disable FK
alter table WF_TRANSITION_CONFIG disable constraint WTC_WWE_FK;

-----------------
-- actualiza PK

-- BLOCK 48->18
UPDATE wf_transition w
   SET id_workflow_action = 19
 WHERE id_status_begin = 48
   AND id_status_end = 18; 
   
UPDATE wf_transition_config w
   SET id_workflow_action = 19
 WHERE id_status_begin = 48
   AND id_status_end = 18;

-- UNBLOCK 18->48
UPDATE wf_transition w
   SET id_workflow_action = 20
 WHERE id_status_begin = 18
   AND id_status_end = 48;

UPDATE wf_transition_config w
   SET id_workflow_action = 20
 WHERE id_status_begin = 18
   AND id_status_end = 48;

-----------------
-- enable FK
alter table WF_TRANSITION_CONFIG enable constraint WTC_WWE_FK;
-- CHANGE END: Ana Monteiro


-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 25/11/2010
-- CHANGE REASON: [ALERT-137811] 
-----------------
-- disable FK
alter table WF_TRANSITION_CONFIG disable constraint WTC_WTS_FK;

-----------------
-- actualiza PK

-- BLOCK 48->18
UPDATE wf_transition w
   SET id_workflow_action = 19
 WHERE id_status_begin = 48
   AND id_status_end = 18; 
   
UPDATE wf_transition_config w
   SET id_workflow_action = 19
 WHERE id_status_begin = 48
   AND id_status_end = 18;

-- UNBLOCK 18->48
UPDATE wf_transition w
   SET id_workflow_action = 20
 WHERE id_status_begin = 18
   AND id_status_end = 48;

UPDATE wf_transition_config w
   SET id_workflow_action = 20
 WHERE id_status_begin = 18
   AND id_status_end = 48;

-----------------
-- enable FK
alter table WF_TRANSITION_CONFIG enable constraint WTC_WTS_FK;
alter table WF_TRANSITION_CONFIG enable constraint WTC_WWE_FK;

-- CHANGE END: Ana Monteiro

-- CHANGED BY: Telmo
-- CHANGE DATE: 26-11-2010
-- CHANGE REASON: SCH-3434
grant select, insert on alert.err$_sch_api_map_ids to alert_apsschdlr_tr;
-- CHANGE END: Telmo


-- CHANGED BY: Rui Duarte
-- CHANGE DATE: 30/11/2010 11:17
-- CHANGE REASON: [ALERT-145613] Issue Replication: Scale of imeline view configurable(v2.6.0.4) 
DECLARE 
    e_table_or_view_dosent_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_table_or_view_dosent_exist, -00942);
    l_table_name VARCHAR2(30) := 'tl_timeline_access'; 
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE ' || l_table_name || '_' || TO_CHAR(current_timestamp, 'YYYYMMDD')  || ' AS SELECT * FROM ' || l_table_name;
EXCEPTION
    WHEN e_table_or_view_dosent_exist THEN
        dbms_output.put_line('WARNING - Backup table for ' || l_table_name || ' already created in previous version.');
END;
/

DECLARE 
    e_table_or_view_dosent_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_table_or_view_dosent_exist, -00942);
    l_table_name VARCHAR2(30) := 'tl_timeline_access';     
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE ' || l_table_name;
EXCEPTION
    WHEN e_table_or_view_dosent_exist THEN
        dbms_output.put_line('WARNING - Table ' || l_table_name || ' already droped in previous version.');
END;
/

DECLARE 
    e_table_or_view_dosent_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_table_or_view_dosent_exist, -00942);
    l_table_name VARCHAR2(30) := 'tl_timeline_scale'; 
BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE ' || l_table_name || '_' || TO_CHAR(current_timestamp, 'YYYYMMDD')  || ' AS SELECT * FROM ' || l_table_name;
EXCEPTION
    WHEN e_table_or_view_dosent_exist THEN
        dbms_output.put_line('WARNING - Backup table for ' || l_table_name || ' already created in previous version.');
END;
/

DECLARE 
    e_table_or_view_dosent_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_table_or_view_dosent_exist, -00942);
    l_table_name VARCHAR2(30) := 'tl_timeline_scale';     
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE ' || l_table_name;
EXCEPTION
    WHEN e_table_or_view_dosent_exist THEN
        dbms_output.put_line('WARNING - Table ' || l_table_name || ' already droped in previous version.');
END;
/

DECLARE 
    e_table_or_view_dosent_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_table_or_view_dosent_exist, -00942);
    l_table_name VARCHAR2(30) := 'tl_vertical_axis';                                      
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE ' || l_table_name;
EXCEPTION
    WHEN e_table_or_view_dosent_exist THEN
        dbms_output.put_line('WARNING - Table ' || l_table_name || ' already droped in previous version.');
END;
/

DECLARE 
    e_invalid_identifier EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_invalid_identifier, -00904);
    l_table_name VARCHAR2(30) := 'tl_software';                                      
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE ' || l_table_name || ' DROP COLUMN rank';
EXCEPTION
    WHEN e_invalid_identifier THEN
        dbms_output.put_line('WARNING - Rank column on table ' || l_table_name || ' already droped in previous version.');
END;
/

DECLARE 
    e_invalid_identifier EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_invalid_identifier, -00904);
    l_table_name VARCHAR2(30) := 'tl_scale';                                      
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE ' || l_table_name || ' DROP COLUMN rank';
EXCEPTION
    WHEN e_invalid_identifier THEN
        dbms_output.put_line('WARNING - Rank column on table ' || l_table_name || ' already created in previous version.');
END;
/
-- CHANGE END: Rui Duarte


-- CHANGED BY: Ana Matos
-- CHANGE DATE: 02-Dez-2010
-- CHANGE REASON: [ALERT-123272] 
alter table lab_tests_ea drop constraint LTA_FLG_STATUS_REQ_CHK;
/

alter table ANALYSIS_REQ add constraint ARQ_FLG_STATUS_CHK check (FLG_STATUS IN ('X', 'D', 'R', 'E', 'P', 'F', 'C'));
/

alter table LAB_TESTS_EA add constraint LTA_FLG_STATUS_REQ_CHK check (FLG_STATUS_REQ IN ('X', 'D', 'R', 'E', 'P', 'F', 'C'));
/

-- CHANGE END: Ana Matos




-- CHANGED BY:  Filipe Sousa
-- CHANGE DATE: 02/12/2010 11:55
-- CHANGE REASON: [ALERT-146257] A rede de referenciação inter-hositalar deverá suportar que uma instituição seja destino dentro e fora da rede de referenciação conforme a especialidade em causa. (ALERT142962)
begin
Insert Into Ref_Dest_Institution_Spec
(Id_Dest_Institution_Spec,
Id_Dest_Institution,
Id_Speciality,
Flg_Available,
Flg_Inside_Ref_Area)
(Select
Seq_Ref_Dest_Institution_Spec.Nextval,
Id_Dest_Institution,
Id_Speciality,
Flg_Available,
Flg_Inside_Ref_Area
from(
Select Distinct
Pdi.Id_Dest_Institution ,
Ps.Id_Speciality,
Nvl((Select 'N' From P1_Dest_Institution_Deny Dn Where Pdi.Id_Inst_Orig = Dn.Id_Inst_Orig And Pdi.Id_Inst_Dest = Dn.Id_Inst_Dest And Dn.Id_Speciality =Ps.Id_Speciality),'Y')
Flg_Available,
nvl(Pdi.Flg_Inside_Ref_Area,'N') Flg_Inside_Ref_Area
FROM p1_speciality         ps,
p1_spec_dep_clin_serv sdcs,
dep_clin_serv         dcs,
department            dpt,
p1_dest_institution   pdi,
Institution           Ist
WHERE ps.id_speciality = sdcs.id_speciality
And Sdcs.Id_Dep_Clin_Serv = Dcs.Id_Dep_Clin_Serv
AND dcs.id_department = dpt.id_department
And Dpt.Id_Institution = Pdi.Id_Inst_Dest
And Ist.Id_Institution = Dpt.Id_Institution));
end;
/
-- CHANGE END:  Filipe Sousa

-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 14/12/2010 11:35
-- CHANGE REASON: [ALERT-146495] 
--supply_sup_area
insert into alert.supply_sup_area (id_supply_soft_inst,id_supply_area,flg_available)
select ssi.id_supply_soft_inst, decode((select s.flg_type from alert.supply s where s.id_supply=ssi.id_supply),'M',2,1) id_supply_area,'Y' from alert.supply_soft_inst ssi;

--supply_workflow
update alert.supply_workflow sw
set sw.id_supply_area=decode((select s.flg_type from alert.supply s where s.id_supply=sw.id_supply),'M',2,1)
where sw.id_supply_area is null; 

ALTER TABLE supply_workflow MODIFY id_supply_area NOT NULL;

--supply_workflow_hist
update alert.supply_workflow_hist sw
set sw.id_supply_area=decode((select s.flg_type from alert.supply s where s.id_supply=sw.id_supply),'M',2,1)
where sw.id_supply_area is null;

ALTER TABLE supply_workflow_hist MODIFY id_supply_area NOT NULL;
-- CHANGE END: Filipe Silva

-- CHANGED BY: Filipe Silva
-- CHANGE DATE: 14/12/2010 16:30
-- CHANGE REASON: [ALERT-146495] 
alter table SUPPLY_SUP_AREA drop COLUMN ID_SUPPLY_SUP_AREA;
drop sequence SEQ_SUPPLY_SUP_AREA;
drop index SSA_ISA_FK_IDX;
alter table supply_sup_area add constraint SSA_UK unique (ID_SUPPLY_AREA,ID_SUPPLY_SOFT_INST);

--supply_sup_area
insert into alert.supply_sup_area (id_supply_soft_inst,id_supply_area,flg_available)
select ssi.id_supply_soft_inst, decode((select s.flg_type from alert.supply s where s.id_supply=ssi.id_supply),'M',2,1) id_supply_area,'Y' from alert.supply_soft_inst ssi;

--supply_workflow
update alert.supply_workflow sw
set sw.id_supply_area=decode((select s.flg_type from alert.supply s where s.id_supply=sw.id_supply),'M',2,1)
where sw.id_supply_area is null; 

ALTER TABLE supply_workflow MODIFY id_supply_area NOT NULL;

--supply_workflow_hist
update alert.supply_workflow_hist sw
set sw.id_supply_area=decode((select s.flg_type from alert.supply s where s.id_supply=sw.id_supply),'M',2,1)
where sw.id_supply_area is null;

ALTER TABLE supply_workflow_hist MODIFY id_supply_area NOT NULL;
-- CHANGE END: Filipe Silva

-- CHANGED BY: Pedro Martins Santos
-- CHANGE DATE: 09/02/2011
-- CHANGE REASON: [ALERT-156592] 
drop type T_REC_PHARM_PEND force;

CREATE or replace TYPE T_REC_PHARM_PEND as object
(
  id_patient number(24),
  id_episode number(24),
  flg_type varchar2(1),
  id_state number(24),
  dt_req timestamp(6) with local time zone
);
/

drop type T_REC_PHARM_ADM_INT force;

CREATE OR REPLACE TYPE T_REC_PHARM_ADM_INT as object
(
  id_patient number(24),
  id_episode number(24),
  flg_type varchar2(1),
  id_state number(24),
  has_notes number(6),
  dt_req timestamp(6) with local time zone
);
/

drop type T_REC_PHARM_STATE_DT force;

CREATE OR REPLACE TYPE T_REC_PHARM_STATE_DT as object
(
  state		number(24),
  dt_state	timestamp
);
/

drop type T_REC_PHARM_STATE_DT_RANK force;

CREATE OR REPLACE TYPE T_REC_PHARM_STATE_DT_RANK as object
(
  id_state	number(24),
  dt_state	timestamp,
  rank		number(3)
);
/
-- CHANGE END: Pedro Martins Santos

-- CHANGED BY: Ana Matos
-- CHANGE DATE: 16/02/2011 15:03
-- CHANGE REASON: [ALERT-41171] 
begin
dbms_errlog.create_error_log(dml_table_name => 'EXAMS_EA', skip_unsupported => true);
end;
/

begin
dbms_errlog.create_error_log(dml_table_name => 'LAB_TESTS_EA', skip_unsupported => true);
end;
/

DROP TYPE t_table_rec_analysis_result;
/

CREATE OR REPLACE TYPE t_rec_analysis_result AS OBJECT
(
    type_rec                    VARCHAR2(1),
    desc_param                  VARCHAR2(4000),
    dt_analysis_result_par      VARCHAR2(4000),
    date_analysis_result_par    VARCHAR2(4000),
    hour_analysis_result_par    VARCHAR2(4000),
    desc_analysis_result        CLOB,
    rank_type                   NUMBER(6),
    abnorm                      VARCHAR2(4000),
    ref_val                     VARCHAR2(200),
    desc_unit_measure           VARCHAR2(200),
    id_analysis                 NUMBER(12),
    id_analysis_parameter       NUMBER(24),
    desc_epi_ant                VARCHAR2(500),
    abbrev_lab                  VARCHAR2(30),
    intf_notes                  CLOB,
    desc_lab                    VARCHAR2(200),
    prof_nickname               VARCHAR2(200),
    arp_status                  VARCHAR2(1),
    id_analysis_req_par         NUMBER(24),
    dt_analysis_result_par_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE,
    abnorm_color                VARCHAR2(30),
    rank_labtest                NUMBER(6),
    rank_labtest_param          NUMBER(6),
    id_analysis_req_det         NUMBER(24),
    desc_abnormality            VARCHAR2(4000),
    result_status               VARCHAR2(1),
    result_comments             CLOB,
    id_result                   VARCHAR2(4000),
    dt_ins_result_tstz          TIMESTAMP(6) WITH LOCAL TIME ZONE,
    res_status_desc             VARCHAR2(200 char),
    ref_val_min                 NUMBER(24,3),
    ref_val_max                 NUMBER(24,3),
    id_analysis_param           NUMBER(12),
    flg_exam_cat                VARCHAR2(1)
);
/

CREATE OR REPLACE TYPE t_table_rec_analysis_result AS TABLE OF t_rec_analysis_result;
/
-- CHANGE END: Ana Matos


-- CHANGED BY: Sofia Mendes
-- CHANGE DATE: 21/01/2011 09:32
-- CHANGE REASON: [ALERT-153427 ] Intake and Output-Have the 
update hidrics_charact_rel h
set h.id_market = 0
where h.id_market is null;

update HIDRICS_CONFIGURATIONS h
set h.id_market = 0
where h.id_market is null;

update hidrics_way_rel h
set h.id_market = 0
where h.id_market is null;

update hidrics_location_rel h
set h.id_market = 0
where h.id_market is null;
-- CHANGE END: Sofia Mendes

-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 28/02/2011 15:40
-- CHANGE REASON: [ALERT-164831] drop unused packages
drop package alert.pk_progress_notes_cfg;
drop package alert.ts_pn_prof_free_text_cfg;
drop package alert.ts_pn_prof_soap_button;
drop package alert.ts_pn_soap_block;
drop package alert.ts_pn_soap_block_cfg;
drop package alert.ts_pn_soap_button_rel;
drop package alert.ts_pn_soap_data_rel;
-- CHANGE END: Pedro Carneiro

-- CHANGED BY: António Neto
-- CHANGE DATE: 15/03/2011 11:19
-- CHANGE REASON: [ALERT-161712] INP - Bed management - The number of occupied beds on the different views don't match.
begin
  pk_data_gov_admin.admin_70_all_bmng_tables;
EXCEPTION
        WHEN others THEN
				     dbms_output.put_line('ERRO: ' || SQLERRM);
end;
/
-- CHANGE END: António Neto

-- CHANGED BY: António Neto
-- CHANGE DATE: 16/03/2011 09:58
-- CHANGE REASON: [ALERT-161712] INP - Bed management - The number of occupied beds on the different views don't match.
begin
  pk_data_gov_admin.admin_70_all_bmng_tables;
EXCEPTION
        WHEN others THEN
				     dbms_output.put_line('ERRO: ' || SQLERRM);
end;
/
-- CHANGE END: António Neto

-- CHANGED BY: Ricardo Pires
-- CHANGE DATE: 15/04/2011 15:50
-- CHANGE REASON: [ALERT-173203] Primary Keys
--REP_UNIQUE_IDENTIFIER_EXCEP
ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP DROP CONSTRAINT RUIE_FLG_REP_TYPE_CHK;

ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP
  ADD CONSTRAINT RUIE_FLG_REP_TYPE_CHK
  CHECK (FLG_REPORT_TYPE IN ('C','D','S','REQUISITION','E','CONSENT','P','CM', 'CERTIFICATE','U')) VALIDATE;

BEGIN
 UPDATE REP_UNIQUE_IDENTIFIER_EXCEP SET FLG_REPORT_TYPE='U' where FLG_REPORT_TYPE is null;
END;
/

COMMENT ON COLUMN REP_UNIQUE_IDENTIFIER_EXCEP.FLG_REPORT_TYPE IS 'Flag that indicates the type of the report (U-Unavailable)';
ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP MODIFY FLG_REPORT_TYPE DEFAULT 'U';
ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP ADD CONSTRAINT RUIE_PK PRIMARY KEY (REP_UNIQUE_IDENTIFIER, FLG_REPORT_TYPE, ID_REPORTS,ID_SOFTWARE,ID_INSTITUTION,ID_MARKET);

--REP_RULE_REL
ALTER TABLE REP_RULE_REL DROP CONSTRAINT RRR_FLG_REP_TYPE_CHK;

ALTER TABLE REP_RULE_REL
  ADD CONSTRAINT RRR_FLG_REP_TYPE_CHK
  CHECK (FLG_REPORT_TYPE IN ('C','D','S','REQUISITION','E','CONSENT','P','CM', 'CERTIFICATE','U')) VALIDATE;

BEGIN
 UPDATE REP_RULE_REL SET FLG_REPORT_TYPE='U' where FLG_REPORT_TYPE is null;
END;
/


COMMENT ON COLUMN REP_RULE_REL.FLG_REPORT_TYPE IS 'Flag that indicates the type of the report (U-Unavailable)';
ALTER TABLE REP_RULE_REL MODIFY FLG_REPORT_TYPE DEFAULT 'U';
ALTER TABLE REP_RULE_REL ADD CONSTRAINT RRR_PK PRIMARY KEY (ID_REP_RULE,ID_REP_SECTION, FLG_REPORT_TYPE, ID_REPORTS,ID_SOFTWARE,ID_INSTITUITON,ID_MARKET);

--REP_LAYOUT_REL
ALTER TABLE REP_LAYOUT_REL DROP CONSTRAINT RLL_FLG_REP_TYPE_CHK;

ALTER TABLE REP_LAYOUT_REL
  ADD CONSTRAINT RLL_FLG_REP_TYPE_CHK
  CHECK (FLG_REPORT_TYPE IN ('C','D','S','REQUISITION','E','CONSENT','P','CM', 'CERTIFICATE','U')) VALIDATE;

BEGIN
 UPDATE REP_LAYOUT_REL SET FLG_REPORT_TYPE='U' where FLG_REPORT_TYPE is null;
END;
/

COMMENT ON COLUMN REP_LAYOUT_REL.FLG_REPORT_TYPE IS 'Flag that indicates the type of the report (U-Unavailable)';
ALTER TABLE REP_LAYOUT_REL MODIFY FLG_REPORT_TYPE DEFAULT 'U';
ALTER TABLE REP_LAYOUT_REL ADD CONSTRAINT RLR_PK PRIMARY KEY (ID_REP_LAYOUT,ID_REP_SECTION, FLG_REPORT_TYPE, ID_REPORTS,ID_SOFTWARE,ID_INSTITUTION,ID_MARKET);
/
-- CHANGE END: Ricardo Pires


-- CHANGED BY: Ricardo Pires
-- CHANGE DATE: 15/04/2011 15:50
-- CHANGE REASON: [ALERT-173203] Primary Keys
BEGIN
 UPDATE REP_UNIQUE_IDENTIFIER_EXCEP SET FLG_REPORT_TYPE=null where FLG_REPORT_TYPE='U';
END;
/

BEGIN
 UPDATE REP_RULE_REL SET FLG_REPORT_TYPE=null where FLG_REPORT_TYPE='U';
END;
/

BEGIN
 UPDATE REP_LAYOUT_REL SET FLG_REPORT_TYPE=null where FLG_REPORT_TYPE='U';
END;
/
        
BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 229
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_001';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '229', 'Y', 0, null, 'UX_IMG_EXAM_001');
END; 
/ 

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 229
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_002';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '229', 'Y', 0, null, 'UX_IMG_EXAM_002');
END; 
/ 
  

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 229
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_004';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '229', 'Y', 0, null, 'UX_OTHER_EXAM_004');
END; 
/   

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_001';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_IMG_EXAM_001');
END; 
/  

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_002';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_IMG_EXAM_002');
END; 
/  

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_004';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_IMG_EXAM_004');
END; 
/

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_005';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_IMG_EXAM_005');
END; 
/

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_001';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_OTHER_EXAM_001');
END; 
/  

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_002';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_OTHER_EXAM_002');
END; 
/ 


BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_004';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_OTHER_EXAM_004');
END; 
/ 

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_005';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_OTHER_EXAM_005');
END; 
/ 

--------------------------


ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP DROP CONSTRAINT RUIE_FLG_REP_TYPE_CHK;

ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP
  ADD CONSTRAINT RUIE_FLG_REP_TYPE_CHK
  CHECK (FLG_REPORT_TYPE IN ('C','D','S','REQUISITION','E','CONSENT','P','CM', 'CERTIFICATE','U')) VALIDATE;

BEGIN
 UPDATE REP_UNIQUE_IDENTIFIER_EXCEP SET FLG_REPORT_TYPE='U' where FLG_REPORT_TYPE is null;
END;
/

COMMENT ON COLUMN REP_UNIQUE_IDENTIFIER_EXCEP.FLG_REPORT_TYPE IS 'Flag that indicates the type of the report (U-Unavailable)';
ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP MODIFY FLG_REPORT_TYPE DEFAULT 'U';
ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP ADD CONSTRAINT RUIE_PK PRIMARY KEY (REP_UNIQUE_IDENTIFIER, FLG_REPORT_TYPE, ID_REPORTS,ID_SOFTWARE,ID_INSTITUTION,ID_MARKET);

--REP_RULE_REL
ALTER TABLE REP_RULE_REL DROP CONSTRAINT RRR_FLG_REP_TYPE_CHK;

ALTER TABLE REP_RULE_REL
  ADD CONSTRAINT RRR_FLG_REP_TYPE_CHK
  CHECK (FLG_REPORT_TYPE IN ('C','D','S','REQUISITION','E','CONSENT','P','CM', 'CERTIFICATE','U')) VALIDATE;

BEGIN
 UPDATE REP_RULE_REL SET FLG_REPORT_TYPE='U' where FLG_REPORT_TYPE is null;
END;
/


COMMENT ON COLUMN REP_RULE_REL.FLG_REPORT_TYPE IS 'Flag that indicates the type of the report (U-Unavailable)';
ALTER TABLE REP_RULE_REL MODIFY FLG_REPORT_TYPE DEFAULT 'U';
ALTER TABLE REP_RULE_REL ADD CONSTRAINT RRR_PK PRIMARY KEY (ID_REP_RULE,ID_REP_SECTION, FLG_REPORT_TYPE, ID_REPORTS,ID_SOFTWARE,ID_INSTITUTION,ID_MARKET);

--REP_LAYOUT_REL
ALTER TABLE REP_LAYOUT_REL DROP CONSTRAINT RLL_FLG_REP_TYPE_CHK;

ALTER TABLE REP_LAYOUT_REL
  ADD CONSTRAINT RLL_FLG_REP_TYPE_CHK
  CHECK (FLG_REPORT_TYPE IN ('C','D','S','REQUISITION','E','CONSENT','P','CM', 'CERTIFICATE','U')) VALIDATE;

BEGIN
 UPDATE REP_LAYOUT_REL SET FLG_REPORT_TYPE='U' where FLG_REPORT_TYPE is null;
END;
/

COMMENT ON COLUMN REP_LAYOUT_REL.FLG_REPORT_TYPE IS 'Flag that indicates the type of the report (U-Unavailable)';
ALTER TABLE REP_LAYOUT_REL MODIFY FLG_REPORT_TYPE DEFAULT 'U';
ALTER TABLE REP_LAYOUT_REL ADD CONSTRAINT RLR_PK PRIMARY KEY (ID_REP_LAYOUT,ID_REP_SECTION, FLG_REPORT_TYPE, ID_REPORTS,ID_SOFTWARE,ID_INSTITUTION,ID_MARKET);
/
-- CHANGE END: Ricardo Pires

-- CHANGED BY: Ricardo Pires
-- CHANGE DATE: 26/04/2011 16:50
-- CHANGE REASON: [ALERT-173203] Primary Keys
BEGIN
 UPDATE REP_UNIQUE_IDENTIFIER_EXCEP SET FLG_REPORT_TYPE=null where FLG_REPORT_TYPE='U';
END;
/

BEGIN
 UPDATE REP_RULE_REL SET FLG_REPORT_TYPE=null where FLG_REPORT_TYPE='U';
END;
/

BEGIN
 UPDATE REP_LAYOUT_REL SET FLG_REPORT_TYPE=null where FLG_REPORT_TYPE='U';
END;
/
        
BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 229
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_001';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '229', 'Y', 0, null, 'UX_IMG_EXAM_001');
END; 
/ 

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 229
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_002';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '229', 'Y', 0, null, 'UX_IMG_EXAM_002');
END; 
/ 
  
BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 229
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_001';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '229', 'Y', 0, null, 'UX_OTHER_EXAM_001');
END; 
/  

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 229
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_002';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '229', 'Y', 0, null, 'UX_OTHER_EXAM_002');
END; 
/  

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 229
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_004';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '229', 'Y', 0, null, 'UX_OTHER_EXAM_004');
END; 
/   

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_001';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_IMG_EXAM_001');
END; 
/  

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_002';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_IMG_EXAM_002');
END; 
/  

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_004';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_IMG_EXAM_004');
END; 
/

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 229
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_004';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '229', 'Y', 0, null, 'UX_IMG_EXAM_004');
END; 
/

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_IMG_EXAM_005';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_IMG_EXAM_005');
END; 
/

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_001';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_OTHER_EXAM_001');
END; 
/  

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_002';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_OTHER_EXAM_002');
END; 
/ 


BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_004';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_OTHER_EXAM_004');
END; 
/ 

BEGIN
   DELETE FROM rep_unique_identifier_excep
    WHERE id_institution = 0
      AND id_software = 0
      AND id_reports = 230
      AND id_market = 0
      AND flg_report_type is null
      AND rep_unique_identifier = 'UX_OTHER_EXAM_005';

  INSERT INTO rep_unique_identifier_excep
      (id_institution,
       id_software,
       id_reports,
       flg_exclude,
       id_market,
       flg_report_type,
       rep_unique_identifier)
  VALUES
      (0, 0, '230', 'Y', 0, null, 'UX_OTHER_EXAM_005');
END; 
/ 

ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP DROP CONSTRAINT RUIE_FLG_REP_TYPE_CHK;

ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP
  ADD CONSTRAINT RUIE_FLG_REP_TYPE_CHK
  CHECK (FLG_REPORT_TYPE IN ('C','D','S','REQUISITION','E','CONSENT','P','CM', 'CERTIFICATE','U')) VALIDATE;

BEGIN
 UPDATE REP_UNIQUE_IDENTIFIER_EXCEP SET FLG_REPORT_TYPE='U' where FLG_REPORT_TYPE is null;
END;
/

COMMENT ON COLUMN REP_UNIQUE_IDENTIFIER_EXCEP.FLG_REPORT_TYPE IS 'Flag that indicates the type of the report (U-Unavailable)';
ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP MODIFY FLG_REPORT_TYPE DEFAULT 'U';
ALTER TABLE REP_UNIQUE_IDENTIFIER_EXCEP ADD CONSTRAINT RUIE_PK PRIMARY KEY (REP_UNIQUE_IDENTIFIER, FLG_REPORT_TYPE, ID_REPORTS,ID_SOFTWARE,ID_INSTITUTION,ID_MARKET);

--REP_RULE_REL
ALTER TABLE REP_RULE_REL DROP CONSTRAINT RRR_FLG_REP_TYPE_CHK;

ALTER TABLE REP_RULE_REL
  ADD CONSTRAINT RRR_FLG_REP_TYPE_CHK
  CHECK (FLG_REPORT_TYPE IN ('C','D','S','REQUISITION','E','CONSENT','P','CM', 'CERTIFICATE','U')) VALIDATE;

BEGIN
 UPDATE REP_RULE_REL SET FLG_REPORT_TYPE='U' where FLG_REPORT_TYPE is null;
END;
/


COMMENT ON COLUMN REP_RULE_REL.FLG_REPORT_TYPE IS 'Flag that indicates the type of the report (U-Unavailable)';
ALTER TABLE REP_RULE_REL MODIFY FLG_REPORT_TYPE DEFAULT 'U';
ALTER TABLE REP_RULE_REL ADD CONSTRAINT RRR_PK PRIMARY KEY (ID_REP_RULE,ID_REP_SECTION, FLG_REPORT_TYPE, ID_REPORTS,ID_SOFTWARE,ID_INSTITUTION,ID_MARKET);

--REP_LAYOUT_REL
ALTER TABLE REP_LAYOUT_REL DROP CONSTRAINT RLL_FLG_REP_TYPE_CHK;

ALTER TABLE REP_LAYOUT_REL
  ADD CONSTRAINT RLL_FLG_REP_TYPE_CHK
  CHECK (FLG_REPORT_TYPE IN ('C','D','S','REQUISITION','E','CONSENT','P','CM', 'CERTIFICATE','U')) VALIDATE;

BEGIN
 UPDATE REP_LAYOUT_REL SET FLG_REPORT_TYPE='U' where FLG_REPORT_TYPE is null;
END;
/

COMMENT ON COLUMN REP_LAYOUT_REL.FLG_REPORT_TYPE IS 'Flag that indicates the type of the report (U-Unavailable)';
ALTER TABLE REP_LAYOUT_REL MODIFY FLG_REPORT_TYPE DEFAULT 'U';
ALTER TABLE REP_LAYOUT_REL ADD CONSTRAINT RLR_PK PRIMARY KEY (ID_REP_LAYOUT,ID_REP_SECTION, FLG_REPORT_TYPE, ID_REPORTS,ID_SOFTWARE,ID_INSTITUTION,ID_MARKET);
/
-- CHANGE END: Ricardo Pires

-- CHANGED BY: Pedro Carneiro
-- CHANGE DATE: 12/03/2012 15:29
-- CHANGE REASON: [ALERT-215533] drop unused objects
declare
  e_no_obj exception;
  pragma exception_init(e_no_obj, -04043);
begin
  begin
    execute immediate 'drop package pk_backoffice_ent_rel';
  exception when e_no_obj then
    dbms_output.put_line('package pk_backoffice_ent_rel does not exist!');
  end;
  begin
    execute immediate 'drop package pk_ent_rel';
  exception when e_no_obj then
    dbms_output.put_line('package pk_ent_rel does not exist!');
  end;
  begin
    execute immediate 'drop type t_entity_relation_param';
  exception when e_no_obj then
    dbms_output.put_line('type t_entity_relation_param does not exist!');
  end;
end;
/
-- CHANGE END: Pedro Carneiro

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 03/05/2016 08:58
-- CHANGE REASON: [ALERT-320563] 
DELETE FROM vital_sign_unit_measure vsum
 WHERE vsum.id_vital_sign_unit_measure IN
       (SELECT aux.id_vital_sign_unit_measure
          FROM (SELECT b.id_vital_sign_unit_measure,
                       tt.id_vital_sign,
                       tt.id_software,
                       tt.id_institution,
                       tt.id_unit_measure,
                       tt.age_min,
                       tt.age_max,
                       row_number() over(PARTITION BY tt.id_vital_sign, tt.id_software, tt.id_institution, tt.id_unit_measure, tt.age_min, tt.age_max ORDER BY b.id_vital_sign_unit_measure DESC) rn
                  FROM (SELECT t.id_vital_sign, t.id_software, t.id_institution, t.id_unit_measure, t.age_min, t.age_max
                          FROM (SELECT a.id_vital_sign,
                                       a.id_software,
                                       a.id_institution,
                                       a.id_unit_measure,
                                       a.age_min,
                                       a.age_max,
                                       COUNT(1) c
                                  FROM vital_sign_unit_measure a
                                 GROUP BY a.id_vital_sign,
                                          a.id_software,
                                          a.id_institution,
                                          a.id_unit_measure,
                                          a.age_min,
                                          a.age_max) t
                         WHERE t.c > 1) tt
                  JOIN vital_sign_unit_measure b
                    ON b.id_vital_sign = tt.id_vital_sign
                   AND b.id_software = tt.id_software
                   AND b.id_institution = tt.id_institution
                   AND (b.id_unit_measure = tt.id_unit_measure OR
                       (b.id_unit_measure IS NULL AND tt.id_unit_measure IS NULL))
                   AND (b.age_min = tt.age_min OR (b.age_min IS NULL AND tt.age_min IS NULL))
                   AND (b.age_max = tt.age_max OR (b.age_max IS NULL AND tt.age_max IS NULL))) aux
         WHERE aux.rn <> 1);


DECLARE
    e_unique_already_there EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_unique_already_there, -02261);
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'alter table vital_sign_unit_measure add constraint vsum_uk unique (ID_VITAL_SIGN,  ID_SOFTWARE, ID_INSTITUTION, id_unit_measure,AGE_MIN,age_max)  ';
    EXCEPTION
        WHEN e_unique_already_there THEN
            dbms_output.put_line('Key already there');
    END;
END;
/

DELETE FROM vs_soft_inst vsi
 WHERE vsi.id_vs_soft_inst IN
       (SELECT aux.id_vs_soft_inst
          FROM (SELECT b.id_vs_soft_inst,
                       tt.id_institution,
                       tt.id_software,
                       tt.id_vital_sign,
                       tt.flg_view,
                       row_number() over(PARTITION BY tt.id_institution, tt.id_software, tt.id_vital_sign, tt.flg_view ORDER BY b.id_vs_soft_inst DESC) rn
                  FROM (SELECT t.id_institution, t.id_software, t.id_vital_sign, t.flg_view
                          FROM (SELECT a.id_institution, a.id_software, a.id_vital_sign, a.flg_view, COUNT(1) c
                                  FROM vs_soft_inst a
                                 GROUP BY a.id_institution, a.id_software, a.id_vital_sign, a.flg_view) t
                         WHERE t.c > 1) tt
                  JOIN vs_soft_inst b
                    ON b.id_institution = tt.id_institution
                   AND b.id_software = tt.id_software
                   AND b.id_vital_sign = tt.id_vital_sign
                   AND b.flg_view = tt.flg_view) aux
         WHERE aux.rn <> 1);


DECLARE
    e_unique_already_there EXCEPTION;
    PRAGMA EXCEPTION_INIT(e_unique_already_there, -02261);
BEGIN
    BEGIN
        EXECUTE IMMEDIATE 'alter table vs_soft_inst add constraint vssi_uk1 unique (ID_VITAL_SIGN,  ID_SOFTWARE, ID_INSTITUTION, FLG_VIEW)  ';
    EXCEPTION
        WHEN e_unique_already_there THEN
            dbms_output.put_line('Key already there');
    END;
END;
/         
-- CHANGE END: Paulo Teixeira

-- CHANGED BY: Pedro Henriques
-- CHANGE DATE: 09/07/2018 09:00
-- CHANGE REASON: [EMR-4796] 
begin
    for i in ( 
        select owner, index_name
        from dba_indexes
        where table_owner like  'ALERT%'
        and status = 'UNUSABLE'
    )
    loop
		   begin
        execute immediate ('alter index '||i.owner||'.'||i.index_name||' rebuild');
			 exception when others then 
			   null;
			 end;
    end loop;
end;
/
-- CHANGE END: Pedro Henriques