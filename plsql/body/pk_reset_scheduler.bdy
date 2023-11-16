/*-- Last Change Revision: $Rev: 2027637 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_reset_scheduler AS

    -- Local package constants
    SUBTYPE obj_name IS VARCHAR2(30);

    c_package_owner CONSTANT obj_name := 'ALERT';
    c_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();

    /**********************************************************************************************
    * This PROCEDURE deletes/updates tables related with the schedulers on the schema ALERT
    *
    * @param i_scheduler_ids                 ID_SCHEDULER table_number
    *
    *
    * @author                                Ruben Araujo
    * @version                               1.0
    * @since                                 2016/05/17
    **********************************************************************************************/

    PROCEDURE reset_sch_alert(i_scheduler_ids IN table_number) IS
    
    BEGIN
    
        ------ Nº 1---------------------------------------------------
    
        UPDATE audit_req_comment
           SET id_audit_quest_answer = NULL
         WHERE id_audit_quest_answer IN
               (SELECT id_audit_quest_answer
                  FROM audit_quest_answer
                 WHERE id_audit_req_prof_epis IN
                       (SELECT id_audit_req_prof_epis
                          FROM audit_req_prof_epis
                         WHERE id_epis_triage IN
                               (SELECT id_epis_triage
                                  FROM epis_triage
                                 WHERE id_transportation IN
                                       (SELECT id_transportation
                                          FROM transportation
                                         WHERE id_transp_req IN
                                               (SELECT id_transp_req
                                                  FROM transp_req
                                                 WHERE id_consult_req IN
                                                       (SELECT id_consult_req
                                                          FROM consult_req
                                                         WHERE id_schedule IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule_ref IN
                                                                       (SELECT id_schedule
                                                                          FROM schedule
                                                                         WHERE id_schedule IN
                                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                                 column_value
                                                                                  FROM TABLE(i_scheduler_ids) t)))))))));
    
        ------ Nº 2---------------------------------------------------
    
        UPDATE vs_read_hist_attribute
           SET id_vital_sign_read_hist = NULL
         WHERE id_vital_sign_read_hist IN
               (SELECT id_vital_sign_read_hist
                  FROM vital_sign_read_hist
                 WHERE id_vital_sign_read IN
                       (SELECT id_vital_sign_read
                          FROM vital_sign_read
                         WHERE id_epis_triage IN
                               (SELECT id_epis_triage
                                  FROM epis_triage
                                 WHERE id_transportation IN
                                       (SELECT id_transportation
                                          FROM transportation
                                         WHERE id_transp_req IN
                                               (SELECT id_transp_req
                                                  FROM transp_req
                                                 WHERE id_consult_req IN
                                                       (SELECT id_consult_req
                                                          FROM consult_req
                                                         WHERE id_schedule IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule_ref IN
                                                                       (SELECT id_schedule
                                                                          FROM schedule
                                                                         WHERE id_schedule IN
                                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                                 column_value
                                                                                  FROM TABLE(i_scheduler_ids) t)))))))));
    
        ------ Nº 3---------------------------------------------------
    
        UPDATE audit_req_comment
           SET id_audit_quest_answer = NULL
         WHERE id_audit_quest_answer IN
               (SELECT id_audit_quest_answer
                  FROM audit_quest_answer
                 WHERE id_audit_req_prof_epis IN
                       (SELECT id_audit_req_prof_epis
                          FROM audit_req_prof_epis
                         WHERE id_epis_triage IN
                               (SELECT id_epis_triage
                                  FROM epis_triage
                                 WHERE id_transportation IN
                                       (SELECT id_transportation
                                          FROM transportation
                                         WHERE id_transp_req IN
                                               (SELECT id_transp_req
                                                  FROM transp_req
                                                 WHERE id_consult_req IN
                                                       (SELECT id_consult_req
                                                          FROM consult_req
                                                         WHERE id_schedule IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule_ref IN
                                                                       (SELECT id_schedule
                                                                          FROM schedule
                                                                         WHERE id_schedule IN
                                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                                 column_value
                                                                                  FROM TABLE(i_scheduler_ids) t)))))))));
    
        ------ Nº 5---------------------------------------------------
    
        UPDATE exam_res_fetus_biom_img
           SET id_exam_res_fetus_biom = NULL
         WHERE id_exam_res_fetus_biom IN
               (SELECT id_exam_res_fetus_biom
                  FROM exam_res_fetus_biom
                 WHERE id_exam_res_pregn_fetus IN
                       (SELECT id_exam_res_pregn_fetus
                          FROM exam_res_pregn_fetus
                         WHERE id_exam_result_pregnancy IN
                               (SELECT id_exam_result_pregnancy
                                  FROM exam_result_pregnancy
                                 WHERE id_exam_result IN
                                       (SELECT id_exam_result
                                          FROM exam_result
                                         WHERE id_exam_req_det IN
                                               (SELECT id_exam_req_det
                                                  FROM exam_req_det
                                                 WHERE id_exam_req IN
                                                       (SELECT id_exam_req
                                                          FROM exam_req
                                                         WHERE id_sched_consult IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule_ref IN
                                                                       (SELECT id_schedule
                                                                          FROM schedule
                                                                         WHERE id_schedule IN
                                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                                 column_value
                                                                                  FROM TABLE(i_scheduler_ids) t)))))))));
    
        ------ Nº 6---------------------------------------------------
    
        UPDATE exam_res_fetus_biom_img
           SET id_exam_res_fetus_biom = NULL
         WHERE id_exam_res_fetus_biom IN
               (SELECT id_exam_res_fetus_biom
                  FROM exam_res_fetus_biom
                 WHERE id_exam_res_pregn_fetus IN
                       (SELECT id_exam_res_pregn_fetus
                          FROM exam_res_pregn_fetus
                         WHERE id_exam_result_pregnancy IN
                               (SELECT id_exam_result_pregnancy
                                  FROM exam_result_pregnancy
                                 WHERE id_exam_result IN
                                       (SELECT id_exam_result
                                          FROM exam_result
                                         WHERE id_exam_req_det IN
                                               (SELECT id_exam_req_det
                                                  FROM exam_req_det
                                                 WHERE id_exam_req IN
                                                       (SELECT id_exam_req
                                                          FROM exam_req
                                                         WHERE id_schedule IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule_ref IN
                                                                       (SELECT id_schedule
                                                                          FROM schedule
                                                                         WHERE id_schedule IN
                                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                                 column_value
                                                                                  FROM TABLE(i_scheduler_ids) t)))))))));
    
        ------ Nº 8---------------------------------------------------
    
        UPDATE vs_read_hist_attribute
           SET id_vital_sign_read_hist = NULL
         WHERE id_vital_sign_read_hist IN
               (SELECT id_vital_sign_read_hist
                  FROM vital_sign_read_hist
                 WHERE id_vital_sign_read IN
                       (SELECT id_vital_sign_read
                          FROM vital_sign_read
                         WHERE id_epis_triage IN
                               (SELECT id_epis_triage
                                  FROM epis_triage
                                 WHERE id_transportation IN
                                       (SELECT id_transportation
                                          FROM transportation
                                         WHERE id_transp_req IN
                                               (SELECT id_transp_req
                                                  FROM transp_req
                                                 WHERE id_consult_req IN
                                                       (SELECT id_consult_req
                                                          FROM consult_req
                                                         WHERE id_schedule IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule_ref IN
                                                                       (SELECT id_schedule
                                                                          FROM schedule
                                                                         WHERE id_schedule IN
                                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                                 column_value
                                                                                  FROM TABLE(i_scheduler_ids) t)))))))));
    
        ------ Nº 9---------------------------------------------------
    
        UPDATE audit_req_comment
           SET id_audit_quest_answer = NULL
         WHERE id_audit_quest_answer IN
               (SELECT id_audit_quest_answer
                  FROM audit_quest_answer
                 WHERE id_audit_req_prof_epis IN
                       (SELECT id_audit_req_prof_epis
                          FROM audit_req_prof_epis
                         WHERE id_epis_triage IN
                               (SELECT id_epis_triage
                                  FROM epis_triage
                                 WHERE id_transportation IN
                                       (SELECT id_transportation
                                          FROM transportation
                                         WHERE id_transp_req IN
                                               (SELECT id_transp_req
                                                  FROM transp_req
                                                 WHERE id_consult_req IN
                                                       (SELECT id_consult_req
                                                          FROM consult_req
                                                         WHERE id_schedule IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 10---------------------------------------------------
    
        /* UPDATE
        SR_PROF_TEAM_DET_HIST SET ID_SR_PROF_TEAM_DET =NULL WHERE ID_SR_PROF_TEAM_DET IN (SELECT ID_SR_PROF_TEAM_DET FROM SR_PROF_TEAM_DET WHERE
        ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))))));*/
    
        ------ Nº 11---------------------------------------------------
    
        UPDATE audit_req_comment
           SET id_audit_quest_answer = NULL
         WHERE id_audit_quest_answer IN
               (SELECT id_audit_quest_answer
                  FROM audit_quest_answer
                 WHERE id_audit_req_prof_epis IN
                       (SELECT id_audit_req_prof_epis
                          FROM audit_req_prof_epis
                         WHERE id_epis_triage IN
                               (SELECT id_epis_triage
                                  FROM epis_triage
                                 WHERE id_transportation IN
                                       (SELECT id_transportation
                                          FROM transportation
                                         WHERE id_transp_req IN
                                               (SELECT id_transp_req
                                                  FROM transp_req
                                                 WHERE id_consult_req IN
                                                       (SELECT id_consult_req
                                                          FROM consult_req
                                                         WHERE id_schedule IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 12---------------------------------------------------
    
        UPDATE vs_read_hist_attribute
           SET id_vital_sign_read_hist = NULL
         WHERE id_vital_sign_read_hist IN
               (SELECT id_vital_sign_read_hist
                  FROM vital_sign_read_hist
                 WHERE id_vital_sign_read IN
                       (SELECT id_vital_sign_read
                          FROM vital_sign_read
                         WHERE id_epis_triage IN
                               (SELECT id_epis_triage
                                  FROM epis_triage
                                 WHERE id_transportation IN
                                       (SELECT id_transportation
                                          FROM transportation
                                         WHERE id_transp_req IN
                                               (SELECT id_transp_req
                                                  FROM transp_req
                                                 WHERE id_consult_req IN
                                                       (SELECT id_consult_req
                                                          FROM consult_req
                                                         WHERE id_schedule IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 13---------------------------------------------------
    
        UPDATE exam_res_fetus_biom_img
           SET id_exam_res_fetus_biom = NULL
         WHERE id_exam_res_fetus_biom IN
               (SELECT id_exam_res_fetus_biom
                  FROM exam_res_fetus_biom
                 WHERE id_exam_res_pregn_fetus IN
                       (SELECT id_exam_res_pregn_fetus
                          FROM exam_res_pregn_fetus
                         WHERE id_exam_result_pregnancy IN
                               (SELECT id_exam_result_pregnancy
                                  FROM exam_result_pregnancy
                                 WHERE id_exam_result IN
                                       (SELECT id_exam_result
                                          FROM exam_result
                                         WHERE id_exam_req_det IN
                                               (SELECT id_exam_req_det
                                                  FROM exam_req_det
                                                 WHERE id_exam_req IN
                                                       (SELECT id_exam_req
                                                          FROM exam_req
                                                         WHERE id_sched_consult IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 14---------------------------------------------------
    
        UPDATE exam_res_fetus_biom_img
           SET id_exam_res_fetus_biom = NULL
         WHERE id_exam_res_fetus_biom IN
               (SELECT id_exam_res_fetus_biom
                  FROM exam_res_fetus_biom
                 WHERE id_exam_res_pregn_fetus IN
                       (SELECT id_exam_res_pregn_fetus
                          FROM exam_res_pregn_fetus
                         WHERE id_exam_result_pregnancy IN
                               (SELECT id_exam_result_pregnancy
                                  FROM exam_result_pregnancy
                                 WHERE id_exam_result IN
                                       (SELECT id_exam_result
                                          FROM exam_result
                                         WHERE id_exam_req_det IN
                                               (SELECT id_exam_req_det
                                                  FROM exam_req_det
                                                 WHERE id_exam_req IN
                                                       (SELECT id_exam_req
                                                          FROM exam_req
                                                         WHERE id_schedule IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 17---------------------------------------------------
    
        UPDATE audit_quest_answer
           SET id_audit_req_prof_epis = NULL
         WHERE id_audit_req_prof_epis IN
               (SELECT id_audit_req_prof_epis
                  FROM audit_req_prof_epis
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 18---------------------------------------------------
    
        UPDATE audit_req_comment
           SET id_audit_req_prof_epis = NULL
         WHERE id_audit_req_prof_epis IN
               (SELECT id_audit_req_prof_epis
                  FROM audit_req_prof_epis
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 19---------------------------------------------------
    
        UPDATE epis_fast_track_hist
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_fast_track
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 20---------------------------------------------------
    
        UPDATE epis_fast_track_reason
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_fast_track
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 21---------------------------------------------------
    
        UPDATE epis_mtos_param
           SET id_task_refid = NULL
         WHERE id_task_refid IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))))
           AND flg_param_task_type = pk_sev_scores_constant.g_flg_param_task_vital_sign;
    
        ------ Nº 22---------------------------------------------------
    
        /*UPDATE
        PRESC SET ID_VITAL_SIGN_READ =NULL WHERE ID_VITAL_SIGN_READ IN (SELECT ID_VITAL_SIGN_READ FROM VITAL_SIGN_READ WHERE
        ID_EPIS_TRIAGE IN (SELECT ID_EPIS_TRIAGE FROM EPIS_TRIAGE WHERE
        ID_TRANSPORTATION IN (SELECT ID_TRANSPORTATION FROM TRANSPORTATION WHERE
        ID_TRANSP_REQ IN (SELECT ID_TRANSP_REQ FROM TRANSP_REQ WHERE
        ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))))));*/
    
        ------ Nº 23---------------------------------------------------
    
        UPDATE pre_hosp_vs_read
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 24---------------------------------------------------
    
        UPDATE vital_sign_pregnancy
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 25---------------------------------------------------
    
        UPDATE vital_sign_read_hist
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 26---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_3_vsr = NULL
         WHERE id_last_3_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 27---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_first_vsr = NULL
         WHERE id_first_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 28---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_min_vsr = NULL
         WHERE id_min_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 29---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_max_vsr = NULL
         WHERE id_max_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 30---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_1_vsr = NULL
         WHERE id_last_1_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 31---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_2_vsr = NULL
         WHERE id_last_2_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 32---------------------------------------------------
    
        UPDATE vs_read_attribute
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 33---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_3_vsr = NULL
         WHERE id_last_3_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 34---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_2_vsr = NULL
         WHERE id_last_2_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 35---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_1_vsr = NULL
         WHERE id_last_1_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 36---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_max_vsr = NULL
         WHERE id_max_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 37---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_min_vsr = NULL
         WHERE id_min_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 38---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_first_vsr = NULL
         WHERE id_first_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 39---------------------------------------------------
    
        UPDATE audit_quest_answer
           SET id_audit_req_prof_epis = NULL
         WHERE id_audit_req_prof_epis IN
               (SELECT id_audit_req_prof_epis
                  FROM audit_req_prof_epis
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 40---------------------------------------------------
    
        UPDATE audit_req_comment
           SET id_audit_req_prof_epis = NULL
         WHERE id_audit_req_prof_epis IN
               (SELECT id_audit_req_prof_epis
                  FROM audit_req_prof_epis
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 41---------------------------------------------------
    
        UPDATE epis_fast_track_hist
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_fast_track
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 42---------------------------------------------------
    
        UPDATE epis_fast_track_reason
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_fast_track
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 43---------------------------------------------------
    
        UPDATE epis_mtos_param
           SET id_task_refid = NULL
         WHERE id_task_refid IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))))
           AND flg_param_task_type = pk_sev_scores_constant.g_flg_param_task_vital_sign;
    
        ------ Nº 44---------------------------------------------------
    
        /*UPDATE
        PRESC SET ID_VITAL_SIGN_READ =NULL WHERE ID_VITAL_SIGN_READ IN (SELECT ID_VITAL_SIGN_READ FROM VITAL_SIGN_READ WHERE
        ID_EPIS_TRIAGE IN (SELECT ID_EPIS_TRIAGE FROM EPIS_TRIAGE WHERE
        ID_TRANSPORTATION IN (SELECT ID_TRANSPORTATION FROM TRANSPORTATION WHERE
        ID_TRANSP_REQ IN (SELECT ID_TRANSP_REQ FROM TRANSP_REQ WHERE
        ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))))));*/
    
        ------ Nº 45---------------------------------------------------
    
        UPDATE pre_hosp_vs_read
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 46---------------------------------------------------
    
        UPDATE vital_sign_pregnancy
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 47---------------------------------------------------
    
        UPDATE vital_sign_read_hist
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 48---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_3_vsr = NULL
         WHERE id_last_3_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 49---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_first_vsr = NULL
         WHERE id_first_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 50---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_min_vsr = NULL
         WHERE id_min_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 51---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_max_vsr = NULL
         WHERE id_max_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 52---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_1_vsr = NULL
         WHERE id_last_1_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 53---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_2_vsr = NULL
         WHERE id_last_2_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 54---------------------------------------------------
    
        UPDATE vs_read_attribute
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 55---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_3_vsr = NULL
         WHERE id_last_3_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 56---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_2_vsr = NULL
         WHERE id_last_2_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 57---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_1_vsr = NULL
         WHERE id_last_1_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 58---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_max_vsr = NULL
         WHERE id_max_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 59---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_min_vsr = NULL
         WHERE id_min_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 60---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_first_vsr = NULL
         WHERE id_first_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 61---------------------------------------------------
    
        UPDATE exam_res_fetus_biom
           SET id_exam_res_pregn_fetus = NULL
         WHERE id_exam_res_pregn_fetus IN
               (SELECT id_exam_res_pregn_fetus
                  FROM exam_res_pregn_fetus
                 WHERE id_exam_result_pregnancy IN
                       (SELECT id_exam_result_pregnancy
                          FROM exam_result_pregnancy
                         WHERE id_exam_result IN
                               (SELECT id_exam_result
                                  FROM exam_result
                                 WHERE id_exam_req_det IN
                                       (SELECT id_exam_req_det
                                          FROM exam_req_det
                                         WHERE id_exam_req IN
                                               (SELECT id_exam_req
                                                  FROM exam_req
                                                 WHERE id_sched_consult IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 62---------------------------------------------------
    
        UPDATE exam_res_fetus_biom
           SET id_exam_res_pregn_fetus = NULL
         WHERE id_exam_res_pregn_fetus IN
               (SELECT id_exam_res_pregn_fetus
                  FROM exam_res_pregn_fetus
                 WHERE id_exam_result_pregnancy IN
                       (SELECT id_exam_result_pregnancy
                          FROM exam_result_pregnancy
                         WHERE id_exam_result IN
                               (SELECT id_exam_result
                                  FROM exam_result
                                 WHERE id_exam_req_det IN
                                       (SELECT id_exam_req_det
                                          FROM exam_req_det
                                         WHERE id_exam_req IN
                                               (SELECT id_exam_req
                                                  FROM exam_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule_ref IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 70---------------------------------------------------
    
        /*UPDATE
        SR_POS_PHARM_DET SET ID_SR_POS_PHARM =NULL WHERE ID_SR_POS_PHARM IN (SELECT ID_SR_POS_PHARM FROM SR_POS_PHARM WHERE
        ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))))));*/
    
        ------ Nº 71---------------------------------------------------
    
        UPDATE vs_read_hist_attribute
           SET id_vital_sign_read_hist = NULL
         WHERE id_vital_sign_read_hist IN
               (SELECT id_vital_sign_read_hist
                  FROM vital_sign_read_hist
                 WHERE id_vital_sign_read IN
                       (SELECT id_vital_sign_read
                          FROM vital_sign_read
                         WHERE id_epis_triage IN
                               (SELECT id_epis_triage
                                  FROM epis_triage
                                 WHERE id_transportation IN
                                       (SELECT id_transportation
                                          FROM transportation
                                         WHERE id_transp_req IN
                                               (SELECT id_transp_req
                                                  FROM transp_req
                                                 WHERE id_consult_req IN
                                                       (SELECT id_consult_req
                                                          FROM consult_req
                                                         WHERE id_schedule IN
                                                               (SELECT id_schedule
                                                                  FROM schedule
                                                                 WHERE id_schedule IN
                                                                       (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                         column_value
                                                                          FROM TABLE(i_scheduler_ids) t))))))));
    
        ------ Nº 72---------------------------------------------------
    
        UPDATE analysis_result_par_hist
           SET id_analysis_result_par = NULL
         WHERE id_analysis_result_par IN
               (SELECT id_analysis_result_par
                  FROM analysis_result_par
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 73---------------------------------------------------
    
        UPDATE analysis_result_par_hist
           SET id_analysis_result_par = NULL
         WHERE id_analysis_result_par IN
               (SELECT id_analysis_result_par
                  FROM analysis_result_par
                 WHERE id_analysis_result IN
                       (SELECT id_analysis_result
                          FROM analysis_result
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 74---------------------------------------------------
    
        UPDATE pat_periodic_obs_hist
           SET id_periodic_observation_reg = NULL
         WHERE id_periodic_observation_reg IN
               (SELECT id_periodic_observation_reg
                  FROM periodic_observation_reg
                 WHERE id_analysis_result IN
                       (SELECT id_analysis_result
                          FROM analysis_result
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 75---------------------------------------------------
    
        UPDATE audit_req_prof_epis
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 76---------------------------------------------------
    
        UPDATE epis_fast_track
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 77---------------------------------------------------
    
        UPDATE epis_fast_track_hist
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 78---------------------------------------------------
    
        UPDATE epis_triage_option
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 79---------------------------------------------------
    
        UPDATE epis_triage_pat_necessity
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 80---------------------------------------------------
    
        UPDATE epis_triage_vs
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 81---------------------------------------------------
    
        UPDATE vital_sign_read
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 82---------------------------------------------------
    
        UPDATE audit_req_prof_epis
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 83---------------------------------------------------
    
        UPDATE epis_fast_track
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 84---------------------------------------------------
    
        UPDATE epis_fast_track_hist
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 85---------------------------------------------------
    
        UPDATE epis_triage_option
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 86---------------------------------------------------
    
        UPDATE epis_triage_pat_necessity
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 87---------------------------------------------------
    
        UPDATE epis_triage_vs
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 88---------------------------------------------------
    
        UPDATE vital_sign_read
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 89---------------------------------------------------
    
        UPDATE exam_res_pregn_fetus
           SET id_exam_result_pregnancy = NULL
         WHERE id_exam_result_pregnancy IN
               (SELECT id_exam_result_pregnancy
                  FROM exam_result_pregnancy
                 WHERE id_exam_result IN
                       (SELECT id_exam_result
                          FROM exam_result
                         WHERE id_exam_req_det IN
                               (SELECT id_exam_req_det
                                  FROM exam_req_det
                                 WHERE id_exam_req IN
                                       (SELECT id_exam_req
                                          FROM exam_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 90---------------------------------------------------
    
        UPDATE exam_res_pregn_fetus
           SET id_exam_result_pregnancy = NULL
         WHERE id_exam_result_pregnancy IN
               (SELECT id_exam_result_pregnancy
                  FROM exam_result_pregnancy
                 WHERE id_exam_result IN
                       (SELECT id_exam_result
                          FROM exam_result
                         WHERE id_exam_req_det IN
                               (SELECT id_exam_req_det
                                  FROM exam_req_det
                                 WHERE id_exam_req IN
                                       (SELECT id_exam_req
                                          FROM exam_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 97---------------------------------------------------
    
        /*UPDATE
        DISCHARGE_NOTES_FOLLOW_UP SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ Nº 98---------------------------------------------------
    
        /*UPDATE
        DISCH_NOTES_DISCUSSED SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ Nº 99---------------------------------------------------
    
        /*UPDATE
        SR_POS_PHARM SET ID_SR_POS_SCHEDULE =NULL WHERE ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ Nº 100---------------------------------------------------
    
        /*DELETE FROM
        SR_POS_SCHEDULE_HIST WHERE ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ Nº 101---------------------------------------------------
    
        /*UPDATE
        SR_PROF_TEAM_DET SET ID_SURGERY_RECORD =NULL WHERE ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ Nº 102---------------------------------------------------
    
        /*UPDATE
        SR_SURGERY_REC_DET SET ID_SURGERY_RECORD =NULL WHERE ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ Nº 103---------------------------------------------------
    
        UPDATE audit_quest_answer
           SET id_audit_req_prof_epis = NULL
         WHERE id_audit_req_prof_epis IN
               (SELECT id_audit_req_prof_epis
                  FROM audit_req_prof_epis
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 104---------------------------------------------------
    
        UPDATE audit_req_comment
           SET id_audit_req_prof_epis = NULL
         WHERE id_audit_req_prof_epis IN
               (SELECT id_audit_req_prof_epis
                  FROM audit_req_prof_epis
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 105---------------------------------------------------
    
        UPDATE epis_fast_track_hist
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_fast_track
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 106---------------------------------------------------
    
        UPDATE epis_fast_track_reason
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_fast_track
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 107---------------------------------------------------
    
        UPDATE epis_mtos_param
           SET flg_param_task_type = NULL, id_task_refid = NULL
         WHERE id_task_refid IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))))
           AND flg_param_task_type = pk_sev_scores_constant.g_flg_param_task_vital_sign;
    
        ------ Nº 108---------------------------------------------------
    
        /*UPDATE
        PRESC SET ID_VITAL_SIGN_READ =NULL WHERE ID_VITAL_SIGN_READ IN (SELECT ID_VITAL_SIGN_READ FROM VITAL_SIGN_READ WHERE
        ID_EPIS_TRIAGE IN (SELECT ID_EPIS_TRIAGE FROM EPIS_TRIAGE WHERE
        ID_TRANSPORTATION IN (SELECT ID_TRANSPORTATION FROM TRANSPORTATION WHERE
        ID_TRANSP_REQ IN (SELECT ID_TRANSP_REQ FROM TRANSP_REQ WHERE
        ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ Nº 109---------------------------------------------------
    
        UPDATE pre_hosp_vs_read
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 110---------------------------------------------------
    
        UPDATE vital_sign_pregnancy
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 111---------------------------------------------------
    
        UPDATE vital_sign_read_hist
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 112---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_3_vsr = NULL
         WHERE id_last_3_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 113---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_first_vsr = NULL
         WHERE id_first_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 114---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_min_vsr = NULL
         WHERE id_min_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 115---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_max_vsr = NULL
         WHERE id_max_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 116---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_1_vsr = NULL
         WHERE id_last_1_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 117---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_2_vsr = NULL
         WHERE id_last_2_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 118---------------------------------------------------
    
        UPDATE vs_read_attribute
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 119---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_3_vsr = NULL
         WHERE id_last_3_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 120---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_2_vsr = NULL
         WHERE id_last_2_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 121---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_1_vsr = NULL
         WHERE id_last_1_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 122---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_max_vsr = NULL
         WHERE id_max_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 123---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_min_vsr = NULL
         WHERE id_min_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 124---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_first_vsr = NULL
         WHERE id_first_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 125---------------------------------------------------
    
        UPDATE audit_quest_answer
           SET id_audit_req_prof_epis = NULL
         WHERE id_audit_req_prof_epis IN
               (SELECT id_audit_req_prof_epis
                  FROM audit_req_prof_epis
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 126---------------------------------------------------
    
        UPDATE audit_req_comment
           SET id_audit_req_prof_epis = NULL
         WHERE id_audit_req_prof_epis IN
               (SELECT id_audit_req_prof_epis
                  FROM audit_req_prof_epis
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 127---------------------------------------------------
    
        UPDATE epis_fast_track_hist
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_fast_track
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 128---------------------------------------------------
    
        UPDATE epis_fast_track_reason
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_fast_track
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 129---------------------------------------------------
    
        UPDATE epis_mtos_param
           SET flg_param_task_type = NULL, id_task_refid = NULL
         WHERE id_task_refid IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))))
           AND flg_param_task_type = pk_sev_scores_constant.g_flg_param_task_vital_sign;
    
        ------ Nº 130---------------------------------------------------
    
        /*UPDATE
        PRESC SET ID_VITAL_SIGN_READ =NULL WHERE ID_VITAL_SIGN_READ IN (SELECT ID_VITAL_SIGN_READ FROM VITAL_SIGN_READ WHERE
        ID_EPIS_TRIAGE IN (SELECT ID_EPIS_TRIAGE FROM EPIS_TRIAGE WHERE
        ID_TRANSPORTATION IN (SELECT ID_TRANSPORTATION FROM TRANSPORTATION WHERE
        ID_TRANSP_REQ IN (SELECT ID_TRANSP_REQ FROM TRANSP_REQ WHERE
        ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ Nº 131---------------------------------------------------
    
        UPDATE pre_hosp_vs_read
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 132---------------------------------------------------
    
        UPDATE vital_sign_pregnancy
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 133---------------------------------------------------
    
        UPDATE vital_sign_read_hist
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 134---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_3_vsr = NULL
         WHERE id_last_3_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 135---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_first_vsr = NULL
         WHERE id_first_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 136---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_min_vsr = NULL
         WHERE id_min_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 137---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_max_vsr = NULL
         WHERE id_max_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 138---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_1_vsr = NULL
         WHERE id_last_1_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 139---------------------------------------------------
    
        UPDATE vs_patient_ea
           SET id_last_2_vsr = NULL
         WHERE id_last_2_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 140---------------------------------------------------
    
        UPDATE vs_read_attribute
           SET id_vital_sign_read = NULL
         WHERE id_vital_sign_read IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 141---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_3_vsr = NULL
         WHERE id_last_3_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 142---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_2_vsr = NULL
         WHERE id_last_2_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 143---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_last_1_vsr = NULL
         WHERE id_last_1_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 144---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_max_vsr = NULL
         WHERE id_max_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 145---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_min_vsr = NULL
         WHERE id_min_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 146---------------------------------------------------
    
        UPDATE vs_visit_ea
           SET id_first_vsr = NULL
         WHERE id_first_vsr IN
               (SELECT id_vital_sign_read
                  FROM vital_sign_read
                 WHERE id_epis_triage IN
                       (SELECT id_epis_triage
                          FROM epis_triage
                         WHERE id_transportation IN
                               (SELECT id_transportation
                                  FROM transportation
                                 WHERE id_transp_req IN
                                       (SELECT id_transp_req
                                          FROM transp_req
                                         WHERE id_consult_req IN
                                               (SELECT id_consult_req
                                                  FROM consult_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 147---------------------------------------------------
    
        UPDATE exam_res_fetus_biom
           SET id_exam_res_pregn_fetus = NULL
         WHERE id_exam_res_pregn_fetus IN
               (SELECT id_exam_res_pregn_fetus
                  FROM exam_res_pregn_fetus
                 WHERE id_exam_result_pregnancy IN
                       (SELECT id_exam_result_pregnancy
                          FROM exam_result_pregnancy
                         WHERE id_exam_result IN
                               (SELECT id_exam_result
                                  FROM exam_result
                                 WHERE id_exam_req_det IN
                                       (SELECT id_exam_req_det
                                          FROM exam_req_det
                                         WHERE id_exam_req IN
                                               (SELECT id_exam_req
                                                  FROM exam_req
                                                 WHERE id_sched_consult IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 148---------------------------------------------------
    
        UPDATE exam_res_fetus_biom
           SET id_exam_res_pregn_fetus = NULL
         WHERE id_exam_res_pregn_fetus IN
               (SELECT id_exam_res_pregn_fetus
                  FROM exam_res_pregn_fetus
                 WHERE id_exam_result_pregnancy IN
                       (SELECT id_exam_result_pregnancy
                          FROM exam_result_pregnancy
                         WHERE id_exam_result IN
                               (SELECT id_exam_result
                                  FROM exam_result
                                 WHERE id_exam_req_det IN
                                       (SELECT id_exam_req_det
                                          FROM exam_req_det
                                         WHERE id_exam_req IN
                                               (SELECT id_exam_req
                                                  FROM exam_req
                                                 WHERE id_schedule IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 156---------------------------------------------------
    
        /*UPDATE
        SR_POS_PHARM_DET SET ID_SR_POS_PHARM =NULL WHERE ID_SR_POS_PHARM IN (SELECT ID_SR_POS_PHARM FROM SR_POS_PHARM WHERE
        ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ Nº 157---------------------------------------------------
    
        /*UPDATE
        SR_PROF_TEAM_DET_HIST SET ID_SR_PROF_TEAM_DET =NULL WHERE ID_SR_PROF_TEAM_DET IN (SELECT ID_SR_PROF_TEAM_DET FROM SR_PROF_TEAM_DET WHERE
        ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ Nº 158---------------------------------------------------
    
        UPDATE analysis_harvest_hist
           SET id_analysis_harvest = NULL
         WHERE id_analysis_harvest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 159---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_dest = NULL
         WHERE id_analysis_harv_dest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 160---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_orig = NULL
         WHERE id_analysis_harv_orig IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 161---------------------------------------------------
    
        UPDATE analysis_result_par_hist
           SET id_analysis_result_par = NULL
         WHERE id_analysis_result_par IN
               (SELECT id_analysis_result_par
                  FROM analysis_result_par
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 162---------------------------------------------------
    
        UPDATE analysis_result_par_hist
           SET id_analysis_result_par = NULL
         WHERE id_analysis_result_par IN
               (SELECT id_analysis_result_par
                  FROM analysis_result_par
                 WHERE id_analysis_result IN
                       (SELECT id_analysis_result
                          FROM analysis_result
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 163---------------------------------------------------
    
        UPDATE pat_periodic_obs_hist
           SET id_periodic_observation_reg = NULL
         WHERE id_periodic_observation_reg IN
               (SELECT id_periodic_observation_reg
                  FROM periodic_observation_reg
                 WHERE id_analysis_result IN
                       (SELECT id_analysis_result
                          FROM analysis_result
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 164---------------------------------------------------
    
        UPDATE analysis_harvest_hist
           SET id_analysis_harvest = NULL
         WHERE id_analysis_harvest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 165---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_dest = NULL
         WHERE id_analysis_harv_dest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 166---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_orig = NULL
         WHERE id_analysis_harv_orig IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule_ref IN
                                                       (SELECT id_schedule
                                                          FROM schedule
                                                         WHERE id_schedule IN
                                                               (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                 column_value
                                                                  FROM TABLE(i_scheduler_ids) t)))))));
    
        ------ Nº 167---------------------------------------------------
    
        UPDATE exam_result_hist
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 168---------------------------------------------------
    
        UPDATE exam_result_pregnancy
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 169---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 170---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_result = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 171---------------------------------------------------
    
        UPDATE exam_media_archive
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 172---------------------------------------------------
    
        UPDATE exam_result_hist
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 173---------------------------------------------------
    
        UPDATE exam_result_pregnancy
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 174---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 192---------------------------------------------------
        /*
        UPDATE
        DOC_ACTIVITY_PARAM SET ID_DOC_ACTIVITY =NULL WHERE ID_DOC_ACTIVITY IN (SELECT ID_DOC_ACTIVITY FROM DOC_ACTIVITY WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 193---------------------------------------------------
        /*
        UPDATE
        DOC_COMMENTS SET ID_DOC_IMAGE =NULL WHERE ID_DOC_IMAGE IN (SELECT ID_DOC_IMAGE FROM DOC_IMAGE WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 194---------------------------------------------------
        /*
        UPDATE
        DISCHARGE_NOTES SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 195---------------------------------------------------
        /*
        UPDATE
        EPIS_REPORT_DISCLOSURE SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 196---------------------------------------------------
    
        /*UPDATE
        EPIS_REPORT_SECTION SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 197---------------------------------------------------
    
        /*UPDATE
        PRESC_PRINT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 198---------------------------------------------------
    
        /*UPDATE
        REF_REPORT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 199---------------------------------------------------
    
        /*UPDATE
        XDS_DOCUMENT_SUB_CONF_CODE SET ID_XDS_DOCUMENT_SUBMISSION =NULL WHERE ID_XDS_DOCUMENT_SUBMISSION IN (SELECT ID_XDS_DOCUMENT_SUBMISSION FROM XDS_DOCUMENT_SUBMISSION WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 200---------------------------------------------------
    
        /*UPDATE
        XDS_DOC_SUB_CONF_CODE_SET SET ID_XDS_DOCUMENT_SUBMISSION =NULL WHERE ID_XDS_DOCUMENT_SUBMISSION IN (SELECT ID_XDS_DOCUMENT_SUBMISSION FROM XDS_DOCUMENT_SUBMISSION WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 201---------------------------------------------------
    
        /*UPDATE
        DISCHARGE_NOTES_FOLLOW_UP SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 202---------------------------------------------------
    
        /*UPDATE
        DISCH_NOTES_DISCUSSED SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 203---------------------------------------------------
    
        /*DELETE FROM
        SCHEDULE_BED_HIST WHERE ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE_BED WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 204---------------------------------------------------
    
        /* UPDATE
        EPIS_INFO SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 205---------------------------------------------------
    
        /*DELETE FROM
        SCHEDULE_SR_HIST WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 206---------------------------------------------------
    
        /*UPDATE
        SR_CONSENT SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 207---------------------------------------------------
    
        /*UPDATE
        SR_DANGER_CONT SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 208---------------------------------------------------
    
        /*UPDATE
        SR_POS_SCHEDULE SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 209---------------------------------------------------
    
        /*DELETE FROM
        SR_POS_SCHEDULE_HIST WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 210---------------------------------------------------
    
        DELETE FROM sr_surgery_record
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_waiting_list IN
                       (SELECT id_waiting_list
                          FROM waiting_list
                         WHERE id_external_request IN
                               (SELECT id_external_request
                                  FROM p1_external_request
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 211---------------------------------------------------
    
        UPDATE interv_pp_modifiers_hist
           SET id_interv_presc_plan_hist = NULL
         WHERE id_interv_presc_plan_hist IN
               (SELECT id_interv_presc_plan_hist
                  FROM interv_presc_plan_hist
                 WHERE id_interv_presc_plan IN
                       (SELECT id_interv_presc_plan
                          FROM interv_presc_plan
                         WHERE id_schedule_intervention IN
                               (SELECT id_schedule_intervention
                                  FROM schedule_intervention
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 212---------------------------------------------------
    
        UPDATE sr_pos_pharm_det
           SET id_sr_pos_pharm = NULL
         WHERE id_sr_pos_pharm IN
               (SELECT id_sr_pos_pharm
                  FROM sr_pos_pharm
                 WHERE id_sr_pos_schedule IN
                       (SELECT id_sr_pos_schedule
                          FROM sr_pos_schedule
                         WHERE id_schedule_sr IN
                               (SELECT id_schedule_sr
                                  FROM schedule_sr
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 213---------------------------------------------------
    
        UPDATE sr_prof_team_det_hist
           SET id_sr_prof_team_det = NULL
         WHERE id_sr_prof_team_det IN
               (SELECT id_sr_prof_team_det
                  FROM sr_prof_team_det
                 WHERE id_surgery_record IN
                       (SELECT id_surgery_record
                          FROM sr_surgery_record
                         WHERE id_schedule_sr IN
                               (SELECT id_schedule_sr
                                  FROM schedule_sr
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 214---------------------------------------------------
    
        UPDATE analysis_harvest_hist
           SET id_analysis_harvest = NULL
         WHERE id_analysis_harvest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 215---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_dest = NULL
         WHERE id_analysis_harv_dest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 216---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_orig = NULL
         WHERE id_analysis_harv_orig IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 217---------------------------------------------------
    
        UPDATE analysis_result_par_hist
           SET id_analysis_result_par = NULL
         WHERE id_analysis_result_par IN
               (SELECT id_analysis_result_par
                  FROM analysis_result_par
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 218---------------------------------------------------
    
        UPDATE analysis_result_par_hist
           SET id_analysis_result_par = NULL
         WHERE id_analysis_result_par IN
               (SELECT id_analysis_result_par
                  FROM analysis_result_par
                 WHERE id_analysis_result IN
                       (SELECT id_analysis_result
                          FROM analysis_result
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 219---------------------------------------------------
    
        UPDATE pat_periodic_obs_hist
           SET id_periodic_observation_reg = NULL
         WHERE id_periodic_observation_reg IN
               (SELECT id_periodic_observation_reg
                  FROM periodic_observation_reg
                 WHERE id_analysis_result IN
                       (SELECT id_analysis_result
                          FROM analysis_result
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 220---------------------------------------------------
    
        UPDATE analysis_harvest_hist
           SET id_analysis_harvest = NULL
         WHERE id_analysis_harvest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 221---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_dest = NULL
         WHERE id_analysis_harv_dest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 222---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_orig = NULL
         WHERE id_analysis_harv_orig IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 223---------------------------------------------------
    
        UPDATE analysis_result_par_hist
           SET id_analysis_result_par = NULL
         WHERE id_analysis_result_par IN
               (SELECT id_analysis_result_par
                  FROM analysis_result_par
                 WHERE id_analysis_req_par IN
                       (SELECT id_analysis_req_par
                          FROM analysis_req_par
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 224---------------------------------------------------
    
        UPDATE analysis_result_par_hist
           SET id_analysis_result_par = NULL
         WHERE id_analysis_result_par IN
               (SELECT id_analysis_result_par
                  FROM analysis_result_par
                 WHERE id_analysis_result IN
                       (SELECT id_analysis_result
                          FROM analysis_result
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 225---------------------------------------------------
    
        UPDATE pat_periodic_obs_hist
           SET id_periodic_observation_reg = NULL
         WHERE id_periodic_observation_reg IN
               (SELECT id_periodic_observation_reg
                  FROM periodic_observation_reg
                 WHERE id_analysis_result IN
                       (SELECT id_analysis_result
                          FROM analysis_result
                         WHERE id_analysis_req_det IN
                               (SELECT id_analysis_req_det
                                  FROM analysis_req_det
                                 WHERE id_analysis_req IN
                                       (SELECT id_analysis_req
                                          FROM analysis_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 226---------------------------------------------------
    
        UPDATE audit_req_prof_epis
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 227---------------------------------------------------
    
        UPDATE epis_fast_track
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 228---------------------------------------------------
    
        UPDATE epis_fast_track_hist
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 229---------------------------------------------------
    
        UPDATE epis_triage_option
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 230---------------------------------------------------
    
        UPDATE epis_triage_pat_necessity
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 231---------------------------------------------------
    
        UPDATE epis_triage_vs
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 232---------------------------------------------------
    
        UPDATE vital_sign_read
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 233---------------------------------------------------
    
        UPDATE audit_req_prof_epis
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 234---------------------------------------------------
    
        UPDATE epis_fast_track
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 235---------------------------------------------------
    
        UPDATE epis_fast_track_hist
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 236---------------------------------------------------
    
        UPDATE epis_triage_option
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 237---------------------------------------------------
    
        UPDATE epis_triage_pat_necessity
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 238---------------------------------------------------
    
        UPDATE epis_triage_vs
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 239---------------------------------------------------
    
        UPDATE vital_sign_read
           SET id_epis_triage = NULL
         WHERE id_epis_triage IN
               (SELECT id_epis_triage
                  FROM epis_triage
                 WHERE id_transportation IN
                       (SELECT id_transportation
                          FROM transportation
                         WHERE id_transp_req IN
                               (SELECT id_transp_req
                                  FROM transp_req
                                 WHERE id_consult_req IN
                                       (SELECT id_consult_req
                                          FROM consult_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 240---------------------------------------------------
    
        UPDATE exam_res_pregn_fetus
           SET id_exam_result_pregnancy = NULL
         WHERE id_exam_result_pregnancy IN
               (SELECT id_exam_result_pregnancy
                  FROM exam_result_pregnancy
                 WHERE id_exam_result IN
                       (SELECT id_exam_result
                          FROM exam_result
                         WHERE id_exam_req_det IN
                               (SELECT id_exam_req_det
                                  FROM exam_req_det
                                 WHERE id_exam_req IN
                                       (SELECT id_exam_req
                                          FROM exam_req
                                         WHERE id_sched_consult IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 241---------------------------------------------------
    
        UPDATE exam_res_pregn_fetus
           SET id_exam_result_pregnancy = NULL
         WHERE id_exam_result_pregnancy IN
               (SELECT id_exam_result_pregnancy
                  FROM exam_result_pregnancy
                 WHERE id_exam_result IN
                       (SELECT id_exam_result
                          FROM exam_result
                         WHERE id_exam_req_det IN
                               (SELECT id_exam_req_det
                                  FROM exam_req_det
                                 WHERE id_exam_req IN
                                       (SELECT id_exam_req
                                          FROM exam_req
                                         WHERE id_schedule IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 248---------------------------------------------------
    
        /*UPDATE
        DISCHARGE_NOTES_FOLLOW_UP SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 249---------------------------------------------------
    
        /*UPDATE
        DISCH_NOTES_DISCUSSED SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 250---------------------------------------------------
    
        /*UPDATE
        SR_POS_PHARM SET ID_SR_POS_SCHEDULE =NULL WHERE ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 251---------------------------------------------------
    
        /*DELETE FROM
        SR_POS_SCHEDULE_HIST WHERE ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 252---------------------------------------------------
    
        /*UPDATE
        SR_PROF_TEAM_DET SET ID_SURGERY_RECORD =NULL WHERE ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 253---------------------------------------------------
    
        /* UPDATE
        SR_SURGERY_REC_DET SET ID_SURGERY_RECORD =NULL WHERE ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ Nº 254---------------------------------------------------
    
        UPDATE analysis_harvest_hist
           SET id_analysis_harvest = NULL
         WHERE id_analysis_harvest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 255---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_dest = NULL
         WHERE id_analysis_harv_dest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 256---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_orig = NULL
         WHERE id_analysis_harv_orig IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 257---------------------------------------------------
    
        UPDATE analysis_harvest
           SET id_analysis_req_par = NULL
         WHERE id_analysis_req_par IN
               (SELECT id_analysis_req_par
                  FROM analysis_req_par
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 258---------------------------------------------------
    
        UPDATE analysis_result_par
           SET id_analysis_req_par = NULL
         WHERE id_analysis_req_par IN
               (SELECT id_analysis_req_par
                  FROM analysis_req_par
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 259---------------------------------------------------
    
        UPDATE analysis_media_archive
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 260---------------------------------------------------
    
        UPDATE analysis_result_par
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 261---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_result = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 262---------------------------------------------------
    
        UPDATE periodic_observation_reg
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 263---------------------------------------------------
    
        UPDATE analysis_harvest_hist
           SET id_analysis_harvest = NULL
         WHERE id_analysis_harvest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 264---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_dest = NULL
         WHERE id_analysis_harv_dest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 265---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_orig = NULL
         WHERE id_analysis_harv_orig IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 266---------------------------------------------------
    
        UPDATE analysis_harvest
           SET id_analysis_req_par = NULL
         WHERE id_analysis_req_par IN
               (SELECT id_analysis_req_par
                  FROM analysis_req_par
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 267---------------------------------------------------
    
        UPDATE analysis_result_par
           SET id_analysis_req_par = NULL
         WHERE id_analysis_req_par IN
               (SELECT id_analysis_req_par
                  FROM analysis_req_par
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 268---------------------------------------------------
    
        UPDATE analysis_media_archive
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 269---------------------------------------------------
    
        UPDATE analysis_result_par
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 270---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_result = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 271---------------------------------------------------
    
        UPDATE periodic_observation_reg
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 272---------------------------------------------------
    
        UPDATE sr_pos_pharm_det
           SET id_sr_pos_pharm = NULL
         WHERE id_sr_pos_pharm IN
               (SELECT id_sr_pos_pharm
                  FROM sr_pos_pharm
                 WHERE id_sr_pos_schedule IN
                       (SELECT id_sr_pos_schedule
                          FROM sr_pos_schedule
                         WHERE id_pos_consult_req IN
                               (SELECT id_consult_req
                                  FROM consult_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 273---------------------------------------------------
    
        UPDATE sr_pos_pharm_det
           SET id_sr_pos_pharm = NULL
         WHERE id_sr_pos_pharm IN
               (SELECT id_sr_pos_pharm
                  FROM sr_pos_pharm
                 WHERE id_sr_pos_schedule IN
                       (SELECT id_sr_pos_schedule
                          FROM sr_pos_schedule
                         WHERE id_pos_consult_req IN
                               (SELECT id_consult_req
                                  FROM consult_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 274---------------------------------------------------
    
        UPDATE epis_triage
           SET id_transportation = NULL
         WHERE id_transportation IN
               (SELECT id_transportation
                  FROM transportation
                 WHERE id_transp_req IN
                       (SELECT id_transp_req
                          FROM transp_req
                         WHERE id_consult_req IN
                               (SELECT id_consult_req
                                  FROM consult_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 275---------------------------------------------------
    
        UPDATE epis_triage
           SET id_transportation = NULL
         WHERE id_transportation IN
               (SELECT id_transportation
                  FROM transportation
                 WHERE id_transp_req IN
                       (SELECT id_transp_req
                          FROM transp_req
                         WHERE id_consult_req IN
                               (SELECT id_consult_req
                                  FROM consult_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 276---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_result = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 277---------------------------------------------------
    
        UPDATE exam_media_archive
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule_ref IN
                                               (SELECT id_schedule
                                                  FROM schedule
                                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                        column_value
                                                                         FROM TABLE(i_scheduler_ids) t))))));
    
        ------ Nº 278---------------------------------------------------
    
        UPDATE p1_exr_temp
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 279---------------------------------------------------
    
        UPDATE susp_task_image_o_exams
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 280---------------------------------------------------
    
        DELETE FROM schedule_exam_hist
         WHERE id_schedule_exam IN
               (SELECT id_schedule_exam
                  FROM schedule_exam
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 285---------------------------------------------------
    
        /*UPDATE
        ANALYSIS_MEDIA_ARCHIVE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 286---------------------------------------------------
        
        UPDATE
        DOC_ACTIVITY SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 287---------------------------------------------------
        
        UPDATE
        DOC_COMMENTS SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ Nº 288---------------------------------------------------
    
        /*UPDATE
        DOC_EXTERNAL_US SET ID_DOC_EXTERNAL_US =NULL WHERE ID_DOC_EXTERNAL_US IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ Nº 289---------------------------------------------------
    
        /*UPDATE
        DOC_IMAGE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 290---------------------------------------------------
        
        UPDATE
        EPIS_REPORT SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 291---------------------------------------------------
        
        UPDATE
        EXAM_MEDIA_ARCHIVE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 292---------------------------------------------------
        
        UPDATE
        EXAM_RES_FETUS_BIOM_IMG SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 293---------------------------------------------------
        
        UPDATE
        PAT_ADV_DIRECTIVE_DOC SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ Nº 294---------------------------------------------------
    
        /*UPDATE
        PAT_AMENDMENT_DOC SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ Nº 295---------------------------------------------------
    
        /*UPDATE
        XDS_DOCUMENT_SUBMISSION SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 296---------------------------------------------------
        
        UPDATE
        DISCHARGE_NOTES SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 297---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_DISCLOSURE SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 298---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_SECTION SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 299---------------------------------------------------
        
        UPDATE
        PRESC_PRINT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 300---------------------------------------------------
        
        UPDATE
        REF_REPORT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 301---------------------------------------------------
        
        UPDATE
        P1_DETAIL SET ID_TRACKING =NULL WHERE ID_TRACKING IN (SELECT ID_TRACKING FROM P1_TRACKING WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 302---------------------------------------------------
        
        UPDATE
        REF_EXT_XML_DATA SET ID_SESSION =NULL WHERE ID_SESSION IN (SELECT ID_SESSION FROM REF_EXT_SESSION WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ Nº 303---------------------------------------------------
    
        /* UPDATE
        REF_TRANS_RESP_HIST SET ID_TRANS_RESP =NULL WHERE ID_TRANS_RESP IN (SELECT ID_TRANS_RESP FROM REF_TRANS_RESPONSIBILITY WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ Nº 304---------------------------------------------------
    
        /*DELETE FROM
        SCHEDULE_BED WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 305---------------------------------------------------
        
        DELETE FROM
        SCHEDULE_SR WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 306---------------------------------------------------
        
        UPDATE
        WAITING_LIST_HIST SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 307---------------------------------------------------
        
        UPDATE
        WTL_DEP_CLIN_SERV SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 308---------------------------------------------------
        
        UPDATE
        WTL_DOCUMENTATION SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 309---------------------------------------------------
        
        UPDATE
        WTL_EPIS SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 310---------------------------------------------------
        
        UPDATE
        WTL_PREF_TIME SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 311---------------------------------------------------
        
        UPDATE
        WTL_PROF SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 312---------------------------------------------------
        
        UPDATE
        WTL_PTREASON_WTLIST SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 313---------------------------------------------------
        
        UPDATE
        WTL_UNAV SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ Nº 314---------------------------------------------------
    
        UPDATE interv_pp_modifiers
           SET id_interv_presc_plan = NULL
         WHERE id_interv_presc_plan IN
               (SELECT id_interv_presc_plan
                  FROM interv_presc_plan
                 WHERE id_schedule_intervention IN
                       (SELECT id_schedule_intervention
                          FROM schedule_intervention
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 315---------------------------------------------------
    
        UPDATE interv_presc_plan_hist
           SET id_interv_presc_plan = NULL
         WHERE id_interv_presc_plan IN
               (SELECT id_interv_presc_plan
                  FROM interv_presc_plan
                 WHERE id_schedule_intervention IN
                       (SELECT id_schedule_intervention
                          FROM schedule_intervention
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 316---------------------------------------------------
    
        UPDATE interv_time_out
           SET id_interv_presc_plan = NULL
         WHERE id_interv_presc_plan IN
               (SELECT id_interv_presc_plan
                  FROM interv_presc_plan
                 WHERE id_schedule_intervention IN
                       (SELECT id_schedule_intervention
                          FROM schedule_intervention
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 317---------------------------------------------------
    
        UPDATE sr_pos_pharm
           SET id_sr_pos_schedule = NULL
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_schedule_sr IN
                       (SELECT id_schedule_sr
                          FROM schedule_sr
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 318---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_schedule_sr IN
                       (SELECT id_schedule_sr
                          FROM schedule_sr
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 319---------------------------------------------------
    
        UPDATE sr_prof_team_det
           SET id_surgery_record = NULL
         WHERE id_surgery_record IN
               (SELECT id_surgery_record
                  FROM sr_surgery_record
                 WHERE id_schedule_sr IN
                       (SELECT id_schedule_sr
                          FROM schedule_sr
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 320---------------------------------------------------
    
        UPDATE sr_surgery_rec_det
           SET id_surgery_record = NULL
         WHERE id_surgery_record IN
               (SELECT id_surgery_record
                  FROM sr_surgery_record
                 WHERE id_schedule_sr IN
                       (SELECT id_schedule_sr
                          FROM schedule_sr
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 321---------------------------------------------------
    
        UPDATE interv_pp_modifiers_hist
           SET id_interv_presc_plan_hist = NULL
         WHERE id_interv_presc_plan_hist IN
               (SELECT id_interv_presc_plan_hist
                  FROM interv_presc_plan_hist
                 WHERE id_interv_presc_plan IN
                       (SELECT id_interv_presc_plan
                          FROM interv_presc_plan
                         WHERE id_schedule_intervention IN
                               (SELECT id_schedule_intervention
                                  FROM schedule_intervention
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 322---------------------------------------------------
    
        UPDATE sr_pos_pharm_det
           SET id_sr_pos_pharm = NULL
         WHERE id_sr_pos_pharm IN
               (SELECT id_sr_pos_pharm
                  FROM sr_pos_pharm
                 WHERE id_sr_pos_schedule IN
                       (SELECT id_sr_pos_schedule
                          FROM sr_pos_schedule
                         WHERE id_schedule_sr IN
                               (SELECT id_schedule_sr
                                  FROM schedule_sr
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 323---------------------------------------------------
    
        UPDATE sr_prof_team_det_hist
           SET id_sr_prof_team_det = NULL
         WHERE id_sr_prof_team_det IN
               (SELECT id_sr_prof_team_det
                  FROM sr_prof_team_det
                 WHERE id_surgery_record IN
                       (SELECT id_surgery_record
                          FROM sr_surgery_record
                         WHERE id_schedule_sr IN
                               (SELECT id_schedule_sr
                                  FROM schedule_sr
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 324---------------------------------------------------
    
        /*UPDATE
          SR_DANGER_CONT SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
          ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
          ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
          ------ Nº 325---------------------------------------------------
        
          UPDATE
          SR_POS_SCHEDULE SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
          ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
          ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
          ------ Nº 326---------------------------------------------------
        
          DELETE FROM
          SR_POS_SCHEDULE_HIST WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
          ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
          ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        */
        ------ Nº 327---------------------------------------------------
    
        DELETE FROM sr_surgery_record
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_waiting_list IN
                       (SELECT id_waiting_list
                          FROM waiting_list
                         WHERE id_external_request IN
                               (SELECT id_external_request
                                  FROM p1_external_request
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 328---------------------------------------------------
    
        UPDATE analysis_abn_print
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 329---------------------------------------------------
    
        UPDATE analysis_harvest
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 330---------------------------------------------------
    
        UPDATE analysis_media_archive
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 331---------------------------------------------------
    
        UPDATE analysis_question_response
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 332---------------------------------------------------
    
        UPDATE analysis_req_det_hist
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 333---------------------------------------------------
    
        UPDATE analysis_req_par
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 334---------------------------------------------------
    
        UPDATE analysis_result
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 335---------------------------------------------------
    
        UPDATE analysis_result_send
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 336---------------------------------------------------
    
        UPDATE grid_task_lab
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 337---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_req_det = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 338---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 339---------------------------------------------------
    
        UPDATE p1_exr_analysis
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 340---------------------------------------------------
    
        UPDATE p1_exr_temp
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 341---------------------------------------------------
    
        UPDATE susp_task_lab
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 342---------------------------------------------------
    
        UPDATE analysis_abn_print
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 343---------------------------------------------------
    
        UPDATE analysis_harvest
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 344---------------------------------------------------
    
        UPDATE analysis_media_archive
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 345---------------------------------------------------
    
        UPDATE analysis_question_response
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 346---------------------------------------------------
    
        UPDATE analysis_req_det_hist
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 347---------------------------------------------------
    
        UPDATE analysis_req_par
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 348---------------------------------------------------
    
        UPDATE analysis_result
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 349---------------------------------------------------
    
        UPDATE analysis_result_send
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 350---------------------------------------------------
    
        UPDATE grid_task_lab
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 351---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_req_det = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 352---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 353---------------------------------------------------
    
        UPDATE p1_exr_analysis
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 354---------------------------------------------------
    
        UPDATE p1_exr_temp
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 355---------------------------------------------------
    
        UPDATE susp_task_lab
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 356---------------------------------------------------
    
        UPDATE cli_rec_req_mov
           SET id_cli_rec_req_det = NULL
         WHERE id_cli_rec_req_det IN
               (SELECT id_cli_rec_req_det
                  FROM cli_rec_req_det
                 WHERE id_cli_rec_req IN
                       (SELECT id_cli_rec_req
                          FROM cli_rec_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 357---------------------------------------------------
    
        UPDATE adm_request_hist
           SET id_adm_request = NULL
         WHERE id_adm_request IN
               (SELECT id_adm_request
                  FROM adm_request
                 WHERE id_nit_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 358---------------------------------------------------
    
        UPDATE adm_req_diagnosis
           SET id_adm_request = NULL
         WHERE id_adm_request IN
               (SELECT id_adm_request
                  FROM adm_request
                 WHERE id_nit_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 359---------------------------------------------------
    
        UPDATE adm_request_hist
           SET id_adm_request = NULL
         WHERE id_adm_request IN
               (SELECT id_adm_request
                  FROM adm_request
                 WHERE id_nit_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 360---------------------------------------------------
    
        UPDATE adm_req_diagnosis
           SET id_adm_request = NULL
         WHERE id_adm_request IN
               (SELECT id_adm_request
                  FROM adm_request
                 WHERE id_nit_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 361---------------------------------------------------
    
        UPDATE sr_pos_pharm
           SET id_sr_pos_schedule = NULL
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_pos_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 362---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_pos_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 363---------------------------------------------------
    
        UPDATE sr_pos_pharm
           SET id_sr_pos_schedule = NULL
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_pos_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 364---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_pos_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 365---------------------------------------------------
    
        UPDATE transportation
           SET id_transp_req = NULL
         WHERE id_transp_req IN
               (SELECT id_transp_req
                  FROM transp_req
                 WHERE id_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 366---------------------------------------------------
    
        UPDATE transportation
           SET id_transp_req = NULL
         WHERE id_transp_req IN
               (SELECT id_transp_req
                  FROM transp_req
                 WHERE id_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 367---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_req_det = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 368---------------------------------------------------
    
        UPDATE exam_media_archive
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 369---------------------------------------------------
    
        UPDATE exam_question_response
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 370---------------------------------------------------
    
        UPDATE exam_result
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 371---------------------------------------------------
    
        UPDATE exam_time_out
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 372---------------------------------------------------
    
        UPDATE grid_task_img
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 373---------------------------------------------------
    
        UPDATE grid_task_oth_exm
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 374---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 375---------------------------------------------------
    
        UPDATE p1_exr_exam
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 376---------------------------------------------------
    
        UPDATE p1_exr_temp
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 377---------------------------------------------------
    
        UPDATE susp_task_image_o_exams
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 378---------------------------------------------------
    
        DELETE FROM schedule_exam_hist
         WHERE id_schedule_exam IN
               (SELECT id_schedule_exam
                  FROM schedule_exam
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 379---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_req_det = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 380---------------------------------------------------
    
        UPDATE exam_media_archive
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 381---------------------------------------------------
    
        UPDATE exam_question_response
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 382---------------------------------------------------
    
        UPDATE exam_result
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 383---------------------------------------------------
    
        UPDATE exam_time_out
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 384---------------------------------------------------
    
        UPDATE grid_task_img
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 385---------------------------------------------------
    
        UPDATE grid_task_oth_exm
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 386---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 387---------------------------------------------------
    
        UPDATE p1_exr_exam
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule_ref IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 388---------------------------------------------------
    
        UPDATE analysis_harvest_hist
           SET id_analysis_harvest = NULL
         WHERE id_analysis_harvest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 389---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_dest = NULL
         WHERE id_analysis_harv_dest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 390---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_orig = NULL
         WHERE id_analysis_harv_orig IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 391---------------------------------------------------
    
        UPDATE analysis_harvest
           SET id_analysis_req_par = NULL
         WHERE id_analysis_req_par IN
               (SELECT id_analysis_req_par
                  FROM analysis_req_par
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 392---------------------------------------------------
    
        UPDATE analysis_result_par
           SET id_analysis_req_par = NULL
         WHERE id_analysis_req_par IN
               (SELECT id_analysis_req_par
                  FROM analysis_req_par
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 393---------------------------------------------------
    
        UPDATE analysis_media_archive
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 394---------------------------------------------------
    
        UPDATE analysis_result_par
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 395---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_result = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 396---------------------------------------------------
    
        UPDATE periodic_observation_reg
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 397---------------------------------------------------
    
        UPDATE analysis_harvest_hist
           SET id_analysis_harvest = NULL
         WHERE id_analysis_harvest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 398---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_dest = NULL
         WHERE id_analysis_harv_dest IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 399---------------------------------------------------
    
        UPDATE analysis_harv_comb_div
           SET id_analysis_harv_orig = NULL
         WHERE id_analysis_harv_orig IN
               (SELECT id_analysis_harvest
                  FROM analysis_harvest
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 400---------------------------------------------------
    
        UPDATE analysis_harvest
           SET id_analysis_req_par = NULL
         WHERE id_analysis_req_par IN
               (SELECT id_analysis_req_par
                  FROM analysis_req_par
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 401---------------------------------------------------
    
        UPDATE analysis_result_par
           SET id_analysis_req_par = NULL
         WHERE id_analysis_req_par IN
               (SELECT id_analysis_req_par
                  FROM analysis_req_par
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 402---------------------------------------------------
    
        UPDATE analysis_media_archive
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 403---------------------------------------------------
    
        UPDATE analysis_result_par
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 404---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_result = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 405---------------------------------------------------
    
        UPDATE periodic_observation_reg
           SET id_analysis_result = NULL
         WHERE id_analysis_result IN
               (SELECT id_analysis_result
                  FROM analysis_result
                 WHERE id_analysis_req_det IN
                       (SELECT id_analysis_req_det
                          FROM analysis_req_det
                         WHERE id_analysis_req IN
                               (SELECT id_analysis_req
                                  FROM analysis_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 406---------------------------------------------------
    
        UPDATE sr_pos_pharm_det
           SET id_sr_pos_pharm = NULL
         WHERE id_sr_pos_pharm IN
               (SELECT id_sr_pos_pharm
                  FROM sr_pos_pharm
                 WHERE id_sr_pos_schedule IN
                       (SELECT id_sr_pos_schedule
                          FROM sr_pos_schedule
                         WHERE id_pos_consult_req IN
                               (SELECT id_consult_req
                                  FROM consult_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 407---------------------------------------------------
    
        UPDATE sr_pos_pharm_det
           SET id_sr_pos_pharm = NULL
         WHERE id_sr_pos_pharm IN
               (SELECT id_sr_pos_pharm
                  FROM sr_pos_pharm
                 WHERE id_sr_pos_schedule IN
                       (SELECT id_sr_pos_schedule
                          FROM sr_pos_schedule
                         WHERE id_pos_consult_req IN
                               (SELECT id_consult_req
                                  FROM consult_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 408---------------------------------------------------
    
        UPDATE epis_triage
           SET id_transportation = NULL
         WHERE id_transportation IN
               (SELECT id_transportation
                  FROM transportation
                 WHERE id_transp_req IN
                       (SELECT id_transp_req
                          FROM transp_req
                         WHERE id_consult_req IN
                               (SELECT id_consult_req
                                  FROM consult_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 409---------------------------------------------------
    
        UPDATE epis_triage
           SET id_transportation = NULL
         WHERE id_transportation IN
               (SELECT id_transportation
                  FROM transportation
                 WHERE id_transp_req IN
                       (SELECT id_transp_req
                          FROM transp_req
                         WHERE id_consult_req IN
                               (SELECT id_consult_req
                                  FROM consult_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 410---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_result = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 411---------------------------------------------------
    
        UPDATE exam_media_archive
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 412---------------------------------------------------
    
        UPDATE exam_result_hist
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 413---------------------------------------------------
    
        UPDATE exam_result_pregnancy
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 414---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_sched_consult IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 415---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_result = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 416---------------------------------------------------
    
        UPDATE exam_media_archive
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 417---------------------------------------------------
    
        UPDATE exam_result_hist
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 418---------------------------------------------------
    
        UPDATE exam_result_pregnancy
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 419---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_result = NULL
         WHERE id_exam_result IN
               (SELECT id_exam_result
                  FROM exam_result
                 WHERE id_exam_req_det IN
                       (SELECT id_exam_req_det
                          FROM exam_req_det
                         WHERE id_exam_req IN
                               (SELECT id_exam_req
                                  FROM exam_req
                                 WHERE id_schedule IN
                                       (SELECT id_schedule
                                          FROM schedule
                                         WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                column_value
                                                                 FROM TABLE(i_scheduler_ids) t)))));
    
        ------ Nº 437---------------------------------------------------
        /*
        UPDATE
        DOC_ACTIVITY_PARAM SET ID_DOC_ACTIVITY =NULL WHERE ID_DOC_ACTIVITY IN (SELECT ID_DOC_ACTIVITY FROM DOC_ACTIVITY WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 438---------------------------------------------------
        
        UPDATE
        DOC_COMMENTS SET ID_DOC_IMAGE =NULL WHERE ID_DOC_IMAGE IN (SELECT ID_DOC_IMAGE FROM DOC_IMAGE WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 439---------------------------------------------------
        
        UPDATE
        DISCHARGE_NOTES SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 440---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_DISCLOSURE SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 441---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_SECTION SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 442---------------------------------------------------
        
        UPDATE
        PRESC_PRINT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 443---------------------------------------------------
        
        UPDATE
        REF_REPORT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 444---------------------------------------------------
        
        UPDATE
        XDS_DOCUMENT_SUB_CONF_CODE SET ID_XDS_DOCUMENT_SUBMISSION =NULL WHERE ID_XDS_DOCUMENT_SUBMISSION IN (SELECT ID_XDS_DOCUMENT_SUBMISSION FROM XDS_DOCUMENT_SUBMISSION WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 445---------------------------------------------------
        
        UPDATE
        XDS_DOC_SUB_CONF_CODE_SET SET ID_XDS_DOCUMENT_SUBMISSION =NULL WHERE ID_XDS_DOCUMENT_SUBMISSION IN (SELECT ID_XDS_DOCUMENT_SUBMISSION FROM XDS_DOCUMENT_SUBMISSION WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 446---------------------------------------------------
        
        UPDATE
        DISCHARGE_NOTES_FOLLOW_UP SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 447---------------------------------------------------
        
        UPDATE
        DISCH_NOTES_DISCUSSED SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 448---------------------------------------------------
        
        DELETE FROM
        SCHEDULE_BED_HIST WHERE ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE_BED WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 449---------------------------------------------------
        
        UPDATE
        EPIS_INFO SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 450---------------------------------------------------
        
        DELETE FROM
        SCHEDULE_SR_HIST WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ Nº 451---------------------------------------------------
        
        UPDATE
        SR_CONSENT SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ Nº 452---------------------------------------------------
    
        UPDATE analysis_abn_print
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 453---------------------------------------------------
    
        UPDATE analysis_harvest
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 454---------------------------------------------------
    
        UPDATE analysis_media_archive
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 455---------------------------------------------------
    
        UPDATE analysis_question_response
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 456---------------------------------------------------
    
        UPDATE analysis_req_det_hist
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 457---------------------------------------------------
    
        UPDATE analysis_req_par
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 458---------------------------------------------------
    
        UPDATE analysis_result
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 459---------------------------------------------------
    
        UPDATE analysis_result_send
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 460---------------------------------------------------
    
        UPDATE grid_task_lab
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 461---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_req_det = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 462---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 463---------------------------------------------------
    
        UPDATE p1_exr_analysis
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 464---------------------------------------------------
    
        UPDATE p1_exr_temp
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 465---------------------------------------------------
    
        UPDATE susp_task_lab
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 466---------------------------------------------------
    
        UPDATE analysis_abn_print
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 467---------------------------------------------------
    
        UPDATE analysis_harvest
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 468---------------------------------------------------
    
        UPDATE analysis_media_archive
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 469---------------------------------------------------
    
        UPDATE analysis_question_response
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 470---------------------------------------------------
    
        UPDATE analysis_req_det_hist
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 471---------------------------------------------------
    
        UPDATE analysis_req_par
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 472---------------------------------------------------
    
        UPDATE analysis_result
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 473---------------------------------------------------
    
        UPDATE analysis_result_send
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 474---------------------------------------------------
    
        UPDATE grid_task_lab
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 475---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_req_det = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 476---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 477---------------------------------------------------
    
        UPDATE p1_exr_analysis
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 478---------------------------------------------------
    
        UPDATE p1_exr_temp
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 479---------------------------------------------------
    
        UPDATE susp_task_lab
           SET id_analysis_req_det = NULL
         WHERE id_analysis_req_det IN
               (SELECT id_analysis_req_det
                  FROM analysis_req_det
                 WHERE id_analysis_req IN
                       (SELECT id_analysis_req
                          FROM analysis_req
                         WHERE id_sched_consult IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 480---------------------------------------------------
    
        UPDATE cli_rec_req_mov
           SET id_cli_rec_req_det = NULL
         WHERE id_cli_rec_req_det IN
               (SELECT id_cli_rec_req_det
                  FROM cli_rec_req_det
                 WHERE id_cli_rec_req IN
                       (SELECT id_cli_rec_req
                          FROM cli_rec_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 481---------------------------------------------------
    
        UPDATE adm_request_hist
           SET id_adm_request = NULL
         WHERE id_adm_request IN
               (SELECT id_adm_request
                  FROM adm_request
                 WHERE id_nit_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 482---------------------------------------------------
    
        UPDATE adm_req_diagnosis
           SET id_adm_request = NULL
         WHERE id_adm_request IN
               (SELECT id_adm_request
                  FROM adm_request
                 WHERE id_nit_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 483---------------------------------------------------
    
        UPDATE adm_request_hist
           SET id_adm_request = NULL
         WHERE id_adm_request IN
               (SELECT id_adm_request
                  FROM adm_request
                 WHERE id_nit_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 484---------------------------------------------------
    
        UPDATE adm_req_diagnosis
           SET id_adm_request = NULL
         WHERE id_adm_request IN
               (SELECT id_adm_request
                  FROM adm_request
                 WHERE id_nit_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 485---------------------------------------------------
    
        UPDATE sr_pos_pharm
           SET id_sr_pos_schedule = NULL
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_pos_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 486---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_pos_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 487---------------------------------------------------
    
        UPDATE sr_pos_pharm
           SET id_sr_pos_schedule = NULL
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_pos_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 488---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_pos_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 489---------------------------------------------------
    
        UPDATE transportation
           SET id_transp_req = NULL
         WHERE id_transp_req IN
               (SELECT id_transp_req
                  FROM transp_req
                 WHERE id_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 490---------------------------------------------------
    
        UPDATE transportation
           SET id_transp_req = NULL
         WHERE id_transp_req IN
               (SELECT id_transp_req
                  FROM transp_req
                 WHERE id_consult_req IN
                       (SELECT id_consult_req
                          FROM consult_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 491---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_req_det = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 492---------------------------------------------------
    
        UPDATE exam_media_archive
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 493---------------------------------------------------
    
        UPDATE exam_question_response
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 494---------------------------------------------------
    
        UPDATE exam_result
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 495---------------------------------------------------
    
        UPDATE exam_time_out
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 496---------------------------------------------------
    
        UPDATE grid_task_img
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 497---------------------------------------------------
    
        UPDATE grid_task_oth_exm
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 498---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 499---------------------------------------------------
    
        UPDATE p1_exr_exam
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 500---------------------------------------------------
    
        UPDATE p1_exr_temp
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 501---------------------------------------------------
    
        UPDATE susp_task_image_o_exams
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 502---------------------------------------------------
    
        DELETE FROM schedule_exam_hist
         WHERE id_schedule_exam IN
               (SELECT id_schedule_exam
                  FROM schedule_exam
                 WHERE id_exam_req IN (SELECT id_exam_req
                                         FROM exam_req
                                        WHERE id_sched_consult IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 503---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_req_det = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 504---------------------------------------------------
    
        UPDATE exam_media_archive
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 505---------------------------------------------------
    
        UPDATE exam_question_response
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 506---------------------------------------------------
    
        UPDATE exam_result
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 507---------------------------------------------------
    
        UPDATE exam_time_out
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 508---------------------------------------------------
    
        UPDATE grid_task_img
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 509---------------------------------------------------
    
        UPDATE grid_task_oth_exm
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 510---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 511---------------------------------------------------
    
        UPDATE p1_exr_exam
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 512---------------------------------------------------
    
        UPDATE p1_exr_temp
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 513---------------------------------------------------
    
        UPDATE susp_task_image_o_exams
           SET id_exam_req_det = NULL
         WHERE id_exam_req_det IN
               (SELECT id_exam_req_det
                  FROM exam_req_det
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 514---------------------------------------------------
    
        DELETE FROM schedule_exam_hist
         WHERE id_schedule_exam IN
               (SELECT id_schedule_exam
                  FROM schedule_exam
                 WHERE id_exam_req IN
                       (SELECT id_exam_req
                          FROM exam_req
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 519---------------------------------------------------
    
        /* UPDATE
        ANALYSIS_MEDIA_ARCHIVE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 520---------------------------------------------------
        
        UPDATE
        DOC_ACTIVITY SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 521---------------------------------------------------
        
        UPDATE
        DOC_COMMENTS SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ Nº 522---------------------------------------------------
    
        /*UPDATE
        DOC_EXTERNAL_US SET ID_DOC_EXTERNAL_US =NULL WHERE ID_DOC_EXTERNAL_US IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ Nº 523---------------------------------------------------
        /*
        UPDATE
        DOC_IMAGE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 524---------------------------------------------------
        
        UPDATE
        EPIS_REPORT SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 525---------------------------------------------------
        
        UPDATE
        EXAM_MEDIA_ARCHIVE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 526---------------------------------------------------
        
        UPDATE
        EXAM_RES_FETUS_BIOM_IMG SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 527---------------------------------------------------
        
        UPDATE
        PAT_ADV_DIRECTIVE_DOC SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ Nº 528---------------------------------------------------
    
        /*UPDATE
        PAT_AMENDMENT_DOC SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ Nº 529---------------------------------------------------
        /*
        UPDATE
        XDS_DOCUMENT_SUBMISSION SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 530---------------------------------------------------
        
        UPDATE
        DISCHARGE_NOTES SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 531---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_DISCLOSURE SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 532---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_SECTION SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 533---------------------------------------------------
        
        UPDATE
        PRESC_PRINT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 534---------------------------------------------------
        
        UPDATE
        REF_REPORT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 535---------------------------------------------------
        
        UPDATE
        P1_DETAIL SET ID_TRACKING =NULL WHERE ID_TRACKING IN (SELECT ID_TRACKING FROM P1_TRACKING WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 536---------------------------------------------------
        
        UPDATE
        REF_EXT_XML_DATA SET ID_SESSION =NULL WHERE ID_SESSION IN (SELECT ID_SESSION FROM REF_EXT_SESSION WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 537---------------------------------------------------
        
        UPDATE
        REF_TRANS_RESP_HIST SET ID_TRANS_RESP =NULL WHERE ID_TRANS_RESP IN (SELECT ID_TRANS_RESP FROM REF_TRANS_RESPONSIBILITY WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 538---------------------------------------------------
        
        DELETE FROM
        SCHEDULE_BED WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 539---------------------------------------------------
        
        DELETE FROM
        SCHEDULE_SR WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 540---------------------------------------------------
        
        UPDATE
        WAITING_LIST_HIST SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 541---------------------------------------------------
        
        UPDATE
        WTL_DEP_CLIN_SERV SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 542---------------------------------------------------
        
        UPDATE
        WTL_DOCUMENTATION SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 543---------------------------------------------------
        
        UPDATE
        WTL_EPIS SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 544---------------------------------------------------
        
        UPDATE
        WTL_PREF_TIME SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 545---------------------------------------------------
        
        UPDATE
        WTL_PROF SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 546---------------------------------------------------
        
        UPDATE
        WTL_PTREASON_WTLIST SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 547---------------------------------------------------
        
        UPDATE
        WTL_UNAV SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ Nº 548---------------------------------------------------
    
        UPDATE analysis_req_det
           SET id_analysis_req = NULL, flg_status = 'PA'
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 549---------------------------------------------------
    
        UPDATE analysis_req_det_hist
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 550---------------------------------------------------
    
        UPDATE analysis_req_hist
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 551---------------------------------------------------
    
        UPDATE grid_task_lab
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 552---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_req = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 553---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 554---------------------------------------------------
    
        DELETE FROM schedule_analysis
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 555---------------------------------------------------
    
        UPDATE analysis_req_det
           SET id_analysis_req = NULL, flg_status = 'PA'
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 556---------------------------------------------------
    
        UPDATE analysis_req_det_hist
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 557---------------------------------------------------
    
        UPDATE analysis_req_hist
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 558---------------------------------------------------
    
        UPDATE grid_task_lab
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 559---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_req = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 560---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 561---------------------------------------------------
    
        DELETE FROM schedule_analysis
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 562---------------------------------------------------
    
        UPDATE cli_rec_req_det
           SET id_cli_rec_req = NULL
         WHERE id_cli_rec_req IN
               (SELECT id_cli_rec_req
                  FROM cli_rec_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 563---------------------------------------------------
    
        UPDATE adm_request
           SET id_nit_req = NULL
         WHERE id_nit_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 564---------------------------------------------------
    
        UPDATE adm_request
           SET id_nit_req = NULL
         WHERE id_nit_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 565---------------------------------------------------
    
        UPDATE consult_req_prof
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 566---------------------------------------------------
    
        UPDATE consult_req_prof
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 567---------------------------------------------------
    
        UPDATE consult_req_prof
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 568---------------------------------------------------
    
        UPDATE consult_req_prof
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 569---------------------------------------------------
    
        UPDATE discharge_detail
           SET id_consult_req_fw = NULL
         WHERE id_consult_req_fw IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 570---------------------------------------------------
    
        UPDATE discharge_detail
           SET id_consult_req_fw = NULL
         WHERE id_consult_req_fw IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 571---------------------------------------------------
    
        UPDATE discharge_detail_hist
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 572---------------------------------------------------
    
        UPDATE discharge_detail_hist
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 573---------------------------------------------------
    
        /*UPDATE
        REQUEST_APPROVAL SET ID_CONSULT_REQ =NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 574---------------------------------------------------
        
        UPDATE
        REQUEST_APPROVAL SET ID_CONSULT_REQ =NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ Nº 575---------------------------------------------------
        /*
        UPDATE
        REQUEST_PROF SET ID_CONSULT_REQ =NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 576---------------------------------------------------
        
        UPDATE
        REQUEST_PROF SET ID_CONSULT_REQ =NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ Nº 577---------------------------------------------------
    
        UPDATE sch_schedule_request
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 578---------------------------------------------------
    
        UPDATE sch_schedule_request
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 579---------------------------------------------------
    
        /*UPDATE
        SR_POS_SCHEDULE SET ID_POS_CONSULT_REQ =NULL WHERE ID_POS_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ Nº 580---------------------------------------------------
        
        UPDATE
        SR_POS_SCHEDULE SET ID_POS_CONSULT_REQ =NULL WHERE ID_POS_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ Nº 581---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_pos_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 582---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_pos_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 583---------------------------------------------------
    
        UPDATE transp_req
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 584---------------------------------------------------
    
        UPDATE transp_req
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 585---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_req = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 586---------------------------------------------------
    
        UPDATE exam_req_det
           SET id_exam_req = NULL, flg_status = 'PA'
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 587---------------------------------------------------
    
        UPDATE grid_task_img
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 588---------------------------------------------------
    
        UPDATE grid_task_oth_exm
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 589---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 590---------------------------------------------------
    
        UPDATE schedule_exam
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN
                       (SELECT id_schedule
                          FROM schedule
                         WHERE id_schedule_ref IN
                               (SELECT id_schedule
                                  FROM schedule
                                 WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                        column_value
                                                         FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 591---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_req = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 592---------------------------------------------------
    
        UPDATE exam_req_det
           SET id_exam_req = NULL, flg_status = 'PA'
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 593---------------------------------------------------
    
        UPDATE grid_task_img
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 594---------------------------------------------------
    
        UPDATE grid_task_oth_exm
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 595---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 596---------------------------------------------------
    
        UPDATE schedule_exam
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows =1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 598---------------------------------------------------
        /*
          UPDATE
          DOC_EXTERNAL SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 599---------------------------------------------------
        
          UPDATE
          EPIS_REPORT SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 600---------------------------------------------------
        
          UPDATE
          P1_DETAIL SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 601---------------------------------------------------
        
          UPDATE
          P1_EXR_ANALYSIS SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 602---------------------------------------------------
        
          UPDATE
          P1_EXR_DIAGNOSIS SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 603---------------------------------------------------
        
          UPDATE
          P1_EXR_EXAM SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 604---------------------------------------------------
        
          UPDATE
          P1_EXR_INTERVENTION SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 605---------------------------------------------------
        
          UPDATE
          P1_EXR_TEMP SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 606---------------------------------------------------
        
          UPDATE
          P1_TASK_DONE SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 607---------------------------------------------------
        
          UPDATE
          P1_TRACKING SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 608---------------------------------------------------
        
          UPDATE
          REFERRAL_EA SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 609---------------------------------------------------
        
          UPDATE
          REF_EXT_SESSION SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 610---------------------------------------------------
        
          UPDATE
          REF_MAP SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 611---------------------------------------------------
        
          UPDATE
          REF_MIG_INST_DEST SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 612---------------------------------------------------
        
          UPDATE
          REF_MIG_INST_DEST_DATA SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 613---------------------------------------------------
        
          UPDATE
          REF_ORIG_DATA SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 614---------------------------------------------------
        
          UPDATE
          REF_PIO SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 615---------------------------------------------------
        
          UPDATE
          REF_PIO_TRACKING SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 616---------------------------------------------------
        
          UPDATE
          REF_REPORT SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 617---------------------------------------------------
        
          UPDATE
          REF_TRANS_RESPONSIBILITY SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 618---------------------------------------------------
        
          UPDATE
          REF_UPDATE_EVENT SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ Nº 619---------------------------------------------------
        
          UPDATE
          WAITING_LIST SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        */
        ------ Nº 620---------------------------------------------------
    
        UPDATE p1_detail
           SET id_tracking = NULL
         WHERE id_tracking IN
               (SELECT id_tracking
                  FROM p1_tracking
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 621---------------------------------------------------
    
        UPDATE epis_info
           SET id_room_scheduled = NULL
         WHERE id_room_scheduled IN
               (SELECT id_room_scheduled
                  FROM room_scheduled
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 622---------------------------------------------------
    
        DELETE FROM schedule_bed_hist
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule_bed
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 623---------------------------------------------------
    
        DELETE FROM schedule_exam_hist
         WHERE id_schedule_exam IN
               (SELECT id_schedule_exam
                  FROM schedule_exam
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 624---------------------------------------------------
    
        UPDATE interv_presc_plan
           SET id_schedule_intervention = NULL
         WHERE id_schedule_intervention IN
               (SELECT id_schedule_intervention
                  FROM schedule_intervention
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 625---------------------------------------------------
    
        UPDATE epis_info
           SET id_schedule_outp = NULL
         WHERE id_schedule_outp IN
               (SELECT id_schedule_outp
                  FROM schedule_outp
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 626---------------------------------------------------
    
        DELETE FROM schedule_outp_hist
         WHERE id_schedule_outp IN
               (SELECT id_schedule_outp
                  FROM schedule_outp
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 627---------------------------------------------------
    
        DELETE FROM sch_prof_outp
         WHERE id_schedule_outp IN
               (SELECT id_schedule_outp
                  FROM schedule_outp
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 628---------------------------------------------------
    
        UPDATE epis_info
           SET id_schedule_sr = NULL
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 629---------------------------------------------------
    
        DELETE FROM schedule_sr_hist
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 630---------------------------------------------------
    
        UPDATE sr_consent
           SET id_schedule_sr = NULL
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 631---------------------------------------------------
    
        UPDATE sr_danger_cont
           SET id_schedule_sr = NULL
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 632---------------------------------------------------
    
        DELETE FROM sr_pos_schedule
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 633---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 634---------------------------------------------------
    
        DELETE FROM sr_surgery_record
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 635---------------------------------------------------
    
        UPDATE sys_alert_read
           SET id_sys_alert_det = NULL
         WHERE id_sys_alert_det IN
               (SELECT id_sys_alert_det
                  FROM sys_alert_det
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule_ref IN
                                              (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 636---------------------------------------------------
    
        UPDATE interv_pp_modifiers
           SET id_interv_presc_plan = NULL
         WHERE id_interv_presc_plan IN
               (SELECT id_interv_presc_plan
                  FROM interv_presc_plan
                 WHERE id_schedule_intervention IN
                       (SELECT id_schedule_intervention
                          FROM schedule_intervention
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 637---------------------------------------------------
    
        UPDATE interv_presc_plan_hist
           SET id_interv_presc_plan = NULL
         WHERE id_interv_presc_plan IN
               (SELECT id_interv_presc_plan
                  FROM interv_presc_plan
                 WHERE id_schedule_intervention IN
                       (SELECT id_schedule_intervention
                          FROM schedule_intervention
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 638---------------------------------------------------
    
        UPDATE interv_time_out
           SET id_interv_presc_plan = NULL
         WHERE id_interv_presc_plan IN
               (SELECT id_interv_presc_plan
                  FROM interv_presc_plan
                 WHERE id_schedule_intervention IN
                       (SELECT id_schedule_intervention
                          FROM schedule_intervention
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 639---------------------------------------------------
    
        UPDATE sr_pos_pharm
           SET id_sr_pos_schedule = NULL
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_schedule_sr IN
                       (SELECT id_schedule_sr
                          FROM schedule_sr
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 640---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_sr_pos_schedule IN
               (SELECT id_sr_pos_schedule
                  FROM sr_pos_schedule
                 WHERE id_schedule_sr IN
                       (SELECT id_schedule_sr
                          FROM schedule_sr
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 641---------------------------------------------------
    
        UPDATE sr_prof_team_det
           SET id_surgery_record = NULL
         WHERE id_surgery_record IN
               (SELECT id_surgery_record
                  FROM sr_surgery_record
                 WHERE id_schedule_sr IN
                       (SELECT id_schedule_sr
                          FROM schedule_sr
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 642---------------------------------------------------
    
        UPDATE sr_surgery_rec_det
           SET id_surgery_record = NULL
         WHERE id_surgery_record IN
               (SELECT id_surgery_record
                  FROM sr_surgery_record
                 WHERE id_schedule_sr IN
                       (SELECT id_schedule_sr
                          FROM schedule_sr
                         WHERE id_schedule IN (SELECT id_schedule
                                                 FROM schedule
                                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                       column_value
                                                                        FROM TABLE(i_scheduler_ids) t))));
    
        ------ Nº 643---------------------------------------------------
        /*
          UPDATE
          REF_MIG_INST_DEST_DATA SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 644---------------------------------------------------
        
          UPDATE
          REF_ORIG_DATA SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 645---------------------------------------------------
        
          UPDATE
          REF_PIO SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 646---------------------------------------------------
        
          UPDATE
          REF_PIO_TRACKING SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 647---------------------------------------------------
        
          UPDATE
          REF_REPORT SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 648---------------------------------------------------
        
          UPDATE
          REF_TRANS_RESPONSIBILITY SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 649---------------------------------------------------
        
          UPDATE
          REF_UPDATE_EVENT SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 650---------------------------------------------------
        
          UPDATE
          WAITING_LIST SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        */
        ------ Nº 651---------------------------------------------------
    
        UPDATE p1_detail
           SET id_tracking = NULL
         WHERE id_tracking IN
               (SELECT id_tracking
                  FROM p1_tracking
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 652---------------------------------------------------
    
        UPDATE epis_info
           SET id_room_scheduled = NULL
         WHERE id_room_scheduled IN
               (SELECT id_room_scheduled
                  FROM room_scheduled
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 653---------------------------------------------------
    
        /*UPDATE
        ADMISSION_AMBULATORY SET ID_SCHEDULE=NULL WHERE ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));*/
    
        ------ Nº 654---------------------------------------------------
    
        UPDATE analysis_req
           SET id_schedule = NULL, flg_status = 'PA'
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 655---------------------------------------------------
    
        UPDATE analysis_req
           SET id_sched_consult = NULL, flg_status = 'PA'
         WHERE id_sched_consult IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 656---------------------------------------------------
    
        UPDATE cli_rec_req
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 657---------------------------------------------------
    
        UPDATE consult_req
           SET id_schedule       = NULL,
               flg_status        = pk_consult_req.g_consult_req_stat_reply,
               status_flg        = pk_consult_req.g_consult_req_stat_reply,
               dt_scheduled_tstz = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 658---------------------------------------------------
    
        UPDATE crisis_epis
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 659---------------------------------------------------
    
        UPDATE discharge_detail_hist
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 660---------------------------------------------------
    
        UPDATE epis_info
           SET id_schedule = -1
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 661---------------------------------------------------
    
        UPDATE exam_req
           SET id_sched_consult = NULL, flg_status = 'PA'
         WHERE id_sched_consult IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 662---------------------------------------------------
    
        UPDATE exam_req
           SET id_schedule = NULL, flg_status = 'PA'
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 663---------------------------------------------------
    
        UPDATE grid_task_oth_exm
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 664---------------------------------------------------
    
        UPDATE hemo_req
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 665---------------------------------------------------
    
        UPDATE matr_scheduled
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 667---------------------------------------------------
    
        UPDATE p1_external_request
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 668---------------------------------------------------
    
        UPDATE p1_tracking
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 669---------------------------------------------------
    
        UPDATE pat_referral
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 670---------------------------------------------------
    
        UPDATE prof_follow_episode
           SET id_schedule = -1
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 671---------------------------------------------------
    
        UPDATE referral_ea
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 672---------------------------------------------------
    
        UPDATE ref_map
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 673---------------------------------------------------
    
        DELETE FROM room_scheduled
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 674---------------------------------------------------
    
        DELETE FROM schedule_analysis
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 675---------------------------------------------------
    
        DELETE FROM schedule_bed
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 676---------------------------------------------------
    
        UPDATE schedule_exam
           SET id_schedule = -1
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 677---------------------------------------------------
    
        DELETE FROM schedule_hist
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 678---------------------------------------------------
    
        DELETE FROM schedule_intervention
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 679---------------------------------------------------
    
        DELETE FROM schedule_outp
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 680---------------------------------------------------
    
        DELETE FROM schedule_sr
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 681---------------------------------------------------
    
        DELETE FROM sch_allocation
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 682---------------------------------------------------
    
        DELETE FROM sch_api_map_ids
         WHERE id_schedule_pfh IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 683---------------------------------------------------
    
        DELETE FROM sch_api_map_ids_hist
         WHERE id_schedule_pfh IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 684---------------------------------------------------
    
        DELETE FROM sch_clipboard
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 685---------------------------------------------------
    
        DELETE FROM sch_group
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 686---------------------------------------------------
    
        DELETE FROM sch_rehab_group
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 687---------------------------------------------------
    
        DELETE FROM sch_resource
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 688---------------------------------------------------
    
        DELETE FROM susp_task_schedules
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 689---------------------------------------------------
    
        UPDATE sys_alert_det
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 690---------------------------------------------------
    
        UPDATE vaccine_presc_plan
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 691---------------------------------------------------
    
        UPDATE wtl_epis
           SET id_schedule = NULL
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 692---------------------------------------------------
    
        DELETE FROM schedule_bed_hist
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule_bed
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 693---------------------------------------------------
    
        DELETE FROM schedule_exam_hist
         WHERE id_schedule_exam IN
               (SELECT id_schedule_exam
                  FROM schedule_exam
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 694---------------------------------------------------
    
        UPDATE interv_presc_plan
           SET id_schedule_intervention = NULL
         WHERE id_schedule_intervention IN
               (SELECT id_schedule_intervention
                  FROM schedule_intervention
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 695---------------------------------------------------
    
        UPDATE epis_info
           SET id_schedule_outp = NULL
         WHERE id_schedule_outp IN
               (SELECT id_schedule_outp
                  FROM schedule_outp
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 696---------------------------------------------------
    
        DELETE FROM schedule_outp_hist
         WHERE id_schedule_outp IN
               (SELECT id_schedule_outp
                  FROM schedule_outp
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 697---------------------------------------------------
    
        DELETE FROM sch_prof_outp
         WHERE id_schedule_outp IN
               (SELECT id_schedule_outp
                  FROM schedule_outp
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 698---------------------------------------------------
    
        UPDATE epis_info
           SET id_schedule_sr = NULL
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 699---------------------------------------------------
    
        DELETE FROM schedule_sr_hist
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 700---------------------------------------------------
    
        UPDATE sr_consent
           SET id_schedule_sr = NULL
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 701---------------------------------------------------
    
        UPDATE sr_danger_cont
           SET id_schedule_sr = NULL
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 702---------------------------------------------------
    
        UPDATE sr_pos_schedule
           SET id_schedule_sr = -1
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 703---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 704---------------------------------------------------
    
        DELETE FROM sr_surgery_record
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 705---------------------------------------------------
    
        UPDATE sys_alert_read
           SET id_sys_alert_det = NULL
         WHERE id_sys_alert_det IN
               (SELECT id_sys_alert_det
                  FROM sys_alert_det
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 706---------------------------------------------------
    
        UPDATE analysis_req_det
           SET id_analysis_req = NULL, flg_status = 'PA'
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 707---------------------------------------------------
    
        UPDATE analysis_req_det_hist
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 708---------------------------------------------------
    
        UPDATE analysis_req_hist
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 709---------------------------------------------------
    
        UPDATE grid_task_lab
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 710---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_req = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 711---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 712---------------------------------------------------
    
        DELETE FROM schedule_analysis
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 713---------------------------------------------------
    
        UPDATE analysis_req_det
           SET id_analysis_req = NULL, flg_status = 'PA'
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 714---------------------------------------------------
    
        UPDATE analysis_req_det_hist
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 715---------------------------------------------------
    
        UPDATE analysis_req_hist
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 716---------------------------------------------------
    
        UPDATE grid_task_lab
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 717---------------------------------------------------
    
        UPDATE lab_tests_ea
           SET id_analysis_req = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 718---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_analysis_req = NULL
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 719---------------------------------------------------
    
        DELETE FROM schedule_analysis
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 720---------------------------------------------------
    
        UPDATE cli_rec_req_det
           SET id_cli_rec_req = NULL
         WHERE id_cli_rec_req IN
               (SELECT id_cli_rec_req
                  FROM cli_rec_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 721---------------------------------------------------
    
        UPDATE adm_request
           SET id_nit_req = NULL
         WHERE id_nit_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 722---------------------------------------------------
    
        UPDATE adm_request
           SET id_nit_req = NULL
         WHERE id_nit_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 723---------------------------------------------------
    
        UPDATE consult_req_prof
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 724---------------------------------------------------
    
        UPDATE consult_req_prof
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 725---------------------------------------------------
    
        UPDATE consult_req_prof
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 726---------------------------------------------------
    
        UPDATE consult_req_prof
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 727---------------------------------------------------
    
        UPDATE discharge_detail
           SET id_consult_req_fw = NULL
         WHERE id_consult_req_fw IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 728---------------------------------------------------
    
        UPDATE discharge_detail
           SET id_consult_req_fw = NULL
         WHERE id_consult_req_fw IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 729---------------------------------------------------
    
        UPDATE discharge_detail_hist
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 730---------------------------------------------------
    
        UPDATE discharge_detail_hist
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 731---------------------------------------------------
    
        /*  UPDATE
        REQUEST_APPROVAL SET ID_CONSULT_REQ=NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
        ------ Nº 732---------------------------------------------------
        
        UPDATE
        REQUEST_APPROVAL SET ID_CONSULT_REQ=NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));*/
    
        ------ Nº 733---------------------------------------------------
    
        /*UPDATE
        REQUEST_PROF SET ID_CONSULT_REQ=NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
        ------ Nº 734---------------------------------------------------
        
        UPDATE
        REQUEST_PROF SET ID_CONSULT_REQ=NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));*/
    
        ------ Nº 735---------------------------------------------------
    
        UPDATE sch_schedule_request
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 736---------------------------------------------------
    
        UPDATE sch_schedule_request
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 737---------------------------------------------------
    
        UPDATE sr_pos_schedule
           SET id_pos_consult_req = NULL
         WHERE id_pos_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 738---------------------------------------------------
    
        UPDATE sr_pos_schedule
           SET id_pos_consult_req = NULL
         WHERE id_pos_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 739---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_pos_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 740---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_pos_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 741---------------------------------------------------
    
        UPDATE transp_req
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 742---------------------------------------------------
    
        UPDATE transp_req
           SET id_consult_req = NULL
         WHERE id_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 743---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_req = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 744---------------------------------------------------
    
        UPDATE exam_req_det
           SET id_exam_req = NULL, flg_status = 'PA'
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 745---------------------------------------------------
    
        UPDATE grid_task_img
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 746---------------------------------------------------
    
        UPDATE grid_task_oth_exm
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 747---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 748---------------------------------------------------
    
        UPDATE schedule_exam
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 749---------------------------------------------------
    
        UPDATE exams_ea
           SET id_exam_req = NULL, flg_status_req = 'PA', flg_status_det = 'PA'
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 750---------------------------------------------------
    
        UPDATE exam_req_det
           SET id_exam_req = NULL, flg_status = 'PA'
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 751---------------------------------------------------
    
        UPDATE grid_task_img
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 752---------------------------------------------------
    
        UPDATE grid_task_oth_exm
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 753---------------------------------------------------
    
        UPDATE mcdt_req_diagnosis
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 754---------------------------------------------------
    
        UPDATE schedule_exam
           SET id_exam_req = NULL
         WHERE id_exam_req IN
               (SELECT id_exam_req
                  FROM exam_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ Nº 756---------------------------------------------------
        /*
          UPDATE
          DOC_EXTERNAL SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 757---------------------------------------------------
        
          UPDATE
          EPIS_REPORT SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 758---------------------------------------------------
        
          UPDATE
          P1_DETAIL SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 759---------------------------------------------------
        
          UPDATE
          P1_EXR_ANALYSIS SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 760---------------------------------------------------
        
          UPDATE
          P1_EXR_DIAGNOSIS SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 761---------------------------------------------------
        
          UPDATE
          P1_EXR_EXAM SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 762---------------------------------------------------
        
          UPDATE
          P1_EXR_INTERVENTION SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 763---------------------------------------------------
        
          UPDATE
          P1_EXR_TEMP SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 764---------------------------------------------------
        
          UPDATE
          P1_TASK_DONE SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 765---------------------------------------------------
        
          UPDATE
          P1_TRACKING SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 766---------------------------------------------------
        
          UPDATE
          REFERRAL_EA SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 767---------------------------------------------------
        
          UPDATE
          REF_EXT_SESSION SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 768---------------------------------------------------
        
          UPDATE
          REF_MAP SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ Nº 769---------------------------------------------------
        
          UPDATE
          REF_MIG_INST_DEST SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        */
        ------ Nº 770---------------------------------------------------
    
        /*UPDATE
        ADMISSION_AMBULATORY SET ID_SCHEDULE=NULL WHERE ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t));*/
    
        ------ Nº 771---------------------------------------------------
    
        UPDATE wtl_epis
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 772---------------------------------------------------
    
        UPDATE analysis_req
           SET id_sched_consult = NULL, flg_status = 'PA'
         WHERE id_sched_consult IN (SELECT id_schedule
                                      FROM schedule
                                     WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                            column_value
                                                             FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 773---------------------------------------------------
    
        UPDATE cli_rec_req
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 774---------------------------------------------------
    
        UPDATE consult_req
           SET id_schedule       = NULL,
               flg_status        = pk_consult_req.g_consult_req_stat_reply,
               status_flg        = pk_consult_req.g_consult_req_stat_reply,
               dt_scheduled_tstz = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 775---------------------------------------------------
    
        UPDATE crisis_epis
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 776---------------------------------------------------
    
        UPDATE discharge_detail_hist
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 777---------------------------------------------------
    
        UPDATE epis_info
           SET id_schedule = -1
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 778---------------------------------------------------
    
        UPDATE exam_req
           SET id_sched_consult = NULL, flg_status = 'PA'
         WHERE id_sched_consult IN (SELECT id_schedule
                                      FROM schedule
                                     WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                            column_value
                                                             FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 779---------------------------------------------------
    
        UPDATE exam_req
           SET id_schedule = NULL, flg_status = 'PA'
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 780---------------------------------------------------
    
        UPDATE grid_task_oth_exm
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 781---------------------------------------------------
    
        UPDATE hemo_req
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 782---------------------------------------------------
    
        UPDATE matr_scheduled
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 784---------------------------------------------------
    
        UPDATE p1_external_request
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 785---------------------------------------------------
    
        UPDATE p1_tracking
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 786---------------------------------------------------
    
        UPDATE pat_referral
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 787---------------------------------------------------
    
        UPDATE prof_follow_episode
           SET id_schedule = -1
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 788---------------------------------------------------
    
        UPDATE referral_ea
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 789---------------------------------------------------
    
        UPDATE ref_map
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 790---------------------------------------------------
    
        DELETE FROM room_scheduled
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 791---------------------------------------------------
    
        UPDATE schedule
           SET id_schedule_ref = NULL
         WHERE id_schedule_ref IN (SELECT id_schedule
                                     FROM schedule
                                    WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                           column_value
                                                            FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 792---------------------------------------------------
    
        DELETE FROM schedule_analysis
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 793---------------------------------------------------
    
        DELETE FROM schedule_bed
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 794---------------------------------------------------
    
        UPDATE schedule_exam
           SET id_schedule = -1
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 795---------------------------------------------------
    
        DELETE FROM schedule_hist
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 796---------------------------------------------------
    
        DELETE FROM schedule_intervention
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 797---------------------------------------------------
    
        DELETE FROM schedule_outp
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 798---------------------------------------------------
    
        DELETE FROM schedule_sr
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 799---------------------------------------------------
    
        DELETE FROM sch_allocation
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 800---------------------------------------------------
    
        DELETE FROM sch_api_map_ids
         WHERE id_schedule_pfh IN (SELECT id_schedule
                                     FROM schedule
                                    WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                           column_value
                                                            FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 801---------------------------------------------------
    
        UPDATE sch_api_map_ids_hist
           SET id_schedule_pfh = NULL
         WHERE id_schedule_pfh IN (SELECT id_schedule
                                     FROM schedule
                                    WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                           column_value
                                                            FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 802---------------------------------------------------
    
        DELETE FROM sch_clipboard
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 803---------------------------------------------------
    
        DELETE FROM sch_group
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 804---------------------------------------------------
    
        DELETE FROM sch_rehab_group
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 805---------------------------------------------------
    
        DELETE FROM sch_resource
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 806---------------------------------------------------
    
        DELETE FROM susp_task_schedules
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 807---------------------------------------------------
    
        UPDATE sys_alert_det
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 808---------------------------------------------------
    
        UPDATE vaccine_presc_plan
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ Nº 809---------------------------------------------------
    
        UPDATE analysis_req
           SET id_schedule = NULL, flg_status = 'PA'
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
    END reset_sch_alert;

    /**********************************************************************************************
    * This Function calls the procedures to do the 
    * deletes/updates tables related with the schedulers on the schema 
    * ALERT/ADTCOD/PRODUCT_TR/APSSCHDLR
    *
    * @param i_lang                          ID Language NUMBER
    * @param i_inst                          ID Institution NUMBER
    *
    * @return                                true (success), false (erroR)
    * @author                                Ruben Araujo
    * @version                               1.0
    * @since                                 2016/05/17
    **********************************************************************************************/

    FUNCTION reset_sch_by_inst
    (
        i_lang  IN language.id_language%TYPE,
        i_inst  IN NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_sch_alert_ids     table_number;
        l_sch_apsschdlr_ids table_number;
        l_message           VARCHAR2(1000 CHAR);
        l_temp              NUMBER;
    
    BEGIN
    
        l_message := '[1] BULK COLLECT INTO L_SCH_APSSCHDLR_IDS - ID_INSTITUTION ' || i_inst;
    
        BEGIN
            SELECT /*+ OPT_ESTIMATE(table s rows = 1)*/
            DISTINCT s.id_schedule
              BULK COLLECT
              INTO l_sch_apsschdlr_ids
              FROM alert_apsschdlr_tr.schedule s
              JOIN alert_apsschdlr_tr.service ser
                ON (s.id_service = ser.id_service)
              JOIN alert_apsschdlr_tr.department de
                ON (ser.id_department = de.id_department)
              JOIN alert_apsschdlr_tr.facility f
                ON (de.id_facility = f.id_facility)
              JOIN alert_apsschdlr_tr.schedule_procedure sp
                ON (s.id_schedule = sp.id_schedule)
             WHERE f.id_ab_institution_facility = i_inst
             ORDER BY s.id_schedule DESC;
        EXCEPTION
            WHEN no_data_found THEN
                l_message := '[1] NO SCHEDULERS TO PUT INTO L_SCH_APSSCHDLR_IDS - ID_INSTITUTION ' || i_inst;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  l_message,
                                                  c_package_owner,
                                                  c_package_name,
                                                  'RESET_SCH_BY_INST',
                                                  o_error);
        END;
    
        l_message := '[2] BULK COLLECT INTO L_SCH_ALERT_IDS - ID_INSTITUTION ' || i_inst;
    
        BEGIN
            SELECT /*+ OPT_ESTIMATE(table s rows = 1)*/
            DISTINCT schmap.id_schedule_pfh
              BULK COLLECT
              INTO l_sch_alert_ids
              FROM sch_api_map_ids schmap
             WHERE schmap.id_schedule_ext IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                               column_value
                                                FROM TABLE(l_sch_apsschdlr_ids));
        EXCEPTION
            WHEN no_data_found THEN
                l_message := '[2] NO SCHEDULERS TO PUT INTO L_SCH_ALERT_IDS - ID_INSTITUTION ' || i_inst;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  l_message,
                                                  c_package_owner,
                                                  c_package_name,
                                                  'RESET_SCH_BY_INST',
                                                  o_error);
        END;
    
        --SCHEMA APSSCHDLR
        IF l_sch_apsschdlr_ids IS NOT NULL
        THEN
            l_message := '[3] RESET_SCH_APSCHDLR_TR - ID_INSTITUTION ';
            alert_apsschdlr_tr.pk_reset_scheduler.reset_sch_apschdlr_tr(l_sch_apsschdlr_ids);
        END IF;
    
        --CREATING DUMMY SCHEDULES
        BEGIN
            SELECT id_schedule_sr
              INTO l_temp
              FROM schedule_sr r
             WHERE r.id_schedule_sr = -1;
        EXCEPTION
            WHEN no_data_found THEN
                INSERT INTO schedule_sr
                    (id_schedule_sr, id_patient, flg_status, flg_sched, id_institution)
                VALUES
                    (-1, -1, 'I', 'N', -1);
        END;
    
        BEGIN
            SELECT id_schedule
              INTO l_temp
              FROM schedule r
             WHERE r.id_schedule = -1;
        EXCEPTION
            WHEN no_data_found THEN
                INSERT INTO schedule
                    (id_schedule,
                     flg_status,
                     id_instit_requested,
                     id_instit_requests,
                     id_dcs_requested,
                     id_prof_schedules,
                     flg_urgency,
                     dt_begin_tstz,
                     dt_schedule_tstz)
                VALUES
                    (-3, 'D', -1, -1, -1, -1, 'N', current_timestamp, current_timestamp);
        END;
    
        --SCHEMA ADT ALERT PRODUCT_TR
        IF l_sch_alert_ids IS NOT NULL
        THEN
            l_message := '[3] RESET_SCH_ADTCOD ';
            alert_adtcod.pk_reset_scheduler.reset_sch_adtcod(l_sch_alert_ids);
            l_message := '[4] RESET_SCH_PRODUCT_TR';
            alert_product_tr.pk_reset_scheduler.reset_sch_product_tr(l_sch_alert_ids);
            l_message := '[5] RESET_SCH_ALERT ';
            pk_reset_scheduler.reset_sch_alert(l_sch_alert_ids);
        
            --delete dos agendamentos principais
            DELETE FROM schedule
             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                    column_value
                                     FROM TABLE(l_sch_alert_ids));
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLERRM);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              c_package_owner,
                                              c_package_name,
                                              'RESET_SCH_BY_INST',
                                              o_error);
            ROLLBACK;
            RETURN FALSE;
        
    END reset_sch_by_inst;

END;
/
