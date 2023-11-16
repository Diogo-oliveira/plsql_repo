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
    
        ------ N� 1---------------------------------------------------
    
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
    
        ------ N� 2---------------------------------------------------
    
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
    
        ------ N� 3---------------------------------------------------
    
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
    
        ------ N� 5---------------------------------------------------
    
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
    
        ------ N� 6---------------------------------------------------
    
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
    
        ------ N� 8---------------------------------------------------
    
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
    
        ------ N� 9---------------------------------------------------
    
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
    
        ------ N� 10---------------------------------------------------
    
        /* UPDATE
        SR_PROF_TEAM_DET_HIST SET ID_SR_PROF_TEAM_DET =NULL WHERE ID_SR_PROF_TEAM_DET IN (SELECT ID_SR_PROF_TEAM_DET FROM SR_PROF_TEAM_DET WHERE
        ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))))));*/
    
        ------ N� 11---------------------------------------------------
    
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
    
        ------ N� 12---------------------------------------------------
    
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
    
        ------ N� 13---------------------------------------------------
    
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
    
        ------ N� 14---------------------------------------------------
    
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
    
        ------ N� 17---------------------------------------------------
    
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
    
        ------ N� 18---------------------------------------------------
    
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
    
        ------ N� 19---------------------------------------------------
    
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
    
        ------ N� 20---------------------------------------------------
    
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
    
        ------ N� 21---------------------------------------------------
    
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
    
        ------ N� 22---------------------------------------------------
    
        /*UPDATE
        PRESC SET ID_VITAL_SIGN_READ =NULL WHERE ID_VITAL_SIGN_READ IN (SELECT ID_VITAL_SIGN_READ FROM VITAL_SIGN_READ WHERE
        ID_EPIS_TRIAGE IN (SELECT ID_EPIS_TRIAGE FROM EPIS_TRIAGE WHERE
        ID_TRANSPORTATION IN (SELECT ID_TRANSPORTATION FROM TRANSPORTATION WHERE
        ID_TRANSP_REQ IN (SELECT ID_TRANSP_REQ FROM TRANSP_REQ WHERE
        ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))))));*/
    
        ------ N� 23---------------------------------------------------
    
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
    
        ------ N� 24---------------------------------------------------
    
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
    
        ------ N� 25---------------------------------------------------
    
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
    
        ------ N� 26---------------------------------------------------
    
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
    
        ------ N� 27---------------------------------------------------
    
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
    
        ------ N� 28---------------------------------------------------
    
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
    
        ------ N� 29---------------------------------------------------
    
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
    
        ------ N� 30---------------------------------------------------
    
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
    
        ------ N� 31---------------------------------------------------
    
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
    
        ------ N� 32---------------------------------------------------
    
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
    
        ------ N� 33---------------------------------------------------
    
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
    
        ------ N� 34---------------------------------------------------
    
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
    
        ------ N� 35---------------------------------------------------
    
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
    
        ------ N� 36---------------------------------------------------
    
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
    
        ------ N� 37---------------------------------------------------
    
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
    
        ------ N� 38---------------------------------------------------
    
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
    
        ------ N� 39---------------------------------------------------
    
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
    
        ------ N� 40---------------------------------------------------
    
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
    
        ------ N� 41---------------------------------------------------
    
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
    
        ------ N� 42---------------------------------------------------
    
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
    
        ------ N� 43---------------------------------------------------
    
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
    
        ------ N� 44---------------------------------------------------
    
        /*UPDATE
        PRESC SET ID_VITAL_SIGN_READ =NULL WHERE ID_VITAL_SIGN_READ IN (SELECT ID_VITAL_SIGN_READ FROM VITAL_SIGN_READ WHERE
        ID_EPIS_TRIAGE IN (SELECT ID_EPIS_TRIAGE FROM EPIS_TRIAGE WHERE
        ID_TRANSPORTATION IN (SELECT ID_TRANSPORTATION FROM TRANSPORTATION WHERE
        ID_TRANSP_REQ IN (SELECT ID_TRANSP_REQ FROM TRANSP_REQ WHERE
        ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))))));*/
    
        ------ N� 45---------------------------------------------------
    
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
    
        ------ N� 46---------------------------------------------------
    
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
    
        ------ N� 47---------------------------------------------------
    
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
    
        ------ N� 48---------------------------------------------------
    
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
    
        ------ N� 49---------------------------------------------------
    
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
    
        ------ N� 50---------------------------------------------------
    
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
    
        ------ N� 51---------------------------------------------------
    
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
    
        ------ N� 52---------------------------------------------------
    
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
    
        ------ N� 53---------------------------------------------------
    
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
    
        ------ N� 54---------------------------------------------------
    
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
    
        ------ N� 55---------------------------------------------------
    
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
    
        ------ N� 56---------------------------------------------------
    
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
    
        ------ N� 57---------------------------------------------------
    
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
    
        ------ N� 58---------------------------------------------------
    
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
    
        ------ N� 59---------------------------------------------------
    
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
    
        ------ N� 60---------------------------------------------------
    
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
    
        ------ N� 61---------------------------------------------------
    
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
    
        ------ N� 62---------------------------------------------------
    
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
    
        ------ N� 70---------------------------------------------------
    
        /*UPDATE
        SR_POS_PHARM_DET SET ID_SR_POS_PHARM =NULL WHERE ID_SR_POS_PHARM IN (SELECT ID_SR_POS_PHARM FROM SR_POS_PHARM WHERE
        ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))))));*/
    
        ------ N� 71---------------------------------------------------
    
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
    
        ------ N� 72---------------------------------------------------
    
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
    
        ------ N� 73---------------------------------------------------
    
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
    
        ------ N� 74---------------------------------------------------
    
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
    
        ------ N� 75---------------------------------------------------
    
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
    
        ------ N� 76---------------------------------------------------
    
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
    
        ------ N� 77---------------------------------------------------
    
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
    
        ------ N� 78---------------------------------------------------
    
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
    
        ------ N� 79---------------------------------------------------
    
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
    
        ------ N� 80---------------------------------------------------
    
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
    
        ------ N� 81---------------------------------------------------
    
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
    
        ------ N� 82---------------------------------------------------
    
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
    
        ------ N� 83---------------------------------------------------
    
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
    
        ------ N� 84---------------------------------------------------
    
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
    
        ------ N� 85---------------------------------------------------
    
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
    
        ------ N� 86---------------------------------------------------
    
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
    
        ------ N� 87---------------------------------------------------
    
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
    
        ------ N� 88---------------------------------------------------
    
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
    
        ------ N� 89---------------------------------------------------
    
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
    
        ------ N� 90---------------------------------------------------
    
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
    
        ------ N� 97---------------------------------------------------
    
        /*UPDATE
        DISCHARGE_NOTES_FOLLOW_UP SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ N� 98---------------------------------------------------
    
        /*UPDATE
        DISCH_NOTES_DISCUSSED SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ N� 99---------------------------------------------------
    
        /*UPDATE
        SR_POS_PHARM SET ID_SR_POS_SCHEDULE =NULL WHERE ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ N� 100---------------------------------------------------
    
        /*DELETE FROM
        SR_POS_SCHEDULE_HIST WHERE ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ N� 101---------------------------------------------------
    
        /*UPDATE
        SR_PROF_TEAM_DET SET ID_SURGERY_RECORD =NULL WHERE ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ N� 102---------------------------------------------------
    
        /*UPDATE
        SR_SURGERY_REC_DET SET ID_SURGERY_RECORD =NULL WHERE ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ N� 103---------------------------------------------------
    
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
    
        ------ N� 104---------------------------------------------------
    
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
    
        ------ N� 105---------------------------------------------------
    
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
    
        ------ N� 106---------------------------------------------------
    
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
    
        ------ N� 107---------------------------------------------------
    
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
    
        ------ N� 108---------------------------------------------------
    
        /*UPDATE
        PRESC SET ID_VITAL_SIGN_READ =NULL WHERE ID_VITAL_SIGN_READ IN (SELECT ID_VITAL_SIGN_READ FROM VITAL_SIGN_READ WHERE
        ID_EPIS_TRIAGE IN (SELECT ID_EPIS_TRIAGE FROM EPIS_TRIAGE WHERE
        ID_TRANSPORTATION IN (SELECT ID_TRANSPORTATION FROM TRANSPORTATION WHERE
        ID_TRANSP_REQ IN (SELECT ID_TRANSP_REQ FROM TRANSP_REQ WHERE
        ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ N� 109---------------------------------------------------
    
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
    
        ------ N� 110---------------------------------------------------
    
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
    
        ------ N� 111---------------------------------------------------
    
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
    
        ------ N� 112---------------------------------------------------
    
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
    
        ------ N� 113---------------------------------------------------
    
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
    
        ------ N� 114---------------------------------------------------
    
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
    
        ------ N� 115---------------------------------------------------
    
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
    
        ------ N� 116---------------------------------------------------
    
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
    
        ------ N� 117---------------------------------------------------
    
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
    
        ------ N� 118---------------------------------------------------
    
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
    
        ------ N� 119---------------------------------------------------
    
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
    
        ------ N� 120---------------------------------------------------
    
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
    
        ------ N� 121---------------------------------------------------
    
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
    
        ------ N� 122---------------------------------------------------
    
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
    
        ------ N� 123---------------------------------------------------
    
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
    
        ------ N� 124---------------------------------------------------
    
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
    
        ------ N� 125---------------------------------------------------
    
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
    
        ------ N� 126---------------------------------------------------
    
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
    
        ------ N� 127---------------------------------------------------
    
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
    
        ------ N� 128---------------------------------------------------
    
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
    
        ------ N� 129---------------------------------------------------
    
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
    
        ------ N� 130---------------------------------------------------
    
        /*UPDATE
        PRESC SET ID_VITAL_SIGN_READ =NULL WHERE ID_VITAL_SIGN_READ IN (SELECT ID_VITAL_SIGN_READ FROM VITAL_SIGN_READ WHERE
        ID_EPIS_TRIAGE IN (SELECT ID_EPIS_TRIAGE FROM EPIS_TRIAGE WHERE
        ID_TRANSPORTATION IN (SELECT ID_TRANSPORTATION FROM TRANSPORTATION WHERE
        ID_TRANSP_REQ IN (SELECT ID_TRANSP_REQ FROM TRANSP_REQ WHERE
        ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ N� 131---------------------------------------------------
    
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
    
        ------ N� 132---------------------------------------------------
    
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
    
        ------ N� 133---------------------------------------------------
    
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
    
        ------ N� 134---------------------------------------------------
    
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
    
        ------ N� 135---------------------------------------------------
    
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
    
        ------ N� 136---------------------------------------------------
    
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
    
        ------ N� 137---------------------------------------------------
    
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
    
        ------ N� 138---------------------------------------------------
    
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
    
        ------ N� 139---------------------------------------------------
    
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
    
        ------ N� 140---------------------------------------------------
    
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
    
        ------ N� 141---------------------------------------------------
    
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
    
        ------ N� 142---------------------------------------------------
    
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
    
        ------ N� 143---------------------------------------------------
    
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
    
        ------ N� 144---------------------------------------------------
    
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
    
        ------ N� 145---------------------------------------------------
    
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
    
        ------ N� 146---------------------------------------------------
    
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
    
        ------ N� 147---------------------------------------------------
    
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
    
        ------ N� 148---------------------------------------------------
    
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
    
        ------ N� 156---------------------------------------------------
    
        /*UPDATE
        SR_POS_PHARM_DET SET ID_SR_POS_PHARM =NULL WHERE ID_SR_POS_PHARM IN (SELECT ID_SR_POS_PHARM FROM SR_POS_PHARM WHERE
        ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ N� 157---------------------------------------------------
    
        /*UPDATE
        SR_PROF_TEAM_DET_HIST SET ID_SR_PROF_TEAM_DET =NULL WHERE ID_SR_PROF_TEAM_DET IN (SELECT ID_SR_PROF_TEAM_DET FROM SR_PROF_TEAM_DET WHERE
        ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))))));*/
    
        ------ N� 158---------------------------------------------------
    
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
    
        ------ N� 159---------------------------------------------------
    
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
    
        ------ N� 160---------------------------------------------------
    
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
    
        ------ N� 161---------------------------------------------------
    
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
    
        ------ N� 162---------------------------------------------------
    
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
    
        ------ N� 163---------------------------------------------------
    
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
    
        ------ N� 164---------------------------------------------------
    
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
    
        ------ N� 165---------------------------------------------------
    
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
    
        ------ N� 166---------------------------------------------------
    
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
    
        ------ N� 167---------------------------------------------------
    
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
    
        ------ N� 168---------------------------------------------------
    
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
    
        ------ N� 169---------------------------------------------------
    
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
    
        ------ N� 170---------------------------------------------------
    
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
    
        ------ N� 171---------------------------------------------------
    
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
    
        ------ N� 172---------------------------------------------------
    
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
    
        ------ N� 173---------------------------------------------------
    
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
    
        ------ N� 174---------------------------------------------------
    
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
    
        ------ N� 192---------------------------------------------------
        /*
        UPDATE
        DOC_ACTIVITY_PARAM SET ID_DOC_ACTIVITY =NULL WHERE ID_DOC_ACTIVITY IN (SELECT ID_DOC_ACTIVITY FROM DOC_ACTIVITY WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 193---------------------------------------------------
        /*
        UPDATE
        DOC_COMMENTS SET ID_DOC_IMAGE =NULL WHERE ID_DOC_IMAGE IN (SELECT ID_DOC_IMAGE FROM DOC_IMAGE WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 194---------------------------------------------------
        /*
        UPDATE
        DISCHARGE_NOTES SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 195---------------------------------------------------
        /*
        UPDATE
        EPIS_REPORT_DISCLOSURE SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 196---------------------------------------------------
    
        /*UPDATE
        EPIS_REPORT_SECTION SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 197---------------------------------------------------
    
        /*UPDATE
        PRESC_PRINT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 198---------------------------------------------------
    
        /*UPDATE
        REF_REPORT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 199---------------------------------------------------
    
        /*UPDATE
        XDS_DOCUMENT_SUB_CONF_CODE SET ID_XDS_DOCUMENT_SUBMISSION =NULL WHERE ID_XDS_DOCUMENT_SUBMISSION IN (SELECT ID_XDS_DOCUMENT_SUBMISSION FROM XDS_DOCUMENT_SUBMISSION WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 200---------------------------------------------------
    
        /*UPDATE
        XDS_DOC_SUB_CONF_CODE_SET SET ID_XDS_DOCUMENT_SUBMISSION =NULL WHERE ID_XDS_DOCUMENT_SUBMISSION IN (SELECT ID_XDS_DOCUMENT_SUBMISSION FROM XDS_DOCUMENT_SUBMISSION WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 201---------------------------------------------------
    
        /*UPDATE
        DISCHARGE_NOTES_FOLLOW_UP SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 202---------------------------------------------------
    
        /*UPDATE
        DISCH_NOTES_DISCUSSED SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 203---------------------------------------------------
    
        /*DELETE FROM
        SCHEDULE_BED_HIST WHERE ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE_BED WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 204---------------------------------------------------
    
        /* UPDATE
        EPIS_INFO SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 205---------------------------------------------------
    
        /*DELETE FROM
        SCHEDULE_SR_HIST WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 206---------------------------------------------------
    
        /*UPDATE
        SR_CONSENT SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 207---------------------------------------------------
    
        /*UPDATE
        SR_DANGER_CONT SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 208---------------------------------------------------
    
        /*UPDATE
        SR_POS_SCHEDULE SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 209---------------------------------------------------
    
        /*DELETE FROM
        SR_POS_SCHEDULE_HIST WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 210---------------------------------------------------
    
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
    
        ------ N� 211---------------------------------------------------
    
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
    
        ------ N� 212---------------------------------------------------
    
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
    
        ------ N� 213---------------------------------------------------
    
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
    
        ------ N� 214---------------------------------------------------
    
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
    
        ------ N� 215---------------------------------------------------
    
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
    
        ------ N� 216---------------------------------------------------
    
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
    
        ------ N� 217---------------------------------------------------
    
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
    
        ------ N� 218---------------------------------------------------
    
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
    
        ------ N� 219---------------------------------------------------
    
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
    
        ------ N� 220---------------------------------------------------
    
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
    
        ------ N� 221---------------------------------------------------
    
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
    
        ------ N� 222---------------------------------------------------
    
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
    
        ------ N� 223---------------------------------------------------
    
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
    
        ------ N� 224---------------------------------------------------
    
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
    
        ------ N� 225---------------------------------------------------
    
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
    
        ------ N� 226---------------------------------------------------
    
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
    
        ------ N� 227---------------------------------------------------
    
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
    
        ------ N� 228---------------------------------------------------
    
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
    
        ------ N� 229---------------------------------------------------
    
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
    
        ------ N� 230---------------------------------------------------
    
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
    
        ------ N� 231---------------------------------------------------
    
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
    
        ------ N� 232---------------------------------------------------
    
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
    
        ------ N� 233---------------------------------------------------
    
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
    
        ------ N� 234---------------------------------------------------
    
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
    
        ------ N� 235---------------------------------------------------
    
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
    
        ------ N� 236---------------------------------------------------
    
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
    
        ------ N� 237---------------------------------------------------
    
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
    
        ------ N� 238---------------------------------------------------
    
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
    
        ------ N� 239---------------------------------------------------
    
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
    
        ------ N� 240---------------------------------------------------
    
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
    
        ------ N� 241---------------------------------------------------
    
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
    
        ------ N� 248---------------------------------------------------
    
        /*UPDATE
        DISCHARGE_NOTES_FOLLOW_UP SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 249---------------------------------------------------
    
        /*UPDATE
        DISCH_NOTES_DISCUSSED SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 250---------------------------------------------------
    
        /*UPDATE
        SR_POS_PHARM SET ID_SR_POS_SCHEDULE =NULL WHERE ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 251---------------------------------------------------
    
        /*DELETE FROM
        SR_POS_SCHEDULE_HIST WHERE ID_SR_POS_SCHEDULE IN (SELECT ID_SR_POS_SCHEDULE FROM SR_POS_SCHEDULE WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 252---------------------------------------------------
    
        /*UPDATE
        SR_PROF_TEAM_DET SET ID_SURGERY_RECORD =NULL WHERE ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 253---------------------------------------------------
    
        /* UPDATE
        SR_SURGERY_REC_DET SET ID_SURGERY_RECORD =NULL WHERE ID_SURGERY_RECORD IN (SELECT ID_SURGERY_RECORD FROM SR_SURGERY_RECORD WHERE
        ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))))));*/
    
        ------ N� 254---------------------------------------------------
    
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
    
        ------ N� 255---------------------------------------------------
    
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
    
        ------ N� 256---------------------------------------------------
    
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
    
        ------ N� 257---------------------------------------------------
    
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
    
        ------ N� 258---------------------------------------------------
    
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
    
        ------ N� 259---------------------------------------------------
    
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
    
        ------ N� 260---------------------------------------------------
    
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
    
        ------ N� 261---------------------------------------------------
    
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
    
        ------ N� 262---------------------------------------------------
    
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
    
        ------ N� 263---------------------------------------------------
    
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
    
        ------ N� 264---------------------------------------------------
    
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
    
        ------ N� 265---------------------------------------------------
    
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
    
        ------ N� 266---------------------------------------------------
    
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
    
        ------ N� 267---------------------------------------------------
    
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
    
        ------ N� 268---------------------------------------------------
    
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
    
        ------ N� 269---------------------------------------------------
    
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
    
        ------ N� 270---------------------------------------------------
    
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
    
        ------ N� 271---------------------------------------------------
    
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
    
        ------ N� 272---------------------------------------------------
    
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
    
        ------ N� 273---------------------------------------------------
    
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
    
        ------ N� 274---------------------------------------------------
    
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
    
        ------ N� 275---------------------------------------------------
    
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
    
        ------ N� 276---------------------------------------------------
    
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
    
        ------ N� 277---------------------------------------------------
    
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
    
        ------ N� 278---------------------------------------------------
    
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
    
        ------ N� 279---------------------------------------------------
    
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
    
        ------ N� 280---------------------------------------------------
    
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
    
        ------ N� 285---------------------------------------------------
    
        /*UPDATE
        ANALYSIS_MEDIA_ARCHIVE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 286---------------------------------------------------
        
        UPDATE
        DOC_ACTIVITY SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 287---------------------------------------------------
        
        UPDATE
        DOC_COMMENTS SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ N� 288---------------------------------------------------
    
        /*UPDATE
        DOC_EXTERNAL_US SET ID_DOC_EXTERNAL_US =NULL WHERE ID_DOC_EXTERNAL_US IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ N� 289---------------------------------------------------
    
        /*UPDATE
        DOC_IMAGE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 290---------------------------------------------------
        
        UPDATE
        EPIS_REPORT SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 291---------------------------------------------------
        
        UPDATE
        EXAM_MEDIA_ARCHIVE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 292---------------------------------------------------
        
        UPDATE
        EXAM_RES_FETUS_BIOM_IMG SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 293---------------------------------------------------
        
        UPDATE
        PAT_ADV_DIRECTIVE_DOC SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ N� 294---------------------------------------------------
    
        /*UPDATE
        PAT_AMENDMENT_DOC SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ N� 295---------------------------------------------------
    
        /*UPDATE
        XDS_DOCUMENT_SUBMISSION SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 296---------------------------------------------------
        
        UPDATE
        DISCHARGE_NOTES SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 297---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_DISCLOSURE SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 298---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_SECTION SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 299---------------------------------------------------
        
        UPDATE
        PRESC_PRINT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 300---------------------------------------------------
        
        UPDATE
        REF_REPORT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 301---------------------------------------------------
        
        UPDATE
        P1_DETAIL SET ID_TRACKING =NULL WHERE ID_TRACKING IN (SELECT ID_TRACKING FROM P1_TRACKING WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 302---------------------------------------------------
        
        UPDATE
        REF_EXT_XML_DATA SET ID_SESSION =NULL WHERE ID_SESSION IN (SELECT ID_SESSION FROM REF_EXT_SESSION WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ N� 303---------------------------------------------------
    
        /* UPDATE
        REF_TRANS_RESP_HIST SET ID_TRANS_RESP =NULL WHERE ID_TRANS_RESP IN (SELECT ID_TRANS_RESP FROM REF_TRANS_RESPONSIBILITY WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ N� 304---------------------------------------------------
    
        /*DELETE FROM
        SCHEDULE_BED WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 305---------------------------------------------------
        
        DELETE FROM
        SCHEDULE_SR WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 306---------------------------------------------------
        
        UPDATE
        WAITING_LIST_HIST SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 307---------------------------------------------------
        
        UPDATE
        WTL_DEP_CLIN_SERV SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 308---------------------------------------------------
        
        UPDATE
        WTL_DOCUMENTATION SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 309---------------------------------------------------
        
        UPDATE
        WTL_EPIS SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 310---------------------------------------------------
        
        UPDATE
        WTL_PREF_TIME SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 311---------------------------------------------------
        
        UPDATE
        WTL_PROF SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 312---------------------------------------------------
        
        UPDATE
        WTL_PTREASON_WTLIST SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 313---------------------------------------------------
        
        UPDATE
        WTL_UNAV SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ N� 314---------------------------------------------------
    
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
    
        ------ N� 315---------------------------------------------------
    
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
    
        ------ N� 316---------------------------------------------------
    
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
    
        ------ N� 317---------------------------------------------------
    
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
    
        ------ N� 318---------------------------------------------------
    
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
    
        ------ N� 319---------------------------------------------------
    
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
    
        ------ N� 320---------------------------------------------------
    
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
    
        ------ N� 321---------------------------------------------------
    
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
    
        ------ N� 322---------------------------------------------------
    
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
    
        ------ N� 323---------------------------------------------------
    
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
    
        ------ N� 324---------------------------------------------------
    
        /*UPDATE
          SR_DANGER_CONT SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
          ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
          ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
          ------ N� 325---------------------------------------------------
        
          UPDATE
          SR_POS_SCHEDULE SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
          ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
          ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
          ------ N� 326---------------------------------------------------
        
          DELETE FROM
          SR_POS_SCHEDULE_HIST WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
          ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
          ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        */
        ------ N� 327---------------------------------------------------
    
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
    
        ------ N� 328---------------------------------------------------
    
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
    
        ------ N� 329---------------------------------------------------
    
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
    
        ------ N� 330---------------------------------------------------
    
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
    
        ------ N� 331---------------------------------------------------
    
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
    
        ------ N� 332---------------------------------------------------
    
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
    
        ------ N� 333---------------------------------------------------
    
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
    
        ------ N� 334---------------------------------------------------
    
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
    
        ------ N� 335---------------------------------------------------
    
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
    
        ------ N� 336---------------------------------------------------
    
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
    
        ------ N� 337---------------------------------------------------
    
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
    
        ------ N� 338---------------------------------------------------
    
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
    
        ------ N� 339---------------------------------------------------
    
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
    
        ------ N� 340---------------------------------------------------
    
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
    
        ------ N� 341---------------------------------------------------
    
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
    
        ------ N� 342---------------------------------------------------
    
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
    
        ------ N� 343---------------------------------------------------
    
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
    
        ------ N� 344---------------------------------------------------
    
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
    
        ------ N� 345---------------------------------------------------
    
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
    
        ------ N� 346---------------------------------------------------
    
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
    
        ------ N� 347---------------------------------------------------
    
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
    
        ------ N� 348---------------------------------------------------
    
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
    
        ------ N� 349---------------------------------------------------
    
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
    
        ------ N� 350---------------------------------------------------
    
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
    
        ------ N� 351---------------------------------------------------
    
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
    
        ------ N� 352---------------------------------------------------
    
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
    
        ------ N� 353---------------------------------------------------
    
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
    
        ------ N� 354---------------------------------------------------
    
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
    
        ------ N� 355---------------------------------------------------
    
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
    
        ------ N� 356---------------------------------------------------
    
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
    
        ------ N� 357---------------------------------------------------
    
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
    
        ------ N� 358---------------------------------------------------
    
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
    
        ------ N� 359---------------------------------------------------
    
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
    
        ------ N� 360---------------------------------------------------
    
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
    
        ------ N� 361---------------------------------------------------
    
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
    
        ------ N� 362---------------------------------------------------
    
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
    
        ------ N� 363---------------------------------------------------
    
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
    
        ------ N� 364---------------------------------------------------
    
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
    
        ------ N� 365---------------------------------------------------
    
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
    
        ------ N� 366---------------------------------------------------
    
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
    
        ------ N� 367---------------------------------------------------
    
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
    
        ------ N� 368---------------------------------------------------
    
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
    
        ------ N� 369---------------------------------------------------
    
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
    
        ------ N� 370---------------------------------------------------
    
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
    
        ------ N� 371---------------------------------------------------
    
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
    
        ------ N� 372---------------------------------------------------
    
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
    
        ------ N� 373---------------------------------------------------
    
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
    
        ------ N� 374---------------------------------------------------
    
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
    
        ------ N� 375---------------------------------------------------
    
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
    
        ------ N� 376---------------------------------------------------
    
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
    
        ------ N� 377---------------------------------------------------
    
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
    
        ------ N� 378---------------------------------------------------
    
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
    
        ------ N� 379---------------------------------------------------
    
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
    
        ------ N� 380---------------------------------------------------
    
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
    
        ------ N� 381---------------------------------------------------
    
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
    
        ------ N� 382---------------------------------------------------
    
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
    
        ------ N� 383---------------------------------------------------
    
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
    
        ------ N� 384---------------------------------------------------
    
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
    
        ------ N� 385---------------------------------------------------
    
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
    
        ------ N� 386---------------------------------------------------
    
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
    
        ------ N� 387---------------------------------------------------
    
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
    
        ------ N� 388---------------------------------------------------
    
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
    
        ------ N� 389---------------------------------------------------
    
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
    
        ------ N� 390---------------------------------------------------
    
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
    
        ------ N� 391---------------------------------------------------
    
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
    
        ------ N� 392---------------------------------------------------
    
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
    
        ------ N� 393---------------------------------------------------
    
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
    
        ------ N� 394---------------------------------------------------
    
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
    
        ------ N� 395---------------------------------------------------
    
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
    
        ------ N� 396---------------------------------------------------
    
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
    
        ------ N� 397---------------------------------------------------
    
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
    
        ------ N� 398---------------------------------------------------
    
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
    
        ------ N� 399---------------------------------------------------
    
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
    
        ------ N� 400---------------------------------------------------
    
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
    
        ------ N� 401---------------------------------------------------
    
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
    
        ------ N� 402---------------------------------------------------
    
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
    
        ------ N� 403---------------------------------------------------
    
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
    
        ------ N� 404---------------------------------------------------
    
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
    
        ------ N� 405---------------------------------------------------
    
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
    
        ------ N� 406---------------------------------------------------
    
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
    
        ------ N� 407---------------------------------------------------
    
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
    
        ------ N� 408---------------------------------------------------
    
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
    
        ------ N� 409---------------------------------------------------
    
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
    
        ------ N� 410---------------------------------------------------
    
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
    
        ------ N� 411---------------------------------------------------
    
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
    
        ------ N� 412---------------------------------------------------
    
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
    
        ------ N� 413---------------------------------------------------
    
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
    
        ------ N� 414---------------------------------------------------
    
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
    
        ------ N� 415---------------------------------------------------
    
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
    
        ------ N� 416---------------------------------------------------
    
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
    
        ------ N� 417---------------------------------------------------
    
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
    
        ------ N� 418---------------------------------------------------
    
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
    
        ------ N� 419---------------------------------------------------
    
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
    
        ------ N� 437---------------------------------------------------
        /*
        UPDATE
        DOC_ACTIVITY_PARAM SET ID_DOC_ACTIVITY =NULL WHERE ID_DOC_ACTIVITY IN (SELECT ID_DOC_ACTIVITY FROM DOC_ACTIVITY WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 438---------------------------------------------------
        
        UPDATE
        DOC_COMMENTS SET ID_DOC_IMAGE =NULL WHERE ID_DOC_IMAGE IN (SELECT ID_DOC_IMAGE FROM DOC_IMAGE WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 439---------------------------------------------------
        
        UPDATE
        DISCHARGE_NOTES SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 440---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_DISCLOSURE SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 441---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_SECTION SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 442---------------------------------------------------
        
        UPDATE
        PRESC_PRINT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 443---------------------------------------------------
        
        UPDATE
        REF_REPORT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 444---------------------------------------------------
        
        UPDATE
        XDS_DOCUMENT_SUB_CONF_CODE SET ID_XDS_DOCUMENT_SUBMISSION =NULL WHERE ID_XDS_DOCUMENT_SUBMISSION IN (SELECT ID_XDS_DOCUMENT_SUBMISSION FROM XDS_DOCUMENT_SUBMISSION WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 445---------------------------------------------------
        
        UPDATE
        XDS_DOC_SUB_CONF_CODE_SET SET ID_XDS_DOCUMENT_SUBMISSION =NULL WHERE ID_XDS_DOCUMENT_SUBMISSION IN (SELECT ID_XDS_DOCUMENT_SUBMISSION FROM XDS_DOCUMENT_SUBMISSION WHERE
        ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 446---------------------------------------------------
        
        UPDATE
        DISCHARGE_NOTES_FOLLOW_UP SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 447---------------------------------------------------
        
        UPDATE
        DISCH_NOTES_DISCUSSED SET ID_DISCHARGE_NOTES =NULL WHERE ID_DISCHARGE_NOTES IN (SELECT ID_DISCHARGE_NOTES FROM DISCHARGE_NOTES WHERE
        ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 448---------------------------------------------------
        
        DELETE FROM
        SCHEDULE_BED_HIST WHERE ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE_BED WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 449---------------------------------------------------
        
        UPDATE
        EPIS_INFO SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 450---------------------------------------------------
        
        DELETE FROM
        SCHEDULE_SR_HIST WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));
        
        ------ N� 451---------------------------------------------------
        
        UPDATE
        SR_CONSENT SET ID_SCHEDULE_SR =NULL WHERE ID_SCHEDULE_SR IN (SELECT ID_SCHEDULE_SR FROM SCHEDULE_SR WHERE
        ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t)))));*/
    
        ------ N� 452---------------------------------------------------
    
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
    
        ------ N� 453---------------------------------------------------
    
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
    
        ------ N� 454---------------------------------------------------
    
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
    
        ------ N� 455---------------------------------------------------
    
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
    
        ------ N� 456---------------------------------------------------
    
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
    
        ------ N� 457---------------------------------------------------
    
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
    
        ------ N� 458---------------------------------------------------
    
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
    
        ------ N� 459---------------------------------------------------
    
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
    
        ------ N� 460---------------------------------------------------
    
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
    
        ------ N� 461---------------------------------------------------
    
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
    
        ------ N� 462---------------------------------------------------
    
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
    
        ------ N� 463---------------------------------------------------
    
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
    
        ------ N� 464---------------------------------------------------
    
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
    
        ------ N� 465---------------------------------------------------
    
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
    
        ------ N� 466---------------------------------------------------
    
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
    
        ------ N� 467---------------------------------------------------
    
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
    
        ------ N� 468---------------------------------------------------
    
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
    
        ------ N� 469---------------------------------------------------
    
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
    
        ------ N� 470---------------------------------------------------
    
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
    
        ------ N� 471---------------------------------------------------
    
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
    
        ------ N� 472---------------------------------------------------
    
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
    
        ------ N� 473---------------------------------------------------
    
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
    
        ------ N� 474---------------------------------------------------
    
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
    
        ------ N� 475---------------------------------------------------
    
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
    
        ------ N� 476---------------------------------------------------
    
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
    
        ------ N� 477---------------------------------------------------
    
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
    
        ------ N� 478---------------------------------------------------
    
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
    
        ------ N� 479---------------------------------------------------
    
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
    
        ------ N� 480---------------------------------------------------
    
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
    
        ------ N� 481---------------------------------------------------
    
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
    
        ------ N� 482---------------------------------------------------
    
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
    
        ------ N� 483---------------------------------------------------
    
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
    
        ------ N� 484---------------------------------------------------
    
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
    
        ------ N� 485---------------------------------------------------
    
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
    
        ------ N� 486---------------------------------------------------
    
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
    
        ------ N� 487---------------------------------------------------
    
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
    
        ------ N� 488---------------------------------------------------
    
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
    
        ------ N� 489---------------------------------------------------
    
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
    
        ------ N� 490---------------------------------------------------
    
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
    
        ------ N� 491---------------------------------------------------
    
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
    
        ------ N� 492---------------------------------------------------
    
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
    
        ------ N� 493---------------------------------------------------
    
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
    
        ------ N� 494---------------------------------------------------
    
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
    
        ------ N� 495---------------------------------------------------
    
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
    
        ------ N� 496---------------------------------------------------
    
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
    
        ------ N� 497---------------------------------------------------
    
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
    
        ------ N� 498---------------------------------------------------
    
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
    
        ------ N� 499---------------------------------------------------
    
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
    
        ------ N� 500---------------------------------------------------
    
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
    
        ------ N� 501---------------------------------------------------
    
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
    
        ------ N� 502---------------------------------------------------
    
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
    
        ------ N� 503---------------------------------------------------
    
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
    
        ------ N� 504---------------------------------------------------
    
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
    
        ------ N� 505---------------------------------------------------
    
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
    
        ------ N� 506---------------------------------------------------
    
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
    
        ------ N� 507---------------------------------------------------
    
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
    
        ------ N� 508---------------------------------------------------
    
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
    
        ------ N� 509---------------------------------------------------
    
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
    
        ------ N� 510---------------------------------------------------
    
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
    
        ------ N� 511---------------------------------------------------
    
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
    
        ------ N� 512---------------------------------------------------
    
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
    
        ------ N� 513---------------------------------------------------
    
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
    
        ------ N� 514---------------------------------------------------
    
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
    
        ------ N� 519---------------------------------------------------
    
        /* UPDATE
        ANALYSIS_MEDIA_ARCHIVE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 520---------------------------------------------------
        
        UPDATE
        DOC_ACTIVITY SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 521---------------------------------------------------
        
        UPDATE
        DOC_COMMENTS SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ N� 522---------------------------------------------------
    
        /*UPDATE
        DOC_EXTERNAL_US SET ID_DOC_EXTERNAL_US =NULL WHERE ID_DOC_EXTERNAL_US IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ N� 523---------------------------------------------------
        /*
        UPDATE
        DOC_IMAGE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 524---------------------------------------------------
        
        UPDATE
        EPIS_REPORT SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 525---------------------------------------------------
        
        UPDATE
        EXAM_MEDIA_ARCHIVE SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 526---------------------------------------------------
        
        UPDATE
        EXAM_RES_FETUS_BIOM_IMG SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 527---------------------------------------------------
        
        UPDATE
        PAT_ADV_DIRECTIVE_DOC SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ N� 528---------------------------------------------------
    
        /*UPDATE
        PAT_AMENDMENT_DOC SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ N� 529---------------------------------------------------
        /*
        UPDATE
        XDS_DOCUMENT_SUBMISSION SET ID_DOC_EXTERNAL =NULL WHERE ID_DOC_EXTERNAL IN (SELECT ID_DOC_EXTERNAL FROM DOC_EXTERNAL WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 530---------------------------------------------------
        
        UPDATE
        DISCHARGE_NOTES SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 531---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_DISCLOSURE SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 532---------------------------------------------------
        
        UPDATE
        EPIS_REPORT_SECTION SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 533---------------------------------------------------
        
        UPDATE
        PRESC_PRINT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 534---------------------------------------------------
        
        UPDATE
        REF_REPORT SET ID_EPIS_REPORT =NULL WHERE ID_EPIS_REPORT IN (SELECT ID_EPIS_REPORT FROM EPIS_REPORT WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 535---------------------------------------------------
        
        UPDATE
        P1_DETAIL SET ID_TRACKING =NULL WHERE ID_TRACKING IN (SELECT ID_TRACKING FROM P1_TRACKING WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 536---------------------------------------------------
        
        UPDATE
        REF_EXT_XML_DATA SET ID_SESSION =NULL WHERE ID_SESSION IN (SELECT ID_SESSION FROM REF_EXT_SESSION WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 537---------------------------------------------------
        
        UPDATE
        REF_TRANS_RESP_HIST SET ID_TRANS_RESP =NULL WHERE ID_TRANS_RESP IN (SELECT ID_TRANS_RESP FROM REF_TRANS_RESPONSIBILITY WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 538---------------------------------------------------
        
        DELETE FROM
        SCHEDULE_BED WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 539---------------------------------------------------
        
        DELETE FROM
        SCHEDULE_SR WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 540---------------------------------------------------
        
        UPDATE
        WAITING_LIST_HIST SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 541---------------------------------------------------
        
        UPDATE
        WTL_DEP_CLIN_SERV SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 542---------------------------------------------------
        
        UPDATE
        WTL_DOCUMENTATION SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 543---------------------------------------------------
        
        UPDATE
        WTL_EPIS SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 544---------------------------------------------------
        
        UPDATE
        WTL_PREF_TIME SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 545---------------------------------------------------
        
        UPDATE
        WTL_PROF SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 546---------------------------------------------------
        
        UPDATE
        WTL_PTREASON_WTLIST SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 547---------------------------------------------------
        
        UPDATE
        WTL_UNAV SET ID_WAITING_LIST =NULL WHERE ID_WAITING_LIST IN (SELECT ID_WAITING_LIST FROM WAITING_LIST WHERE
        ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ N� 548---------------------------------------------------
    
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
    
        ------ N� 549---------------------------------------------------
    
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
    
        ------ N� 550---------------------------------------------------
    
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
    
        ------ N� 551---------------------------------------------------
    
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
    
        ------ N� 552---------------------------------------------------
    
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
    
        ------ N� 553---------------------------------------------------
    
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
    
        ------ N� 554---------------------------------------------------
    
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
    
        ------ N� 555---------------------------------------------------
    
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
    
        ------ N� 556---------------------------------------------------
    
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
    
        ------ N� 557---------------------------------------------------
    
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
    
        ------ N� 558---------------------------------------------------
    
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
    
        ------ N� 559---------------------------------------------------
    
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
    
        ------ N� 560---------------------------------------------------
    
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
    
        ------ N� 561---------------------------------------------------
    
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
    
        ------ N� 562---------------------------------------------------
    
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
    
        ------ N� 563---------------------------------------------------
    
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
    
        ------ N� 564---------------------------------------------------
    
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
    
        ------ N� 565---------------------------------------------------
    
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
    
        ------ N� 566---------------------------------------------------
    
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
    
        ------ N� 567---------------------------------------------------
    
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
    
        ------ N� 568---------------------------------------------------
    
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
    
        ------ N� 569---------------------------------------------------
    
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
    
        ------ N� 570---------------------------------------------------
    
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
    
        ------ N� 571---------------------------------------------------
    
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
    
        ------ N� 572---------------------------------------------------
    
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
    
        ------ N� 573---------------------------------------------------
    
        /*UPDATE
        REQUEST_APPROVAL SET ID_CONSULT_REQ =NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 574---------------------------------------------------
        
        UPDATE
        REQUEST_APPROVAL SET ID_CONSULT_REQ =NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ N� 575---------------------------------------------------
        /*
        UPDATE
        REQUEST_PROF SET ID_CONSULT_REQ =NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 576---------------------------------------------------
        
        UPDATE
        REQUEST_PROF SET ID_CONSULT_REQ =NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ N� 577---------------------------------------------------
    
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
    
        ------ N� 578---------------------------------------------------
    
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
    
        ------ N� 579---------------------------------------------------
    
        /*UPDATE
        SR_POS_SCHEDULE SET ID_POS_CONSULT_REQ =NULL WHERE ID_POS_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
        ------ N� 580---------------------------------------------------
        
        UPDATE
        SR_POS_SCHEDULE SET ID_POS_CONSULT_REQ =NULL WHERE ID_POS_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));*/
    
        ------ N� 581---------------------------------------------------
    
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
    
        ------ N� 582---------------------------------------------------
    
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
    
        ------ N� 583---------------------------------------------------
    
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
    
        ------ N� 584---------------------------------------------------
    
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
    
        ------ N� 585---------------------------------------------------
    
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
    
        ------ N� 586---------------------------------------------------
    
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
    
        ------ N� 587---------------------------------------------------
    
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
    
        ------ N� 588---------------------------------------------------
    
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
    
        ------ N� 589---------------------------------------------------
    
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
    
        ------ N� 590---------------------------------------------------
    
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
    
        ------ N� 591---------------------------------------------------
    
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
    
        ------ N� 592---------------------------------------------------
    
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
    
        ------ N� 593---------------------------------------------------
    
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
    
        ------ N� 594---------------------------------------------------
    
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
    
        ------ N� 595---------------------------------------------------
    
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
    
        ------ N� 596---------------------------------------------------
    
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
    
        ------ N� 598---------------------------------------------------
        /*
          UPDATE
          DOC_EXTERNAL SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 599---------------------------------------------------
        
          UPDATE
          EPIS_REPORT SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 600---------------------------------------------------
        
          UPDATE
          P1_DETAIL SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 601---------------------------------------------------
        
          UPDATE
          P1_EXR_ANALYSIS SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 602---------------------------------------------------
        
          UPDATE
          P1_EXR_DIAGNOSIS SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 603---------------------------------------------------
        
          UPDATE
          P1_EXR_EXAM SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 604---------------------------------------------------
        
          UPDATE
          P1_EXR_INTERVENTION SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 605---------------------------------------------------
        
          UPDATE
          P1_EXR_TEMP SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 606---------------------------------------------------
        
          UPDATE
          P1_TASK_DONE SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 607---------------------------------------------------
        
          UPDATE
          P1_TRACKING SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows =1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 608---------------------------------------------------
        
          UPDATE
          REFERRAL_EA SET ID_EXTERNAL_REQUEST =NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 609---------------------------------------------------
        
          UPDATE
          REF_EXT_SESSION SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 610---------------------------------------------------
        
          UPDATE
          REF_MAP SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 611---------------------------------------------------
        
          UPDATE
          REF_MIG_INST_DEST SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 612---------------------------------------------------
        
          UPDATE
          REF_MIG_INST_DEST_DATA SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 613---------------------------------------------------
        
          UPDATE
          REF_ORIG_DATA SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 614---------------------------------------------------
        
          UPDATE
          REF_PIO SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 615---------------------------------------------------
        
          UPDATE
          REF_PIO_TRACKING SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 616---------------------------------------------------
        
          UPDATE
          REF_REPORT SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 617---------------------------------------------------
        
          UPDATE
          REF_TRANS_RESPONSIBILITY SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 618---------------------------------------------------
        
          UPDATE
          REF_UPDATE_EVENT SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        
          ------ N� 619---------------------------------------------------
        
          UPDATE
          WAITING_LIST SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t))));
        */
        ------ N� 620---------------------------------------------------
    
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
    
        ------ N� 621---------------------------------------------------
    
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
    
        ------ N� 622---------------------------------------------------
    
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
    
        ------ N� 623---------------------------------------------------
    
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
    
        ------ N� 624---------------------------------------------------
    
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
    
        ------ N� 625---------------------------------------------------
    
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
    
        ------ N� 626---------------------------------------------------
    
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
    
        ------ N� 627---------------------------------------------------
    
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
    
        ------ N� 628---------------------------------------------------
    
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
    
        ------ N� 629---------------------------------------------------
    
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
    
        ------ N� 630---------------------------------------------------
    
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
    
        ------ N� 631---------------------------------------------------
    
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
    
        ------ N� 632---------------------------------------------------
    
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
    
        ------ N� 633---------------------------------------------------
    
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
    
        ------ N� 634---------------------------------------------------
    
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
    
        ------ N� 635---------------------------------------------------
    
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
    
        ------ N� 636---------------------------------------------------
    
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
    
        ------ N� 637---------------------------------------------------
    
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
    
        ------ N� 638---------------------------------------------------
    
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
    
        ------ N� 639---------------------------------------------------
    
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
    
        ------ N� 640---------------------------------------------------
    
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
    
        ------ N� 641---------------------------------------------------
    
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
    
        ------ N� 642---------------------------------------------------
    
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
    
        ------ N� 643---------------------------------------------------
        /*
          UPDATE
          REF_MIG_INST_DEST_DATA SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 644---------------------------------------------------
        
          UPDATE
          REF_ORIG_DATA SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 645---------------------------------------------------
        
          UPDATE
          REF_PIO SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 646---------------------------------------------------
        
          UPDATE
          REF_PIO_TRACKING SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 647---------------------------------------------------
        
          UPDATE
          REF_REPORT SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 648---------------------------------------------------
        
          UPDATE
          REF_TRANS_RESPONSIBILITY SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 649---------------------------------------------------
        
          UPDATE
          REF_UPDATE_EVENT SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 650---------------------------------------------------
        
          UPDATE
          WAITING_LIST SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        */
        ------ N� 651---------------------------------------------------
    
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
    
        ------ N� 652---------------------------------------------------
    
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
    
        ------ N� 653---------------------------------------------------
    
        /*UPDATE
        ADMISSION_AMBULATORY SET ID_SCHEDULE=NULL WHERE ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE_REF IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));*/
    
        ------ N� 654---------------------------------------------------
    
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
    
        ------ N� 655---------------------------------------------------
    
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
    
        ------ N� 656---------------------------------------------------
    
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
    
        ------ N� 657---------------------------------------------------
    
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
    
        ------ N� 658---------------------------------------------------
    
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
    
        ------ N� 659---------------------------------------------------
    
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
    
        ------ N� 660---------------------------------------------------
    
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
    
        ------ N� 661---------------------------------------------------
    
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
    
        ------ N� 662---------------------------------------------------
    
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
    
        ------ N� 663---------------------------------------------------
    
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
    
        ------ N� 664---------------------------------------------------
    
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
    
        ------ N� 665---------------------------------------------------
    
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
    
        ------ N� 667---------------------------------------------------
    
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
    
        ------ N� 668---------------------------------------------------
    
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
    
        ------ N� 669---------------------------------------------------
    
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
    
        ------ N� 670---------------------------------------------------
    
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
    
        ------ N� 671---------------------------------------------------
    
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
    
        ------ N� 672---------------------------------------------------
    
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
    
        ------ N� 673---------------------------------------------------
    
        DELETE FROM room_scheduled
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 674---------------------------------------------------
    
        DELETE FROM schedule_analysis
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 675---------------------------------------------------
    
        DELETE FROM schedule_bed
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 676---------------------------------------------------
    
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
    
        ------ N� 677---------------------------------------------------
    
        DELETE FROM schedule_hist
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 678---------------------------------------------------
    
        DELETE FROM schedule_intervention
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 679---------------------------------------------------
    
        DELETE FROM schedule_outp
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 680---------------------------------------------------
    
        DELETE FROM schedule_sr
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 681---------------------------------------------------
    
        DELETE FROM sch_allocation
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 682---------------------------------------------------
    
        DELETE FROM sch_api_map_ids
         WHERE id_schedule_pfh IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 683---------------------------------------------------
    
        DELETE FROM sch_api_map_ids_hist
         WHERE id_schedule_pfh IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 684---------------------------------------------------
    
        DELETE FROM sch_clipboard
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 685---------------------------------------------------
    
        DELETE FROM sch_group
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 686---------------------------------------------------
    
        DELETE FROM sch_rehab_group
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 687---------------------------------------------------
    
        DELETE FROM sch_resource
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 688---------------------------------------------------
    
        DELETE FROM susp_task_schedules
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule
                 WHERE id_schedule_ref IN (SELECT id_schedule
                                             FROM schedule
                                            WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                   column_value
                                                                    FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 689---------------------------------------------------
    
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
    
        ------ N� 690---------------------------------------------------
    
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
    
        ------ N� 691---------------------------------------------------
    
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
    
        ------ N� 692---------------------------------------------------
    
        DELETE FROM schedule_bed_hist
         WHERE id_schedule IN
               (SELECT id_schedule
                  FROM schedule_bed
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 693---------------------------------------------------
    
        DELETE FROM schedule_exam_hist
         WHERE id_schedule_exam IN
               (SELECT id_schedule_exam
                  FROM schedule_exam
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 694---------------------------------------------------
    
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
    
        ------ N� 695---------------------------------------------------
    
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
    
        ------ N� 696---------------------------------------------------
    
        DELETE FROM schedule_outp_hist
         WHERE id_schedule_outp IN
               (SELECT id_schedule_outp
                  FROM schedule_outp
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 697---------------------------------------------------
    
        DELETE FROM sch_prof_outp
         WHERE id_schedule_outp IN
               (SELECT id_schedule_outp
                  FROM schedule_outp
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 698---------------------------------------------------
    
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
    
        ------ N� 699---------------------------------------------------
    
        DELETE FROM schedule_sr_hist
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 700---------------------------------------------------
    
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
    
        ------ N� 701---------------------------------------------------
    
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
    
        ------ N� 702---------------------------------------------------
    
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
    
        ------ N� 703---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 704---------------------------------------------------
    
        DELETE FROM sr_surgery_record
         WHERE id_schedule_sr IN
               (SELECT id_schedule_sr
                  FROM schedule_sr
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 705---------------------------------------------------
    
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
    
        ------ N� 706---------------------------------------------------
    
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
    
        ------ N� 707---------------------------------------------------
    
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
    
        ------ N� 708---------------------------------------------------
    
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
    
        ------ N� 709---------------------------------------------------
    
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
    
        ------ N� 710---------------------------------------------------
    
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
    
        ------ N� 711---------------------------------------------------
    
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
    
        ------ N� 712---------------------------------------------------
    
        DELETE FROM schedule_analysis
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 713---------------------------------------------------
    
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
    
        ------ N� 714---------------------------------------------------
    
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
    
        ------ N� 715---------------------------------------------------
    
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
    
        ------ N� 716---------------------------------------------------
    
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
    
        ------ N� 717---------------------------------------------------
    
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
    
        ------ N� 718---------------------------------------------------
    
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
    
        ------ N� 719---------------------------------------------------
    
        DELETE FROM schedule_analysis
         WHERE id_analysis_req IN
               (SELECT id_analysis_req
                  FROM analysis_req
                 WHERE id_sched_consult IN (SELECT id_schedule
                                              FROM schedule
                                             WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                    column_value
                                                                     FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 720---------------------------------------------------
    
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
    
        ------ N� 721---------------------------------------------------
    
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
    
        ------ N� 722---------------------------------------------------
    
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
    
        ------ N� 723---------------------------------------------------
    
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
    
        ------ N� 724---------------------------------------------------
    
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
    
        ------ N� 725---------------------------------------------------
    
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
    
        ------ N� 726---------------------------------------------------
    
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
    
        ------ N� 727---------------------------------------------------
    
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
    
        ------ N� 728---------------------------------------------------
    
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
    
        ------ N� 729---------------------------------------------------
    
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
    
        ------ N� 730---------------------------------------------------
    
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
    
        ------ N� 731---------------------------------------------------
    
        /*  UPDATE
        REQUEST_APPROVAL SET ID_CONSULT_REQ=NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
        ------ N� 732---------------------------------------------------
        
        UPDATE
        REQUEST_APPROVAL SET ID_CONSULT_REQ=NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));*/
    
        ------ N� 733---------------------------------------------------
    
        /*UPDATE
        REQUEST_PROF SET ID_CONSULT_REQ=NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
        ------ N� 734---------------------------------------------------
        
        UPDATE
        REQUEST_PROF SET ID_CONSULT_REQ=NULL WHERE ID_CONSULT_REQ IN (SELECT ID_CONSULT_REQ FROM CONSULT_REQ WHERE
        ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));*/
    
        ------ N� 735---------------------------------------------------
    
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
    
        ------ N� 736---------------------------------------------------
    
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
    
        ------ N� 737---------------------------------------------------
    
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
    
        ------ N� 738---------------------------------------------------
    
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
    
        ------ N� 739---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_pos_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 740---------------------------------------------------
    
        DELETE FROM sr_pos_schedule_hist
         WHERE id_pos_consult_req IN
               (SELECT id_consult_req
                  FROM consult_req
                 WHERE id_schedule IN (SELECT id_schedule
                                         FROM schedule
                                        WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                               column_value
                                                                FROM TABLE(i_scheduler_ids) t)));
    
        ------ N� 741---------------------------------------------------
    
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
    
        ------ N� 742---------------------------------------------------
    
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
    
        ------ N� 743---------------------------------------------------
    
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
    
        ------ N� 744---------------------------------------------------
    
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
    
        ------ N� 745---------------------------------------------------
    
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
    
        ------ N� 746---------------------------------------------------
    
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
    
        ------ N� 747---------------------------------------------------
    
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
    
        ------ N� 748---------------------------------------------------
    
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
    
        ------ N� 749---------------------------------------------------
    
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
    
        ------ N� 750---------------------------------------------------
    
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
    
        ------ N� 751---------------------------------------------------
    
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
    
        ------ N� 752---------------------------------------------------
    
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
    
        ------ N� 753---------------------------------------------------
    
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
    
        ------ N� 754---------------------------------------------------
    
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
    
        ------ N� 756---------------------------------------------------
        /*
          UPDATE
          DOC_EXTERNAL SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 757---------------------------------------------------
        
          UPDATE
          EPIS_REPORT SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 758---------------------------------------------------
        
          UPDATE
          P1_DETAIL SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 759---------------------------------------------------
        
          UPDATE
          P1_EXR_ANALYSIS SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 760---------------------------------------------------
        
          UPDATE
          P1_EXR_DIAGNOSIS SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 761---------------------------------------------------
        
          UPDATE
          P1_EXR_EXAM SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 762---------------------------------------------------
        
          UPDATE
          P1_EXR_INTERVENTION SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 763---------------------------------------------------
        
          UPDATE
          P1_EXR_TEMP SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 764---------------------------------------------------
        
          UPDATE
          P1_TASK_DONE SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 765---------------------------------------------------
        
          UPDATE
          P1_TRACKING SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 766---------------------------------------------------
        
          UPDATE
          REFERRAL_EA SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 767---------------------------------------------------
        
          UPDATE
          REF_EXT_SESSION SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 768---------------------------------------------------
        
          UPDATE
          REF_MAP SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        
          ------ N� 769---------------------------------------------------
        
          UPDATE
          REF_MIG_INST_DEST SET ID_EXTERNAL_REQUEST=NULL WHERE ID_EXTERNAL_REQUEST IN (SELECT ID_EXTERNAL_REQUEST FROM P1_EXTERNAL_REQUEST WHERE
          ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
          ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t)));
        */
        ------ N� 770---------------------------------------------------
    
        /*UPDATE
        ADMISSION_AMBULATORY SET ID_SCHEDULE=NULL WHERE ID_SCHEDULE IN (SELECT ID_SCHEDULE FROM SCHEDULE WHERE
        ID_SCHEDULE IN (SELECT \*+ opt_estimate(table t rows=1)*\ column_value FROM TABLE(i_scheduler_ids)t));*/
    
        ------ N� 771---------------------------------------------------
    
        UPDATE wtl_epis
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 772---------------------------------------------------
    
        UPDATE analysis_req
           SET id_sched_consult = NULL, flg_status = 'PA'
         WHERE id_sched_consult IN (SELECT id_schedule
                                      FROM schedule
                                     WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                            column_value
                                                             FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 773---------------------------------------------------
    
        UPDATE cli_rec_req
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 774---------------------------------------------------
    
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
    
        ------ N� 775---------------------------------------------------
    
        UPDATE crisis_epis
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 776---------------------------------------------------
    
        UPDATE discharge_detail_hist
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 777---------------------------------------------------
    
        UPDATE epis_info
           SET id_schedule = -1
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 778---------------------------------------------------
    
        UPDATE exam_req
           SET id_sched_consult = NULL, flg_status = 'PA'
         WHERE id_sched_consult IN (SELECT id_schedule
                                      FROM schedule
                                     WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                            column_value
                                                             FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 779---------------------------------------------------
    
        UPDATE exam_req
           SET id_schedule = NULL, flg_status = 'PA'
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 780---------------------------------------------------
    
        UPDATE grid_task_oth_exm
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 781---------------------------------------------------
    
        UPDATE hemo_req
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 782---------------------------------------------------
    
        UPDATE matr_scheduled
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 784---------------------------------------------------
    
        UPDATE p1_external_request
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 785---------------------------------------------------
    
        UPDATE p1_tracking
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 786---------------------------------------------------
    
        UPDATE pat_referral
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 787---------------------------------------------------
    
        UPDATE prof_follow_episode
           SET id_schedule = -1
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 788---------------------------------------------------
    
        UPDATE referral_ea
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 789---------------------------------------------------
    
        UPDATE ref_map
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 790---------------------------------------------------
    
        DELETE FROM room_scheduled
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 791---------------------------------------------------
    
        UPDATE schedule
           SET id_schedule_ref = NULL
         WHERE id_schedule_ref IN (SELECT id_schedule
                                     FROM schedule
                                    WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                           column_value
                                                            FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 792---------------------------------------------------
    
        DELETE FROM schedule_analysis
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 793---------------------------------------------------
    
        DELETE FROM schedule_bed
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 794---------------------------------------------------
    
        UPDATE schedule_exam
           SET id_schedule = -1
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 795---------------------------------------------------
    
        DELETE FROM schedule_hist
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 796---------------------------------------------------
    
        DELETE FROM schedule_intervention
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 797---------------------------------------------------
    
        DELETE FROM schedule_outp
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 798---------------------------------------------------
    
        DELETE FROM schedule_sr
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 799---------------------------------------------------
    
        DELETE FROM sch_allocation
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 800---------------------------------------------------
    
        DELETE FROM sch_api_map_ids
         WHERE id_schedule_pfh IN (SELECT id_schedule
                                     FROM schedule
                                    WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                           column_value
                                                            FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 801---------------------------------------------------
    
        UPDATE sch_api_map_ids_hist
           SET id_schedule_pfh = NULL
         WHERE id_schedule_pfh IN (SELECT id_schedule
                                     FROM schedule
                                    WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                           column_value
                                                            FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 802---------------------------------------------------
    
        DELETE FROM sch_clipboard
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 803---------------------------------------------------
    
        DELETE FROM sch_group
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 804---------------------------------------------------
    
        DELETE FROM sch_rehab_group
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 805---------------------------------------------------
    
        DELETE FROM sch_resource
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 806---------------------------------------------------
    
        DELETE FROM susp_task_schedules
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 807---------------------------------------------------
    
        UPDATE sys_alert_det
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 808---------------------------------------------------
    
        UPDATE vaccine_presc_plan
           SET id_schedule = NULL
         WHERE id_schedule IN (SELECT id_schedule
                                 FROM schedule
                                WHERE id_schedule IN (SELECT /*+ opt_estimate(table t rows=1)*/
                                                       column_value
                                                        FROM TABLE(i_scheduler_ids) t));
    
        ------ N� 809---------------------------------------------------
    
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
