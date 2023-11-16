CREATE OR REPLACE VIEW V_EXAM_DEP_CLIN_SERV AS
SELECT edcs.id_exam_dep_clin_serv, 
       edcs.id_exam, 
       edcs.id_dep_clin_serv, 
       edcs.flg_type,
       edcs.id_exam_group, 
       edcs.id_institution, 
       edcs.id_software,
	   edcs.rank,
	   edcs.flg_first_result,
       edcs.flg_mov_pat,
       edcs.cost,
       edcs.price,
       edcs.id_external_sys,
       edcs.flg_execute,
       edcs.flg_timeout,
       edcs.flg_result_notes,
       edcs.flg_first_execute,
       edcs.flg_chargeable,
	   edcs.id_professional
  from exam_dep_clin_serv edcs;
  
-- CHANGED BY: Howard Cheng
-- CHANGE DATE: 2018-05-29
-- CHANGE REASON: [CEMR-1590] [Subtask] [CNT] DB alert_core_cnt_api.pk_cnt_api.exam and alert_core_cnt.pk_cnt_exam
CREATE OR REPLACE VIEW V_EXAM_DEP_CLIN_SERV AS
SELECT edcs.id_exam_dep_clin_serv,
       edcs.id_exam,
       edcs.id_dep_clin_serv,
       edcs.flg_type,
       edcs.id_exam_group,
       edcs.id_institution,
       edcs.id_software,
	   edcs.rank,
	   edcs.flg_first_result,
       edcs.flg_mov_pat,
       edcs.cost,
       edcs.price,
       edcs.id_external_sys,
       edcs.flg_execute,
       edcs.flg_timeout,
       edcs.flg_result_notes,
       edcs.flg_first_execute,
       edcs.flg_chargeable,
	   edcs.id_professional
  from exam_dep_clin_serv edcs;
-- CHANGE END:Howard Cheng