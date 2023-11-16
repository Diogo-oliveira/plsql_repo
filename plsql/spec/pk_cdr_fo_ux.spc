/*-- Last Change Revision: $Rev: 1835713 $*/
/*-- Last Change by: $Author: alexander.camilo $*/
/*-- Date of last change: $Date: 2018-04-13 15:04:11 +0100 (sex, 13 abr 2018) $*/

CREATE OR REPLACE PACKAGE pk_cdr_fo_ux IS

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    * @param o_btn_config   popup buttons config
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
    ) RETURN BOOLEAN;

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
    * @param o_btn_config   popup buttons config
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    FUNCTION get_cdr_doc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_cdr_doc_instance IN cdr_doc.id_cdr_doc_instance%TYPE,
        o_title               OUT VARCHAR2,
        o_info                OUT CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * Get all ges from patient file.
     *
     * @param i_lang         language identifier
    * @param i_prof         logged professional structure
     * @param i_call         id_cdr_call generated
     * @param o_ges          cursor with records with triggered exemption
     * @param o_error        error
     *
     * @return               false if errors occur, true otherwise
     *
     * @author               Carlos Ferreira
     * @version               2.6.5.0.1
     * @since                2015/04/20
     */
    FUNCTION get_all_ges
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_call  IN NUMBER,
        o_ges   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

	
    /**
    * Checks the CDR engine for applicable rules, using task types. - EMR-2452 (Receive Array)
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
    ) RETURN BOOLEAN;

END pk_cdr_fo_ux;
/

	
END pk_cdr_fo_ux;
/
