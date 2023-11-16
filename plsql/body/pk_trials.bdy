/*-- Last Change Revision: $Rev: 1890952 $ */
/*-- Last Change by: $Author: nuno.coelho $ */
/*-- Date of last change: $Date: 2019-02-06 10:11:55 +0000 (qua, 06 fev 2019) $ */
CREATE OR REPLACE PACKAGE BODY pk_trials IS

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_sch_reason_discontinue NUMBER := 50; -- Schedule cancel reason for discontinue
    g_sch_reason_conclude    NUMBER := 49; -- Schedule cancel reason for conclude
    g_sch_reason_hold        NUMBER := 48; -- Schedule cancel reason for hold

    /**********************************************************************************************
    * Check if a patient is on trial
    *
    * @param i_id_patient   PATIENT ID
    * @param o_pat_trial    Y - is on trial N - not on trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/24
    **********************************************************************************************/
    FUNCTION check_patient_trial
    (
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_error     t_error_out;
        l_pat_trial VARCHAR2(1);
    BEGIN
    
        SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_pat_trial
          FROM pat_trial pt
         WHERE pt.id_patient = i_id_patient
           AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r);
        RETURN l_pat_trial;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => 1,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'check_patient_trial',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
        
    END check_patient_trial;

    /**********************************************************************************************
    * Retrieves the list of internal trials. This list excludes all the trials that 
    * have been canceled by the professionals.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_trials_list            array with the list of Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_trials_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_trials_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ ]', g_package, 'GET_TRIALS_LIST');
        --
        g_error := 'OPEN CURSOR o_trials_list';
        OPEN o_trials_list FOR
            SELECT t.id_trial id,
                   t.code code,
                   t.name name,
                   pk_utils.concat_table(get_trial_resp_name_list(i_lang, i_prof, t.id_trial), ',') responsibles,
                   pk_prof_utils.get_nickname(i_lang, t.id_prof_record) prof_last_edition,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, t.dt_record, NULL) dt_last_edition,
                   pk_sysdomain.get_domain(g_trial_f_status_domain, t.flg_status, i_lang) status_desc,
                   t.flg_status status,
                   decode(t.flg_status,
                          g_trial_f_status_r,
                          1,
                          g_trial_f_status_a,
                          2,
                          g_trial_f_status_f,
                          3,
                          g_trial_f_status_d,
                          4,
                          5) rank,
                   
                   decode(t.flg_status, g_trial_f_status_r, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_cancel,
                   decode(t.flg_status,
                          g_trial_f_status_r,
                          pk_alert_constant.g_yes,
                          g_trial_f_status_a,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_edit
              FROM trial t
             WHERE t.flg_trial_type = g_trial_f_trial_type_i
                  --  AND t.flg_status <> g_trial_f_status_c
               AND t.id_institution = i_prof.institution
            --this order is defined in the drawings
             ORDER BY rank, name DESC, code DESC, prof_last_edition DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trials_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIALS_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_trials_list;
    --

    /**********************************************************************************************
    * Retrieves the list of internal trials that are under responsability of a given professional
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_trials_list            array with the list of Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_my_internal_trials
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        o_trials_list   OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_prof.ID: ' || i_prof.id || ']', g_package, 'get_my_internal_trials');
        --
        g_error := 'OPEN CURSOR o_trials_list';
        OPEN o_trials_list FOR
            SELECT t.id_trial id,
                   t.code code,
                   t.name name,
                   t.flg_status status,
                   decode(t.flg_status, g_trial_f_status_a, 1, g_trial_f_status_i, 2, 3) rank
              FROM trial t
             WHERE t.flg_trial_type = g_trial_f_trial_type_i
               AND t.flg_status = g_trial_f_status_a
               AND i_prof.id IN (SELECT *
                                   FROM TABLE(get_trial_resp_id_list(i_lang, i_prof, t.id_trial)))
               AND t.id_institution = i_prof.institution
               AND NOT EXISTS
             (SELECT 1
                      FROM pat_trial pt
                     WHERE pt.id_patient = i_id_patient
                       AND pt.id_trial = t.id_trial
                       AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r, g_pat_trial_f_status_h))
            --this order is defined in the drawings
             ORDER BY rank, name DESC, code DESC;
    
        g_error := 'OPEN CURSOR o_screen_labels';
        OPEN o_screen_labels FOR
            SELECT pk_message.get_message(i_lang, 'TRIALS_T001') screen_header,
                   pk_message.get_message(i_lang, 'TRIALS_T040') header_viewer
              FROM dual;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trials_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_MY_INTERNAL_TRIALS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_my_internal_trials;
    --

    /**********************************************************************************************
    * Retrieves the list Trials (internal and external) in which a patient is participating 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param o_trials_int_list        array with the list of internal Trials
    * @param o_trials_ext_list        array with the list of external Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_pat_trials_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        o_trials_int_list OUT pk_types.cursor_type,
        o_trials_ext_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient :' || i_id_patient || ']', g_package, 'GET_TRIALS_LIST');
    
        g_error := 'OPEN CURSOR o_trials_list';
    
        OPEN o_trials_int_list FOR
            SELECT pt.id_pat_trial id_pat_trial,
                   t.id_trial id_trial,
                   t.code code,
                   t.name name,
                   pk_utils.concat_table(get_trial_resp_name_list(i_lang, i_prof, t.id_trial), ',') responsibles,
                   get_trial_resp_id_list(i_lang, i_prof, t.id_trial) responsibles_ids,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, pt.dt_trial_begin, NULL) dt_trial_begin,
                   pk_sysdomain.get_domain(g_pat_trial_f_status_domain, pt.flg_status, i_lang) status_desc,
                   pt.flg_status status,
                   decode(pt.flg_status,
                          g_pat_trial_f_status_a,
                          1,
                          g_pat_trial_f_status_e,
                          2,
                          g_pat_trial_f_status_r,
                          3,
                          g_pat_trial_f_status_h,
                          4,
                          g_pat_trial_f_status_d,
                          5,
                          g_pat_trial_f_status_f,
                          6,
                          g_pat_trial_f_status_c,
                          7,
                          9) rank,
                   pk_sysdomain.get_img(i_lang, g_pat_trial_f_status_domain, pt.flg_status) status_img,
                   --                   decode(get_count_trial_follow_up(pt.id_pat_trial),
                   --                          0,
                   --                          decode(check_prof_responsible(i_prof, t.id_trial),
                   --                                 pk_alert_constant.g_yes,
                   --                                 pk_alert_constant.g_yes,
                   --                                 pk_alert_constant.g_no),
                   --                          pk_alert_constant.get_no) flg_cancel,
                   decode(check_prof_responsible(i_prof, t.id_trial),
                          pk_alert_constant.g_yes,
                          decode(pt.flg_status,
                                 g_pat_trial_f_status_a,
                                 pk_alert_constant.g_yes,
                                 g_pat_trial_f_status_r,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no) flg_action
              FROM pat_trial pt
              JOIN trial t
                ON pt.id_trial = t.id_trial
             WHERE pt.id_patient = i_id_patient
               AND t.flg_trial_type = g_trial_f_trial_type_i
               AND t.flg_status <> g_trial_f_status_c
            --this order is defined in the drawings
             ORDER BY rank, name DESC, code DESC, responsibles DESC, dt_trial_begin DESC;
    
        OPEN o_trials_ext_list FOR
            SELECT pt.id_pat_trial id_pat_trial,
                   t.id_trial id_trial,
                   t.code code,
                   t.name name,
                   t.responsible responsibles,
                   pk_date_utils.get_timestamp_str(i_lang, i_prof, pt.dt_trial_begin, NULL) dt_trial_begin,
                   pk_sysdomain.get_domain(g_pat_trial_f_status_domain, pt.flg_status, i_lang) status_desc,
                   pt.flg_status status,
                   decode(pt.flg_status,
                          g_pat_trial_f_status_a,
                          1,
                          g_pat_trial_f_status_e,
                          2,
                          g_pat_trial_f_status_r,
                          3,
                          g_pat_trial_f_status_h,
                          4,
                          g_pat_trial_f_status_d,
                          5,
                          g_pat_trial_f_status_f,
                          6,
                          g_pat_trial_f_status_c,
                          7,
                          9) rank,
                   pk_sysdomain.get_img(i_lang, g_pat_trial_f_status_domain, pt.flg_status) status_img,
                   --                   decode(get_count_trial_follow_up(pt.id_pat_trial),
                   --                          0,
                   --                          pk_alert_constant.g_yes,
                   --                          pk_alert_constant.get_no) flg_cancel,
                   decode(pt.flg_status,
                          g_pat_trial_f_status_a,
                          pk_alert_constant.g_yes,
                          g_pat_trial_f_status_r,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no) flg_action
              FROM pat_trial pt
              JOIN trial t
                ON pt.id_trial = t.id_trial
             WHERE pt.id_patient = i_id_patient
               AND t.flg_trial_type = g_trial_f_trial_type_e
               AND t.flg_status <> g_trial_f_status_c
            --this order is defined in the drawings
            
             ORDER BY rank, name DESC, code DESC, responsibles DESC, dt_trial_begin DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trials_int_list);
            pk_types.open_my_cursor(o_trials_ext_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PAT_TRIALS_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_trials_list;
    --

    /**********************************************************************************************
    * Retrieves the information for a given trial to edit.
    * If the i_id_trial parameter is NULL, the function returns only the labels to be used 
    * in the edit screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_trial               ID trial to edit, or NULL for trial creation
    * @param i_trial_type             Type of trial: I -internal, E - external
    * @param o_trial                  Information for the trial to edit
    * @param o_screen_labels          Labels for the edit screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/28
    **********************************************************************************************/
    FUNCTION get_trial_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_trial      IN trial.id_trial%TYPE,
        i_trial_type    IN trial.flg_trial_type%TYPE DEFAULT 'I',
        o_trial         OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_id_trial:' || i_id_trial || ' ]', g_package, 'GET_TRIAL_EDIT');
        --
        g_error := 'OPEN CURSOR o_trial';
    
        IF i_trial_type = g_trial_f_trial_type_i
        THEN
            OPEN o_screen_labels FOR
                SELECT decode(i_id_trial,
                              NULL,
                              pk_message.get_message(i_lang, 'TRIALS_T010'),
                              pk_message.get_message(i_lang, 'TRIALS_T009')) screen_header,
                       pk_message.get_message(i_lang, 'TRIALS_T002') code,
                       pk_message.get_message(i_lang, 'TRIALS_T003') name,
                       pk_message.get_message(i_lang, 'TRIALS_T007') responsibles,
                       pk_message.get_message(i_lang, 'TRIALS_T008') notes,
                       pk_message.get_message(i_lang, 'TRIALS_T006') status,
                       pk_message.get_message(i_lang, 'TRIALS_T081') pharma_code,
                       pk_message.get_message(i_lang, 'TRIALS_T082') pharma_name
                  FROM dual;
        ELSE
            OPEN o_screen_labels FOR
                SELECT decode(i_id_trial,
                              NULL,
                              pk_message.get_message(i_lang, 'TRIALS_T017'),
                              pk_message.get_message(i_lang, 'TRIALS_T016')) screen_header,
                       pk_message.get_message(i_lang, 'TRIALS_T002') code,
                       pk_message.get_message(i_lang, 'TRIALS_T003') name,
                       pk_message.get_message(i_lang, 'TRIALS_T007') responsibles,
                       pk_message.get_message(i_lang, 'TRIALS_T018') contacts,
                       pk_message.get_message(i_lang, 'TRIALS_T008') notes
                
                  FROM dual;
        
        END IF;
        IF i_id_trial IS NULL
        
        THEN
            IF i_trial_type = g_trial_f_trial_type_i
            THEN
                --creating new trial: there is no info to be shown
            
                OPEN o_trial FOR
                    SELECT pk_sysdomain.get_domain(g_trial_f_status_domain, g_pat_trial_f_status_a, i_lang) status_desc,
                           g_pat_trial_f_status_a status
                      FROM dual;
            ELSE
                pk_types.open_my_cursor(o_trial);
            END IF;
        ELSE
            IF i_trial_type = g_trial_f_trial_type_i
            THEN
            
                OPEN o_trial FOR
                    SELECT t.id_trial id,
                           t.code code,
                           t.name name,
                           get_trial_resp_id_list(i_lang, i_prof, t.id_trial) responsibles_ids,
                           pk_utils.concat_table(get_trial_resp_name_list(i_lang, i_prof, t.id_trial), ',') responsibles,
                           pk_sysdomain.get_domain(g_trial_f_status_domain, t.flg_status, i_lang) status_desc,
                           t.flg_status status,
                           t.notes,
                           t.pharma_code,
                           t.pharma_name
                      FROM trial t
                     WHERE t.id_trial = i_id_trial;
            ELSE
                OPEN o_trial FOR
                    SELECT t.id_trial         id,
                           t.code             code,
                           t.name             name,
                           t.resp_contact_det contacts,
                           t.responsible      responsibles,
                           t.notes
                      FROM trial t
                     WHERE t.id_trial = i_id_trial;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIAL_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_trial_edit;
    --

    /**********************************************************************************************
    * Retrieves the information for a given external trial to edit.
    * If the i_id_trial parameter is NULL, the function returns only the labels to be used 
    * in the edit screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_trial               ID trial to edit, or NULL for trial creation
    * @param o_trial                  Information for the trial to edit
    * @param o_screen_labels          Labels for the edit screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/28
    **********************************************************************************************/
    FUNCTION get_external_trial_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_trial      IN trial.id_trial%TYPE,
        o_trial         OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_id_trial:' || i_id_trial || ' ]',
                                       g_package,
                                       'GET_EXTERNAL_TRIAL_EDIT');
        --
        IF NOT get_trial_edit(i_lang          => i_lang,
                              i_prof          => i_prof,
                              i_id_trial      => i_id_trial,
                              i_trial_type    => g_trial_f_trial_type_e,
                              o_trial         => o_trial,
                              o_screen_labels => o_screen_labels,
                              o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_EXTERNAL_TRIAL_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_external_trial_edit;
    --
    /**********************************************************************************************
    * Retrieves the information for a given internal trial to edit.
    * If the i_id_trial parameter is NULL, the function returns only the labels to be used 
    * in the edit screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_trial               ID trial to edit, or NULL for trial creation
    * @param o_trials_list            Information for the trial to edit
    * @param o_screen_labels          Labels for the edit screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/28
    **********************************************************************************************/
    FUNCTION get_internal_trial_edit
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_trial      IN trial.id_trial%TYPE,
        o_trial         OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_id_trial:' || i_id_trial || ' ]',
                                       g_package,
                                       'GET_INTERNAL_TRIAL_EDIT');
        --
    
        IF NOT get_trial_edit(i_lang          => i_lang,
                              i_prof          => i_prof,
                              i_id_trial      => i_id_trial,
                              i_trial_type    => g_trial_f_trial_type_i,
                              o_trial         => o_trial,
                              o_screen_labels => o_screen_labels,
                              o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_INTERNAL_TRIAL_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_internal_trial_edit;

    /**********************************************************************************************
    * Get the list of professionals responsible for a trial (list of IDs).
    *
    * @param i_lang                   ID language
    * @param i_prof                   professional, software and institution ids
    
    * @param o_trials_list            array with the list of 
    * @param o_error                  Error message
    *
    * @return                         List of professionals 
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION get_trial_resp_id_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_trial_id IN trial.id_trial%TYPE
    ) RETURN table_number IS
    
        l_prof_resp_list table_number := table_number();
        l_error          t_error_out;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_trial_id:' || i_trial_id || ' ]',
                                       g_package,
                                       'GET_TRIAL_RESP_ID_LIST');
        --
    
        --get the list of professionals associated with the trial
        g_error := 'GET_TRIAL_RESPONSIBLES';
        SELECT tp.id_professional
          BULK COLLECT
          INTO l_prof_resp_list
          FROM trial_prof tp
         WHERE tp.id_trial = i_trial_id;
    
        RETURN l_prof_resp_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIAL_RESP_ID_LIST',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN table_number();
    END get_trial_resp_id_list;
    --

    /**********************************************************************************************
    * Get the trial's name.
    *
    * @param i_lang                   ID language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_pat_trial           ID Trial 
    * @param o_error                  Error message
    *
    * @return                         Name of the trial 
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION get_pat_trial_name
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN pat_trial.id_pat_trial%TYPE
    ) RETURN VARCHAR2 IS
    
        l_trial_name trial.name%TYPE;
        l_error      t_error_out;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_id_pat_trial:' || i_id_pat_trial || ' ]',
                                       g_package,
                                       'GET_TRIAL_NAME');
        --
    
        --get the list of professionals associated with the trial
        g_error := 'GET_PAT_TRIAL_NAME';
        SELECT t.name
          INTO l_trial_name
          FROM pat_trial pt
          JOIN trial t
            ON pt.id_trial = t.id_trial
         WHERE pt.id_pat_trial = i_id_pat_trial;
    
        RETURN l_trial_name;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PAT_TRIAL_NAME',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_pat_trial_name;
    --

    /**********************************************************************************************
    * Get the list of professionals responsible for a trial (list of professional names).
    *
    * @param i_lang                   ID language
    * @param i_prof                   professional, software and institution ids
    *
    * @param o_error                  Error message
    *
    * @return                         List of professionals 
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION get_trial_resp_name_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_trial_id IN trial.id_trial%TYPE
    ) RETURN table_varchar IS
    
        l_prof_resp_list table_varchar := table_varchar();
        l_error          t_error_out;
        CURSOR c_trial IS
            SELECT t.flg_trial_type
              FROM trial t
             WHERE t.id_trial = i_trial_id;
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_trial_id:' || i_trial_id || ' ]',
                                       g_package,
                                       'GET_TRIAL_RESP_NAME_LIST');
        --
    
        --get the list of professionals associated with the trial
        g_error := 'GET_TRIAL_RESPONSIBLES NAMES';
        SELECT pk_prof_utils.get_nickname(i_lang, tp.id_professional)
          BULK COLLECT
          INTO l_prof_resp_list
          FROM trial_prof tp
         WHERE tp.id_trial = i_trial_id;
    
        RETURN l_prof_resp_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIAL_RESP_NAME_LIST',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN table_varchar();
    END get_trial_resp_name_list;

    /**********************************************************************************************
    * Get the list of professionals responsible for a trial (list of professional names) from history.
    *
    * @param i_lang                   ID language
    * @param i_prof                   professional, software and institution ids
    *
    * @param o_error                  Error message
    *
    * @return                         List of professionals 
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/09
    **********************************************************************************************/
    FUNCTION get_trial_resp_name_hist_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_trial_hist_id IN trial.id_trial%TYPE
    ) RETURN table_varchar IS
    
        l_prof_resp_list table_varchar := table_varchar();
        l_error          t_error_out;
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_trial_id:' || i_trial_hist_id || ' ]',
                                       g_package,
                                       'GET_TRIAL_RESP_NAME_HIST_LIST');
        --
    
        --get the list of professionals associated with the trial
        g_error := 'GET_TRIAL_RESPONSIBLES HIST LIST';
        SELECT pk_prof_utils.get_nickname(i_lang, tph.id_professional)
          BULK COLLECT
          INTO l_prof_resp_list
          FROM trial_prof_hist tph
         WHERE tph.id_trial_hist = i_trial_hist_id;
    
        RETURN l_prof_resp_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIAL_RESP_NAME_HIST_LIST',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN table_varchar();
    END get_trial_resp_name_hist_list;

    /**********************************************************************************************
    * Creates a new internal trial or edit an existing one. 
    * If the parameter i_trial_id is NULL we are creating new trials.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_status           Trial status
    * @param i_trial_responsibles     List of IDs of professionals responsible for this trial
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param o_id_trial               ID of the created trial 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION set_internal_trial
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_trial_id           IN trial.id_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_status       IN trial.flg_status%TYPE DEFAULT 'A',
        i_trial_responsibles IN table_number,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        o_id_trial           OUT trial.id_trial%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_dt_start      trial.dt_start%TYPE := NULL;
        l_dt_end        trial.dt_end%TYPE := NULL;
        l_rows_out      table_varchar := table_varchar();
        l_id_trial_hist trial_hist.id_trial_hist%TYPE;
        l_id_trial      trial.id_trial%TYPE;
    
        --manage the professionals 
        l_cur_profs_list table_number := table_number();
        l_new_profs_list table_number := table_number();
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_trial_name: ' || i_trial_name || ', i_trial_code: ' || i_trial_code ||
                                       ', i_trial_status: ' || i_trial_status || ' ]',
                                       g_package,
                                       'SET_INTERNAL_TRIAL');
        --
        g_sysdate_tstz := current_timestamp;
    
        IF NOT set_trial(i_lang               => i_lang,
                         i_prof               => i_prof,
                         i_trial_id           => i_trial_id,
                         i_trial_name         => i_trial_name,
                         i_trial_code         => i_trial_code,
                         i_trial_notes        => i_trial_notes,
                         i_trial_status       => i_trial_status,
                         i_trial_responsibles => i_trial_responsibles,
                         i_dt_start           => i_dt_start,
                         i_dt_end             => i_dt_end,
                         i_trial_type         => g_trial_f_trial_type_i,
                         o_id_trial           => o_id_trial,
                         o_id_trial_hist      => l_id_trial_hist,
                         o_error              => o_error)
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
                                              i_function => 'SET_INTERNAL_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_internal_trial;
    --

    /**********************************************************************************************
    * Creates a new external trial or edit an existing one. 
    * If the parameter i_trial_id is NULL we are creating new trials.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_status           Trial status
    * @param i_trial_responsibles     Text with the name of the responsible(s) for the trial
    * @param i_trial_resp_contact     Contact details for the responsible(s) for the trial    
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param o_id_trial               ID of the created trial 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION set_external_trial
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_trial_id           IN trial.id_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_status       IN trial.flg_status%TYPE DEFAULT 'A',
        i_trial_responsibles IN VARCHAR2,
        i_trial_resp_contact IN VARCHAR2,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_commit             IN VARCHAR2 DEFAULT 'Y',
        o_id_trial           OUT trial.id_trial%TYPE,
        o_id_trial_hist      OUT trial_hist.id_trial_hist%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_trial_name: ' || i_trial_name || ', i_trial_code: ' || i_trial_code ||
                                       ', i_trial_status: ' || i_trial_status || ' ]',
                                       g_package,
                                       'SET_EXTERNAL_TRIAL');
        --
        g_sysdate_tstz := current_timestamp;
    
        IF NOT set_trial(i_lang               => i_lang,
                         i_prof               => i_prof,
                         i_trial_id           => i_trial_id,
                         i_trial_name         => i_trial_name,
                         i_trial_code         => i_trial_code,
                         i_trial_notes        => i_trial_notes,
                         i_trial_status       => i_trial_status,
                         i_trial_responsibles => table_number(),
                         i_trial_resp_ext     => i_trial_responsibles,
                         i_trial_resp_cont    => i_trial_resp_contact,
                         i_dt_start           => i_dt_start,
                         i_dt_end             => i_dt_end,
                         i_trial_type         => g_trial_f_trial_type_e,
                         i_commit             => pk_alert_constant.g_no,
                         o_id_trial           => o_id_trial,
                         o_id_trial_hist      => o_id_trial_hist,
                         o_error              => o_error)
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
                                              i_function => 'SET_EXTERNAL_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_external_trial;
    --

    /**********************************************************************************************
    * Creates a new trial (internal or external) or edit an existing one. 
    * If the parameter i_trial_id is NULL we are creating new trials.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_status           Trial status
    * @param i_trial_responsibles     List of IDs of professionals responsible for this trial
    * @param i_trial_resp_ext         Free text list os professionals responsible for this trial
    * @param i_trial_resp_cont        Contact details for the professionals responsible for this trial
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param i_trial_type             Type of trial: I -internal, E - external
    * @param o_id_trial               ID of the created trial 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION set_trial
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_trial_id           IN trial.id_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_status       IN trial.flg_status%TYPE DEFAULT 'A',
        i_trial_responsibles IN table_number,
        i_trial_resp_ext     IN trial.responsible%TYPE DEFAULT NULL,
        i_trial_resp_cont    IN trial.resp_contact_det%TYPE DEFAULT NULL,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_trial_type         IN trial.flg_trial_type%TYPE DEFAULT 'I',
        i_pharma_code        IN trial.pharma_code%TYPE DEFAULT NULL,
        i_pharma_name        IN trial.pharma_name%TYPE DEFAULT NULL,
        i_commit             IN VARCHAR2 DEFAULT 'Y',
        o_id_trial           OUT trial.id_trial%TYPE,
        o_id_trial_hist      OUT trial_hist.id_trial_hist%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_dt_start      trial.dt_start%TYPE := NULL;
        l_dt_end        trial.dt_end%TYPE := NULL;
        l_rows_out      table_varchar := table_varchar();
        l_id_trial_hist trial_hist.id_trial_hist%TYPE;
        l_id_trial      trial.id_trial%TYPE;
    
        --manage the trial responsibles 
        l_cur_profs_list table_number := table_number();
        l_new_profs_list table_number := table_number();
        l_num            NUMBER;
        l_flg_status     trial.flg_status%TYPE;
        l_exception EXCEPTION;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_trial_name: ' || i_trial_name || ', i_trial_code: ' || i_trial_code ||
                                       ', i_trial_status: ' || i_trial_status || ' ]',
                                       g_package,
                                       'SET_TRIAL');
        --
        g_sysdate_tstz := current_timestamp;
    
        --datas validation
        IF i_dt_start IS NOT NULL
        THEN
        
            l_dt_start := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_dt_start,
                                                        i_timezone  => NULL);
        END IF;
    
        IF i_dt_end IS NOT NULL
        THEN
        
            l_dt_end := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_timestamp => i_dt_end,
                                                      i_timezone  => NULL);
        END IF;
    
        IF i_trial_id IS NULL
        THEN
            o_id_trial := ts_trial.next_key;
            IF i_trial_type = g_trial_f_trial_type_i
            THEN
                l_flg_status := g_trial_f_status_r;
            ELSE
                l_flg_status := g_trial_f_status_a;
            END IF;
        
        ELSE
            o_id_trial := i_trial_id;
        
            IF i_trial_status = g_trial_f_status_i
            THEN
                SELECT flg_status
                  INTO l_flg_status
                  FROM trial
                 WHERE id_trial = i_trial_id;
                IF l_flg_status = g_trial_f_status_a
                THEN
                    SELECT COUNT(1)
                      INTO l_num
                      FROM pat_trial pt
                     WHERE pt.id_trial = i_trial_id
                       AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r, g_pat_trial_f_status_h);
                    IF l_num > 0
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF;
            END IF;
        END IF;
    
        g_error := 'CALL TS_TRIAL.INS';
        ts_trial.upd_ins(id_trial_in         => o_id_trial,
                         name_in             => i_trial_name,
                         code_in             => i_trial_code,
                         notes_in            => i_trial_notes,
                         flg_status_in       => l_flg_status,
                         dt_record_in        => g_sysdate_tstz,
                         id_prof_record_in   => i_prof.id,
                         responsible_in      => i_trial_resp_ext,
                         resp_contact_det_in => i_trial_resp_cont,
                         dt_start_in         => l_dt_start,
                         dt_end_in           => l_dt_end,
                         pharma_code_in      => i_pharma_code,
                         pharma_name_in      => i_pharma_name,
                         id_institution_in   => i_prof.institution,
                         flg_trial_type_in   => i_trial_type,
                         rows_out            => l_rows_out);
    
        IF i_trial_id IS NULL
        THEN
            alertlog.pk_alertlog.log_debug('CREATE_TRIAL: id_trial:' || o_id_trial, g_package, 'SET_TRIAL');
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'TRIAL',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            IF i_trial_type = g_trial_f_trial_type_i
            THEN
                --create the professionals responsible for the trial
                FOR i IN 1 .. i_trial_responsibles.count
                LOOP
                    alertlog.pk_alertlog.log_debug('CREATE_TRIAL_RESPONSIBLE: id_trial:' || o_id_trial ||
                                                   ', id_professional: ' || i_trial_responsibles(i),
                                                   g_package,
                                                   'SET_TRIAL');
                    ts_trial_prof.ins(id_trial_in        => o_id_trial,
                                      id_professional_in => i_trial_responsibles(i),
                                      rows_out           => l_rows_out);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'TRIAL_PROF',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                END LOOP;
            END IF;
        ELSE
            alertlog.pk_alertlog.log_debug('UPDATE_TRIAL: id_trial:' || o_id_trial, g_package, 'SET_TRIAL');
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'TRIAL',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
            -- 
            IF i_trial_type = g_trial_f_trial_type_i
            THEN
                l_cur_profs_list := get_trial_resp_id_list(i_lang, i_prof, o_id_trial);
            
                --delete professionals that are not responsible for the trial
                l_new_profs_list := l_cur_profs_list MULTISET except i_trial_responsibles;
                FOR i IN 1 .. l_new_profs_list.count
                LOOP
                    pk_alertlog.log_debug('DELETE NOT USED PROFESSIONALS: l_new_profs_list: ' || l_new_profs_list(i));
                
                    ts_trial_prof.del(id_trial_in        => o_id_trial,
                                      id_professional_in => l_new_profs_list(i),
                                      rows_out           => l_rows_out);
                
                    t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'TRIAL_PROF',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                END LOOP;
                --
                --create new professionals that are added as responsible for the trial
                l_new_profs_list := i_trial_responsibles MULTISET except l_cur_profs_list;
                FOR i IN 1 .. l_new_profs_list.count
                LOOP
                    pk_alertlog.log_debug('INSERT INTO TRIAL_PROF: l_new_profs_list' || l_new_profs_list(i));
                
                    ts_trial_prof.ins(id_trial_in        => o_id_trial,
                                      id_professional_in => l_new_profs_list(i),
                                      rows_out           => l_rows_out);
                
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'TRIAL_PROF',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                END LOOP;
            END IF;
        END IF;
    
        --Create new record in the history for this trial
        IF NOT set_internal_trial_hist(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_trial_id      => o_id_trial,
                                       o_id_trial_hist => o_id_trial_hist,
                                       o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        /*g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;*/
        IF i_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            DECLARE
                l_error_msg    sys_message.desc_message%TYPE;
                l_error_action sys_message.desc_message%TYPE;
                l_ret          BOOLEAN;
            BEGIN
                l_error_msg    := pk_message.get_message(i_lang, 'COMMON_T013');
                l_error_action := pk_message.get_message(i_lang, 'TRIALS_T044');
            
                l_ret := pk_alert_exceptions.process_warning(i_lang        => i_lang,
                                                             i_sqlcode     => '',
                                                             i_sqlerrm     => l_error_action,
                                                             i_message     => g_error,
                                                             i_owner       => g_owner,
                                                             i_package     => g_package,
                                                             i_function    => 'SET_INTERNAL_TRIAL',
                                                             i_action_type => 'U',
                                                             i_action_msg  => '',
                                                             i_msg_title   => l_error_msg,
                                                             o_error       => o_error);
                pk_alert_exceptions.reset_error_state();
                RETURN l_ret;
            END;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_INTERNAL_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_trial;
    --

    /**********************************************************************************************
    * Set the internal trials in which the patient is paticipating
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_patient                ID patient
    * @param i_id_episode             ID episode    
    * @param i_trials_id              array with internal trial IDs
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date  
    * @param o_pat_trial_ids          array with the created pat trials 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION set_pat_internal_trials
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_trials_ids    IN table_number,
        i_dt_start      IN VARCHAR2,
        i_dt_end        IN VARCHAR2,
        o_pat_trial_ids OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out     table_varchar := table_varchar();
        l_pat_trial_id pat_trial.id_pat_trial%TYPE;
    
        l_dt_start      trial.dt_start%TYPE := NULL;
        l_dt_end        trial.dt_end%TYPE := NULL;
        l_pat_trial_ids table_number := table_number();
        l_patient_trial VARCHAR2(1 CHAR);
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient: ' || i_id_patient || ' ]',
                                       g_package,
                                       'SET_PAT_INTERNAL_TRIALS');
        g_error         := 'CHECK_PATIENT_TRIAL';
        l_patient_trial := check_patient_trial(i_prof => i_prof, i_id_patient => i_id_patient);
        --
        g_sysdate_tstz := current_timestamp;
    
        --datas validation
        IF i_dt_start IS NOT NULL
        THEN
        
            l_dt_start := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_dt_start,
                                                        i_timezone  => NULL);
        END IF;
    
        IF i_dt_end IS NOT NULL
        THEN
        
            l_dt_end := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_timestamp => i_dt_end,
                                                      i_timezone  => NULL);
        END IF;
    
        FOR i IN 1 .. i_trials_ids.count
        LOOP
            ts_pat_trial.ins(id_patient_in     => i_id_patient,
                             id_episode_in     => i_id_episode,
                             id_trial_in       => i_trials_ids(i),
                             dt_record_in      => g_sysdate_tstz,
                             id_prof_record_in => i_prof.id,
                             dt_trial_begin_in => g_sysdate_tstz,
                             flg_status_in     => g_pat_trial_f_status_a,
                             id_institution_in => i_prof.institution,
                             dt_start_in       => l_dt_start,
                             dt_end_in         => l_dt_end,
                             id_pat_trial_out  => l_pat_trial_id,
                             rows_out          => l_rows_out);
        
            alertlog.pk_alertlog.log_debug('CREATE_PAT_TRIAL: i_trials_ids:' || i_trials_ids(i),
                                           g_package,
                                           'SET_TRIAL');
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_TRIAL',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            l_pat_trial_ids.extend();
            l_pat_trial_ids(i) := l_pat_trial_id;
        
            ts_pat_trial_hist.ins(id_pat_trial_in   => l_pat_trial_id,
                                  id_episode_in     => i_id_episode,
                                  id_patient_in     => i_id_patient,
                                  id_trial_in       => i_trials_ids(i),
                                  dt_record_in      => g_sysdate_tstz,
                                  id_prof_record_in => i_prof.id,
                                  dt_trial_begin_in => g_sysdate_tstz,
                                  flg_status_in     => g_pat_trial_f_status_a,
                                  id_institution_in => i_prof.institution,
                                  rows_out          => l_rows_out);
        
            alertlog.pk_alertlog.log_debug('CREATE_PAT_TRIAL: i_trials_ids:' || i_trials_ids(i),
                                           g_package,
                                           'SET_TRIAL');
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_TRIAL_HIST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
        END LOOP;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        IF l_patient_trial = pk_alert_constant.g_no
        THEN
            alertlog.pk_alertlog.log_debug('CALL pk_ia_event_common.set_patient_in_trial ' || i_id_patient || ' ]',
                                           g_package,
                                           'SET_PAT_INTERNAL_TRIALS');
        
            pk_ia_event_common.set_patient_in_trial(id_patient => i_id_patient, i_id_institution => i_prof.institution);
        END IF;
        o_pat_trial_ids := l_pat_trial_ids;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PAT_INTERNAL_TRIALS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_internal_trials;
    --

    /**********************************************************************************************
    * Create an external trials in which the patient is paticipating
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_patient                ID patient
    * @param i_id_episode             ID episode
    * @param i_id_pat_trial           ID pat_trial
    * @param i_trial_name             trial name
    * @param i_trial_code             Trial code
    * @param i_trial_notes            Trial notes    
    * @param i_trial_responsibles     Text with the name of the responsible(s) for the trial
    * @param i_trial_resp_contact     Contact details for the responsible(s) for the trial    
    * @param i_dt_start               Trial start date    
    * @param i_dt_end                 Trial end date   
    * @param i_trials_id              array with internal trial IDs
    * @param o_pat_trial_ids          array with the created pat trials 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/31
    **********************************************************************************************/
    FUNCTION set_pat_external_trials
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_pat_trial       IN pat_trial.id_pat_trial%TYPE,
        i_trial_name         IN trial.name%TYPE,
        i_trial_code         IN trial.code%TYPE,
        i_trial_notes        IN trial.notes%TYPE,
        i_trial_responsibles IN trial.responsible%TYPE DEFAULT NULL,
        i_trial_resp_cont    IN trial.resp_contact_det%TYPE DEFAULT NULL,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        o_pat_trial_id       OUT pat_trial.id_pat_trial%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out table_varchar := table_varchar();
        l_trial_id pat_trial.id_pat_trial%TYPE;
    
        l_dt_start   trial.dt_start%TYPE := NULL;
        l_dt_end     trial.dt_end%TYPE := NULL;
        l_trial_hist trial_hist.id_trial_hist%TYPE;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient: ' || i_id_patient || 'i_trial_name: ' || i_trial_name || ' ]',
                                       g_package,
                                       'SET_PAT_EXTERNAL_TRIALS');
        --
    
        --datas validation
        IF i_dt_start IS NOT NULL
        THEN
        
            l_dt_start := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_timestamp => i_dt_start,
                                                        i_timezone  => NULL);
        END IF;
    
        IF i_dt_end IS NOT NULL
        THEN
        
            l_dt_end := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_timestamp => i_dt_end,
                                                      i_timezone  => NULL);
        END IF;
        IF i_id_pat_trial IS NOT NULL
        THEN
            SELECT id_trial
              INTO l_trial_id
              FROM pat_trial
             WHERE id_pat_trial = i_id_pat_trial;
        END IF;
        g_error := 'CREATE THE EXTERNAL TRIAL';
        IF NOT set_external_trial(i_lang               => i_lang,
                                  i_prof               => i_prof,
                                  i_trial_id           => l_trial_id,
                                  i_trial_name         => i_trial_name,
                                  i_trial_code         => i_trial_code,
                                  i_trial_notes        => i_trial_notes,
                                  i_trial_status       => g_trial_f_status_a,
                                  i_trial_responsibles => i_trial_responsibles,
                                  i_trial_resp_contact => i_trial_resp_cont,
                                  i_dt_start           => i_dt_start,
                                  i_dt_end             => i_dt_end,
                                  i_commit             => pk_alert_constant.g_no,
                                  o_id_trial           => l_trial_id,
                                  o_id_trial_hist      => l_trial_hist,
                                  o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --TODO: Edição...
    
        IF i_id_pat_trial IS NULL
        THEN
            o_pat_trial_id := ts_pat_trial.next_key;
            g_sysdate_tstz := current_timestamp;
        
            ts_pat_trial.upd_ins(id_pat_trial_in   => o_pat_trial_id,
                                 id_patient_in     => i_id_patient,
                                 id_episode_in     => i_id_episode,
                                 id_trial_in       => l_trial_id,
                                 dt_record_in      => g_sysdate_tstz,
                                 id_prof_record_in => i_prof.id,
                                 dt_trial_begin_in => g_sysdate_tstz,
                                 flg_status_in     => g_pat_trial_f_status_a,
                                 id_institution_in => i_prof.institution,
                                 dt_start_in       => l_dt_start,
                                 dt_end_in         => l_dt_end,
                                 rows_out          => l_rows_out);
        
            alertlog.pk_alertlog.log_debug('CREATE_PAT_TRIAL: i_trials_ids:' || l_trial_id, g_package, 'SET_TRIAL');
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_TRIAL',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            ts_pat_trial_hist.ins(id_pat_trial_in   => o_pat_trial_id,
                                  id_patient_in     => i_id_patient,
                                  id_episode_in     => i_id_episode,
                                  id_trial_in       => l_trial_id,
                                  dt_record_in      => g_sysdate_tstz,
                                  id_prof_record_in => i_prof.id,
                                  dt_trial_begin_in => g_sysdate_tstz,
                                  flg_status_in     => g_pat_trial_f_status_a,
                                  id_institution_in => i_prof.institution,
                                  rows_out          => l_rows_out);
            alertlog.pk_alertlog.log_debug('CREATE_PAT_TRIAL: i_trials_ids:' || l_trial_id, g_package, 'SET_TRIAL');
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_TRIAL_HIST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
        ELSE
            o_pat_trial_id := i_id_pat_trial;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
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
                                              i_function => 'SET_PAT_EXTERNAL_TRIALS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_external_trials;
    --

    /**********************************************************************************************
    * Change the state of a given trial.
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_trial_status           New trial status
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/26
    **********************************************************************************************/
    FUNCTION set_internal_trial_state
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_trial_id     IN trial_hist.id_trial%TYPE,
        i_trial_status IN trial.flg_status%TYPE,
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_rows_out      table_varchar := table_varchar();
        l_id_trial_hist trial_hist.id_trial_hist%TYPE;
        l_num           NUMBER;
        l_flg_status    trial.flg_status%TYPE;
        l_exception  EXCEPTION;
        l_exception2 EXCEPTION;
        l_error_description sys_message.desc_message%TYPE;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_trial_id:' || i_trial_id || ', i_trial_status: ' || i_trial_status || ' ]',
                                       g_package,
                                       'SET_INTERNAL_TRIAL_STATE');
        --
        g_sysdate_tstz := current_timestamp;
        SELECT flg_status
          INTO l_flg_status
          FROM trial
         WHERE id_trial = i_trial_id;
        IF i_trial_status = g_trial_f_status_f
        THEN
        
            IF l_flg_status = g_trial_f_status_a
            THEN
                SELECT COUNT(1)
                  INTO l_num
                  FROM pat_trial pt
                 WHERE pt.id_trial = i_trial_id
                   AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r, g_pat_trial_f_status_h);
                IF l_num > 0
                THEN
                    RAISE l_exception;
                END IF;
            ELSE
                l_error_description := pk_message.get_message(i_lang, 'TRIALS_T088');
                RAISE l_exception2;
            END IF;
        ELSIF i_trial_status = g_trial_f_status_a
              AND l_flg_status <> g_trial_f_status_r
        THEN
            l_error_description := pk_message.get_message(i_lang, 'TRIALS_T089');
            RAISE l_exception2;
        END IF;
    
        g_error := 'CALL TS_TRIAL.INS';
        ts_trial.upd(id_trial_in       => i_trial_id,
                     flg_status_in     => i_trial_status,
                     dt_record_in      => g_sysdate_tstz,
                     id_prof_record_in => i_prof.id,
                     rows_out          => l_rows_out);
    
        alertlog.pk_alertlog.log_debug('UPDATE_INTERNAL_TRIAL: id_trial:' || i_trial_id,
                                       g_package,
                                       'SET_INTERNAL_TRIAL');
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'TRIAL',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        --Create new record in the history for this trial
        IF NOT set_internal_trial_hist(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_trial_id      => i_trial_id,
                                       o_id_trial_hist => l_id_trial_hist,
                                       o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        OPEN o_status FOR
            SELECT pk_sysdomain.get_domain(g_trial_f_status_domain, t.flg_status, i_lang) status_desc,
                   t.flg_status status,
                   pk_alert_constant.g_no flg_cancel,
                   decode(t.flg_status, g_trial_f_status_f, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_edit
              FROM trial t
             WHERE id_trial = i_trial_id;
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            DECLARE
                l_error_msg    sys_message.desc_message%TYPE;
                l_error_action sys_message.desc_message%TYPE;
                l_ret          BOOLEAN;
            BEGIN
                l_error_msg    := pk_message.get_message(i_lang, 'COMMON_T013');
                l_error_action := pk_message.get_message(i_lang, 'TRIALS_T086');
            
                l_ret := pk_alert_exceptions.process_warning(i_lang        => i_lang,
                                                             i_sqlcode     => '',
                                                             i_sqlerrm     => l_error_action,
                                                             i_message     => g_error,
                                                             i_owner       => g_owner,
                                                             i_package     => g_package,
                                                             i_function    => 'SET_INTERNAL_TRIAL_STATE',
                                                             i_action_type => 'U',
                                                             i_action_msg  => '',
                                                             i_msg_title   => l_error_msg,
                                                             o_error       => o_error);
                pk_alert_exceptions.reset_error_state();
                pk_types.open_my_cursor(o_status);
                RETURN l_ret;
            END;
        WHEN l_exception2 THEN
            DECLARE
                l_error_msg sys_message.desc_message%TYPE;
                l_ret       BOOLEAN;
            BEGIN
                l_error_msg := pk_message.get_message(i_lang, 'COMMON_T013');
            
                l_ret := pk_alert_exceptions.process_warning(i_lang        => i_lang,
                                                             i_sqlcode     => '',
                                                             i_sqlerrm     => l_error_description,
                                                             i_message     => g_error,
                                                             i_owner       => g_owner,
                                                             i_package     => g_package,
                                                             i_function    => 'SET_INTERNAL_TRIAL_STATE',
                                                             i_action_type => 'U',
                                                             i_action_msg  => '',
                                                             i_msg_title   => l_error_msg,
                                                             o_error       => o_error);
                pk_alert_exceptions.reset_error_state();
                pk_types.open_my_cursor(o_status);
                RETURN l_ret;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_INTERNAL_TRIAL_STATE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_status);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_internal_trial_state;
    --

    /**********************************************************************************************
    * Create the internal trial history (for created or updated records).
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param o_id_trial_hist          ID of the created trial history record
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION set_internal_trial_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_trial_id      IN trial_hist.id_trial%TYPE,
        o_id_trial_hist OUT trial_hist.id_trial_hist%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_rows_out       table_varchar := table_varchar();
        l_trial          trial%ROWTYPE;
        l_prof_resp_list table_number;
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_trial_id: ' || i_trial_id || ' ]',
                                       g_package,
                                       'SET_INTERNAL_TRIAL_HIST');
    
        --
        g_error := 'GET LINE FORM TRIAL TABLE';
        SELECT *
          INTO l_trial
          FROM trial t
         WHERE t.id_trial = i_trial_id;
    
        --
        g_error := 'CALL TS_TRIAL_HIST.INS';
        ts_trial_hist.ins(id_trial_hist_out     => o_id_trial_hist,
                          id_trial_in           => l_trial.id_trial,
                          name_in               => l_trial.name,
                          code_in               => l_trial.code,
                          notes_in              => l_trial.notes,
                          flg_status_in         => l_trial.flg_status,
                          dt_record_in          => l_trial.dt_record,
                          id_prof_record_in     => l_trial.id_prof_record,
                          dt_start_in           => l_trial.dt_start,
                          dt_end_in             => l_trial.dt_end,
                          id_institution_in     => l_trial.id_institution,
                          flg_trial_type_in     => l_trial.flg_trial_type,
                          responsible_in        => l_trial.responsible,
                          resp_contact_det_in   => l_trial.resp_contact_det,
                          id_cancel_info_det_in => l_trial.id_cancel_info_det,
                          pharma_code_in        => l_trial.pharma_code,
                          pharma_name_in        => l_trial.pharma_name,
                          rows_out              => l_rows_out);
    
        alertlog.pk_alertlog.log_debug('CREATE_INTERNAL_TRIAL_HIST: id_trial_hist:' || o_id_trial_hist,
                                       g_package,
                                       'SET_INTERNAL_TRIAL_HIST');
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'TRIAL_HIST',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        --get the list of professionals associated with the trial
        SELECT tp.id_professional
          BULK COLLECT
          INTO l_prof_resp_list
          FROM trial_prof tp
         WHERE tp.id_trial = i_trial_id;
    
        --create the professionals responsible for the trial
        FOR i IN 1 .. l_prof_resp_list.count
        LOOP
            alertlog.pk_alertlog.log_debug('CREATE_TRIAL_RESPONSIBLE_HIST: id_trial:' || i_trial_id ||
                                           ', id_professional: ' || l_prof_resp_list(i),
                                           g_package,
                                           'SET_INTERNAL_TRIAL_HIST');
            ts_trial_prof_hist.ins(id_trial_hist_in   => o_id_trial_hist,
                                   id_professional_in => l_prof_resp_list(i),
                                   rows_out           => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'TRIAL_PROF_HIST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
        END LOOP;
    
        --This function does not implement the Commit because it is used internal by other functions
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_INTERNAL_TRIAL_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_internal_trial_hist;
    --

    /**********************************************************************************************
    * Cancel internal trials .
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_trial_id               ID trial
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION inactivate_internal_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_trial_id      IN trial_hist.id_trial%TYPE,
        i_flg_status    IN trial.flg_status%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_rows_out           table_varchar := table_varchar();
        l_id_trial_hist      trial_hist.id_trial_hist%TYPE;
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
        l_num                NUMBER;
        l_exception EXCEPTION;
        l_error_action sys_message.desc_message%TYPE;
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_trial_id:' || i_trial_id || ' ]',
                                       g_package,
                                       'INACTIVATE_INTERNAL_TRIAL');
    
        g_error := 'CHECK usage of trial on FO';
        IF i_flg_status = g_trial_f_status_c
        THEN
            SELECT COUNT(1)
              INTO l_num
              FROM pat_trial pt
             WHERE pt.id_trial = i_trial_id;
            IF l_num > 0
            THEN
                l_error_action := pk_message.get_message(i_lang, 'TRIALS_T043');
                RAISE l_exception;
            END IF;
        ELSE
            --check_conclude_trial
            SELECT COUNT(1)
              INTO l_num
              FROM pat_trial pt
             WHERE id_trial = i_trial_id
               AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r, g_pat_trial_f_status_h);
            IF l_num > 0
            THEN
                l_error_action := pk_message.get_message(i_lang, 'TRIALS_T087');
                RAISE l_exception;
            END IF;
        END IF;
        --insert the cancel details:
        g_sysdate_tstz := current_timestamp;
        --
        pk_alertlog.log_debug('INACTIVATE_INTERNAL_TRIAL: i_cancel_reason =  ' || i_cancel_reason || ', ');
        ts_cancel_info_det.ins(id_prof_cancel_in      => i_prof.id,
                               id_cancel_reason_in    => i_cancel_reason,
                               dt_cancel_in           => g_sysdate_tstz,
                               notes_cancel_short_in  => i_notes,
                               id_cancel_info_det_out => l_cancel_info_det_id,
                               rows_out               => l_rows_out);
    
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON CANCEL_INFO_DET';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CANCEL_INFO_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL TS_TRIAL.INS';
        ts_trial.upd(id_trial_in           => i_trial_id,
                     flg_status_in         => i_flg_status,
                     dt_record_in          => g_sysdate_tstz,
                     id_prof_record_in     => i_prof.id,
                     id_cancel_info_det_in => l_cancel_info_det_id,
                     rows_out              => l_rows_out);
    
        alertlog.pk_alertlog.log_debug('UPDATE_INTERNAL_TRIAL: id_trial:' || i_trial_id,
                                       g_package,
                                       'INACTIVATE_INTERNAL_TRIAL');
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'TRIAL',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        --Set the history for the trial
        IF NOT set_internal_trial_hist(i_lang          => i_lang,
                                       i_prof          => i_prof,
                                       i_trial_id      => i_trial_id,
                                       o_id_trial_hist => l_id_trial_hist,
                                       o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            DECLARE
                l_error_msg sys_message.desc_message%TYPE;
                l_ret       BOOLEAN;
            BEGIN
                l_error_msg := pk_message.get_message(i_lang, 'COMMON_T013');
            
                l_ret := pk_alert_exceptions.process_warning(i_lang        => i_lang,
                                                             i_sqlcode     => '',
                                                             i_sqlerrm     => l_error_action,
                                                             i_message     => g_error,
                                                             i_owner       => g_owner,
                                                             i_package     => g_package,
                                                             i_function    => 'INACTIVATE_INTERNAL_TRIAL',
                                                             i_action_type => 'U',
                                                             i_action_msg  => '',
                                                             i_msg_title   => l_error_msg,
                                                             o_error       => o_error);
                pk_alert_exceptions.reset_error_state();
                RETURN l_ret;
            END;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'INACTIVATE_INTERNAL_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END inactivate_internal_trial;
    --

    /**********************************************************************************************
    * Gets the list of professionals that can be responsible for internal trials.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_prof_list              list of professionals 
    * @param o_cat_list               list of possible categories    
    * @param o_screen_labels          Labels    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/27
    **********************************************************************************************/
    FUNCTION get_responsibles_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_prof_list     OUT pk_types.cursor_type,
        o_cat_list      OUT pk_types.cursor_type,
        o_screen_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_prof.INSTITUTION:' || i_prof.institution || ' ]',
                                       g_package,
                                       'GET_RESPONSIBLES_LIST');
        --
        g_error := 'OPEN CURSOR o_prof_list';
        IF NOT get_cat_prof_list(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_categories  => table_number(1, 2),
                                 i_institution => i_prof.institution,
                                 o_profs       => o_prof_list,
                                 o_error       => o_error)
        
        THEN
            RETURN FALSE;
        END IF;
    
        --
        OPEN o_cat_list FOR
            SELECT c.id_category,
                   pk_translation.get_translation(i_lang, c.code_category) category,
                   c.flg_type category_type
              FROM category c
             WHERE c.flg_available = pk_alert_constant.g_yes
               AND c.flg_prof = pk_alert_constant.g_yes
               AND c.id_category IN (1, 2)
             ORDER BY category;
        --
    
        OPEN o_screen_labels FOR
            SELECT pk_message.get_message(i_lang, 'TRIALS_T022') screen_header,
                   pk_message.get_message(i_lang, 'TRIALS_T023') viewer_header,
                   pk_message.get_message(i_lang, 'TRIALS_T024') cat_column,
                   pk_message.get_message(i_lang, 'TRIALS_T025') prof_column
              FROM dual;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_prof_list);
            pk_types.open_my_cursor(o_cat_list);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_RESPONSIBLES_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_responsibles_list;
    --

    /**********************************************************************************************
    * Retrieves the list of follow ups for a given patient's trial.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_trials_list            array with the list of Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/01/25
    **********************************************************************************************/
    FUNCTION get_trial_follow_up_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_trial   IN pat_trial.id_pat_trial%TYPE,
        o_follow_up_list OUT pk_types.cursor_type,
        o_screen_labels  OUT pk_types.cursor_type,
        o_trial_desc     OUT trial.name%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_pat_trial:' || i_id_pat_trial || ']',
                                       g_package,
                                       'GET_TRIAL_FOLLOW_UP_LIST');
        --
        o_trial_desc := get_pat_trial_name(i_lang, i_prof, i_id_pat_trial);
    
        g_error := 'OPEN CURSOR o_screen_labels';
        OPEN o_screen_labels FOR
            SELECT pk_message.get_message(i_lang, 'TRIALS_T020') screen_header,
                   pk_message.get_message(i_lang, 'TRIALS_T021') selected
              FROM dual;
    
        g_error := 'OPEN CURSOR o_trials_list';
        OPEN o_follow_up_list FOR
            SELECT ptfu.id_pat_trial_follow_up id_pat_trial_follow_up,
                   pt.id_pat_trial id_pat_trial,
                   ptfu.notes trial_follow_up_notes,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, ptfu.dt_create, i_prof) dt_creation,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ptfu.id_prof_create) prof_creation,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, ptfu.id_prof_create, ptfu.dt_create, NULL) prof_creation_spec,
                   pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                     i_prof,
                                                                     ptfu.dt_record,
                                                                     ptfu.id_prof_record,
                                                                     NULL) last_update_info,
                   ptfu.flg_status
              FROM pat_trial pt
              JOIN pat_trial_follow_up ptfu
                ON pt.id_pat_trial = ptfu.id_pat_trial
             WHERE pt.id_pat_trial = i_id_pat_trial
            --this order is defined in the drawings
             ORDER BY ptfu.dt_create DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_follow_up_list);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIAL_FOLLOW_UP_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_trial_follow_up_list;

    /**********************************************************************************************
    * Create or edit a follow up associated with a given patient internal Trial
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_patient                ID patient
    * @param id_pat_trial_follow_up   ID trial follow up
    * @param i_id_pat_trial           ID pat_trial
    * @param i_follow_up_notes        Follow_up_notes 
    * @param o_id_pat_trial_follow_up Follow up ID for the created follow up 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/02/01
    **********************************************************************************************/
    FUNCTION set_pat_trial_follow_up
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        i_id_pat_trial           IN pat_trial.id_pat_trial%TYPE,
        i_follow_up_notes        IN pat_trial_follow_up.notes%TYPE,
        o_id_pat_trial_follow_up OUT pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out                 table_varchar := table_varchar();
        l_pat_trial_hist_id        pat_trial_hist.id_pat_trial_hist%TYPE;
        l_pat_trial_follow_up_hist pat_trial_follow_up_hist.id_pat_trial_follow_up_h%TYPE;
        l_pat_trial_follow_dt      pat_trial_follow_up.dt_create%TYPE;
        l_pat_trial_follow_id      pat_trial_follow_up.id_prof_create%TYPE;
    
        CURSOR c_pat_trial_hist IS
            SELECT pth.id_pat_trial_hist
              INTO l_pat_trial_hist_id
              FROM pat_trial_hist pth
             WHERE pth.id_pat_trial = i_id_pat_trial
             ORDER BY pth.dt_record DESC;
    
        CURSOR c_pat_follow IS
            SELECT ptf.dt_create, ptf.id_prof_create
              FROM pat_trial_follow_up ptf
             WHERE ptf.id_pat_trial_follow_up = o_id_pat_trial_follow_up;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient: ' || i_id_patient || 'id_pat_trial_follow_up: ' ||
                                       i_id_pat_trial_follow_up || ' ]',
                                       g_package,
                                       'SET_PAT_TRIAL_FOLLOW_UP');
        --
        g_sysdate_tstz := current_timestamp;
    
        IF i_id_pat_trial_follow_up IS NULL
        THEN
            o_id_pat_trial_follow_up := ts_pat_trial_follow_up.next_key;
        ELSE
            o_id_pat_trial_follow_up := i_id_pat_trial_follow_up;
        END IF;
    
        g_error := 'GET_PAT_TRIAL_HIST_ID';
        alertlog.pk_alertlog.log_debug(g_error, g_package, 'SET_PAT_TRIAL_FOLLOW_UP');
    
        OPEN c_pat_trial_hist;
        --get the more recent...
        FETCH c_pat_trial_hist
            INTO l_pat_trial_hist_id;
        CLOSE c_pat_trial_hist;
    
        ts_pat_trial_follow_up.upd_ins(id_pat_trial_follow_up_in => o_id_pat_trial_follow_up,
                                       id_pat_trial_in           => i_id_pat_trial,
                                       id_pat_trial_hist_in      => l_pat_trial_hist_id,
                                       id_episode_record_in      => i_id_episode,
                                       dt_record_in              => g_sysdate_tstz,
                                       id_prof_record_in         => i_prof.id,
                                       dt_create_in              => CASE
                                                                        WHEN i_id_pat_trial_follow_up IS NULL THEN
                                                                         g_sysdate_tstz
                                                                        ELSE
                                                                         NULL
                                                                    END,
                                       id_prof_create_in         => i_prof.id,
                                       flg_status_in             => g_pat_trial_follow_status_a,
                                       notes_in                  => i_follow_up_notes,
                                       rows_out                  => l_rows_out);
    
        alertlog.pk_alertlog.log_debug('CREATE_PAT_TRIAL_FOLLOW_UP: id_pat_trial_follow_up:' ||
                                       o_id_pat_trial_follow_up,
                                       g_package,
                                       'SET_PAT_TRIAL_FOLLOW_UP');
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_TRIAL_FOLLOW_UP',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        OPEN c_pat_follow;
        --get the more recent...
        FETCH c_pat_follow
            INTO l_pat_trial_follow_dt, l_pat_trial_follow_id;
        CLOSE c_pat_follow;
        --Histórico dos follow_ups                              
        ts_pat_trial_follow_up_hist.ins(id_pat_trial_follow_up_in    => o_id_pat_trial_follow_up,
                                        dt_record_in                 => g_sysdate_tstz,
                                        id_prof_record_in            => i_prof.id,
                                        dt_create_in                 => l_pat_trial_follow_dt,
                                        id_prof_create_in            => l_pat_trial_follow_id,
                                        id_episode_record_in         => i_id_episode,
                                        flg_status_in                => g_pat_trial_follow_status_a,
                                        notes_in                     => i_follow_up_notes,
                                        id_pat_trial_follow_up_h_out => l_pat_trial_follow_up_hist,
                                        rows_out                     => l_rows_out);
    
        alertlog.pk_alertlog.log_debug('CREATE_pat_trial_follow_up_hist: o_id_pat_trial_follow_up:' ||
                                       o_id_pat_trial_follow_up,
                                       g_package,
                                       'SET_TRIAL');
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_TRIAL_FOLLOW_UP_HIST',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => i_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
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
                                              i_function => 'SET_PAT_TRIAL_FOLLOW_UP',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_trial_follow_up;
    --

    /**********************************************************************
    * Returns all professionals associated with a given list of categories
    * for an institution
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_categories             array with categories
    * @param i_institution            ID institution 
    * @param o_profs                  list of professionals 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/02/01
    **********************************************************************************************/
    FUNCTION get_cat_prof_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_categories  IN table_number,
        i_institution IN institution.id_institution%TYPE,
        o_profs       OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        OPEN o_profs FOR
            SELECT pc.id_professional,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    profissional(pc.id_professional, NULL, NULL),
                                                    pc.id_professional) prof_name,
                   decode(i_prof.id, pc.id_professional, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_default,
                   c.id_category category
              FROM prof_cat pc
              JOIN category c
                ON c.id_category = pc.id_category
             INNER JOIN prof_institution pi
                ON pc.id_professional = pi.id_professional
               AND pc.id_institution = pi.id_institution
             WHERE pc.id_institution = i_institution
               AND c.id_category IN (SELECT *
                                       FROM TABLE(i_categories))
               AND pi.flg_state = pk_alert_constant.g_active
               AND dt_end_tstz IS NULL
             ORDER BY prof_name DESC;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CAT_PROF_LIST',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_profs);
            RETURN FALSE;
    END get_cat_prof_list;

    /**********************************************************************
    * Returns the number of follow up notes for a patient 
    *
    * @param i_pat_trial              id patient trial
    *
    * @return                         the number of follow up notes 
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION get_count_trial_follow_up(i_pat_trial IN pat_trial.id_pat_trial%TYPE) RETURN NUMBER IS
        l_num_follow NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO l_num_follow
          FROM pat_trial_follow_up ptf
         WHERE ptf.id_pat_trial = i_pat_trial
           AND ptf.flg_status = g_pat_trial_follow_status_a;
        RETURN l_num_follow;
    END get_count_trial_follow_up;

    /**********************************************************************************************
    * Cancel patient trials .
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_pat_trial           ID patient trial
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION cancel_patient_trial
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat_trial  IN pat_trial.id_pat_trial%TYPE,
        i_notes         IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_rows_out           table_varchar := table_varchar();
        l_id_pat_trial_hist  pat_trial_hist.id_pat_trial_hist%TYPE;
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_id_pat_trial:' || i_id_pat_trial || ' ]',
                                       g_package,
                                       'CANCEL_PATIENT_TRIAL');
    
        --insert the cancel details:
        g_sysdate_tstz := current_timestamp;
        --
        pk_alertlog.log_debug('CANCEL_INTERNAL_TRIAL: i_cancel_reason =  ' || i_cancel_reason || ', ');
        ts_cancel_info_det.ins(id_prof_cancel_in      => i_prof.id,
                               id_cancel_reason_in    => i_cancel_reason,
                               dt_cancel_in           => g_sysdate_tstz,
                               notes_cancel_short_in  => i_notes,
                               id_cancel_info_det_out => l_cancel_info_det_id,
                               rows_out               => l_rows_out);
    
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON CANCEL_INFO_DET';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CANCEL_INFO_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL TS_TRIAL.INS';
        ts_pat_trial.upd(id_pat_trial_in       => i_id_pat_trial,
                         flg_status_in         => g_pat_trial_f_status_c,
                         dt_record_in          => g_sysdate_tstz,
                         id_prof_record_in     => i_prof.id,
                         id_cancel_info_det_in => l_cancel_info_det_id,
                         rows_out              => l_rows_out);
    
        alertlog.pk_alertlog.log_debug('UPDATE_PATIENT_TRIAL: id_patient_trial:' || i_id_pat_trial,
                                       g_package,
                                       'CANCEL_PATIENT_TRIAL');
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_TRIAL',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        --Set the history for the trial
    
        IF NOT set_patient_trial_hist(i_lang              => i_lang,
                                      i_prof              => i_prof,
                                      i_id_pat_trial      => i_id_pat_trial,
                                      o_id_pat_trial_hist => l_id_pat_trial_hist,
                                      o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
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
                                              i_function => 'CANCEL_INTERNAL_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_patient_trial;

    /**********************************************************************************************
    * Create the PATIENT trial history (for created or updated records).
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_pat_trial           ID patienttrial
    * @param o_id_pat_trial_hist      ID of the created trial history record
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION set_patient_trial_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_pat_trial      IN pat_trial.id_pat_trial%TYPE,
        o_id_pat_trial_hist OUT pat_trial_hist.id_pat_trial_hist%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_rows_out  table_varchar := table_varchar();
        l_pat_trial pat_trial%ROWTYPE;
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_trial_id: ' || i_id_pat_trial || ' ]',
                                       g_package,
                                       'SET_INTERNAL_TRIAL_HIST');
    
        --
        g_error := 'GET LINE FORM TRIAL TABLE';
        SELECT *
          INTO l_pat_trial
          FROM pat_trial t
         WHERE t.id_pat_trial = i_id_pat_trial;
        o_id_pat_trial_hist := ts_pat_trial_hist.next_key;
        --
        g_error := 'CALL TS_PAT_TRIAL_HIST.INS';
        ts_pat_trial_hist.ins(id_pat_trial_hist_in  => o_id_pat_trial_hist,
                              id_pat_trial_in       => l_pat_trial.id_pat_trial,
                              id_patient_in         => l_pat_trial.id_patient,
                              id_trial_in           => l_pat_trial.id_trial,
                              dt_record_in          => l_pat_trial.dt_record,
                              id_prof_record_in     => l_pat_trial.id_prof_record,
                              dt_trial_begin_in     => l_pat_trial.dt_trial_begin,
                              flg_status_in         => l_pat_trial.flg_status,
                              dt_start_in           => l_pat_trial.dt_start,
                              dt_end_in             => l_pat_trial.dt_end,
                              id_institution_in     => l_pat_trial.id_institution,
                              id_cancel_info_det_in => l_pat_trial.id_cancel_info_det,
                              id_episode_in         => l_pat_trial.id_episode,
                              rows_out              => l_rows_out);
    
        alertlog.pk_alertlog.log_debug('CREATE_PATIENT_TRIAL_HIST: id_trial_hist:' || o_id_pat_trial_hist,
                                       g_package,
                                       'SET_PATIENT_TRIAL_HIST');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PATIENT_TRIAL_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_patient_trial_hist;

    /**********************************************************************
    * Returns if the professional is responsible for trial
    *
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_trial               ID of trial
    *
    * @return                         Y - professional responsible; N - Professioanl not responsaible 
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION check_prof_responsible
    (
        i_prof     IN profissional,
        i_id_trial IN trial.id_trial%TYPE
    ) RETURN VARCHAR2 IS
        l_resp VARCHAR2(1);
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_trial_id:' || i_id_trial || ' ]',
                                       g_package,
                                       'CHECK_PROF_RESPONSIBLE');
    
        --verify if professional is responsible for trial
        g_error := 'GET_TRIAL_RESPONSIBLES';
        SELECT decode(COUNT(tp.id_professional), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_resp
          FROM trial_prof tp
         WHERE tp.id_trial = i_id_trial
           AND tp.id_professional = i_prof.id;
    
        RETURN l_resp;
    
    END check_prof_responsible;

    /**********************************************************************
    * Get patient trial create button available actions.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient                ID patient
    * @param o_actions      actions cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/04
    **********************************************************************************************/
    FUNCTION get_create_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_subject CONSTANT action.subject%TYPE := 'PATIENT_TRIAL_CREATE';
        l_count      PLS_INTEGER := 0;
        l_flg_active VARCHAR2(1 CHAR) := pk_alert_constant.g_inactive;
    
    BEGIN
    
        g_error := 'OPEN o_actions';
        l_count := get_count_trial_resp_patient(i_prof, i_patient);
        OPEN o_actions FOR
            SELECT id_action,
                   pk_message.get_message(i_lang, i_prof, code_action) desc_action, --action's description
                   icon, --action's icon
                   decode(flg_default, 'D', 'Y', 'N') flg_default, --default action
                   decode(l_count,
                          0,
                          decode(internal_name, g_trial_action_internal, pk_alert_constant.g_inactive, flg_status),
                          flg_status) flg_active, --action's state
                   internal_name action
              FROM action a
             WHERE subject = l_subject
             ORDER BY rank, desc_action;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_CREATE_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_create_list;

    /***********************************************************************************************
    * Change status of the participation of the patient on a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param i_flg_status      status of patient trial    
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/04
    **********************************************************************************************/
    FUNCTION set_pat_trial_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN table_number,
        i_flg_status   IN pat_trial.flg_status%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pat_trial_rec   pat_trial%ROWTYPE;
        l_rows_out        table_varchar;
        l_id_patient      patient.id_patient%TYPE;
        l_patient_trial   VARCHAR2(1 CHAR);
        l_patient_trial_b VARCHAR2(1 CHAR);
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[ i_trial_id: ' || pk_utils.concat_table(i_id_pat_trial, ',') ||
                                       ',i_flg_status:' || i_flg_status || '  ]',
                                       g_package,
                                       'SET_PAT_TRIAL_STATUS');
    
        l_patient_trial_b := check_patient_trial(i_prof => i_prof, i_id_patient => l_id_patient);
    
        g_sysdate_tstz := current_timestamp;
        FOR i IN i_id_pat_trial.first .. i_id_pat_trial.last
        LOOP
            g_error := 'GET TAT_TRIAL';
        
            g_error := 'CALL ts_pat_trial.upd';
            ts_pat_trial.upd(id_pat_trial_in        => i_id_pat_trial(i),
                             id_prof_record_in      => i_prof.id,
                             dt_record_in           => g_sysdate_tstz,
                             flg_status_in          => i_flg_status,
                             id_cancel_info_det_in  => NULL,
                             id_cancel_info_det_nin => FALSE,
                             rows_out               => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_TRIAL',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
            SELECT *
              INTO l_pat_trial_rec
              FROM pat_trial
             WHERE id_pat_trial = i_id_pat_trial(i);
        
            l_id_patient := l_pat_trial_rec.id_patient;
        
            l_rows_out := table_varchar();
            ts_pat_trial_hist.ins(id_pat_trial_in       => i_id_pat_trial(i),
                                  id_patient_in         => l_pat_trial_rec.id_patient,
                                  id_trial_in           => l_pat_trial_rec.id_trial,
                                  dt_record_in          => l_pat_trial_rec.dt_record,
                                  id_prof_record_in     => l_pat_trial_rec.id_prof_record,
                                  dt_trial_begin_in     => l_pat_trial_rec.dt_trial_begin,
                                  flg_status_in         => l_pat_trial_rec.flg_status,
                                  dt_start_in           => l_pat_trial_rec.dt_start,
                                  dt_end_in             => l_pat_trial_rec.dt_end,
                                  id_institution_in     => l_pat_trial_rec.id_institution,
                                  id_cancel_info_det_in => l_pat_trial_rec.id_cancel_info_det,
                                  id_episode_in         => l_pat_trial_rec.id_episode,
                                  rows_out              => l_rows_out);
        END LOOP;
        -- Check if patient is on trial
    
        l_patient_trial := check_patient_trial(i_prof => i_prof, i_id_patient => l_id_patient);
    
        -- verify the action
        IF i_flg_status IN (g_pat_trial_f_status_f, g_pat_trial_f_status_d, g_pat_trial_f_status_h)
        THEN
            -- cancelar os agendamentos existentes no ambito dos trials
            IF NOT cancel_scheduled_trial(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_id_patient => l_id_patient,
                                          i_pat_trial  => i_id_pat_trial,
                                          i_flg_status => i_flg_status,
                                          i_notes      => NULL,
                                          o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
            IF l_patient_trial = pk_alert_constant.g_no
            THEN
                pk_ia_event_common.cancel_patient_in_trial(id_patient       => l_id_patient,
                                                           i_id_institution => i_prof.institution);
            END IF;
        
        END IF;
        IF i_flg_status = g_pat_trial_f_status_r
        THEN
            IF l_patient_trial_b = pk_alert_constant.g_no
            THEN
                pk_ia_event_common.cancel_patient_in_trial(id_patient       => l_id_patient,
                                                           i_id_institution => i_prof.institution);
            END IF;
        END IF;
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
        pk_schedule_api_upstream.do_commit(i_prof);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PAT_TRIAL_STATUS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END set_pat_trial_status;

    /**********************************************************************************************
    * Gets the detail of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_trial_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_trial IN trial.id_trial%TYPE,
        o_trial    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_label_trial_name    sys_message.desc_message%TYPE;
        l_label_trial_code    sys_message.desc_message%TYPE;
        l_label_start         sys_message.desc_message%TYPE;
        l_label_end           sys_message.desc_message%TYPE;
        l_label_responsible   sys_message.desc_message%TYPE;
        l_label_contact       sys_message.desc_message%TYPE;
        l_label_status        sys_message.desc_message%TYPE;
        l_label_notes         sys_message.desc_message%TYPE;
        l_label_cancel_reason sys_message.desc_message%TYPE;
        l_label_cancel_notes  sys_message.desc_message%TYPE;
        l_label_documented    sys_message.desc_message%TYPE;
        l_label_no_speciality sys_message.desc_message%TYPE;
        l_label_pharma_code   sys_message.desc_message%TYPE;
        l_label_pharma_name   sys_message.desc_message%TYPE;
    
        l_type_bold   VARCHAR2(1 CHAR);
        l_type_italic VARCHAR2(1 CHAR);
    
    BEGIN
        l_label_trial_name    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T003');
        l_label_trial_code    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T002');
        l_label_start         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T030');
        l_label_end           := pk_message.get_message(i_lang, i_prof, 'TRIALS_T031');
        l_label_responsible   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T007');
        l_label_contact       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T018');
        l_label_status        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T006');
        l_label_notes         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T008');
        l_label_cancel_reason := pk_message.get_message(i_lang, i_prof, 'TRIALS_T015');
        l_label_cancel_notes  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T011');
        l_label_documented    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T032');
        l_label_no_speciality := pk_message.get_message(i_lang, i_prof, 'TRIALS_T033');
        l_label_pharma_code   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T081');
        l_label_pharma_name   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T082');
    
        l_type_bold   := 'B';
        l_type_italic := 'N';
    
        OPEN o_trial FOR
            SELECT table_varchar(l_type_bold, l_label_trial_name, t.name) trial_name,
                   table_varchar(l_type_bold, l_label_trial_code, t.code) trial_code,
                   table_varchar(l_type_bold, l_label_pharma_code, t.pharma_code) pharma_code,
                   table_varchar(l_type_bold, l_label_pharma_name, t.pharma_name) pharma_name,
                   table_varchar(l_type_bold,
                                 l_label_start,
                                 pk_date_utils.date_char_tsz(i_lang, t.dt_start, i_prof.institution, i_prof.software)) dt_start,
                   table_varchar(l_type_bold,
                                 l_label_start,
                                 pk_date_utils.date_char_tsz(i_lang, t.dt_end, i_prof.institution, i_prof.software)) dt_end,
                   table_varchar(l_type_bold,
                                 l_label_responsible,
                                 pk_utils.concat_table(get_trial_resp_name_list(i_lang, i_prof, t.id_trial), ',')) responsibles,
                   table_varchar(l_type_bold, l_label_contact, t.resp_contact_det) trial_contact,
                   table_varchar(l_type_bold,
                                 l_label_status,
                                 pk_sysdomain.get_domain(g_trial_f_status_domain, t.flg_status, i_lang)) status,
                   table_varchar(l_type_bold, l_label_notes, t.notes) notes,
                   table_varchar(l_type_bold,
                                 l_label_cancel_reason,
                                 decode(t.id_cancel_info_det,
                                        NULL,
                                        NULL,
                                        pk_paramedical_prof_core.get_cancel_reason_desc(i_lang,
                                                                                        i_prof,
                                                                                        t.id_cancel_info_det))) cancel_reason,
                   table_varchar(l_type_bold,
                                 l_label_cancel_reason,
                                 decode(t.id_cancel_info_det,
                                        NULL,
                                        NULL,
                                        pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, t.id_cancel_info_det))) cancel_notes,
                   table_varchar(l_type_italic,
                                 l_label_documented,
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_record) || ' (' ||
                                 nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      t.id_prof_record,
                                                                      t.dt_record,
                                                                      NULL),
                                     l_label_no_speciality) || ')' || g_semicolon ||
                                 pk_date_utils.date_char_tsz(i_lang, t.dt_record, i_prof.institution, i_prof.software)) registered
              FROM trial t
             WHERE t.id_trial = i_id_trial;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIAL_DETAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            RETURN FALSE;
        
    END get_trial_detail;

    /**********************************************************************************************
    * Gets the detail history of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_trial_detail_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_trial   IN trial.id_trial%TYPE,
        o_trial      OUT pk_types.cursor_type,
        o_trial_hist OUT table_table_varchar,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_label_trial_name        sys_message.desc_message%TYPE;
        l_label_trial_name_hist   sys_message.desc_message%TYPE;
        l_label_trial_code        sys_message.desc_message%TYPE;
        l_label_trial_code_hist   sys_message.desc_message%TYPE;
        l_label_start             sys_message.desc_message%TYPE;
        l_label_end               sys_message.desc_message%TYPE;
        l_label_responsibles      sys_message.desc_message%TYPE;
        l_label_contact           sys_message.desc_message%TYPE;
        l_label_status            sys_message.desc_message%TYPE;
        l_label_notes             sys_message.desc_message%TYPE;
        l_label_cancel_reason     sys_message.desc_message%TYPE;
        l_label_cancel_notes      sys_message.desc_message%TYPE;
        l_label_documented        sys_message.desc_message%TYPE;
        l_label_no_speciality     sys_message.desc_message%TYPE;
        l_label_start_hist        sys_message.desc_message%TYPE;
        l_label_end_hist          sys_message.desc_message%TYPE;
        l_label_contact_hist      sys_message.desc_message%TYPE;
        l_label_notes_hist        sys_message.desc_message%TYPE;
        l_label_status_hist       sys_message.desc_message%TYPE;
        l_label_responsibles_hist sys_message.desc_message%TYPE;
        l_label_pharma_code       sys_message.desc_message%TYPE;
        l_label_pharma_name       sys_message.desc_message%TYPE;
        l_label_pharma_code_hist  sys_message.desc_message%TYPE;
        l_label_pharma_name_hist  sys_message.desc_message%TYPE;
    
        l_type_bold   VARCHAR2(1 CHAR) := 'B';
        l_type_red    VARCHAR2(1 CHAR) := 'R';
        l_type_italic VARCHAR2(1 CHAR) := 'N';
    
        all_trial_hist pk_types.cursor_type;
    
        t_trial             trial_type;
        trial_dif_table_rec trial_type_dif_table;
        t_trial_previous    trial_type;
        t_trial_first       trial_type;
    
        i             NUMBER := 0;
        first_rec     NUMBER := 0;
        l_counter     NUMBER := 0;
        l_flag_change NUMBER := 0;
        l_na          sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'N/A');
    BEGIN
        l_label_trial_name    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T003');
        l_label_trial_code    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T002');
        l_label_start         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T030');
        l_label_end           := pk_message.get_message(i_lang, i_prof, 'TRIALS_T031');
        l_label_responsibles  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T007');
        l_label_contact       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T018');
        l_label_status        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T006');
        l_label_notes         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T008');
        l_label_cancel_reason := pk_message.get_message(i_lang, i_prof, 'TRIALS_T015');
        l_label_cancel_notes  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T011');
        l_label_documented    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T032');
        l_label_no_speciality := pk_message.get_message(i_lang, i_prof, 'TRIALS_T033');
        l_label_pharma_code   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T081');
        l_label_pharma_name   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T082');
    
        l_label_trial_name_hist   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T034');
        l_label_trial_code_hist   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T035');
        l_label_start_hist        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T036');
        l_label_end_hist          := pk_message.get_message(i_lang, i_prof, 'TRIALS_T037');
        l_label_contact_hist      := pk_message.get_message(i_lang, i_prof, 'TRIALS_T038');
        l_label_notes_hist        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T039');
        l_label_status_hist       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T041');
        l_label_responsibles_hist := pk_message.get_message(i_lang, i_prof, 'TRIALS_T042');
        l_label_pharma_code_hist  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T083');
        l_label_pharma_name_hist  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T084');
    
        l_type_bold   := 'B';
        l_type_italic := 'N';
        o_trial_hist  := table_table_varchar();
        OPEN all_trial_hist FOR
            SELECT th.name,
                   th.code,
                   th.flg_trial_type,
                   pk_date_utils.date_char_tsz(i_lang, th.dt_start, i_prof.institution, i_prof.software) dt_start,
                   pk_date_utils.date_char_tsz(i_lang, th.dt_end, i_prof.institution, i_prof.software) dt_end,
                   pk_utils.concat_table(get_trial_resp_name_hist_list(i_lang, i_prof, th.id_trial_hist), ',') responsibles,
                   th.pharma_code,
                   th.pharma_name,
                   th.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, th.dt_record, i_prof) dt_create,
                   th.resp_contact_det trial_contact,
                   pk_sysdomain.get_domain(g_trial_f_status_domain, th.flg_status, i_lang) status,
                   th.notes,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, th.id_prof_record) || ' (' ||
                   nvl(pk_prof_utils.get_spec_signature(i_lang, i_prof, th.id_prof_record, th.dt_record, NULL),
                       l_label_no_speciality) || ')' || g_semicolon ||
                   pk_date_utils.date_char_tsz(i_lang, th.dt_record, i_prof.institution, i_prof.software) registered,
                   pk_date_utils.date_send_tsz(i_lang, th.dt_record, i_prof) date_record,
                   th.dt_record,
                   decode(th.id_cancel_info_det,
                          NULL,
                          NULL,
                          pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, th.id_cancel_info_det)) cancel_reason,
                   decode(th.id_cancel_info_det,
                          NULL,
                          NULL,
                          pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, th.id_cancel_info_det)) cancel_notes
              FROM trial_hist th
             WHERE th.id_trial = i_id_trial
             ORDER BY dt_record;
    
        -- find differences
        g_error := 'LOOP all_trial_hist';
        LOOP
            FETCH all_trial_hist
                INTO t_trial;
            EXIT WHEN all_trial_hist%NOTFOUND;
        
            IF first_rec = 0
            THEN
                t_trial_first.name          := t_trial.name;
                t_trial_first.code          := t_trial.code;
                t_trial_first.status        := t_trial.status;
                t_trial_first.create_time   := t_trial.create_time;
                t_trial_first.dt_start      := t_trial.dt_start;
                t_trial_first.dt_end        := t_trial.dt_end;
                t_trial_first.responsibles  := t_trial.responsibles;
                t_trial_first.pharma_code   := t_trial.pharma_code;
                t_trial_first.pharma_name   := t_trial.pharma_name;
                t_trial_first.trial_contact := t_trial.trial_contact;
                t_trial_first.notes         := t_trial.notes;
                t_trial_first.registered    := t_trial.registered;
                t_trial_first.dt_record     := t_trial.dt_record;
                t_trial_first.cancel_reason := t_trial.cancel_reason;
                t_trial_first.cancel_notes  := t_trial.cancel_notes;
                first_rec                   := 1;
                i                           := i + 1;
            ELSE
                l_flag_change := 0;
            
                IF (t_trial_previous.name <> t_trial.name)
                   OR (t_trial_previous.name IS NOT NULL AND t_trial.name IS NULL)
                   OR (t_trial_previous.name IS NULL AND t_trial.name IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).name_b := t_trial_previous.name;
                    trial_dif_table_rec(i).name_a := t_trial.name;
                    l_flag_change := 1;
                END IF;
                IF (t_trial_previous.code <> t_trial.code)
                   OR (t_trial_previous.code IS NOT NULL AND t_trial.code IS NULL)
                   OR (t_trial_previous.code IS NULL AND t_trial.code IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).code_b := t_trial_previous.code;
                    trial_dif_table_rec(i).code_a := t_trial.code;
                    l_flag_change := 1;
                END IF;
                IF (t_trial_previous.pharma_code <> t_trial.pharma_code)
                   OR (t_trial_previous.pharma_code IS NOT NULL AND t_trial.pharma_code IS NULL)
                   OR (t_trial_previous.pharma_code IS NULL AND t_trial.pharma_code IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).pharma_code_b := t_trial_previous.pharma_code;
                    trial_dif_table_rec(i).pharma_code_a := t_trial.pharma_code;
                    l_flag_change := 1;
                END IF;
                IF (t_trial_previous.pharma_name <> t_trial.pharma_name)
                   OR (t_trial_previous.pharma_name IS NOT NULL AND t_trial.pharma_name IS NULL)
                   OR (t_trial_previous.pharma_name IS NULL AND t_trial.pharma_name IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).pharma_name_b := t_trial_previous.pharma_name;
                    trial_dif_table_rec(i).pharma_name_a := t_trial.pharma_name;
                    l_flag_change := 1;
                END IF;
                IF (t_trial_previous.responsibles <> t_trial.responsibles)
                   OR (t_trial_previous.responsibles IS NOT NULL AND t_trial.responsibles IS NULL)
                   OR (t_trial_previous.responsibles IS NULL AND t_trial.responsibles IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).responsibles_b := t_trial_previous.responsibles;
                    trial_dif_table_rec(i).responsibles_a := t_trial.responsibles;
                    l_flag_change := 1;
                END IF;
                IF (t_trial_previous.status <> t_trial.status)
                   OR (t_trial_previous.status IS NOT NULL AND t_trial.status IS NULL)
                   OR (t_trial_previous.status IS NULL AND t_trial.status IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).status_b := t_trial_previous.status;
                    trial_dif_table_rec(i).status_a := t_trial.status;
                    l_flag_change := 1;
                END IF;
                IF (t_trial_previous.dt_start <> t_trial.dt_start)
                   OR (t_trial_previous.dt_start IS NOT NULL AND t_trial.dt_start IS NULL)
                   OR (t_trial_previous.dt_start IS NULL AND t_trial.dt_start IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).dt_start_b := t_trial_previous.dt_start;
                    trial_dif_table_rec(i).dt_start_a := t_trial.dt_start;
                    l_flag_change := 1;
                END IF;
                IF (t_trial_previous.dt_end <> t_trial.dt_end)
                   OR (t_trial_previous.dt_end IS NOT NULL AND t_trial.dt_end IS NULL)
                   OR (t_trial_previous.dt_end IS NULL AND t_trial.dt_end IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).dt_end_b := t_trial_previous.dt_end;
                    trial_dif_table_rec(i).dt_end_a := t_trial.dt_end;
                    l_flag_change := 1;
                END IF;
                IF (t_trial_previous.trial_contact <> t_trial.trial_contact)
                   OR (t_trial_previous.trial_contact IS NOT NULL AND t_trial.trial_contact IS NULL)
                   OR (t_trial_previous.trial_contact IS NULL AND t_trial.trial_contact IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).trial_contact_b := t_trial_previous.trial_contact;
                    trial_dif_table_rec(i).trial_contact_a := t_trial.trial_contact;
                    l_flag_change := 1;
                END IF;
                IF (t_trial_previous.notes <> t_trial.notes)
                   OR (t_trial_previous.notes IS NOT NULL AND t_trial.notes IS NULL)
                   OR (t_trial_previous.notes IS NULL AND t_trial.notes IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).notes_b := t_trial_previous.notes;
                    trial_dif_table_rec(i).notes_a := t_trial.notes;
                    l_flag_change := 1;
                END IF;
                IF (t_trial_previous.cancel_reason <> t_trial.cancel_reason)
                   OR (t_trial_previous.cancel_reason IS NOT NULL AND t_trial.cancel_reason IS NULL)
                   OR (t_trial_previous.cancel_reason IS NULL AND t_trial.cancel_reason IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).cancel_reason_b := t_trial_previous.cancel_reason;
                    trial_dif_table_rec(i).cancel_reason_a := t_trial.cancel_reason;
                    l_flag_change := 1;
                END IF;
                IF (t_trial_previous.cancel_notes <> t_trial.cancel_notes)
                   OR (t_trial_previous.cancel_notes IS NOT NULL AND t_trial.cancel_notes IS NULL)
                   OR (t_trial_previous.cancel_notes IS NULL AND t_trial.cancel_notes IS NOT NULL)
                THEN
                    trial_dif_table_rec(i).cancel_notes_b := t_trial_previous.cancel_notes;
                    trial_dif_table_rec(i).cancel_notes_a := t_trial.cancel_notes;
                    l_flag_change := 1;
                END IF;
                IF l_flag_change = 1
                THEN
                    trial_dif_table_rec(i).registered := t_trial.registered;
                    trial_dif_table_rec(i).create_time := t_trial.dt_record;
                    i := i + 1;
                END IF;
            
            END IF;
            t_trial_previous.name          := t_trial.name;
            t_trial_previous.code          := t_trial.code;
            t_trial_previous.pharma_code   := t_trial.pharma_code;
            t_trial_previous.pharma_name   := t_trial.pharma_name;
            t_trial_previous.status        := t_trial.status;
            t_trial_previous.dt_start      := t_trial.dt_start;
            t_trial_previous.dt_end        := t_trial.dt_end;
            t_trial_previous.responsibles  := t_trial.responsibles;
            t_trial_previous.trial_contact := t_trial.trial_contact;
            t_trial_previous.registered    := t_trial.registered;
            t_trial_previous.notes         := t_trial.notes;
            t_trial_previous.dt_record     := t_trial.dt_record;
            t_trial_previous.create_time   := t_trial.create_time;
            t_trial_previous.cancel_reason := t_trial.cancel_reason;
            t_trial_previous.cancel_notes  := t_trial.cancel_notes;
        
        END LOOP;
        CLOSE all_trial_hist;
    
        -- build first history record = creation record    
        g_error := 'OPEN O_TRIAL';
        OPEN o_trial FOR
            SELECT table_varchar(l_type_bold, l_label_trial_name, t_trial_first.name) trial_name,
                   table_varchar(l_type_bold, l_label_trial_code, t_trial_first.code) trial_code,
                   table_varchar(l_type_bold, l_label_pharma_code, t_trial_first.pharma_code) pharma_code,
                   table_varchar(l_type_bold, l_label_pharma_name, t_trial_first.pharma_name) pharma_name,
                   table_varchar(l_type_bold, l_label_start, t_trial_first.dt_start) dt_start,
                   table_varchar(l_type_bold, l_label_end, t_trial_first.dt_end) dt_end,
                   table_varchar(l_type_bold, l_label_responsibles, t_trial_first.responsibles) responsibles,
                   table_varchar(l_type_bold, l_label_contact, t_trial_first.trial_contact) trial_contact,
                   table_varchar(l_type_bold, l_label_status, t_trial_first.status) status,
                   table_varchar(l_type_bold, l_label_notes, t_trial_first.notes) trial_notes,
                   table_varchar(l_type_bold, l_label_cancel_reason, t_trial_first.cancel_reason) cancel_reason,
                   table_varchar(l_type_bold, l_label_cancel_notes, t_trial_first.cancel_notes) cancel_notes,
                   table_varchar(l_type_italic, l_label_documented, t_trial_first.registered) registered
              FROM dual;
    
        -- build before / after history information     
        g_error := 'BUILD O_TRIAL_HIST';
        IF trial_dif_table_rec.count <> 0
        THEN
            o_trial_hist := table_table_varchar(table_varchar(NULL));
        END IF;
        FOR k IN 1 .. trial_dif_table_rec.count
        LOOP
        
            IF trial_dif_table_rec(k).name_b IS NOT NULL
                OR trial_dif_table_rec(k).name_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_trial_name,
                                                             nvl(trial_dif_table_rec(k).name_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_trial_name_hist,
                                                             nvl(trial_dif_table_rec(k).name_a, l_na));
            END IF;
        
            IF trial_dif_table_rec(k).code_b IS NOT NULL
                OR trial_dif_table_rec(k).code_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_trial_code,
                                                             nvl(trial_dif_table_rec(k).code_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_trial_code_hist,
                                                             nvl(trial_dif_table_rec(k).code_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).pharma_code_b IS NOT NULL
                OR trial_dif_table_rec(k).pharma_code_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_pharma_code,
                                                             nvl(trial_dif_table_rec(k).pharma_code_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_pharma_code_hist,
                                                             nvl(trial_dif_table_rec(k).pharma_code_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).pharma_name_b IS NOT NULL
                OR trial_dif_table_rec(k).pharma_name_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_pharma_name,
                                                             nvl(trial_dif_table_rec(k).pharma_name_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_pharma_name_hist,
                                                             nvl(trial_dif_table_rec(k).pharma_name_a, l_na));
            END IF;
        
            IF trial_dif_table_rec(k).status_b IS NOT NULL
                OR trial_dif_table_rec(k).status_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_status,
                                                             nvl(trial_dif_table_rec(k).status_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_status_hist,
                                                             nvl(trial_dif_table_rec(k).status_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).dt_start_b IS NOT NULL
                OR trial_dif_table_rec(k).dt_start_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_start,
                                                             nvl(trial_dif_table_rec(k).dt_start_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_start_hist,
                                                             nvl(trial_dif_table_rec(k).dt_start_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).dt_end_b IS NOT NULL
                OR trial_dif_table_rec(k).dt_end_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_end,
                                                             nvl(trial_dif_table_rec(k).dt_end_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_end_hist,
                                                             nvl(trial_dif_table_rec(k).dt_end_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).responsibles_b IS NOT NULL
                OR trial_dif_table_rec(k).responsibles_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_responsibles,
                                                             nvl(trial_dif_table_rec(k).responsibles_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_responsibles_hist,
                                                             nvl(trial_dif_table_rec(k).responsibles_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).trial_contact_b IS NOT NULL
                OR trial_dif_table_rec(k).trial_contact_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_end,
                                                             nvl(trial_dif_table_rec(k).trial_contact_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_end_hist,
                                                             nvl(trial_dif_table_rec(k).trial_contact_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).notes_b IS NOT NULL
                OR trial_dif_table_rec(k).notes_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_notes,
                                                             nvl(trial_dif_table_rec(k).notes_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_notes_hist,
                                                             nvl(trial_dif_table_rec(k).notes_a, l_na));
            END IF;
        
            IF trial_dif_table_rec(k).cancel_reason_b IS NOT NULL
                OR trial_dif_table_rec(k).cancel_reason_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(1);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_red,
                                                             l_label_cancel_reason,
                                                             nvl(trial_dif_table_rec(k).cancel_reason_a, l_na));
            END IF;
        
            IF trial_dif_table_rec(k).cancel_notes_b IS NOT NULL
                OR trial_dif_table_rec(k).cancel_reason_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(1);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_red,
                                                             l_label_cancel_notes,
                                                             nvl(trial_dif_table_rec(k).cancel_notes_a, l_na));
            END IF;
            l_counter := o_trial_hist.count;
            o_trial_hist.extend(1);
            o_trial_hist(l_counter + 1) := table_varchar(l_type_italic,
                                                         l_label_documented,
                                                         trial_dif_table_rec(k).registered,
                                                         trial_dif_table_rec(k).create_time);
        
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
                                              i_function => 'GET_TRIAL_DETAIL_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            RETURN FALSE;
        
    END get_trial_detail_hist;

    /**********************************************************************************************
    * Gets the detail of a patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_followup      cursor with followup
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/09
    **********************************************************************************************/
    FUNCTION get_pat_trial_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_trial   IN pat_trial.id_pat_trial%TYPE,
        o_trial          OUT pk_types.cursor_type,
        o_followup_title OUT pk_types.cursor_type,
        o_followup       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_label_trial_name         sys_message.desc_message%TYPE;
        l_label_trial_code         sys_message.desc_message%TYPE;
        l_label_start              sys_message.desc_message%TYPE;
        l_label_end                sys_message.desc_message%TYPE;
        l_label_responsible        sys_message.desc_message%TYPE;
        l_label_contact            sys_message.desc_message%TYPE;
        l_label_status             sys_message.desc_message%TYPE;
        l_label_notes              sys_message.desc_message%TYPE;
        l_label_cancel_reason      sys_message.desc_message%TYPE;
        l_label_cancel_notes       sys_message.desc_message%TYPE;
        l_label_documented         sys_message.desc_message%TYPE;
        l_label_no_speciality      sys_message.desc_message%TYPE;
        l_label_follow_up          sys_message.desc_message%TYPE;
        l_label_follow_up_title    sys_message.desc_message%TYPE;
        l_label_hold_reason        sys_message.desc_message%TYPE;
        l_label_hold_notes         sys_message.desc_message%TYPE;
        l_label_discontinue_reason sys_message.desc_message%TYPE;
        l_label_discontinue_notes  sys_message.desc_message%TYPE;
        l_label_pharma_code        sys_message.desc_message%TYPE;
        l_label_pharma_name        sys_message.desc_message%TYPE;
        l_type_bold                VARCHAR2(1 CHAR);
        l_type_italic              VARCHAR2(1 CHAR);
        l_id_trial                 trial.id_trial%TYPE;
    
    BEGIN
        l_label_trial_name         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T003');
        l_label_trial_code         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T002');
        l_label_start              := pk_message.get_message(i_lang, i_prof, 'TRIALS_T030');
        l_label_end                := pk_message.get_message(i_lang, i_prof, 'TRIALS_T031');
        l_label_responsible        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T007');
        l_label_contact            := pk_message.get_message(i_lang, i_prof, 'TRIALS_T018');
        l_label_status             := pk_message.get_message(i_lang, i_prof, 'TRIALS_T006');
        l_label_notes              := pk_message.get_message(i_lang, i_prof, 'TRIALS_T008');
        l_label_cancel_reason      := pk_message.get_message(i_lang, i_prof, 'TRIALS_T015');
        l_label_cancel_notes       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T011');
        l_label_documented         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T032');
        l_label_no_speciality      := pk_message.get_message(i_lang, i_prof, 'TRIALS_T033');
        l_label_follow_up          := pk_message.get_message(i_lang, i_prof, 'TRIALS_T045');
        l_label_follow_up_title    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T020');
        l_label_hold_reason        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T062');
        l_label_hold_notes         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T063');
        l_label_discontinue_reason := pk_message.get_message(i_lang, i_prof, 'TRIALS_T066');
        l_label_discontinue_notes  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T067');
        l_label_pharma_code        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T081');
        l_label_pharma_name        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T082');
    
        l_type_bold   := 'B';
        l_type_italic := 'N';
    
        OPEN o_trial FOR
            SELECT table_varchar(l_type_bold, l_label_trial_name, t.name) trial_name,
                   table_varchar(l_type_bold, l_label_trial_code, t.code) trial_code,
                   table_varchar(l_type_bold, l_label_pharma_code, t.pharma_code) pharma_code,
                   table_varchar(l_type_bold, l_label_pharma_name, t.pharma_name) pharma_name,
                   table_varchar(l_type_bold,
                                 l_label_start,
                                 pk_date_utils.date_char_tsz(i_lang, pt.dt_start, i_prof.institution, i_prof.software)) dt_start,
                   table_varchar(l_type_bold,
                                 l_label_start,
                                 pk_date_utils.date_char_tsz(i_lang, pt.dt_end, i_prof.institution, i_prof.software)) dt_end,
                   table_varchar(l_type_bold,
                                 l_label_responsible,
                                 decode(t.flg_trial_type,
                                        g_trial_f_trial_type_i,
                                        pk_utils.concat_table(get_trial_resp_name_list(i_lang, i_prof, t.id_trial), ','),
                                        t.responsible)) responsibles,
                   table_varchar(l_type_bold, l_label_contact, t.resp_contact_det) trial_contact,
                   table_varchar(l_type_bold,
                                 l_label_status,
                                 pk_sysdomain.get_domain(g_pat_trial_f_status_domain, pt.flg_status, i_lang)) status,
                   table_varchar(l_type_bold, l_label_notes, t.notes) notes,
                   table_varchar(l_type_bold,
                                 decode(pt.flg_status,
                                        g_pat_trial_f_status_d,
                                        l_label_discontinue_reason,
                                        g_pat_trial_f_status_h,
                                        l_label_hold_reason,
                                        l_label_cancel_reason),
                                 decode(pt.id_cancel_info_det,
                                        NULL,
                                        NULL,
                                        pk_paramedical_prof_core.get_cancel_reason_desc(i_lang,
                                                                                        i_prof,
                                                                                        pt.id_cancel_info_det))) cancel_reason,
                   table_varchar(l_type_bold,
                                 decode(pt.flg_status,
                                        g_pat_trial_f_status_d,
                                        l_label_discontinue_notes,
                                        g_pat_trial_f_status_h,
                                        l_label_hold_notes,
                                        l_label_cancel_reason),
                                 decode(pt.id_cancel_info_det,
                                        NULL,
                                        NULL,
                                        pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, pt.id_cancel_info_det))) cancel_notes,
                   table_varchar(l_type_italic,
                                 l_label_documented,
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, pt.id_prof_record) || ' (' ||
                                 nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      pt.id_prof_record,
                                                                      pt.dt_record,
                                                                      NULL),
                                     l_label_no_speciality) || ')' || g_semicolon ||
                                 pk_date_utils.date_char_tsz(i_lang, pt.dt_record, i_prof.institution, i_prof.software)) registered
              FROM pat_trial pt, trial t
             WHERE pt.id_pat_trial = i_id_pat_trial
               AND t.id_trial = pt.id_trial;
    
        g_error := 'GET id_trial';
        SELECT id_trial
          INTO l_id_trial
          FROM pat_trial
         WHERE id_pat_trial = i_id_pat_trial;
    
        IF check_prof_responsible(i_prof => i_prof, i_id_trial => l_id_trial) = pk_alert_constant.g_yes
        THEN
            IF get_count_trial_follow_up(i_id_pat_trial) > 0
            THEN
                OPEN o_followup_title FOR
                    SELECT table_varchar(l_type_bold, l_label_follow_up, '') followup
                      FROM dual;
            ELSE
                pk_types.open_my_cursor(o_followup_title);
            END IF;
            OPEN o_followup FOR
                SELECT table_varchar(l_type_bold, l_label_follow_up, ptfu.notes) followup,
                       table_varchar(l_type_italic,
                                     l_label_documented,
                                     pk_prof_utils.get_name_signature(i_lang, i_prof, ptfu.id_prof_record) || ' (' ||
                                     nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                          i_prof,
                                                                          ptfu.id_prof_record,
                                                                          ptfu.dt_record,
                                                                          NULL),
                                         l_label_no_speciality) || ')' || g_semicolon ||
                                     pk_date_utils.date_char_tsz(i_lang,
                                                                 ptfu.dt_record,
                                                                 i_prof.institution,
                                                                 i_prof.software)) registered
                  FROM pat_trial_follow_up ptfu
                 WHERE ptfu.id_pat_trial = i_id_pat_trial
                   AND ptfu.flg_status = g_pat_trial_follow_status_a;
        ELSE
            pk_types.open_my_cursor(o_followup_title);
            pk_types.open_my_cursor(o_followup);
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
                                              i_function => 'GET_PAT_TRIAL_DETAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_followup);
            RETURN FALSE;
        
    END get_pat_trial_detail;

    /**********************************************************************
    * Returns the number of trials i'am responsible
    *
    * @param i_pat_trial              id patient trial
    *
    * @return                         the number of follow up notes 
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION get_count_trial_responsible(i_prof IN profissional) RETURN NUMBER IS
        l_num_trial NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO l_num_trial
          FROM trial t, trial_prof tp
         WHERE t.id_trial = tp.id_trial
           AND tp.id_professional = i_prof.id;
    
        RETURN l_num_trial;
    END get_count_trial_responsible;

    /**********************************************************************
    * Returns the number of trials i'am responsible and available for patient
    *
    * @param i_pat_trial              id patient trial
    *
    * @return                         the number of follow up notes 
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/04
    **********************************************************************************************/
    FUNCTION get_count_trial_resp_patient
    (
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_num_trial NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO l_num_trial
          FROM trial t, trial_prof tp
         WHERE t.id_trial = tp.id_trial
           AND tp.id_professional = i_prof.id
           AND t.id_institution = i_prof.institution
           AND t.flg_status = g_trial_f_status_a
           AND NOT EXISTS
         (SELECT 1
                  FROM pat_trial pt
                 WHERE pt.id_trial = t.id_trial
                   AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r, g_pat_trial_f_status_h)
                   AND pt.id_patient = i_patient);
    
        RETURN l_num_trial;
    END get_count_trial_resp_patient;
    /**********************************************************************************************
    * Gets the detail history of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial id  PAT trial
    * @param o_trial        trial cursor
    * @param o_followup     follow up notes
    * @param o_trial_hist   trial hist cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_pat_trial_detail_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN trial.id_trial%TYPE,
        o_trial        OUT pk_types.cursor_type,
        o_followup     OUT pk_types.cursor_type,
        o_trial_hist   OUT table_table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_label_trial_name         sys_message.desc_message%TYPE;
        l_label_trial_name_hist    sys_message.desc_message%TYPE;
        l_label_trial_code         sys_message.desc_message%TYPE;
        l_label_trial_code_hist    sys_message.desc_message%TYPE;
        l_label_start              sys_message.desc_message%TYPE;
        l_label_end                sys_message.desc_message%TYPE;
        l_label_responsibles       sys_message.desc_message%TYPE;
        l_label_contact            sys_message.desc_message%TYPE;
        l_label_status             sys_message.desc_message%TYPE;
        l_label_notes              sys_message.desc_message%TYPE;
        l_label_cancel_reason      sys_message.desc_message%TYPE;
        l_label_cancel_notes       sys_message.desc_message%TYPE;
        l_label_documented         sys_message.desc_message%TYPE;
        l_label_no_speciality      sys_message.desc_message%TYPE;
        l_label_start_hist         sys_message.desc_message%TYPE;
        l_label_end_hist           sys_message.desc_message%TYPE;
        l_label_contact_hist       sys_message.desc_message%TYPE;
        l_label_notes_hist         sys_message.desc_message%TYPE;
        l_label_status_hist        sys_message.desc_message%TYPE;
        l_label_responsibles_hist  sys_message.desc_message%TYPE;
        l_label_hold_reason        sys_message.desc_message%TYPE;
        l_label_hold_notes         sys_message.desc_message%TYPE;
        l_label_discontinue_reason sys_message.desc_message%TYPE;
        l_label_discontinue_notes  sys_message.desc_message%TYPE;
        l_label_pharma_code        sys_message.desc_message%TYPE;
        l_label_pharma_name        sys_message.desc_message%TYPE;
        l_label_notes_c            sys_message.desc_message%TYPE;
        l_label_reason_c           sys_message.desc_message%TYPE;
    
        l_type_bold   VARCHAR2(1 CHAR) := 'B';
        l_type_red    VARCHAR2(1 CHAR) := 'R';
        l_type_italic VARCHAR2(1 CHAR) := 'N';
    
        all_trial_hist pk_types.cursor_type;
    
        t_trial                trial_type;
        trial_dif_table_rec    trial_type_dif_table;
        t_trial_previous       trial_type;
        t_trial_first          trial_type;
        t_trial_previous_trial trial_type;
    
        i             NUMBER := 0;
        first_rec     NUMBER := 0;
        l_counter     NUMBER := 0;
        l_flag_change NUMBER := 0;
        l_num         NUMBER := 0;
        l_na          sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'N/A');
        l_flg_type    trial.flg_trial_type%TYPE;
    
    BEGIN
        l_label_trial_name         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T003');
        l_label_trial_code         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T002');
        l_label_start              := pk_message.get_message(i_lang, i_prof, 'TRIALS_T030');
        l_label_end                := pk_message.get_message(i_lang, i_prof, 'TRIALS_T031');
        l_label_responsibles       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T007');
        l_label_contact            := pk_message.get_message(i_lang, i_prof, 'TRIALS_T018');
        l_label_status             := pk_message.get_message(i_lang, i_prof, 'TRIALS_T006');
        l_label_notes              := pk_message.get_message(i_lang, i_prof, 'TRIALS_T008');
        l_label_cancel_reason      := pk_message.get_message(i_lang, i_prof, 'TRIALS_T015');
        l_label_cancel_notes       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T011');
        l_label_documented         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T032');
        l_label_no_speciality      := pk_message.get_message(i_lang, i_prof, 'TRIALS_T033');
        l_label_hold_reason        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T062');
        l_label_hold_notes         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T063');
        l_label_discontinue_reason := pk_message.get_message(i_lang, i_prof, 'TRIALS_T066');
        l_label_discontinue_notes  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T067');
    
        l_label_trial_name_hist   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T034');
        l_label_trial_code_hist   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T035');
        l_label_start_hist        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T036');
        l_label_end_hist          := pk_message.get_message(i_lang, i_prof, 'TRIALS_T037');
        l_label_contact_hist      := pk_message.get_message(i_lang, i_prof, 'TRIALS_T038');
        l_label_notes_hist        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T039');
        l_label_status_hist       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T041');
        l_label_responsibles_hist := pk_message.get_message(i_lang, i_prof, 'TRIALS_T042');
        l_label_pharma_code       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T081');
        l_label_pharma_name       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T082');
    
        l_type_bold   := 'B';
        l_type_italic := 'N';
        o_trial_hist  := table_table_varchar();
    
        g_error := 'GET TRIAL TYPE';
        SELECT t.flg_trial_type
          INTO l_flg_type
          FROM trial t, pat_trial pt
         WHERE pt.id_trial = t.id_trial
           AND pt.id_pat_trial = i_id_pat_trial;
    
        g_error := 'OPEN all_trial_hist';
        OPEN all_trial_hist FOR
            SELECT t.name,
                   t.code,
                   'P' flg_type,
                   pk_date_utils.date_char_tsz(i_lang, pth.dt_start, i_prof.institution, i_prof.software) dt_start,
                   pk_date_utils.date_char_tsz(i_lang, pth.dt_end, i_prof.institution, i_prof.software) dt_end,
                   decode(t.flg_trial_type,
                          g_trial_f_trial_type_i,
                          pk_utils.concat_table(get_trial_resp_name_list(i_lang, i_prof, pth.id_trial), ','),
                          t.responsible) responsibles,
                   t.pharma_code,
                   t.pharma_name,
                   pth.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, pth.dt_record, i_prof) dt_create,
                   t.resp_contact_det trial_contact,
                   pk_sysdomain.get_domain(g_pat_trial_f_status_domain, pth.flg_status, i_lang) status,
                   t.notes,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, pth.id_prof_record) || ' (' ||
                   nvl(pk_prof_utils.get_spec_signature(i_lang, i_prof, pth.id_prof_record, pth.dt_record, NULL),
                       l_label_no_speciality) || ')' || g_semicolon ||
                   pk_date_utils.date_char_tsz(i_lang, pth.dt_record, i_prof.institution, i_prof.software) registered,
                   pk_date_utils.date_send_tsz(i_lang, pth.dt_record, i_prof) date_record,
                   pth.dt_record,
                   decode(pth.id_cancel_info_det,
                          NULL,
                          NULL,
                          pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, pth.id_cancel_info_det)) reason,
                   decode(pth.id_cancel_info_det,
                          NULL,
                          NULL,
                          pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, pth.id_cancel_info_det)) cancel_notes
            
              FROM pat_trial_hist pth, pat_trial pt, trial t
             WHERE pt.id_pat_trial = i_id_pat_trial
               AND pt.id_pat_trial = pth.id_pat_trial
               AND pt.id_trial = t.id_trial
            UNION ALL
            SELECT th.name,
                   th.code,
                   'T' flg_type,
                   pk_date_utils.date_char_tsz(i_lang, th.dt_start, i_prof.institution, i_prof.software) dt_start,
                   pk_date_utils.date_char_tsz(i_lang, th.dt_end, i_prof.institution, i_prof.software) dt_end,
                   th.responsible responsibles,
                   NULL pharma_code,
                   NULL pharma_name,
                   th.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, th.dt_record, i_prof) dt_create,
                   th.resp_contact_det trial_contact,
                   pk_sysdomain.get_domain(g_pat_trial_f_status_domain, th.flg_status, i_lang) status,
                   th.notes,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, th.id_prof_record) || ' (' ||
                   nvl(pk_prof_utils.get_spec_signature(i_lang, i_prof, th.id_prof_record, th.dt_record, NULL),
                       l_label_no_speciality) || ')' || g_semicolon ||
                   pk_date_utils.date_char_tsz(i_lang, th.dt_record, i_prof.institution, i_prof.software) registered,
                   pk_date_utils.date_send_tsz(i_lang, th.dt_record, i_prof) date_record,
                   th.dt_record,
                   decode(th.id_cancel_info_det,
                          NULL,
                          NULL,
                          pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, th.id_cancel_info_det)) reason,
                   decode(th.id_cancel_info_det,
                          NULL,
                          NULL,
                          pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, th.id_cancel_info_det)) cancel_notes
            
              FROM trial_hist th, pat_trial pt, trial t
             WHERE pt.id_pat_trial = i_id_pat_trial
               AND t.id_trial = th.id_trial
               AND pt.id_trial = t.id_trial
               AND t.flg_trial_type = pk_trials.g_trial_f_trial_type_e
             ORDER BY dt_record, flg_type DESC;
    
        -- find differences
        g_error := 'LOOP all_trial_hist';
        LOOP
            FETCH all_trial_hist
                INTO t_trial;
            EXIT WHEN all_trial_hist%NOTFOUND;
            l_num := l_num + 1;
            IF first_rec = 0
            THEN
                t_trial_first.name          := t_trial.name;
                t_trial_first.code          := t_trial.code;
                t_trial_first.status        := t_trial.status;
                t_trial_first.pharma_code   := t_trial.pharma_code;
                t_trial_first.pharma_name   := t_trial.pharma_name;
                t_trial_first.create_time   := t_trial.create_time;
                t_trial_first.dt_start      := t_trial.dt_start;
                t_trial_first.dt_end        := t_trial.dt_end;
                t_trial_first.responsibles  := t_trial.responsibles;
                t_trial_first.trial_contact := t_trial.trial_contact;
                t_trial_first.notes         := t_trial.notes;
                t_trial_first.registered    := t_trial.registered;
                t_trial_first.dt_record     := t_trial.dt_record;
                t_trial_first.cancel_reason := t_trial.cancel_reason;
                t_trial_first.cancel_notes  := t_trial.cancel_notes;
                first_rec                   := 1;
                i                           := i + 1;
            ELSE
                l_flag_change := 0;
                IF t_trial.trial_type = 'T'
                THEN
                    IF (t_trial_previous_trial.name <> t_trial.name)
                       OR (t_trial_previous_trial.name IS NOT NULL AND t_trial.name IS NULL)
                       OR (t_trial_previous_trial.name IS NULL AND t_trial.name IS NOT NULL)
                    THEN
                        trial_dif_table_rec(i).name_b := t_trial_previous_trial.name;
                        trial_dif_table_rec(i).name_a := t_trial.name;
                        l_flag_change := 1;
                    END IF;
                    IF (t_trial_previous_trial.code <> t_trial.code)
                       OR (t_trial_previous_trial.code IS NOT NULL AND t_trial.code IS NULL)
                       OR (t_trial_previous_trial.code IS NULL AND t_trial.code IS NOT NULL)
                    THEN
                        trial_dif_table_rec(i).code_b := t_trial_previous_trial.code;
                        trial_dif_table_rec(i).code_a := t_trial.code;
                        l_flag_change := 1;
                    END IF;
                    IF (t_trial_previous_trial.responsibles <> t_trial.responsibles)
                       OR (t_trial_previous_trial.responsibles IS NOT NULL AND t_trial.responsibles IS NULL)
                       OR (t_trial_previous_trial.responsibles IS NULL AND t_trial.responsibles IS NOT NULL)
                    THEN
                        trial_dif_table_rec(i).responsibles_b := t_trial_previous_trial.responsibles;
                        trial_dif_table_rec(i).responsibles_a := t_trial.responsibles;
                        l_flag_change := 1;
                    END IF;
                    IF (t_trial_previous_trial.trial_contact <> t_trial.trial_contact)
                       OR (t_trial_previous_trial.trial_contact IS NOT NULL AND t_trial.trial_contact IS NULL)
                       OR (t_trial_previous_trial.trial_contact IS NULL AND t_trial.trial_contact IS NOT NULL)
                    THEN
                        trial_dif_table_rec(i).trial_contact_b := t_trial_previous_trial.trial_contact;
                        trial_dif_table_rec(i).trial_contact_a := t_trial.trial_contact;
                        l_flag_change := 1;
                    END IF;
                    IF (t_trial_previous_trial.notes <> t_trial.notes)
                       OR (t_trial_previous_trial.notes IS NOT NULL AND t_trial.notes IS NULL)
                       OR (t_trial_previous_trial.notes IS NULL AND t_trial.notes IS NOT NULL)
                    THEN
                        trial_dif_table_rec(i).notes_b := t_trial_previous_trial.notes;
                        trial_dif_table_rec(i).notes_a := t_trial.notes;
                        l_flag_change := 1;
                    END IF;
                ELSE
                    IF (t_trial_previous.status <> t_trial.status)
                       OR (t_trial_previous.status IS NOT NULL AND t_trial.status IS NULL)
                       OR (t_trial_previous.status IS NULL AND t_trial.status IS NOT NULL)
                    THEN
                        trial_dif_table_rec(i).status_b := t_trial_previous.status;
                        trial_dif_table_rec(i).status_a := t_trial.status;
                        trial_dif_table_rec(i).flg_status_a := t_trial.flg_status;
                        l_flag_change := 1;
                    END IF;
                    IF (t_trial_previous.cancel_reason <> t_trial.cancel_reason)
                       OR (t_trial_previous.cancel_reason IS NOT NULL AND t_trial.cancel_reason IS NULL)
                       OR (t_trial_previous.cancel_reason IS NULL AND t_trial.cancel_reason IS NOT NULL)
                    THEN
                        trial_dif_table_rec(i).cancel_reason_b := t_trial_previous.cancel_reason;
                        trial_dif_table_rec(i).cancel_reason_a := t_trial.cancel_reason;
                        l_flag_change := 1;
                    END IF;
                    IF (t_trial_previous.cancel_notes <> t_trial.cancel_notes)
                       OR (t_trial_previous.cancel_notes IS NOT NULL AND t_trial.cancel_notes IS NULL)
                       OR (t_trial_previous.cancel_notes IS NULL AND t_trial.cancel_notes IS NOT NULL)
                    THEN
                        trial_dif_table_rec(i).cancel_notes_b := t_trial_previous.cancel_notes;
                        trial_dif_table_rec(i).cancel_notes_a := t_trial.cancel_notes;
                        l_flag_change := 1;
                    END IF;
                END IF;
                IF l_flag_change = 1
                THEN
                    trial_dif_table_rec(i).registered := t_trial.registered;
                    trial_dif_table_rec(i).create_time := t_trial.dt_record;
                    i := i + 1;
                END IF;
            
            END IF;
        
            IF l_num = 1
            THEN
                t_trial_previous.name          := t_trial.name;
                t_trial_previous.code          := t_trial.code;
                t_trial_previous.status        := t_trial.status;
                t_trial_previous.flg_status    := t_trial.flg_status;
                t_trial_previous.dt_start      := t_trial.dt_start;
                t_trial_previous.dt_end        := t_trial.dt_end;
                t_trial_previous.responsibles  := t_trial.responsibles;
                t_trial_previous.trial_contact := t_trial.trial_contact;
                t_trial_previous.registered    := t_trial.registered;
                t_trial_previous.notes         := t_trial.notes;
                t_trial_previous.dt_record     := t_trial.dt_record;
                t_trial_previous.create_time   := t_trial.create_time;
                t_trial_previous.cancel_reason := t_trial.cancel_reason;
                t_trial_previous.cancel_notes  := t_trial.cancel_notes;
            
                t_trial_previous_trial.name          := t_trial.name;
                t_trial_previous_trial.code          := t_trial.code;
                t_trial_previous_trial.status        := t_trial.status;
                t_trial_previous_trial.flg_status    := t_trial.flg_status;
                t_trial_previous_trial.dt_start      := t_trial.dt_start;
                t_trial_previous_trial.dt_end        := t_trial.dt_end;
                t_trial_previous_trial.responsibles  := t_trial.responsibles;
                t_trial_previous_trial.trial_contact := t_trial.trial_contact;
                t_trial_previous_trial.registered    := t_trial.registered;
                t_trial_previous_trial.notes         := t_trial.notes;
            ELSIF t_trial.trial_type = 'P'
            
            THEN
                t_trial_previous.name          := t_trial.name;
                t_trial_previous.code          := t_trial.code;
                t_trial_previous.status        := t_trial.status;
                t_trial_previous.flg_status    := t_trial.flg_status;
                t_trial_previous.dt_start      := t_trial.dt_start;
                t_trial_previous.dt_end        := t_trial.dt_end;
                t_trial_previous.responsibles  := t_trial.responsibles;
                t_trial_previous.trial_contact := t_trial.trial_contact;
                t_trial_previous.registered    := t_trial.registered;
                t_trial_previous.notes         := t_trial.notes;
                t_trial_previous.dt_record     := t_trial.dt_record;
                t_trial_previous.create_time   := t_trial.create_time;
                t_trial_previous.cancel_reason := t_trial.cancel_reason;
                t_trial_previous.cancel_notes  := t_trial.cancel_notes;
            ELSIF t_trial.trial_type = 'T'
            THEN
                t_trial_previous_trial.name          := t_trial.name;
                t_trial_previous_trial.code          := t_trial.code;
                t_trial_previous_trial.status        := t_trial.status;
                t_trial_previous_trial.flg_status    := t_trial.flg_status;
                t_trial_previous_trial.dt_start      := t_trial.dt_start;
                t_trial_previous_trial.dt_end        := t_trial.dt_end;
                t_trial_previous_trial.responsibles  := t_trial.responsibles;
                t_trial_previous_trial.trial_contact := t_trial.trial_contact;
                t_trial_previous_trial.registered    := t_trial.registered;
                t_trial_previous_trial.notes         := t_trial.notes;
            
            END IF;
        END LOOP;
        CLOSE all_trial_hist;
    
        -- build first history record = creation record    
        g_error := 'OPEN O_TRIAL';
        OPEN o_trial FOR
            SELECT table_varchar(l_type_bold, l_label_trial_name, t_trial_first.name) trial_name,
                   table_varchar(l_type_bold, l_label_trial_code, t_trial_first.code) trial_code,
                   table_varchar(l_type_bold, l_label_pharma_code, t_trial_first.pharma_code) pharma_code,
                   table_varchar(l_type_bold, l_label_pharma_code, t_trial_first.pharma_name) pharma_nam,
                   table_varchar(l_type_bold, l_label_start, t_trial_first.dt_start) dt_start,
                   table_varchar(l_type_bold, l_label_end, t_trial_first.dt_end) dt_end,
                   table_varchar(l_type_bold, l_label_responsibles, t_trial_first.responsibles) responsibles,
                   table_varchar(l_type_bold, l_label_contact, t_trial_first.trial_contact) trial_contact,
                   table_varchar(l_type_bold, l_label_status, t_trial_first.status) status,
                   table_varchar(l_type_bold, l_label_notes, t_trial_first.notes) trial_notes,
                   table_varchar(l_type_italic, l_label_documented, t_trial_first.registered) registered
              FROM dual;
    
        -- build before / after history information     
        g_error := 'BUILD O_TRIAL_HIST';
        IF trial_dif_table_rec.count <> 0
        THEN
            o_trial_hist := table_table_varchar(table_varchar(NULL));
        END IF;
        FOR k IN 1 .. trial_dif_table_rec.count
        LOOP
        
            IF trial_dif_table_rec(k).name_b IS NOT NULL
                OR trial_dif_table_rec(k).name_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_trial_name,
                                                             nvl(trial_dif_table_rec(k).name_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_trial_name_hist,
                                                             nvl(trial_dif_table_rec(k).name_a, l_na));
            END IF;
        
            IF trial_dif_table_rec(k).code_b IS NOT NULL
                OR trial_dif_table_rec(k).code_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_trial_code,
                                                             nvl(trial_dif_table_rec(k).code_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_trial_code_hist,
                                                             nvl(trial_dif_table_rec(k).code_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).dt_start_b IS NOT NULL
                OR trial_dif_table_rec(k).dt_start_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_start,
                                                             nvl(trial_dif_table_rec(k).dt_start_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_start_hist,
                                                             nvl(trial_dif_table_rec(k).dt_start_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).dt_end_b IS NOT NULL
                OR trial_dif_table_rec(k).dt_end_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_end,
                                                             nvl(trial_dif_table_rec(k).dt_end_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_end_hist,
                                                             nvl(trial_dif_table_rec(k).dt_end_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).responsibles_b IS NOT NULL
                OR trial_dif_table_rec(k).responsibles_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_responsibles,
                                                             nvl(trial_dif_table_rec(k).responsibles_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_responsibles_hist,
                                                             nvl(trial_dif_table_rec(k).responsibles_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).trial_contact_b IS NOT NULL
                OR trial_dif_table_rec(k).trial_contact_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_contact,
                                                             nvl(trial_dif_table_rec(k).trial_contact_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_contact_hist,
                                                             nvl(trial_dif_table_rec(k).trial_contact_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).notes_b IS NOT NULL
                OR trial_dif_table_rec(k).notes_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_notes,
                                                             nvl(trial_dif_table_rec(k).notes_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_notes_hist,
                                                             nvl(trial_dif_table_rec(k).notes_a, l_na));
            END IF;
            IF trial_dif_table_rec(k).status_b IS NOT NULL
                OR trial_dif_table_rec(k).status_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(2);
                o_trial_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                             l_label_status,
                                                             nvl(trial_dif_table_rec(k).status_b, l_na));
                o_trial_hist(l_counter + 2) := table_varchar(l_type_red,
                                                             l_label_status_hist,
                                                             nvl(trial_dif_table_rec(k).status_a, l_na));
            END IF;
        
            IF trial_dif_table_rec(k).cancel_reason_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(1);
                IF trial_dif_table_rec(k).flg_status_a = g_pat_trial_f_status_d
                THEN
                    l_label_reason_c := l_label_discontinue_reason;
                ELSE
                    l_label_reason_c := l_label_hold_reason;
                END IF;
                o_trial_hist(l_counter + 1) := table_varchar(l_type_red,
                                                             l_label_reason_c,
                                                             nvl(trial_dif_table_rec(k).cancel_reason_a, l_na));
            
            END IF;
            IF trial_dif_table_rec(k).cancel_notes_a IS NOT NULL
            THEN
                l_counter := o_trial_hist.count;
                o_trial_hist.extend(1);
            
                IF trial_dif_table_rec(k).flg_status_a = g_pat_trial_f_status_d
                THEN
                    l_label_notes_c := l_label_discontinue_notes;
                ELSE
                    l_label_notes_c := l_label_hold_notes;
                END IF;
                o_trial_hist(l_counter + 1) := table_varchar(l_type_red,
                                                             l_label_notes_c,
                                                             nvl(trial_dif_table_rec(k).cancel_notes_a, l_na));
            
            END IF;
            l_counter := o_trial_hist.count;
            o_trial_hist.extend(1);
            o_trial_hist(l_counter + 1) := table_varchar(l_type_italic,
                                                         l_label_documented,
                                                         trial_dif_table_rec(k).registered,
                                                         trial_dif_table_rec(k).create_time);
        
        END LOOP;
    
        pk_types.open_my_cursor(o_followup);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIAL_DETAIL_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_followup);
            RETURN FALSE;
        
    END get_pat_trial_detail_hist;

    /**********************************************************************************************
     * Gets the detail of a patient trial for viewer
     *
     * @param i_lang         language identifier
     * @param i_prof         logged professional structure
     * @param i_id_trial     id  trial
     * @param o_trial        trial cursor
    * @param o_responsible  cursor with responsibles
     * @param o_error        error
     *
     * @return               false if errors occur, true otherwise
     *
     * @author               Elisabete Bugalho
     * @version              2.6.1
     * @since                2011/02/09
     **********************************************************************************************/
    FUNCTION get_trials_details
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat_trial IN table_number,
        i_type         IN VARCHAR2 DEFAULT 'V',
        o_trial        OUT pk_types.cursor_type,
        o_responsible  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_label_trial_name    sys_message.desc_message%TYPE;
        l_label_trial_code    sys_message.desc_message%TYPE;
        l_label_start         sys_message.desc_message%TYPE;
        l_label_end           sys_message.desc_message%TYPE;
        l_label_responsible   sys_message.desc_message%TYPE;
        l_label_contact       sys_message.desc_message%TYPE;
        l_label_status        sys_message.desc_message%TYPE;
        l_label_notes         sys_message.desc_message%TYPE;
        l_label_cancel_reason sys_message.desc_message%TYPE;
        l_label_cancel_notes  sys_message.desc_message%TYPE;
        l_label_documented    sys_message.desc_message%TYPE;
        l_label_no_speciality sys_message.desc_message%TYPE;
        l_label_title         sys_message.desc_message%TYPE;
        l_label_undergoing    sys_message.desc_message%TYPE;
        l_label_suspended     sys_message.desc_message%TYPE;
        l_label_descontinued  sys_message.desc_message%TYPE;
        l_label_concluded     sys_message.desc_message%TYPE;
        l_lable_no_patients   sys_message.desc_message%TYPE;
        l_label_patient       sys_message.desc_message%TYPE;
        l_label_workphone     sys_message.desc_message%TYPE;
        l_label_cell          sys_message.desc_message%TYPE;
    
        l_type_bold  VARCHAR2(1 CHAR);
        l_type_sub   VARCHAR2(1 CHAR);
        l_type_title VARCHAR2(1 CHAR);
        l_id_trial   trial.id_trial%TYPE;
    
    BEGIN
        l_label_trial_name    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T003');
        l_label_trial_code    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T002');
        l_label_start         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T030');
        l_label_end           := pk_message.get_message(i_lang, i_prof, 'TRIALS_T031');
        l_label_responsible   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T004');
        l_label_contact       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T018');
        l_label_status        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T006');
        l_label_notes         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T008');
        l_label_cancel_reason := pk_message.get_message(i_lang, i_prof, 'TRIALS_T015');
        l_label_cancel_notes  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T011');
        l_label_documented    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T032');
        l_label_no_speciality := pk_message.get_message(i_lang, i_prof, 'TRIALS_T033');
        l_label_title         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T046');
        l_label_undergoing    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T047');
        l_label_suspended     := pk_message.get_message(i_lang, i_prof, 'TRIALS_T048');
        l_label_descontinued  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T049');
        l_label_concluded     := pk_message.get_message(i_lang, i_prof, 'TRIALS_T050');
        l_lable_no_patients   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T051');
        l_label_patient       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T052');
        l_label_workphone     := pk_message.get_message(i_lang, i_prof, 'TRIALS_T054');
        l_label_cell          := pk_message.get_message(i_lang, i_prof, 'TRIALS_T055');
    
        l_type_bold  := 'B';
        l_type_sub   := 'S';
        l_type_title := 'T';
    
        g_error := 'OPEN o_trial';
        IF i_type = 'V'
        THEN
            OPEN o_trial FOR
                SELECT t.id_trial,
                       table_varchar(l_type_title, NULL, l_label_title) title,
                       table_varchar(l_type_bold, l_label_trial_name, t.name) trial_name,
                       table_varchar(l_type_bold, l_label_trial_code, t.code) trial_code,
                       table_varchar(l_type_bold,
                                     l_label_undergoing,
                                     decode(get_count_trial_patients(pt.id_trial,
                                                                     table_varchar(g_pat_trial_f_status_a,
                                                                                   g_pat_trial_f_status_r)),
                                            0,
                                            l_lable_no_patients,
                                            get_count_trial_patients(pt.id_trial,
                                                                     table_varchar(g_pat_trial_f_status_a,
                                                                                   g_pat_trial_f_status_r)) || g_space ||
                                            l_label_patient)) undergoing,
                       table_varchar(l_type_bold,
                                     l_label_suspended,
                                     decode(get_count_trial_patients(pt.id_trial, table_varchar(g_pat_trial_f_status_h)),
                                            0,
                                            l_lable_no_patients,
                                            get_count_trial_patients(pt.id_trial, table_varchar(g_pat_trial_f_status_h)) ||
                                            g_space || l_label_patient)) suspended,
                       table_varchar(l_type_bold,
                                     l_label_descontinued,
                                     decode(get_count_trial_patients(pt.id_trial, table_varchar(g_pat_trial_f_status_d)),
                                            0,
                                            l_lable_no_patients,
                                            get_count_trial_patients(pt.id_trial, table_varchar(g_pat_trial_f_status_d)) ||
                                            g_space || l_label_patient)) descontinued,
                       table_varchar(l_type_bold,
                                     l_label_concluded,
                                     decode(get_count_trial_patients(pt.id_trial, table_varchar(g_pat_trial_f_status_f)),
                                            0,
                                            l_lable_no_patients,
                                            get_count_trial_patients(pt.id_trial, table_varchar(g_pat_trial_f_status_f)) ||
                                            g_space || l_label_patient)) concluded
                  FROM pat_trial pt, trial t
                 WHERE pt.id_pat_trial IN (SELECT *
                                             FROM TABLE(i_id_pat_trial))
                   AND t.id_trial = pt.id_trial;
        ELSE
            OPEN o_trial FOR
                SELECT t.id_trial,
                       table_varchar(l_type_bold, NULL, t.name) trial_name,
                       table_varchar(l_type_bold, NULL, t.code) trial_code
                  FROM pat_trial pt, trial t
                 WHERE pt.id_pat_trial IN (SELECT *
                                             FROM TABLE(i_id_pat_trial))
                   AND t.id_trial = pt.id_trial;
        END IF;
        g_error := 'OPEN o_responsible';
        OPEN o_responsible FOR
            SELECT tr.id_trial,
                   table_varchar(l_type_title, NULL, l_label_responsible) title,
                   table_varchar(l_type_bold,
                                 NULL,
                                 decode(tr.flg_trial_type,
                                        g_trial_f_trial_type_e,
                                        tr.responsible,
                                        pk_prof_utils.get_nickname(i_lang, tr.id_professional))) responsible,
                   table_varchar(l_type_sub,
                                 decode(tr.flg_trial_type, g_trial_f_trial_type_e, l_label_contact, l_label_workphone),
                                 decode(tr.flg_trial_type, g_trial_f_trial_type_e, tr.resp_contact_det, tr.work_phone)) contact_first,
                   table_varchar(l_type_sub,
                                 decode(tr.flg_trial_type, g_trial_f_trial_type_e, NULL, l_label_cell),
                                 decode(tr.flg_trial_type, g_trial_f_trial_type_e, NULL, tr.cell_phone)) contact_second
              FROM (SELECT DISTINCT t.id_trial,
                                    flg_trial_type,
                                    t.responsible,
                                    tp.id_professional,
                                    t.resp_contact_det,
                                    p.work_phone,
                                    p.cell_phone
                    
                      FROM pat_trial pt, trial t, trial_prof tp, professional p
                     WHERE pt.id_pat_trial IN (SELECT *
                                                 FROM TABLE(i_id_pat_trial))
                       AND t.id_trial = pt.id_trial
                       AND t.id_trial = tp.id_trial(+)
                       AND tp.id_professional = p.id_professional(+)) tr;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIALS_DETAILS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_responsible);
        
            RETURN FALSE;
        
    END get_trials_details;

    /**********************************************************************
    * Returns the number of patients on a trial in a determinated status
    *
    * @param i_id_trial              id trial
    *
    * @return                        the number of patient in that status 
    *                        
    * @author                        Elisabete Bugalho
    * @version                       1.0
    * @since                         2011/02/10
    **********************************************************************************************/
    FUNCTION get_count_trial_patients
    (
        i_id_trial IN trial.id_trial%TYPE,
        i_status   IN table_varchar
    ) RETURN NUMBER IS
        l_num_patients NUMBER;
    BEGIN
        SELECT COUNT(1)
          INTO l_num_patients
          FROM pat_trial pt
         WHERE pt.id_trial = i_id_trial
           AND pt.flg_status IN (SELECT *
                                   FROM TABLE(i_status));
        RETURN l_num_patients;
    END get_count_trial_patients;

    /**********************************************************************************************
    * Retrieves the information for a given follow up.
    * If the i_id_pat_trial_follow_up parameter is NULL, the function returns only the labels to be used 
    * in the edit screen.
    *
    * @param i_lang                    the id language
    * @param i_prof                    professional, software and institution ids
    * @param i_id_pat_trial_follow_up  ID follow up to edit, or NULL for follow  creation
    * @param o_follow_up               Information for the follow up to edit
    * @param o_screen_labels           Labels for the edit screen
    * @param o_error                   Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/10
    **********************************************************************************************/
    FUNCTION get_pat_trial_follow_up_edit
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_follow_up              OUT pk_types.cursor_type,
        o_screen_labels          OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_id_pat_trial_follow_up:' || i_id_pat_trial_follow_up || ' ]',
                                       g_package,
                                       'GET_PAT_TRIAL_FOLLOW_UP_EDIT');
    
        g_error := 'OPEN o_screen_labels';
        OPEN o_screen_labels FOR
            SELECT decode(i_id_pat_trial_follow_up,
                          NULL,
                          pk_message.get_message(i_lang, 'TRIALS_T020'),
                          pk_message.get_message(i_lang, 'TRIALS_T053')) screen_header,
                   pk_message.get_message(i_lang, 'TRIALS_T045') followup_note
              FROM dual;
    
        IF i_id_pat_trial_follow_up IS NULL
        THEN
            pk_types.open_my_cursor(o_follow_up);
        ELSE
            g_error := 'OPEN o_follow_up';
            OPEN o_follow_up FOR
                SELECT ptf.id_pat_trial_follow_up, ptf.notes
                  FROM pat_trial_follow_up ptf
                 WHERE ptf.id_pat_trial_follow_up = i_id_pat_trial_follow_up;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_follow_up);
            pk_types.open_my_cursor(o_screen_labels);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PAT_TRIAL_FOLLOW_UP_EDIT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_trial_follow_up_edit;

    /**********************************************************************************************
    * Gets the detail of a patient trial
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pat_trial_follow_up id  pat trial follow up
    * @param o_followup               cursor with followup
    * @param o_error                  error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/10
    **********************************************************************************************/
    FUNCTION get_follow_up_detail
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_followup               OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_label_trial_name    sys_message.desc_message%TYPE;
        l_label_trial_code    sys_message.desc_message%TYPE;
        l_label_start         sys_message.desc_message%TYPE;
        l_label_end           sys_message.desc_message%TYPE;
        l_label_responsible   sys_message.desc_message%TYPE;
        l_label_contact       sys_message.desc_message%TYPE;
        l_label_status        sys_message.desc_message%TYPE;
        l_label_notes         sys_message.desc_message%TYPE;
        l_label_cancel_reason sys_message.desc_message%TYPE;
        l_label_cancel_notes  sys_message.desc_message%TYPE;
        l_label_documented    sys_message.desc_message%TYPE;
        l_label_no_speciality sys_message.desc_message%TYPE;
        l_label_follow_up     sys_message.desc_message%TYPE;
    
        l_type_bold   VARCHAR2(1 CHAR);
        l_type_italic VARCHAR2(1 CHAR);
        l_id_trial    trial.id_trial%TYPE;
    
    BEGIN
        l_label_cancel_reason := pk_message.get_message(i_lang, i_prof, 'TRIALS_T015');
        l_label_cancel_notes  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T011');
        l_label_documented    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T032');
        l_label_no_speciality := pk_message.get_message(i_lang, i_prof, 'TRIALS_T033');
        l_label_follow_up     := pk_message.get_message(i_lang, i_prof, 'TRIALS_T045');
    
        l_type_bold   := 'B';
        l_type_italic := 'N';
    
        OPEN o_followup FOR
            SELECT table_varchar(l_type_bold, l_label_follow_up, ptfu.notes) followup,
                   table_varchar(l_type_bold,
                                 l_label_cancel_reason,
                                 decode(ptfu.id_cancel_info_det,
                                        NULL,
                                        NULL,
                                        pk_paramedical_prof_core.get_cancel_reason_desc(i_lang,
                                                                                        i_prof,
                                                                                        ptfu.id_cancel_info_det))) cancel_reason,
                   table_varchar(l_type_bold,
                                 l_label_cancel_notes,
                                 decode(ptfu.id_cancel_info_det,
                                        NULL,
                                        NULL,
                                        pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, ptfu.id_cancel_info_det))) cancel_notes,
                   table_varchar(l_type_italic,
                                 l_label_documented,
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, ptfu.id_prof_record) || ' (' ||
                                 nvl(pk_prof_utils.get_spec_signature(i_lang,
                                                                      i_prof,
                                                                      ptfu.id_prof_record,
                                                                      ptfu.dt_record,
                                                                      NULL),
                                     l_label_no_speciality) || ')' || g_semicolon ||
                                 pk_date_utils.date_char_tsz(i_lang, ptfu.dt_record, i_prof.institution, i_prof.software)) registered
              FROM pat_trial_follow_up ptfu
             WHERE ptfu.id_pat_trial_follow_up = i_id_pat_trial_follow_up;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_FOLLOW_UP_DETAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_followup);
            RETURN FALSE;
        
    END get_follow_up_detail;

    /**********************************************************************************************
    * Gets the detail history of a trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_trial     id  trial
    * @param o_trial        trial cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/07
    **********************************************************************************************/
    FUNCTION get_followup_det_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_follow_up  IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        o_followup      OUT pk_types.cursor_type,
        o_followup_hist OUT table_table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_label_trial_name        sys_message.desc_message%TYPE;
        l_label_trial_name_hist   sys_message.desc_message%TYPE;
        l_label_trial_code        sys_message.desc_message%TYPE;
        l_label_trial_code_hist   sys_message.desc_message%TYPE;
        l_label_start             sys_message.desc_message%TYPE;
        l_label_end               sys_message.desc_message%TYPE;
        l_label_responsibles      sys_message.desc_message%TYPE;
        l_label_contact           sys_message.desc_message%TYPE;
        l_label_status            sys_message.desc_message%TYPE;
        l_label_notes             sys_message.desc_message%TYPE;
        l_label_cancel_reason     sys_message.desc_message%TYPE;
        l_label_cancel_notes      sys_message.desc_message%TYPE;
        l_label_documented        sys_message.desc_message%TYPE;
        l_label_no_speciality     sys_message.desc_message%TYPE;
        l_label_start_hist        sys_message.desc_message%TYPE;
        l_label_end_hist          sys_message.desc_message%TYPE;
        l_label_contact_hist      sys_message.desc_message%TYPE;
        l_label_notes_hist        sys_message.desc_message%TYPE;
        l_label_status_hist       sys_message.desc_message%TYPE;
        l_label_responsibles_hist sys_message.desc_message%TYPE;
    
        l_type_bold   VARCHAR2(1 CHAR) := 'B';
        l_type_red    VARCHAR2(1 CHAR) := 'R';
        l_type_italic VARCHAR2(1 CHAR) := 'N';
    
        all_followup_hist pk_types.cursor_type;
    
        t_followup           followup_type;
        follow_dif_table_rec followup_type_dif_table;
        t_followup_previous  followup_type;
        t_followup_first     followup_type;
    
        i             NUMBER := 0;
        first_rec     NUMBER := 0;
        l_counter     NUMBER := 0;
        l_flag_change NUMBER := 0;
        l_na          sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'N/A');
    BEGIN
        l_label_trial_name    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T003');
        l_label_trial_code    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T002');
        l_label_start         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T030');
        l_label_end           := pk_message.get_message(i_lang, i_prof, 'TRIALS_T031');
        l_label_responsibles  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T007');
        l_label_contact       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T018');
        l_label_status        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T006');
        l_label_notes         := pk_message.get_message(i_lang, i_prof, 'TRIALS_T008');
        l_label_cancel_reason := pk_message.get_message(i_lang, i_prof, 'TRIALS_T015');
        l_label_cancel_notes  := pk_message.get_message(i_lang, i_prof, 'TRIALS_T011');
        l_label_documented    := pk_message.get_message(i_lang, i_prof, 'TRIALS_T032');
        l_label_no_speciality := pk_message.get_message(i_lang, i_prof, 'TRIALS_T033');
    
        l_label_trial_name_hist   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T034');
        l_label_trial_code_hist   := pk_message.get_message(i_lang, i_prof, 'TRIALS_T035');
        l_label_start_hist        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T036');
        l_label_end_hist          := pk_message.get_message(i_lang, i_prof, 'TRIALS_T037');
        l_label_contact_hist      := pk_message.get_message(i_lang, i_prof, 'TRIALS_T038');
        l_label_notes_hist        := pk_message.get_message(i_lang, i_prof, 'TRIALS_T039');
        l_label_status_hist       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T041');
        l_label_responsibles_hist := pk_message.get_message(i_lang, i_prof, 'TRIALS_T042');
    
        l_type_bold   := 'B';
        l_type_italic := 'N';
    
        o_followup_hist := table_table_varchar();
    
        g_error := 'OPEN all_followup_hist';
        OPEN all_followup_hist FOR
            SELECT ptfh.notes,
                   ptfh.flg_status,
                   pk_date_utils.date_send_tsz(i_lang, ptfh.dt_record, i_prof) dt_create,
                   pk_sysdomain.get_domain(g_follow_up_f_status_domain, ptfh.flg_status, i_lang) status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ptfh.id_prof_record) || ' (' ||
                   nvl(pk_prof_utils.get_spec_signature(i_lang, i_prof, ptfh.id_prof_record, ptfh.dt_record, NULL),
                       l_label_no_speciality) || ')' || g_semicolon ||
                   pk_date_utils.date_char_tsz(i_lang, ptfh.dt_record, i_prof.institution, i_prof.software) registered,
                   ptfh.dt_record,
                   decode(ptfh.id_cancel_info_det,
                          NULL,
                          NULL,
                          pk_paramedical_prof_core.get_cancel_reason_desc(i_lang, i_prof, ptfh.id_cancel_info_det)) cancel_reason,
                   decode(ptfh.id_cancel_info_det,
                          NULL,
                          NULL,
                          pk_paramedical_prof_core.get_notes_desc(i_lang, i_prof, ptfh.id_cancel_info_det)) cancel_notes
              FROM pat_trial_follow_up_hist ptfh
             WHERE ptfh.id_pat_trial_follow_up = i_id_follow_up
             ORDER BY dt_record;
    
        -- find differences
        g_error := 'LOOP all_followup_hist';
        LOOP
            FETCH all_followup_hist
                INTO t_followup;
            EXIT WHEN all_followup_hist%NOTFOUND;
        
            IF first_rec = 0
            THEN
            
                t_followup_first.status        := t_followup.status;
                t_followup_first.notes         := t_followup.notes;
                t_followup_first.registered    := t_followup.registered;
                t_followup_first.dt_record     := t_followup.dt_record;
                t_followup_first.cancel_reason := t_followup.cancel_reason;
                t_followup_first.cancel_notes  := t_followup.cancel_notes;
                first_rec                      := 1;
                i                              := i + 1;
            ELSE
                l_flag_change := 0;
            
                IF (t_followup_previous.status <> t_followup.status)
                   OR (t_followup_previous.status IS NOT NULL AND t_followup.status IS NULL)
                   OR (t_followup_previous.status IS NULL AND t_followup.status IS NOT NULL)
                THEN
                    follow_dif_table_rec(i).status_b := t_followup_previous.status;
                    follow_dif_table_rec(i).status_a := t_followup.status;
                    l_flag_change := 1;
                END IF;
            
                IF (t_followup_previous.notes <> t_followup.notes)
                   OR (t_followup_previous.notes IS NOT NULL AND t_followup.notes IS NULL)
                   OR (t_followup_previous.notes IS NULL AND t_followup.notes IS NOT NULL)
                THEN
                    follow_dif_table_rec(i).notes_b := t_followup_previous.notes;
                    follow_dif_table_rec(i).notes_a := t_followup.notes;
                    l_flag_change := 1;
                END IF;
                IF (t_followup_previous.cancel_reason <> t_followup.cancel_reason)
                   OR (t_followup_previous.cancel_reason IS NOT NULL AND t_followup.cancel_reason IS NULL)
                   OR (t_followup_previous.cancel_reason IS NULL AND t_followup.cancel_reason IS NOT NULL)
                THEN
                    follow_dif_table_rec(i).cancel_reason_b := t_followup_previous.cancel_reason;
                    follow_dif_table_rec(i).cancel_reason_a := t_followup.cancel_reason;
                    l_flag_change := 1;
                END IF;
                IF (t_followup_previous.cancel_notes <> t_followup.cancel_notes)
                   OR (t_followup_previous.cancel_notes IS NOT NULL AND t_followup.cancel_notes IS NULL)
                   OR (t_followup_previous.cancel_notes IS NULL AND t_followup.cancel_notes IS NOT NULL)
                THEN
                    follow_dif_table_rec(i).cancel_notes_b := t_followup_previous.cancel_notes;
                    follow_dif_table_rec(i).cancel_notes_a := t_followup.cancel_notes;
                    l_flag_change := 1;
                END IF;
                IF l_flag_change = 1
                THEN
                    follow_dif_table_rec(i).registered := t_followup.registered;
                    follow_dif_table_rec(i).dt_record := t_followup.dt_record;
                    i := i + 1;
                END IF;
            
            END IF;
            t_followup_previous.status        := t_followup.status;
            t_followup_previous.registered    := t_followup.registered;
            t_followup_previous.notes         := t_followup.notes;
            t_followup_previous.dt_record     := t_followup.dt_record;
            t_followup_previous.cancel_reason := t_followup.cancel_reason;
            t_followup_previous.cancel_notes  := t_followup.cancel_notes;
        
        END LOOP;
        CLOSE all_followup_hist;
    
        -- build first history record = creation record    
        g_error := 'OPEN o_followup';
        OPEN o_followup FOR
            SELECT table_varchar(l_type_bold, l_label_notes, t_followup_first.notes) trial_notes,
                   table_varchar(l_type_bold, l_label_status, t_followup_first.status) status,
                   table_varchar(l_type_bold, l_label_cancel_reason, t_followup_first.cancel_reason) cancel_reason,
                   table_varchar(l_type_bold, l_label_cancel_notes, t_followup_first.cancel_notes) cancel_notes,
                   table_varchar(l_type_italic, l_label_documented, t_followup_first.registered) registered
              FROM dual;
    
        -- build before / after history information     
        g_error := 'BUILD o_followup_hist';
        IF follow_dif_table_rec.count <> 0
        THEN
            o_followup_hist := table_table_varchar(table_varchar(NULL));
        END IF;
        FOR k IN 1 .. follow_dif_table_rec.count
        LOOP
        
            IF follow_dif_table_rec(k).notes_b IS NOT NULL
                OR follow_dif_table_rec(k).notes_a IS NOT NULL
            THEN
                l_counter := o_followup_hist.count;
                o_followup_hist.extend(2);
                o_followup_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                                l_label_notes,
                                                                nvl(follow_dif_table_rec(k).notes_b, l_na));
                o_followup_hist(l_counter + 2) := table_varchar(l_type_red,
                                                                l_label_notes_hist,
                                                                nvl(follow_dif_table_rec(k).notes_a, l_na));
            END IF;
            IF follow_dif_table_rec(k).status_b IS NOT NULL
                OR follow_dif_table_rec(k).status_a IS NOT NULL
            THEN
                l_counter := o_followup_hist.count;
                o_followup_hist.extend(2);
                o_followup_hist(l_counter + 1) := table_varchar(l_type_bold,
                                                                l_label_status,
                                                                nvl(follow_dif_table_rec(k).status_b, l_na));
                o_followup_hist(l_counter + 2) := table_varchar(l_type_red,
                                                                l_label_status_hist,
                                                                nvl(follow_dif_table_rec(k).status_a, l_na));
            END IF;
            IF follow_dif_table_rec(k).cancel_reason_b IS NOT NULL
                OR follow_dif_table_rec(k).cancel_reason_a IS NOT NULL
            THEN
                l_counter := o_followup_hist.count;
                o_followup_hist.extend(1);
                o_followup_hist(l_counter + 1) := table_varchar(l_type_red,
                                                                l_label_cancel_reason,
                                                                nvl(follow_dif_table_rec(k).cancel_reason_a, l_na));
            END IF;
            IF follow_dif_table_rec(k).cancel_notes_b IS NOT NULL
                OR follow_dif_table_rec(k).cancel_notes_a IS NOT NULL
            THEN
                l_counter := o_followup_hist.count;
                o_followup_hist.extend(1);
                o_followup_hist(l_counter + 1) := table_varchar(l_type_red,
                                                                l_label_cancel_notes,
                                                                nvl(follow_dif_table_rec(k).cancel_notes_a, l_na));
            END IF;
        
            l_counter := o_followup_hist.count;
            o_followup_hist.extend(1);
            o_followup_hist(l_counter + 1) := table_varchar(l_type_italic,
                                                            l_label_documented,
                                                            follow_dif_table_rec(k).registered,
                                                            follow_dif_table_rec(k).dt_record);
        
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
                                              i_function => 'GET_FOLLOWUP_DET_HIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_followup);
            RETURN FALSE;
        
    END get_followup_det_hist;

    /**********************************************************************************************
    * Cancel patient follow up trials .
    *
    * @param i_lang                      Id language
    * @param i_prof                      Professional, software and institution ids
    * @param i_id_pat_trial_follow_up    ID Follow up
    * @param i_notes                     Cancel notes
    * @param i_cancel_reason             ID Cancel reason    
    * @param o_error                     Error message
    *
    * @return                            TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/02/10
    **********************************************************************************************/
    FUNCTION cancel_follow_up_trial
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_trial_follow_up IN pat_trial_follow_up.id_pat_trial_follow_up%TYPE,
        i_notes                  IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason          IN cancel_reason.id_cancel_reason%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        --Local Variables
        l_rows_out                 table_varchar := table_varchar();
        l_id_pat_trial_hist        pat_trial_hist.id_pat_trial_hist%TYPE;
        l_cancel_info_det_id       cancel_info_det.id_cancel_info_det%TYPE;
        l_pat_trial_follow_dt      pat_trial_follow_up.dt_create%TYPE;
        l_pat_trial_follow_id      pat_trial_follow_up.id_prof_create%TYPE;
        l_pat_trial_follow_up_hist pat_trial_follow_up_hist.id_pat_trial_follow_up_h%TYPE;
        l_pat_trial_follow_notes   pat_trial_follow_up.notes%TYPE;
        CURSOR c_pat_follow IS
            SELECT ptf.dt_create, ptf.id_prof_create, notes
              FROM pat_trial_follow_up ptf
             WHERE ptf.id_pat_trial_follow_up = i_id_pat_trial_follow_up;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_id_pat_trial_follow_up:' || i_id_pat_trial_follow_up || ' ]',
                                       g_package,
                                       'CANCEL_FOLLOW_UP_TRIAL');
    
        --insert the cancel details:
        g_sysdate_tstz := current_timestamp;
        --
        pk_alertlog.log_debug('CANCEL_FOLLOW_UP_TRIAL: i_cancel_reason =  ' || i_cancel_reason || ', ');
        ts_cancel_info_det.ins(id_prof_cancel_in      => i_prof.id,
                               id_cancel_reason_in    => i_cancel_reason,
                               dt_cancel_in           => g_sysdate_tstz,
                               notes_cancel_short_in  => i_notes,
                               id_cancel_info_det_out => l_cancel_info_det_id,
                               rows_out               => l_rows_out);
    
        g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON CANCEL_INFO_DET';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'CANCEL_INFO_DET',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'CALL TS_PAT_TRIAL_FOLLOW_UP.UPD';
        ts_pat_trial_follow_up.upd(id_pat_trial_follow_up_in => i_id_pat_trial_follow_up,
                                   flg_status_in             => g_pat_trial_follow_status_c,
                                   dt_record_in              => g_sysdate_tstz,
                                   id_prof_record_in         => i_prof.id,
                                   id_cancel_info_det_in     => l_cancel_info_det_id,
                                   rows_out                  => l_rows_out);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'PAT_TRIAL_FOLLOW_UP',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        --Set the history for the trial
        OPEN c_pat_follow;
        --get the more recent...
        FETCH c_pat_follow
            INTO l_pat_trial_follow_dt, l_pat_trial_follow_id, l_pat_trial_follow_notes;
        CLOSE c_pat_follow;
        --Histórico dos follow_ups                              
        ts_pat_trial_follow_up_hist.ins(id_pat_trial_follow_up_in    => i_id_pat_trial_follow_up,
                                        dt_record_in                 => g_sysdate_tstz,
                                        id_prof_record_in            => i_prof.id,
                                        dt_create_in                 => l_pat_trial_follow_dt,
                                        id_prof_create_in            => l_pat_trial_follow_id,
                                        flg_status_in                => g_pat_trial_follow_status_c,
                                        id_cancel_info_det_in        => l_cancel_info_det_id,
                                        notes_in                     => l_pat_trial_follow_notes,
                                        id_pat_trial_follow_up_h_out => l_pat_trial_follow_up_hist,
                                        rows_out                     => l_rows_out);
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
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
                                              i_function => 'CANCEL_FOLLOW_UP_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_follow_up_trial;

    /**********************************************************************************************
    * Get actions for patient trials
    *
    * @param i_lang              Id language
    * @param i_prof              Professional, software and institution ids
    * @param i_subject           Subject of action
    * @param i_from_state        Array of status of trials
    * @param i_pat_trial         Array of patient trials
    * @param o_actions           Cursor with available actions    
    * @param o_error             Error message
    *
    * @return                    TRUE if sucess, FALSE otherwise
    *                        
    * @author                    Elisabete Bugalho
    * @version                   1.0
    * @since                     2011/02/16
    **********************************************************************************************/
    FUNCTION get_actions_permissions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_from_state IN table_varchar,
        i_pat_trial  IN table_number,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_num   NUMBER;
        l_count NUMBER;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[:i_subject:' || i_subject || 'i_from_state:' ||
                                       pk_utils.concat_table(i_from_state) || ' i_pat_trial:' ||
                                       pk_utils.concat_table(i_pat_trial) || '  ]',
                                       g_package,
                                       'GET_ACTIONS_PERMISSIONS');
        l_count := i_pat_trial.count;
        IF i_subject = g_pat_trial_action_i
        THEN
        
            g_error := 'COUNT PROF RESPONSIBLE';
            SELECT COUNT(1)
              INTO l_num
              FROM pat_trial pt, trial t
             WHERE pt.id_trial = t.id_trial
               AND pt.id_pat_trial IN (SELECT *
                                         FROM TABLE(i_pat_trial))
               AND i_prof.id NOT IN (SELECT *
                                       FROM TABLE(get_trial_resp_id_list(i_lang, i_prof, t.id_trial)));
            IF l_num > 0
            THEN
                g_error := 'GET actions all unavailable';
                -- professional not responsible for at least one trial
                IF NOT pk_action.get_actions(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_subject    => i_subject,
                                             i_from_state => g_pat_trial_f_status_f,
                                             o_actions    => o_actions,
                                             o_error      => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSE
                g_error := 'GET actions ';
                OPEN o_actions FOR
                    SELECT MIN(id_action) id_action,
                           id_parent,
                           l AS "LEVEL",
                           to_state,
                           desc_action,
                           icon,
                           flg_default,
                           decode(action,
                                  g_action_internal_i,
                                  decode(l_count, 1, MAX(flg_active), pk_alert_constant.g_inactive),
                                  MAX(flg_active)) flg_active,
                           action,
                           MIN(rank) rank
                      FROM (SELECT id_action,
                                   id_parent,
                                   LEVEL AS l, --used to manage the shown' items by Flash
                                    to_state, --destination state flag
                                    pk_message.get_message(i_lang, i_prof, code_action) desc_action, --action's description
                                   icon, --action's icon
                                    decode(flg_default, 'D', 'Y', 'N') flg_default, --default action
                                    flg_status AS flg_active, --action's state
                                   internal_name action,
                                   rank
                              FROM action a
                             WHERE subject = i_subject
                               AND from_state IN (SELECT *
                                                    FROM TABLE(i_from_state))
                            CONNECT BY PRIOR id_action = id_parent
                             START WITH id_parent IS NULL)
                     GROUP BY id_parent, l, to_state, desc_action, icon, flg_default, action
                     ORDER BY "LEVEL", rank, desc_action;
            END IF;
        ELSE
            g_error := 'GET actions (external)';
            g_error := 'GET actions ';
            OPEN o_actions FOR
                SELECT MIN(id_action) id_action,
                       id_parent,
                       l AS "LEVEL",
                       to_state,
                       desc_action,
                       icon,
                       flg_default,
                       decode(action,
                              g_action_internal_e,
                              decode(l_count, 1, MAX(flg_active), pk_alert_constant.g_inactive),
                              MAX(flg_active)) flg_active,
                       action,
                       MIN(rank) rank
                  FROM (SELECT id_action,
                               id_parent,
                               LEVEL AS l, --used to manage the shown' items by Flash
                                to_state, --destination state flag
                                pk_message.get_message(i_lang, i_prof, code_action) desc_action, --action's description
                               icon, --action's icon
                                decode(flg_default, 'D', 'Y', 'N') flg_default, --default action
                                flg_status AS flg_active, --action's state
                               internal_name action,
                               rank
                          FROM action a
                         WHERE subject = i_subject
                           AND from_state IN (SELECT *
                                                FROM TABLE(i_from_state))
                        CONNECT BY PRIOR id_action = id_parent
                         START WITH id_parent IS NULL)
                 GROUP BY id_parent, l, to_state, desc_action, icon, flg_default, action
                 ORDER BY "LEVEL", rank, desc_action;
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
                                              i_function => 'GET_ACTIONS_PERMISSIONS',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_actions_permissions;

    /***********************************************************************************************
    * Suspend or Descontinue patient trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_trial    id patient trial
    * @param i_flg_status      status of patient trial   
    * @param i_cancel_reason     cancel reason
    * @param i_cancel_notes   cancel notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/15
    **********************************************************************************************/
    FUNCTION set_pat_trial_status_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pat_trial  IN table_number,
        i_flg_status    IN pat_trial.flg_status%TYPE,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes  IN cancel_info_det.notes_cancel_short%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pat_trial_rec      pat_trial%ROWTYPE;
        l_rows_out           table_varchar;
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
        l_id_patient         patient.id_patient%TYPE;
        l_patient_trial      VARCHAR2(1 CHAR);
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[ i_trial_id: ' || pk_utils.concat_table(i_id_pat_trial, ',') ||
                                       ',i_flg_status:' || i_flg_status || '  ]',
                                       g_package,
                                       'SET_PAT_TRIAL_STATUS');
    
        g_sysdate_tstz := current_timestamp;
        pk_alertlog.log_debug('CANCEL_FOLLOW_UP_TRIAL: i_cancel_reason =  ' || i_cancel_reason || ', ');
        ts_cancel_info_det.ins(id_prof_cancel_in      => i_prof.id,
                               id_cancel_reason_in    => i_cancel_reason,
                               dt_cancel_in           => g_sysdate_tstz,
                               notes_cancel_short_in  => i_cancel_notes,
                               id_cancel_info_det_out => l_cancel_info_det_id,
                               rows_out               => l_rows_out);
    
        FOR i IN i_id_pat_trial.first .. i_id_pat_trial.last
        LOOP
            g_error := 'GET TAT_TRIAL';
        
            g_error := 'CALL ts_pat_trial.upd';
            ts_pat_trial.upd(id_pat_trial_in       => i_id_pat_trial(i),
                             id_prof_record_in     => i_prof.id,
                             dt_record_in          => g_sysdate_tstz,
                             flg_status_in         => i_flg_status,
                             id_cancel_info_det_in => l_cancel_info_det_id,
                             rows_out              => l_rows_out);
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_TRIAL',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            SELECT *
              INTO l_pat_trial_rec
              FROM pat_trial
             WHERE id_pat_trial = i_id_pat_trial(i);
        
            l_id_patient := l_pat_trial_rec.id_patient;
        
            l_rows_out := table_varchar();
            ts_pat_trial_hist.ins(id_pat_trial_in       => i_id_pat_trial(i),
                                  id_patient_in         => l_pat_trial_rec.id_patient,
                                  id_trial_in           => l_pat_trial_rec.id_trial,
                                  dt_record_in          => l_pat_trial_rec.dt_record,
                                  id_prof_record_in     => l_pat_trial_rec.id_prof_record,
                                  dt_trial_begin_in     => l_pat_trial_rec.dt_trial_begin,
                                  flg_status_in         => l_pat_trial_rec.flg_status,
                                  dt_start_in           => l_pat_trial_rec.dt_start,
                                  dt_end_in             => l_pat_trial_rec.dt_end,
                                  id_institution_in     => l_pat_trial_rec.id_institution,
                                  id_cancel_info_det_in => l_pat_trial_rec.id_cancel_info_det,
                                  id_episode_in         => l_pat_trial_rec.id_episode,
                                  rows_out              => l_rows_out);
        END LOOP;
    
        -- cancelar os agendamentos existentes no ambito dos trials
        IF i_flg_status IN (g_pat_trial_f_status_f, g_pat_trial_f_status_d, g_pat_trial_f_status_h)
        THEN
            IF NOT cancel_scheduled_trial(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_id_patient => l_id_patient,
                                          i_pat_trial  => i_id_pat_trial,
                                          i_flg_status => i_flg_status,
                                          i_notes      => i_cancel_notes,
                                          o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'CALL pk_visit.set_first_obs';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => NULL,
                                      i_pat                 => NULL,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        END IF;
    
        -- Check if patient is on trial
        l_patient_trial := check_patient_trial(i_prof => i_prof, i_id_patient => l_id_patient);
        IF l_patient_trial = pk_alert_constant.g_no
        THEN
            pk_ia_event_common.cancel_patient_in_trial(id_patient       => l_id_patient,
                                                       i_id_institution => i_prof.institution);
        END IF;
    
        pk_schedule_api_upstream.do_commit(i_prof);
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PAT_TRIAL_STATUS_CANCEL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END set_pat_trial_status_cancel;

    /**********************************************************************************************
    * Gets all patient trials (undergoing)
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   PATIENT ID
    * @param o_trial        trial cursor
    * @param o_responsible  cursor with responsibles
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/16
    **********************************************************************************************/
    FUNCTION get_pat_trials_details
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_type        IN VARCHAR2 DEFAULT 'P',
        o_trial       OUT pk_types.cursor_type,
        o_responsible OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_trials   table_number;
        l_internal sys_config.value%TYPE;
        l_external sys_config.value%TYPE;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient: ' || i_id_patient || 'i_type:' || i_type,
                                       g_package,
                                       'GET_PAT_TRIALS_DETAILS');
    
        IF i_type = 'E'
        THEN
            l_internal := pk_sysconfig.get_config(i_code_cf => g_pat_trial_action_i, i_prof => i_prof);
            l_external := pk_sysconfig.get_config(i_code_cf => g_pat_trial_action_e, i_prof => i_prof);
        
            SELECT pt.id_pat_trial
              BULK COLLECT
              INTO l_trials
              FROM pat_trial pt, trial t
             WHERE pt.id_patient = i_id_patient
               AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r)
               AND pt.id_trial = t.id_trial
               AND ((t.flg_trial_type = pk_trials.g_trial_f_trial_type_i AND l_internal = pk_alert_constant.g_yes) OR
                   (t.flg_trial_type = pk_trials.g_trial_f_trial_type_e AND l_external = pk_alert_constant.g_yes));
        
        ELSE
            SELECT pt.id_pat_trial
              BULK COLLECT
              INTO l_trials
              FROM pat_trial pt
             WHERE pt.id_patient = i_id_patient
               AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r);
        END IF;
    
        g_error := 'CALL get_trials_details';
        IF NOT get_trials_details(i_lang         => i_lang,
                                  i_prof         => i_prof,
                                  i_id_pat_trial => l_trials,
                                  i_type         => i_type,
                                  o_trial        => o_trial,
                                  o_responsible  => o_responsible,
                                  o_error        => o_error)
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
                                              i_function => 'GET_TRIALS_DETAILS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_trial);
            pk_types.open_my_cursor(o_responsible);
        
            RETURN FALSE;
        
    END get_pat_trials_details;

    /**********************************************************************************************
    * Check if a patient is on trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   PATIENT ID
    * @param o_pat_trial    Y - is on trial N - not on trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/16
    **********************************************************************************************/
    FUNCTION check_patient_on_trial
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_pat_trial  OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient: ' || i_id_patient, g_package, 'CHECK_PATIENT_ON_TRIAL');
    
        o_pat_trial := pk_trials.check_patient_trial(i_id_patient => i_id_patient);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIALS_DETAILS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END check_patient_on_trial;

    /**********************************************************************************************
    * Check if a patient is on trial
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_patient   PATIENT ID
    * @param o_pat_trial    Y - is on trial N - not on trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/16
    **********************************************************************************************/
    FUNCTION check_patient_trial_ehr
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_internal  sys_config.value%TYPE;
        l_external  sys_config.value%TYPE;
        l_pat_trial VARCHAR2(1);
        l_error     t_error_out;
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient: ' || i_id_patient, g_package, 'CHECK_PATIENT_TRIAL_EHR');
        g_error    := 'CALL pk_sysconfig.get_config';
        l_internal := pk_sysconfig.get_config(i_code_cf => g_pat_trial_action_i, i_prof => i_prof);
        l_external := pk_sysconfig.get_config(i_code_cf => g_pat_trial_action_e, i_prof => i_prof);
    
        IF l_internal = pk_alert_constant.g_yes
           OR l_external = pk_alert_constant.g_yes
        THEN
        
            SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
              INTO l_pat_trial
              FROM pat_trial pt
              JOIN trial t
                ON pt.id_trial = t.id_trial
             WHERE pt.id_patient = i_id_patient
               AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r)
               AND ((t.flg_trial_type = g_trial_f_trial_type_e AND l_external = pk_alert_constant.g_yes) OR
                   (t.flg_trial_type = g_trial_f_trial_type_i AND l_internal = pk_alert_constant.g_yes));
            RETURN l_pat_trial;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_TRIALS_DETAILS',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
        
    END check_patient_trial_ehr;

    /**********************************************************************************************
    * Check if a patient is on trial
    *
    * @param i_id_patient   PATIENT ID
    * @param o_pat_trial    Y - is on trial N - not on trial
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Elisabete Bugalho
    * @version              2.6.1
    * @since                2011/02/24
    **********************************************************************************************/
    FUNCTION check_patient_trial(i_id_patient IN patient.id_patient%TYPE) RETURN VARCHAR2 IS
        l_error     t_error_out;
        l_pat_trial VARCHAR2(1);
    BEGIN
    
        SELECT decode(COUNT(1), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_pat_trial
          FROM pat_trial pt
         WHERE pt.id_patient = i_id_patient
           AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r);
        RETURN l_pat_trial;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => 1,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'check_patient_trial',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
        
    END check_patient_trial;

    /**********************************************************************************************
    * Retrieves the list of internal Trials undergoing  for a patient 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param o_trials                 array with the list of internal Trials
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/03/18
    **********************************************************************************************/
    FUNCTION get_pat_trials_undergoing
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_trials     OUT t_coll_pat_trial,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient :' || i_id_patient || ']',
                                       g_package,
                                       'GET_PAT_TRIALS_UNDERGOING');
    
        g_error := 'OPEN CURSOR o_trials';
        SELECT t_rec_pat_trial(t.id_trial, t.code, t.name)
          BULK COLLECT
          INTO o_trials
          FROM pat_trial pt
          JOIN trial t
            ON pt.id_trial = t.id_trial
         WHERE pt.id_patient = i_id_patient
           AND t.flg_trial_type = g_trial_f_trial_type_i
           AND t.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r)
        --this order is defined in the drawings
         ORDER BY name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PAT_TRIALS_UNDERGOING',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_trials_undergoing;

    /**********************************************************************************************
    * Cancels a list a schedule for a trial 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param i_pat_trial              list of patien trials
    * @param i_flg_status             status os trials (H / D / F)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/03/18
    **********************************************************************************************/

    FUNCTION cancel_scheduled_trial
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_pat_trial  IN table_number,
        i_flg_status IN pat_trial.flg_status%TYPE,
        i_notes      IN cancel_info_det.notes_cancel_short%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_trial IS
            SELECT id_trial
              FROM pat_trial
             WHERE id_pat_trial IN (SELECT *
                                      FROM TABLE(i_pat_trial));
    
        l_trial table_number;
    
        CURSOR c_scheduled_trial IS
            SELECT s.id_schedule
              FROM episode e, epis_info ei, epis_trial et, schedule s
             WHERE e.id_patient = i_id_patient
               AND e.id_episode = et.id_episode
               AND e.id_episode = ei.id_episode
               AND ei.id_schedule = s.id_schedule
               AND s.flg_status = pk_schedule.g_sched_status_scheduled
               AND et.id_trial IN (SELECT *
                                     FROM TABLE(l_trial));
    
        l_schedule_trial table_number;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient :' || i_id_patient || ', i_flg_status:' || i_flg_status || ']',
                                       g_package,
                                       'CANCEL_SCHEDULED_TRIAL');
    
        g_error := 'OPEN c_trial';
        OPEN c_trial;
        FETCH c_trial BULK COLLECT
            INTO l_trial;
        CLOSE c_trial;
    
        g_error := 'OPEN c_scheduled_trial';
        OPEN c_scheduled_trial;
        FETCH c_scheduled_trial BULK COLLECT
            INTO l_schedule_trial;
        CLOSE c_scheduled_trial;
    
        g_error := 'VERIFY l_schedule_trial';
        IF l_schedule_trial.count > 0
        THEN
            -- fazer chamada à função de cancelamento;
            g_error := 'CALL pk_schedule.cancel_schedule';
        
            IF NOT pk_schedule_api_upstream.cancel_schedules(i_lang                 => i_lang,
                                                        i_prof                 => i_prof,
                                                        i_ids_schedule         => l_schedule_trial,
                                                        i_id_sch_cancel_reason => CASE
                                                                                      WHEN i_flg_status = g_pat_trial_f_status_d THEN
                                                                                       g_sch_reason_discontinue
                                                                                      WHEN i_flg_status = g_pat_trial_f_status_h THEN
                                                                                       g_sch_reason_hold
                                                                                      WHEN i_flg_status = g_pat_trial_f_status_f THEN
                                                                                       g_sch_reason_conclude
                                                                                  END,
                                                        i_cancel_notes         => i_notes,
                                                        o_error                => o_error)
            THEN
                RAISE g_exception;
            END IF;
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
                                              i_function => 'CANCEL_SCHEDULED_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_scheduled_trial;

    /**********************************************************************************************
    * Check if theres is any schedule for a trial  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param i_pat_trial              list of patien trials
    * @param i_flg_status             status os trials (H / D / F / R)
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/03/23
    **********************************************************************************************/

    FUNCTION check_scheduled_trial
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_pat_trial  IN table_number,
        i_flg_status IN pat_trial.flg_status%TYPE,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_buttons    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_trial IS
            SELECT id_trial
              FROM pat_trial
             WHERE id_pat_trial IN (SELECT *
                                      FROM TABLE(i_pat_trial));
    
        l_trial    table_number;
        l_num      NUMBER := 0;
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
    
        CURSOR c_scheduled_trial IS
            SELECT COUNT(1)
              FROM episode e, epis_info ei, epis_trial et, schedule s
             WHERE e.id_patient = i_id_patient
               AND e.id_episode = et.id_episode
               AND e.id_episode = ei.id_episode
               AND ei.id_schedule = s.id_schedule
               AND s.flg_status = pk_schedule.g_sched_status_scheduled
               AND s.dt_begin_tstz > l_dt_begin
               AND et.id_trial IN (SELECT *
                                     FROM TABLE(l_trial));
    
    BEGIN
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient :' || i_id_patient || ', i_flg_status:' || i_flg_status || ']',
                                       g_package,
                                       'CHECK_SCHEDULED_TRIAL');
    
        l_dt_begin := current_timestamp;
        o_flg_show := pk_alert_constant.g_yes;
        o_buttons  := 'NC';
        g_error    := 'OPEN c_trial';
        IF i_flg_status IN (g_pat_trial_f_status_f, g_pat_trial_f_status_d, g_pat_trial_f_status_h)
        THEN
            OPEN c_trial;
            FETCH c_trial BULK COLLECT
                INTO l_trial;
            CLOSE c_trial;
        
            g_error := 'OPEN c_scheduled_trial';
            OPEN c_scheduled_trial;
            FETCH c_scheduled_trial
                INTO l_num;
            CLOSE c_scheduled_trial;
        
        END IF;
        g_error := 'I_FLG_STATUS';
        IF i_flg_status = g_pat_trial_f_status_f
        THEN
            o_msg_title := pk_message.get_message(i_lang, i_prof, 'TRIALS_T071');
            o_msg       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T072');
        ELSIF i_flg_status = g_pat_trial_f_status_d
        THEN
            o_msg_title := pk_message.get_message(i_lang, i_prof, 'TRIALS_T069');
            o_msg       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T064');
        ELSIF i_flg_status = g_pat_trial_f_status_h
        THEN
            o_msg_title := pk_message.get_message(i_lang, i_prof, 'TRIALS_T070');
            o_msg       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T060');
        ELSIF i_flg_status = g_pat_trial_f_status_r
        THEN
            o_msg_title := pk_message.get_message(i_lang, i_prof, 'TRIALS_T073');
            o_msg       := pk_message.get_message(i_lang, i_prof, 'TRIALS_T074');
        END IF;
        g_error := 'VERIFY l_schedule_trial';
        IF l_num > 0
        THEN
            o_msg := o_msg || '<BR><BR>' || pk_message.get_message(i_lang, i_prof, 'TRIALS_T085');
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
                                              i_function => 'CHECK_SCHEDULED_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END check_scheduled_trial;

    /**********************************************************************************************
    * Sets an shcedule/episode for a specific trial 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param i_id_episode             ID Episode
    * @param i_id_trial               ID trial
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/03/30
    **********************************************************************************************/

    FUNCTION set_scheduled_trial
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_trial   IN trial.id_trial%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows table_varchar;
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient :' || i_id_patient || ', i_id_episode:' || i_id_episode ||
                                       ', i_id_trial:' || i_id_trial || ']',
                                       g_package,
                                       'SET_SCHEDULED_TRIAL');
    
        g_error := 'CALL ts_epis_trial.ins';
        ts_epis_trial.ins(id_episode_in     => i_id_episode,
                          id_trial_in       => i_id_trial,
                          id_prof_create_in => i_prof.id,
                          dt_create_in      => current_timestamp,
                          rows_out          => l_rows);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_SCHEDULED_TRIAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_scheduled_trial;

    FUNCTION check_diso_trial
    (
        i_id_trial   IN trial.id_trial%TYPE,
        i_flg_status trial.flg_status%TYPE
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
        l_num   NUMBER;
    BEGIN
        IF i_flg_status = g_trial_f_status_a
        THEN
            SELECT COUNT(1)
              INTO l_num
              FROM pat_trial pt
             WHERE id_trial = i_id_trial
               AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_r, g_pat_trial_f_status_h);
            IF l_num > 0
            THEN
                RETURN pk_alert_constant.g_yes;
            END IF;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN pk_alert_constant.g_no;
    END;

    /**********************************************************************************************
    * Match the patient trial 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_patient             ID Patient
    * @param i_id_patient_temp        ID Patient
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/28
    **********************************************************************************************/

    FUNCTION set_match_pat_trial
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_patient_temp IN patient.id_patient%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids            table_varchar;
        l_count             NUMBER;
        l_id_pat_trial      pat_trial.id_pat_trial%TYPE;
        l_id_pat_trial_hist pat_trial_hist.id_pat_trial_hist%TYPE;
        l_count_patient     NUMBER;
    
    BEGIN
    
        alertlog.pk_alertlog.log_debug('PARAMS[ i_id_patient :' || i_id_patient || ', i_id_patient_temp:' ||
                                       i_id_patient_temp || ']',
                                       g_package,
                                       'SET_MATCH_PAT_TRIAL');
        SELECT COUNT(1)
          INTO l_count_patient
          FROM pat_trial pt
         WHERE pt.id_patient IN (i_id_patient, i_id_patient_temp);
        --  AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_h, g_pat_trial_f_status_r)
    
        IF l_count_patient = 0
        THEN
            alertlog.pk_alertlog.log_debug('NO TRIALS FOR PATIENT', g_package, 'SET_MATCH_PAT_TRIAL');
            RETURN TRUE;
        END IF;
    
        g_error := 'COUNT id_pat_trial';
        BEGIN
            SELECT COUNT(pt.id_pat_trial) AS id_pat_trial
              INTO l_count
              FROM pat_trial pt
             WHERE pt.id_patient IN (i_id_patient, i_id_patient_temp)
               AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_h, g_pat_trial_f_status_r)
             GROUP BY id_trial
            HAVING COUNT(id_pat_trial) > 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_count := 0;
        END;
        IF l_count > 0 -- existe o mesmo trial nos dois pacientes
        THEN
            alertlog.pk_alertlog.log_debug('ACTIVE TRIAL FOR BOTH PATIENTS', g_package, 'SET_MATCH_PAT_TRIAL');
        
            g_error := 'LOOP TRIAL';
            FOR rec IN (SELECT MIN(pt.id_trial) AS id_trial
                          FROM pat_trial pt
                         WHERE pt.id_patient IN (i_id_patient, i_id_patient_temp)
                           AND pt.flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_h, g_pat_trial_f_status_r)
                         GROUP BY id_trial
                        HAVING COUNT(id_trial) > 1)
            LOOP
            
                g_error  := 'UPDATE PAT_TRIAL';
                l_rowids := table_varchar();
            
                -- descontinuar o trial do paciente temporário
                UPDATE pat_trial
                   SET id_patient = i_id_patient, flg_status = g_pat_trial_f_status_d
                 WHERE id_patient = i_id_patient_temp
                   AND id_trial = rec.id_trial
                   AND flg_status IN (g_pat_trial_f_status_a, g_pat_trial_f_status_h, g_pat_trial_f_status_r)
                RETURNING id_pat_trial INTO l_id_pat_trial;
            
                g_error := 'PAT_TRIAL_HIST';
            
                IF NOT set_patient_trial_hist(i_lang              => i_lang,
                                              i_prof              => i_prof,
                                              i_id_pat_trial      => l_id_pat_trial,
                                              o_id_pat_trial_hist => l_id_pat_trial_hist,
                                              o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END LOOP;
        END IF;
    
        alertlog.pk_alertlog.log_debug('CHANGE PATIENT TRIAL', g_package, 'SET_MATCH_PAT_TRIAL');
    
        g_error  := 'PAT_TRIAL';
        l_rowids := table_varchar();
        ts_pat_trial.upd(id_patient_in  => i_id_patient,
                         id_patient_nin => FALSE,
                         where_in       => ' ID_PATIENT = ' || i_id_patient_temp,
                         rows_out       => l_rowids);
        g_error := ' PROCESS_UPDATE PAT_TRIAL';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_TRIAL',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
        g_error  := 'PAT_TRIAL_HIST';
        l_rowids := table_varchar();
        ts_pat_trial_hist.upd(id_patient_in  => i_id_patient,
                              id_patient_nin => FALSE,
                              where_in       => ' ID_PATIENT = ' || i_id_patient_temp,
                              rows_out       => l_rowids);
        g_error := ' PROCESS_UPDATE PAT_TRIAL_HIST';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'PAT_TRIAL_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PATIENT'));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_MATCH_PAT_TRIAL',
                                              o_error    => o_error);
            --      pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_match_pat_trial;
    /**********************************************************************************************
    * Delete all trials by episode 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_episode             ID Episode
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Jorge Silva
    * @version                        1.0
    * @since                          2014/04/01
    **********************************************************************************************/

    FUNCTION delete_trials_by_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient_trial VARCHAR2(1 CHAR);
    
        l_patient     patient.id_patient%TYPE;
        l_tbl_patient table_number;
        l_aux         table_number;
    
    BEGIN
        l_tbl_patient := table_number();
    
        DELETE pat_trial_follow_up_hist ptfuh
         WHERE EXISTS (SELECT 1
                  FROM pat_trial_follow_up ptfu
                 WHERE ptfuh.id_pat_trial_follow_up = ptfu.id_pat_trial_follow_up
                   AND EXISTS (SELECT 1
                          FROM pat_trial pt
                         WHERE pt.id_pat_trial = ptfu.id_pat_trial
                           AND pt.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                                  column_value
                                                   FROM TABLE(i_id_episode) epis)));
    
        DELETE pat_trial_follow_up ptfu
         WHERE EXISTS (SELECT 1
                  FROM pat_trial pt
                 WHERE pt.id_pat_trial = ptfu.id_pat_trial
                   AND pt.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                          column_value
                                           FROM TABLE(i_id_episode) epis));
    
        DELETE pat_trial_hist pth
         WHERE pth.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                   column_value
                                    FROM TABLE(i_id_episode) epis);
    
        DELETE pat_trial pt
         WHERE pt.id_episode IN (SELECT /*+ OPT_ESTIMATE(table epis rows = 1)*/
                                  column_value
                                   FROM TABLE(i_id_episode) epis)
        RETURNING pt.id_patient BULK COLLECT INTO l_aux;
    
        l_tbl_patient := l_tbl_patient MULTISET UNION DISTINCT l_aux;
    
        FOR rec IN (SELECT DISTINCT column_value id_patient
                      FROM TABLE(l_tbl_patient))
        LOOP
            l_patient_trial := check_patient_trial(i_prof => i_prof, i_id_patient => rec.id_patient);
        
            IF l_patient_trial = pk_alert_constant.g_no
            THEN
                pk_ia_event_common.cancel_patient_in_trial(id_patient       => rec.id_patient,
                                                           i_id_institution => i_prof.institution);
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
                                              i_function => 'DELETE_TRIALS_BY_EPISODE',
                                              o_error    => o_error);
            -- pk_alert_exceptions.reset_error_state; 
            RETURN FALSE;
        
    END delete_trials_by_episode;

/*
    FUNCTION delete_trials_by_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_patient_trial VARCHAR2(1 CHAR);
    
    BEGIN
    
        DELETE pat_trial_hist pth
         WHERE pth.id_episode IN (SELECT *
                                    FROM TABLE(i_id_episode));
    
        DELETE pat_trial pt
         WHERE pt.id_episode IN (SELECT *
                                   FROM TABLE(i_id_episode));
    
        l_patient_trial := check_patient_trial(i_prof => i_prof, i_id_patient => i_id_patient);
    
        IF l_patient_trial = pk_alert_constant.g_no
        THEN
            pk_ia_event_common.cancel_patient_in_trial(id_patient       => i_id_patient,
                                                       i_id_institution => i_prof.institution);
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
                                              i_function => 'DELETE_TRIALS_BY_EPISODE',
                                              o_error    => o_error);
            --      pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END delete_trials_by_episode;*/

BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_trials;
/
