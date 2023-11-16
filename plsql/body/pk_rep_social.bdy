/*-- Last Change Revision: $Rev: 1896678 $*/
/*-- Last Change by: $Author: nuno.coelho $*/
/*-- Date of last change: $Date: 2019-03-12 10:04:16 +0000 (ter, 12 mar 2019) $*/

CREATE OR REPLACE PACKAGE BODY pk_rep_social IS

    g_error         VARCHAR2(1000 CHAR);
    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

    /**
    * Get an episode's follow up notes list.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      actual episode identifier
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up    follow up notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/03/02
    */
    FUNCTION get_followup_notes_rep
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
		i_show_cancelled IN VARCHAR2 DEFAULT NULL,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_FOLLOWUP_NOTES_REP';
    BEGIN
        g_error := 'CALL pk_paramedical_prof_core.get_followup_notes_rep';
        IF NOT pk_paramedical_prof_core.get_followup_notes_rep(i_lang           => i_lang,
                                                               i_prof           => i_prof,
                                                               i_episode        => i_episode,
															   i_show_cancelled => i_show_cancelled,
                                                               o_follow_up_prof => o_follow_up_prof,
                                                               o_follow_up      => o_follow_up,
                                                               o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up_prof);
            pk_types.open_my_cursor(o_follow_up);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_follow_up_prof);
            pk_types.open_my_cursor(o_follow_up);
            RETURN FALSE;
    END get_followup_notes_rep;

    /**
    * Get an episode's discharge record history.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      actual episode identifier
    * @param o_discharge    discharges
    * @param o_discharge_prof discharges records info
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/03/09
    */
    FUNCTION get_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DISCHARGE';
    BEGIN
        g_error := 'CALL pk_discharge_amb.get_discharge';
        IF NOT pk_discharge_amb.get_discharge(i_lang           => i_lang,
                                              i_prof           => i_prof,
                                              i_episode        => i_episode,
                                              o_discharge      => o_discharge,
                                              o_discharge_prof => o_discharge_prof,
                                              o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            pk_types.open_my_cursor(o_discharge_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_discharge);
            pk_types.open_my_cursor(o_discharge_prof);
            RETURN FALSE;
    END get_discharge;

    /**
    * Get the EHR social summary.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param o_labels       labels
    * @param o_episodes_det episodes
    * @param o_diagnosis    social diagnoses
    * @param o_interv_plan  social intervention plans
    * @param o_follow_up    follow up notes
    * @param o_soc_report   social report
    * @param o_soc_request  previous encounters data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/12
    */
    FUNCTION get_social_summary_ehr_rep
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_labels       OUT pk_types.cursor_type,
        o_episodes_det OUT pk_types.cursor_type,
        o_diagnosis    OUT pk_types.cursor_type,
        o_interv_plan  OUT pk_types.cursor_type,
        o_follow_up    OUT pk_types.cursor_type,
        o_soc_report   OUT pk_types.cursor_type,
        o_soc_request  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SOCIAL_SUMMARY_EHR_REP';
    BEGIN
        g_error := 'CALL pk_social.get_social_summary_ehr_rep';
        IF NOT pk_social.get_social_summary_ehr_rep(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_patient      => i_patient,
                                                    o_labels       => o_labels,
                                                    o_episodes_det => o_episodes_det,
                                                    o_diagnosis    => o_diagnosis,
                                                    o_interv_plan  => o_interv_plan,
                                                    o_follow_up    => o_follow_up,
                                                    o_soc_report   => o_soc_report,
                                                    o_soc_request  => o_soc_request,
                                                    o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_labels);
            pk_types.open_my_cursor(i_cursor => o_episodes_det);
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
            pk_types.open_my_cursor(i_cursor => o_interv_plan);
            pk_types.open_my_cursor(i_cursor => o_follow_up);
            pk_types.open_my_cursor(i_cursor => o_soc_report);
            pk_types.open_my_cursor(i_cursor => o_soc_request);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_labels);
            pk_types.open_my_cursor(i_cursor => o_episodes_det);
            pk_types.open_my_cursor(i_cursor => o_diagnosis);
            pk_types.open_my_cursor(i_cursor => o_interv_plan);
            pk_types.open_my_cursor(i_cursor => o_follow_up);
            pk_types.open_my_cursor(i_cursor => o_soc_report);
            pk_types.open_my_cursor(i_cursor => o_soc_request);
            RETURN FALSE;
    END get_social_summary_ehr_rep;

BEGIN
    -- Log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    pk_alertlog.log_init(object_name => g_package_name);
END pk_rep_social;
/
