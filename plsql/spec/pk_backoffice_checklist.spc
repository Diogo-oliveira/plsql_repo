/*-- Last Change Revision: $Rev: 2028511 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_checklist IS

    -- Author  : ARIEL.MACHADO
    -- Created : 20-May-10 2:56:54 PM
    -- Purpose : Checklists: Backoffice methods
    -- JIRA issue: ALERT-14485

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Creates a new checklist
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_inst                   Institution/facility
    * @param   i_name                   Checklist name
    * @param   i_flg_type               Type of checklist
    * @param   i_profile_list           Authorized profiles for checklist
    * @param   i_clin_service_list      Specialties where checklist is applicable
    * @param   i_item_list              Checklist items
    * @param   i_item_profile_list      Authorized profiles for checklist items
    * @param   i_item_dependence_list   Dependences between checklist items
    * @param   o_checklist              Generated ID for checklist
    * @param   o_checklist_version      Generated ID for checklist version
    * @param   o_error                  Error information
    *
    * @value   i_flg_type               {*} 'G' Checklist for Group - same checklist for all professionals {*} 'I' Individual checklist - one checklist by professional
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-May-10
    */
    FUNCTION create_checklist
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        i_prof                 IN profissional,
        i_inst                 IN institution.id_institution%TYPE,
        i_name                 IN checklist_version.name%TYPE,
        i_flg_type             IN checklist_version.flg_type%TYPE,
        i_profile_list         IN table_table_varchar,
        i_clin_service_list    IN table_number,
        i_item_list            IN table_varchar,
        i_item_profile_list    IN table_table_number,
        i_item_dependence_list IN table_table_varchar,
        o_cnt_creator          OUT checklist.flg_content_creator%TYPE,
        o_checklist            OUT checklist.id_checklist%TYPE,
        o_checklist_version    OUT checklist_version.id_checklist_version%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates definitions of a checklist creating a new version
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_checklist              ID of checklist to be updated
    * @param   i_name                   Checklist name
    * @param   i_flg_type               Type of checklist
    * @param   i_profile_list           Authorized profiles for checklist
    * @param   i_clin_service_list      Specialties where checklist is applicable
    * @param   i_item_list              Checklist items
    * @param   i_item_profile_list      Authorized profiles for checklist items
    * @param   i_item_dependence_list   Dependences between checklist items
    * @param   o_checklist_version      Generated ID for new checklist version
    * @param   o_error                  Error information
    *
    * @value   i_flg_type               {*} 'G' Checklist for Group - same checklist for all professionals {*} 'I' Individual checklist - one checklist by professional
    * @value   i_cnt_creator            {*} 'A' ALERT {*} 'I' Institution
    *
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-May-10
    */
    FUNCTION update_checklist
    (
        i_lang                  IN LANGUAGE.id_language%TYPE,
        i_prof                  IN profissional,
        i_checklist             IN checklist.id_checklist%TYPE,
        i_name                  IN checklist_version.name%TYPE,
        i_flg_type              IN checklist_version.flg_type%TYPE,
        i_profile_list          IN table_table_varchar,
        i_clin_service_list     IN table_number,
        i_item_list             IN table_varchar,
        i_item_profile_list     IN table_table_number,
        i_item_dependence_list  IN table_table_varchar,
        o_new_checklist_version OUT checklist_version.id_checklist_version%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a checklist
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)
    * @param   i_checklist     Checklist ID to cancel
    * @param   i_cancel_reason Cancel reason ID
    * @param   i_cancel_notes  Cancelation notes
    * @param   o_error         Error information
    *
    * @value   i_cnt_creator  {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-May-10
    */
    FUNCTION cancel_checklist
    (
        i_lang          IN LANGUAGE.id_language%TYPE,
        i_prof          IN profissional,
        i_checklist     IN checklist.id_checklist%TYPE,
        i_cancel_reason IN checklist.id_cancel_reason%TYPE,
        i_cancel_notes  IN checklist.cancel_notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets detailed information about a checklist
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_cnt_creator            Checklist content creator 
    * @param   i_checklist              Checklist ID
    * @param   i_detail_level           Detail level 
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_clin_service_list      Specialties where checklist is applicable
    * @param   o_item_list              Checklist items
    * @param   o_item_profile_list      Authorized profiles for checklist items
    * @param   o_item_dependence_list   Dependences between checklist items
    * @param   o_error                  Error information
    *
    * @value   i_detail_level {*} 'G' General {*} 'H' History
    * @value   i_cnt_creator  {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   27-May-10
    */
    FUNCTION get_checklist_detail
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        i_prof                 IN profissional,
        i_cnt_creator          IN checklist.flg_content_creator%TYPE,
        i_checklist            IN checklist.id_checklist%TYPE,
        i_detail_level         IN VARCHAR2,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_clin_service_list    OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a list of checklists defined in the facility
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_inst         Institution/facility 
    * @param   o_list         Checklist list
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   21-May-10
    */
    FUNCTION get_checklist_list
    (
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a specific checklist version
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)
    * @param   i_content_creator        Checklist content creator
    * @param   i_checklist_version      Checklist version ID
    * @param   o_checklist_info         Checklist information (name,type,author,etc..)
    * @param   o_profile_list           Authorized profiles for checklist
    * @param   o_clin_service_list      Specialties where checklist is applicable
    * @param   o_item_list              Checklist items
    * @param   o_item_profile_list      Authorized profiles for checklist items
    * @param   o_item_dependence_list   Dependences between checklist items
    * @param   o_error                  Error information
    *
    * @value   i_content_creator    {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   04-Jun-10
    */
    FUNCTION get_checklist
    (
        i_lang                 IN LANGUAGE.id_language%TYPE,
        i_prof                 IN profissional,
        i_content_creator      IN checklist_version.flg_content_creator%TYPE,
        i_checklist_version    IN checklist_version.id_checklist_version%TYPE,
        o_checklist_info       OUT pk_types.cursor_type,
        o_profile_list         OUT pk_types.cursor_type,
        o_clin_service_list    OUT pk_types.cursor_type,
        o_item_list            OUT pk_types.cursor_type,
        o_item_profile_list    OUT pk_types.cursor_type,
        o_item_dependence_list OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Changes the status of a checklist in an institution to active/inactive
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_inst         Institution/facility
    * @param   i_cnt_creator  Checklist content creator 
    * @param   i_checklist    Checklist ID 
    * @param   i_status       Status
    * @param   o_error        Error information
    *
    * @value   i_status       {*} 'A' Active {*} 'I' Inactive
    * @value   i_cnt_creator  {*} 'A' ALERT {*} 'I' Institution
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   21-May-10
    */
    FUNCTION set_checklist_status
    (
        i_lang        IN LANGUAGE.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_cnt_creator IN checklist.flg_content_creator%TYPE,
        i_checklist   IN checklist.id_checklist%TYPE,
        i_status      IN checklist_inst.flg_status%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a list of available software by institution that can use Checklists functionality
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_inst         Institution/facility
    * @param   o_soft_list    A list of available software
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   07-Jun-10
    */
    FUNCTION get_software_list
    (
        i_lang      IN LANGUAGE.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_soft_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a list of available templates by software that can use Checklists functionality
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_inst         Institution/facility
    * @param   i_soft         Software ID
    * @param   o_profile_list List of available profiles
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   07-Jun-10
    */
    FUNCTION get_template_list
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_inst         IN institution.id_institution%TYPE,
        i_soft         IN software.id_software%TYPE,
        o_profile_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets clinical services (specialties) that are defined to specific software in the institution
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_inst         Institution/facility
    * @param   i_soft         List of software ID
    * @param   o_profile_list List of clinical services
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   10-Jun-10
    */
    FUNCTION get_clin_serv_list
    (
        i_lang         IN LANGUAGE.id_language%TYPE,
        i_prof         IN profissional,
        i_inst         IN institution.id_institution%TYPE,
        i_soft_list    IN table_number,
        o_clin_service OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

END pk_backoffice_checklist;
/
