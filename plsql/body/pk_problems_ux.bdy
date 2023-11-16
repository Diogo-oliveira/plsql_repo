/*-- Last Change Revision: $Rev: 1854211 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2018-07-13 12:04:09 +0100 (sex, 13 jul 2018) $*/
CREATE OR REPLACE PACKAGE BODY pk_problems_ux IS
    /**
    * Registers a review for a problem.
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_id_pat_problem  problem id
    * @param i_flg_source      FLAG SOURCE
    * @param i_review_notes    review notes (optional)
    * @param i_EPISODE         episode identifier
    * @param I_FLG_AUTO        FLAG AUTO Y/N
    *
    * @param o_error           error message 
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION set_pat_problem_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_problem IN table_number,
        i_flg_source     IN table_varchar,
        i_review_notes   IN review_detail.review_notes%TYPE DEFAULT NULL,
        i_episode        IN review_detail.id_episode%TYPE,
        i_flg_auto       IN review_detail.flg_auto%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'set_pat_problem_review';
    BEGIN
    
        IF NOT pk_problems.set_pat_problem_review(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_id_pat_problem => i_id_pat_problem,
                                                  i_flg_source     => i_flg_source,
                                                  i_review_notes   => i_review_notes,
                                                  i_episode        => i_episode,
                                                  i_flg_auto       => i_flg_auto,
                                                  o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_problem_review;
    /********************************************************************************************
    * Returns history of status and nature changes on a problem
    * Based on the old PK_PROBLEMS.GET_PAT_PROBLEM_DET function but refering to the pat_history_diagnosis table.
    *
    * @param i_lang                   Language ID
    * @param i_pat_prob               Problem ID
    * @param i_type                   Type of records wanted (P - problems, A - alergies)
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_problem                Cursor containing the original problem
    * @param o_problem_hist           table_table_varchar containing the problem's changes
    * @param o_review_hist            cursor containing review list
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION get_pat_problem_det_new_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_pat_problem_det_new_hist';
    BEGIN
    
        IF NOT pk_problems.get_pat_problem_det_new_hist(i_lang         => i_lang,
                                                        i_pat_prob     => i_pat_prob,
                                                        i_type         => i_type,
                                                        i_prof         => i_prof,
                                                        o_problem      => o_problem,
                                                        o_problem_hist => o_problem_hist,
                                                        o_review_hist  => o_review_hist,
                                                        o_error        => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_problem);
            pk_types.open_my_cursor(o_review_hist);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_problem_det_new_hist;

    FUNCTION get_pat_problem_det_new_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_problem_view IN VARCHAR2,
        o_problem      OUT pk_types.cursor_type,
        o_problem_hist OUT table_table_varchar,
        o_review_hist  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_pat_problem_det_new_hist';
    BEGIN
    
        IF NOT pk_problems.get_pat_problem_det_new_hist(i_lang         => i_lang,
                                                        i_pat_prob     => i_pat_prob,
                                                        i_type         => i_type,
                                                        i_prof         => i_prof,
                                                        i_problem_view => i_problem_view,
                                                        o_problem      => o_problem,
                                                        o_problem_hist => o_problem_hist,
                                                        o_review_hist  => o_review_hist,
                                                        o_error        => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_problem);
            pk_types.open_my_cursor(o_review_hist);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_problem_det_new_hist;

    /********************************************************************************************
    * Get problem detail
    *
    * @param i_lang                   Language ID
    * @param i_pat_prob               probblem identifier
    * @param i_type                   Patient ID
    * @param i_prof                   object (professional ID, institution ID, software ID)
    * @param i_flg_area               Parameter exists only for audit-trail purposes
    * @param o_problem                out cursor
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION get_pat_problem_det
    (
        i_lang     IN language.id_language%TYPE,
        i_pat_prob IN pat_problem.id_pat_problem%TYPE,
        i_type     IN VARCHAR2,
        i_prof     IN profissional,
        i_flg_area IN pat_history_diagnosis.flg_area%TYPE,
        o_problem  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_pat_problem_det';
    BEGIN
    
        IF NOT pk_problems.get_pat_problem_det(i_lang     => i_lang,
                                               i_pat_prob => i_pat_prob,
                                               i_type     => i_type,
                                               i_prof     => i_prof,
                                               o_problem  => o_problem,
                                               o_error    => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_problem);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_problem_det;

    FUNCTION get_pat_problem_det
    (
        i_lang         IN language.id_language%TYPE,
        i_pat_prob     IN pat_problem.id_pat_problem%TYPE,
        i_type         IN VARCHAR2,
        i_prof         IN profissional,
        i_flg_area     IN pat_history_diagnosis.flg_area%TYPE,
        i_problem_view IN VARCHAR2,
        o_problem      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_pat_problem_det';
    BEGIN
    
        IF NOT pk_problems.get_pat_problem_det(i_lang         => i_lang,
                                               i_pat_prob     => i_pat_prob,
                                               i_type         => i_type,
                                               i_prof         => i_prof,
                                               i_problem_view => i_problem_view,
                                               o_problem      => o_problem,
                                               o_error        => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_problem);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_problem_det;

    /********************************************************************************************
    * Cancels a specific problem in the Problems functionality
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat                    Patient ID
    * @param i_id_episode             Episode ID
    * @param i_id_problem             The problem ID 
    * @param i_type                   Type of problem 
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes
    * @param i_prof_cat_type          Professional category flag
    * @param i_flg_area               Parameter exists only for audit-trail purposes
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION cancel_pat_problem
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_pat              IN pat_problem.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_problem       IN NUMBER,
        i_type             IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_problem_hist.cancel_notes%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_flg_area         IN pat_history_diagnosis.flg_area%TYPE,
        o_type             OUT table_varchar,
        o_ids              OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'cancel_pat_problem';
    BEGIN
    
        IF NOT pk_problems.cancel_pat_problem(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_pat              => i_pat,
                                              i_id_episode       => i_id_episode,
                                              i_id_problem       => i_id_problem,
                                              i_type             => i_type,
                                              i_id_cancel_reason => i_id_cancel_reason,
                                              i_cancel_notes     => i_cancel_notes,
                                              i_prof_cat_type    => i_prof_cat_type,
                                              o_type             => o_type,
                                              o_ids              => o_ids,
                                              o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_pat_problem;
    /********************************************************************************************
    * get_pat_problem_report
    *
    * @param i_lang                   Language ID
    * @param i_pat                    Patient ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode 
    * @param i_report
    * @param o_pat_problem            Cursor containing the problems
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/

    FUNCTION get_pat_problem_report
    (
        i_lang                 IN language.id_language%TYPE,
        i_pat                  IN pat_problem.id_patient%TYPE,
        i_prof                 IN profissional,
        i_episode              IN pat_problem.id_episode%TYPE,
        i_report               IN VARCHAR2,
        i_dt_ini               IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        o_pat_problem          OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_pat_problem_report';
    BEGIN
    
        IF NOT pk_problems.get_pat_problem_report(i_lang                 => i_lang,
                                                  i_pat                  => i_pat,
                                                  i_prof                 => i_prof,
                                                  i_episode              => i_episode,
                                                  i_report               => i_report,
                                                  i_dt_ini               => i_dt_ini,
                                                  i_dt_end               => i_dt_end,
                                                  i_show_hist            => pk_alert_constant.g_yes,
                                                  o_pat_problem          => o_pat_problem,
                                                  o_unawareness_active   => o_unawareness_active,
                                                  o_unawareness_outdated => o_unawareness_outdated,
                                                  o_error                => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_pat_problem);
            pk_types.open_my_cursor(o_unawareness_active);
            pk_types.open_my_cursor(o_unawareness_outdated);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_problem_report;

    /********************************************************************************************
    * get_pat_problem_hie
    *
    * @param i_lang                   Language ID
    * @param i_pat                    Patient ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode 
    * @param i_report
    * @param o_pat_problem            Cursor containing the problems
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/

    FUNCTION get_pat_problem_hie
    (
        i_lang                 IN language.id_language%TYPE,
        i_pat                  IN pat_problem.id_patient%TYPE,
        i_prof                 IN profissional,
        i_episode              IN pat_problem.id_episode%TYPE,
        i_report               IN VARCHAR2,
        i_dt_ini               IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        o_pat_problem          OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_pat_problem_hie';
    BEGIN
    
        IF NOT pk_problems.get_pat_problem_report(i_lang                 => i_lang,
                                                  i_pat                  => i_pat,
                                                  i_prof                 => i_prof,
                                                  i_episode              => i_episode,
                                                  i_report               => i_report,
                                                  i_dt_ini               => i_dt_ini,
                                                  i_dt_end               => i_dt_end,
                                                  i_show_hist            => pk_alert_constant.g_no,
                                                  o_pat_problem          => o_pat_problem,
                                                  o_unawareness_active   => o_unawareness_active,
                                                  o_unawareness_outdated => o_unawareness_outdated,
                                                  o_error                => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_pat_problem);
            pk_types.open_my_cursor(o_unawareness_active);
            pk_types.open_my_cursor(o_unawareness_outdated);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_problem_hie;

    /********************************************************************************************
    * create_pat_problem_array
    *
    * @param i_lang               language identifier  
    * @param i_epis               episode identifier  
    * @param i_pat                patient identifier
    * @param i_prof               professional identifier
    * @param i_desc_problem       problem descriptions
    * @param i_flg_status         status flag
    * @param i_notes              notes
    * @param i_dt_symptoms        onset date
    * @param i_epis_anamnesis     ???
    * @param i_prof_cat_type      professional category
    * @param i_diagnosis          id diagnosis
    * @param i_flg_nature         nature flag
    * @param i_alert_diag         alert diagnosis
    * @param i_dt_resolution      resolution date
    * @param i_precaution_measure precausion measures
    * @param i_header_warning     header warning
    * @param i_cdr_call           clinical decision rule corresponding id
    * @param i_flg_area - Indentifies the area to which the record belongs: H-Past Medical History; P -Problems
    * @param o_msg                
    * @param o_msg_title         
    * @param o_flg_show          
    * @param o_button
    * @param o_error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION create_pat_problem_array
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_area               IN table_varchar,
        i_diagnosis              IN table_number,
        i_alert_diag             IN table_number,
        i_desc_problem           IN table_varchar,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_dt_symptoms            IN table_varchar,
        i_flg_nature             IN table_varchar,
        i_dt_resolution          IN table_varchar,
        i_header_warning         IN table_varchar,
        i_flg_complications      IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_cdr_call               IN cdr_call.id_cdr_call%TYPE,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        o_msg                    OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'create_pat_problem_array';
    BEGIN
    
        IF NOT pk_problems.create_pat_problem_array(i_lang                   => i_lang,
                                                    i_epis                   => i_epis,
                                                    i_pat                    => i_pat,
                                                    i_prof                   => i_prof,
                                                    i_desc_problem           => i_desc_problem,
                                                    i_flg_status             => i_flg_status,
                                                    i_notes                  => i_notes,
                                                    i_prof_cat_type          => i_prof_cat_type,
                                                    i_diagnosis              => i_diagnosis,
                                                    i_flg_nature             => i_flg_nature,
                                                    i_alert_diag             => i_alert_diag,
                                                    i_precaution_measure     => i_precaution_measure,
                                                    i_header_warning         => i_header_warning,
                                                    i_cdr_call               => i_cdr_call,
                                                    i_flg_area               => i_flg_area,
                                                    i_flg_complications      => i_flg_complications,
                                                    i_dt_diagnosed           => i_dt_diagnosed,
                                                    i_dt_diagnosed_precision => i_dt_diagnosed_precision,
                                                    i_dt_resolved            => i_dt_resolved,
                                                    i_dt_resolved_precision  => i_dt_resolved_precision,
                                                    i_location               => i_location,
                                                    o_msg                    => o_msg,
                                                    o_msg_title              => o_msg_title,
                                                    o_flg_show               => o_flg_show,
                                                    o_button                 => o_button,
                                                    o_type                   => o_type,
                                                    o_ids                    => o_ids,
                                                    o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_pat_problem_array;

    FUNCTION create_pat_problem_array
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_area               IN table_varchar,
        i_diagnosis              IN table_number,
        i_alert_diag             IN table_number,
        i_desc_problem           IN table_varchar,
        i_flg_status             IN table_varchar,
        i_notes                  IN table_varchar,
        i_dt_symptoms            IN table_varchar,
        i_flg_nature             IN table_varchar,
        i_dt_resolution          IN table_varchar,
        i_header_warning         IN table_varchar,
        i_flg_complications      IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_cdr_call               IN cdr_call.id_cdr_call%TYPE,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        i_flg_epis_prob          IN VARCHAR2,
        i_prob_group             IN table_number DEFAULT NULL,
        o_msg                    OUT VARCHAR2,
        o_msg_title              OUT VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'create_pat_problem_array';
    BEGIN
    
        IF NOT pk_problems.create_pat_problem_array(i_lang                   => i_lang,
                                                    i_epis                   => i_epis,
                                                    i_pat                    => i_pat,
                                                    i_prof                   => i_prof,
                                                    i_desc_problem           => i_desc_problem,
                                                    i_flg_status             => i_flg_status,
                                                    i_notes                  => i_notes,
                                                    i_prof_cat_type          => i_prof_cat_type,
                                                    i_diagnosis              => i_diagnosis,
                                                    i_flg_nature             => i_flg_nature,
                                                    i_alert_diag             => i_alert_diag,
                                                    i_precaution_measure     => i_precaution_measure,
                                                    i_header_warning         => i_header_warning,
                                                    i_cdr_call               => i_cdr_call,
                                                    i_flg_area               => i_flg_area,
                                                    i_flg_complications      => i_flg_complications,
                                                    i_dt_diagnosed           => i_dt_diagnosed,
                                                    i_dt_diagnosed_precision => i_dt_diagnosed_precision,
                                                    i_dt_resolved            => i_dt_resolved,
                                                    i_dt_resolved_precision  => i_dt_resolved_precision,
                                                    i_location               => i_location,
                                                    i_flg_epis_prob          => i_flg_epis_prob,
                                                    i_prob_group             => i_prob_group,
                                                    o_msg                    => o_msg,
                                                    o_msg_title              => o_msg_title,
                                                    o_flg_show               => o_flg_show,
                                                    o_button                 => o_button,
                                                    o_type                   => o_type,
                                                    o_ids                    => o_ids,
                                                    o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF o_error.ora_sqlcode = 'PROB-0001'
            THEN
                o_error.ora_sqlcode := '';
            ELSE
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_pk_owner,
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
            END IF;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_pat_problem_array;

    /**
    * Removes a problem from the list of problems registered by the professional
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         The episode id
    * @param i_pat                The patient id
    * @param i_id_problem         Problem id
    * @param i_flg_type           Type of problem
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION set_unregistered_by_me
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_pat        IN patient.id_patient%TYPE,
        i_id_problem IN NUMBER,
        i_flg_type   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'set_unregistered_by_me';
    BEGIN
    
        IF NOT pk_problems.set_unregistered_by_me(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_id_episode => i_id_episode,
                                                  i_pat        => i_pat,
                                                  i_id_problem => i_id_problem,
                                                  i_flg_type   => i_flg_type,
                                                  o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_unregistered_by_me;

    /**
    * Add a problem to the list of problems registered by the professional
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional identifier
    * @param i_id_episode         The episode id
    * @param i_pat                The patient id
    * @param i_id_problem         Problem id
    * @param i_flg_type           Type of problem
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION set_registered_by_me
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_info.id_episode%TYPE,
        i_pat        IN patient.id_patient%TYPE,
        i_id_problem IN NUMBER,
        i_flg_type   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'set_registered_by_me';
    BEGIN
    
        IF NOT pk_problems.set_registered_by_me(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => i_id_episode,
                                                i_pat        => i_pat,
                                                i_id_problem => i_id_problem,
                                                i_flg_type   => i_flg_type,
                                                o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_registered_by_me;
    /******************************************************************************
    *       OBJECTIVO: Alterar / cancelar problema do doente.
    *              Usada no ecrã de mudanças de estado dos "Problemas" do doente, pq 
    *            permite a mudança de estado de vários problemas em simultâneo.
    *       PARAMETROS:  Entrada: 
    * @param I_LANG - Língua registada como preferência do profissional 
    * @param I_PAT - ID do doente 
    * @param I_PROF - profissional q regista 
    * @param I_ID_PAT_PROBLEM - array de IDs de registos alterados 
    * @param I_FLG_STATUS - array de estados 
    * @param I_NOTES - array de notas  
    * @param I_TYPE - array de tipos: P - problemas, A - alergias, H - hábitos 
    * @param I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF 
    * @param i_flg_area - Indentifies the area to which the record belongs: H-Past Medical History; P -Problems
    * @param O_ERROR - erro 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **/
    FUNCTION set_pat_problem_array_dt
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_id_pat_problem         IN table_number,
        i_flg_status             IN table_varchar,
        i_dt_symptoms            IN table_varchar,
        i_notes                  IN table_varchar,
        i_type                   IN table_varchar,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_nature             IN table_varchar,
        i_dt_resolution          IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_header_warning         IN table_varchar,
        i_flg_area               IN pat_history_diagnosis.flg_area%TYPE,
        i_flg_complications      IN table_varchar,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'set_pat_problem_array_dt';
    BEGIN
    
        IF NOT pk_problems.set_pat_problem_array_dt(i_lang                   => i_lang,
                                                    i_epis                   => i_epis,
                                                    i_pat                    => i_pat,
                                                    i_prof                   => i_prof,
                                                    i_id_pat_problem         => i_id_pat_problem,
                                                    i_flg_status             => i_flg_status,
                                                    i_notes                  => i_notes,
                                                    i_type                   => i_type,
                                                    i_prof_cat_type          => i_prof_cat_type,
                                                    i_flg_nature             => i_flg_nature,
                                                    i_precaution_measure     => i_precaution_measure,
                                                    i_header_warning         => i_header_warning,
                                                    i_flg_area               => i_flg_area,
                                                    i_flg_complications      => i_flg_complications,
                                                    i_dt_diagnosed           => i_dt_diagnosed,
                                                    i_dt_diagnosed_precision => i_dt_diagnosed_precision,
                                                    i_dt_resolved            => i_dt_resolved,
                                                    i_dt_resolved_precision  => i_dt_resolved_precision,
                                                    i_location               => i_location,
                                                    o_type                   => o_type,
                                                    o_ids                    => o_ids,
                                                    o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF o_error.ora_sqlcode = 'PROB-0001'
            THEN
                o_error.ora_sqlcode := '';
            ELSE
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_pk_owner,
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
            END IF;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_problem_array_dt;

    FUNCTION set_pat_problem_array_dt
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis                   IN episode.id_episode%TYPE,
        i_pat                    IN pat_problem.id_patient%TYPE,
        i_prof                   IN profissional,
        i_id_pat_problem         IN table_number,
        i_flg_status             IN table_varchar,
        i_dt_symptoms            IN table_varchar,
        i_notes                  IN table_varchar,
        i_type                   IN table_varchar,
        i_prof_cat_type          IN category.flg_type%TYPE,
        i_flg_nature             IN table_varchar,
        i_dt_resolution          IN table_varchar,
        i_precaution_measure     IN table_table_number,
        i_header_warning         IN table_varchar,
        i_flg_area               IN pat_history_diagnosis.flg_area%TYPE,
        i_flg_complications      IN table_varchar,
        i_dt_diagnosed           IN table_varchar,
        i_dt_diagnosed_precision IN table_varchar,
        i_dt_resolved            IN table_varchar,
        i_dt_resolved_precision  IN table_varchar,
        i_location               IN table_number,
        i_flg_epis_prob          IN VARCHAR2,
        i_prob_group             IN table_number,
        i_seq_num                IN table_number,
        o_type                   OUT table_varchar,
        o_ids                    OUT table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'set_pat_problem_array_dt';
    BEGIN
    
        IF NOT pk_problems.set_pat_problem_array_dt(i_lang                   => i_lang,
                                                    i_epis                   => i_epis,
                                                    i_pat                    => i_pat,
                                                    i_prof                   => i_prof,
                                                    i_id_pat_problem         => i_id_pat_problem,
                                                    i_flg_status             => i_flg_status,
                                                    i_notes                  => i_notes,
                                                    i_type                   => i_type,
                                                    i_prof_cat_type          => i_prof_cat_type,
                                                    i_flg_nature             => i_flg_nature,
                                                    i_precaution_measure     => i_precaution_measure,
                                                    i_header_warning         => i_header_warning,
                                                    i_flg_area               => i_flg_area,
                                                    i_flg_complications      => i_flg_complications,
                                                    i_dt_diagnosed           => i_dt_diagnosed,
                                                    i_dt_diagnosed_precision => i_dt_diagnosed_precision,
                                                    i_dt_resolved            => i_dt_resolved,
                                                    i_dt_resolved_precision  => i_dt_resolved_precision,
                                                    i_location               => i_location,
                                                    i_flg_epis_prob          => i_flg_epis_prob,
                                                    i_prob_group             => i_prob_group,
                                                    i_seq_num                => i_seq_num,
                                                    o_type                   => o_type,
                                                    o_ids                    => o_ids,
                                                    o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF o_error.ora_sqlcode = 'PROB-0001'
            THEN
                o_error.ora_sqlcode := '';
            ELSE
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_pk_owner,
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
            END IF;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_problem_array_dt;
    /**
    *           OBJECTIVO: Alterar / cancelar problema do doente.
    *                  Usada no ecrã de mudanças de estado dos "Problemas" do doente, pq 
    *                permite a mudança de estado de vários problemas em simultâneo.
    * @param I_LANG - Língua registada como preferência do profissional                      
    * @param I_PAT - ID do doente                      
    * @param I_PROF - profissional q regista                      
    * @param I_ID_PAT_PROBLEM - array de IDs de registos alterados                      
    * @param I_FLG_STATUS - array de estados                      
    * @param I_NOTES - array de notas                       
    * @param I_TYPE - array de tipos: P - problemas, A - alergias, H - hábitos                      
    * @param I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF 
    * @param O_ERROR - erro 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **/
    FUNCTION set_pat_problem_array
    (
        i_lang                  IN language.id_language%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_pat                   IN pat_problem.id_patient%TYPE,
        i_prof                  IN profissional,
        i_id_pat_problem        IN table_number,
        i_flg_status            IN table_varchar,
        i_notes                 IN table_varchar,
        i_type                  IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_flg_nature            IN table_varchar,
        i_dt_resolution         IN table_varchar,
        i_precaution_measure    IN table_table_number,
        i_header_warning        IN table_varchar,
        i_dt_resolved           IN table_varchar,
        i_dt_resolved_precision IN table_varchar,
        o_type                  OUT table_varchar,
        o_ids                   OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'set_pat_problem_array';
    BEGIN
    
        IF NOT pk_problems.set_pat_problem_array(i_lang                  => i_lang,
                                                 i_epis                  => i_epis,
                                                 i_pat                   => i_pat,
                                                 i_prof                  => i_prof,
                                                 i_id_pat_problem        => i_id_pat_problem,
                                                 i_flg_status            => i_flg_status,
                                                 i_notes                 => i_notes,
                                                 i_type                  => i_type,
                                                 i_prof_cat_type         => i_prof_cat_type,
                                                 i_flg_nature            => i_flg_nature,
                                                 i_precaution_measure    => i_precaution_measure,
                                                 i_header_warning        => i_header_warning,
                                                 i_dt_resolved           => i_dt_resolved,
                                                 i_dt_resolved_precision => i_dt_resolved_precision,
                                                 o_type                  => o_type,
                                                 o_ids                   => o_ids,
                                                 o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF o_error.ora_sqlcode = 'PROB-0001'
            THEN
                o_error.ora_sqlcode := '';
            ELSE
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_pk_owner,
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
            END IF;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_problem_array;
    FUNCTION set_pat_problem_array
    (
        i_lang                  IN language.id_language%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_pat                   IN pat_problem.id_patient%TYPE,
        i_prof                  IN profissional,
        i_id_pat_problem        IN table_number,
        i_flg_status            IN table_varchar,
        i_notes                 IN table_varchar,
        i_type                  IN table_varchar,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_flg_nature            IN table_varchar,
        i_dt_resolution         IN table_varchar,
        i_precaution_measure    IN table_table_number,
        i_header_warning        IN table_varchar,
        i_dt_resolved           IN table_varchar,
        i_dt_resolved_precision IN table_varchar,
        i_flg_epis_prob         IN VARCHAR2,
        i_prob_group            IN table_number,
        i_seq_num               IN table_number,
        o_type                  OUT table_varchar,
        o_ids                   OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'set_pat_problem_array';
    BEGIN
    
        IF NOT pk_problems.set_pat_problem_array(i_lang                  => i_lang,
                                                 i_epis                  => i_epis,
                                                 i_pat                   => i_pat,
                                                 i_prof                  => i_prof,
                                                 i_id_pat_problem        => i_id_pat_problem,
                                                 i_flg_status            => i_flg_status,
                                                 i_notes                 => i_notes,
                                                 i_type                  => i_type,
                                                 i_prof_cat_type         => i_prof_cat_type,
                                                 i_flg_nature            => i_flg_nature,
                                                 i_precaution_measure    => i_precaution_measure,
                                                 i_header_warning        => i_header_warning,
                                                 i_dt_resolved           => i_dt_resolved,
                                                 i_dt_resolved_precision => i_dt_resolved_precision,
                                                 i_flg_epis_prob         => i_flg_epis_prob,
                                                 i_prob_group            => i_prob_group,
                                                 i_seq_num               => i_seq_num,
                                                 o_type                  => o_type,
                                                 o_ids                   => o_ids,
                                                 o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            IF o_error.ora_sqlcode = 'PROB-0001'
            THEN
                o_error.ora_sqlcode := '';
            ELSE
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_pk_owner,
                                                  g_package_name,
                                                  l_func_name,
                                                  o_error);
            END IF;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_problem_array;
    /**
    * problem grid
    *
    * @param i_lang        language identifier       
    * @param i_pat         patient identifier   
    * @param i_status      flag status   
    * @param i_type        type   
    * @param i_prof        professional identifier   
    * @param i_problem     problem identifier   
    * @param o_pat_problem   out cursor 
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_pat_problem';
    BEGIN
    
        IF NOT pk_problems.get_pat_problem(i_lang                      => i_lang,
                                           i_pat                       => i_pat,
                                           i_status                    => i_status,
                                           i_type                      => i_type,
                                           i_prof                      => i_prof,
                                           i_problem                   => i_problem,
                                           o_pat_problem               => o_pat_problem,
                                           o_pat_prob_unaware_active   => o_pat_prob_unaware_active,
                                           o_pat_prob_unaware_outdated => o_pat_prob_unaware_outdated,
                                           o_error                     => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_pat_problem);
            pk_types.open_my_cursor(o_pat_prob_unaware_active);
            pk_types.open_my_cursor(o_pat_prob_unaware_outdated);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_problem;
    /**
    * problem grid
    *
    * @param i_lang        language identifier       
    * @param i_pat         patient identifier   
    * @param i_status      flag status   
    * @param i_type        type   
    * @param i_prof        professional identifier   
    * @param i_problem     problem identifier   
    * @param i_episode     episode identifier   
    * @param i_report      report flag   
    * @param o_pat_problem   out cursor 
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        i_problem                   IN pat_problem.id_pat_problem%TYPE,
        i_episode                   IN pat_problem.id_episode%TYPE,
        i_report                    IN VARCHAR2,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_pat_problem';
    BEGIN
    
        IF NOT pk_problems.get_pat_problem(i_lang                      => i_lang,
                                           i_pat                       => i_pat,
                                           i_status                    => i_status,
                                           i_type                      => i_type,
                                           i_prof                      => i_prof,
                                           i_problem                   => i_problem,
                                           i_episode                   => i_episode,
                                           i_report                    => i_report,
                                           o_pat_problem               => o_pat_problem,
                                           o_pat_prob_unaware_active   => o_pat_prob_unaware_active,
                                           o_pat_prob_unaware_outdated => o_pat_prob_unaware_outdated,
                                           o_error                     => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_pat_problem);
            pk_types.open_my_cursor(o_pat_prob_unaware_active);
            pk_types.open_my_cursor(o_pat_prob_unaware_outdated);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_problem;

    /**
    * problem grid
    *
    * @param i_lang        language identifier       
    * @param i_pat         patient identifier   
    * @param i_status      flag status   
    * @param i_type        type   
    * @param i_prof        professional identifier   
    * @param i_report      report flag   
    * @param o_pat_problem   out cursor 
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */

    FUNCTION get_pat_problem
    (
        i_lang                      IN language.id_language%TYPE,
        i_pat                       IN pat_problem.id_patient%TYPE,
        i_status                    IN pat_problem.flg_status%TYPE,
        i_type                      IN VARCHAR2,
        i_prof                      IN profissional,
        o_pat_problem               OUT pk_types.cursor_type,
        o_pat_prob_unaware_active   OUT pk_types.cursor_type,
        o_pat_prob_unaware_outdated OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_pat_problem';
    BEGIN
    
        IF NOT pk_problems.get_pat_problem(i_lang                      => i_lang,
                                           i_pat                       => i_pat,
                                           i_status                    => i_status,
                                           i_type                      => i_type,
                                           i_prof                      => i_prof,
                                           o_pat_problem               => o_pat_problem,
                                           o_pat_prob_unaware_active   => o_pat_prob_unaware_active,
                                           o_pat_prob_unaware_outdated => o_pat_prob_unaware_outdated,
                                           o_error                     => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_pat_problem);
            pk_types.open_my_cursor(o_pat_prob_unaware_active);
            pk_types.open_my_cursor(o_pat_prob_unaware_outdated);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_problem;
    /********************************************************************************************
    * Returns the problems onset list
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_onset                  Onset list
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION get_problems_onset_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_onset OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_problems_onset_list';
    BEGIN
    
        IF NOT pk_problems.get_problems_onset_list(i_lang  => i_lang,
                                                   i_prof  => i_prof,
                                                   o_onset => o_onset,
                                                   o_error => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_onset);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_problems_onset_list;
    /**
    *           OBJECTIVO:   Obter estados possíveis para um problema
    * @param I_LANG - Língua registada como preferência do profissional                      
    * @param I_PROF - Profissional                Saida:   
    * @param O_PROBLEM_PROT - Lista de protocolos possíveis                            
    * @param O_ERROR - erro 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    ***/
    FUNCTION get_problem_protocol
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN pat_history_diagnosis.flg_area%TYPE,
        o_problem_prot OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_problem_protocol';
    BEGIN
    
        IF NOT pk_problems.get_problem_protocol(i_lang         => i_lang,
                                                i_prof         => i_prof,
                                                i_task_type    => i_task_type,
                                                o_problem_prot => o_problem_prot,
                                                o_error        => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_problem_prot);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_problem_protocol;

    /**
    * Get nature field options.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_nat          nature field options
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/07/04
    */
    FUNCTION get_nature_options
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_nat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_NATURE_OPTIONS';
    BEGIN
        g_error := 'CALL pk_problems.get_nature_options';
        pk_problems.get_nature_options(i_prof => i_prof, o_nat => o_nat);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_pk_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_cursor_if_closed(i_cursor => o_nat);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_nature_options;

    /**
    * Obter naturezas possíveis para um problema
    * @param I_LANG - Língua registada como preferência do profissional 
    * @param I_PROF - Profissional
    * @param O_PROBLEM_NATURE - Na   
    * @param O_ERROR - erro 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **/
    FUNCTION get_problem_nature
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_problem_nature OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_problem_nature';
    BEGIN
    
        IF NOT pk_problems.get_problem_nature(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              o_problem_nature => o_problem_nature,
                                              o_error          => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_problem_nature);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_problem_nature;
    /**
    * Obter lista de diagóstios dos vários níveis. se I_ID_PARENT for null, tráz os diagnósticos de 1º nível,
    *       senão, traz todos os diagnósticos "filhos" do seleccionado.    
    * @param I_LANG - Língua registada como preferência do profissional                                
    * @param I_ID_PARENT - ID do diagnóstico "pai" seleccionado. Se for NULL, traz os diagnósticos de 1º nível                                    
    * @param I_PATIENT - ID do doente                                       
    * @param I_FLG_TYPE - Tipo: D - ICD9, P - ICPC2, C - ICD9 CM 
    * @param I_SEARCH - valor do critério de pesquisa      
    * @param O_LIST - array de diagnósticos                       
    * @param O_ERROR - erro 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION get_problem_list
    (
        i_lang      IN language.id_language%TYPE,
        i_id_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_flg_type  IN diagnosis.flg_type%TYPE,
        i_search    IN VARCHAR2,
        o_list      OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_problem_list';
    BEGIN
    
        IF NOT pk_problems.get_problem_list(i_lang      => i_lang,
                                            i_id_parent => i_id_parent,
                                            i_prof      => i_prof,
                                            i_patient   => i_patient,
                                            i_flg_type  => i_flg_type,
                                            i_search    => i_search,
                                            o_list      => o_list,
                                            o_error     => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_problem_list;
    /**
    * Returns the possible precautions available
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param o_precautions     Cursor containing the precautions
    * @param o_error           error message 
    *
    * @return               false if errors occur, true otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION get_precaution_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_precautions OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_precaution_list';
    BEGIN
    
        IF NOT pk_problems.get_precaution_list(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               o_precautions => o_precautions,
                                               o_error       => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_precautions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_precaution_list;
    /********************************************************************************************
    * Returns the information of a specific problem. The problem can be in problems and relevant diseases.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_pat                    Patient ID
    * @param i_id_problem             The problem ID 
    * @param i_type                   Type of records wanted (P - problems, D - relevant diseases)
    * @param o_pat_problem            Cursor containing the problem information
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    **********************************************************************************************/
    FUNCTION get_pat_problem_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_pat         IN pat_problem.id_patient%TYPE,
        i_id_problem  IN NUMBER,
        i_type        IN VARCHAR2,
        o_pat_problem OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_pat_problem_info';
    BEGIN
    
        IF NOT pk_problems.get_pat_problem_info(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_pat         => i_pat,
                                                i_id_problem  => i_id_problem,
                                                i_type        => i_type,
                                                o_pat_problem => o_pat_problem,
                                                o_error       => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_pat_problem);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_problem_info;

    /********************************************************************************************
    * Search all diagnosis on the DIAGNOSIS table
    *
    * @param i_lang                   Language ID
    * @param i_episode                Episode ID
    * @param i_criteria               String to search
    * @param i_diag_parent            Diagnosis parent, if it exists
    * @param i_flg_type               Protocol to be used (ICPC2, ICD9, ...), if it exists
    * @param i_prof                   Professional object
    * @param o_diagnosis              Cursor containing the diagnosis info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                Jorge Silva
    * @version               2.6.3
    * @since                 2013/01/21
    **********************************************************************************************/

    FUNCTION get_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_patient       IN patient.id_patient%TYPE,
        i_criteria      IN VARCHAR2,
        i_diag_parent   IN diagnosis.id_diagnosis_parent%TYPE,
        i_flg_type      IN diagnosis.flg_type%TYPE,
        i_prof          IN profissional,
        i_flg_task_type IN VARCHAR2,
        o_diagnosis     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_diagnosis';
    BEGIN
    
        IF NOT pk_problems.get_diagnosis(i_lang          => i_lang,
                                         i_episode       => i_episode,
                                         i_patient       => i_patient,
                                         i_criteria      => i_criteria,
                                         i_diag_parent   => i_diag_parent,
                                         i_flg_type      => i_flg_type,
                                         i_prof          => i_prof,
                                         i_flg_task_type => i_flg_task_type,
                                         o_diagnosis     => o_diagnosis,
                                         o_error         => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_diagnosis;

    /********************************************************************************************
    * Search all diagnosis on the DIAGNOSIS table
    *
    * @param i_lang                   Language ID
    * @param i_episode                Episode ID
    * @param i_criteria               String to search
    * @param i_diag_parent            Diagnosis parent, if it exists
    * @param i_flg_type               Protocol to be used (ICPC2, ICD9, ...), if it exists
    * @param i_prof                   Professional object
    * @param o_diagnosis              Cursor containing the diagnosis info
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                Jorge Silva
    * @version               2.6.3
    * @since                 2013/01/21
    **********************************************************************************************/

    FUNCTION get_diagnosis
    (
        i_lang        IN language.id_language%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_criteria    IN VARCHAR2,
        i_diag_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_flg_type    IN diagnosis.flg_type%TYPE,
        i_prof        IN profissional,
        o_diagnosis   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_diagnosis';
    BEGIN
    
        IF NOT pk_problems.get_diagnosis(i_lang        => i_lang,
                                         i_episode     => i_episode,
                                         i_criteria    => i_criteria,
                                         i_patient     => i_patient,
                                         i_diag_parent => i_diag_parent,
                                         i_flg_type    => i_flg_type,
                                         i_prof        => i_prof,
                                         o_diagnosis   => o_diagnosis,
                                         o_error       => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_diagnosis;

    /**
    * Multitype diagnoses search. Based on GET_DIAGNOSIS.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_flg_type     diagnosis types flags
    * @param i_diag_parent  parent diagnosis identifier
    * @param i_criteria     user query
    * @param i_format_text  apply styles to diagnoses names? Y/N
    * @param o_diagnosis    diagnoses data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Paulo Teixeira
    * @version               2.6.1
    * @since                2011/01/19
    */
    FUNCTION get_diagnosis_mt
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN table_varchar,
        i_diag_parent IN diagnosis.id_diagnosis_parent%TYPE,
        i_criteria    IN VARCHAR2,
        i_format_text IN VARCHAR2,
        o_diagnosis   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_diagnosis_mt';
    BEGIN
    
        IF NOT pk_problems.get_diagnosis_mt(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_flg_type    => i_flg_type,
                                            i_diag_parent => i_diag_parent,
                                            i_criteria    => i_criteria,
                                            i_format_text => i_format_text,
                                            o_diagnosis   => o_diagnosis,
                                            o_error       => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_diagnosis);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_diagnosis_mt;
    /**
    * get_problem_status
    *
    * @param i_lang        language identifier       
    * @param i_prof        professional identifier   
    * @param i_status      flag status   
    *
    * @param o_problem_status   out cursor 
    *
    * @param o_error              Error object
    *
    * @return                True if succeed, False otherwise
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/19
    */
    FUNCTION get_problem_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_problem_status OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_problem_status';
    BEGIN
    
        IF NOT pk_problems.get_problem_status(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              o_problem_status => o_problem_status,
                                              o_error          => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_problem_status);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_problem_status;
    /********************************************************************************************
    * Returns add button options
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                patient_id
    * @param o_list                  add list
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/01/31
    **********************************************************************************************/
    FUNCTION get_add_problems
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_add_problems';
    BEGIN
    
        IF NOT pk_problems.get_add_problems(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_patient => i_patient,
                                            i_episode => i_episode,
                                            o_list    => o_list,
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_add_problems;
    /********************************************************************************************
    * insert patient problem unawareness
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_id_prob_unaware    problem unawareness identifier
    * @param      i_id_patient         patient identifier
    * @param      i_id_episode         episode identifier
    * @param      i_notes              notes
    * @param      i_flg_status         flag status
    * @param      i_id_cancel_reason   cancel reason identifier
    * @param      i_cancel_notes       cancel notes
    *
    * @param      o_id_combination_spec  combination specification identifier  
    * @param      o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION ins_pat_prob_unaware
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prob_unaware     IN pat_prob_unaware.id_prob_unaware%TYPE,
        i_id_patient          IN pat_prob_unaware.id_patient%TYPE,
        i_id_episode          IN pat_prob_unaware.id_episode%TYPE,
        i_notes               IN pat_prob_unaware.notes%TYPE,
        i_flg_status          IN pat_prob_unaware.flg_status%TYPE,
        i_id_cancel_reason    IN pat_prob_unaware.id_cancel_reason%TYPE,
        i_cancel_notes        IN pat_prob_unaware.cancel_notes%TYPE,
        o_id_pat_prob_unaware OUT pat_prob_unaware.id_pat_prob_unaware%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'INS_PAT_PROB_UNAWARE';
    BEGIN
    
        g_error := 'CALL INS_PAT_PROB_UNAWARE';
        IF NOT pk_problems.ins_pat_prob_unaware(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_prob_unaware     => i_id_prob_unaware,
                                                i_id_patient          => i_id_patient,
                                                i_id_episode          => i_id_episode,
                                                i_notes               => i_notes,
                                                i_flg_status          => i_flg_status,
                                                i_id_cancel_reason    => i_id_cancel_reason,
                                                i_cancel_notes        => i_cancel_notes,
                                                o_id_pat_prob_unaware => o_id_pat_prob_unaware,
                                                o_error               => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END ins_pat_prob_unaware;
    ---
    /********************************************************************************************
    * get patient problem unawareness choices
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                patient_id
    * @param o_choices                choices list
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/02/01
    **********************************************************************************************/
    FUNCTION get_pat_prob_unaware_choices
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2,
        o_choices  OUT pk_types.cursor_type,
        o_notes    OUT pat_prob_unaware.notes%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'get_pat_prob_unaware_choices';
    BEGIN
        g_error := 'CALL get_pat_prob_unaware_choices';
        IF NOT pk_problems.get_pat_prob_unaware_choices(i_lang     => i_lang,
                                                        i_prof     => i_prof,
                                                        i_patient  => i_patient,
                                                        i_episode  => i_episode,
                                                        i_flg_type => i_flg_type,
                                                        o_choices  => o_choices,
                                                        o_notes    => o_notes,
                                                        o_error    => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_choices);
            RETURN FALSE;
    END get_pat_prob_unaware_choices;

    /********************************************************************************************
    * get patient problem unawareness choices
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                patient_id
    * @param i_episode                episode id
    * @param o_title                  title
    * @param o_msg                    message
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Paulo Teixeira
    * @version               2.6.1
    * @since                 2011/02/01
    **********************************************************************************************/
    FUNCTION validate_unawareness
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_id_prob_unaware IN pat_prob_unaware.id_prob_unaware%TYPE,
        o_title           OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_show            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'validate_unawareness';
    BEGIN
        g_error := 'CALL validate_unawareness';
        IF NOT pk_problems.validate_unawareness(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_patient         => i_patient,
                                                i_episode         => i_episode,
                                                i_id_prob_unaware => i_id_prob_unaware,
                                                o_title           => o_title,
                                                o_msg             => o_msg,
                                                o_show            => o_show,
                                                o_error           => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_unawareness;

    /********************************************************************************************
    * Validate if problem is a trial
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_diagnosis              diagnosis
    * @param o_title                  title
    * @param o_msg                    message
    * @param o_flg_show               show popup Y or N
    * @param o_error                  Error Message
    *
    * @return                         True if success, False in case of error
    *
    * @author                Elisabete Bugalho
    * @version               2.6.1
    * @since                 2011/03/03
    **********************************************************************************************/
    FUNCTION validate_trials
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN table_number,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_shortcut  OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(60 CHAR) := 'VALIDATE_TRIALS';
    BEGIN
    
        IF NOT pk_problems.validate_trials(i_lang      => i_lang,
                                           i_prof      => i_prof,
                                           i_diagnosis => i_diagnosis,
                                           o_msg       => o_msg,
                                           o_msg_title => o_msg_title,
                                           o_flg_show  => o_flg_show,
                                           o_shortcut  => o_shortcut,
                                           o_error     => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END validate_trials;

    /********************************************************************************************
    * Get the area option that will appear in the problems edition screen that allow to switch the
    * area of the record (Problems, PAst medical history)
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_id_record          Record identifier, if not null, this means the function was called during an edit action
    * @param      o_list               List with the available area
    *
    * @param      o_error              mensagem de erro
    *
    * @author  Sofia Mendes
    * @version 2.6.3.2.1
    * @since   13-Feb-2013
    **********************************************************************************************/
    FUNCTION get_areas_domain
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_record         IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        id_tl_task_timeline IN tl_task.id_tl_task%TYPE DEFAULT NULL,
        o_list              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(16 CHAR) := 'GET_AREAS_DOMAIN';
    
    BEGIN
        g_error := 'CALL pk_problems.get_areas_domain';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.get_areas_domain(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_record         => i_id_record,
                                            id_tl_task_timeline => id_tl_task_timeline,
                                            o_list              => o_list,
                                            o_error             => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_areas_domain;

    /**********************************************************************************************************************
    * During a problem creation, validates if the selected diagnoses can remain selected when changing to a different type
    *
    * @param      i_lang                Língua registada como preferência do profissional
    * @param      i_prof                profissional identifier
    * @param      i_id_patient          Patient ID
    * @param      i_flg_area            Indicates the type of problem to which the user just changed (past_history_diagnosis.flg_area)
    * @param      i_id_diagnosis        Selected diagnoses id list
    * @param      i_id_alert_diagnosis  Selected alert_diagnoses id list
    * @param      o_id_diagnosis        Diagnoses id list that can remain selected
    * @param      o_id_alert_diagnosis  Alert_diagnoses id list that can remain selected
    *
    * @param      o_error              error message
    *
    * @author     Sergio Dias
    * @version    2.6.3.12
    * @since      10-Mar-2013
    ************************************************************************************************************************/
    FUNCTION validate_diagnosis_selection
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_area           IN pat_history_diagnosis.flg_area%TYPE,
        i_id_diagnosis       IN table_number,
        i_id_alert_diagnosis IN table_number,
        o_id_diagnosis       OUT table_number,
        o_id_alert_diagnosis OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'VALIDATE_DIAGNOSIS_SELECTION';
    
    BEGIN
        g_error := 'CALL pk_problems.get_areas_domain';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.validate_diagnosis_selection(i_lang               => i_lang,
                                                        i_prof               => i_prof,
                                                        i_id_patient         => i_id_patient,
                                                        i_flg_area           => i_flg_area,
                                                        i_id_diagnosis       => i_id_diagnosis,
                                                        i_id_alert_diagnosis => i_id_alert_diagnosis,
                                                        o_id_diagnosis       => o_id_diagnosis,
                                                        o_id_alert_diagnosis => o_id_alert_diagnosis,
                                                        o_error              => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_diagnosis_selection;

    FUNCTION get_pat_problem_detail
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN pat_history_diagnosis.id_patient%TYPE,
        i_type        IN VARCHAR2,
        i_id          IN NUMBER,
        i_id_episode  IN pat_problem.id_episode%TYPE,
        o_pat_problem OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_PAT_PROBLEM_DETAIL';
    
    BEGIN
        g_error := 'CALL pk_problems.GET_PAT_PROBLEM_DETAIL';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.get_pat_problem_detail(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_id_patient  => i_id_patient,
                                                  i_type        => i_type,
                                                  i_id          => i_id,
                                                  i_id_episode  => i_id_episode,
                                                  o_pat_problem => o_pat_problem,
                                                  o_error       => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_problem_detail;

    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_id_location IN diagnosis_ea.id_concept_term%TYPE DEFAULT NULL,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_PLACE_OF_OCCURENCE';
    
    BEGIN
        g_error := 'CALL PK_PROBLEMS.GET_PLACE_OF_OCCURENCE';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.get_place_of_occurence(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_diagnosis   => i_diagnosis,
                                                  i_id_location => i_id_location,
                                                  o_location    => o_location,
                                                  o_error       => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_place_of_occurence;

    /********************************************************************************************
    * Function that returns the the places of occurence of the diagnoses
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_diagnosis              Collection of diagnoses IDs
    * @param i_id_location            Collection of places of occurence (IDs already registered)
    *
    * @return                         Places of occurence
    *
    * Note: This function will return the locations that are common to all the input diagnoses.
    **********************************************************************************************/
    FUNCTION get_place_of_occurence
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diagnosis   IN table_number,
        i_id_location IN table_number DEFAULT NULL,
        o_location    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_PLACE_OF_OCCURENCE';
    
    BEGIN
        g_error := 'CALL PK_PROBLEMS.GET_PLACE_OF_OCCURENCE';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.get_place_of_occurence(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_diagnosis   => i_diagnosis,
                                                  i_id_location => i_id_location,
                                                  o_location    => o_location,
                                                  o_error       => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_place_of_occurence;	

    /************************************************************************************************************************
    * set_epis_problem_group_array
    *
    * @param i_lang The language id
    * @param i_episode The episode id
    * @param i_prof The professional, institution and software ids
    * @param i_id_problem An array with pat problem
    * @param i_flg_status An array of problem status
    * @param i_prob_group  An array with group ids
    * @param i_seq_num An array with rank ids
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/8
    */
    FUNCTION set_epis_problem_group_array
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_id_problem     IN table_number,
        i_pre_id_problem IN table_number,
        i_flg_status     IN table_varchar,
        i_prob_group     IN table_number,
        i_seq_num        IN table_number,
        i_flg_type       IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'SET_EPIS_PROBLEM_GROUP_ARRAY';
    BEGIN
        g_error := 'CALL PK_PROBLEMS.SET_EPIS_PROBLEM_GROUP_ARRAY';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.set_epis_problem_group_array(i_lang            => i_lang,
                                                        i_episode         => i_episode,
                                                        i_prof            => i_prof,
                                                        i_id_problem      => i_id_problem,
                                                        i_prev_id_problem => i_pre_id_problem,
                                                        i_flg_status      => i_flg_status,
                                                        i_prob_group      => i_prob_group,
                                                        i_seq_num         => i_seq_num,
                                                        i_flg_type        => i_flg_type,
                                                        o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_problem_group_array;

    /************************************************************************************************************************
    * set_epis_prob_group_note
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_episode The episode id
    * @param i_id_epis_prob_group episode group id
    * @param i_assessment_note assessment note
    * @param i_plan_note plan note
    * @param i_dteg_note DETG note
    
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return max. episode group number.
    *
    * @author : Lillian Lu
     * @since 2017/11/10
    **********************************************************************************************/
    FUNCTION set_epis_prob_group_note
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_epis_prob_grp_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        i_id_epis_prob_group   IN epis_prob_group.id_epis_prob_group%TYPE,
        i_assessment_note      IN CLOB,
        i_plan_note            IN CLOB,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'SET_EPIS_PROB_GROUP_NOTE';
    BEGIN
        g_error := 'CALL PK_PROBLEMS.SET_EPIS_PROB_GROUP_NOTE';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.set_epis_prob_group_note(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_episode              => i_episode,
                                                    i_id_epis_prob_grp_ass => i_id_epis_prob_grp_ass,
                                                    i_id_epis_prob_group   => i_id_epis_prob_group,
                                                    i_assessment_note      => i_assessment_note,
                                                    i_plan_note            => i_plan_note,
                                                    o_error                => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_prob_group_note;

    /************************************************************************************************************************
    * get_max_problem_group
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_epis The episode id
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return max. episode group number.
    *
    * @author : Lillian Lu
     * @since 2017/11/10
    **********************************************************************************************/
    FUNCTION get_max_problem_group
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_group OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_MAX_PROBLEM_GROUP';
    BEGIN
        g_error := 'CALL PK_PROBLEMS.GET_MAX_PROBLEM_GROUP';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.get_max_problem_group(i_lang  => i_lang,
                                                 i_prof  => i_prof,
                                                 i_epis  => i_epis,
                                                 o_group => o_group,
                                                 o_error => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_max_problem_group;

    /************************************************************************************************************************
    * get_epis_problem
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_episode The episode id
    * @param i_pat patient id
    * @param i_status
    * @param i_type
    * @param i_problem
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/23
    **********************************************************************************************/
    FUNCTION get_epis_problem
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_pat        IN pat_history_diagnosis.id_patient%TYPE,
        i_status     IN table_varchar,
        i_type       IN VARCHAR2,
        i_id_problem IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE DEFAULT NULL,
        o_problem    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_EPIS_PROBLEM';
    BEGIN
        g_error := 'CALL PK_PROBLEMS.GET_EPIS_PROBLEM';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.get_epis_problem(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_episode    => i_episode,
                                            i_pat        => i_pat,
                                            i_status     => i_status,
                                            i_type       => i_type,
                                            i_id_problem => i_id_problem,
                                            o_problem    => o_problem,
                                            o_error      => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_problem;

    /************************************************************************************************************************
    * validate_epis_prob_group ( check if no any problem in the specific group)
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_episode The episode id
    * @param i_prob_group  group id
    * @param i_problem
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if has problems in the group, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/24
    **********************************************************************************************/
    FUNCTION validate_epis_prob_group
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_problem        IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_prob_group        IN epis_prob_group.prob_group%TYPE,
        o_prob_in_epis_prob OUT VARCHAR2,
        o_prob_in_gorup     OUT VARCHAR2,
        o_prob_in_prev_epis OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'VALIDATE_EPIS_PROB_GROUP';
    BEGIN
        g_error := 'CALL PK_PROBLEMS.VALIDATE_EPIS_PROB_GROUP';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.validate_epis_prob_group(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_episode           => i_episode,
                                                    i_id_problem        => i_id_problem,
                                                    i_prob_group        => i_prob_group,
                                                    o_prob_in_epis_prob => o_prob_in_epis_prob,
                                                    o_prob_in_gorup     => o_prob_in_gorup,
                                                    o_prob_in_prev_epis => o_prob_in_prev_epis,
                                                    o_error             => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END validate_epis_prob_group;
    /************************************************************************************************************************
    * cancel_epis_problem
    *
    * @param i_lang The language id
    * @param i_prof The professional, institution and software ids
    * @param i_pat  patient id
    * @param i_id_episode The episode id
    * @param i_id_problem problem id
    * @param i_type                   Type of problem
    * @param i_id_cancel_reason       Cancel Reason ID
    * @param i_cancel_notes           Cancelation notes
    * @param i_prof_cat_type          Professional category flag
    * @param i_flg_cancel_pat_prob    cancel patient problem flah:
    *                                                'Y' if need to cancel patient problem
    * @param o_error                  Error message
    *
    * @return True if has problems in the group, false otherwise.
    *
    * @author : Lillian Lu
     * @since 2017/11/27
    **********************************************************************************************/
    FUNCTION cancel_epis_problem
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pat                 IN pat_problem.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_problem          IN NUMBER,
        i_type                IN VARCHAR2,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN epis_prob.cancel_notes%TYPE,
        i_prof_cat_type       IN category.flg_type%TYPE,
        i_flg_cancel_pat_prob IN VARCHAR2,
        o_type                OUT table_varchar,
        o_ids                 OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'CANCEL_EPIS_PROBLEM';
    BEGIN
        g_error := 'CALL PK_PROBLEMS.CANCEL_EPIS_PROBLEM';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.cancel_epis_problem(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_pat                 => i_pat,
                                               i_id_episode          => i_id_episode,
                                               i_id_problem          => i_id_problem,
                                               i_type                => i_type,
                                               i_id_cancel_reason    => i_id_cancel_reason,
                                               i_cancel_notes        => i_cancel_notes,
                                               i_prof_cat_type       => i_prof_cat_type,
                                               i_flg_cancel_pat_prob => i_flg_cancel_pat_prob,
                                               o_type                => o_type,
                                               o_ids                 => o_ids,
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_epis_problem;

    /**
    * Gets actions available for Problem List View
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   o_list                       List of actions available
    * @param   o_error                    Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  Lillian Lu
    * @since   14-12-2017
    */
    FUNCTION get_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'GET_ACTIONS';
    BEGIN
        g_error := 'CALL PK_PROBLEMS.GET_ACTIONS';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF NOT pk_problems.get_actions(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_from_state => i_from_state,
                                       o_actions    => o_actions,
                                       o_error      => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions;

    FUNCTION get_epis_prob_group
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_flg_status IN VARCHAR2,
        o_prob_group OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_problems.get_epis_prob_group(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_episode    => i_episode,
                                               i_id_epis_pn => i_id_epis_pn,
                                               i_flg_status => i_flg_status,
                                               o_prob_group => o_prob_group,
                                               o_error      => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              'get_epis_prob_group',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_prob_group);
            RETURN FALSE;
    END get_epis_prob_group;

    FUNCTION get_prob_group_assessment
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_epis_prob_group     IN epis_prob_group.id_epis_prob_group%TYPE,
        i_id_epis_prob_group_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        o_assessement            OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_problems.get_prob_group_assessment(i_lang                   => i_lang,
                                                     i_prof                   => i_prof,
                                                     i_episode                => i_episode,
                                                     i_id_epis_prob_group     => i_id_epis_prob_group,
                                                     i_id_epis_prob_group_ass => i_id_epis_prob_group_ass,
                                                     o_assessement            => o_assessement,
                                                     o_error                  => o_error)
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
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_PROB_GROUP_ASSESSMENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_assessement);
            RETURN FALSE;
    END get_prob_group_assessment;

    FUNCTION cancel_prob_group_assessment
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_id_epis_prob_group_ass IN epis_prob_group_assess.id_epis_prob_group_ass%TYPE,
        i_id_cancel_reason       IN cancel_reason.id_cancel_reason%TYPE,
        notes_cancel             IN CLOB,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'CANCEL_PROB_GROUP_ASSESSMENT',
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_prob_group_assessment;

    /********************************************************************************************
    **********************************************************************************************/

    FUNCTION check_dup_icd_problem
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_type           IN epis_diagnosis.flg_type%TYPE,
        i_id_diagnosis_list  IN table_number,
        i_id_alert_diag_list IN table_number,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT pk_problems.check_dup_icd_problem(i_lang               => i_lang,
                                                 i_prof               => i_prof,
                                                 i_episode            => i_episode,
                                                 i_flg_type           => i_flg_type,
                                                 i_id_diagnosis_list  => i_id_diagnosis_list,
                                                 i_id_alert_diag_list => i_id_alert_diag_list,
                                                 o_flg_show           => o_flg_show,
                                                 o_msg                => o_msg,
                                                 o_error              => o_error)
        THEN
            RETURN FALSE;
        END IF;
        IF o_msg IS NOT NULL
        THEN
            RETURN TRUE;
        END IF;
    
        RETURN TRUE;
    
    END check_dup_icd_problem;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END;
/
