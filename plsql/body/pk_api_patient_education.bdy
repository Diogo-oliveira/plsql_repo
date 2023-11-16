/*-- Last Change Revision: $Rev: 2001943 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2021-11-24 16:20:34 +0000 (qua, 24 nov 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_patient_education IS

    FUNCTION get_pat_education_cda
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_type_scope  IN VARCHAR2,
        i_id_scope    IN NUMBER,
        o_pat_edu_cda OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_patient_education_api_db.get_pat_education_cda(i_lang        => i_lang,
                                                                 i_prof        => i_prof,
                                                                 i_type_scope  => i_type_scope,
                                                                 i_id_scope    => i_id_scope,
                                                                 o_pat_edu_cda => o_pat_edu_cda,
                                                                 o_error       => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_EDUCATION_CDA',
                                              o_error);
            RETURN FALSE;
    END get_pat_education_cda;

    FUNCTION get_pat_educa_instruct_cda
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_scope    IN VARCHAR2,
        i_id_scope      IN NUMBER,
        o_pat_edu_instr OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_patient_education_api_db.get_pat_educa_instruct_cda(i_lang          => i_lang,
                                                                      i_prof          => i_prof,
                                                                      i_type_scope    => i_type_scope,
                                                                      i_id_scope      => i_id_scope,
                                                                      o_pat_edu_instr => o_pat_edu_instr,
                                                                      o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_EDUCA_INSTRUCT_CDA',
                                              o_error);
            RETURN FALSE;
    END get_pat_educa_instruct_cda;

    PROCEDURE insert_ntr_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) IS
        l_rec  nurse_tea_req_hist%ROWTYPE;
        l_rows table_varchar;
    BEGIN
        g_error := 'Get NURSE_TEA_REQ data';
        SELECT ts_nurse_tea_req_hist.next_key,
               ntr.id_nurse_tea_req,
               ntr.id_prof_req,
               ntr.id_episode,
               ntr.req_header,
               ntr.flg_status,
               ntr.notes_req,
               ntr.id_prof_close,
               ntr.notes_close,
               ntr.id_prof_exec,
               ntr.id_prev_episode,
               ntr.dt_nurse_tea_req_tstz,
               ntr.dt_begin_tstz,
               ntr.dt_close_tstz,
               ntr.id_visit,
               ntr.id_patient,
               ntr.status_flg,
               ntr.status_icon,
               ntr.status_msg,
               ntr.status_str,
               ntr.create_user,
               ntr.create_time,
               ntr.create_institution,
               ntr.update_user,
               ntr.update_time,
               ntr.update_institution,
               ntr.id_cancel_reason,
               ntr.id_context,
               ntr.flg_context,
               ntr.id_nurse_tea_topic,
               ntr.id_order_recurr_plan,
               ntr.description,
               ntr.flg_time,
               current_timestamp,
               ntr.desc_topic_aux,
               ntr.id_not_order_reason
          INTO l_rec
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_id_nurse_tea_req;
    
        g_error := 'Insert into history table';
        ts_nurse_tea_req_hist.ins(rec_in => l_rec, rows_out => l_rows);
    
        g_error := 'Process insert on NURSE_TEA_REQ_HIST';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'NURSE_TEA_REQ_HIST',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_NTR_HIST',
                                              o_error);
    END insert_ntr_hist;

    FUNCTION get_diagnosis_struct
    (
        i_id_episode      IN nurse_tea_req.id_episode%TYPE,
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE,
        o_diag_struct     OUT CLOB
    ) RETURN BOOLEAN IS
    
        l_id_patient   patient.id_patient%TYPE;
        l_id_diagnosis alert_diagnosis.id_diagnosis%TYPE;
    
    BEGIN
    
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        SELECT ad.id_diagnosis
          INTO l_id_diagnosis
          FROM alert_diagnosis ad
         WHERE ad.id_alert_diagnosis = i_alert_diagnosis;
    
        o_diag_struct := '<EPIS_DIAGNOSES ID_PATIENT="' || l_id_patient || '" ID_EPISODE="' || i_id_episode ||
                         '" PROF_CAT_TYPE="D" FLG_TYPE="P" FLG_EDIT_MODE="" ID_CDR_CALL="">
                            <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" FLG_TRANSF_FINAL="">
                              <CANCEL_REASON ID_CANCEL_REASON="" FLG_CANCEL_DIFF_DIAG="" />
                              <DIAGNOSIS ID_DIAGNOSIS="' || l_id_diagnosis ||
                         '" ID_ALERT_DIAG="' || i_alert_diagnosis || '">
                                <DESC_DIAGNOSIS>undefined</DESC_DIAGNOSIS>
                                <DIAGNOSIS_WARNING_REPORT>Diagnosis with no form fields.</DIAGNOSIS_WARNING_REPORT>
                              </DIAGNOSIS>
                            </EPIS_DIAGNOSIS>
                            <GENERAL_NOTES ID="" ID_CANCEL_REASON="" />
                          </EPIS_DIAGNOSES>';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END get_diagnosis_struct;

    FUNCTION create_patient_education
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN nurse_tea_req.id_episode%TYPE,
        i_nurse_tea_req      IN table_number, --transacional (Vazio => Novo)
        i_id_nurse_topic     IN table_number,
        i_diagnosis          IN table_clob, --tratar dos diagnósticos
        i_to_be_performed    IN table_varchar,
        i_start_date         IN table_varchar,
        i_notes              IN table_varchar,
        i_description        IN table_clob,
        i_order_recurr_freq  IN table_number,
        i_occurrences        IN table_number,
        i_duration           IN table_number,
        i_unit_meas_duration IN table_number,
        i_end_date           IN table_varchar,
        o_id_nurse_tea_req   OUT table_number,
        o_id_nurse_tea_topic OUT table_number,
        o_title_topic        OUT table_varchar,
        o_desc_diagnosis     OUT table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_order_recurr_desc       order_recurr_area.internal_name%TYPE;
        l_tbl_order_recurr_desc   table_varchar := table_varchar();
        l_order_recurr_option     order_recurr_option.id_order_recurr_option%TYPE;
        l_start_date              TIMESTAMP WITH LOCAL TIME ZONE;
        l_tbl_start_date          table_varchar := table_varchar();
        l_end_date                TIMESTAMP WITH LOCAL TIME ZONE;
        l_tbl_end_date            table_varchar := table_varchar();
        l_occurrences             order_recurr_plan.occurrences%TYPE;
        l_tbl_occurences          table_number := table_number();
        l_duration                order_recurr_plan.duration%TYPE;
        l_tbl_duration            table_number := table_number();
        l_unit_meas_duration      order_recurr_plan.id_unit_meas_duration%TYPE;
        l_tbl_unit_meas_duration  table_number := table_number();
        l_flg_end_by_editable     order_recurr_option.flg_set_end_date%TYPE;
        l_tbl_flg_end_by_editable table_varchar := table_varchar();
        l_order_recurr_plan       order_recurr_plan.id_order_recurr_plan%TYPE;
        l_tbl_order_recurr_plan   table_number := table_number();
    
        l_tbl_id_nurse_tea_req_sugg table_number := table_number();
        l_tbl_desc_topic_aux        table_varchar := table_varchar();
        l_tbl_not_order_reason      table_number := table_number();
    
        l_duration_desc VARCHAR2(1000 CHAR);
    
    BEGIN
        -- call pk_order_recurrence_core.create_order_recurr_plan functio
        FOR i IN i_id_nurse_topic.first .. i_id_nurse_topic.last
        LOOP
            IF NOT pk_order_recurrence_core.create_order_recurr_plan(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_order_recurr_area   => 'PATIENT_EDUCATION',
                                                                     o_order_recurr_desc   => l_order_recurr_desc,
                                                                     o_order_recurr_option => l_order_recurr_option,
                                                                     o_start_date          => l_start_date,
                                                                     o_occurrences         => l_occurrences,
                                                                     o_duration            => l_duration,
                                                                     o_unit_meas_duration  => l_unit_meas_duration,
                                                                     o_end_date            => l_end_date,
                                                                     o_flg_end_by_editable => l_flg_end_by_editable,
                                                                     o_order_recurr_plan   => l_order_recurr_plan,
                                                                     o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.create_order_recurr_plan function';
                RAISE g_exception;
            END IF;
        
            -- call set_order_recurr_option function        
            IF NOT pk_order_recurrence_core.set_order_recurr_option(i_lang                => i_lang,
                                                                    i_prof                => i_prof,
                                                                    i_order_recurr_plan   => l_order_recurr_plan,
                                                                    i_order_recurr_option => i_order_recurr_freq(i),
                                                                    o_order_recurr_desc   => l_order_recurr_desc,
                                                                    o_start_date          => l_start_date,
                                                                    o_occurrences         => l_occurrences,
                                                                    o_duration            => l_duration,
                                                                    o_unit_meas_duration  => l_unit_meas_duration,
                                                                    o_end_date            => l_end_date,
                                                                    o_flg_end_by_editable => l_flg_end_by_editable,
                                                                    o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_option function';
                RAISE g_exception;
            END IF;
        
            -- call pk_order_recurrence_core.set_order_recurr_instructions function
            IF NOT pk_order_recurrence_core.set_order_recurr_instructions(i_lang              => i_lang,
                                                                          i_prof              => i_prof,
                                                                          i_order_recurr_plan => l_order_recurr_plan,
                                                                          i_start_date        => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                               i_prof,
                                                                                                                               i_start_date(i),
                                                                                                                               NULL),
                                                                          
                                                                          i_occurrences         => i_occurrences(i),
                                                                          i_duration            => i_duration(i),
                                                                          i_unit_meas_duration  => i_unit_meas_duration(i),
                                                                          i_end_date            => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 i_end_date(i),
                                                                                                                                 NULL),
                                                                          o_order_recurr_desc   => l_order_recurr_desc,
                                                                          o_start_date          => l_start_date,
                                                                          o_order_recurr_option => l_order_recurr_option,
                                                                          o_occurrences         => l_occurrences,
                                                                          o_duration            => l_duration,
                                                                          o_unit_meas_duration  => l_unit_meas_duration,
                                                                          o_end_date            => l_end_date,
                                                                          o_flg_end_by_editable => l_flg_end_by_editable,
                                                                          o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
                RAISE g_exception;
            END IF;
        
            l_tbl_order_recurr_desc.extend;
            l_tbl_order_recurr_desc(i) := l_order_recurr_desc;
        
            l_tbl_start_date.extend;
            l_tbl_start_date(i) := l_start_date;
        
            l_tbl_occurences.extend;
            l_tbl_occurences(i) := l_occurrences;
        
            l_tbl_duration.extend;
            l_tbl_duration(i) := l_duration;
        
            l_tbl_unit_meas_duration.extend;
            l_tbl_unit_meas_duration(i) := l_unit_meas_duration;
        
            l_tbl_end_date.extend;
            l_tbl_end_date(i) := l_end_date;
        
            l_tbl_flg_end_by_editable.extend;
            l_tbl_flg_end_by_editable(i) := l_flg_end_by_editable;
        
            l_tbl_order_recurr_plan.extend;
            l_tbl_order_recurr_plan(i) := l_order_recurr_plan;
        
            l_tbl_id_nurse_tea_req_sugg.extend();
            l_tbl_id_nurse_tea_req_sugg(i) := NULL;
            l_tbl_desc_topic_aux.extend();
            l_tbl_desc_topic_aux(i) := NULL;
            l_tbl_not_order_reason.extend();
            l_tbl_not_order_reason(i) := NULL;
        
        END LOOP;
    
        IF NOT pk_patient_education_api_db.create_request(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_id_episode            => i_id_episode,
                                                          i_topics                => i_id_nurse_topic,
                                                          i_compositions          => table_table_number(NULL),
                                                          i_to_be_performed       => i_to_be_performed,
                                                          i_start_date            => i_start_date,
                                                          i_notes                 => i_notes,
                                                          i_description           => i_description,
                                                          i_order_recurr          => l_tbl_order_recurr_plan,
                                                          i_draft                 => 'N',
                                                          i_id_nurse_tea_req_sugg => l_tbl_id_nurse_tea_req_sugg,
                                                          i_desc_topic_aux        => l_tbl_desc_topic_aux,
                                                          i_diagnoses             => i_diagnosis,
                                                          i_not_order_reason      => l_tbl_not_order_reason,
                                                          o_id_nurse_tea_req      => o_id_nurse_tea_req,
                                                          o_id_nurse_tea_topic    => o_id_nurse_tea_topic,
                                                          o_title_topic           => o_title_topic,
                                                          o_desc_diagnosis        => o_desc_diagnosis,
                                                          o_error                 => o_error)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    END create_patient_education;

    FUNCTION check_recurr_option_modifying
    (
        i_nurse_tea_req       IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_order_recurr_option IN order_recurr_plan.id_order_recurr_option%TYPE
    ) RETURN BOOLEAN IS
    
        l_order_plan      order_recurr_plan.id_order_recurr_plan%TYPE;
        l_previous_option order_recurr_plan.id_order_recurr_option%TYPE;
    BEGIN
    
        SELECT ntr.id_order_recurr_plan
          INTO l_order_plan
          FROM nurse_tea_req ntr
         WHERE ntr.id_nurse_tea_req = i_nurse_tea_req;
    
        IF l_order_plan IS NULL
           AND i_order_recurr_option = 0
        THEN
            RETURN FALSE;
        ELSIF l_order_plan IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        SELECT orp.id_order_recurr_option
          INTO l_previous_option
          FROM order_recurr_plan orp
         WHERE orp.id_order_recurr_plan = l_order_plan;
    
        IF l_previous_option = i_order_recurr_option
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END check_recurr_option_modifying;

    FUNCTION edit_patient_education
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN nurse_tea_req.id_episode%TYPE,
        i_nurse_tea_req      IN table_number, --transacional (Vazio => Novo)
        i_id_nurse_topic     IN table_number,
        i_diagnosis          IN table_clob, --tratar dos diagnósticos
        i_to_be_performed    IN table_varchar,
        i_start_date         IN table_varchar,
        i_notes              IN table_varchar,
        i_description        IN table_clob,
        i_order_recurr_freq  IN table_number,
        i_occurrences        IN table_number,
        i_duration           IN table_number,
        i_unit_meas_duration IN table_number,
        i_end_date           IN table_varchar,
        o_id_nurse_tea_req   OUT table_number,
        o_id_nurse_tea_topic OUT table_number,
        o_title_topic        OUT table_varchar,
        o_desc_diagnosis     OUT table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_order_recurr_plan   order_recurr_plan.id_order_recurr_plan%TYPE;
        l_order_recurr_desc   order_recurr_area.internal_name%TYPE;
        l_order_recurr_option order_recurr_option.id_order_recurr_option%TYPE;
        l_start_date          TIMESTAMP WITH LOCAL TIME ZONE;
        l_occurrences         order_recurr_plan.occurrences%TYPE;
        l_duration            order_recurr_plan.duration%TYPE;
        l_unit_meas_duration  order_recurr_plan.id_unit_meas_duration%TYPE;
        l_end_date            TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_end_by_editable order_recurr_option.flg_set_end_date%TYPE;
    
        l_tbl_order_recurr_desc     table_varchar := table_varchar();
        l_tbl_start_date            table_varchar := table_varchar();
        l_tbl_end_date              table_varchar := table_varchar();
        l_tbl_occurences            table_number := table_number();
        l_tbl_duration              table_number := table_number();
        l_tbl_unit_meas_duration    table_number := table_number();
        l_tbl_flg_end_by_editable   table_varchar := table_varchar();
        l_tbl_order_recurr_plan     table_number := table_number();
        l_tbl_id_nurse_tea_req_sugg table_number := table_number();
        l_tbl_desc_topic_aux        table_varchar := table_varchar();
        l_tbl_not_order_reason      table_number := table_number();
    
        l_duration_desc VARCHAR2(1000 CHAR);
    
    BEGIN
        -- call pk_order_recurrence_core.create_order_recurr_plan functio
        FOR i IN i_nurse_tea_req.first .. i_nurse_tea_req.last
        LOOP
        
            --If l_order_recurr_plan is NULL => Plan of single execution
            SELECT ntr.id_order_recurr_plan
              INTO l_order_recurr_plan
              FROM nurse_tea_req ntr
             WHERE ntr.id_nurse_tea_req = i_nurse_tea_req(i);
        
            IF l_order_recurr_plan IS NOT NULL
            THEN
                -- call pk_order_recurrence_core.copy_order_recurr_plan function
                IF NOT pk_order_recurrence_core.copy_order_recurr_plan(i_lang                   => i_lang,
                                                                       i_prof                   => i_prof,
                                                                       i_order_recurr_plan_from => l_order_recurr_plan,
                                                                       o_order_recurr_desc      => l_order_recurr_desc,
                                                                       o_order_recurr_option    => l_order_recurr_option,
                                                                       o_start_date             => l_start_date,
                                                                       o_occurrences            => l_occurrences,
                                                                       o_duration               => l_duration,
                                                                       o_unit_meas_duration     => l_unit_meas_duration,
                                                                       o_end_date               => l_end_date,
                                                                       o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                       o_order_recurr_plan      => l_order_recurr_plan,
                                                                       o_error                  => o_error)
                THEN
                    g_error := 'error found while calling pk_order_recurrence_core.copy_order_recurr_plan function';
                    RAISE g_exception;
                END IF;
            
            ELSE
                IF NOT pk_order_recurrence_core.edit_order_recurr_plan(i_lang                   => i_lang,
                                                                       i_prof                   => i_prof,
                                                                       i_order_recurr_area      => 'PATIENT_EDUCATION',
                                                                       i_order_recurr_option    => NULL,
                                                                       i_start_date             => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 i_start_date(i),
                                                                                                                                 NULL),
                                                                       i_occurrences            => NULL,
                                                                       i_duration               => NULL,
                                                                       i_unit_meas_duration     => NULL,
                                                                       i_end_date               => NULL,
                                                                       i_order_recurr_plan_from => NULL,
                                                                       o_order_recurr_desc      => l_order_recurr_desc,
                                                                       o_order_recurr_option    => l_order_recurr_option,
                                                                       o_start_date             => l_start_date,
                                                                       o_occurrences            => l_occurrences,
                                                                       o_duration               => l_duration,
                                                                       o_unit_meas_duration     => l_unit_meas_duration,
                                                                       o_end_date               => l_end_date,
                                                                       o_flg_end_by_editable    => l_flg_end_by_editable,
                                                                       o_order_recurr_plan      => l_order_recurr_plan,
                                                                       o_error                  => o_error)
                THEN
                    g_error := 'error found while calling pk_order_recurrence_core.edit_order_recurr_plan function';
                    RAISE g_exception;
                END IF;
            END IF;
        
            --alterar a função para detetar se vem de Single Execution e se mantém em single
            --A set_option só é necessária quando se altera a frequência
            IF check_recurr_option_modifying(i_nurse_tea_req(i), i_order_recurr_freq(i))
            THEN
                dbms_output.put_line('check_recurr_option_modifying');
                -- call set_order_recurr_option function        
                IF NOT pk_order_recurrence_core.set_order_recurr_option(i_lang                => i_lang,
                                                                        i_prof                => i_prof,
                                                                        i_order_recurr_plan   => l_order_recurr_plan,
                                                                        i_order_recurr_option => i_order_recurr_freq(i),
                                                                        o_order_recurr_desc   => l_order_recurr_desc,
                                                                        o_start_date          => l_start_date,
                                                                        o_occurrences         => l_occurrences,
                                                                        o_duration            => l_duration,
                                                                        o_unit_meas_duration  => l_unit_meas_duration,
                                                                        o_end_date            => l_end_date,
                                                                        o_flg_end_by_editable => l_flg_end_by_editable,
                                                                        o_error               => o_error)
                THEN
                    g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_option function';
                    RAISE g_exception;
                END IF;
            
            END IF;
        
            -- call pk_order_recurrence_core.set_order_recurr_instructions function
            IF NOT pk_order_recurrence_core.set_order_recurr_instructions(i_lang              => i_lang,
                                                                          i_prof              => i_prof,
                                                                          i_order_recurr_plan => l_order_recurr_plan,
                                                                          i_start_date        => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                               i_prof,
                                                                                                                               i_start_date(i),
                                                                                                                               NULL),
                                                                          
                                                                          i_occurrences         => i_occurrences(i),
                                                                          i_duration            => i_duration(i),
                                                                          i_unit_meas_duration  => i_unit_meas_duration(i),
                                                                          i_end_date            => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 i_end_date(i),
                                                                                                                                 NULL),
                                                                          o_order_recurr_desc   => l_order_recurr_desc,
                                                                          o_start_date          => l_start_date,
                                                                          o_order_recurr_option => l_order_recurr_option,
                                                                          o_occurrences         => l_occurrences,
                                                                          o_duration            => l_duration,
                                                                          o_unit_meas_duration  => l_unit_meas_duration,
                                                                          o_end_date            => l_end_date,
                                                                          o_flg_end_by_editable => l_flg_end_by_editable,
                                                                          o_error               => o_error)
            THEN
                g_error := 'error found while calling pk_order_recurrence_core.set_order_recurr_instructions function';
                RAISE g_exception;
            END IF;
        
            l_tbl_order_recurr_desc.extend;
            l_tbl_order_recurr_desc(i) := l_order_recurr_desc;
        
            l_tbl_start_date.extend;
            l_tbl_start_date(i) := l_start_date;
        
            l_tbl_occurences.extend;
            l_tbl_occurences(i) := l_occurrences;
        
            l_tbl_duration.extend;
            l_tbl_duration(i) := l_duration;
        
            l_tbl_unit_meas_duration.extend;
            l_tbl_unit_meas_duration(i) := l_unit_meas_duration;
        
            l_tbl_end_date.extend;
            l_tbl_end_date(i) := l_end_date;
        
            l_tbl_flg_end_by_editable.extend;
            l_tbl_flg_end_by_editable(i) := l_flg_end_by_editable;
        
            l_tbl_order_recurr_plan.extend;
            l_tbl_order_recurr_plan(i) := l_order_recurr_plan;
        
            l_tbl_id_nurse_tea_req_sugg.extend();
            l_tbl_id_nurse_tea_req_sugg(i) := NULL;
            l_tbl_desc_topic_aux.extend();
            l_tbl_desc_topic_aux(i) := NULL;
            l_tbl_not_order_reason.extend();
            l_tbl_not_order_reason(i) := NULL;
        
        END LOOP;
    
        IF NOT pk_patient_education_api_db.update_request(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_episode       => i_id_episode,
                                                          i_id_nurse_tea_req => i_nurse_tea_req,
                                                          i_topics           => i_id_nurse_topic,
                                                          i_compositions     => table_table_number(NULL),
                                                          i_to_be_performed  => i_to_be_performed,
                                                          i_start_date       => i_start_date,
                                                          i_notes            => i_notes,
                                                          i_description      => i_description,
                                                          i_order_recurr     => l_tbl_order_recurr_plan,
                                                          i_upd_flg_status   => 'Y',
                                                          i_diagnoses        => i_diagnosis,
                                                          i_not_order_reason => l_tbl_not_order_reason,
                                                          o_error            => o_error)
        THEN
            RETURN FALSE;
        ELSE
        
            RETURN TRUE;
        END IF;
    
    END edit_patient_education;

    FUNCTION set_patient_education
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN nurse_tea_req.id_episode%TYPE,
        i_nurse_tea_req      IN table_number,
        i_id_nurse_topic     IN table_number,
        i_diagnosis          IN table_number,
        i_to_be_performed    IN table_varchar,
        i_start_date         IN table_varchar,
        i_notes              IN table_varchar,
        i_description        IN table_clob,
        i_order_recurr_freq  IN table_number,
        i_occurrences        IN table_number,
        i_duration           IN table_number,
        i_unit_meas_duration IN table_number,
        i_end_date           IN table_varchar,
        o_id_nurse_tea_req   OUT table_number,
        o_id_nurse_tea_topic OUT table_number,
        o_title_topic        OUT table_varchar,
        o_desc_diagnosis     OUT table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_diagnosis table_clob := table_clob();
    
    BEGIN
    
        FOR i IN i_diagnosis.first .. i_diagnosis.last
        LOOP
            l_diagnosis.extend;
            IF NOT get_diagnosis_struct(i_id_episode, i_diagnosis(i), l_diagnosis(i))
            THEN
                l_diagnosis(i) := NULL;
            END IF;
        END LOOP;
    
        IF i_nurse_tea_req(1) IS NULL
        THEN
            IF NOT create_patient_education(i_lang               => i_lang,
                                            i_prof               => i_prof,
                                            i_id_episode         => i_id_episode,
                                            i_nurse_tea_req      => i_nurse_tea_req,
                                            i_id_nurse_topic     => i_id_nurse_topic,
                                            i_diagnosis          => l_diagnosis,
                                            i_to_be_performed    => i_to_be_performed,
                                            i_start_date         => i_start_date,
                                            i_notes              => i_notes,
                                            i_description        => i_description,
                                            i_order_recurr_freq  => i_order_recurr_freq,
                                            i_occurrences        => i_occurrences,
                                            i_duration           => i_duration,
                                            i_unit_meas_duration => i_unit_meas_duration,
                                            i_end_date           => i_end_date,
                                            o_id_nurse_tea_req   => o_id_nurse_tea_req,
                                            o_id_nurse_tea_topic => o_id_nurse_tea_topic,
                                            o_title_topic        => o_title_topic,
                                            o_desc_diagnosis     => o_desc_diagnosis,
                                            o_error              => o_error)
            THEN
                RETURN FALSE;
            ELSE
                RETURN TRUE;
            END IF;
        ELSE
            IF NOT edit_patient_education(i_lang               => i_lang,
                                          i_prof               => i_prof,
                                          i_id_episode         => i_id_episode,
                                          i_nurse_tea_req      => i_nurse_tea_req,
                                          i_id_nurse_topic     => i_id_nurse_topic,
                                          i_diagnosis          => l_diagnosis,
                                          i_to_be_performed    => i_to_be_performed,
                                          i_start_date         => i_start_date,
                                          i_notes              => i_notes,
                                          i_description        => i_description,
                                          i_order_recurr_freq  => i_order_recurr_freq,
                                          i_occurrences        => i_occurrences,
                                          i_duration           => i_duration,
                                          i_unit_meas_duration => i_unit_meas_duration,
                                          i_end_date           => i_end_date,
                                          o_id_nurse_tea_req   => o_id_nurse_tea_req,
                                          o_id_nurse_tea_topic => o_id_nurse_tea_topic,
                                          o_title_topic        => o_title_topic,
                                          o_desc_diagnosis     => o_desc_diagnosis,
                                          o_error              => o_error)
            THEN
                RETURN FALSE;
            ELSE
                RETURN TRUE;
            END IF;
        END IF;
    
    END set_patient_education;

    FUNCTION cancel_patient_education
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        i_id_cancel_reason IN table_number,
        i_cancel_notes     IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'Cancel patient education';
        FOR i IN 1 .. i_id_nurse_tea_req.count
        LOOP
        
            IF NOT pk_patient_education_api_db.cancel_nurse_tea_req_int(i_lang             => i_lang,
                                                                        i_nurse_tea_req    => i_id_nurse_tea_req(i),
                                                                        i_prof_close       => i_prof,
                                                                        i_notes_close      => i_cancel_notes(i),
                                                                        i_id_cancel_reason => i_id_cancel_reason(i),
                                                                        i_flg_commit       => pk_alert_constant.g_yes,
                                                                        o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'Add to history';
            insert_ntr_hist(i_lang             => i_lang,
                            i_prof             => i_prof,
                            i_id_nurse_tea_req => i_id_nurse_tea_req(i),
                            o_error            => o_error);
        
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_PATIENT_EDUCATION',
                                              o_error);
        
            RETURN FALSE;
    END cancel_patient_education;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_patient_education;
/
