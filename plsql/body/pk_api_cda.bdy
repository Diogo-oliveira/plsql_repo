/*-- Last Change Revision: $Rev: 2026668 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_cda IS

    /* CAN'T TOUCH THIS */
    g_error    VARCHAR2(1000 CHAR);
    g_owner    VARCHAR2(30 CHAR);
    g_package  VARCHAR2(30 CHAR);
    g_function VARCHAR2(128 CHAR);
    g_exception EXCEPTION;

    -- Function and procedure implementations

    /***********************************************************************
                           GLOBAL - Generic Functions
    ***********************************************************************/

    FUNCTION get_pat_problems
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_problems   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_unawareness_active   pk_types.cursor_type;
        l_unawareness_outdated pk_types.cursor_type;
    BEGIN
        g_function := 'get_pat_problem';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_problems.get_pat_problem_report(i_lang                 => i_lang,
                                                  i_pat                  => i_id_patient,
                                                  i_prof                 => i_prof,
                                                  i_episode              => i_id_episode,
                                                  i_report               => i_scope,
                                                  i_dt_ini               => NULL,
                                                  i_dt_end               => NULL,
                                                  i_show_hist            => pk_alert_constant.g_no,
                                                  o_pat_problem          => o_problems,
                                                  o_unawareness_active   => l_unawareness_active,
                                                  o_unawareness_outdated => l_unawareness_outdated,
                                                  o_error                => o_error);
    
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
            pk_types.open_my_cursor(o_problems);
            RETURN FALSE;
    END get_pat_problems;

    FUNCTION get_pat_lab_tests_results
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_scope                       IN VARCHAR2,
        i_id_patient                  IN patient.id_patient%TYPE,
        i_id_episode                  IN episode.id_episode%TYPE,
        i_id_visit                    IN episode.id_episode%TYPE,
        o_serialized_analysis_columns OUT pk_types.cursor_type,
        o_serialized_analysis_rows    OUT pk_types.cursor_type,
        o_serialized_analysis_values  OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    BEGIN
        g_function := 'get_lab_tests_results';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        CASE i_scope
            WHEN 'E' THEN
                l_id_episode := i_id_episode;
                l_id_visit   := pk_episode.get_id_visit(i_episode => i_id_episode);
            WHEN 'P' THEN
                l_id_episode := NULL;
                l_id_visit   := NULL;
            WHEN 'V' THEN
                l_id_episode := NULL;
                l_id_visit   := pk_episode.get_id_visit(i_episode => i_id_episode);
        END CASE;
    
        RETURN pk_lab_tests_external_api_db.get_reports_table1(i_lang,
                                                               i_prof,
                                                               i_id_patient,
                                                               NULL,
                                                               l_id_episode,
                                                               l_id_visit,
                                                               'A',
                                                               NULL,
                                                               NULL,
                                                               o_serialized_analysis_columns,
                                                               o_serialized_analysis_rows,
                                                               o_serialized_analysis_values,
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
            pk_types.open_my_cursor(o_serialized_analysis_columns);
            pk_types.open_my_cursor(o_serialized_analysis_rows);
            pk_types.open_my_cursor(o_serialized_analysis_values);
            RETURN FALSE;
    END get_pat_lab_tests_results;

    /********************************************************************************************
    * Get patient allergies
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)  
    * @param i_scope                  Episode (E) / Patient (P) / Visit (V)
    * @param i_id_patient             Patient identifier
    * @param i_id_episode             Episode identifier
    * @param i_id_visit               Visit identifier
    * @param o_allergies              Allergies list
    * @param o_error                  Error message
    *
    * @return                         true or false on success or error
    *
    * @author                Tiago Lourenço
    * @version               2.6.1
    * @since                 5-May-2011
    ********************************************************************************************/
    FUNCTION get_pat_allergies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_allergies  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    BEGIN
        g_function := 'get_pat_allergies';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        CASE i_scope
            WHEN 'E' THEN
                l_id_episode := i_id_episode;
                l_id_visit   := i_id_visit;
            WHEN 'P' THEN
                l_id_episode := NULL;
                l_id_visit   := NULL;
            WHEN 'V' THEN
                l_id_episode := NULL;
                l_id_visit   := pk_episode.get_id_visit(i_episode => i_id_episode);
        END CASE;
    
        RETURN pk_allergy.get_allergy_list_cda(i_lang, i_prof, i_id_patient, l_id_episode, o_allergies, o_error);
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
            pk_types.open_my_cursor(o_allergies);
            RETURN FALSE;
    END get_pat_allergies;

    FUNCTION get_pat_surgical_procedures
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_surg_hist  OUT pk_types.cursor_type,
        o_interv     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_context                NUMBER;
        l_labels                    pk_types.cursor_type;
        l_interv_supplies           pk_types.cursor_type;
        l_interv_clinical_questions pk_types.cursor_type;
    
    BEGIN
        g_function := 'get_pat_surgical_procedures';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        CASE i_scope
            WHEN 'E' THEN
                l_id_context := i_id_episode;
            WHEN 'P' THEN
                l_id_context := i_id_patient;
            WHEN 'V' THEN
                l_id_context := pk_episode.get_id_visit(i_episode => i_id_episode);
        END CASE;
    
        IF NOT (pk_past_history.get_past_hist_surgical_api(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_id_context       => l_id_context,
                                                           i_flg_type_context => i_scope,
                                                           o_doc_area         => o_surg_hist,
                                                           o_error            => o_error))
        THEN
            g_error := 'Error calling [pk_past_history.get_past_hist_surgical_api]';
            g_error := g_error || '[' || o_error.ora_sqlcode || '][' || o_error.ora_sqlerrm || '][' || o_error.err_desc || '][' ||
                       o_error.err_action || '][' || o_error.log_id || ']';
            alertlog.pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => g_function);
            pk_types.open_my_cursor(o_surg_hist);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
        END IF;
    
        IF NOT (pk_sr_planning.get_summ_interv_api(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_id_context                => l_id_context,
                                                   i_flg_type_context          => i_scope,
                                                   o_interv                    => o_interv,
                                                   o_labels                    => l_labels,
                                                   o_interv_supplies           => l_interv_supplies,
                                                   o_interv_clinical_questions => l_interv_clinical_questions,
                                                   o_error                     => o_error))
        THEN
            g_error := 'Error calling [pk_sr_planning.get_summ_interv_api]';
            g_error := g_error || '[' || o_error.ora_sqlcode || '][' || o_error.ora_sqlerrm || '][' || o_error.err_desc || '][' ||
                       o_error.err_action || '][' || o_error.log_id || ']';
            alertlog.pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => g_function);
            pk_types.open_my_cursor(o_interv);
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
            pk_types.open_my_cursor(o_surg_hist);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
    END get_pat_surgical_procedures;

    FUNCTION get_pat_medication
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_visit   IN visit.id_visit%TYPE,
        o_medication OUT CLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_visit visit.id_visit%TYPE;
    BEGIN
        g_function := 'get_pat_medication';
        g_error    := 'Init: [' || i_scope || '][' || i_id_patient || '][' || i_id_episode || '][' || i_id_visit || ']';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        CASE i_scope
            WHEN 'E' THEN
                l_id_visit := pk_episode.get_id_visit(i_episode => i_id_episode);
            WHEN 'P' THEN
                l_id_visit := NULL;
            WHEN 'V' THEN
                l_id_visit := pk_episode.get_id_visit(i_episode => i_id_episode);
        END CASE;
    
        g_error := 'Execution code: [' || i_id_patient || '][' || l_id_visit || ']';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        o_medication := pk_api_pfh_in.get_list_medication_aggr(i_lang       => i_lang,
                                                               i_prof       => i_prof,
                                                               i_id_patient => i_id_patient,
                                                               i_id_visit   => l_id_visit,
                                                               i_id_presc   => NULL,
                                                               o_error      => o_error);
    
        IF (o_error IS NULL)
        THEN
            g_error := 'Returning: ' || dbms_lob.substr(o_medication, amount => 100, offset => 1);
            alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
            RETURN TRUE;
        ELSE
            g_error := 'Error calling pk_api_pfh_in.get_list_medication_aggr';
            alertlog.pk_alertlog.log_error(text => g_error, object_name => g_package, sub_object_name => g_function);
            RETURN FALSE;
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
    END get_pat_medication;

BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_api_cda;
/
