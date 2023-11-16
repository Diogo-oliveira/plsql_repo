/*-- Last Change Revision: $Rev: 2026696 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_pdms IS

    /* CAN'T TOUCH THIS */
    g_error    VARCHAR2(1000 CHAR);
    g_owner    VARCHAR2(30 CHAR);
    g_package  VARCHAR2(30 CHAR);
    g_function VARCHAR2(128 CHAR);
    g_exception EXCEPTION;

    -- debug mode enabled/disabled
    g_debug BOOLEAN;

    g_retval BOOLEAN;

    -- Function and procedure implementations

    /***********************************************************************
                           GLOBAL - Generic Functions
    ***********************************************************************/

    /********************************************************************************************
    * Gets the episode software
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_episode      Episode identifier
    *
    * @return  ID_SOFTWARE
    *
    * @author Rui Teixeira
    * @version 2.6.2.1.1
    * @since 2012-May-18
    ********************************************************************************************/
    FUNCTION get_software_by_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN software.id_software%TYPE IS
        l_error       t_error_out;
        l_id_software software.id_software%TYPE;
    BEGIN
    
        IF pk_episode.get_episode_software(i_lang, i_prof, i_episode, l_id_software, l_error)
        THEN
            RETURN l_id_software;
        END IF;
        RETURN 0;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => l_error);
            RETURN 0;
    END;

    /********************************************************************************************
    * Gets the list of cancel reasons available for a specific area.
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_area         The cancel reason area. -- 'EXM_CANCEL' - Exams; 'LAB_CANCEL' - Lab
    *
    * @param o_reasons      The list of cancel reasons available.
    * @param o_error        Message to be shown to the user.
    *
    * @return  TRUE if succeeded. FALSE otherwise.
    *
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Out-06
    ********************************************************************************************/
    FUNCTION get_cancel_reason_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_area    IN cancel_rea_area.intern_name%TYPE,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'get_cancel_reason_list';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_cancel_reason.get_cancel_reason_list(i_lang, i_prof, i_area, o_reasons, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /*
    * Get episodes for a visit
    *
    * @param      I_LANG                     Language identififer
    * @param      I_PROF                     Professional identifier
    * @param      I_VISIT                    Visit identifier
    * @param      I_DT_START                 Start date
    * @param      I_DT_END                   End date
    * @param      O_EPISODES                 Episode list
    * @param      O_ERROR                    Error object
    *
    * @return    TRUE on success or FALSE on error
    *
    * @author Tiago Lourenço
    * @version 2.6.0.4
    * @since 3-Nov-2010
    */
    FUNCTION get_visit_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN institution.id_institution%TYPE,
        i_dt_start IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        o_episodes OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_begin episode.dt_begin_tstz%TYPE;
        l_dt_end   episode.dt_end_tstz%TYPE;
    BEGIN
        g_function := 'get_visit_episodes';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_start, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        OPEN o_episodes FOR
            SELECT epis.id_episode,
                   epis.flg_status,
                   pk_sysdomain.get_domain(g_episode_code_domain, epis.flg_status, i_lang) AS flg_status_desc,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_end_tstz, i_prof) dt_end,
                   pk_api_pdms.get_episode_disposition_date(i_lang, i_prof, epis.id_episode, epis.id_epis_type) dt_disposition,
                   epis.id_epis_type,
                   pk_translation.get_translation(i_lang, et.code_epis_type) epis_type_desc,
                   pk_translation.get_translation(i_lang, et.code_icon) epis_type_icon,
                   get_software_by_episode(i_lang, i_prof, epis.id_episode) id_software
              FROM episode epis
              JOIN epis_type et
                ON epis.id_epis_type = et.id_epis_type
             WHERE epis.id_visit = i_visit
               AND epis.flg_status <> pk_alert_constant.g_epis_diag_flg_status_c -- Ignore cancelled
               AND epis.flg_ehr IN (pk_alert_constant.g_epis_ehr_normal, pk_alert_constant.g_epis_ehr_schedule) -- Ignore EHR episodes
               AND ((epis.dt_begin_tstz <= l_dt_end) AND (epis.dt_end_tstz IS NULL OR epis.dt_end_tstz >= l_dt_begin));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_episodes);
            RETURN FALSE;
    END get_visit_episodes;

    FUNCTION get_episode_disposition_date
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN VARCHAR2 IS
        l_disp_date      VARCHAR2(4000);
        l_disp_date_tstz epis_info.dt_med_tstz%TYPE;
        l_disp_label     VARCHAR2(4000);
        r_epis_info      epis_info%ROWTYPE;
        o_error          t_error_out;
        e_internal_exception EXCEPTION;
    BEGIN
        IF (i_id_epis_type = pk_alert_constant.g_epis_type_inpatient)
        THEN
            SELECT ei.*
              INTO r_epis_info
              FROM epis_info ei
             WHERE ei.id_episode = i_id_episode;
        
            IF (pk_api_inpatient.get_inp_disposition_date(i_lang,
                                                          i_prof,
                                                          r_epis_info,
                                                          l_disp_date,
                                                          l_disp_date_tstz,
                                                          l_disp_label,
                                                          o_error))
            THEN
                IF (l_disp_date = '---')
                THEN
                    RETURN NULL;
                ELSE
                    RETURN pk_date_utils.date_send_tsz(i_lang, l_disp_date_tstz, i_prof);
                END IF;
            ELSE
                RAISE e_internal_exception;
            END IF;
        END IF;
        RETURN NULL;
    EXCEPTION
        WHEN e_internal_exception THEN
            raise_application_error(o_error.ora_sqlcode, o_error.ora_sqlerrm);
            RETURN NULL;
    END get_episode_disposition_date;

    /***********************************************************************
                            Events
    ***********************************************************************/

    /*******************************************************************************************************************************************
    * GET_patient_tasks_pdms          Function that returns all the information that should be sent to FLASH concerning TASK TIMELINE functionality
    *                                 for only one patient (episode and visit)
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             ID_EPISODE that should be searched in Task Timeline information (available visits in current grid)
    * @param I_ID_VISIT               ID_VISIT that should be searched in Task Timeline information (available visits in current grid)
    * @param I_TL_TASK_LIST           TABLE_NUMBER with all ID_TL_TASK that should be searched in Task Timeline information (available TL_TASKS in current institution)
    * @param I_FLG_METHOD             'R' - Filter by requisition date / 'E' - Filter by execution date
    * @param I_DT_START               Date to filter (lower limit)
    * @param I_DT_END                 Date to filter (higher limit)
    * @param O_DATE_SERVER            Parameter that returns current server date as a VARCHAR2
    * @param O_PATIENTS_TASK          Cursor that returns available tasks for current visit's and available tl_task's
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    *
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Out-06
    *******************************************************************************************************************************************/
    FUNCTION get_patient_tasks_pdms
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN task_timeline_ea.id_episode%TYPE DEFAULT NULL,
        i_id_visit      IN task_timeline_ea.id_visit%TYPE DEFAULT NULL,
        i_tl_task_list  IN table_number DEFAULT NULL,
        i_flg_method    IN VARCHAR2,
        i_dt_start      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        o_date_server   OUT VARCHAR2,
        o_patient_tasks OUT pk_types.cursor_type,
        o_cur_last_info OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package,
                                      sub_object_name => 'get_patient_tasks_pdms');
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text            => g_error,
                                      object_name     => g_package,
                                      sub_object_name => 'get_patient_tasks_pdms');
        RETURN pk_timeline.get_patient_tasks_pdms(i_lang,
                                                  i_prof,
                                                  i_id_episode,
                                                  i_id_visit,
                                                  i_tl_task_list,
                                                  i_flg_method,
                                                  i_dt_start,
                                                  i_dt_end,
                                                  o_date_server,
                                                  o_patient_tasks,
                                                  o_cur_last_info,
                                                  o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'get_patient_tasks_pdms',
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /***********************************************************************
                            Positionings
    ***********************************************************************/

    /********************************************************************************************
    * Cancels a positioning given by its epis_positioning id by setting 
    * an epis_positioning to interrupted
    *
    * @param i_lang language id
    * @param i_prof professional information
    * @param i_pos_status epis_positioning id
    * @param i_notes Status change notes
    * @param i_id_cancel_reason cancel reason id
    * @param o_error error information
    *
    * @return boolean true on success, otherwise false
    *
    * @author João Reis
    * @version 2.6.0.4
    * @since 2010-Out-14
    ********************************************************************************************/
    FUNCTION cancel_positioning
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pos         IN epis_positioning.id_epis_positioning%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_id_cancel_reason IN epis_positioning.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'cancel_positioning';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_inpatient.set_epis_pos_status(i_lang,
                                                    i_prof,
                                                    i_epis_pos,
                                                    'C',
                                                    i_notes,
                                                    i_id_cancel_reason,
                                                    o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /***************************************************************************************************************
    * Function that executes a positioning movement
    *
    *
    * @param i_lang language ID
    * @param i_prof ALERT profissional
    * @param i_epis_pos ID_EPISODE to check
    * @param i_dt_exec_str date os positioning execution
    * @param i_notes execution notes
    * @param i_rot_interv rotation interval
    * @param o_error If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN TRUE or FALSE
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Out-06
    ****************************************************************************************************/
    FUNCTION execute_positioning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis_pos    IN epis_positioning.id_epis_positioning%TYPE,
        i_dt_exec_str IN VARCHAR2,
        i_notes       IN epis_positioning.notes%TYPE,
        i_rot_interv  IN epis_positioning.rot_interval%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'execute_positioning';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_inpatient.set_epis_positioning(i_lang,
                                                     i_prof,
                                                     i_epis_pos,
                                                     i_dt_exec_str,
                                                     i_notes,
                                                     i_rot_interv,
                                                     o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /***********************************************************************
                            Surgery
    ***********************************************************************/

    /********************************************************************************************
    * Get surgery time for a specific visit.
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_visit         Id visit
    * @param i_dt_begin         Start date for surgery time
    * @param i_dt_end           End date for surgery time
    *
    * @param o_surgery_time_def Cursor with all type of surgery times.
    * @param o_surgery_times    Cursor with surgery times by visit.
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Out-06
    ********************************************************************************************/

    FUNCTION get_op_times_between_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_dt_begin         IN VARCHAR2 DEFAULT NULL,
        i_dt_end           IN VARCHAR2 DEFAULT NULL,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_function := 'get_op_times_between_dates';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_oris.get_surgery_times_visit(i_lang,
                                                   i_prof,
                                                   i_id_visit,
                                                   i_dt_begin,
                                                   i_dt_end,
                                                   o_surgery_time_def,
                                                   o_surgery_times,
                                                   o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Set surgery times
    *
    * @param i_lang             ID language
    * @param i_prof             Professional, institution and software IDs
    * @param i_sr_surgery_time  List of ID Surgery time type
    * @param i_episode          ID episode
    * @param i_dt_surgery_time  List of Surgery time/date
    * @param i_dt_reg           Record date
    *
    * @param o_flg_show         Show message: Y/N
    * @param o_msg_result       Message to show
    * @param o_title            Message title
    * @param o_button           Buttons to show: NC - Yes/No button
    *                                            C - Read button
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Out-06
    ********************************************************************************************/

    FUNCTION set_operative_time
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_sr_surgery_time IN table_number,
        i_episode         IN episode.id_episode%TYPE,
        i_dt_surgery_time IN table_varchar,
        o_flg_show        OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_title           OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_flg_refresh     OUT VARCHAR2,
        o_sr_surgery_time OUT sr_surgery_time.id_sr_surgery_time%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
    BEGIN
    
        g_function := 'set_operative_time';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        -- First validate data, then execute it
    
        FOR i IN 1 .. i_sr_surgery_time.count
        LOOP
            IF NOT pk_api_oris.set_surgery_time(i_lang,
                                                i_sr_surgery_time(i),
                                                i_episode,
                                                i_dt_surgery_time(i),
                                                i_prof,
                                                'Y',
                                                l_transaction_id,
                                                o_flg_show,
                                                o_msg_result,
                                                o_title,
                                                o_button,
                                                o_flg_refresh,
                                                o_error)
            THEN
                RAISE g_exception;
            ELSE
                IF o_msg_result IS NOT NULL
                THEN
                    o_sr_surgery_time := i;
                END IF;
            END IF;
        END LOOP;
    
        FOR i IN 1 .. i_sr_surgery_time.count
        LOOP
            IF NOT pk_api_oris.set_surgery_time(i_lang,
                                                i_sr_surgery_time(i),
                                                i_episode,
                                                i_dt_surgery_time(i),
                                                i_prof,
                                                'N',
                                                l_transaction_id,
                                                o_flg_show,
                                                o_msg_result,
                                                o_title,
                                                o_button,
                                                o_flg_refresh,
                                                o_error)
            THEN
                RAISE g_exception;
            END IF;
        END LOOP;
    
        IF l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obtém os tempos operatórios para um dado episódio.
    *
    * @param i_lang             Id do idioma
    * @param i_software         Id do software
    * @param i_institution      Id da instituição
    * @param i_episode          Id do episódio
    * 
    * @param o_surgery_time_def Cursor com as categorias de tempos operatórios definidos para o 
    *                            software e instituição definidos.
    * @param o_surgery_times    Cursor com os tempos operatórios para o episódio definido.
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   João Reis
    * @since                    2010/11/08
       ********************************************************************************************/

    FUNCTION get_op_times_by_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'get_surgery_times';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_oris.get_surgery_times(i_lang, i_prof, i_episode, o_surgery_time_def, o_surgery_times, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Get a default record date for a operative time category of a given episode.
    * The default data is obtained by the last active record, and in case of the lack of this value, returns the system date.
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional ID, institution ID and software id
    * @param i_sr_surgery_time  operative time id
    * @param i_episode          episode id
    * 
    * @param o_date             default time date for a given episode id and operative time id
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   João Reis
    * @since                    2010/11/22
       ********************************************************************************************/
    FUNCTION get_op_default_time
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_sr_surgery_time IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_date            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'get_op_default_time';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_sr_surg_record.get_surg_time_default_date(i_lang,
                                                            i_prof,
                                                            i_sr_surgery_time,
                                                            i_episode,
                                                            o_date,
                                                            o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END;

    /***********************************************************************
                           TASKS
    ***********************************************************************/

    /*******************************************************************************************************************************************
    * Name:                           get_tasks_type
    * Description:                    Function that return the list of available tasks in table TL_TASK for current timeline and professional
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional information Vector: (professional ID, institution ID, software ID)
    * @param O_TL_TASKS               Cursor with information about available tasks in selected task timeline for current professional
    * @param O_ERROR                  Error information
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * @value I_ID_TL_TIMELINE         {*} '1' Episode timeline {*} '2' Task timeline
    * 
    * @return                         Return FALSE if an error occours, otherwise return TRUE
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         João Reis
    * @version                        2.6.0.4
    * @since                          2010-Out-14
    *******************************************************************************************************************************************/
    FUNCTION get_tasks_type
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_tl_tasks OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'get_tasks_type';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_timeline.get_tl_tasks(i_lang, i_prof, '2', o_tl_tasks, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /*
    * Start movement or end movement based in the current status
    *
    * @param     i_lang            Language id
    * @param     i_movement        Moviment id
    * @param     i_prof            Professional
    * @param     o_error           Error message
    
    * @return    string on success or error
    *
    * @author Tiago Lourenço
    * @version 2.6.0.4
    * @since 20-Out-2010
    */

    FUNCTION set_movement
    (
        i_lang     IN language.id_language%TYPE,
        i_movement IN movement.id_movement%TYPE,
        i_prof     IN profissional,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        i_id_prof      profissional := i_prof;
        o_lang         language.id_language%TYPE;
        o_desc_lang    language.desc_language%TYPE;
        o_time         prof_preferences.timeout%TYPE;
        o_first_screen prof_preferences.first_screen%TYPE;
        o_photo        VARCHAR2(1024);
        o_nick_name    professional.nick_name%TYPE;
        o_name         professional.name%TYPE;
        o_cat_type     category.flg_type%TYPE;
        o_clin_cat     category.flg_clinical%TYPE;
        o_header       VARCHAR2(10);
        o_shortcut     sys_shortcut.id_sys_shortcut%TYPE;
        o_num_mecan    prof_institution.num_mecan%TYPE;
    BEGIN
        g_function := 'set_movement';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        /* GET PROF CAT TYPE */
        IF NOT pk_login.get_prof_pref(i_lang,
                                      i_id_prof,
                                      o_lang,
                                      o_desc_lang,
                                      o_time,
                                      o_first_screen,
                                      o_photo,
                                      o_nick_name,
                                      o_name,
                                      o_cat_type,
                                      o_clin_cat,
                                      o_header,
                                      o_shortcut,
                                      o_num_mecan,
                                      o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_movement.set_movement(i_lang, i_movement, i_prof, o_cat_type, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /***********************************************************************
                            BackOffice functions
    ***********************************************************************/

    /*
    * Get softwares available for institution
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_INSTITUTION           Identificação da Instituição
    * @param      o_software                 Cursor com a lista de Perfis 
    * @param      O_ERROR                    Erro
    *
    * @return    string on success or error
    *
    * @author Rui Teixeira e João Reis
    * @version 2.6.0.4
    * @since 26-Out-2010
    */
    FUNCTION get_institution_software
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_software       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'get_institution_software';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_backoffice.get_institution_software(i_lang, i_id_institution, o_software, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /***********************************************************************
                            Severity Scores functions
    ***********************************************************************/

    /********************************************************************************************
    * Get Severit Scores for a given date period and visit id. 
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_visit         Id visit
    * @param i_dt_begin         Start date for surgery time
    * @param i_dt_end           End date for surgery time
    *
    * @param o_sev_scoress      cursor with severity score values and definitions
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author João Reis
    * @version 2.6.0.4
    * @since 2010-DEZ-20
    ********************************************************************************************/

    FUNCTION get_sev_scores_between_dates
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_visit    IN visit.id_visit%TYPE,
        i_dt_begin    IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        o_sev_scoress OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_function := 'get_sev_scores_between_dates';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_sev_scores_api_ui.get_sev_scores_pdms(i_lang,
                                                        i_prof,
                                                        i_id_visit,
                                                        i_dt_begin,
                                                        i_dt_end,
                                                        o_sev_scoress,
                                                        o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Get shortcuts available for a professional
    *
    * @param i_lang                 Id language
    * @param i_prof                 Professional, software and institution ids
    * @param i_list_shrtcut_id      Shortcuts identifiers
    *
    * @param o_shortcuts            Cursor with shortcut id's
    * @param o_error                Error message
    *
    * @return                       TRUE/FALSE
    *
    * @author Miguel Gomes
    * @version 2.6.4.3
    * @since 2014-Nov-06
    ********************************************************************************************/
    FUNCTION get_shortcuts
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_list_shrtcut_id IN table_number,
        o_shortcuts       OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_t_sht    pk_access.t_shortcut;
        l_o_access pk_access.c_shortcut;
        l_o_prt    pk_types.cursor_type;
    
        l_params VARCHAR2(1000 CHAR);
    BEGIN
    
        g_function := 'get_shortcuts';
        l_params   := 'i_lang=' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof);
    
        g_error := 'Init ' || g_function || ' / ' || l_params;
    
        o_shortcuts := table_varchar();
    
        o_shortcuts.extend(i_list_shrtcut_id.count);
    
        FOR sh_index IN 1 .. i_list_shrtcut_id.count
        LOOP
        
            g_error  := 'Call pk_access.get_shortcut / ' || i_list_shrtcut_id(sh_index) || ' - ' || l_params;
            g_retval := pk_access.get_shortcut(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_patient => NULL,
                                               i_episode => NULL,
                                               i_short   => i_list_shrtcut_id(sh_index),
                                               o_access  => l_o_access,
                                               o_prt     => l_o_prt,
                                               o_error   => o_error);
        
            FETCH l_o_access
                INTO l_t_sht;
        
            IF l_o_access%NOTFOUND
            THEN
                o_shortcuts(sh_index) := pk_alert_constant.get_no;
            ELSE
                o_shortcuts(sh_index) := pk_alert_constant.get_yes;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_shortcuts;

    /********************************************************************************************
    * Get all episode related data that is need on PDMS
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_episode       Episode identifier
    *
    * @param o_data             Response with data from episode and visit
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author Rui Teixeira
    * @version 2.6.0.4
    * @since 2010-Nov-19
    ********************************************************************************************/
    FUNCTION get_epis_data_for_pdms
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        g_error VARCHAR2(4000);
        --
    BEGIN
    
        pk_alertlog.log_debug('Get episode and visit info for PDMS');
    
        g_function := 'get_epis_data_for_pdms';
        g_error    := 'GET EPISODE INFORMATION';
    
        OPEN o_data FOR
            SELECT epis.id_institution id_institution,
                   ei.id_software id_software,
                   epis.id_episode id_episode,
                   epis.id_visit id_visit,
                   epis.id_patient id_patient,
                   epis.id_dept id_dept,
                   epis.id_clinical_service id_clinical_service,
                   ei.id_dep_clin_serv id_dep_clin_serv,
                   epis.flg_status flg_status,
                   epis.id_epis_type id_epis_type,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) epis_dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_end_tstz, i_prof) epis_dt_end,
                   pk_date_utils.date_send_tsz(i_lang, v.dt_begin_tstz, i_prof) visit_dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, v.dt_end_tstz, i_prof) visit_dt_end,
                   ei.id_professional id_responsible_professional,
                   pk_prof_utils.get_nickname(i_lang, i_prof.id) prof_nick_name,
                   pk_prof_utils.get_prof_speciality(i_lang, i_prof) prof_specialty
              FROM episode epis
              JOIN visit v
                ON epis.id_visit = v.id_visit
              JOIN epis_info ei
                ON epis.id_episode = ei.id_episode
             WHERE epis.id_episode = i_id_episode;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_epis_data_for_pdms;

    /***********************************************************************
                            Monitoring - Vital Signs functions
    ***********************************************************************/

    /***********************************************************************
                           Medication functions
    ***********************************************************************/

    /******************************************************************************
    * Cancel severity score
    *
    * @param   I_LANG - Professional language
    * @param   I_PROF - Profissional 
    * @param   I_ID_EPISODE - Episode
    * @param   I_EPIS_MTOS_SCORE - Severity score evaluation ID
    * @param   I_ID_CANCEL_REASON - Razão de cancelamento
    * @param   I_NOTES - Notas
    * @param   O_ERROR - error
    * 
    * @author                Rui Teixeira
    * @version               2.6.1.1
    * @since                 2011/05/26
    * *********************************************************************************/
    FUNCTION cancel_sev_score
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_epis_mtos_score  IN epis_mtos_score.id_epis_mtos_score%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes            IN epis_mtos_score.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'cancel_sev_score';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        /* GET PROF CAT TYPE */
        IF NOT pk_sev_scores_api_ui.cancel_sev_score(i_lang,
                                                     i_prof,
                                                     i_id_episode,
                                                     i_epis_mtos_score,
                                                     i_id_cancel_reason,
                                                     i_notes,
                                                     o_error)
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
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
     * Returns a ref cursor with id episode and id patient of a barcode
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_barcode                Barcode
     * @param o_error                  Error message
     *
     * @return                         Ref cursor with id episode and id patient of a barcode
    *
    * @author                Rui Teixeira
    * @version               2.6.1.1
    * @since                 2011/01/11
    ********************************************************************************************/
    FUNCTION call_get_barcode_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_barcode    IN episode.barcode%TYPE,
        l_id_episode OUT episode.id_episode%TYPE,
        l_id_patient OUT patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        o_result pk_types.cursor_type;
        l_ret    BOOLEAN;
    BEGIN
        l_ret := FALSE;
        IF pk_barcode.get_grid_barcode(i_lang, i_prof, i_barcode, o_result, o_error)
        THEN
            FETCH o_result
                INTO l_id_episode, l_id_patient;
            l_ret := TRUE;
        END IF;
        IF o_result%ISOPEN
        THEN
            CLOSE o_result;
        END IF;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            -- could not open cursor
            RETURN FALSE;
        
    END call_get_barcode_data;
    /********************************************************************************************
     * Get patient data to ALERT CAP from barcode
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_institution         Institution identifier
     * @param i_barcode                Barcode
     * @param o_result                 Patient data
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
    *
    * @author                Rui Teixeira
    * @version               2.6.0.5
    * @since                 2011/02/23
    ********************************************************************************************/
    PROCEDURE get_cap_barcode_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof_id        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_prof_soft      IN software.id_software%TYPE,
        i_barcode        IN episode.barcode%TYPE,
        o_result         OUT pk_types.cursor_type
    ) IS
        o_error      t_error_out;
        o_software   pk_types.cursor_type;
        l_result     BOOLEAN;
        l_id_episode episode.id_episode%TYPE;
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_pat_age    NUMBER(24, 12);
        l_pat_photo  BLOB := NULL;
        l_silhouette VARCHAR2(200) := NULL;
        i_prof       profissional;
        l_can_end    VARCHAR2(1) := '0';
    
        l_soft_id   software.id_software%TYPE;
        l_soft_desc VARCHAR(200);
        l_soft_icon VARCHAR(200);
    
        l_id_institution institution.id_institution%TYPE;
        l_id_prof        professional.id_professional%TYPE;
        l_cnt            NUMBER;
    
        l_timestamp_str VARCHAR2(100);
        l_offset        VARCHAR2(100 CHAR);
    
    BEGIN
    
        g_function := 'get_cap_barcode_data';
    
        -- get institution of episode
    
        SELECT COUNT(1)
          INTO l_cnt
          FROM episode e
         WHERE barcode = i_barcode;
    
        IF l_cnt > 0
        THEN
            SELECT e.id_institution, pi.id_professional
              INTO l_id_institution, l_id_prof
              FROM episode e
              JOIN prof_institution pi
                ON e.id_institution = pi.id_institution
             WHERE barcode = i_barcode
               AND rownum = 1
               AND pi.id_professional = i_prof_id;
        ELSE
            l_id_institution := i_id_institution;
            l_id_prof        := i_prof_id;
        END IF;
    
        i_prof := NEW profissional(l_id_prof, l_id_institution, i_prof_soft);
    
        IF pk_login.get_software_list(i_lang, i_prof, o_software, l_timestamp_str, l_offset, o_error)
        THEN
        
            FETCH o_software
                INTO l_soft_id, l_soft_desc, l_soft_icon;
        
            WHILE o_software%FOUND
                  AND l_can_end = '0'
            LOOP
                g_error := 'Init';
                alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
                g_error := 'Get barcode data';
                alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
            
                i_prof := NEW profissional(l_id_prof, l_id_institution, l_soft_id);
                -- Test statements here
                IF call_get_barcode_data(i_lang, i_prof, i_barcode, l_id_episode, l_id_patient, o_error)
                THEN
                
                    --             if o_result%rowcount > 0 then    
                
                    --           if l_result and o_result%isopen and o_result%rowcount > 0 then       
                
                    l_can_end := '1';
                
                    g_error := 'Get visit data';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => g_function);
                
                    l_id_visit := pk_episode.get_id_visit(l_id_episode);
                
                    g_error := 'Check if can show patient photo';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => g_function);
                
                    IF pk_adt.show_patient_info(i_lang         => i_lang,
                                                i_patient      => l_id_patient,
                                                i_is_prof_resp => pk_patient.get_prof_resp(i_lang     => i_lang,
                                                                                           i_prof     => i_prof,
                                                                                           i_patient  => l_id_patient,
                                                                                           i_episode  => l_id_episode,
                                                                                           i_schedule => NULL))
                    THEN
                        g_error := 'Get patient photo blob';
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package,
                                                      sub_object_name => g_function);
                    
                        l_result := pk_patphoto.get_blob(l_id_patient, i_prof, l_pat_photo, o_error);
                    END IF;
                    IF NOT l_result
                       OR l_pat_photo IS NULL
                       OR dbms_lob.getlength(l_pat_photo) = 0
                    THEN
                        g_error := 'Patient photo not found getting silhouette';
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package,
                                                      sub_object_name => g_function);
                        l_silhouette := pk_hea_prv_pat.get_value(i_lang,
                                                                 i_prof,
                                                                 NULL,
                                                                 l_id_patient,
                                                                 l_id_episode,
                                                                 NULL,
                                                                 NULL,
                                                                 'PAT_PHOTO');
                    END IF;
                END IF;
                FETCH o_software
                    INTO l_soft_id, l_soft_desc, l_soft_icon;
            END LOOP;
        END IF;
        l_pat_age := pk_patient.get_pat_age(i_lang, l_id_patient, i_prof);
        OPEN o_result FOR
            SELECT l_id_patient id_patient,
                   l_id_episode id_episode,
                   l_id_visit id_visit,
                   CASE
                        WHEN dbms_lob.getlength(l_pat_photo) = 0 THEN
                         NULL
                        ELSE
                         l_pat_photo
                    END pat_photo,
                   l_silhouette silhouette,
                   pk_patient.get_pat_name(i_lang, i_prof, l_id_patient, NULL) pat_name,
                   l_pat_age pat_age,
                   pk_patient.get_pat_gender(l_id_patient) pat_gender
              FROM dual;
        --RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_result);
            --     RETURN FALSE;
    END get_cap_barcode_data;

    /********************************************************************************************
     * Get patient data to ALERT CAP from barcode
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_institution         Institution identifier
     * @param i_barcode                Barcode
     * @param o_result                 Patient data
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
    *
    * @author                Rui Teixeira
    * @version               2.6.0.5
    * @since                 2011/02/23
    ********************************************************************************************/
    PROCEDURE get_gw_barcode_data2
    (
        i_lang           IN language.id_language%TYPE,
        i_prof_id        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_prof_soft      IN software.id_software%TYPE,
        i_barcode        IN episode.barcode%TYPE,
        o_photo          OUT BLOB,
        o_result         OUT pk_types.cursor_type
    ) IS
        o_error      t_error_out;
        o_software   pk_types.cursor_type;
        l_result     BOOLEAN;
        l_id_episode episode.id_episode%TYPE;
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_pat_age    NUMBER(24, 12);
        l_pat_photo  BLOB := NULL;
        l_silhouette VARCHAR2(200) := NULL;
        i_prof       profissional;
        l_can_end    VARCHAR2(1) := '0';
    
        l_soft_id   software.id_software%TYPE;
        l_soft_desc VARCHAR(200);
        l_soft_icon VARCHAR(200);
    
        l_id_institution institution.id_institution%TYPE;
        l_id_prof        professional.id_professional%TYPE;
        l_cnt            NUMBER;
    
        l_timestamp_str VARCHAR2(100);
        l_offset        VARCHAR2(100 CHAR);
    
    BEGIN
    
        g_function := 'get_cap_barcode_data';
    
        -- get institution of episode
    
        SELECT COUNT(1)
          INTO l_cnt
          FROM episode e
         WHERE barcode = i_barcode;
    
        IF l_cnt > 0
        THEN
            SELECT e.id_institution, pi.id_professional
              INTO l_id_institution, l_id_prof
              FROM episode e
              JOIN prof_institution pi
                ON e.id_institution = pi.id_institution
             WHERE barcode = i_barcode
               AND rownum = 1
               AND pi.id_professional = i_prof_id;
        ELSE
            l_id_institution := i_id_institution;
            l_id_prof        := i_prof_id;
        END IF;
    
        i_prof := NEW profissional(l_id_prof, l_id_institution, i_prof_soft);
    
        IF pk_login.get_software_list(i_lang, i_prof, o_software, l_timestamp_str, l_offset, o_error)
        THEN
        
            FETCH o_software
                INTO l_soft_id, l_soft_desc, l_soft_icon;
        
            WHILE o_software%FOUND
                  AND l_can_end = '0'
            LOOP
                g_error := 'Init';
                alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
                g_error := 'Get barcode data';
                alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
            
                i_prof := NEW profissional(l_id_prof, l_id_institution, l_soft_id);
                -- Test statements here
                IF call_get_barcode_data(i_lang, i_prof, i_barcode, l_id_episode, l_id_patient, o_error)
                THEN
                
                    --             if o_result%rowcount > 0 then    
                
                    --           if l_result and o_result%isopen and o_result%rowcount > 0 then       
                
                    l_can_end := '1';
                
                    g_error := 'Get visit data';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => g_function);
                
                    l_id_visit := pk_episode.get_id_visit(l_id_episode);
                
                    g_error := 'Check if can show patient photo';
                    alertlog.pk_alertlog.log_info(text            => g_error,
                                                  object_name     => g_package,
                                                  sub_object_name => g_function);
                
                    IF pk_adt.show_patient_info(i_lang         => i_lang,
                                                i_patient      => l_id_patient,
                                                i_is_prof_resp => pk_patient.get_prof_resp(i_lang     => i_lang,
                                                                                           i_prof     => i_prof,
                                                                                           i_patient  => l_id_patient,
                                                                                           i_episode  => l_id_episode,
                                                                                           i_schedule => NULL))
                    THEN
                        g_error := 'Get patient photo blob';
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package,
                                                      sub_object_name => g_function);
                    
                        l_result := pk_patphoto.get_blob(l_id_patient, i_prof, l_pat_photo, o_error);
                    END IF;
                    IF NOT l_result
                       OR l_pat_photo IS NULL
                       OR dbms_lob.getlength(l_pat_photo) = 0
                    THEN
                        g_error := 'Patient photo not found getting silhouette';
                        alertlog.pk_alertlog.log_info(text            => g_error,
                                                      object_name     => g_package,
                                                      sub_object_name => g_function);
                        l_silhouette := pk_hea_prv_pat.get_value(i_lang,
                                                                 i_prof,
                                                                 NULL,
                                                                 l_id_patient,
                                                                 l_id_episode,
                                                                 NULL,
                                                                 NULL,
                                                                 'PAT_PHOTO');
                    END IF;
                END IF;
                FETCH o_software
                    INTO l_soft_id, l_soft_desc, l_soft_icon;
            END LOOP;
        END IF;
        l_pat_age := pk_patient.get_pat_age(i_lang, l_id_patient, i_prof);
        OPEN o_result FOR
            SELECT l_id_patient id_patient,
                   l_id_episode id_episode,
                   l_id_visit id_visit,
                   l_silhouette silhouette,
                   pk_patient.get_pat_name(i_lang, i_prof, l_id_patient, NULL) pat_name,
                   l_pat_age pat_age,
                   pk_patient.get_pat_gender(l_id_patient) pat_gender
              FROM dual;
        o_photo := l_pat_photo;
        --RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_result);
            --     RETURN FALSE;
    END get_gw_barcode_data2;

    /********************************************************************************************
     * Get patient data to ALERT Gateway from barcode
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_id_institution         Institution identifier
     * @param i_barcode                Barcode
     * @param o_result                 Patient data
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
    *
    * @author                Rui Teixeira
    * @version               2.6.3.8.3
    * @since                 2012/10/17
    ********************************************************************************************/
    PROCEDURE get_gw_barcode_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof_id        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_prof_soft      IN software.id_software%TYPE,
        i_barcode        IN episode.barcode%TYPE,
        o_result         OUT pk_types.cursor_type
    ) IS
        o_error t_error_out;
    
        l_id_episode     episode.id_episode%TYPE;
        l_id_patient     patient.id_patient%TYPE;
        l_id_visit       visit.id_visit%TYPE;
        l_pat_age        NUMBER(24, 12) := 0;
        l_pat_photo      VARCHAR2(255) := NULL;
        l_silhouette     VARCHAR2(200) := NULL;
        i_prof           profissional;
        l_patient_name   patient.name%TYPE;
        l_patient_gender patient.gender%TYPE;
    
    BEGIN
    
        g_function := 'get_cap_barcode_data';
    
        SELECT e.id_patient, e.id_episode, e.id_visit
          INTO l_id_patient, l_id_episode, l_id_visit
          FROM episode e
         WHERE barcode = i_barcode;
    
        SELECT p.name, p.gender, p.age
          INTO l_patient_name, l_patient_gender, l_pat_age
          FROM patient p
         WHERE id_patient = l_id_patient;
    
        OPEN o_result FOR
            SELECT l_id_patient     id_patient,
                   l_id_episode     id_episode,
                   l_id_visit       id_visit,
                   l_pat_photo      pat_photo,
                   l_silhouette     silhouette,
                   l_patient_name   pat_name,
                   l_pat_age        pat_age,
                   l_patient_gender pat_gender
              FROM dual;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_result);
    END get_gw_barcode_data;

    /***********************************************************************
                            HIDRICS
    ***********************************************************************/

    /********************************************************************************************
    * Get hidrics values between dates for a specific visit.
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_visit         Id visit
    * @param i_dt_begin         Start date for surgery time
    * @param i_dt_end           End date for surgery time
    *
    * @param o_hidrics_def    cursor with the intake and output fluids for the given period
    * @param o_hidrics_values   cursor with the values of the intakes and outputs for the given period
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author João Reis
    * @version 2.6.1.2
    * @since 2011-Jun-13
    ********************************************************************************************/
    FUNCTION get_hidrics_between_dates
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_visit       IN visit.id_visit%TYPE,
        i_dt_begin       IN VARCHAR2 DEFAULT NULL,
        i_dt_end         IN VARCHAR2 DEFAULT NULL,
        o_hidrics_def    OUT pk_types.cursor_type,
        o_hidrics_values OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        flg_scope VARCHAR2(1) := 'V';
    
    BEGIN
    
        g_function := 'get_hidrics_between_dates';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_inp_hidrics_pbl.get_epis_hidrics_pdms(i_lang          => i_lang,
                                                        i_prof          => i_prof,
                                                        i_flg_scope     => flg_scope,
                                                        i_scope         => i_id_visit,
                                                        i_start_date    => i_dt_begin,
                                                        i_end_date      => i_dt_end,
                                                        o_hidrics       => o_hidrics_def,
                                                        o_hidrics_value => o_hidrics_values,
                                                        o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_hidrics_between_dates;

    /********************************************************************************************
    * Get hidrics values.
    *
    * @param i_lang             Id language
    * @param i_par              Parent
    * @param i_flg_type         Hidrics flag type
    *
    * @param o_hidrics_val      Values of hidrics
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author Miguel Gomes
    * @version 2.6.3.9
    * @since 2013-AGO-29
    ********************************************************************************************/
    FUNCTION get_hidric_ways
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN way.flg_type%TYPE,
        o_hidric_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'get_hidrics';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_inp_hidrics_out.get_pdms_ways(i_lang, i_prof, i_flg_type, o_hidric_list, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_hidric_ways;

    /**********************************************************************************************
    * Gets all event types 
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_events                 Selected event types.
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.9
    * @since        2013-08-28
    **********************************************************************************************/
    FUNCTION get_pdms_event_type_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_events OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'get_pdms_event_type_list';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_timeline.get_pdms_task_list(i_lang, i_prof, 2, o_events, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pdms_event_type_list;

    /**********************************************************************************************
    * Gets hidrics detail (calls ux functions)
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        i_episode                  Episode identifier
    * @param        i_epis_hidrics             
    * @param        o_epis_hid  
    * @param        o_error                    Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-04
    **********************************************************************************************/
    FUNCTION get_hidrics_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_hidrics_det IN epis_hidrics_det.id_epis_hidrics_det%TYPE,
        i_flg_screen       IN VARCHAR2,
        o_hist             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_function := 'get_hidrics_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_inp_hidrics_ux.get_epis_hidrics_res_hist(i_lang,
                                                           i_prof,
                                                           i_epis_hidrics_det,
                                                           i_flg_screen,
                                                           o_hist,
                                                           o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_hidrics_detail;

    /**********************************************************************************************
    * Gets positioning detail (calls ux functions)
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        i_id_episode               Episode identifier
    * @param        i_id_epis_positioning      
    * @param        i_flg_screen  
    * @param        o_hist                     Historico
    * @param        o_error                    Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-04
    **********************************************************************************************/
    FUNCTION get_positioning_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_screen          IN VARCHAR2,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_function := 'get_positioning_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_inp_positioning.get_epis_positioning_hist(i_lang,
                                                            i_prof,
                                                            i_id_episode,
                                                            i_id_epis_positioning,
                                                            i_flg_screen,
                                                            o_hist,
                                                            o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_positioning_detail;

    /**********************************************************************************************
    * Gets severity score detail (calls ux functions)
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        i_id_episode               Episode identifier
    * @param        o_reg                      
    * @param        o_value                    
    * @param        o_cancel
    * @param        o_error                    Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-04
    **********************************************************************************************/
    FUNCTION get_sev_score_detail
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_mtos_score IN epis_mtos_score.id_epis_mtos_score%TYPE,
        o_reg             OUT pk_types.cursor_type,
        o_value           OUT pk_types.cursor_type,
        o_cancel          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_function := 'get_sev_score_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_sev_scores_api_ui.get_sev_score_detail(i_lang,
                                                         i_prof,
                                                         i_id_episode,
                                                         i_epis_mtos_score,
                                                         o_reg,
                                                         o_value,
                                                         o_cancel,
                                                         o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_sev_score_detail;

    /**********************************************************************************************
    * Gets transport (calls ux functions)
    *
    * @param        i_lang                     Language id
    * @param        i_prof                     Professional, software and institution ids
    * @param        i_movement                 Transport identifier
    * @param        o_mov
    * @param        o_error                    Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Rui Teixeira
    * @version      2.6.3.8.4
    * @since        2013-11-04
    **********************************************************************************************/
    FUNCTION get_transport_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_movement IN movement.id_movement%TYPE,
        o_mov      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_function := 'get_transport_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_movement.get_mov_info(i_lang, i_movement, i_prof, o_mov, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_transport_detail;

    /***********************************************************************
                            Patient Location functions
    ***********************************************************************/

    /**********************************************************************************************
    *
    * GET_DEPARTMENTS          Function that returns all departments for the current professional institution
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  O_DEPS           Department information cursor
    * @param  O_ERROR          If an error occurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Miguel Gomes
    * @version 2.6.3.9
    * @since   07-Jan-2014
    *
    **********************************************************************************************/
    FUNCTION get_departments
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_deps  OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'get_departments';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_bmng_pbl.get_departments(i_lang => i_lang, i_prof => i_prof, o_deps => o_deps, o_error => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_departments;

    /**********************************************************************************************
    *
    * GET_ROOMS                Function that returns all rooms for the specified department
    *
    * @param  I_LANG                    Language associated to the professional executing the request
    * @param  I_PROF                    Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_DEPARTMENT              Department ID
    * @param  I_FLG_TYPE                Bed type
    * @param  I_SHOW_OCCUPIED_BEDS      Number of beds show in current rooms should count with occupied beds ('Y' - Yes; 'N' - No)
    * @param  O_ROOMS                   Rooms information cursor
    * @param  O_ERROR                   If an error occurs, this parameter will have information about the error
    *
    * @value  I_FLG_TYPE                NULL - ALL TYPES; P - Permanent beds; T - Temporary beds
    *
    * @return                           Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Miguel Gomes
    * @version 2.6.3.9
    * @since   07-Jan-2014
    *
    **********************************************************************************************/
    FUNCTION get_rooms
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_department         IN department.id_department%TYPE,
        i_flg_type           IN bed.flg_type%TYPE,
        i_show_occupied_beds IN VARCHAR2,
        o_rooms              OUT NOCOPY pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'get_rooms';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_bmng_ux.get_rooms(i_lang               => i_lang,
                                    i_prof               => i_prof,
                                    i_department         => i_department,
                                    i_flg_type           => i_flg_type,
                                    i_show_occupied_beds => i_show_occupied_beds,
                                    o_rooms              => o_rooms,
                                    o_error              => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rooms;
    /**********************************************************************************************
    *
    * GET_BEDS                 Function that returns all beds for the specified room
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ROOM           Room ID
    * @param  I_FLG_TYPE       Bed type
    * @param  O_BEDS           Beds information cursor
    * @param  O_ERROR          If an error occurs, this parameter will have information about the error
    *
    * @value  I_FLG_TYPE       NULL - ALL TYPES; P - Permanent beds; T - Temporary beds
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    *
    * @author  Miguel Gomes
    * @version 2.6.3.9
    * @since   07-Jan-2014
    *
    **********************************************************************************************/
    FUNCTION get_beds
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_room     IN room.id_room%TYPE,
        i_flg_type IN bed.flg_type%TYPE,
        o_beds     OUT NOCOPY pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'get_beds';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_bmng_ux.get_beds(i_lang     => i_lang,
                                   i_prof     => i_prof,
                                   i_room     => i_room,
                                   i_flg_type => i_flg_type,
                                   o_beds     => o_beds,
                                   o_error    => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_beds;

    /***************************************************************************************************************
    *
    * Returns the data of the bed allocations associated with the provided episode.
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional
    * @param      i_episode           ID_EPISODE to check
    * @param      o_result            Y/N : Yes for existing bed allocations, no for no available bed allocations
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Miguel Gomes
    * @version 2.6.3.9
    * @since   13-Fev-2014
    *
    ****************************************************************************************************/
    FUNCTION get_epis_bed_allocation
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_result  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'get_beds';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_bmng_ux.get_epis_bed_allocation(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  i_episode => i_episode,
                                                  o_result  => o_result,
                                                  
                                                  o_error => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_epis_bed_allocation;

    /***************************************************************************************************************
    *
    * Returns patient information by bed identifier.
    *
    *
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional
    * @param      i_bed               bed identifier
    * @param      o_result            Y/N : Yes for existing bed associated to a patient, no for any bed associated
    * @param      o_error            If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN  TRUE or FALSE
    * @author  Miguel Gomes
    * @version 2.6.3.9
    * @since   14-Fev-2014
    *
    ****************************************************************************************************/
    FUNCTION get_patient_by_bed
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_bed    IN bed.id_bed%TYPE,
        o_result OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        p_barcode episode.barcode%TYPE;
    BEGIN
        g_function := 'get_bed';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        SELECT e.barcode
          INTO p_barcode
          FROM episode e
         WHERE id_episode = (SELECT ei.id_episode
                               FROM bed b
                               JOIN epis_info ei
                                 ON b.id_bed = ei.id_bed
                              WHERE b.id_bed = i_bed);
    
        get_gw_barcode_data(i_lang           => i_lang,
                            i_prof_id        => i_prof.id,
                            i_id_institution => i_prof.institution,
                            i_prof_soft      => i_prof.software,
                            i_barcode        => p_barcode,
                            o_result         => o_result);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_patient_by_bed;

    PROCEDURE vital_signs__________________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    FUNCTION get_pdms_module_vital_signs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_flg_view IN vs_soft_inst.flg_view%TYPE,
        i_tb_vs    IN table_number DEFAULT NULL,
        i_tb_view  IN table_varchar DEFAULT NULL,
        o_vs       OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        c_function_name CONSTANT VARCHAR2(30) := 'GET_PDMS_MODULE_VITAL_SIGNS';
        l_um pk_types.cursor_type;
    
    BEGIN
    
        g_error := 'call pk_vital_sign_core.get_pdms_module_vital_sign';
        IF NOT pk_vital_sign_core.get_pdms_module_vital_signs(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_patient => i_patient,
                                                              i_tb_vs   => i_tb_vs,
                                                              i_tb_view => i_tb_view,
                                                              o_vs      => o_vs,
                                                              o_um      => l_um,
                                                              o_error   => o_error)
        THEN
            RAISE g_exception;
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
                                              c_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_vs);
            pk_types.open_my_cursor(l_um);
            RETURN FALSE;
    END get_pdms_module_vital_signs;

    FUNCTION get_vs_between_dates
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_visit  IN visit.id_visit%TYPE,
        i_id_vs     IN table_number DEFAULT NULL,
        i_dt_begin  IN VARCHAR2 DEFAULT NULL,
        i_dt_end    IN VARCHAR2 DEFAULT NULL,
        o_vs        OUT pk_types.cursor_type,
        o_vs_parent OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
    
    BEGIN
    
        g_function := 'get_vs_between_dates';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        l_result := pk_api_vital_sign_pdms.get_visit_vital_signs(i_lang,
                                                                 i_prof,
                                                                 i_id_visit,
                                                                 i_id_vs,
                                                                 i_dt_begin,
                                                                 i_dt_end,
                                                                 'M',
                                                                 o_vs,
                                                                 o_error);
        IF l_result
        THEN
            l_result := pk_api_vital_sign_pdms.get_vital_signs_bp_parents(i_lang, i_prof, i_id_vs, o_vs_parent, o_error);
        ELSE
            pk_types.open_my_cursor(o_vs_parent);
        END IF;
        RETURN l_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_vs);
            pk_types.open_my_cursor(o_vs_parent);
            RETURN FALSE;
    END get_vs_between_dates;

    FUNCTION set_vital_signs
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN vital_sign_read.id_episode%TYPE,
        i_id_vs          IN table_number,
        i_value_vs       IN table_number,
        i_id_um          IN table_number,
        i_dt_vs          IN table_varchar,
        i_id_scales      IN table_number,
        i_insert         IN VARCHAR,
        i_tbtb_attribute IN table_table_number,
        i_tbtb_free_text IN table_table_clob,
        o_id_vsr         OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_desc   table_number;
        l_value_vs  table_number;
        l_um        table_number;
        l_count     NUMBER;
        l_id_scales table_number;
        l_type      vital_sign.flg_fill_type%TYPE;
    
    BEGIN
    
        l_id_scales := table_number();
        l_id_desc   := table_number();
        l_um        := table_number();
    
        l_count := i_id_scales.count;
        FOR i IN 1 .. l_count
        LOOP
            l_id_scales.extend();
            IF i_id_scales(i) = 0
            THEN
                l_id_scales(i) := NULL;
            ELSE
                l_id_scales(i) := i_id_scales(i);
            END IF;
        END LOOP;
    
        l_count := i_id_um.count;
        FOR i IN 1 .. l_count
        LOOP
            l_um.extend();
            IF i_id_um(i) = 0
            THEN
                l_um(i) := NULL;
            ELSE
                l_um(i) := i_id_um(i);
            END IF;
        END LOOP;
    
        SELECT pk_api_vital_sign_pdms.get_vs_type(i_lang, i_prof, i_id_vs(1))
          INTO l_type
          FROM dual;
    
        IF l_type = pk_alert_constant.g_vs_ft_multichoice
        THEN
            l_id_desc  := i_value_vs;
            l_value_vs := table_number();
            l_value_vs.extend(i_id_vs.count);
        ELSE
            l_value_vs := i_value_vs;
            l_id_desc  := table_number();
            l_id_desc.extend(i_id_vs.count);
        END IF;
    
        g_function := 'set_vital_signs';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_vital_sign_pdms.set_episode_vital_signs(i_lang           => i_lang,
                                                              i_prof           => i_prof,
                                                              i_episode        => i_episode,
                                                              i_id_vs          => i_id_vs,
                                                              i_value_vs       => l_value_vs,
                                                              i_id_um          => l_um,
                                                              i_multichoice_vs => l_id_desc,
                                                              i_scales_elem_vs => l_id_scales,
                                                              i_dt_vs          => i_dt_vs,
                                                              i_validate_rep   => i_insert,
                                                              i_tbtb_attribute => i_tbtb_attribute,
                                                              i_tbtb_free_text => i_tbtb_free_text,
                                                              o_id_vsr         => o_id_vsr,
                                                              o_error          => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_vital_signs;

    FUNCTION get_vs_read_attributes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign      IN vital_sign.id_vital_sign%TYPE,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        o_vs_attributes      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_vital_sign_pdms.get_vs_read_attributes(i_lang               => i_lang,
                                                             i_prof               => i_prof,
                                                             i_id_vital_sign      => i_id_vital_sign,
                                                             i_id_vital_sign_read => i_id_vital_sign_read,
                                                             o_vs_attributes      => o_vs_attributes,
                                                             o_error              => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vs_read_attributes;

    FUNCTION edit_vital_signs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN table_number,
        i_value              IN table_number,
        i_id_unit_measure    IN table_number,
        i_dt_vital_sign_read IN VARCHAR2,
        i_tbtb_attribute     IN table_table_number,
        i_tbtb_free_text     IN table_table_clob,
        o_id_vsr             OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        RETURN pk_api_vital_sign_pdms.edit_vital_signs(i_lang                    => i_lang,
                                                       i_prof                    => i_prof,
                                                       i_id_vital_sign_read      => i_id_vital_sign_read,
                                                       i_value                   => i_value,
                                                       i_id_unit_measure         => i_id_unit_measure,
                                                       i_dt_vital_sign_read_tstz => i_dt_vital_sign_read,
                                                       i_tbtb_attribute          => i_tbtb_attribute,
                                                       i_tbtb_free_text          => i_tbtb_free_text,
                                                       o_id_vsr                  => o_id_vsr,
                                                       o_error                   => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END edit_vital_signs;

    FUNCTION cancel_vital_signs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE DEFAULT pk_cancel_reason.c_reason_other,
        i_notes           IN vital_sign_read.notes_cancel%TYPE DEFAULT NULL,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_vital_sign_read table_number;
    
    BEGIN
    
        g_function := 'cancel_vital_signs';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        l_vital_sign_read := table_number(i_vital_sign_read);
    
        RETURN pk_api_vital_sign_pdms.cancel_vital_signs(i_lang,
                                                         i_prof,
                                                         l_vital_sign_read,
                                                         i_cancel_reason,
                                                         i_notes,
                                                         o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_vital_signs;

    FUNCTION get_pdms_module_vs_by_ids
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_vs_ids  IN table_number,
        o_vital_s OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'get_pdms_module_vs_by_ids';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_vital_sign_pdms.get_pdms_module_vs_by_ids(i_lang,
                                                                i_prof,
                                                                i_patient,
                                                                i_vs_ids,
                                                                o_vital_s,
                                                                o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pdms_module_vs_by_ids;

    FUNCTION get_vs_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_id_vs   IN vital_sign_desc.id_vital_sign%TYPE,
        o_vs      OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        i_gender patient.gender%TYPE;
        i_age    patient.age%TYPE;
    
    BEGIN
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_vital_sign_pdms.get_vs_options(i_lang, i_prof, i_patient, i_id_vs, o_vs, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vs_options;

    FUNCTION get_all_vital_signs_views
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_vital_s OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'get_pdms_module_vital_signs';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_vital_sign_pdms.get_all_pdms_views(i_lang, i_prof, o_vital_s, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_all_vital_signs_views;

    FUNCTION get_pdms_vital_sign_to_reg
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_vital_signs IN table_table_number,
        o_selected    OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'get_pdms_vital_sign_to_reg';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_vital_sign_pdms.get_pdms_vital_sign_to_reg(i_lang,
                                                                 i_prof,
                                                                 i_patient,
                                                                 i_vital_signs,
                                                                 o_selected,
                                                                 o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pdms_vital_sign_to_reg;

    FUNCTION get_vs_attribute
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_vital_sign IN vital_sign_read.id_vital_sign_read%TYPE,
        o_vs_attribute  OUT pk_types.cursor_type,
        o_vs_options    OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'get_med_task_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_vital_sign_pdms.get_vs_attribute(i_lang,
                                                       i_prof,
                                                       i_id_vital_sign,
                                                       o_vs_attribute,
                                                       o_vs_options,
                                                       o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vs_attribute;

    FUNCTION get_vs_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_vital_sign_read IN vital_sign_read.id_vital_sign_read%TYPE,
        i_detail_type        IN VARCHAR2,
        o_hist               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'get_vs_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_vital_sign_pdms.get_vs_detail(i_lang,
                                                    i_prof,
                                                    i_id_vital_sign_read,
                                                    i_detail_type,
                                                    o_hist,
                                                    o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_vs_detail;

    PROCEDURE lab_tests___________________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    FUNCTION cancel_lab_test
    (
        i_lang             IN language.id_language%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_prof             IN profissional,
        i_notes            IN analysis_req_det.notes_cancel%TYPE,
        i_cancel_reason    IN analysis_req_det.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'cancel_lab_test';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_lab_tests_external_api_db.cancel_lab_test_task(i_lang         => i_lang,
                                                                 i_prof         => i_prof,
                                                                 i_task_request => i_analysis_req_det,
                                                                 i_reason       => i_cancel_reason,
                                                                 i_reason_notes => i_notes,
                                                                 i_prof_order   => NULL,
                                                                 i_dt_order     => NULL,
                                                                 i_order_type   => NULL,
                                                                 o_error        => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_lab_test;

    FUNCTION get_lab_test_results
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_visit            IN visit.id_visit%TYPE,
        i_analysis_req_det IN table_number,
        i_flg_type         IN VARCHAR2,
        i_dt_min           IN VARCHAR2,
        i_dt_max           IN VARCHAR2,
        o_result_gridview  OUT pk_types.cursor_type,
        o_result_graphview OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'get_lab_test_results';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_lab_tests_external_api_db.get_lab_test_pdmsview(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_patient          => i_patient,
                                                                  i_visit            => i_visit,
                                                                  i_analysis_req_det => i_analysis_req_det,
                                                                  i_flg_type         => i_flg_type,
                                                                  i_dt_min           => i_dt_min,
                                                                  i_dt_max           => i_dt_max,
                                                                  o_result_gridview  => o_result_gridview,
                                                                  o_result_graphview => o_result_graphview,
                                                                  o_error            => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_lab_test_results;

    FUNCTION get_lab_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_episode                     IN episode.id_episode%TYPE,
        i_analysis_req_det            IN analysis_req_det.id_analysis_req_det%TYPE,
        i_detail_type                 IN VARCHAR2,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_co_sign            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_result             OUT pk_types.cursor_type,
        o_lab_test_doc                OUT pk_types.cursor_type,
        o_lab_test_review             OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'get_lab_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        IF (i_detail_type = 'D')
        THEN
            RETURN pk_lab_tests_api_ux.get_lab_test_detail(i_lang,
                                                           i_prof,
                                                           i_episode,
                                                           i_analysis_req_det,
                                                           o_lab_test_order,
                                                           o_lab_test_co_sign,
                                                           o_lab_test_clinical_questions,
                                                           o_lab_test_harvest,
                                                           o_lab_test_result,
                                                           o_lab_test_doc,
                                                           o_lab_test_review,
                                                           o_error);
        
        ELSE
            RETURN pk_lab_tests_api_ux.get_lab_test_detail_history(i_lang,
                                                                   i_prof,
                                                                   i_episode,
                                                                   i_analysis_req_det,
                                                                   o_lab_test_order,
                                                                   o_lab_test_co_sign,
                                                                   o_lab_test_clinical_questions,
                                                                   o_lab_test_harvest,
                                                                   o_lab_test_result,
                                                                   o_lab_test_doc,
                                                                   o_lab_test_review,
                                                                   o_error);
        
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
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_lab_detail;

    FUNCTION get_lab_harvest_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        i_detail_type                 IN VARCHAR2,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'get_lab_harvest_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        IF (i_detail_type = 'D')
        THEN
            RETURN pk_lab_tests_api_ux.get_harvest_detail(i_lang                        => i_lang,
                                                          i_prof                        => i_prof,
                                                          i_harvest                     => i_harvest,
                                                          o_lab_test_harvest            => o_lab_test_harvest,
                                                          o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                          o_error                       => o_error);
        
        ELSE
            RETURN pk_lab_tests_api_ux.get_harvest_detail_history(i_lang                        => i_lang,
                                                                  i_prof                        => i_prof,
                                                                  i_harvest                     => i_harvest,
                                                                  o_lab_test_harvest            => o_lab_test_harvest,
                                                                  o_lab_test_clinical_questions => o_lab_test_clinical_questions,
                                                                  o_error                       => o_error);
        
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
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_lab_harvest_detail;

    FUNCTION get_lab_result_detail
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_analysis_result_par        IN table_number,
        o_lab_test_result            OUT pk_types.cursor_type,
        o_lab_test_result_laboratory OUT pk_types.cursor_type,
        o_lab_test_result_history    OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'get_lab_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_lab_tests_api_ux.get_lab_test_result(i_lang,
                                                       i_prof,
                                                       i_analysis_result_par,
                                                       o_lab_test_result,
                                                       o_lab_test_result_laboratory,
                                                       o_lab_test_result_history,
                                                       o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_lab_result_detail;

    FUNCTION get_lab_tests_by_type
    (
        i_type            IN VARCHAR2,
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_exam_cat        IN exam_cat.id_exam_cat%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        i_analysis_group  IN analysis_group.id_analysis_group%TYPE,
        o_cursor          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ret           BOOLEAN;
        o_list          t_tbl_lab_tests_cat_search;
        o_selectionlist t_tbl_lab_tests_for_selection;
    
    BEGIN
        g_function := 'get_lab_tests_by_type';
        g_error    := 'Init';
    
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        IF (i_type = 'labTestElementCategory1' OR i_type = 'labTestElementCategory2' OR
           i_type = 'labTestElementSample2' OR i_type = 'labTestElementSample3')
        THEN
            l_ret := pk_lab_tests_api_db.get_lab_test_category_search(i_lang,
                                                                      i_prof,
                                                                      i_patient,
                                                                      i_sample_type,
                                                                      i_exam_cat_parent,
                                                                      i_codification,
                                                                      o_list,
                                                                      o_error);
            OPEN o_cursor FOR
                SELECT id_exam_cat, desc_category
                  FROM TABLE(o_list);
        ELSE
        
            IF (i_type = 'labTestElementGroup1')
            THEN
                l_ret := pk_lab_tests_api_db.get_lab_test_group_search(i_lang, i_prof, i_patient, o_cursor, o_error);
            ELSE
                IF (i_type = 'labTestElementCategory3' OR i_type = 'labTestElementSample1')
                THEN
                    l_ret := pk_lab_tests_api_db.get_lab_test_sample_search(i_lang,
                                                                            i_prof,
                                                                            i_patient,
                                                                            i_exam_cat,
                                                                            i_codification,
                                                                            o_cursor,
                                                                            o_error);
                
                ELSE
                    IF (i_type = 'labTestElementCategory4' OR i_type = 'labTestElementSample4')
                    THEN
                    
                        l_ret := pk_lab_tests_api_db.get_lab_test_for_selection(i_lang,
                                                                                i_prof,
                                                                                i_patient,
                                                                                i_sample_type,
                                                                                i_exam_cat,
                                                                                i_exam_cat_parent,
                                                                                i_codification,
                                                                                o_selectionlist,
                                                                                o_error);
                    
                        OPEN o_cursor FOR
                            SELECT id_analysis, desc_analysis
                              FROM TABLE(o_selectionlist);
                    ELSE
                        IF (i_type = 'labTestElementGroup2')
                        THEN
                            l_ret := pk_lab_tests_api_db.get_lab_test_in_group(i_lang,
                                                                               i_prof,
                                                                               i_patient,
                                                                               i_analysis_group,
                                                                               i_codification,
                                                                               o_cursor,
                                                                               o_error);
                        ELSE
                            l_ret := FALSE;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_lab_tests_by_type;

    FUNCTION get_category_lab_tests
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_sample_type     IN analysis.id_sample_type%TYPE,
        i_exam_cat_parent IN exam_cat.parent_id%TYPE,
        i_codification    IN codification.id_codification%TYPE,
        o_cursor          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        retorno BOOLEAN;
        o_list  t_tbl_lab_tests_cat_search;
    
    BEGIN
    
        g_function := 'get_category_lab_tests';
        g_error    := 'Init';
    
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        retorno := pk_lab_tests_api_db.get_lab_test_category_search(i_lang,
                                                                    i_prof,
                                                                    i_patient,
                                                                    i_sample_type,
                                                                    i_exam_cat_parent,
                                                                    i_codification,
                                                                    o_list,
                                                                    o_error);
        OPEN o_cursor FOR
            SELECT id_exam_cat, desc_category
              FROM TABLE(o_list);
    
        RETURN retorno;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_category_lab_tests;

    FUNCTION get_sample_lab_tests
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_exam_cat     IN exam_cat.id_exam_cat%TYPE,
        i_codification IN codification.id_codification%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'get_sample_lab_tests';
        g_error    := 'Init';
    
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_lab_tests_api_db.get_lab_test_sample_search(i_lang,
                                                              i_prof,
                                                              i_patient,
                                                              i_exam_cat,
                                                              i_codification,
                                                              o_list,
                                                              o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_sample_lab_tests;

    FUNCTION get_group_lab_tests
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'get_group_lab_tests';
        g_error    := 'Init';
    
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_lab_tests_api_db.get_lab_test_group_search(i_lang, i_prof, i_patient, o_list, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_group_lab_tests;

    FUNCTION get_lab_test_order_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN harvest.id_harvest%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'get_lab_test_order_list';
        g_error    := 'Init';
    
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        /* TODO:check permissions */
        RETURN TRUE; --pk_lab_tests_core.get_lab_test_order_list(i_lang, i_prof, i_harvest, o_list, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_lab_test_order_list;

    PROCEDURE exams_____________________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    FUNCTION cancel_exams
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_exam_req_det  IN table_number,
        i_cancel_reason IN table_number,
        i_notes_cancel  IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'cancel_exams';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_exams_api_db.cancel_exam_request(i_lang           => i_lang,
                                                   i_prof           => i_prof,
                                                   i_exam_req_det   => i_exam_req_det,
                                                   i_dt_cancel      => NULL,
                                                   i_cancel_reason  => i_cancel_reason(1),
                                                   i_cancel_notes   => i_notes_cancel(1),
                                                   i_prof_order     => NULL,
                                                   i_dt_order       => NULL,
                                                   i_order_type     => NULL,
                                                   i_transaction_id => NULL,
                                                   o_error          => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_exams;

    FUNCTION get_exams_detail
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_episode                 IN episode.id_episode%TYPE,
        i_detail_type             IN VARCHAR2,
        i_exam_req_det            IN exam_req_det.id_exam_req_det%TYPE,
        o_exam_order              OUT pk_types.cursor_type,
        o_exam_co_sign            OUT pk_types.cursor_type,
        o_exam_clinical_questions OUT pk_types.cursor_type,
        o_exam_perform            OUT pk_types.cursor_type,
        o_exam_result             OUT pk_types.cursor_type,
        o_exam_result_images      OUT pk_types.cursor_type,
        o_exam_doc                OUT pk_types.cursor_type,
        o_exam_review             OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'get_exams_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        IF (i_detail_type = 'D')
        THEN
        
            RETURN pk_exam_external.get_exam_detail(i_lang                    => i_lang,
                                                    i_prof                    => i_prof,
                                                    i_episode                 => i_episode,
                                                    i_exam_req_det            => i_exam_req_det,
                                                    o_exam_order              => o_exam_order,
                                                    o_exam_co_sign            => o_exam_co_sign,
                                                    o_exam_clinical_questions => o_exam_clinical_questions,
                                                    o_exam_perform            => o_exam_perform,
                                                    o_exam_result             => o_exam_result,
                                                    o_exam_result_images      => o_exam_result_images,
                                                    o_exam_doc                => o_exam_doc,
                                                    o_exam_review             => o_exam_review,
                                                    o_error                   => o_error);
        ELSE
            RETURN pk_exam_external.get_exam_detail_history(i_lang                    => i_lang,
                                                            i_prof                    => i_prof,
                                                            i_episode                 => i_episode,
                                                            i_exam_req_det            => i_exam_req_det,
                                                            o_exam_order              => o_exam_order,
                                                            o_exam_co_sign            => o_exam_co_sign,
                                                            o_exam_clinical_questions => o_exam_clinical_questions,
                                                            o_exam_perform            => o_exam_perform,
                                                            o_exam_result             => o_exam_result,
                                                            o_exam_result_images      => o_exam_result_images,
                                                            o_exam_doc                => o_exam_doc,
                                                            o_exam_review             => o_exam_review,
                                                            o_error                   => o_error);
        
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_exams_detail;

    PROCEDURE procedures_________________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    FUNCTION cancel_interv_presc_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        i_dt_cancel_str    IN VARCHAR2,
        i_notes_cancel     IN interv_presc_det.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'cancel_procedure_request';
        g_error    := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_procedures_api_db.cancel_procedure_request(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_interv_presc_det => table_number(i_interv_presc_det),
                                                             i_dt_cancel        => i_dt_cancel_str,
                                                             i_cancel_reason    => i_id_cancel_reason,
                                                             i_cancel_notes     => i_notes_cancel,
                                                             i_prof_order       => NULL,
                                                             i_dt_order         => NULL,
                                                             i_order_type       => NULL,
                                                             o_error            => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_interv_presc_det;

    FUNCTION cancel_interv_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        i_dt_plan           IN VARCHAR2,
        i_notes             IN epis_interv.notes%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'cancel_procedure_execution';
        g_error    := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_procedures_api_db.cancel_procedure_execution(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_interv_presc_plan => i_interv_presc_plan,
                                                               i_dt_plan           => i_dt_plan,
                                                               i_cancel_reason     => i_id_cancel_reason,
                                                               i_cancel_notes      => i_notes,
                                                               o_error             => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_interv_plan;

    FUNCTION get_aux_cancel_take
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_interv_presc_plan IN interv_presc_plan.id_interv_presc_plan%TYPE,
        o_interv            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'get_aux_cancel_take';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_procedures_core.get_procedure_to_cancel(i_lang, i_prof, i_interv_presc_plan, o_interv, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_aux_cancel_take;

    FUNCTION get_interv_detail
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_interv_presc_det          IN interv_presc_det.id_interv_presc_det%TYPE,
        o_interv_order              OUT pk_types.cursor_type,
        o_interv_co_sign            OUT pk_types.cursor_type,
        o_interv_clinical_questions OUT pk_types.cursor_type,
        o_interv_execution          OUT pk_types.cursor_type,
        o_interv_execution_images   OUT pk_types.cursor_type,
        o_interv_doc                OUT pk_types.cursor_type,
        o_interv_review             OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'get_interv_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_procedures_api_db.get_procedure_detail(i_lang                      => i_lang,
                                                         i_prof                      => i_prof,
                                                         i_episode                   => i_episode,
                                                         i_interv_presc_det          => i_interv_presc_det,
                                                         o_interv_order              => o_interv_order,
                                                         o_interv_co_sign            => o_interv_co_sign,
                                                         o_interv_clinical_questions => o_interv_clinical_questions,
                                                         o_interv_execution          => o_interv_execution,
                                                         o_interv_execution_images   => o_interv_execution_images,
                                                         o_interv_doc                => o_interv_doc,
                                                         o_interv_review             => o_interv_review,
                                                         o_error                     => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_interv_detail;

    FUNCTION cancel_nurse_activity
    (
        i_lang             IN language.id_language%TYPE,
        i_req_det          IN nurse_activity_req.id_nurse_activity_req%TYPE,
        i_prof             IN profissional,
        i_notes            IN nurse_activity_req.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'cancel_nurse_activity';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    FUNCTION cancel_wound_treat
    (
        i_lang             IN language.id_language%TYPE,
        i_wtreat           IN wound_treat.id_wound_treatment%TYPE,
        i_prof             IN profissional,
        i_notes            IN nurse_activity_req.notes_cancel%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_dt_next_str      IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'cancel_wound_treat';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END;

    FUNCTION get_aux_cancel_treat
    (
        i_lang           IN language.id_language%TYPE,
        i_id_wound_treat IN wound_treat.id_wound_treatment%TYPE,
        i_prof           IN profissional,
        o_treat          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'get_aux_cancel_treat';
    
        pk_types.open_my_cursor(o_treat);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_aux_cancel_treat;

    FUNCTION get_dressing_detail
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_epis   IN nurse_activity_req.id_episode%TYPE,
        i_req    IN nurse_actv_req_det.id_nurse_actv_req_det%TYPE,
        o_nactiv OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'get_dressing_detail';
    
        pk_types.open_my_cursor(o_nactiv);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_dressing_detail;

    PROCEDURE medication_________________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    FUNCTION get_med_actions
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN presc.id_patient%TYPE,
        i_id_episode         IN presc.id_epis_create%TYPE,
        i_id_presc           IN table_number,
        i_id_presc_plan      IN table_number,
        i_id_presc_plan_task IN table_number,
        i_id_print_group     IN table_number,
        i_flg_action_type    IN VARCHAR2,
        o_action             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_params VARCHAR2(1000 CHAR);
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'get_med_actions';
    
    BEGIN
    
        l_params := 'i_lang= ' || i_lang || ' i_prof=' || pk_utils.to_string(i_prof) || ' i_id_patient = ' ||
                    i_id_patient || ' i_id_episode=' || i_id_episode || ' i_id_presc=' ||
                    pk_utils.to_string(i_id_presc) || ' i_id_presc_plan=' || pk_utils.to_string(i_id_presc_plan) ||
                    ' i_id_presc_plan_task=' || pk_utils.to_string(i_id_presc_plan_task) || ' i_id_print_group=' ||
                    pk_utils.to_string(i_id_print_group) || ' i_flg_action_type=' || i_flg_action_type;
    
        -- init
        g_error := 'Init priv' || l_func_name || ' / ' || l_params;
    
        IF g_debug
        THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        END IF;
    
        RETURN pk_api_pfh_in.get_med_tab_actions(i_lang                 => i_lang,
                                                 i_prof                 => i_prof,
                                                 i_id_patient           => i_id_patient,
                                                 i_id_episode           => i_id_episode,
                                                 i_id_presc             => i_id_presc,
                                                 i_id_presc_plan        => i_id_presc_plan,
                                                 i_id_presc_plan_task   => i_id_presc_plan_task,
                                                 i_id_print_group       => i_id_print_group,
                                                 i_id_editor_tab        => 10,
                                                 i_class_origin_context => 'MEDICATION',
                                                 i_flg_ignore_inactive  => 'N',
                                                 i_flg_action_type      => i_flg_action_type,
                                                 o_action               => o_action,
                                                 o_error                => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_med_actions;

    FUNCTION get_med_between_dates
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_dt_begin     IN VARCHAR2 DEFAULT NULL,
        i_dt_end       IN VARCHAR2 DEFAULT NULL,
        i_filter_types IN table_number,
        i_filter_items IN table_number,
        o_presc_info   OUT pk_types.cursor_type,
        o_drug_info    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        e_internal_exception EXCEPTION;
    
    BEGIN
    
        g_function := 'get_med_between_dates';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL);
    
        g_error := 'Getting data';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Getting administrations';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_pfh_in.get_task_list_by_patient(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_id_patient => i_patient,
                                                      i_first_date => l_dt_begin,
                                                      i_last_date  => l_dt_end,
                                                      o_presc      => o_presc_info,
                                                      o_tasks      => o_drug_info,
                                                      o_error      => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_med_between_dates;

    FUNCTION get_med_freq_units
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_duration_units OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_function := 'get_med_freq_units';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_pfh_in.get_editor_lookup(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_editor_lookup    => pk_api_pfh_in.el_duration_smaller_month_unit,
                                               i_id_product          => NULL,
                                               i_id_product_supplier => NULL,
                                               o_info                => o_duration_units,
                                               o_error               => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_med_freq_units;

    FUNCTION hold_med_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN table_number,
        i_dt_hold_begin    IN VARCHAR2,
        i_dt_hold_end      IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_result BOOLEAN;
    
    BEGIN
    
        g_function := 'hold_med_presc';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        FOR i IN 1 .. i_id_presc.count
        LOOP
        
            l_result := pk_api_pfh_in.set_suspend_presc(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_presc         => i_id_presc(i),
                                                        i_dt_begin_suspend => i_dt_hold_begin,
                                                        i_dt_end_suspend   => i_dt_hold_end,
                                                        i_id_reason        => i_id_cancel_reason,
                                                        i_reason           => i_cancel_reason,
                                                        i_notes            => i_notes,
                                                        o_error            => o_error);
        
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END hold_med_presc;

    FUNCTION hold_med_adm
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN drug_presc_det.id_drug_presc_det%TYPE,
        i_id_presc_plan    IN drug_presc_plan.id_drug_presc_plan%TYPE,
        i_dt_suspend       IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_result BOOLEAN;
    BEGIN
    
        g_function := 'hold_med_presc';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        l_result := pk_api_pfh_in.set_suspend_adm(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_id_presc      => i_id_presc,
                                                  i_id_presc_plan => i_id_presc_plan,
                                                  i_id_reason     => i_id_cancel_reason,
                                                  i_reason        => i_cancel_reason,
                                                  i_notes         => i_notes,
                                                  i_dt_suspend    => i_dt_suspend,
                                                  o_error         => o_error);
    
        RETURN l_result;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END hold_med_adm;

    FUNCTION resume_med_presc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_presc        IN drug_presc_det.id_drug_presc_det%TYPE,
        i_dt_resume_begin IN VARCHAR2,
        i_notes           IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_function := 'resume_med_presc';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_pfh_in.set_resume_presc(i_lang            => i_lang,
                                              i_prof            => i_prof,
                                              i_id_presc        => i_id_presc,
                                              i_dt_begin_resume => i_dt_resume_begin,
                                              i_id_reason       => NULL,
                                              i_reason          => NULL,
                                              i_notes           => i_notes,
                                              o_error           => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END resume_med_presc;

    FUNCTION resume_med_adm
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN drug_presc_det.id_drug_presc_det%TYPE,
        i_id_presc_plan    IN drug_presc_plan.id_drug_presc_plan%TYPE,
        i_id_resume_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_resume_reason    IN VARCHAR2,
        i_notes_resume     IN VARCHAR2,
        i_dt_resume        IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_function := 'resume_med_adm';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_pfh_in.set_resume_adm(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_id_presc         => i_id_presc,
                                            i_id_presc_plan    => i_id_presc_plan,
                                            i_id_resume_reason => i_id_resume_reason,
                                            i_resume_reason    => i_resume_reason,
                                            i_notes_resume     => i_notes_resume,
                                            i_dt_resume        => i_dt_resume,
                                            i_flg_confirm      => 'Y',
                                            o_error            => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END resume_med_adm;

    FUNCTION discontinue_med_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_notes            IN drug_presc_det.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
    BEGIN
    
        g_function := 'discontinue_med_presc';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        FOR i IN 1 .. i_id_presc.count
        LOOP
        
            l_result := pk_api_pfh_in.set_cancel_presc(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_id_presc  => i_id_presc(i),
                                                       i_id_reason => i_id_cancel_reason,
                                                       i_reason    => i_cancel_reason,
                                                       i_notes     => i_notes,
                                                       o_error     => o_error);
        
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END discontinue_med_presc;

    FUNCTION cancel_med_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_presc         IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_notes            IN drug_presc_det.notes_cancel%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
    
    BEGIN
    
        g_function := 'cancel_med_presc';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        FOR i IN 1 .. i_id_presc.count
        LOOP
        
            l_result := pk_api_pfh_in.set_cancel_presc(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_id_presc  => i_id_presc(i),
                                                       i_id_reason => i_id_cancel_reason,
                                                       i_reason    => i_cancel_reason,
                                                       i_notes     => i_notes,
                                                       o_error     => o_error);
        
        END LOOP;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_med_presc;

    FUNCTION cancel_med_take
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_presc            IN drug_presc_det.id_drug_presc_det%TYPE,
        i_id_presc_plan       IN drug_presc_plan.id_drug_presc_plan%TYPE,
        i_id_cancel_reason    IN drug_presc_plan.id_cancel_reason%TYPE,
        i_cancel_reason_descr IN VARCHAR2,
        i_notes               IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_function := 'cancel_take';
    
        g_error := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_api_pfh_in.set_cancel_adm(i_lang          => i_lang,
                                            i_prof          => i_prof,
                                            i_id_presc      => i_id_presc,
                                            i_id_presc_plan => i_id_presc_plan,
                                            i_id_reason     => i_id_cancel_reason,
                                            i_reason        => i_cancel_reason_descr,
                                            i_notes         => i_notes,
                                            o_error         => o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_med_take;

    FUNCTION get_med_task_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_detail_type        IN VARCHAR2,
        i_id_detail          IN NUMBER,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_presc_plan      IN NUMBER, --presc_plan.id_presc_plan%type ( no grants)
        i_id_presc           IN table_number,
        i_id_presc_plan_task IN NUMBER, --presc_plan_task.id_presc_plan_task%type ( no grants)
        o_cur_data           OUT pk_types.cursor_type,
        o_cur_tables         OUT table_table_varchar,
        o_header_presc       OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alertlog.log_error('i_id_detail: ' || i_id_detail || ' i_id_episode: ' || i_id_episode ||
                              ' i_id_presc_plan: ' || i_id_presc_plan || ' i_id_presc_plan_task: ' ||
                              i_id_presc_plan_task || ' i_id_presc: ' || i_id_presc(1));
    
        g_function := 'get_med_task_detail';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        IF (i_detail_type = 'D')
        THEN
        
            RETURN pk_api_pfh_in.get_details(i_lang,
                                             i_prof,
                                             i_id_detail,
                                             i_id_episode,
                                             i_id_presc_plan,
                                             i_id_presc,
                                             i_id_presc_plan_task,
                                             o_cur_data,
                                             o_cur_tables,
                                             o_header_presc,
                                             o_error);
        ELSE
            RETURN pk_api_pfh_in.get_details_history(i_lang,
                                                     i_prof,
                                                     i_id_detail,
                                                     i_id_episode,
                                                     i_id_presc_plan,
                                                     i_id_presc,
                                                     o_cur_data,
                                                     o_cur_tables,
                                                     o_header_presc,
                                                     o_error);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_med_task_detail;

    PROCEDURE events_________________(i_lang IN language.id_language%TYPE) IS
    BEGIN
        dbms_output.put_line(i_lang);
    END;

    FUNCTION get_pdms_events
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_scope     IN VARCHAR2,
        i_scope         IN NUMBER,
        i_flg_report    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_hist IN VARCHAR2,
        o_events        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'get_pdms_events';
        IF i_flg_show_hist = pk_alert_constant.g_no
        THEN
            RETURN pk_api_pdms_core.get_events(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_flg_scope  => i_flg_scope,
                                               i_scope      => i_scope,
                                               i_flg_type   => 'E',
                                               i_flg_report => i_flg_report,
                                               o_events     => o_events,
                                               o_error      => o_error);
        ELSE
            RETURN pk_api_pdms_core.get_events_hist(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_flg_scope  => i_flg_scope,
                                                    i_scope      => i_scope,
                                                    i_flg_type   => 'E',
                                                    i_flg_report => i_flg_report,
                                                    o_events     => o_events,
                                                    o_error      => o_error);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pdms_events;

    FUNCTION get_pdms_cases
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_scope     IN VARCHAR2,
        i_scope         IN NUMBER,
        i_flg_report    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_hist IN VARCHAR2,
        o_events        OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_function := 'get_pdms_cases';
        IF i_flg_show_hist = pk_alert_constant.g_no
        THEN
            RETURN pk_api_pdms_core.get_events(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_flg_scope  => i_flg_scope,
                                               i_scope      => i_scope,
                                               i_flg_type   => 'C',
                                               i_flg_report => i_flg_report,
                                               o_events     => o_events,
                                               o_error      => o_error);
        ELSE
            RETURN pk_api_pdms_core.get_events_hist(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_flg_scope  => i_flg_scope,
                                                    i_scope      => i_scope,
                                                    i_flg_type   => 'C',
                                                    i_flg_report => i_flg_report,
                                                    o_events     => o_events,
                                                    o_error      => o_error);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_pdms_cases;

BEGIN

    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_api_pdms;
/
