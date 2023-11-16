/*-- Last Change Revision: $Rev: 1835713 $*/
/*-- Last Change by: $Author: alexander.camilo $*/
/*-- Date of last change: $Date: 2018-04-13 15:04:11 +0100 (sex, 13 abr 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_cdr_fo_ux IS

    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    g_exception EXCEPTION;

    /**
    * Checks the CDR engine for applicable rules.
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_concepts     rule concept identifiers list
    * @param i_elements     element identifiers list
    * @param i_dose         dosage values list
    * @param i_dose_um      dosage measurement units list
    * @param i_route        administration routes list
    * @param o_sect1        popup section 1 cursor
    * @param o_sect2        popup section 2 cursor
    * @param o_sect3        popup section 3 cursor
    * @param o_sect4        popup section 4 cursor
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Orlando Antunes
    * @version               2.6.1
    * @since                2011/02/10
    */
    FUNCTION check_rules
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_concepts IN table_number,
        i_elements IN table_varchar,
        i_dose     IN table_number,
        i_dose_um  IN table_number,
        i_route    IN table_varchar,
        i_screen_name IN VARCHAR2,
        o_sect1    OUT pk_types.cursor_type,
        o_sect2    OUT pk_types.cursor_type,
        o_sect3    OUT pk_types.cursor_type,
        o_sect4    OUT pk_types.cursor_type,
        o_call     OUT cdr_call.id_cdr_call%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_RULES';
    BEGIN
        g_error := 'CALL pk_cdr_fo_core.check_rules';
        IF NOT pk_cdr_fo_core.check_rules(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_patient  => i_patient,
                                          i_episode  => i_episode,
                                          i_concepts => i_concepts,
                                          i_elements => i_elements,
                                          i_dose     => i_dose,
                                          i_dose_um  => i_dose_um,
                                          i_route    => i_route,
                                          i_screen_name => i_screen_name,
                                          o_sect1    => o_sect1,
                                          o_sect2    => o_sect2,
                                          o_sect3    => o_sect3,
                                          o_sect4    => o_sect4,
                                          o_call     => o_call,
                                          o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
    END check_rules;

    /**
    * Checks the CDR engine for applicable rules.
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
    * Keeps history of previous engine calls.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_call         previous call identifier
    * @param i_concepts     rule concept identifiers list
    * @param i_elements     element identifiers list
    * @param i_dose         dosage values list
    * @param i_dose_um      dosage measurement units list
    * @param i_route        administration routes list
    * @param o_sect1        popup section 1 cursor
    * @param o_sect2        popup section 2 cursor
    * @param o_sect3        popup section 3 cursor
    * @param o_sect4        popup section 4 cursor
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Orlando Antunes
    * @version               2.6.1
    * @since                2011/02/10
    */
    FUNCTION check_rules
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_call     IN cdr_call.id_cdr_call%TYPE,
        i_concepts IN table_number,
        i_elements IN table_varchar,
        i_dose     IN table_number,
        i_dose_um  IN table_number,
        i_route    IN table_varchar,
        i_screen_name IN VARCHAR2,
        o_sect1    OUT pk_types.cursor_type,
        o_sect2    OUT pk_types.cursor_type,
        o_sect3    OUT pk_types.cursor_type,
        o_sect4    OUT pk_types.cursor_type,
        o_call     OUT cdr_call.id_cdr_call%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_RULES';
    BEGIN
        g_error := 'CALL pk_cdr_fo_core.check_rules';
        IF NOT pk_cdr_fo_core.check_rules(i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          i_patient  => i_patient,
                                          i_episode  => i_episode,
                                          i_call     => i_call,
                                          i_concepts => i_concepts,
                                          i_elements => i_elements,
                                          i_dose     => i_dose,
                                          i_dose_um  => i_dose_um,
                                          i_route    => i_route,
                                          i_screen_name => i_screen_name,
                                          o_sect1    => o_sect1,
                                          o_sect2    => o_sect2,
                                          o_sect3    => o_sect3,
                                          o_sect4    => o_sect4,
                                          o_call     => o_call,
                                          o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
    END check_rules;

    /**
    * Checks the CDR engine for applicable rules, using task types.
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_task_types   task type identifiers list
    * @param i_task_reqs    task request identifiers list
    * @param i_dose         dosage values list
    * @param i_dose_um      dosage measurement units list
    * @param i_route        administration routes list
    * @param o_sect1        popup section 1 cursor
    * @param o_sect2        popup section 2 cursor
    * @param o_sect3        popup section 3 cursor
    * @param o_sect4        popup section 4 cursor
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Orlando Antunes
    * @version               2.6.1
    * @since                2011/02/10
    */
    FUNCTION check_rules_tt
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_types   IN table_number,
        i_task_reqs    IN table_varchar,
        i_dose         IN table_number,
        i_dose_um      IN table_number,
        i_route        IN table_varchar,
        i_id_task_type IN task_type.id_task_type%TYPE, -- the area where check_rules is called
        i_screen_name  IN VARCHAR2,
        o_sect1        OUT pk_types.cursor_type,
        o_sect2        OUT pk_types.cursor_type,
        o_sect3        OUT pk_types.cursor_type,
        o_sect4        OUT pk_types.cursor_type,
        o_btn_config   OUT pk_types.cursor_type,
        o_call         OUT cdr_call.id_cdr_call%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_RULES_TT';
    BEGIN
        g_error := 'CALL pk_cdr_fo_core.check_rules';
        IF NOT pk_cdr_fo_core.check_rules_tt(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_patient      => i_patient,
                                             i_episode      => i_episode,
                                             i_task_types   => i_task_types,
                                             i_task_reqs    => i_task_reqs,
                                             i_dose         => i_dose,
                                             i_dose_um      => i_dose_um,
                                             i_route        => i_route,
                                             i_id_task_type => i_id_task_type,
											 i_screen_name  => i_screen_name,
                                             o_sect1        => o_sect1,
                                             o_sect2        => o_sect2,
                                             o_sect3        => o_sect3,
                                             o_sect4        => o_sect4,
                                             o_btn_config   => o_btn_config,
                                             o_call         => o_call,
                                             o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
    END check_rules_tt;

    /**
    * Checks the CDR engine for applicable rules, using task types.
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
    * Keeps history of previous engine calls.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_call         previous call identifier
    * @param i_task_types   task type identifiers list
    * @param i_task_reqs    task request identifiers list
    * @param i_dose         dosage values list
    * @param i_dose_um      dosage measurement units list
    * @param i_route        administration routes list
    * @param o_sect1        popup section 1 cursor
    * @param o_sect2        popup section 2 cursor
    * @param o_sect3        popup section 3 cursor
    * @param o_sect4        popup section 4 cursor
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Orlando Antunes
    * @version               2.6.1
    * @since                2011/02/10
    */

    FUNCTION check_rules_tt
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_call       IN cdr_call.id_cdr_call%TYPE,
        i_task_types IN table_number,
        i_task_reqs  IN table_varchar,
        i_dose       IN table_number,
        i_dose_um    IN table_number,
        i_route      IN table_varchar,
        i_screen_name IN VARCHAR2,
        o_sect1      OUT pk_types.cursor_type,
        o_sect2      OUT pk_types.cursor_type,
        o_sect3      OUT pk_types.cursor_type,
        o_sect4      OUT pk_types.cursor_type,
        o_btn_config  OUT pk_types.cursor_type,
        o_call       OUT cdr_call.id_cdr_call%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_RULES_TT';
    BEGIN
        g_error := 'CALL pk_cdr_fo_core.check_rules';
        IF NOT pk_cdr_fo_core.check_rules_tt(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_patient      => i_patient,
                                             i_episode      => i_episode,
                                             i_call         => i_call,
                                             i_task_types   => i_task_types,
                                             i_task_reqs    => i_task_reqs,
                                             i_dose         => i_dose,
                                             i_dose_um      => i_dose_um,
                                             i_route        => i_route,
                                             i_id_task_type => NULL, -- the area where check_rules is called
                                             i_screen_name  => i_screen_name,
                                             o_sect1        => o_sect1,
                                             o_sect2        => o_sect2,
                                             o_sect3        => o_sect3,
                                             o_sect4        => o_sect4,
                                             o_btn_config   => o_btn_config,
                                             o_call         => o_call,
                                             o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
    END check_rules_tt;

    /**
    * Checks the CDR engine for applicable rules in the given areas.
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_area         area identifiers list
    * @param o_sect1        popup section 1 cursor
    * @param o_sect2        popup section 2 cursor
    * @param o_sect3        popup section 3 cursor
    * @param o_sect4        popup section 4 cursor
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.3
    * @since                2011/10/07
    */
    FUNCTION check_rules_area
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_area    IN table_number,
        o_sect1   OUT pk_types.cursor_type,
        o_sect2   OUT pk_types.cursor_type,
        o_sect3   OUT pk_types.cursor_type,
        o_sect4   OUT pk_types.cursor_type,
        o_call    OUT cdr_call.id_cdr_call%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_RULES_AREA';
    BEGIN
        g_error := 'CALL pk_cdr_fo_core.check_rules_area';
        IF NOT pk_cdr_fo_core.check_rules_area(i_lang    => i_lang,
                                               i_prof    => i_prof,
                                               i_patient => i_patient,
                                               i_episode => i_episode,
                                               i_area    => i_area,
                                               o_sect1   => o_sect1,
                                               o_sect2   => o_sect2,
                                               o_sect3   => o_sect3,
                                               o_sect4   => o_sect4,
                                               o_call    => o_call,
                                               o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
    END check_rules_area;

    /**
    * Set the user's answer to the warnings.
    * Outputs the list of elements that were chosen to proceed.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_answers      answer identifiers list
    * @param i_concepts     rule concept identifiers list (user input)
    * @param i_elements     element identifiers list (user input)
    * @param i_call         call identifier
    * @param i_cdripas      rule instance parameter action identifiers list
    * @param i_ans_notes    answer notes list
    * @param o_concepts     rule concept identifiers list (filtered)
    * @param o_elements     element identifiers list (filtered)
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/26
    */
    FUNCTION set_answer
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_answers   IN table_number,
        i_concepts  IN table_number,
        i_elements  IN table_varchar,
        i_call      IN cdr_call.id_cdr_call%TYPE,
        i_cdripas   IN table_number,
        i_ans_notes IN table_clob,
        i_domain_value     IN table_varchar DEFAULT table_varchar(),
        i_domain_free_text IN table_varchar DEFAULT table_varchar(),
        o_concepts  OUT table_number,
        o_elements  OUT table_varchar,
        o_call      OUT cdr_call.id_cdr_call%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_ANSWER';
    BEGIN
        g_error := 'CALL pk_cdr_fo_core.set_answer';
        IF NOT pk_cdr_fo_core.set_answer(i_lang      => i_lang,
                                         i_prof      => i_prof,
                                         i_patient   => i_patient,
                                         i_episode   => i_episode,
                                         i_concepts  => i_concepts,
                                         i_elements  => i_elements,
                                         i_call      => i_call,
                                         i_cdripas   => i_cdripas,
                                         i_answers   => i_answers,
                                         i_ans_notes => i_ans_notes,
                                         i_domain_value     => i_domain_value,
                                         i_domain_free_text => i_domain_free_text,
                                         o_concepts  => o_concepts,
                                         o_elements  => o_elements,
                                         o_call      => o_call,
                                         o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_answer;

    /**
    * Set the user's answer to the warnings, using task types.
    * Outputs the list of task types that were chosen to proceed.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_answers      answer identifiers list
    * @param i_task_types   task type identifiers list (user input)
    * @param i_task_reqs    task request identifiers list (user input)
    * @param i_call         call identifier
    * @param i_cdripas      rule instance parameter action identifiers list
    * @param i_ans_notes    answer notes list
    * @param o_task_types   task type identifiers list (filtered)
    * @param o_task_reqs    task request identifiers list (filtered)
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/06
    */
    FUNCTION set_answer_tt
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_answers    IN table_number,
        i_task_types IN table_number,
        i_task_reqs  IN table_varchar,
        i_call       IN cdr_call.id_cdr_call%TYPE,
        i_cdripas    IN table_number,
        i_ans_notes  IN table_clob,
        i_domain_value     IN table_varchar DEFAULT table_varchar(),
        i_domain_free_text IN table_varchar DEFAULT table_varchar(),
        o_task_types OUT table_number,
        o_task_reqs  OUT table_varchar,
        o_call       OUT cdr_call.id_cdr_call%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_ANSWER_TT';
    BEGIN
        g_error := 'CALL pk_cdr_fo_core.set_answer_tt';
        IF NOT pk_cdr_fo_core.set_answer_tt(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_patient    => i_patient,
                                            i_episode    => i_episode,
                                            i_task_types => i_task_types,
                                            i_task_reqs  => i_task_reqs,
                                            i_call       => i_call,
                                            i_cdripas    => i_cdripas,
                                            i_answers    => i_answers,
                                            i_ans_notes  => i_ans_notes,
                                            i_domain_value     => i_domain_value,
                                            i_domain_free_text => i_domain_free_text,
                                            o_task_types => o_task_types,
                                            o_task_reqs  => o_task_reqs,
                                            o_call       => o_call,
                                            o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_answer_tt;

    /**
    * Set the user's answer to the warnings.
    * Does not interact with user input.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_answers      answer identifiers list
    * @param i_call         call identifier
    * @param i_cdripas      rule instance parameter action identifiers list
    * @param i_ans_notes    answer notes list
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.3
    * @since                2011/10/07
    */
    FUNCTION set_answer
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_answers   IN table_number,
        i_call      IN cdr_call.id_cdr_call%TYPE,
        i_cdripas   IN table_number,
        i_ans_notes IN table_clob,
        i_domain_value     IN table_varchar DEFAULT table_varchar(),
        i_domain_free_text IN table_varchar DEFAULT table_varchar(),
        o_call      OUT cdr_call.id_cdr_call%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_ANSWER';
    BEGIN
        g_error := 'CALL pk_cdr_fo_core.set_answer';
        IF NOT pk_cdr_fo_core.set_answer(i_lang      => i_lang,
                                         i_prof      => i_prof,
                                         i_patient   => i_patient,
                                         i_episode   => i_episode,
                                         i_call      => i_call,
                                         i_cdripas   => i_cdripas,
                                         i_answers   => i_answers,
                                         i_ans_notes => i_ans_notes,
										 i_domain_value     => i_domain_value,
                                         i_domain_free_text => i_domain_free_text,
                                         o_call      => o_call,
                                         o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_answer;

    /**
    * Get warning answers.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param o_actions      actions cursor
    * @param o_answers      answers cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/03/14
    */
    FUNCTION get_warning_answers
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_answers OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_WARNING_ANSWERS';
    BEGIN
        g_error := 'CALL pk_cdr_fo_core.get_warning_answers';
        IF NOT pk_cdr_fo_core.get_warning_answers(i_lang    => i_lang,
                                                  i_prof    => i_prof,
                                                  o_actions => o_actions,
                                                  o_answers => o_answers,
                                                  o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_actions);
            pk_types.open_my_cursor(o_answers);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_actions);
            pk_types.open_my_cursor(o_answers);
            RETURN FALSE;
    END get_warning_answers;

    FUNCTION get_cdr_doc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_cdr_doc_instance IN cdr_doc.id_cdr_doc_instance%TYPE,
        o_title               OUT VARCHAR2,
        o_info                OUT CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_CDR_DOC';
    BEGIN
        g_error := 'CALL PK_CDR_FO_CORE.GET_CDR_DOC';
    
        IF NOT pk_cdr_fo_core.get_cdr_doc(i_lang                => i_lang,
                                          i_prof                => i_prof,
                                          i_id_cdr_doc_instance => i_id_cdr_doc_instance,
                                          o_title               => o_title,
                                          o_info                => o_info,
                                          o_error               => o_error)
        
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            --            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_cdr_doc;

    FUNCTION get_all_ges
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_call  IN NUMBER,
        o_ges   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_cdr_fo_core.get_all_ges(i_lang  => i_lang,
                                          i_prof  => i_prof,
                                          i_call  => i_call,
                                          o_ges   => o_ges,
                                          o_error => o_error);
    
    END get_all_ges;

    /**
    * Checks the CDR engine for applicable rules, using task types. - EMR-2225 (Receive Array)
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_xml          xml array
    * @param i_task_types   task type identifiers list
    * @param o_sect1        popup section 1 cursor
    * @param o_sect2        popup section 2 cursor
    * @param o_sect3        popup section 3 cursor
    * @param o_sect4        popup section 4 cursor
    * @param o_call         call identifier
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Alexander Camilo
    * @version              2.7.3
    * @since                2018/04/04
    */
    FUNCTION check_rules_tt
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_types   IN table_number,
        i_task_reqs    IN table_varchar,
        i_xml          IN table_varchar,
        i_id_task_type IN task_type.id_task_type%TYPE, -- the area where check_rules is called
        i_screen_name  IN VARCHAR2,
        o_sect1        OUT pk_types.cursor_type,
        o_sect2        OUT pk_types.cursor_type,
        o_sect3        OUT pk_types.cursor_type,
        o_sect4        OUT pk_types.cursor_type,
        o_btn_config   OUT pk_types.cursor_type,
        o_call         OUT cdr_call.id_cdr_call%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_RULES_TT';
    BEGIN
        g_error := 'CALL pk_cdr_fo_core.check_rules';
        IF NOT pk_cdr_fo_core.check_rules_tt(i_lang         => i_lang,
                                             i_prof         => i_prof,
                                             i_patient      => i_patient,
                                             i_episode      => i_episode,
                                             i_task_types   => i_task_types,
                                             i_task_reqs    => i_task_reqs,
                                             i_dose         => NULL,
                                             i_dose_um      => NULL,
                                             i_route        => NULL,
                                             i_xml          => i_xml,
                                             i_id_task_type => i_id_task_type, -- the area where check_rules is called
                                             i_screen_name  => i_screen_name,
                                             o_sect1        => o_sect1,
                                             o_sect2        => o_sect2,
                                             o_sect3        => o_sect3,
                                             o_sect4        => o_sect4,
                                             o_btn_config   => o_btn_config,
                                             o_call         => o_call,
                                             o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_sect1);
            pk_types.open_my_cursor(o_sect2);
            pk_types.open_my_cursor(o_sect3);
            pk_types.open_my_cursor(o_sect4);
            RETURN FALSE;
    END check_rules_tt;	
	
BEGIN
    -- log initialization
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    pk_alertlog.log_init(object_name => g_package);
END pk_cdr_fo_ux;
/
