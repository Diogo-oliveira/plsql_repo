/*-- Last Change Revision: $Rev: 2028556 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_checklist_api_rep IS

    -- Author  : ARIEL.MACHADO
    -- Created : 17-May-10 11:18:21 AM
    -- Purpose : Checklist: Report methods
    -- JIRA issue: ALERT-14485

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations
    /**
    * Gets a list of all checklists for patient
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_patient      Patient ID 
    * @param   i_episode      Episode ID (if null returns all patient's checklist unfiltered by episode)
    * @param   o_list         Checklist list
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   08-Jun-10
    */
    FUNCTION get_pat_checklist_list
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info about an associated checklist to patient
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_pat_checklist          Association ID 
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_clin_service_list      Specialties where checklist is applicable
    * @param   o_item_list              Checklist items
    * @param   o_item_profile_list      Authorized profiles for checklist items
    * @param   o_item_dependence_list   Dependences between checklist items
    * @param   o_pat_checklist_info     Information related to the association between checklist and patient(requested by,status,cancel info,etc.)
    * @param   o_answer_data            Answers given
    * @param   o_error                  Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   10-Jun-10
    */
    FUNCTION get_pat_checklist
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        i_prof                 IN profissional,
        i_pat_checklist        IN pat_checklist.id_pat_checklist%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_clin_service_list    OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_pat_checklist_info   OUT pk_types.cursor_type,
        o_answer_data          OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

END pk_checklist_api_rep;
/
