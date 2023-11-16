/*-- Last Change Revision: $Rev: 2026674 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:32 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_discharge IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_exception EXCEPTION;

    -- Function and procedure implementations

    /**
    * Gets the list of tasks that were selected in the GP Letter
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID
    * @param   i_episode      Episode ID
    * @param   i_discharge    Discharge ID
    *
    * @param   o_tasks        List of tasks         
    *
    * @param   o_error        Error information
    *
    * @return  True or False
    *
    * @author  JOSE.SILVA
    * @version 2.6
    * @since   04-03-2010
    */
    FUNCTION get_task_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_tasks     OUT table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_tasks discharge_rep_notes.flg_task%TYPE;
    
        CURSOR c_tasks IS
            SELECT dr.flg_task
              FROM discharge d
              JOIN discharge_rep_notes dr
                ON dr.id_discharge = d.id_discharge
             WHERE d.id_discharge = i_discharge
             ORDER BY dr.dt_reg DESC;
    
    BEGIN
    
        g_error := 'OPEN c_tasks';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'get_task_list');
    
        OPEN c_tasks;
        FETCH c_tasks
            INTO l_flg_tasks;
        CLOSE c_tasks;
    
        g_error := 'RETURN TASKS';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => 'get_task_list');
    
        o_tasks := pk_utils.str_split_l(l_flg_tasks, '|');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TASK_LIST',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_task_list;

    /**
    * Gets the admission date
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID
    * @param   i_episode      Episode ID
    *
    * @param   o_info         Admission date
    *
    * @param   o_error        Error information
    *
    * @return  True or False
    *
    * @author  JOSE.SILVA
    * @version 2.6
    * @since   04-03-2010
    */
    FUNCTION get_admission_date
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_info    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_INFO';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package,
                                      sub_object_name => 'get_admission_date');
    
        OPEN o_info FOR
            SELECT pk_date_utils.date_char_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_admission_chr,
                   e.dt_begin_tstz dt_admission
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_ADMISSION_DATE',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_admission_date;

    /********************************************************************************************
    * Sets a discharge, in ambulatory products.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_prof_cat              logged professional category
    * @param i_disch                 discharge identifier
    * @param i_episode               episode identifier
    * @param i_dt_end                discharge date
    * @param i_disch_dest            discharge reason destiny identifier
    * @param i_notes                 discharge notes_med
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Pedro Teixeira
    * @since                         26/07/2010
    ********************************************************************************************/
    FUNCTION set_discharge_amb
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_cat   IN category.flg_type%TYPE,
        i_disch      IN discharge.id_discharge%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_dt_end     IN VARCHAR2,
        i_disch_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_notes      IN discharge.notes_med%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_show  VARCHAR2(4000 CHAR);
        l_msg_title VARCHAR2(4000 CHAR);
        l_msg_text  VARCHAR2(4000 CHAR);
        l_button    VARCHAR2(4000 CHAR);
    
    BEGIN
        IF NOT pk_discharge.set_discharge_amb(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_prof_cat       => i_prof_cat,
                                              i_disch          => i_disch,
                                              i_episode        => i_episode,
                                              i_dt_end         => i_dt_end,
                                              i_disch_dest     => i_disch_dest,
                                              i_notes          => i_notes,
                                              i_transaction_id => NULL,
                                              o_flg_show       => l_flg_show,
                                              o_msg_title      => l_msg_title,
                                              o_msg_text       => l_msg_text,
                                              o_button         => l_button,
                                              o_error          => o_error)
        THEN
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
                                              i_function => 'SET_DISCHARGE_AMB',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_discharge_amb;

    /**
    * Sets medical discharge info in enviroments where price is specified.
    *
    * @param   i_lang                language associated to the professional executing the request
    * @param   i_episode             episode id
    * @param   i_prof                professional, institution and software ids
    * @param   i_reas_dest           discharge reason by destination
    * @param   i_disch_type          discharge type
    * @param   i_flg_type            flag type
    * @param   i_notes               discharge notes
    * @param   i_transp              transport id
    * @param   i_justify             discharge justify
    * @param   i_prof_cat_type       prof category type
    * @param   i_price               appointment price
    * @param   i_currency            appointment price currency
    * @param   i_flg_payment         payment condition
    * @param   i_flg_surgery         indicates if discharge for internment is associated to a surgery (Y/N)
    * @param   i_dt_surgery          date of surgery
    * @param   i_clin_serv           id_clinical_service of internment speciality, in case od discharge for internment
    * @param   i_department          department id
    * @param   i_flg_print_report    print report (Y/N)
    * @param   i_sysdate             record date
    * @param   i_flg_pat_condition   patient condition
    * @param   o_reports_pat         patient report
    * @param   o_flg_show            does it shows buttons
    * @param   o_msg_title           warning/error message title
    * @param   o_msg_text            warning/error message
    * @param   o_button              the buttons to show in the warning/error
    * @param   o_id_episode          episode id
    * @param   o_id_shortcut         shortcut id
    * @param   o_discharge           discharge id
    * @param   o_discharge_detail    discharge_detail id
    * @param   o_error               error message
             
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version 2.6.0.4
    * @since   18-08-2010
    *
    */
    FUNCTION intf_set_discharge
    (
        i_lang              IN language.id_language%TYPE,
        i_episode           IN discharge.id_episode%TYPE,
        i_prof              IN profissional,
        i_reas_dest         IN discharge.id_disch_reas_dest%TYPE,
        i_disch_type        IN discharge.flg_type%TYPE,
        i_flg_type          IN VARCHAR2,
        i_notes             IN discharge.notes_med%TYPE,
        i_transp            IN transp_entity.id_transp_entity%TYPE,
        i_justify           IN discharge.notes_justify %TYPE,
        i_prof_cat_type     IN category.flg_type%TYPE,
        i_price             IN discharge.price%TYPE,
        i_currency          IN discharge.currency%TYPE,
        i_flg_payment       IN discharge.flg_payment%TYPE,
        i_flg_surgery       IN VARCHAR2,
        i_dt_surgery        IN VARCHAR2,
        i_clin_serv         IN clinical_service.id_clinical_service%TYPE,
        i_department        IN department.id_department%TYPE,
        i_flg_print_report  IN discharge_detail.flg_print_report%TYPE DEFAULT NULL,
        i_sysdate           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_pat_condition IN discharge_detail.flg_pat_condition%TYPE,
        o_reports_pat       OUT reports.id_reports%TYPE,
        o_flg_show          OUT VARCHAR2,
        o_msg_title         OUT VARCHAR2,
        o_msg_text          OUT VARCHAR2,
        o_button            OUT VARCHAR2,
        o_id_episode        OUT episode.id_episode%TYPE,
        o_id_shortcut       OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_discharge         OUT discharge.id_discharge%TYPE,
        o_discharge_detail  OUT discharge_detail.id_discharge_detail%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_discharge.set_discharge_no_commit(i_lang                => i_lang,
                                                    i_episode             => i_episode,
                                                    i_prof                => i_prof,
                                                    i_reas_dest           => i_reas_dest,
                                                    i_disch_type          => i_disch_type,
                                                    i_flg_type            => i_flg_type,
                                                    i_notes               => i_notes,
                                                    i_transp              => i_transp,
                                                    i_justify             => i_justify,
                                                    i_prof_cat_type       => i_prof_cat_type,
                                                    i_price               => i_price,
                                                    i_currency            => i_currency,
                                                    i_flg_payment         => i_flg_payment,
                                                    i_flg_surgery         => i_flg_surgery,
                                                    i_dt_surgery          => i_dt_surgery,
                                                    i_clin_serv           => i_clin_serv,
                                                    i_department          => i_department,
                                                    i_transaction_id      => NULL,
                                                    i_flg_bill_type       => NULL,
                                                    i_flg_print_report    => i_flg_print_report,
                                                    i_flg_letter          => NULL,
                                                    i_flg_task            => NULL,
                                                    i_sysdate             => i_sysdate,
                                                    i_flg_pat_condition   => i_flg_pat_condition,
                                                    i_flg_hist            => pk_alert_constant.g_yes,
                                                    i_dt_fw_visit         => NULL,
                                                    i_id_dep_clin_serv_fw => NULL,
                                                    i_id_prof_fw          => NULL,
                                                    i_sched_notes         => NULL,
                                                    i_id_complaint_fw     => NULL,
                                                    i_reason_for_visit_fw => NULL,
                                                    o_reports_pat         => o_reports_pat,
                                                    o_flg_show            => o_flg_show,
                                                    o_msg_title           => o_msg_title,
                                                    o_msg_text            => o_msg_text,
                                                    o_button              => o_button,
                                                    o_id_episode          => o_id_episode,
                                                    o_id_shortcut         => o_id_shortcut,
                                                    o_discharge           => o_discharge,
                                                    o_discharge_detail    => o_discharge_detail,
                                                    o_error               => o_error)
        THEN
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
                                              i_function => 'SET_DISCHARGE',
                                              o_error    => o_error);
            RETURN FALSE;
    END intf_set_discharge;

    /********************************************************************************************
    * Insert discharge notes, follow-up entities
    * and manages pending issues related to discharge instructions.
    *
    * @param i_lang                    Language id
    * @param i_prof                    Professional, software and institution ids
    * @param i_prof_cat_type           Professional category
    * @param i_epis                    Episode id
    * @param i_patient                 Patient id
    * @param i_id_disch                Discharge notes id
    * @param i_epis_complaint          Patient complaint
    * @param i_epis_diagnosis          Patient diagnosis
    * @param i_recommended             Recommendations for patient    
    * @param i_release_from            Release from work or school
    * @param i_dt_from                 Release from this date...
    * @param i_dt_until                ...until this date
    * @param i_notes_release           Release notes
    * @param i_instructions_discussed  Instructions discussed with...
    * @param i_follow_up_with          Follow-up entities ID (can be a physician, external physician or external institution)
    * @param i_follow_up_in            Array of dates or number of days from which the patient must be followed-up
    * @param i_id_follow_up_type       Array of type of follow-up: D - Date; DY - Days; S - SOS
    * @param i_flg_follow_up_with      Follow-up with: (OC) on-call physician (PH) external physician
                                                       (CL) clinic (OF) office (O) other (free text specified in 'i_follow_up_text')
    * @param i_follow_up_text          Specified follow-up entity, with free text, if 'i_flg_follow_up_with' is 'O'
    * @param i_follow_up_notes         Specific notes for follow-up
    * @param i_issue_assignee         Selected assignee(s) in the multichoice, in the format: P<id> or G<id>
                                       Examples:
                                                P142 (Professional with ID_PROFESSIONAL = 142)
                                                G27  (Group with ID_GROUP = 27)
    * @param i_issue_title             Title for the pending issue
    * @param i_flg_printer             Flag printer: P - Printed
    * @param i_commit_data             Commit date? (Y) Yes (N) No   
    * @param i_sysdate                 record date   
    * @param o_error                   Error message
    *
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          Alexandre Santos
    * @version                         2.6.0.4
    * @since                           2010-08-18
    *
    ********************************************************************************************/
    FUNCTION intf_set_discharge_notes
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_patient                IN patient.id_patient%TYPE,
        i_id_disch               IN discharge_notes.id_discharge_notes%TYPE,
        i_epis_complaint         IN discharge_notes.epis_complaint%TYPE,
        i_epis_diagnosis         IN discharge_notes.epis_diagnosis%TYPE,
        i_recommended            IN discharge_notes.discharge_instructions%TYPE,
        i_release_from           IN discharge_notes.release_from%TYPE,
        i_dt_from                IN VARCHAR2,
        i_dt_until               IN VARCHAR2,
        i_notes_release          IN discharge_notes.notes_release%TYPE,
        i_instructions_discussed IN discharge_notes.instructions_discussed%TYPE,
        i_follow_up_with         IN table_number,
        i_follow_up_in           IN table_varchar,
        i_id_follow_up_type      IN table_number,
        i_flg_follow_up_type     IN follow_up_entity.flg_type%TYPE,
        i_follow_up_text         IN VARCHAR2,
        i_follow_up_notes        IN VARCHAR2,
        i_issue_assignee         IN table_varchar,
        i_issue_title            IN pending_issue.title%TYPE,
        i_flg_printer            IN VARCHAR,
        i_commit_data            IN VARCHAR2,
        i_sysdate                IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_id_discharge_note      OUT discharge_notes.id_discharge_notes%TYPE,
        o_reports_pat            OUT reports.id_reports%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_discharge.set_discharge_notes(i_lang                   => i_lang,
                                                i_prof                   => i_prof,
                                                i_prof_cat_type          => i_prof_cat_type,
                                                i_epis                   => i_epis,
                                                i_patient                => i_patient,
                                                i_id_disch               => i_id_disch,
                                                i_epis_complaint         => i_epis_complaint,
                                                i_epis_diagnosis         => i_epis_diagnosis,
                                                i_discharge_instructions => i_recommended,
                                                i_release_from           => i_release_from,
                                                i_dt_from                => i_dt_from,
                                                i_dt_until               => i_dt_until,
                                                i_notes_release          => i_notes_release,
                                                i_instructions_discussed => table_varchar(i_instructions_discussed),
                                                i_follow_up_with         => i_follow_up_with,
                                                i_follow_up_in           => i_follow_up_in,
                                                i_id_follow_up_type      => i_id_follow_up_type,
                                                i_flg_follow_up_type     => i_flg_follow_up_type,
                                                i_follow_up_text         => i_follow_up_text,
                                                i_follow_up_notes        => i_follow_up_notes,
                                                i_issue_assignee         => i_issue_assignee,
                                                i_issue_title            => i_issue_title,
                                                i_flg_printer            => i_flg_printer,
                                                i_commit_data            => i_commit_data,
                                                i_sysdate                => i_sysdate,
                                                i_flg_csg_patient        => NULL,
                                                i_dt_csg_patient         => NULL,
                                                
                                                o_id_discharge_note => o_id_discharge_note,
                                                o_reports_pat       => o_reports_pat,
                                                o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END intf_set_discharge_notes;

    /********************************************************************************************
    * Clears all records from discharge and related (FK's) tables for the given id_episode's
    *
    * @param i_lang                    Language id
    * @param i_table_id_episodes       table with id episodes
    * @param o_error                   Error message
    *
    * @return                          TRUE if sucess, FALSE otherwise
    *
    * @author                          Alexandre Santos
    * @version                         2.6.0.4
    * @since                           2010-09-08
    *
    ********************************************************************************************/
    FUNCTION clear_discharge_reset
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_episodes IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_discharge.clear_discharge_reset(i_lang              => i_lang,
                                                  i_table_id_episodes => i_table_id_episodes,
                                                  o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    END clear_discharge_reset;
    --
    /**
    * Valid if there report request by the user, if not, creates a report asynchronously.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_EPISODE episode id
    * @param   I_DISCHARGE discharge id
    * @param   I_PROF  professional, institution and software ids
    * @param   I_CURRENCY appointment price currency
    
    
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Nuno Neves
    * @version 2.6.05
    * @since   23-Dec-2010
    */
    FUNCTION check_request_print_report
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN discharge.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        i_prof      IN profissional,
        i_currency  IN discharge.currency%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_print_report VARCHAR2(1);
        l_id_patient       VARCHAR2(200);
        l_reports_pat      reports.id_reports%TYPE;
        l_ret              BOOLEAN;
        e_exception EXCEPTION;
    
    BEGIN
        --flg_print_report
        SELECT er.flg_print_report
          INTO l_flg_print_report
          FROM discharge_detail er
         WHERE er.id_discharge = i_discharge;
    
        --id_patient
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        -- sys_config PRINT_DISCHARGE_REPORT(value) 
        l_reports_pat := pk_sysconfig.get_config(i_code_cf => 'PRINT_DISCHARGE_REPORT', i_prof => i_prof);
    
        -- report request validation
        IF nvl(l_flg_print_report, pk_alert_constant.g_no) != pk_alert_constant.g_yes
           AND l_reports_pat IS NOT NULL
        THEN
            --generation asynchronous
            IF NOT pk_ia_event_common.request_gen_report(i_episode,
                                                         l_id_patient,
                                                         i_prof.institution,
                                                         i_lang,
                                                         l_reports_pat,
                                                         'NULL',
                                                         i_prof.id,
                                                         i_prof.software,
                                                         'D')
            THEN
                RAISE e_exception;
            END IF;
            ---------------------------------
        END IF;
        -----------------------------
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              'pk_api_discharge',
                                              'CHECK_REQUEST_PRINT_REPORT',
                                              o_error);
            pk_utils.undo_changes; -- ROLLBACK
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END check_request_print_report;
    --

    /********************************************************************************************
    * Checks if the current discharge record shows the MyAlert purchase form
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_episode            episode ID
    * @param o_flg_has_trans_model   has transactional model: Y - yes, N - No
    * @param o_error                 error message
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        José Silva
    * @version                       2.6.0.5
    * @since                         13-01-2011
    ********************************************************************************************/
    FUNCTION check_transactional_model
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        o_flg_has_trans_model OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30) := 'CHECK_TRANSACTIONAL_MODEL';
    
    BEGIN
    
        g_error := 'CALL TO PK_DISCHARGE_CORE.CHECK_TRANSACTIONAL_MODEL';
        IF NOT pk_discharge_core.check_transactional_model(i_lang                => i_lang,
                                                           i_prof                => i_prof,
                                                           i_id_episode          => i_id_episode,
                                                           o_flg_has_trans_model => o_flg_has_trans_model,
                                                           o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
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
    END check_transactional_model;

    /********************************************************************************************
    * Sets administrative discharge and ends the episode
    *
    * @param i_lang                           language id
    * @param i_prof                           professional, software and institution ids
    * @param i_episode                        episode id
    * @param i_reas_dest                      Relation between discharge reason and destiny
    * @param i_notes                          Discharge notes
    * @param i_transp                         Transport id
    * @param i_flg_status                     Status                     
    * @param o_flg_show
    * @param o_msg_title
    * @param o_msg_text
    * @param o_button
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 Alexandre Santos
    * @version                                1.0
    * @since                                  27-09-2012
    ********************************************************************************************/
    FUNCTION intf_set_epis_discharge
    (
        i_lang         IN NUMBER,
        i_prof         IN profissional,
        i_episode      IN NUMBER,
        i_flg_new_epis IN VARCHAR2,
        i_reas_dest    IN NUMBER,
        i_notes        IN discharge.notes_med%TYPE,
        i_transp       IN discharge.id_transp_ent_med%TYPE,
        i_flg_status   IN discharge.flg_status%TYPE,
        i_dt_admin     IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_text     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_reports      OUT reports.id_reports%TYPE,
        o_reports_pat  OUT reports.id_reports%TYPE,
        o_id_episode   OUT episode.id_episode%TYPE,
        o_id_discharge OUT discharge.id_discharge%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_cat_type CONSTANT category.flg_type%TYPE := 'A';
        l_disch_type    CONSTANT VARCHAR2(1) := 'F';
        l_flg_type      CONSTANT VARCHAR2(1) := 'M';
        l_shortcut sys_shortcut.id_sys_shortcut%TYPE;
    BEGIN
        RETURN pk_discharge.set_epis_discharge(i_lang                    => i_lang,
                                               i_episode                 => i_episode,
                                               i_prof                    => i_prof,
                                               i_prof_cat_type           => l_prof_cat_type,
                                               i_flg_new_epis            => i_flg_new_epis,
                                               i_reas_dest               => i_reas_dest,
                                               i_disch_type              => l_disch_type,
                                               i_flg_type                => l_flg_type,
                                               i_notes                   => i_notes,
                                               i_notes_det               => NULL,
                                               i_transp                  => i_transp,
                                               i_notes_justify           => NULL,
                                               i_flg_pat_condition       => NULL,
                                               i_id_transport_type       => NULL,
                                               i_id_disch_rea_t_ent_inst => NULL,
                                               i_flg_caretaker           => NULL,
                                               i_caretaker_notes         => NULL,
                                               i_flg_follow_up_by        => NULL,
                                               i_follow_up_notes         => NULL,
                                               i_follow_up_date_str      => NULL,
                                               i_flg_written_notes       => NULL,
                                               i_flg_voluntary           => NULL,
                                               i_flg_pat_report          => NULL,
                                               i_flg_transfer_form       => NULL,
                                               i_id_prof_admitting       => NULL,
                                               i_prof_admitting_desc     => NULL,
                                               i_id_dep_clin_serv_admit  => NULL,
                                               i_dep_clin_serv_ad_desc   => NULL,
                                               i_flg_summary_report      => NULL,
                                               i_flg_autopsy_consent     => NULL,
                                               i_autopsy_consent_desc    => NULL,
                                               i_flg_orgn_dntn_info      => NULL,
                                               i_orgn_dntn_info          => NULL,
                                               i_flg_examiner_notified   => NULL,
                                               i_examiner_notified_info  => NULL,
                                               i_flg_orgn_dntn_f_compl   => NULL,
                                               i_flg_ama_form_complete   => NULL,
                                               i_flg_lwbs_form_complete  => NULL,
                                               i_price                   => NULL,
                                               i_currency                => NULL,
                                               i_flg_payment             => NULL,
                                               i_flg_status              => i_flg_status,
                                               i_mse_type                => NULL,
                                               i_flg_surgery             => NULL,
                                               i_date_surgery_str        => NULL,
                                               i_flg_print_report        => NULL,
                                               i_transfer_diagnosis      => NULL,
                                               i_flg_inst_transfer       => NULL,
                                               i_dt_admin                => i_dt_admin,
                                               i_flg_autopsy             => NULL,
                                               o_flg_show                => o_flg_show,
                                               o_msg_title               => o_msg_title,
                                               o_msg_text                => o_msg_text,
                                               o_button                  => o_button,
                                               o_reports                 => o_reports,
                                               o_reports_pat             => o_reports_pat,
                                               o_id_episode              => o_id_episode,
                                               o_id_discharge            => o_id_discharge,
                                               o_shortcut                => l_shortcut,
                                               o_error                   => o_error);
    END intf_set_epis_discharge;

    FUNCTION intf_set_discharge_date
    (
        i_lang                  IN language.id_language%TYPE,
        i_episode               IN discharge_schedule.id_episode%TYPE,
        i_prof                  IN profissional,
        i_dt_discharge_schedule IN VARCHAR2,
        i_flg_hour_origin       IN VARCHAR2 DEFAULT 'DH',
        o_id_discharge_schedule OUT discharge_schedule.id_discharge_schedule%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient discharge_schedule.id_patient%TYPE;
    
    BEGIN
    
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        RETURN pk_discharge.set_discharge_schedule_date(i_lang                  => i_lang,
                                                        i_episode               => i_episode,
                                                        i_patient               => l_id_patient,
                                                        i_prof                  => i_prof,
                                                        i_dt_discharge_schedule => i_dt_discharge_schedule,
                                                        i_flg_hour_origin       => i_flg_hour_origin,
                                                        o_id_discharge_schedule => o_id_discharge_schedule,
                                                        o_error                 => o_error);
    
    END intf_set_discharge_date;

    /********************************************************************************************
    * Sets  discharge note instructions 
    *
    * @param i_lang                           language id
    * @param i_prof                           professional, software and institution ids
    * @param i_episode                        episode id
    * @param i_patient                        patient id    
    * @param i_discharge_instructions         discharge instructions
    * @param o_id_discharge_notes
    * @param o_error                          error message
    *
    * @return                                 TRUE if sucess, FALSE otherwise
    *
    * @author                                 Alexis Nascimento
    ********************************************************************************************/

    FUNCTION intf_set_discharge_instr
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_patient                IN patient.id_patient%TYPE,
        i_discharge_instructions IN discharge_notes.discharge_instructions%TYPE,
        o_id_discharge_notes     OUT discharge_notes.id_discharge_notes%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        o_reports_pat reports.id_reports%TYPE;
    
    BEGIN
    
        IF NOT pk_discharge.set_discharge_notes(
                                                
                                                i_lang                   => i_lang,
                                                i_prof                   => i_prof,
                                                i_prof_cat_type          => 'D',
                                                i_epis                   => i_episode,
                                                i_patient                => i_patient,
                                                i_id_disch               => NULL,
                                                i_epis_complaint         => NULL,
                                                i_epis_diagnosis         => NULL,
                                                i_discharge_instructions => i_discharge_instructions,
                                                i_discharge_instr_list   => NULL,
                                                i_release_from           => NULL,
                                                i_dt_from                => NULL,
                                                i_dt_until               => NULL,
                                                i_notes_release          => NULL,
                                                i_instructions_discussed => NULL,
                                                i_follow_up_with         => NULL,
                                                i_follow_up_in           => NULL,
                                                i_id_follow_up_type      => NULL,
                                                i_flg_follow_up_type     => NULL,
                                                i_follow_up_text         => NULL,
                                                i_follow_up_notes        => NULL,
                                                i_issue_assignee         => NULL,
                                                i_issue_title            => NULL,
                                                i_flg_printer            => NULL,
                                                i_commit_data            => pk_alert_constant.g_no,
                                                i_sysdate                => NULL,
                                                i_flg_csg_patient        => NULL,
                                                i_dt_csg_patient         => NULL,
                                                o_id_discharge_note      => o_id_discharge_notes,
                                                o_reports_pat            => o_reports_pat,
                                                o_error                  => o_error)
        THEN
        
            RAISE g_exception;
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
                                              i_function => 'INTF_SET_DISCHARGE_INSTR',
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END intf_set_discharge_instr;
BEGIN
    -- Initialization

    g_yes := 'Y';
    g_no  := 'N';

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_api_discharge;
/
