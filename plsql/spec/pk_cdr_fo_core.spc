/*-- Last Change Revision: $Rev: 2028555 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_cdr_fo_core IS

    /**
    * Condition procedure: check if the patient's age is within range.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_age
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if an allergy is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_allergy
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if a ddi is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.1
    * @since                2011/05/30
    */
    PROCEDURE check_ddi
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if a diagnosis synonym is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/11/22
    */
    PROCEDURE check_diag_synonym
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if a diagnosis is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_diagnosis
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if an drug group is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.1
    * @since                2012/02/24
    */
    PROCEDURE check_drug_group
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if an exam is requested in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_exam_req
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if an exam request is duplicate in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_exam_req_dup
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if the patient is of a given gender.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_gender
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if an ingredient is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.1
    * @since                2011/05/30
    */
    PROCEDURE check_ingredient
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if an ingredient group is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.1
    * @since                2011/05/30
    */
    PROCEDURE check_ingredient_group
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if a lab test is requested in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_lab_test_req
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if an lab test request is duplicate in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_lab_test_req_dup
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if a lab test result is within range.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_lab_test_res
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if a lab test result was registered after
    * the last acknowledgment of a recommendation.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/08
    */
    PROCEDURE check_ltr_after_rcm_ack
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if the patient is pregnant.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_pregnancy
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if a pregnancy is within a time range.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/09/08
    */
    PROCEDURE check_pregnancy_time
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if a product is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.1
    * @since                2011/05/30
    */
    PROCEDURE check_product
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if a surgical procedure is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_sr_proc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Condition procedure: check if a procedure is registered in the EHR.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/04/19
    */
    PROCEDURE check_procedure
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Get values domain description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_val_min      minimum value
    * @param i_val_max      maximum value
    * @param i_domain_um    domain measurement unit
    *
    * @return               values domain description
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/05/09
    */
    FUNCTION get_val_domain_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_val_min   IN cdr_inst_param.val_min%TYPE,
        i_val_max   IN cdr_inst_param.val_max%TYPE,
        i_domain_um IN cdr_inst_param.id_domain_umea%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Get element translation.
    * TODO: this function is temporary. Should be replaced by
    * the calls to CDR_CONCEPT.SERVICE_DESC.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_concept      rule concept identifier
    * @param i_element      element identifier
    * @param i_task_req     task request identifier
    *
    * @return               element description
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/05/10
    */
    FUNCTION get_elem_translation
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_concept  IN cdr_concept.id_cdr_concept%TYPE,
        i_element  IN cdr_inst_param.id_element%TYPE,
        i_task_req IN cdr_call_det.id_task_request%TYPE := NULL,
        i_call     IN cdr_call.id_cdr_call%TYPE := NULL
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Get "Triggered by" field description.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_call         call identifier
    * @param i_instance     rule instance identifier
    *
    * @return               "triggered by" description
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/05/10
    */
    FUNCTION get_triggered_by
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_call     IN cdr_call.id_cdr_call%TYPE,
        i_instance IN cdr_instance.id_cdr_instance%TYPE
    ) RETURN CLOB;

    /**
    * Is the notes field mandatory? Y/N
    *
    * @param i_answer       answer identifier
    * @param i_cdrs         rule severity identifier
    * @param i_institution  institution identifier
    *
    * @return               'Y', if notes are mandatory, 'N' otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/03/09
    */
    FUNCTION get_notes_mandatory
    (
        i_answer      IN cdr_answer.id_cdr_answer%TYPE,
        i_cdrs        IN cdr_severity.id_cdr_severity%TYPE,
        i_institution IN institution.id_institution%TYPE
    ) RETURN cdr_answer.flg_req_notes%TYPE;

    /**
    * Get the description of all instance elements.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_instance     rule instance identifiers list
    * @param o_msg          element descriptions cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/05/09
    */
    FUNCTION get_inst_elems
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_instances IN table_number,
        o_element   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks the CDR engine for applicable rules.
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
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
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_call        IN cdr_call.id_cdr_call%TYPE := NULL,
        i_concepts    IN table_number,
        i_elements    IN table_varchar,
        i_dose        IN table_number,
        i_dose_um     IN table_number,
        i_route       IN table_varchar,
        i_screen_name IN VARCHAR2,
        o_sect1       OUT pk_types.cursor_type,
        o_sect2       OUT pk_types.cursor_type,
        o_sect3       OUT pk_types.cursor_type,
        o_sect4       OUT pk_types.cursor_type,
        o_call        OUT cdr_call.id_cdr_call%TYPE,
        o_error       OUT t_error_out
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
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_call         IN cdr_call.id_cdr_call%TYPE := NULL,
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
    ) RETURN BOOLEAN;

    /**
    * Set the user's answer to the warnings.
    * Outputs the list of elements that were chosen to proceed.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_concepts     rule concept identifiers list (user input)
    * @param i_elements     element identifiers list (user input)
    * @param i_call         call identifier
    * @param i_cdripas      rule instance parameter action identifiers list
    * @param i_answers      answer identifiers list
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
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_concepts         IN table_number,
        i_elements         IN table_varchar,
        i_call             IN cdr_call.id_cdr_call%TYPE,
        i_cdripas          IN table_number,
        i_answers          IN table_number,
        i_ans_notes        IN table_clob,
        i_domain_value     IN table_varchar DEFAULT table_varchar(),
        i_domain_free_text IN table_varchar DEFAULT table_varchar(),
        o_concepts         OUT table_number,
        o_elements         OUT table_varchar,
        o_call             OUT cdr_call.id_cdr_call%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set the user's answer to the warnings, using task types.
    * Outputs the list of task types that were chosen to proceed.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_task_types   task type identifiers list (user input)
    * @param i_task_reqs    task request identifiers list (user input)
    * @param i_call         call identifier
    * @param i_cdripas      rule instance parameter action identifiers list
    * @param i_answers      answer identifiers list
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
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_task_types       IN table_number,
        i_task_reqs        IN table_varchar,
        i_call             IN cdr_call.id_cdr_call%TYPE,
        i_cdripas          IN table_number,
        i_answers          IN table_number,
        i_ans_notes        IN table_clob,
        i_domain_value     IN table_varchar DEFAULT table_varchar(),
        i_domain_free_text IN table_varchar DEFAULT table_varchar(),
        o_task_types       OUT table_number,
        o_task_reqs        OUT table_varchar,
        o_call             OUT cdr_call.id_cdr_call%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set the user's answer to the warnings.
    * Does not interact with user input.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_call         call identifier
    * @param i_cdripas      rule instance parameter action identifiers list
    * @param i_answers      answer identifiers list
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
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_call             IN cdr_call.id_cdr_call%TYPE,
        i_cdripas          IN table_number,
        i_answers          IN table_number,
        i_ans_notes        IN table_clob,
        i_domain_value     IN table_varchar DEFAULT table_varchar(),
        i_domain_free_text IN table_varchar DEFAULT table_varchar(),
        o_call             OUT cdr_call.id_cdr_call%TYPE,
        o_error            OUT t_error_out
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

    /**
    * Get information on a CDR engine call.
    * The call events are filtered by the input task types.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_call         call identifier
    * @param i_task_types   task type identifiers list
    * @param i_task_reqs    task request identifiers list
    * @param o_icon         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/12/13
    */
    FUNCTION get_call_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_call       IN cdr_call.id_cdr_call%TYPE,
        i_task_types IN table_number,
        i_task_reqs  IN table_varchar,
        o_info       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates the prescription identifier.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_presc_old    outdated prescription identifier
    * @param i_presc_new    updated prescription identifier
    * @param o_error        error
    *
    * @author               Pedro Carneiro
    * @version               2.6.2?
    * @since                2011/09/28
    */
    PROCEDURE set_prescription
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_presc_old IN cdr_call_det.id_task_request%TYPE,
        i_presc_new IN cdr_call_det.id_task_request%TYPE,
        o_error     OUT t_error_out
    );

    /**
    * check if given task type is being considered in cdr processing
    *
    * @param i_task_type    task type id
    *
    * @return  varchar2     flag that indicates if task type is supported or not within cdr 
    *
    * @value   i_filter     {*} 'Y' given task type is supported in cdr
    *                       {*} 'N' given task type is not supported in cdr
    *
    * @author               Carlos Loureiro
    * @since                2011/10/20
    */
    FUNCTION check_cdr_support(i_task_type IN cdr_concept_task_type.id_task_type%TYPE) RETURN VARCHAR2;

    /**
    * 
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Mário Mineiro
    * @version               
    * @since                
    */
    PROCEDURE check_severity_scores
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Mário Mineiro
    * @version              2.6.3.8.5 
    * @since                11-11-2013
    */
    PROCEDURE check_med_extern
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Get "Triggered by" field description EXTERNAL.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_call         call identifier
    * @param i_instance     rule instance identifier
    *
    * @return               "triggered by" description
    *
    * @author               Mário Mineiro
    * @version               2.6.3
    * @since                2014/01/14
    */
    FUNCTION get_triggered_by_external
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_call         IN cdr_call.id_cdr_call%TYPE,
        i_cdr_external IN cdr_external.id_cdr_external%TYPE
    ) RETURN CLOB;

    PROCEDURE check_vs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    FUNCTION get_cdr_doc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_cdr_doc_instance IN cdr_doc.id_cdr_doc_instance%TYPE,
        o_title               OUT VARCHAR2,
        o_info                OUT CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cdr_task_type_filter
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN task_type.id_task_type%TYPE,
        o_flg_filter   OUT table_varchar,
        o_severity     OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets a a description for a given cdr type and cdr severity
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_market         institution market
    * @param i_cdr_type       type of cdr
    * @param i_cdr_severity   type of severity
    *
    * @return                 translation code
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.5
    * @since                  2015/03/12
    **********************************************************************************************/
    FUNCTION get_type_severity_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_market       IN market.id_market%TYPE,
        i_cdr_type     IN cdr_type.id_cdr_type%TYPE,
        i_cdr_severity IN cdr_severity.id_cdr_severity%TYPE
    ) RETURN VARCHAR2;

    -- temporary tem de ir para o pk_constant...
    g_id_cdr_call cdr_call.id_cdr_call%TYPE;

    /**
    * Condition procedure: check ges
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_mode         condition execution mode
    * @param i_input        input parameters
    * @param i_inst_par     fully-instantiated parameters list
    * @param o_ret          output
    * @param o_applic       condition applicability
    * @param o_error        error
    *
    * @author               Carlos El Ferreira
    * @version               2.6.5.0
    * @since                2015 e pozinhos...
    */
    PROCEDURE check_ges
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_mode     IN PLS_INTEGER,
        i_input    IN t_coll_cdr_in,
        i_inst_par IN t_coll_cdrip,
        o_ret      OUT t_coll_cdr_out,
        o_applic   OUT PLS_INTEGER,
        o_error    OUT t_error_out
    );

    /**
    * Get warnings popup sections of a given CDR engine call.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_call         call identifier
    * @param i_use_input    was user input used in this call? Y/N
    * @param o_sect1        popup section 1 cursor
    * @param o_sect2        popup section 2 cursor
    * @param o_sect3        popup section 3 cursor
    * @param o_sect4        popup section 4 cursor
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/03/07
    */
    PROCEDURE get_popup_sections
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_call         IN cdr_call.id_cdr_call%TYPE,
        i_use_input    IN VARCHAR2,
        i_id_task_type IN task_type.id_task_type%TYPE DEFAULT NULL,
        o_sect1        OUT pk_types.cursor_type,
        o_sect2        OUT pk_types.cursor_type,
        o_sect3        OUT pk_types.cursor_type,
        o_sect4        OUT pk_types.cursor_type
    );

    FUNCTION get_all_ges
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_call  IN NUMBER,
        o_ges   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_id_isencao(i_id_content IN VARCHAR2) RETURN NUMBER;

    /**
    * inserts array of names of screens into cdr_screens table
    *
    * @param i_screen_name  name of ux screen, used as identifier
    * @param i_Desc         Description of screen
    *
    * @author               Carlos Ferreira
    * @version              2.6.5
    * @since                2015/10/16
    */
    PROCEDURE ins_cdr_screen
    (
        i_tbl_screen_name IN table_varchar,
        i_tbl_desc        IN table_varchar
    );

    /**
    * inserts one name of screen into cdr_screens table
    *
    * @param i_screen_name  name of ux screen, used as identifier
    * @param i_Desc         Description of screen
    *
    * @author               Carlos Ferreira
    * @version              2.6.5
    * @since                2015/10/16
    */

    PROCEDURE ins_cdr_screen
    (
        i_screen_name IN VARCHAR2,
        i_desc        IN VARCHAR2
    );

    /**
    * Creates Configuration that disables given definition for a specific screen for an institution
    *
    * @param i_tbl_cdr_definition     Array of definitions to disable for associated screen
    * @param i_screen_name          name of ux screen, used as identifier
    * @param i_id_institution     target institution  for configuration
    *
    * @author               Carlos Ferreira
    * @version              2.6.5
    * @since                2015/10/16
    */
    PROCEDURE ins_cdr_def_exception
    (
        i_tbl_cdr_definition IN table_number,
        i_screen_name        IN VARCHAR2,
        i_id_institution     IN NUMBER
    );

    /**
    * Creates Configuration that disables given definition for a specific screen for an institution
    *
    * @param i_id_cdr_definition    definition to disable for associated screen
    * @param i_screen_name          name of ux screen, used as identifier
    * @param i_id_institution     target institution  for configuration
    *
    * @author               Carlos Ferreira
    * @version              2.6.5
    * @since                2015/10/16
    */
    PROCEDURE ins_cdr_def_exception
    (
        i_id_cdr_definition IN NUMBER,
        i_screen_name       IN VARCHAR2,
        i_id_institution    IN NUMBER
    );

    /**
    * Deletes Configuration that disables given definition for a specific screen for an institution
    *
    * @param i_id_cdr_definition    definition to disable for associated screen
    * @param i_screen_name          name of ux screen, used as identifier
    * @param i_id_institution     target institution  for configuration
    *
    * @author               Carlos Ferreira
    * @version              2.6.5
    * @since                2015/10/16
    */
    PROCEDURE del_cdr_def_exception
    (
        i_id_cdr_definition IN NUMBER,
        i_screen_name       IN VARCHAR2,
        i_id_institution    IN NUMBER
    );

    /********************************************************************************************
    * Get the respective ALERT cdr external type from VIDAL
    *
    * @param i_cdr_type       type of cdr
    *
    * @return                 ALERT CDR type
    *
    * @author                 Vanessa Barsottelli
    * @version                2.6.5
    * @since                  20-06-2016
    **********************************************************************************************/
    FUNCTION get_map_vidal_types(i_type cdr_external.id_cdr_type%TYPE) RETURN NUMBER;
    /**
    * Checks the CDR engine for applicable rules, using task types. -- EMR-2225
    * Analyzes all rules within the framework, and creates events for the valid ones.
    * Outputs a list of rules that must be seen as warnings.
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
    * @param i_xml          Array of XML
    * @param i_id_task_type Area for check rules (51)
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
        i_call         IN cdr_call.id_cdr_call%TYPE := NULL,
        i_task_types   IN table_number,
        i_task_reqs    IN table_varchar,
        i_dose         IN table_number := NULL,
        i_dose_um      IN table_number := NULL,
        i_route        IN table_varchar := NULL,
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

    g_xml table_varchar; -- EMR-2225 

END pk_cdr_fo_core;
/
