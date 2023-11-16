/*-- Last Change Revision: $Rev: 2026678 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_edis IS

    /**
    * This function changes the id_patient of the i_old_episode
    * and associated visit to the i_new_patient
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_new_patient new patient id
    * @param i_old_episode id of episode for which the associated patient will change
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error
    */

    FUNCTION set_episode_new_patient
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_new_patient IN patient.id_patient%TYPE,
        i_old_episode IN episode.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        c_function_name CONSTANT VARCHAR2(32 CHAR) := 'SET_EPISODE_NEW_PATIENT';
    
        l_old_visit   visit.id_visit%TYPE;
        l_old_patient patient.id_patient%TYPE;
        l_php         pat_health_plan%ROWTYPE;
    
        -- denormalization variables
        l_rows_out    table_varchar := table_varchar();
        rows_vsr_out  table_varchar;
        rows_epis_out table_varchar;
        e_process_event EXCEPTION;
    
        l_ied_rowids_upd table_varchar;
        l_iei_rowids_upd table_varchar := table_varchar();
    
        l_rows_ar  table_varchar;
        l_rows_anr table_varchar;
        l_rows_h   table_varchar;
        l_rows_php table_varchar := table_varchar();
        l_rowids   table_varchar;
        l_rows     table_varchar := table_varchar();
    
        l_rows_dn   table_varchar;
        l_rows_ed   table_varchar;
        l_rows_edgr table_varchar;
        l_rows_er   table_varchar;
        l_rows_m    table_varchar;
        rows_ei_out table_varchar;
    
        l_rows_id  table_varchar;
        l_error_in t_error_in := t_error_in();
    
    BEGIN
        BEGIN
            -- <DENORM_EPISODE_JOSE_BRITO>
            g_error := 'GET ID_VISIT';
            SELECT e.id_visit, e.id_patient --v.id_visit, v.id_patient
              INTO l_old_visit, l_old_patient
              FROM episode e --, visit v
             WHERE e.id_episode = i_old_episode;
            --AND e.id_visit = v.id_visit;
        EXCEPTION
            WHEN no_data_found THEN
                --o_error := 'INVALID I_OLD_EPISODE ' || i_old_episode;
                l_error_in.set_all(i_lang,
                                   NULL,
                                   'INVALID I_OLD_EPISODE ' || i_old_episode,
                                   NULL,
                                   g_owner,
                                   g_package,
                                   c_function_name,
                                   'INVALID I_OLD_EPISODE ' || i_old_episode,
                                   'U');
                RETURN pk_alert_exceptions.process_error(l_error_in, o_error);
        END;
    
        g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.SET_LAB_TEST_MATCH';
        IF NOT pk_lab_tests_external_api_db.set_lab_test_match(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_patient      => i_new_patient,
                                                               i_episode      => NULL,
                                                               i_episode_temp => i_old_episode,
                                                               o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_EXAMS_EXTERNAL_API_DB.SET_EXAM_MATCH';
        IF NOT pk_exams_external_api_db.set_exam_match(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_patient      => i_new_patient,
                                                       i_episode      => NULL,
                                                       i_episode_temp => i_old_episode,
                                                       o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_PROCEDURES_EXTERNAL_API_DB.SET_PROCEDURE_MATCH';
        IF NOT pk_procedures_external_api_db.set_procedure_match(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_patient      => i_new_patient,
                                                                 i_episode      => NULL,
                                                                 i_episode_temp => i_old_episode,
                                                                 o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_BP_EXTERNAL_API_DB.SET_BP_MATCH';
        IF NOT pk_bp_external_api_db.set_bp_match(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_patient      => i_new_patient,
                                                  i_episode      => NULL,
                                                  i_episode_temp => i_old_episode,
                                                  o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL PK_HISTORY.SET_MATCH_COMPLETE_HISTORY';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_history.set_match_complete_history(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_id_episode_new => NULL,
                                                     i_id_episode_old => i_old_episode,
                                                     i_id_patient_new => i_new_patient,
                                                     i_id_patient_old => NULL,
                                                     o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'UPDATE EHR_ACCESS_LOG';
        UPDATE ehr_access_log
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        g_error := 'UPDATE CONSULT_REQ';
        ts_consult_req.upd(id_patient_in => i_new_patient,
                           where_in      => 'id_episode=' || i_old_episode,
                           rows_out      => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_consult_req';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'CONSULT_REQ',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'UPDATE DOC_EXTERNAL';
        -- UPDATE doc_external
        --    SET id_patient = i_new_patient
        --  WHERE id_episode = i_old_episode;
    
        l_rows  := table_varchar();
        g_error := 'Call ts_doc_external.upd / ID_EPISODE=' || i_old_episode;
        ts_doc_external.upd(id_patient_in => i_new_patient,
                            where_in      => 'id_episode=' || i_old_episode,
                            rows_out      => l_rows);
    
        g_error := 'Call t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'DOC_EXTERNAL',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'UPDATE EPIS_ANAMNESIS';
        l_rows  := table_varchar();
        ts_epis_anamnesis.upd(id_patient_in => i_new_patient,
                              where_in      => 'id_episode = ' || i_old_episode,
                              rows_out      => l_rows);
    
        g_error := 't_data_gov_mnt.process_update ts_epis_anamnesis';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ANAMNESIS',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'UPDATE EPIS_PROF_REC';
        UPDATE epis_prof_rec
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        g_error := 'UPDATE GUIDELINE_PROCESS';
        UPDATE guideline_process
           SET id_patient = i_new_patient
        --WHERE id_episode = i_old_episode;
         WHERE id_patient = l_old_patient;
    
        g_error := 'UPDATE PROTOCOL_PROCESS';
        UPDATE protocol_process
           SET id_patient = i_new_patient
        --WHERE id_episode = i_old_episode;
         WHERE id_patient = l_old_patient;
    
        g_error := 'UPDATE ORDER_SET_PROCESS';
        UPDATE order_set_process
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        g_error  := 'UPDATE COMM_ORDER_REQ';
        l_rowids := table_varchar();
        ts_comm_order_req.upd(id_patient_in => i_new_patient,
                              where_in      => 'id_episode = ' || i_old_episode,
                              rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE COMM_ORDER_REQ';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'COMM_ORDER_REQ',
                                      i_list_columns => table_varchar('ID_PATIENT'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error := 'UPDATE COMM_ORDER_REQ_HIST';
        UPDATE comm_order_req_hist
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        -- print list
        g_error  := 'UPDATE PRINT_LIST_JOB';
        l_rowids := table_varchar();
        ts_print_list_job.upd(id_patient_in => i_new_patient,
                              where_in      => 'id_episode = ' || i_old_episode,
                              rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PRINT_LIST_JOB';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PRINT_LIST_JOB',
                                      i_list_columns => table_varchar('ID_PATIENT'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error  := 'UPDATE PRINT_LIST_JOB_HIST';
        l_rowids := table_varchar();
        ts_print_list_job_hist.upd(id_patient_in => i_new_patient,
                                   where_in      => 'id_episode = ' || i_old_episode,
                                   rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PRINT_LIST_JOB_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PRINT_LIST_JOB_HIST',
                                      i_list_columns => table_varchar('ID_PATIENT'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        -- <DENORM_JOSE_BRITO>
        g_error := 'UPDATE ICNP_EPIS_DIAGNOSIS';
        ts_icnp_epis_diagnosis.upd(id_patient_in => i_new_patient,
                                   where_in      => 'id_episode = ' || i_old_episode,
                                   rows_out      => l_ied_rowids_upd);
    
        g_error := 'UPDATE ICNP_EPIS_INTERVENTION';
        ts_icnp_epis_intervention.upd(id_patient_in => i_new_patient,
                                      where_in      => 'id_episode = ' || i_old_episode,
                                      rows_out      => l_iei_rowids_upd);
    
        g_error := 'UPDATE ICNP_EPIS_INTERVENTION (id_episode_origin) ';
        ts_icnp_epis_intervention.upd(id_patient_in => i_new_patient,
                                      where_in      => 'id_episode_origin = ' || i_old_episode,
                                      rows_out      => l_iei_rowids_upd);
    
        g_error := 'UPDATE ICNP_EPIS_INTERVENTION (id_episode_destination) ';
        ts_icnp_epis_intervention.upd(id_patient_in => i_new_patient,
                                      where_in      => 'id_episode_destination = ' || i_old_episode,
                                      rows_out      => l_iei_rowids_upd);
    
        g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_UPDATE - ICNP_EPIS_INTERVENTION';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_EPIS_INTERVENTION',
                                      i_rowids     => l_iei_rowids_upd,
                                      o_error      => o_error);
    
        g_error := 'CALL TO T_DATA_GOV_MNT.PROCESS_UPDATE - ICNP_EPIS_DIAGNOSIS';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ICNP_EPIS_DIAGNOSIS',
                                      i_rowids     => l_ied_rowids_upd,
                                      o_error      => o_error);
        -- </DENORM_JOSE_BRITO>
    
        g_error := 'UPDATE ICNP_EPIS_INTERVENTION_HIST';
        UPDATE icnp_epis_intervention_hist
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        g_error := 'UPDATE ICNP_EPIS_INTERVENTION_HIST';
        UPDATE icnp_epis_intervention_hist
           SET id_patient = i_new_patient
         WHERE id_episode_origin = i_old_episode;
    
        g_error := 'UPDATE ICNP_EPIS_INTERVENTION_HIST';
        UPDATE icnp_epis_intervention_hist
           SET id_patient = i_new_patient
         WHERE id_episode_destination = i_old_episode;
    
        g_error := 'CALL pk_nnn_core.set_episode_new_patient';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => c_function_name);
        IF NOT pk_nnn_core.set_episode_new_patient(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_new_patient => i_new_patient,
                                                   i_old_episode => i_old_episode,
                                                   o_error       => o_error)
        THEN
            pk_utils.undo_changes();
            RETURN FALSE;
        END IF;
    
        g_error := 'UPDATE IDENTIFICATION_NOTES';
        UPDATE identification_notes
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        g_error := 'UPDATE ISSUE';
        UPDATE issue
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        g_error  := 'UPDATE ID_PATIENT IN LENS_PRESC';
        l_rowids := table_varchar();
        ts_lens_presc.upd(id_patient_in  => i_new_patient,
                          id_patient_nin => TRUE,
                          where_in       => 'id_episode = ' || i_old_episode,
                          rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE ID_PATIENT IN LENS_PRESC';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'LENS_PRESC',
                                      i_list_columns => table_varchar('id_patient'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error  := 'UPDATE ID_PATIENT IN LENS_PRESC_HIST';
        l_rowids := table_varchar();
        ts_lens_presc_hist.upd(id_patient_in  => i_new_patient,
                               id_patient_nin => TRUE,
                               where_in       => 'id_episode = ' || i_old_episode,
                               rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE ID_PATIENT IN LENS_PRESC_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'LENS_PRESC_HIST',
                                      i_list_columns => table_varchar('id_patient'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error := 'UPDATE MATCH_EPIS';
        UPDATE match_epis
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        g_error := 'UPDATE MATCH_EPIS';
        UPDATE match_epis
           SET id_patient = i_new_patient
         WHERE id_episode_temp = i_old_episode;
    
        g_error  := 'UPDATE PAT_ALLERGY';
        l_rowids := table_varchar();
        ts_pat_allergy.upd(id_patient_in => i_new_patient,
                           where_in      => 'id_episode = ' || i_old_episode,
                           rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PAT_ALLERGY';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_ALLERGY',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'UPDATE PAT_BLOOD_GROUP';
        UPDATE pat_blood_group
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        --Actualiza o estado dos registos de Grupo sanguíneo de forma a só o último ficar activo
        g_error := 'UPDATE PAT_BLOOD_GROUP FLG_STATUS';
        UPDATE pat_blood_group p
           SET flg_status = 'I'
         WHERE p.id_patient = i_new_patient
           AND p.flg_status = 'A'
           AND p.dt_pat_blood_group_tstz < (SELECT MAX(p1.dt_pat_blood_group_tstz)
                                              FROM pat_blood_group p1
                                             WHERE p1.id_patient = i_new_patient
                                               AND p1.flg_status = 'A');
    
        g_error := 'UPDATE PAT_FAM_SOC_HIST';
        UPDATE pat_fam_soc_hist
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        g_error  := 'UPDATE PAT_HABIT';
        l_rowids := table_varchar();
        ts_pat_habit.upd(id_patient_in => i_new_patient,
                         where_in      => 'id_episode = ' || i_old_episode,
                         rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PAT_HABIT';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_HABIT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error  := 'UPDATE PAT_HISTORY_DIAGNOSIS';
        l_rowids := table_varchar();
        ts_pat_history_diagnosis.upd(id_patient_in => i_new_patient,
                                     where_in      => 'id_episode = ' || i_old_episode,
                                     rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PAT_HISTORY_DIAGNOSIS';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_HISTORY_DIAGNOSIS',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'CALL PK_API_PFH_CLINDOC_IN.MATCH_EPISODE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_api_pfh_clindoc_in.match_episode(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_old_id_patient => NULL,
                                                   i_new_id_patient => i_new_patient,
                                                   i_old_id_episode => i_old_episode,
                                                   i_new_id_episode => NULL,
                                                   o_error          => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'UPDATE PAT_PAST_HIST_FREE_TEXT';
        UPDATE pat_past_hist_free_text ft
           SET ft.id_patient = i_new_patient
         WHERE ft.id_episode = i_old_episode;
    
        g_error  := 'UPDATE PAT_PROBLEM';
        l_rowids := table_varchar();
        ts_pat_problem.upd(id_patient_in => i_new_patient,
                           where_in      => 'id_episode = ' || i_old_episode,
                           rows_out      => l_rowids);
    
        g_error := 'PROCESS UPDATE PAT_PROBLEM';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_PROBLEM',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'UPDATE PAT_VACC_ADM';
        UPDATE pat_vacc_adm
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        g_error := 'UPDATE PERIODIC_OBSERVATION_REG';
        UPDATE periodic_observation_reg
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        /*g_error := 'UPDATE SCHEDULE_INP';
        UPDATE schedule_inp
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;*/
    
        g_error  := 'UPDATE SCHEDULE_SR';
        l_rowids := table_varchar();
        ts_schedule_sr.upd(id_patient_in  => i_new_patient,
                           id_patient_nin => FALSE,
                           where_in       => 'id_episode = ' || i_old_episode,
                           rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE SCHEDULE_SR';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SCHEDULE_SR',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'UPDATE VITAL_SIGN_READ';
        -- CHAMAR O UPDATE DO PACKAGE TS_VITAL_SIGN_READ
        ts_vital_sign_read.upd(id_patient_in => i_new_patient,
                               where_in      => 'id_episode = ' || i_old_episode,
                               rows_out      => rows_vsr_out);
    
        -- CHAMAR O PROCEDIMENTO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
        g_error := 'PROCESS UPDATE VITAL_SIGN_READ';
        t_data_gov_mnt.process_update(i_lang => i_lang,
                                      
                                      i_prof       => i_prof,
                                      i_table_name => 'VITAL_SIGN_READ',
                                      i_rowids     => rows_vsr_out,
                                      o_error      => o_error);
    
        g_error := 'UPDATE WL_WAITING_LINE';
        UPDATE wl_waiting_line
           SET id_patient = i_new_patient
         WHERE id_episode = i_old_episode;
    
        /* <DENORM Ariel - ALERT-1337> */
        g_error := 'UPDATE DISCHARGE_NOTES';
        ts_discharge_notes.upd(id_patient_in  => i_new_patient,
                               id_patient_nin => FALSE,
                               where_in       => 'id_episode = ' || i_old_episode,
                               rows_out       => l_rows_dn);
    
        g_error := 'UPDATE EPIS_DIAGNOSIS';
        ts_epis_diagnosis.upd(id_patient_in  => i_new_patient,
                              id_patient_nin => FALSE,
                              where_in       => 'id_episode = ' || i_old_episode,
                              rows_out       => l_rows_ed);
    
        g_error := 'UPDATE EPIS_DIAGRAM';
        ts_epis_diagram.upd(id_patient_in  => i_new_patient,
                            id_patient_nin => FALSE,
                            where_in       => 'id_episode = ' || i_old_episode,
                            rows_out       => l_rows_edgr);
    
        g_error := 'UPDATE EPIS_RECOMEND';
        ts_epis_recomend.upd(id_patient_in  => i_new_patient,
                             id_patient_nin => FALSE,
                             where_in       => 'id_episode = ' || i_old_episode,
                             rows_out       => l_rows_er);
    
        g_error := 'UPDATE MONITORIZATION';
        ts_monitorization.upd(id_patient_in  => i_new_patient,
                              id_patient_nin => FALSE,
                              where_in       => 'id_episode = ' || i_old_episode,
                              rows_out       => l_rows_m);
    
        /* </DENORM Ariel - ALERT-1337> */
    
        g_error := 'UPDATE VISIT';
        UPDATE visit
           SET id_patient = i_new_patient
         WHERE id_visit = l_old_visit;
    
        l_rowids := table_varchar();
        g_error  := 'UPDATE EPISODE';
        ts_episode.upd(id_patient_in  => i_new_patient,
                       id_patient_nin => FALSE,
                       where_in       => 'id_visit = ' || l_old_visit,
                       rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE EPISODE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rowids := table_varchar();
        g_error  := 'UPDATE EPIS_INFO';
        ts_epis_info.upd(id_patient_in  => i_new_patient,
                         id_patient_nin => FALSE,
                         where_in       => 'id_episode = ' || i_old_episode,
                         rows_out       => l_rowids);
    
        g_error := 'UPDATE EPIS_INFO';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        l_rows_id := table_varchar();
        g_error   := 'UPDATE ANNOUNCED_ARRIVAL';
        ts_announced_arrival.upd(id_patient_in  => i_new_patient,
                                 id_patient_nin => FALSE,
                                 where_in       => 'id_episode = ' || i_old_episode || ' OR id_patient = ' ||
                                                   l_old_patient,
                                 rows_out       => l_rows_id);
    
        g_error := 'PROCESS UPDATE ANNOUNCED_ARRIVAL';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANNOUNCED_ARRIVAL',
                                      i_rowids     => l_rows_id,
                                      o_error      => o_error);
    
        l_rows_id := table_varchar();
        g_error   := 'UPDATE ANNOUNCED_ARRIVAL_HIST';
        ts_announced_arrival_hist.upd(id_patient_in  => i_new_patient,
                                      id_patient_nin => FALSE,
                                      where_in       => 'id_episode = ' || i_old_episode || ' OR id_patient = ' ||
                                                        l_old_patient,
                                      rows_out       => l_rows_id);
    
        -- Alexandre Santos 02-04-2009 ALERT-8544
        -- LMAIA 22-05-2009 USE FRAMEWORK SYSTEM
        g_error  := 'UPDATE DISCHARGE_SCHEDULE';
        l_rowids := table_varchar();
        ts_discharge_schedule.upd(id_patient_in => i_new_patient,
                                  where_in      => 'id_episode = ' || i_old_episode,
                                  rows_out      => l_rowids);
        --
        g_error := 'PROCESS UPDATE DISCHARGE_SCHEDULE';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'DISCHARGE_SCHEDULE',
                                      i_list_columns => table_varchar('id_patient'),
                                      i_rowids       => l_rowids,
                                      o_error        => o_error);
    
        g_error := 'UPDATE SYS_ALERT_EVENT';
        UPDATE sys_alert_event sae
           SET sae.id_patient = i_new_patient
         WHERE sae.id_episode = i_old_episode;
    
        g_error  := 'UPDATE EPIS_INTAKE_TIME';
        l_rowids := table_varchar();
        ts_epis_intake_time.upd(id_patient_in  => i_new_patient,
                                id_patient_nin => FALSE,
                                where_in       => 'id_episode = ' || i_old_episode,
                                rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE EPIS_INTAKE_TIME';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_INTAKE_TIME',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        l_rowids := table_varchar();
        g_error  := 'CALL ts_cdr_call.upd II';
        ts_cdr_call.upd(id_patient_in  => i_new_patient,
                        id_patient_nin => FALSE,
                        where_in       => 'id_episode = ' || i_old_episode,
                        rows_out       => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_update CDR_CALL II';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'CDR_CALL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        --lógicas mais complexas
    
        /* <DENORM RicardoNunoAlmeida> */
        g_error := 'FIDDLE PAT_HEALTH_PLAN';
        --passar para o novo paciente planos de saúde que tenham sido atribuidos no antigo
        BEGIN
            SELECT php1.*
              INTO l_php
              FROM pat_health_plan php1
             WHERE id_patient = l_old_patient
               AND NOT EXISTS (SELECT 0
                      FROM pat_health_plan php2
                     WHERE php2.id_health_plan = php1.id_health_plan
                       AND nvl(php2.id_institution, -1) = nvl(php1.id_institution, -1)
                       AND php2.id_patient = i_new_patient)
               AND EXISTS (SELECT 0
                      FROM epis_health_plan ehp
                     WHERE ehp.id_episode = i_old_episode
                       AND ehp.id_pat_health_plan = php1.id_pat_health_plan);
        
            g_error                  := 'GET KEY id_pat_health_plan';
            l_php.id_pat_health_plan := ts_pat_health_plan.next_key();
        
            g_error := 'UPDATE PAT_HEALTH_PLAN';
            ts_pat_health_plan.ins(id_pat_health_plan_in => l_php.id_pat_health_plan,
                                   dt_health_plan_in     => l_php.dt_health_plan,
                                   id_patient_in         => i_new_patient,
                                   id_health_plan_in     => l_php.id_health_plan,
                                   num_health_plan_in    => l_php.num_health_plan,
                                   flg_status_in         => l_php.flg_status,
                                   barcode_in            => l_php.barcode,
                                   flg_default_in        => l_php.flg_default,
                                   id_institution_in     => l_php.id_institution,
                                   id_episode_in         => l_php.id_episode,
                                   rows_out              => l_rows_php);
        
            g_error := 'PROCESS UPDATE PAT_HEALTH_PLAN';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_HEALTH_PLAN',
                                          i_rowids     => l_rows_php,
                                          o_error      => o_error);
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
            
        END;
    
        g_error := 'FIDDLE EPIS_HEALTH_PLAN';
        --actualizar referencia do episódio, para apontar para o plano de saúde do novo paciente
        UPDATE epis_health_plan e
           SET id_pat_health_plan =
               (SELECT p.id_pat_health_plan
                  FROM pat_health_plan p, visit v, episode e2
                 WHERE p.id_patient = i_new_patient
                   AND p.id_health_plan = (SELECT p2.id_health_plan
                                             FROM pat_health_plan p2
                                            WHERE e.id_pat_health_plan = p2.id_pat_health_plan)
                   AND p.id_institution = v.id_institution
                   AND v.id_visit = e2.id_visit
                   AND e2.id_episode = e.id_episode)
         WHERE id_episode = i_old_episode
           AND EXISTS
         (SELECT 0
                  FROM pat_health_plan p, visit v, episode e2
                 WHERE p.id_patient = i_new_patient
                   AND p.id_health_plan = (SELECT p2.id_health_plan
                                             FROM pat_health_plan p2
                                            WHERE e.id_pat_health_plan = p2.id_pat_health_plan)
                   AND p.id_institution = v.id_institution
                   AND v.id_visit = e2.id_visit
                   AND e2.id_episode = e.id_episode);
    
        g_error := 'DELETE EPIS_HEALTH_PLAN';
        DELETE FROM epis_health_plan eh
         WHERE eh.id_episode = i_old_episode
           AND eh.id_pat_health_plan IN (SELECT php.id_pat_health_plan
                                           FROM pat_health_plan php
                                          WHERE php.id_patient = l_old_patient);
    
        --por fim, query sobre o dicionários de dados para garantir que é passado tudo.
        --fk para a episode
        g_error := 'LOOP EPISODE FK';
        FOR all_tbs IN (SELECT DISTINCT 'update ' || m1.table_name || ' set ' || mc2.column_name ||
                                        ' = :i_patient where ' || mc1.column_name || ' = :i_episode and ' ||
                                        mc2.column_name || ' = :i_old_patient' query
                          FROM all_constraints  m1,
                               all_cons_columns mc1,
                               all_cons_columns rc1,
                               all_constraints  m2,
                               all_cons_columns mc2,
                               all_cons_columns rc2
                         WHERE m1.table_name = m2.table_name
                           AND m1.owner = g_owner
                           AND rc1.constraint_name = m1.r_constraint_name
                           AND rc1.table_name = 'EPISODE'
                           AND mc1.table_name = m1.table_name
                           AND mc1.constraint_name = m1.constraint_name
                           AND rc2.constraint_name = m2.r_constraint_name
                           AND rc2.table_name = 'PATIENT'
                           AND mc2.table_name = m2.table_name
                           AND mc2.constraint_name = m2.constraint_name
                         ORDER BY 1)
        LOOP
            g_error := all_tbs.query;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => c_function_name);
            EXECUTE IMMEDIATE all_tbs.query
                USING i_new_patient, i_old_episode, l_old_patient;
        END LOOP;
    
        --fk para a visit
        g_error := 'LOOP VISIT FK';
        FOR all_tbs IN (SELECT DISTINCT 'update ' || m1.table_name || ' set ' || mc2.column_name ||
                                        ' = :i_patient where ' || mc1.column_name || ' = :i_visit and ' ||
                                        mc2.column_name || ' = :i_old_patient' query
                          FROM all_constraints  m1,
                               all_cons_columns mc1,
                               all_cons_columns rc1,
                               all_constraints  m2,
                               all_cons_columns mc2,
                               all_cons_columns rc2
                         WHERE m1.table_name = m2.table_name
                           AND m1.owner = g_owner
                           AND rc1.constraint_name = m1.r_constraint_name
                           AND rc1.table_name = 'VISIT'
                           AND mc1.table_name = m1.table_name
                           AND mc1.constraint_name = m1.constraint_name
                           AND rc2.constraint_name = m2.r_constraint_name
                           AND rc2.table_name = 'PATIENT'
                           AND mc2.table_name = m2.table_name
                           AND mc2.constraint_name = m2.constraint_name
                         ORDER BY 1)
        LOOP
            g_error := all_tbs.query;
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => c_function_name);
            EXECUTE IMMEDIATE all_tbs.query
                USING i_new_patient, l_old_visit, l_old_patient;
        END LOOP;
    
        /* <DENORM Ariel - ALERT-1337 > */
    
        --DISCHARGE_NOTES
        g_error := 'PROCESS UPDATE DISCHARGE_NOTES';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'DISCHARGE_NOTES',
                                      i_rowids       => l_rows_dn,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        --EPIS_DIAGNOSIS
        g_error := 'PROCESS UPDATE EPIS_DIAGNOSIS';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_DIAGNOSIS',
                                      i_rowids       => l_rows_ed,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        --EPIS_DIAGRAM
        g_error := 'PROCESS UPDATE EPIS_DIAGRAM';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_DIAGRAM',
                                      i_rowids       => l_rows_edgr,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        --EPIS_RECOMEND
        g_error := 'PROCESS UPDATE EPIS_RECOMEND';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_RECOMEND',
                                      i_rowids       => l_rows_er,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        --MONITORIZATION
        g_error := 'PROCESS UPDATE MONITORIZATION';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'MONITORIZATION',
                                      i_rowids       => l_rows_m,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        /* </DENORM Ariel> */
    
        --
        -- Match of EPISODES/PATIENTS in functionality WAITING LIST (ADMISSION and SURGERY REQUEST)
        -- SURGERY REQUEST
        --
        g_error  := 'UPDATE SR_DANGER_CONT';
        l_rowids := table_varchar();
        ts_sr_danger_cont.upd(id_patient_in  => i_new_patient,
                              id_patient_nin => FALSE,
                              where_in       => 'id_episode = ' || i_old_episode,
                              rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE SR_DANGER_CONT';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'SR_DANGER_CONT', l_rowids, o_error, table_varchar('ID_PATIENT'));
        -- END WAITING LIST (ADMISSION and SURGERY REQUEST)
    
        -- DIET
        g_error  := 'UPDATE EPIS_DIET_REQ';
        l_rowids := table_varchar();
        ts_epis_diet_req.upd(id_patient_in  => i_new_patient,
                             id_patient_nin => FALSE,
                             where_in       => 'id_episode = ' || i_old_episode,
                             rows_out       => l_rowids);
        g_error := 'PROCESS UPDATE EPIS_DIET_REQ';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_DIET_REQ', l_rowids, o_error, table_varchar('ID_PATIENT'));
    
        -- END DIET
        -- THERAPEUTIC DECISION
        g_error  := 'THERAPEUTIC_DECISION';
        l_rowids := table_varchar();
        ts_therapeutic_decision.upd(id_patient_in  => i_new_patient,
                                    id_patient_nin => FALSE,
                                    where_in       => 'id_episode = ' || i_old_episode,
                                    rows_out       => l_rowids);
    
        -- END THERAPEUTIC DECISION
    
        -- BED MANAGEMENT
        --
        g_error  := 'UPDATE BED_MANAGEMENT';
        l_rowids := table_varchar();
        ts_bmng_allocation_bed.upd(id_patient_in  => i_new_patient,
                                   id_patient_nin => FALSE,
                                   where_in       => 'id_episode = ' || i_old_episode,
                                   rows_out       => l_rowids);
    
        g_error := 'PROCESS UPDATE BMNG_ALLOCATION_BED';
        t_data_gov_mnt.process_update(i_lang,
                                      i_prof,
                                      'BMNG_ALLOCATION_BED',
                                      l_rowids,
                                      o_error,
                                      table_varchar('ID_PATIENT'));
        -- END BED MANAGEMENT
    
        -- INP_HIDRICS
        l_rowids := table_varchar();
        g_error  := 'UPDATE EPIS_HIDRICS';
        ts_epis_hidrics.upd(id_patient_in  => i_new_patient,
                            id_patient_nin => FALSE,
                            where_in       => 'id_episode = ' || i_old_episode,
                            rows_out       => l_rowids);
        g_error := 'PROCESS  UPDATE EPIS_HIDRICS';
        t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_HIDRICS', l_rowids, o_error, table_varchar('ID_PATIENT'));
        l_rowids := table_varchar();
    
        g_error := 'UPDATE EPIS_HIDRICS_HIST';
        ts_epis_hidrics_hist.upd(id_patient_in  => i_new_patient,
                                 id_patient_nin => FALSE,
                                 where_in       => 'id_episode = ' || i_old_episode,
                                 rows_out       => l_rowids);
    
        -- END INP_HIDRICS
    
        g_error  := 'UPDATE OPINION';
        l_rowids := table_varchar();
        ts_opinion.upd(id_patient_in  => i_new_patient,
                       id_patient_nin => FALSE,
                       where_in       => ' ID_EPISODE = ' || i_old_episode,
                       rows_out       => l_rowids);
        g_error := 'PROCESS UPDATE OPINION';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'OPINION',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error  := 'UPDATE EPIS_ENCOUNTER';
        l_rowids := table_varchar();
        ts_epis_encounter.upd(id_patient_in  => i_new_patient,
                              id_patient_nin => FALSE,
                              where_in       => ' ID_EPISODE = ' || i_old_episode,
                              rows_out       => l_rowids);
        g_error := 'PROCESS UPDATE EPIS_ENCOUNTER';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_ENCOUNTER',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        g_error := 'CALL pk_organ_donor.change_donor_patient_id';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => c_function_name);
        IF NOT pk_organ_donor.change_donor_patient_id(i_lang        => i_lang,
                                                      i_new_patient => i_new_patient,
                                                      i_episode     => i_old_episode,
                                                      o_error       => o_error)
        THEN
            pk_utils.undo_changes();
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => c_function_name,
                                              o_error    => o_error);
            pk_utils.undo_changes();
            RETURN FALSE;
        
    END set_episode_new_patient;

    /**
    * This function marges all the information of the two patients into i_patient, including episodes
    *
    * @param i_lang language id
    * @param i_prof user's object
    * @param i_patient new patient id
    * @param i_patient_temp tmeporary patient which data will be merged out, and then deleted
    * @param o_error error message, if error occurs
    *
    * @return true on success, false on error      
    */
    FUNCTION set_match_all_pat
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_patient_temp IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_match.set_match_all_pat(i_lang, i_prof, i_patient, i_patient_temp, o_error)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'SET_MATCH_ALL_PAT',
                                                     o_error);
    END set_match_all_pat;

    /********************************************************************************************
    * Used to cancel episodes through external administrative systems.
    * Allows to cancel EDIS/UBU, Inpatient, Outpatient and Private Practice episodes.
    *
    * @param i_lang                           language id
    * @param i_id_episode                     episode id
    * @param i_prof                           professional id, software and institution
    * @param i_cancel_reason                  motive of cancellation
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 Unknown / José Brito (edited)
    * @version                                1.0  
    * @since                                  2008-06-05
    ********************************************************************************************/
    FUNCTION intf_cancel_episode
    (
        i_lang           IN language.id_language%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_cancel_reason  IN episode.desc_cancel_reason%TYPE,
        i_transaction_id IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type   episode.id_epis_type%TYPE;
        l_amb_episode BOOLEAN;
    
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        -- retrieve episode type
        g_error := 'CALL pk_episode.get_epis_type';
        IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                        i_id_epis   => i_id_episode,
                                        o_epis_type => l_epis_type,
                                        o_error     => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- check if the episode is of Ambulatory products
        g_error       := 'CALL pk_visit.check_epis_type_amb';
        l_amb_episode := pk_visit.check_epis_type_amb(i_epis_type => l_epis_type);
    
        IF l_amb_episode
        THEN
            g_error := 'CALL pk_api_visit.intf_cancel_episode';
            RETURN pk_api_visit.intf_cancel_episode(i_lang          => i_lang,
                                                    i_id_episode    => i_id_episode,
                                                    i_prof          => i_prof,
                                                    i_cancel_reason => i_cancel_reason,
                                                    --  i_transaction_id => l_transaction_id,
                                                    o_error => o_error);
        ELSE
            g_error := 'CALL pk_visit.call_cancel_episode';
            IF NOT pk_visit.call_cancel_episode(i_lang           => i_lang,
                                                i_id_episode     => i_id_episode,
                                                i_prof           => i_prof,
                                                i_cancel_reason  => i_cancel_reason,
                                                i_cancel_type    => 'I',
                                                i_transaction_id => l_transaction_id,
                                                o_error          => o_error)
            
            THEN
            
                RETURN FALSE;
            END IF;
        END IF;
    
        -- Scheduler 3.0. DO NOT REMOVE
        IF i_transaction_id IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'INTF_CANCEL_EPISODE',
                                                     o_error);
            -- will be needed when new scheduler is active  DO NOT REMOVE                                 
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
        
    END intf_cancel_episode;

    /*******************************************************************************************************************************************
    * INTF_CREATE_TRANSF_INST         This function is responsible for creating an institution transfer request.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with institution transfer
    * @param I_ID_PATIENT             PATIENT identifier that should be associated with institution transfer
    * @param I_ID_INSTITUTION_ORIG    Institution ID from which the patient leaves
    * @param I_ID_INSTITUTION_DEST    Institution ID in which the patient arrives
    * @param I_ID_TRANSP_ENTITY       Transport ID to be used during the transfer
    * @param I_NOTES                  Request notes
    * @param I_ID_DEP_CLIN_SERV       ID_DEP_CLIN_SERV identifier (associate Department and Clinical service ID's in destiny institution 
    * @param I_ID_TRANSFER_OPTION     Transfer reason selected during the request
    * @param O_DT_CREATION            Creation date of current institution transfer request
    * @param O_ERROR                  If an error occurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic error "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.6
    * @since                          2009/09/21
    * @dependents                     INTERFACE TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_create_transf_inst
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_institution_orig IN transfer_institution.id_institution_origin%TYPE,
        i_id_institution_dest IN transfer_institution.id_institution_dest%TYPE,
        i_id_transp_entity    IN transfer_institution.id_transp_entity%TYPE,
        i_notes               IN transfer_institution.notes%TYPE,
        i_id_dep_clin_serv    IN transfer_institution.id_dep_clin_serv%TYPE,
        i_id_transfer_option  IN transfer_institution.id_transfer_option%TYPE,
        o_dt_creation         OUT transfer_institution.dt_creation_tstz%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- Call to create institution transfer
        g_error := 'CALL PK_TRANSFER_INSTITUTION.CREATE_TRANSFER_INST FOR ID_EPISODE ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_transfer_institution.create_transfer_inst_int(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_id_episode          => i_id_episode,
                                                                i_id_patient          => i_id_patient,
                                                                i_id_institution_orig => i_id_institution_orig,
                                                                i_id_institution_dest => i_id_institution_dest,
                                                                i_id_transp_entity    => i_id_transp_entity,
                                                                i_notes               => i_notes,
                                                                i_id_dep_clin_serv    => i_id_dep_clin_serv,
                                                                i_id_transfer_option  => i_id_transfer_option,
                                                                o_dt_creation         => o_dt_creation,
                                                                o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'INTF_CREATE_TRANSF_INST',
                                                     o_error);
    END intf_create_transf_inst;

    /*******************************************************************************************************************************************
    * INTF_UPD_TRANSF_INST            Updates an institution transfer request
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             EPISODE identifier that should be associated with institution transfer
    * @param I_DT_CREATION            Record creation date
    * @param I_DT_UPDATE              Begin or end date of the institution transfer
    * @param I_FLG_STATUS             New status of the institution transfer ('C' - Cancel transfer; 'T' - Approve transfer in destiny institution; 'F' - Finalized transfer in destiny institution; 'R' - Request transfer)
    * @param O_ERROR                  If an error occurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic error "OTHERS"
    *
    * @author                         Luís Maia
    * @version                        2.5.0.6
    * @since                          2009/09/21
    * @dependents                     INTERFACE TEAM
    *******************************************************************************************************************************************/
    FUNCTION intf_upd_transf_inst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_dt_creation IN transfer_institution.dt_creation_tstz%TYPE,
        i_dt_update   IN transfer_institution.dt_begin_tstz%TYPE,
        i_flg_status  IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- Approve, Cancel, Finalise or Request institution transfer
        g_error := 'CALL PK_TRANSFER_INSTITUTION.UPDATE_TRANSFER_INST FOR ID_EPISODE ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_transfer_institution.update_transfer_inst(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_episode     => i_id_episode,
                                                            i_dt_creation => pk_date_utils.date_send_tsz(i_lang,
                                                                                                         i_dt_creation,
                                                                                                         i_prof),
                                                            i_dt_update   => pk_date_utils.date_send_tsz(i_lang,
                                                                                                         i_dt_update,
                                                                                                         i_prof),
                                                            i_flg_status  => i_flg_status,
                                                            --i_flg_status = g_inst_transfer_approve - Transfer request approve 
                                                            --i_flg_status = g_inst_transfer_finnished - Transfer finalised by administrative
                                                            --i_flg_status = g_inst_transfer_cancel - Transfer cancel
                                                            --i_flg_status = g_transfer_inst_req - Transfer request
                                                            o_error => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'INTF_UPD_TRANSF_INST',
                                                     o_error);
    END intf_upd_transf_inst;
    --

    /**
    * API to add a free text History of Present Illness to a episode
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_notes        Notes   
    *
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO / Filipe Machado
    * @version 2.5.0.8
    * @since   05-Jul-10
    */
    FUNCTION intf_add_hpi_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_notes              IN epis_documentation.notes%TYPE,
        o_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN AS
        l_prof_cat_type category.flg_type%TYPE;
    
    BEGIN
        --retrieves prof category
        l_prof_cat_type := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_prof_cat_type         => l_prof_cat_type,
                                                          i_epis                  => i_episode,
                                                          i_doc_area              => pk_summary_page.g_doc_area_hist_ill,
                                                          i_doc_template          => NULL,
                                                          i_epis_documentation    => NULL,
                                                          i_flg_type              => pk_touch_option.g_flg_edition_type_new,
                                                          i_id_documentation      => table_number(),
                                                          i_id_doc_element        => table_number(),
                                                          i_id_doc_element_crit   => table_number(),
                                                          i_value                 => table_varchar(),
                                                          i_notes                 => i_notes,
                                                          i_id_epis_complaint     => NULL,
                                                          i_id_doc_element_qualif => table_table_number(),
                                                          i_epis_context          => NULL,
                                                          o_epis_documentation    => o_epis_documentation,
                                                          o_error                 => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'INTF_HPI_NOTES',
                                                     o_error);
        
    END intf_add_hpi_notes;
    --
    /**********************************************************************************************
    * API to set the professional responsible for the a array of episodes
    * 
    *  Record the requests for transfer of responsibility
    *   The transfer of responsibility may be carried out over several episodes.
    *   Is it possible to perform transf. responsibility for one or more professionals.
    *   The same may happen with the specialties, one or more specialties.
    * 
    * @param i_lang                   id language
    * @param i_prof                   professional, software and institution ids
    * @param i_prof_to                Array of professionals who were asked to transfer responsibility   
    * @param i_tot_epis               Array with the total number of episodes for which was requested transfer of responsibility
    * @param i_epis_pat               Array IDs episodes / patients for whom it was requested transfer of responsibility
    * @param i_cs_or_dept             Array of clinical services or departments where the request was made to transfer responsibility        
    * @param i_notes                  Array of Notes
    * @param i_flg_type               Professional Category: S - Social Worker; D - Doctor, N - Nurse
    * @param i_flg_resp               It can take two values: G -  Assume responsibility of the patient in the entry screens
                                                              H -  Hand-Off                   
    * @param i_flg_profile            Type of profile: (S) specialist (R) resident (I) intern (N) nurse
    * @param i_sysdate                Request date, if needed.
    * @param i_id_speciality          Destination speciality ID. Must be the same for all professionals in 'i_prof_to'.
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Alexandre Santos
    * @version                        2.6.0.4
    * @since                          2010-08-17
    **********************************************************************************************/
    FUNCTION intf_create_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_to       IN table_varchar,
        i_tot_epis      IN table_number,
        i_epis_pat      IN table_number,
        i_cs_or_dept    IN table_number,
        i_notes         IN table_varchar,
        i_flg_type      IN epis_prof_resp.flg_type%TYPE,
        i_flg_resp      IN VARCHAR2,
        i_flg_profile   IN profile_template.flg_profile%TYPE DEFAULT NULL,
        i_sysdate       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_speciality IN speciality.id_speciality%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_show  VARCHAR2(4000);
        l_msg_title VARCHAR2(4000);
        l_msg_body  VARCHAR2(4000);
    BEGIN
        IF NOT pk_hand_off.create_epis_prof_resp(i_lang          => i_lang,
                                                 i_prof          => i_prof,
                                                 i_prof_to       => i_prof_to,
                                                 i_tot_epis      => i_tot_epis,
                                                 i_epis_pat      => i_epis_pat,
                                                 i_cs_or_dept    => i_cs_or_dept,
                                                 i_notes         => i_notes,
                                                 i_flg_type      => i_flg_type,
                                                 i_flg_resp      => i_flg_resp,
                                                 i_flg_profile   => i_flg_profile,
                                                 i_sysdate       => i_sysdate,
                                                 i_id_speciality => i_id_speciality,
                                                 o_flg_show      => l_flg_show,
                                                 o_msg_title     => l_msg_title,
                                                 o_msg_body      => l_msg_body,
                                                 o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'INTF_CREATE_PROF_RESP',
                                                     o_error);
    END intf_create_prof_resp;
    --    
    --    
    /**
    * API to add a free text History of Present Illness to a episode with flg_status and creation date
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_notes        Notes   
    * @param   i_flg_status    
    * @param   i_dt_creation   
    *
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  Pedro Maia
    * @version 2.6.0.3
    * @since   24-Jan-11
    */
    FUNCTION intf_add_hpi_notes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_notes              IN epis_documentation.notes%TYPE,
        i_flg_status         IN epis_documentation.flg_status%TYPE,
        i_dt_creation        IN epis_documentation.dt_creation_tstz%TYPE,
        o_epis_documentation OUT epis_documentation.id_epis_documentation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN AS
        l_prof_cat_type category.flg_type%TYPE;
    
    BEGIN
        --retrieves prof category
        l_prof_cat_type := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        IF NOT pk_touch_option.set_epis_document_internal(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_prof_cat_type         => l_prof_cat_type,
                                                          i_epis                  => i_episode,
                                                          i_doc_area              => pk_summary_page.g_doc_area_hist_ill,
                                                          i_doc_template          => NULL,
                                                          i_epis_documentation    => NULL,
                                                          i_flg_type              => pk_touch_option.g_flg_edition_type_new,
                                                          i_id_documentation      => table_number(),
                                                          i_id_doc_element        => table_number(),
                                                          i_id_doc_element_crit   => table_number(),
                                                          i_value                 => table_varchar(),
                                                          i_notes                 => i_notes,
                                                          i_id_epis_complaint     => NULL,
                                                          i_id_doc_element_qualif => table_table_number(),
                                                          i_epis_context          => NULL,
                                                          i_episode_context       => NULL,
                                                          i_flg_table_origin      => 'D',
                                                          i_flg_status            => i_flg_status,
                                                          i_dt_creation           => i_dt_creation,
                                                          o_epis_documentation    => o_epis_documentation,
                                                          o_error                 => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_owner,
                                                     g_package,
                                                     'INTF_HPI_NOTES',
                                                     o_error);
        
    END intf_add_hpi_notes;

    /********************************************************************************************
    * Cancel a Transfer Institution
    *
    * @param i_lang                    Language associated to the professional executing the request
    * @param i_prof                    Professional, Software and Institution ids
    * @param i_id_episode              Episode ID
    * @param i_dt_creation               Begin Date of transfer 
    * @param i_notes_cancel            Notes of cancelation
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          António Neto
    * @version                         2.6.1.0.1
    * @since                           21-Apr-2011
    *
    **********************************************************************************************/
    FUNCTION intf_cancel_transf_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_dt_creation      IN VARCHAR2,
        i_notes_cancel     IN transfer_institution.notes_cancel%TYPE,
        i_id_cancel_reason IN transfer_institution.id_cancel_reason%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_TRANSFER_INSTITUTION.CANCEL_TRANSFER_INST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_transfer_institution.cancel_transfer_inst_int(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_episode          => i_id_episode,
                                                                i_dt_creation      => i_dt_creation,
                                                                i_notes_cancel     => i_notes_cancel,
                                                                i_id_cancel_reason => i_id_cancel_reason,
                                                                o_error            => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'INTF_CANCEL_TRANSF_INST',
                                              o_error);
            RETURN FALSE;
    END intf_cancel_transf_inst;

    /********************************************************************************************
    * Sets the match log information
    *
    * @param i_lang                    Language associated to the professional executing the request
    * @param i_prof                    Professional, Software and Institution ids
    * @param i_id_prof_match           Professional that executed the match process
    * @param i_dt_match                Date of the match execution 
    * @param i_episode_temp            Temporary episode that was deleted during the episode merge
    * @param o_error                   Error message
    * 
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          José Silva
    * @version                         2.6.0.5
    * @since                           17-05-2011
    **********************************************************************************************/
    FUNCTION intf_upd_match_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_prof_match IN professional.id_professional%TYPE,
        i_dt_match      IN match_epis.dt_match_tstz%TYPE,
        i_episode_temp  IN episode.id_episode%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'UPDATE MATCH_EPIS';
        pk_alertlog.log_debug(g_error);
        UPDATE match_epis me
           SET me.dt_match_tstz   = nvl(i_dt_match, me.dt_match_tstz),
               me.id_professional = nvl(i_id_prof_match, me.id_professional)
         WHERE me.id_episode_temp = i_episode_temp;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'INTF_UPD_MATCH_EPIS',
                                              o_error);
            RETURN FALSE;
    END intf_upd_match_epis;

    /********************************************************************************************
    * Function that adds the 'payment made' care stage to the episode
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Alexandre Santos
    * @version               2.6.2
    * @since                 2011/10/24
    ********************************************************************************************/
    FUNCTION intf_set_care_state_pyt_made
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'INTF_SET_CARE_STATE_PYT_MADE';
    BEGIN
        g_error := 'CALL PK_PATIENT_TRACKING.SET_CS_PAYMENT_MADE';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_patient_tracking.set_cs_payment_made(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_episode => i_episode,
                                                       o_error   => o_error);
    END intf_set_care_state_pyt_made;

    /********************************************************************************************
      * Function that adds the 'Wainting for payment' care stage to the episode
    * This function is used by Interfaces Team and is called by a external system 
      *
      * @param i_lang          Language ID
      * @param i_prof          Professional
      * @param i_episode       Definitive episode ID
      * @param o_error         Error ocurred
      *
      * @return                False if an error ocurred and True if not
      *
      * @author                Gisela Couto
      * @version               2.6.2
      * @since                 2014/08/25
      ********************************************************************************************/
    FUNCTION intf_set_care_state_wait_f_pyt
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'INTF_SET_CARE_STATE_WAIT_PYT';
    BEGIN
        g_error := 'CALL PK_PATIENT_TRACKING.SET_CS_WAIT_FR_PAYMENT';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        RETURN pk_patient_tracking.set_cs_wait_fr_payment(i_lang    => i_lang,
                                                          i_prof    => i_prof,
                                                          i_episode => i_episode,
                                                          o_error   => o_error);
    END intf_set_care_state_wait_f_pyt;

    /**
    * Encapsulates the logic of saving (create or update) a announced arrival patient
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_announced_arrival     Announced arrival id 
    * @param   o_error                 Error information
    *
    * @example i_params                Example of the possible XML passed in this variable
    * <ANNOUNCED_ARRIVAL ID_ANNOUNCED_ARRIVAL="" ID_EPISODE="">
    *   <!-- ID_EPISODE -> Only put this arg to substitute the old call to CREATE_ANN_ARRIVAL_BY_EPI - Creation in pre-hospital screen inside patient area -->
    *   <!-- ID_ANNOUNCED_ARRIVAL -> Only used when editing a existing recorded (Instead of calls to SET_ANN_ARRIVAL and SET_ANN_ARRIVAL_PRE_HOSP) -->
    *   <PATIENT NAME="" GENDER="" DT_BIRTH="" AGE="" ADDRESS="" CITY="" ZIP_CODE="" />
    *   <INCIDENT DT_ACCIDENT="" TYPE_INJURY="" CONDITION="" ZIP_CODE="" LATITUDE="" LONGITUDE="" />
    *   <REFERRAL_ARRIV REFERRED_BY="" SPECIALITY="" CLINICAL_SERVICE="" ED_PHYSICIAN="" DT_EXPECTED_ARRIVAL="" />
    *   <ACT_EMERG_SERV DT_REPORT_MKA="" CPA_CODE="" TRANSPORT_NUMBER="" DT_RIDE_OUT="" DT_ARRIVAL="" />
    *   <TRIAGE FLG_MECH_INJ="" MECH_INJURY_FT="" >
    *     <VITAL_SIGNS>
    *       <VITAL_SIGN ID="" VAL="" UNIT_MEAS="" />
    *     </VITAL_SIGNS>
    *   </TRIAGE>
    *   <TRANSFER_HOSP DT_DRV_AWAY="" />
    *   <RTC FLG_PROT_DEVICE="" FLG_RTA_PAT_TYPE="" RTA_PAT_TYPE_FT="" FLG_IS_DRIV_OWN="" FLG_POLICE_INVOLVED="" POLICE_NUM="" POLICE_STATION="" POLICE_ACCIDENT_NUM="" />
    * </ANNOUNCED_ARRIVAL>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.1.2
    * @since   01-08-2011
    */
    FUNCTION set_announced_arrival
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_params            IN CLOB,
        o_announced_arrival OUT announced_arrival.id_announced_arrival%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ANNOUNCED_ARRIVAL';
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL PK_ANNOUNCED_ARRIVAL.SET_ANNOUNCED_ARRIVAL';
        pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_announced_arrival.set_announced_arrival(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_patient           => NULL,
                                                          i_params            => i_params,
                                                          o_announced_arrival => o_announced_arrival,
                                                          o_error             => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_announced_arrival;

    /********************************************************************************************
    * Creates a new complaint (used when admitting a new episode) 
    *
    * @param i_lang                 language ID
    * @param i_episode              episode id
    * @param i_prof                 professional object
    * @param i_desc                 complaint description 
    * @param o_id_epis_anamnesis    new complaint ID           
    * @param o_error                Error message
    * 
    * @return                       true or false on success or error
    * 
    * @author                       José Silva
    * @version                      2.6.1
    * @since                        09-May-2012 
    ********************************************************************************************/
    FUNCTION set_epis_anamnesis
    (
        i_lang                   IN language.id_language%TYPE,
        i_episode                IN epis_anamnesis.id_episode%TYPE,
        i_prof                   IN profissional,
        i_desc                   IN epis_anamnesis.desc_epis_anamnesis%TYPE,
        i_dt_epis_anamnesis_tstz IN epis_anamnesis.dt_epis_anamnesis_tstz%TYPE,
        o_id_epis_anamnesis      OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_clinical_info.set_epis_anamnesis_int(i_lang                   => i_lang,
                                                       i_episode                => i_episode,
                                                       i_prof                   => i_prof,
                                                       i_desc                   => i_desc,
                                                       i_flg_type               => pk_clinical_info.g_flg_type_c,
                                                       i_flg_type_mode          => pk_clinical_info.g_flg_edition_type_new,
                                                       i_id_epis_anamnesis      => NULL,
                                                       i_id_diag                => NULL,
                                                       i_flg_class              => NULL,
                                                       i_prof_cat_type          => pk_prof_utils.get_category(i_lang,
                                                                                                              i_prof),
                                                       i_flg_rep_by             => NULL,
                                                       i_dt_epis_anamnesis_tstz => i_dt_epis_anamnesis_tstz,
                                                       o_id_epis_anamnesis      => o_id_epis_anamnesis,
                                                       o_error                  => o_error);
    END set_epis_anamnesis;

    /********************************************************************************************
    * Get triage board vital signs
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional info
    * @param i_id_episode          Episode id
    * @param i_id_triage_board     Triage board id
    * @param i_id_triage_type      Triage type id
    * @param i_pat_gender          Patient gender
    *    
    * @return                      Table with vital sign id's
    *
    * @author                      Alexandre Santos
    * @version                     2.6.3
    * @since                       04-03-2012
    **********************************************************************************************/
    FUNCTION tf_triage_board_vital_signs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_triage_board IN triage_board.id_triage_board%TYPE,
        i_id_triage_type  IN triage_type.id_triage_type%TYPE DEFAULT NULL,
        i_pat_gender      IN patient.gender%TYPE DEFAULT NULL
    ) RETURN table_number IS
    BEGIN
        RETURN pk_edis_triage.tf_triage_vital_signs(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_episode     => i_id_episode,
                                                    i_tbl_id_context => table_number(i_id_triage_board),
                                                    i_flg_context    => pk_edis_triage.g_flg_context_id_triage_board,
                                                    i_id_triage_type => i_id_triage_type,
                                                    i_pat_gender     => i_pat_gender);
    END tf_triage_board_vital_signs;

    /********************************************************************************************
    * Get triage discriminator vital signs
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional info
    * @param i_id_episode          Episode id
    * @param i_id_triage_discrim   Triage Discriminator id
    * @param i_id_triage_type      Triage type id
    * @param i_pat_gender          Patient gender
    *    
    * @return                      Table with vital sign id's
    *
    * @author                      Alexandre Santos
    * @version                     2.6.3
    * @since                       04-03-2012
    **********************************************************************************************/
    FUNCTION tf_triage_discrim_vital_signs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_triage_discrim IN triage_discriminator.id_triage_discriminator%TYPE,
        i_id_triage_type    IN triage_type.id_triage_type%TYPE DEFAULT NULL,
        i_pat_gender        IN patient.gender%TYPE DEFAULT NULL
    ) RETURN table_number IS
    BEGIN
        RETURN pk_edis_triage.tf_triage_vital_signs(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_episode     => i_id_episode,
                                                    i_tbl_id_context => table_number(i_id_triage_discrim),
                                                    i_flg_context    => pk_edis_triage.g_flg_context_id_triage_disc,
                                                    i_id_triage_type => i_id_triage_type,
                                                    i_pat_gender     => i_pat_gender);
    END tf_triage_discrim_vital_signs;

    /********************************************************************************************
    * Returns professional responsible for patient
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_scope                    Scope - 'P'
    * @param   i_id_scope                 id - patient_id
    *
    *                        
    * @return  Episode responsible ID
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0
    * @since                          05-May-2014
    **********************************************************************************************/
    FUNCTION get_prof_resp_cda
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_scope    IN VARCHAR2,
        i_id_scope IN patient.id_patient%TYPE
        
    ) RETURN t_resp_professional_cda IS
    BEGIN
        RETURN pk_hand_off.get_prof_resp_cda(i_lang     => i_lang,
                                             i_prof     => i_prof,
                                             i_scope    => i_scope,
                                             i_id_scope => i_id_scope);
    
    END get_prof_resp_cda;

    /********************************************************************************************
    * Function to add/edit/remove a set of allergies. 
    * @param i_lang                Language
    * @param i_prof                Professional
    * @param i_scope               Scope - 'P' Patient
    * @param i_id_scope            Scope id
    * @param i_id_episode          Episode id
    * @param i_entries_to_add      Allergies to add
    * @param i_entries_to_edit     Allergies to edit
    * @param i_entries_to_remove   Allergies to remove
    * @param i_cdr_call            Flash warning id
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-May-2014
    **********************************************************************************************/
    FUNCTION set_allergies_cda
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_entries_to_add    IN t_tab_allergies_cdas_new,
        i_entries_to_edit   IN t_tab_allergies_cdas_new,
        i_entries_to_remove IN t_tab_allergies_cdas_new,
        i_cdr_call          IN NUMBER DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(1000) := 'SET_ALLERGIES_CDA';
        l_id_pat_allergy pat_allergy.id_pat_allergy%TYPE;
        l_record         t_rec_allergies_cdas_new;
        l_ret            BOOLEAN;
        l_exception EXCEPTION;
        l_flg_cda_reconciliation VARCHAR2(1) := 'Y';
        l_error                  VARCHAR2(1000);
    BEGIN
    
        IF i_entries_to_add.exists(1)
        THEN
            g_error := 'ADD ALERGIES';
            FOR i IN i_entries_to_add.first .. i_entries_to_add.last
            LOOP
                l_record := i_entries_to_add(i);
                l_error  := 'CALL PK_ALLERGY - SET ALLERGIES - ADD ALLERGY';
                IF NOT (pk_allergy.set_allergy(i_lang                   => i_lang,
                                               i_prof                   => i_prof,
                                               i_id_patient             => i_patient,
                                               i_id_episode             => i_episode,
                                               i_id_pat_allergy         => l_record.id_pat_allergy,
                                               i_id_allergy             => l_record.id_allergy,
                                               i_desc_allergy           => l_record.desc_allergy,
                                               i_notes                  => l_record.notes,
                                               i_flg_status             => l_record.flg_status,
                                               i_flg_type               => l_record.flg_type,
                                               i_flg_aproved            => l_record.flg_approved,
                                               i_desc_aproved           => l_record.desc_approved,
                                               i_year_begin             => l_record.year_begin,
                                               i_id_symptoms            => l_record.symptoms_num_id,
                                               i_day_begin              => l_record.day_begin,
                                               i_month_begin            => l_record.month_begin,
                                               i_id_allergy_severity    => l_record.severity_code,
                                               i_flg_edit               => l_record.flg_edit,
                                               i_desc_edit              => l_record.desc_edit,
                                               i_cdr_call               => i_cdr_call,
                                               i_flg_cda_reconciliation => l_flg_cda_reconciliation,
                                               o_id_pat_allergy         => l_id_pat_allergy,
                                               o_error                  => o_error))
                THEN
                    RAISE l_exception;
                END IF;
            
            END LOOP;
        END IF;
        IF i_entries_to_edit.exists(1)
        THEN
            FOR i IN i_entries_to_edit.first .. i_entries_to_edit.last
            LOOP
                l_error  := 'CALL PK_ALLERGY - SET ALLERGIES - EDIT ALLERGY';
                l_record := i_entries_to_edit(i);
                IF NOT (pk_allergy.set_allergy(i_lang                   => i_lang,
                                               i_prof                   => i_prof,
                                               i_id_patient             => i_patient,
                                               i_id_episode             => i_episode,
                                               i_id_pat_allergy         => l_record.id_pat_allergy,
                                               i_id_allergy             => l_record.id_allergy,
                                               i_desc_allergy           => l_record.desc_allergy,
                                               i_notes                  => l_record.notes,
                                               i_flg_status             => l_record.flg_status,
                                               i_flg_type               => l_record.flg_type,
                                               i_flg_aproved            => l_record.flg_approved,
                                               i_desc_aproved           => l_record.desc_approved,
                                               i_year_begin             => l_record.year_begin,
                                               i_id_symptoms            => l_record.symptoms_num_id,
                                               i_day_begin              => l_record.day_begin,
                                               i_month_begin            => l_record.month_begin,
                                               i_id_allergy_severity    => l_record.severity_code,
                                               i_flg_edit               => l_record.flg_edit,
                                               i_desc_edit              => l_record.desc_edit,
                                               i_cdr_call               => i_cdr_call,
                                               i_flg_cda_reconciliation => l_flg_cda_reconciliation,
                                               o_id_pat_allergy         => l_id_pat_allergy,
                                               o_error                  => o_error))
                THEN
                    RAISE l_exception;
                END IF;
            
            END LOOP;
        END IF;
        IF i_entries_to_remove.exists(1)
        THEN
            FOR i IN i_entries_to_remove.first .. i_entries_to_remove.last
            LOOP
                l_record := i_entries_to_remove(i);
                l_error  := 'CALL PK_ALLERGY - CANCEL ALLERGY - REMOVE ALLERGY';
                IF NOT (pk_allergy.cancel_allergy(i_lang                   => i_lang,
                                                  i_prof                   => i_prof,
                                                  i_id_pat_allergy         => l_record.id_pat_allergy,
                                                  i_id_cancel_reason       => l_record.id_cancel_reason,
                                                  i_cancel_notes           => l_record.cancel_notes,
                                                  i_flg_cda_reconciliation => l_flg_cda_reconciliation,
                                                  o_error                  => o_error))
                THEN
                    RAISE l_exception;
                END IF;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
        
    END set_allergies_cda;

    /********************************************************************************************
    * Converts allergy concepts from/to some code.  
    * @param i_lang                     Language
    * @param i_source_codes             Codes to be mapped
    * @param i_source_coding_scheme     Type code (rxnorm - 6, snomed - 2)
    * @param i_target_coding_scheme     Allergy context (101 - id allergy, 103 - allergy type, 105 - reactions, 106 - severity)
    * @param o_target_codes             All Codes returned
    * @param o_target_display_names     All Code descriptions returned
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-May-2014
    **********************************************************************************************/
    FUNCTION get_mapping_allergy_conc_cda
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_source_codes         IN table_varchar,
        i_source_coding_scheme IN VARCHAR2,
        i_target_coding_scheme IN VARCHAR2,
        i_id_med_context       IN VARCHAR2 DEFAULT NULL,
        o_target_codes         OUT table_varchar,
        o_target_display_names OUT table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_table_mapping_concept t_table_mapping_conc := t_table_mapping_conc();
        l_curr_code             VARCHAR(4000);
        l_record                t_rec_mapping_conc;
        l_index                 NUMBER;
        l_message               VARCHAR(1000);
        l_func_name             VARCHAR(1000) := 'GET_MAPPING_ALLERGY_CONC';
        l_target_codes          table_varchar := NEW table_varchar();
        l_target_display_names  table_varchar := NEW table_varchar();
        l_t_codes               table_varchar := NEW table_varchar();
        l_t_display_names       table_varchar := NEW table_varchar();
        l_conc_not_mapped       VARCHAR2(100) := 'NOT_MAPPED';
        l_error                 VARCHAR2(1000);
    BEGIN
    
        IF i_source_codes.exists(1)
        THEN
            l_error := 'CALL PK_ALLERGY - GET_ALLERGY_INFO_CS_CDA';
            IF NOT (pk_allergy.get_allergy_info_cs_cda(i_lang                    => i_lang,
                                                       i_prof                    => i_prof,
                                                       i_target_coding_scheme    => i_target_coding_scheme,
                                                       i_target_coordinated_expr => i_source_codes,
                                                       i_id_med_context          => i_id_med_context,
                                                       o_target_codes            => l_t_codes,
                                                       o_target_display_name     => l_t_display_names,
                                                       o_error                   => o_error))
            
            THEN
                RETURN FALSE;
            END IF;
        END IF;
        o_target_codes         := l_t_codes;
        o_target_display_names := l_t_display_names;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_message,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_mapping_allergy_conc_cda;

BEGIN
    -- Initialization
    NULL;
END pk_api_edis;
/
