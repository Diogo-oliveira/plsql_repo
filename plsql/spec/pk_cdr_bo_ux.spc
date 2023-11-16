/*-- Last Change Revision: $Rev: 2028554 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_cdr_bo_ux IS

    /**********************************************************************************************
    * Get list of definitions for the settings grid screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_list              list of definitions for the settings grid screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/18
    **********************************************************************************************/
    FUNCTION get_setting_grid_def
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_rule_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get list of definitions for the settings selection screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_def_list          list of definitions for the selection screen
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION get_setting_select_def
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_rule_def_list OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of definition rules from a determine type
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_type            Id type of cdr
    * @param o_def_list               list of definitions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/27
    **********************************************************************************************/
    FUNCTION get_setting_select_def_by_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_cdr_type IN cdr_type.id_cdr_type%TYPE,
        o_def_list    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get list of exceptions for the settings summary screen.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_definition             Id cdr definition
    * @param o_exception              list of all rule instances exceptions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/
    FUNCTION get_setting_summary_def
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_exception  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get list of exceptions for the settings summary screen,
    * through user setting defined lists.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_definition   rule definition identifier
    * @param i_software     software identifiers list
    * @param i_specialty    specialty identifiers list
    * @param i_profile      profile identifiers list
    * @param i_professional professional identifiers list
    * @param i_severity     severity identifiers list
    * @param i_action       action identifiers list
    * @param i_e_soft       exception software identifiers list
    * @param i_e_spec       exception specialty identifiers list
    * @param i_e_pt         exception profile identifiers list
    * @param i_e_prof       exception professional identifiers list
    * @param i_e_cdrs       exception severity identifiers list
    * @param i_e_cdra       exception action identifiers list
    * @param o_exception    cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/25
    */
    FUNCTION get_setting_summary_def_coll
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_definition   IN cdr_definition.id_cdr_definition%TYPE,
        i_software     IN table_number,
        i_specialty    IN table_number,
        i_profile      IN table_number,
        i_professional IN table_number,
        i_severity     IN table_number,
        i_action       IN table_number,
        i_e_soft       IN table_number,
        i_e_spec       IN table_number,
        i_e_pt         IN table_number,
        i_e_prof       IN table_number,
        i_e_cdrs       IN table_number,
        i_e_cdra       IN table_number,
        o_exception    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of all rules instance execptions
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_inst_list         list of all rule instances exceptions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/12
    **********************************************************************************************/
    FUNCTION get_rules_inst_settings
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_rule_inst_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get list of actions by definition.
    *
    * @param i_lang                   the id language
    * @param i_definition             ID Definition
    * @param o_list                   list of definition actions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/24
    **********************************************************************************************/
    FUNCTION get_list_action_by_def
    (
        i_lang       IN language.id_language%TYPE,
        i_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of department filtered by a list of software
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_software               table with software 
    * @param o_dept_list              list of department available
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/04
    **********************************************************************************************/
    FUNCTION get_list_department
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_software  IN table_number,
        o_dept_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get list of professionals.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_software               table with software 
    * @param i_dep_clin_serv          table with dep_clin_serv 
    * @param i_profile_template       table with profile_template 
    * @param o_list                   list of professionals
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/29
    **********************************************************************************************/
    FUNCTION get_list_professional
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_software         IN table_number,
        i_dep_clin_serv    IN table_number,
        i_profile_template IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get list of profiles.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_software               table with software 
    * @param o_list                   list of profiles
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/29
    **********************************************************************************************/
    FUNCTION get_list_profile
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_software IN table_number,
        o_templ    OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get list of services by department.
    *
    * @param i_lang         language identifier
    * @param i_dept         department identifier
    * @param o_list         list of services by department
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/24
    */
    FUNCTION get_list_service
    (
        i_lang  IN language.id_language%TYPE,
        i_dept  IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get list of severities by definition.
    *
    * @param i_lang         language identifier
    * @param i_definition   rule definition identifier
    * @param o_list         list of severities by definition
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/18
    */
    FUNCTION get_list_severity_by_def
    (
        i_lang       IN language.id_language%TYPE,
        i_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get list of softwares.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_software               list of softwares
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/04
    **********************************************************************************************/
    FUNCTION get_list_software
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_software OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of dep_clin_serv by department and service.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_dept                   department identifier
    * @param i_department             service identifier
    * @param o_list                   list of dep_clin_serv available
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/05
    **********************************************************************************************/
    FUNCTION get_list_specialty
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_dept       IN dept.id_dept%TYPE,
        i_department IN department.id_department%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get list of rule types.
    *
    * @param i_lang                   the id language
    * @param i_prof                   logged professional structure
    * @param o_list                   list of rule types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/07
    **********************************************************************************************/
    FUNCTION get_list_type
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set definition settings.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_definition             Id cdr definition
    * @param i_software               list of software exceptions
    * @param i_profile                list of profile templates exceptions
    * @param i_dep_clin_serv          list of dep_clin_serv exceptions
    * @param i_professional           list of professionals exceptions
    * @param i_severity               instance severity
    * @param i_action                 list os distinct action of instance                  
    * @param o_cdrdcf_ids             created setting identifiers                  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/25
    **********************************************************************************************/
    FUNCTION set_setting_def
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_definition   IN cdr_definition.id_cdr_definition%TYPE,
        i_software     IN table_number,
        i_specialty    IN table_number,
        i_profile      IN table_number,
        i_professional IN table_number,
        i_severity     IN table_number,
        i_action       IN table_number,
        o_cdrdcf_ids   OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of action types available
    *
    * @param i_lang                   the id language
    * @param o_action_type_list       list of action types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/15
    **********************************************************************************************/
    FUNCTION get_action_type_list
    (
        i_lang             IN language.id_language%TYPE,
        o_action_type_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of severity types available
    *
    * @param i_lang                   the id language
    * @param o_severity_type_list     list of severity types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/07
    **********************************************************************************************/
    FUNCTION get_severity_type_list
    (
        i_lang               IN language.id_language%TYPE,
        o_severity_type_list OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of conditions for the rule definition
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_condition_list         list of all rule definition
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/18
    **********************************************************************************************/
    FUNCTION get_cdr_conditions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_condition_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Returns the list of conditions for the rule definition
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_condition_list         list of all rule definition
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/18
    **********************************************************************************************/
    FUNCTION get_cdr_definition_concepts
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_concepts_list     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list all rule instances, or all rule instances for a given rule definition, when 
    * the parameter i_id_rule_definiton is either NULL or not.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_definition     ID rule definition (Only in cases that we want the list of instances of a definition)
    * @param o_rule_inst_list         list of all rule instances
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/19
    **********************************************************************************************/
    FUNCTION get_rules_instances_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_rule_inst_list    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set/change the rule instance state.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_rule_instance       ID rule instance
    * @param i_rule_status            rule new status 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION set_cdr_instance_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        i_cdr_status      IN cdr_instance.flg_status%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set/change the rule definition state.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_CDR_DEFINITION     ID rule definition
    * @param i_rule_status            rule new status 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION set_cdr_definition_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        i_cdr_status        IN cdr_definition.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get all information to the edit screen in order to edit a rule definition
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_rule_def_list          list of all rule definitions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/09
    **********************************************************************************************/
    FUNCTION get_edit_cdr_definition
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_cdr_definition      IN cdr_definition.id_cdr_definition%TYPE,
        o_cdr_definition         OUT pk_types.cursor_type,
        o_cdr_def_condition      OUT pk_types.cursor_type,
        o_cdr_concepts           OUT pk_types.cursor_type,
        o_cdr_actions            OUT pk_types.cursor_type,
        o_cdr_severity           OUT pk_types.cursor_type,
        o_cdr_parameters         OUT pk_types.cursor_type,
        o_cdr_parameters_actions OUT pk_types.cursor_type,
        o_screen_labels          OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel Rule definition
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_CDR_DEFINITION     ID rule definition
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/14
    **********************************************************************************************/
    FUNCTION cancel_cdr_definition
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        i_notes             IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel Rule instance
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_rule_instance       ID rule instance
    * @param i_notes                  Cancel notes
    * @param i_cancel_reason          ID Cancel reason    
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2011/03/14
    **********************************************************************************************/
    FUNCTION cancel_cdr_instance
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        i_notes           IN cancel_info_det.notes_cancel_short%TYPE,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list all rule instances, or all rule instances for a given rule definition, when 
    * the parameter i_id_rule_definiton is NOT NULL.
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_definition     ID rule definition
    * @param o_rule_inst_list         list of all rule instances
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/04/27
    **********************************************************************************************/
    FUNCTION get_cdr_instances
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_cdr_inst          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of all cdr instance exceptions
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_instance        Id cdr instance
    * @param o_cdr_inst_exception     list of all rule instances exceptions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/
    FUNCTION get_cdr_inst_exception
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_cdr_instance    IN cdr_instance.id_cdr_instance%TYPE,
        o_cdr_inst_exception OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the expections defined for an instance
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_instance        Id cdr instance
    * @param o_cdr_labels             list of all labels used on screen
    * @param o_software               list of software exceptions
    * @param o_profile                list of profile templates exceptions
    * @param o_dep_clin_serv          list of dep_clin_serv exceptions
    * @param o_professional           list of professionals exceptions
    * @param o_action                 list os distinct action of instance                  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/

    FUNCTION get_edit_cdr_inst_exception
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        o_cdr_labels      OUT pk_types.cursor_type,
        o_software        OUT pk_types.cursor_type,
        o_profile         OUT pk_types.cursor_type,
        o_dep_clin_serv   OUT pk_types.cursor_type,
        o_professional    OUT pk_types.cursor_type,
        o_action          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel a instance exception
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_cdr_ins_config      ID rule definition
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/

    FUNCTION cancel_cdr_inst_exception
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_ins_config cdr_inst_config.id_cdr_inst_config%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel a definition exception
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_cdr_def_config      ID rule definition exception 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/02
    **********************************************************************************************/

    FUNCTION cancel_cdr_def_exception
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_def_config cdr_inst_config.id_cdr_inst_config%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get list of actions for a specified subject and state.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_subject                Subject
     * @param i_from_state             State
     * @param o_actions                List of actions
     * @param o_error                  Error
     *
     * @return                         true or false on success or error
     *
     * @author                          Elisabete Bugalho
     * @version                         0.1
     * @since                           2011/05/03
    **********************************************************************************************/
    FUNCTION get_cdr_actions
    (
        i_lang      IN language.id_language%TYPE,
        i_subject   IN action.subject%TYPE,
        i_exception IN NUMBER,
        o_actions   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the list of action types available for a instance
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_warning_type_list      list of action types
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/04
    **********************************************************************************************/
    FUNCTION get_cdr_inst_action_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cdr_instance  IN cdr_instance.id_cdr_instance%TYPE,
        o_action_type_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the expections defined for an instance
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_id_cdr_instance        Id cdr instance
    * @param i_software               list of software exceptions
    * @param i_profile                list of profile templates exceptions
    * @param i_dep_clin_serv          list of dep_clin_serv exceptions
    * @param i_professional           list of professionals exceptions
    * @param i_action                 list os distinct action of instance                  
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/05/06
    **********************************************************************************************/

    FUNCTION set_cdr_inst_exception
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_cdr_instance IN cdr_instance.id_cdr_instance%TYPE,
        i_software        IN table_number,
        i_profile         IN table_number,
        i_dep_clin_serv   IN table_number,
        i_professional    IN table_number,
        i_action          IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Set the Status of a rule (id_Cdr_definition) on table cdr_def_inst by [A]dd or [R]emove
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION set_rule_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        i_flg_add_remove    IN cdr_def_inst.flg_add_remove%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Get the rule (id_cdr_definition) data in bulk, definition, status, url info button
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_bulk
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        i_sep               IN VARCHAR2 DEFAULT ' - ',
        i_sep_final         IN VARCHAR2 DEFAULT '; ',
        o_rule_info         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Return Y or N if have or not exceptions
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_have_exceptions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN cdr_definition.id_cdr_definition%TYPE,
        o_have_exceptions   OUT sys_domain.val%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  set the rule data in bulk, links, status
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION set_rule_bulk
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        i_flg_add_remove    IN cdr_def_inst.flg_add_remove%TYPE,
        i_id_links          IN links.id_links%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  get the rule detail
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        o_history           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  get the rule detail history
    *
    * @author               Mário Mineiro
    * @version               2.6.4
    * @since                27-03/2014
    */
    FUNCTION get_rule_detail_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_cdr_definition IN table_number,
        o_history           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

END pk_cdr_bo_ux;
/
