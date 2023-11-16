/*-- Last Change Revision: $Rev: 2028897 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_protocol IS

    /**
    *  Convert date strings to date format
    *
    * @param C_DATE                     String of date
    *
    * @return     DATE
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION convert_to_date(c_date VARCHAR2) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /********************************************************************************************
    * return a number, converted from a string (if possible)
    *
    * @param       i_txt                     string to convert
    *
    * @return      number                    converted number (null if the conversion fails)
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2010/03/30
    ********************************************************************************************/
    FUNCTION safe_to_number(i_txt IN VARCHAR2) RETURN NUMBER;

    /** 
    *  Verify if a task type is available to a given software and institution
    *
    * @param      I_LANG            Preferred language ID for this professional
    * @param      I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE       Task type ID
    *
    * @return     VARCHAR2:         'Y': task type is available, 'N' task type is not available
    *
    * @author     Tiago Silva
    * @version    1.0
    * @since      2010/04/28
    */
    FUNCTION check_task_type_soft_inst
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN protocol_action_category.task_type%TYPE
    ) RETURN VARCHAR2;

    /** 
    *  Check permissions of a task type
    *
    * @param      I_LANG      Preferred language ID for this professional
    * @param      I_PROF      Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE  Task type to check permissions
    *
    * @return     BOOLEAN
    * @author     Tiago Silva
    * @version    1.0
    * @since      2009/09/30
    */
    FUNCTION check_task_permissions
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN protocol_action_category.task_type%TYPE
    ) RETURN VARCHAR2;

    /**
    *  Returns string with specific link type content separated by defined separator
    *
    * @param I_LANG                 Language
    * @param I_PROF                 Professional structure
    * @param I_ID_PROTOCOL         protocol
    * @param I_LINK_TYPE            Type of Link
    * @param I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_link_id_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        i_link_type   IN protocol_link.link_type%TYPE,
        i_separator   IN VARCHAR2
    ) RETURN VARCHAR2;

    /** 
    *  Returns string with the details of an item (protocol task or criteria) 
    *  between brackets and separated by defined separator
    *
    * @param  I_LANG          Language
    * @param  I_PROF          Professional structure
    * @param  I_TYPE_ITEM     Type of the protocol item (C)riteria or (T)ask
    * @param  I_ID_ITEM       ID of the item link
    *
    * @return     VARCHAR2
    * @author     TS
    * @version    0.1
    * @since      2007/11/08
    */
    FUNCTION get_item_details_str
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_type_item IN protocol_adv_input_value.flg_type%TYPE,
        i_id_item   IN protocol_adv_input_value.id_adv_input_link%TYPE,
        i_separator IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    *  Returns string with specific link criteria type content separated by defined separator
    *
    * @param  I_LANG                       Language
    * @param  I_PROF                       Professional structure
    * @param  I_ID_PROTOCOL                Protocol
    * @param  I_CRIT_TYPE                  Type of Criteria: Inclusion or Exclusion
    * @param  I_ID_CRIT_OTHER_TYPE         ID of other type of criteria
    * @param  I_BULLET                     Bullet for the criteria list
    * @param  I_SEPARATOR                  Separator between criteria
    * @param  I_FLG_DETAILS                Define if details should appear    
    * @param  I_ID_LINK_OTHER_CRITERIA     ID of other criteria
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_criteria_link_id_str
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_protocol            IN protocol.id_protocol%TYPE,
        i_crit_type              IN protocol_criteria.criteria_type%TYPE,
        i_id_crit_other_type     IN protocol_criteria_link.id_link_other_criteria_type%TYPE,
        i_bullet                 IN VARCHAR2,
        i_separator              IN VARCHAR2,
        i_flg_details            IN VARCHAR2,
        i_id_link_other_criteria IN protocol_criteria_link.id_link_other_criteria%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    * Returns string with specific task ID content
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_TASK              ID of task
    * @param  I_TASK_TYPE            Type of task
    * @param  I_TASK_CODIFICATION    Task codification
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_task_id_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_task           IN protocol_task.id_task_link%TYPE,
        i_task_type         IN protocol_task.task_type%TYPE,
        i_task_codification IN protocol_task.task_codification%TYPE
    ) RETURN VARCHAR2;

    /**
    *  Returns string with specifictask content separated by defined separator
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_PROTOCOL          Protocol
    * @param  I_element_type         Type of task
    * @param  I_SEPARATOR            Separator between diferent elements of string
    * @param  I_ID_TASK              ID of task
    * @param  I_TASK_CODIFICATION    Task codification    
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_task_id_str
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_protocol       IN protocol.id_protocol%TYPE,
        i_task_type         IN protocol_task.task_type%TYPE,
        i_separator         IN VARCHAR2,
        i_id_task           IN protocol_task.id_task_link%TYPE DEFAULT NULL,
        i_task_codification IN protocol_task.task_codification%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**
    *  Returns string with picture name separated by defined separator
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_PROTOCOL          Protocol
    * @param  I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_image_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        i_separator   IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    *  returns string with author of a specified protocol
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_PROTOCOL          Protocol
    * @param  I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_context_author_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        i_separator   IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    *  returns string with specific criteria_type
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_CRITERIA_TYPE     Criteria type ID
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_criteria_type_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_criteria_type IN protocol_criteria_type.id_protocol_criteria_type%TYPE
    ) RETURN VARCHAR2;

    ---------------------------------------
    -- Sequence IDs functions
    /**
    * Function. returns sequence ID for protocol
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_seq RETURN NUMBER;

    -- protocol Criteria
    /**
    * Function. returns sequence ID for protocol criteria
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_criteria_seq RETURN NUMBER;

    -- protocol_link
    /**
    * Function. returns sequence ID for protocol link
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_link_seq RETURN NUMBER;

    -- protocol criteria link
    /**
    * Function. returns sequence ID for protocol criteria link
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_crit_lnk_seq RETURN NUMBER;

    -- Task Link
    /**
    * Function. returns sequence ID for protocol task link
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_id_protocol_element_seq RETURN NUMBER;
    -- Task Link
    /**
    * Function. returns sequence ID for protocol relation
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_relation_seq RETURN NUMBER;
    /**
    * Function. returns sequence ID for protocol connector
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_connector_seq RETURN NUMBER;

    /**
    * Function. returns sequence ID for protocol element ID
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_id_element_seq RETURN NUMBER;

    /**
    * Function. returns sequence ID for protocol author
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_ctx_author_seq RETURN NUMBER;

    /**
    *  Create specific protocol
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               Object (ID of professional, ID of institution, ID of software)
    * @param      I_DUPLICATE_FLG              Duplicate protocol (Y/N)
    
    * @param      O_ID_PROTOCOL               identifier of protocol created
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION create_protocol
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        i_duplicate_flg IN VARCHAR2,
        ---
        o_id_protocol OUT protocol.id_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Set specific protocol main attributes
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_protocol               protocol ID
    * @param      I_PROTOCOL_DESC             protocol description
    * @param      I_ID_PROTOCOL_TYPE          protocol Type
    * @param      I_LINK_ENVIRONMENT           protocol environment link
    * @param      I_LINK_SPECIALTY             protocol specialty link
    * @param      I_LINK_PROFESSIONAL          protocol professional link
    * @param      I_LINK_EDIT_PROF             protocol edit professional link
    * @param      I_TYPE_RECOMMEDNATION        protocol type of recommendation
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_protocol_main
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol         IN protocol.id_protocol%TYPE,
        i_protocol_desc       IN protocol.protocol_desc%TYPE,
        i_link_type           IN table_number,
        i_link_environment    IN table_number,
        i_link_specialty      IN table_number,
        i_link_professional   IN table_number,
        i_link_edit_prof      IN table_number,
        i_type_recommendation IN protocol.flg_type_recommendation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Set specific protocol main pathology
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                  protocol ID
    * @param      I_LINK_PATHOLOGY             Pathology link ID
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_protocol_main_pathology
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_protocol    IN protocol.id_protocol%TYPE,
        i_link_pathology IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get protocol available criteria, to be shown
    *
    * @param      I_LANG      Preferred language ID for this professional
    * @param      I_PROF      Object (ID of professional, ID of institution, ID of software)
    * @param      O_CRITS     List of criteria to be shown
    * @param      O_ERROR     error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/08/29
    */
    FUNCTION get_protocol_avail_criteria
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_crits OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get protocol main attributes
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    
    * @param      O_PROTOCOL_MAIN             protocol main attributes cursor
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_main
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        o_protocol_main OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Obtain all protocol by title
    *
    * @param      I_LANG                 Prefered language ID for this professional
    * @param      I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param      I_VALUE                Value to search for
    * @param      I_ID_PATIENT           Patient ID
    * @param      O_PROTOCOL             Cursor with all protocol
    * @param      O_ERROR                error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_by_title
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_value      IN VARCHAR2,
        i_id_patient IN protocol_process.id_patient%TYPE,
        o_protocol   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get all protocol types
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_PROTOCOL_TYPE             Cursor with all protocol types
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_type_all
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_protocol_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get pathologies of a specific type of protocol
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_TYPE          ID of protocol type
    * @param      I_ID_PATIENT                 Patient ID
    * @param      O_PROTOCOL_PATHOL           Cursor with pathologies
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.4
    * @since      2007/07/13
    */
    FUNCTION get_protocol_pathologies
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_protocol_type IN NUMBER,
        i_id_patient       IN protocol_process.id_patient%TYPE,
        o_protocol_pathol  OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get all protocol by type and pathology
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_TYPE          ID of protocol type
    * @param      I_ID_PROTOCOL_PATHO         ID of protocol pathology
    * @param      I_ID_PATIENT                 Patient ID
    * @param      O_PROTOCOL_PATHOL           Cursor with pathologies
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_by_type_patho
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_protocol_type   IN NUMBER,
        i_id_protocol_pathol IN NUMBER,
        i_id_patient         IN protocol_process.id_patient%TYPE,
        o_protocol           OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Obtain all protocol by pathology
    *
    * @param      I_LANG               Prefered languagie ID for this professional
    * @param      I_PROF               object (ID of professional, ID of institution, ID of software)
    * @param      I_VALUE              Value to search for
    * @param      O_PROTOCOL         cursor with all protocol classified by type
    * @param      O_ERROR              error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_protocol_by_pathology
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_value    IN VARCHAR2,
        o_protocol OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get a list of possible nested protocols for a given protocol
    *
    * @param      I_LANG              Prefered languagie ID for this professional
    * @param      I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL       ID of protocol.
    * @param      I_VALUE             Value to search for
    * @param      O_NESTED_PROTOCOLS  List of possible nested protocols
    * @param      O_ERROR             error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/09/28
    */
    FUNCTION get_nested_protocols
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_protocol      IN protocol.id_protocol%TYPE,
        i_value            IN VARCHAR2,
        o_nested_protocols OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Gets protocol pathology ids
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    
    * @param      O_PATHOLOGY_ID               protocol pathology ids
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_pathology_id
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_protocol  IN protocol.id_protocol%TYPE,
        o_pathology_id OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get all types of appointments
    *
    * @param      I_LANG       Preferred language ID for this professional
    * @param      I_PROF       Object (ID of professional, ID of institution, ID of software)
    * @param      I_VALUE      Search value
    * @param      O_SPECS      Specialties
    * @param      O_ERROR      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.2
    * @since      2007/08/21
    */
    FUNCTION get_appointments
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_value IN VARCHAR2,
        o_specs OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Set protocol criteria
    *
    * @param      I_LANG                         Prefered languagie ID for this professional
    * @param      I_PROF                         Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                 protocol ID
    * @param      I_CRITERIA_TYPE                Criteria Type: Inclusion / Exclusion
    * @param      I_GENDER                       Gender: Male / Female / Undefined
    * @param      I_MIN_AGE                      Minimum age
    * @param      I_MAX_AGE                      Maximum age
    * @param      I_MIN_WEIGHT                   Minimum weight
    * @param      I_MAX_WEIGHT                   Maximum weight
    * @param      I_ID_WEIGHT_UNIT_MEASURE       Measure for weight unit ID
    * @param      I_MIN_HEIGHT                   Minimum height
    * @param      I_MAX_HEIGHT                   Maximum height
    * @param      I_ID_HEIGHT_UNIT_MEASURE       Measure for height unit ID
    * @param      I_IMC_MIN                      IMC minimum value
    * @param      I_IMC_MAX                      IMC maximum value
    * @param      I_ID_BLOOD_PRESS_UNIT_MEASURE  Measure for height unit ID
    * @param      I_MIN_BLOOD_PRESSURE_S         Diastolic blood pressure minimum value
    * @param      I_MAX_BLOOD_PRESSURE_S         Diastolic blood pressure maximum value
    * @param      I_MIN_BLOOD_PRESSURE_D         Systolic blood pressure minimum value
    * @param      I_MAX_BLOOD_PRESSURE_D         Systolic blood pressure maximum value
    *
    * @param      O_ERROR                        error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_protocol_criteria
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_protocol                 IN protocol.id_protocol%TYPE,
        i_criteria_type               IN protocol_criteria.criteria_type%TYPE,
        i_gender                      IN protocol_criteria.gender%TYPE,
        i_min_age                     IN protocol_criteria.min_age%TYPE,
        i_max_age                     IN protocol_criteria.max_age%TYPE,
        i_min_weight                  IN protocol_criteria.min_weight%TYPE,
        i_max_weight                  IN protocol_criteria.max_weight%TYPE,
        i_id_weight_unit_measure      IN protocol_criteria.id_weight_unit_measure%TYPE,
        i_min_height                  IN protocol_criteria.min_height%TYPE,
        i_max_height                  IN protocol_criteria.max_height%TYPE,
        i_id_height_unit_measure      IN protocol_criteria.id_height_unit_measure%TYPE,
        i_imc_min                     IN protocol_criteria.imc_min%TYPE,
        i_imc_max                     IN protocol_criteria.imc_max%TYPE,
        i_id_blood_press_unit_measure IN protocol_criteria.id_blood_pressure_unit_measure%TYPE,
        i_min_blood_pressure_s        IN protocol_criteria.min_blood_pressure_s%TYPE,
        i_max_blood_pressure_s        IN protocol_criteria.max_blood_pressure_s%TYPE,
        i_min_blood_pressure_d        IN protocol_criteria.min_blood_pressure_d%TYPE,
        i_max_blood_pressure_d        IN protocol_criteria.max_blood_pressure_d%TYPE,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;
    /** 
    *  Set protocol other criteria
    *
    * @param      I_LANG                        Prefered languagie ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                 Protocol ID
    * @param      I_CRITERIA_TYPE               Criteria Type: Inclusion / Exclusion
    * @param      I_ID_LINK_OTHER_CRITERIA      Other criterias link
    * @param      I_ID_LINK_OTHER_CRITERIA_TYPE Type of other criteria link
    * @param      O_ID_GUID_CRITERIA_LINK       New ID of each criteria
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/18
    */

    FUNCTION set_protocol_criteria_other
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_protocol                 IN protocol.id_protocol%TYPE,
        i_criteria_type               IN protocol_criteria.criteria_type%TYPE,
        i_id_link_other_criteria      IN table_varchar,
        i_id_link_other_criteria_type IN table_number,
        o_id_prot_criteria_link       OUT table_number,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Get protocol criteria
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    * @param      I_CRITERIA_TYPE              Criteria Type: Inclusion / Exclusion
    
    * @param      O_PROTOCOL_CRITERIA         Cursor for protocol criteria
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_protocol_criteria
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_protocol       IN protocol.id_protocol%TYPE,
        i_criteria_type     IN protocol_criteria.criteria_type%TYPE,
        o_protocol_criteria OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Get protocol criteria
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    
    * @param      O_PROTOCOL_CRITERIA         Cursor for protocol criteria
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_criteria_all
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_criteria_all OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Get protocol tasks
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
    * @param      I_element_type               Task type list wanted
    * @param      O_PROTOCOL_TASK              Cursor for protocol tasks
    * @param      O_ERROR                      Error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_task_all
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_protocol       IN protocol.id_protocol%TYPE,
        i_element_type      IN protocol_task.task_type%TYPE,
        o_protocol_task_all OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  set protocol element/relation
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
    * @param      I_ELEMENT                    Element lists
    * @param      I_ELEMENT_DETAIL             Element lists
    * @param      I_ELEMENT_RELATION           Element relation lists
    * @param      O_ID_PROT_TASK               Task list    
    * @param      O_ERROR                      Error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_protocol_structure
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_protocol      IN protocol.id_protocol%TYPE,
        i_element          IN table_table_varchar,
        i_element_detail   IN table_table_varchar,
        i_element_relation IN table_table_varchar,
        o_id_prot_task     OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get protocol structure
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
        
    * @param      O_PROTOCOL_ELEMENTS           Cursor for protocol elements
    * @param      O_PROTOCOL_DETAILS            Cursor for protocol elements details as tasks
    * @param      O_PROTOCOL_RELATION          Cursor for protocol relations    
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_structure
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol              IN protocol.id_protocol%TYPE,
        o_protocol_elements        OUT pk_types.cursor_type,
        o_protocol_element_details OUT pk_types.cursor_type,
        o_protocol_relations       OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get protocol structure
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS        Protocol ID
    * @param      i_id_episode                 ID of the current episode
    * @param      dt_server                    Date of server        
    * @param      O_PROTOCOL_ELEMENTS          Cursor for protocol elements
    * @param      O_PROTOCOL_DETAILS           Cursor for protocol elements details as tasks
    * @param      O_PROTOCOL_RELATION          Cursor for protocol relations    
    * @param      o_flg_read_only              flag with read only indication
    * @param      O_ERROR                      error
    *
    * @value      o_flg_read_only              {*} 'Y' read-only mode is on
    *                                          {*} 'N' read-only mode is off
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/08
    */
    FUNCTION get_protocol_structure_app
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol_process      IN protocol_process.id_protocol_process%TYPE,
        i_id_episode               IN episode.id_episode%TYPE,
        dt_server                  OUT VARCHAR2,
        o_protocol_elements        OUT pk_types.cursor_type,
        o_protocol_element_details OUT pk_types.cursor_type,
        o_protocol_relations       OUT pk_types.cursor_type,
        o_flg_read_only            OUT VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Set protocol context
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
    
    
    * @param      I_CONTEXT_DESC               Context description
    * @param      I_CONTEXT_TITLE              Context title
    * @param      I_CONTEXT_EBM                Context EBM
    * @param      I_CONTEXT_ADAPTATION         Context adaptation
    * @param      I_CONTEXT_TYPE_MEDIA         Context type of media
    * @param      I_CONTEXT_EDITOR             Context editor
    * @param      I_CONTEXT_EDITION_SITE       Context edition site
    * @param      I_CONTEXT_EDITION            Context edition
    * @param      I_DT_CONTEXT_EDITION         Date of context edition
    * @param      I_CONTEXT_ACCESS             Context access
    * @param      I_ID_CONTEXT_LANGUAGE        ID of context language
    * @param      I_ID_CONTEXT_SUBTITLE        Context subtitle
    * @param      I_ID_CONTEXT_ASSOC_LANGUAGE  ID of context associated language
    
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION set_protocol_context
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_protocol        IN protocol.id_protocol%TYPE,
        i_context_desc       IN protocol.context_desc%TYPE,
        i_context_title      IN protocol.context_title%TYPE,
        i_context_ebm        IN protocol.id_ebm%TYPE,
        i_context_adaptation IN protocol.context_adaptation%TYPE,
        i_context_type_media IN protocol.context_type_media%TYPE,
        --        i_context_author_last_name  IN protocol_context_author.last_name%TYPE,
        --        i_context_author_first_name IN protocol_context_author.first_name%TYPE,
        i_context_editor            IN protocol.context_editor%TYPE,
        i_context_edition_site      IN protocol.context_edition_site%TYPE,
        i_context_edition           IN protocol.context_edition%TYPE,
        i_dt_context_edition        IN protocol.dt_context_edition%TYPE,
        i_context_access            IN protocol.context_access%TYPE,
        i_id_context_language       IN protocol.id_context_language%TYPE,
        i_context_subtitle          IN protocol.context_subtitle%TYPE,
        i_id_context_assoc_language IN protocol.id_context_associated_language%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get protocol context
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    
    * @param      O_PROTOCOL_CONTEXT          Cursor for protocol context
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_context
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_protocol      IN protocol.id_protocol%TYPE,
        o_protocol_context OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Set protocol context authors
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    * @param      I_CONTEXT_AUTHOR_LAST_NAME   Context author last name
    * @param      I_CONTEXT_AUTHOR_FIRST_NAME  Context author first name
    * @param      I_CONTEXT_AUTHOR_TITLE       Context author title
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION set_protocol_context_author
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_protocol               IN protocol.id_protocol%TYPE,
        i_context_author_last_name  IN table_varchar,
        i_context_author_first_name IN table_varchar,
        i_context_author_title      IN table_varchar,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get protocol context authors
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    * @param      O_PROTOCOL_CONTEXT_AUTHOR          Cursor for protocol context
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_context_author
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_protocol             IN protocol.id_protocol%TYPE,
        o_protocol_context_author OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Sets a protocol as definitive
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               ID of protocol to set as final
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_protocol
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Check if it is possible to cancel a protocol process
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS        Protocol process ID
    *
    * @return     VARCHAR2:                    'Y': protocol can be canceled, 'N' protocol cannot be canceled
    *
    * @author     Tiago Silva
    * @version    1.0
    * @since      2010/04/27
    */
    FUNCTION check_cancel_protocol_proc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE
    ) RETURN VARCHAR2;

    /**
    *  Cancel protocol / mark as deleted
    *
    * @param      I_LANG              Prefered languagie ID for this professional
    * @param      I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL      ID of protocol.
    * @param      O_ERROR             error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION cancel_protocol
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get protocol task types to be shown
    *
    * @param      I_LANG      Preferred language ID for this professional
    * @param      I_PROF      Object (ID of professional, ID of institution, ID of software)
    * @param      O_TASKS     List of tasks to be shown
    * @param      O_ERROR     error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/08/29
    */
    FUNCTION get_protocol_task_type_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_tasks OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get multichoice for protocol types
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                ID of protocol.
    * @param      O_PROTOCOL_TYPE              Cursor with all protocol types
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        o_protocol_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get multichoice for environment
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                ID of protocol.
    * @param      O_PROTOCOL_ENVIRONMENT       Cursor with all environment availables
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_environment_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_protocol          IN protocol.id_protocol%TYPE,
        o_protocol_environment OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Get multichoice for specialty
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                ID of protocol.
    * @param      O_PROTOCOL_SPECIALTY         Cursor with all specialty available
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB/TS
    * @version    0.2
    * @since      2007/07/13
    */
    FUNCTION get_protocol_specialty_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_protocol        IN protocol.id_protocol%TYPE,
        o_protocol_specialty OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Get multichoice for professional
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                ID of protocol.
    * @param      O_PROTOCOL_PROFESSIONAL      Cursor with all professional categories availables
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_protocol_prof_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_professional OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /** 
    *  Get multichoice for professionals that will be able to edit protocols
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                ID of protocol
    * @param      O_PROTOCOL_PROFESSIONAL      Cursor with all professional categories availables
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_protocol_edit_prof_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_professional OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get multichoice for types of protocol recommendation
    *
    * @param      I_LANG                  Prefered languagie ID for this professional
    * @param      I_PROF                  Object (ID of professional, ID of institution, ID of software)
    * @param      O_PROTOCOL_REC_MODE     Cursor with types of recommendation
    * @param      O_ERROR                 Error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_protocol_type_rec_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_protocol_type_rec OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Get multichoice for EBM
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               ID of protocol.
    * @param      O_PROTOCOL_EBM              Cursor with all EBM values availables
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_ebm_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_protocol  IN protocol.id_protocol%TYPE,
        o_protocol_ebm OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get multichoice for Gender
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_CRITERIA_TYPE              Criteria Type : I- Incusion E - Exclusion
    * @param      O_PROTOCOL_GENDER           Cursor with all Genders
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_gender_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_criteria_type   IN protocol_criteria.criteria_type%TYPE,
        o_protocol_gender OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get multichoice for type of media
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_PROTOCOL_TM               Cursor with all Genders
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_type_media_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_protocol_tm OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get multichoice for protocol edit options
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_OPTIONS                    Cursor with all options
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_protocol_edit_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get multichoice for languages
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_LANGUAGES                  Cursor with all languages
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_language_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_languages OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get title list for professionals
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      O_TITLE                      Title cursor
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_prof_title_list
    (
        i_lang  IN language.id_language%TYPE,
        o_title OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get status list for allergy criterias
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_allergy_status_list
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get reactions list for allergy criterias
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_REACTS   Reactions cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_allergy_react_list
    (
        i_lang   IN language.id_language%TYPE,
        o_reacts OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get status list for diagnose criterias
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_diagnose_status_list
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get natures list for diagnose criterias
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_NATURES  Natures cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_diagnose_nature_list
    (
        i_lang    IN language.id_language%TYPE,
        o_natures OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get status list for nurse diagnosis criterias
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_nurse_diag_status_list
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get connector options
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/16
    */
    FUNCTION get_connector_list
    (
        i_lang   IN language.id_language%TYPE,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Checks difference between number of allergies and criteria allergy choosen
    *
    * @param      i_prof                      professional structure id
    * @param      i_id_protocol               protocol id
    * @param      i_id_allergy                allergy id
    * @param      i_market                    allergies default market  
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_count_allergies
    (
        i_prof        profissional,
        i_id_protocol protocol.id_protocol%TYPE,
        i_id_allergy  allergy.id_allergy%TYPE,
        i_market      PLS_INTEGER
    ) RETURN NUMBER;

    /**
    *  Checks difference between number of nurse diagnosis and criteria nurse diagnosis choosen
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    * @param      I_ID_NURSE_DIAG              Nurse diagnosis ID
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_count_nurse_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   protocol.id_protocol%TYPE,
        i_id_nurse_diag NUMBER
    ) RETURN NUMBER;

    /** 
    *  Checks difference between number of diagnoses and criteria diagnoses choosen
    *
    * @param      I_ID_PROTOCOL  Protocol ID
    * @param      I_FLG_TYPE     Diagnoses type
    *
    * @return     NUMBER
    * @author     TS
    * @version    0.1
    * @since      2007/11/26
    */
    FUNCTION get_count_diagnoses
    (
        i_id_protocol protocol.id_protocol%TYPE,
        i_diags_type  diagnosis.flg_type%TYPE
    ) RETURN NUMBER;

    /**
    *  Checks difference between number of analysis and criteria
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL               protocol ID
    * @param      I_ID_SAMPLE_TYPE             Sample type ID
    * @param      I_ID_EXAM_CAT                Exam category
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_count_analysis_sample
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_protocol    protocol.id_protocol%TYPE,
        i_id_sample_type sample_type.id_sample_type%TYPE,
        i_id_exam_cat    exam_cat.id_exam_cat%TYPE
    ) RETURN NUMBER;

    /** 
    *  Search specific criterias
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                protocol ID
    * @param      I_CRITERIA_TYPE              Criteria type - 'I'nclusion / 'E'xclusion
    * @param      I_PROTOCOL_CRITERIA_SEARCH   Criteria search topics
    * @param      I_VALUE_SEARCH               Values to search
    * @param      o_flg_show                   shows warning message: Y - yes, N - No
    * @param      o_msg                        message text
    * @param      o_msg_title                  message title
    * @param      o_button                     buttons to show: N-No, R-Read, C-Confirmed
    * @param      O_CRITERIA_SEARCH            Cursor with all elements of specific criteria
    * @param      O_ERROR                      error
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/09
    */
    FUNCTION get_criteria_search
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol              IN NUMBER,
        i_criteria_type            IN VARCHAR2, -- Inclusion / exclusion
        i_protocol_criteria_search IN table_varchar,
        i_value_search             IN table_varchar,
        o_flg_show                 OUT VARCHAR2,
        o_msg                      OUT VARCHAR2,
        o_msg_title                OUT VARCHAR2,
        o_button                   OUT VARCHAR2,
        o_criteria_search          OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get criteria types
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                  protocol ID
    * @param      O_CRITERIA_TYPE              cursor with all criteria types
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_criteria_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        o_criteria_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Obtain all pathologies by search code
    *
    * @param      I_LANG                     Prefered languagie ID for this professional
    * @param      I_PROF                     object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL              Protocol ID
    * @param      I_VALUE_CODE               Value with code to search for
    * @param      O_PATHOLOGY_BY_SEARCH      cursor with all pathologies
    * @param      O_ERROR                    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_pathology_by_code
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_protocol       IN protocol.id_protocol%TYPE,
        i_value_code        IN VARCHAR2,
        o_pathology_by_code OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Obtain all pathologies by search
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
    * @param      I_VALUE                      Value to be searched in database
    * @param      O_PATHOLOGY_BY_SEARCH        cursor with all pathologies
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_pathology_by_search
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol         IN protocol.id_protocol%TYPE,
        i_value               IN VARCHAR2,
        o_pathology_by_search OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Obtain all pathologies by group
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                Protocol ID
    * @param      I_ID_PARENT                  Parent ID
    * @param      I_VALUE                      Value to be searched in database
    * @param      O_PATHOLOGY_BY_GROUP         cursor with all pathologies
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/08/10
    */
    FUNCTION get_pathology_by_group
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_protocol        IN protocol.id_protocol%TYPE,
        i_id_parent          IN diagnosis.id_diagnosis_parent%TYPE,
        i_value              IN VARCHAR2,
        o_pathology_by_group OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Gets a specialty list to which can be requested a opinion
    *
    * @param      I_LANG      Preferred language ID for this professional
    * @param      I_PROF      Object (ID of professional, ID of institution, ID of software)
    * @param      O_SPEC      Specialties list
    * @param      O_ERROR     Error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/03/12
    */
    FUNCTION get_opinion_spec_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_spec  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Gets a professionals list, of the given speciality, to which can be requested a opinion
    *
    * @param      I_LANG          Preferred language ID for this professional
    * @param      I_PROF          Object (ID of professional, ID of institution, ID of software)
    * @param      I_SPECIALITY    Professionals specialty
    * @param      O_PROF          Professionals list
    * @param      O_ERROR         Error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/03/12
    */
    FUNCTION get_opinion_prof_spec_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_speciality IN speciality.id_speciality%TYPE,
        o_prof       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Clean temp protocol
    *
    * @param      I_LANG              Prefered languagie ID for this professional
    * @param      I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL      ID of protocol.
    * @param      I_DATE_OFFSET       Date with offset in days
    * @param      O_ERROR             error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION clean_protocol_temp
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        i_date_offset IN protocol.dt_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Cancel a task request
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE                  Task Type
    * @param      i_id_episode                 episode id
    * @param      i_id_cancel_reason           cancel reason that justifies the task cancel
    * @param      i_cancel_notes               cancel notes (free text) that justifies the task cancel      
    * @param      i_transaction_id            Scheduler 3.0 remote id.    
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION cancel_task_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_type        IN protocol_task.task_type%TYPE,
        i_id_request       IN protocol_process_element.id_request%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN VARCHAR2,
        i_transaction_id   IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Verify if task request is scheduled.
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE                  Task Type
    * @param      I_ID_REQUEST                 Request ID of the task
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_task_request_schedule
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN protocol_task.task_type%TYPE,
        i_id_request IN protocol_process_element.id_request%TYPE
    ) RETURN VARCHAR2;

    /**
    *  Get status of a task request
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE                  Task Type
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_task_request_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN protocol_task.task_type%TYPE,
        i_id_request IN protocol_process_element.id_request%TYPE
    ) RETURN protocol_process_element.flg_status%TYPE;

    /**
    *  Update protocol process tasks status
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS      ID of protocol process
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION update_prot_proc_task_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Update protocol process status
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS       ID of protocol process
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION update_prot_proc_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Update all protocol processes status (including tasks)
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                Patient ID
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION update_all_prot_proc_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN protocol_process.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get recommended protocol
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                 Patient ID
    * @param      I_VALUE                      String to search for
    * @param      DT_SERVER                    Current server time
    * @param      O_PROTOCOL_RECOMMENDED       protocol recomended for specific user
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_recommended_protocol
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN protocol_process.id_patient%TYPE,
        i_value                IN VARCHAR2,
        dt_server              OUT VARCHAR2,
        o_protocol_recommended OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Change state of recomended protocol
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS       ID of protocol process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel     
    * @param      i_transaction_id            Scheduler 3.0 remote id.    
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_rec_protocol_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        i_id_action           IN action.id_action%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN VARCHAR2,
        i_transaction_id      IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Change state of recomended protocol
    *  Wrapper for flash. DO NOT USE OTHERWISE!!
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS       ID of protocol process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel     
    * @param      i_transaction_id            Scheduler 3.0 remote id.    
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION set_rec_protocol_status
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        i_id_action           IN action.id_action%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  cancel recomended protocol
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS       ID of protocol process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel   
    * @param      i_transaction_id            Scheduler 3.0 remote id.    
    
    * @param      I_ID_ACTION                 Action to execute
    
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION cancel_rec_protocol
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN VARCHAR2,
        i_transaction_id      IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  cancel recomended protocol
    *  wrapper for flash invocations. DO NOT USE OTHERWISE
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS       ID of protocol process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel       
    
    * @param      I_ID_ACTION                 Action to execute
    
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     CN
    * @version    0.1
    * @since      2010/03/09
    */
    FUNCTION cancel_rec_protocol
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all frequent protocols
    *
    * @param      i_lang                      preferred language id for this professional
    * @param      i_prof                      object (id of professional, id of institution, id of software)
    * @param      i_id_patient                patient id
    * @param      i_id_episode                episode id   
    * @param      i_flg_filter                protocols filter   
    * @param      i_value                     value to search for        
    * @param      o_guideline_frequent        guidelines cursor
    * @param      o_error                     error
    *
    * @value      i_flg_filter                {*} 'C' filtered by chief complaint
    *                                         {*} 'S' filtered by i_prof specialty 
    *                                         {*} 'F' all frequent protocols
    * 
    * @return     boolean                     true or false on success or error
    *
    * @author     Tiago Silva
    * @since      13-Jul-2007
    ********************************************************************************************/
    FUNCTION get_protocol_frequent
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN protocol_process.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_filter        IN VARCHAR2,
        i_value             IN VARCHAR2,
        o_protocol_frequent OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Verify if a protocol task is available for the software, institution and professional
    *
    * @param      I_LANG             Prefered language ID for this professional
    * @param      I_PROF             Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE        Type of the task
    * @param      I_ID_TASK          Task ID
    * @param      I_ID_TASK_ATTACH   Auxiliary ID associated to the task    
    * @param      i_id_episode       ID of the current episode 
    *
    * @return     VARCHAR2 (Y - available / N - not available)
    * @author     TS
    * @version    0.2
    * @since      2007/09/27
    */
    FUNCTION get_task_avail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_task_type      IN protocol_task.task_type%TYPE,
        i_id_task        IN protocol_task.id_task_link%TYPE,
        i_id_task_attach IN protocol_task.id_task_attach%TYPE,
        i_id_episode     IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**
    *  Get protocol tasks recommended
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_EPISODE                 Episode ID
    * @param      I_ID_PROTOCOL_PROCESS        ID of protocol process
    * @param      i_id_episode                 ID of the current episode
    * @param      DT_SERVER                    Current server time
    * @param      O_PROTOCOL_RECOMMENDED       protocol recomended for specific user
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_recommended_tasks
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN table_number,
        i_id_episode          IN episode.id_episode%TYPE,
        dt_server             OUT VARCHAR2,
        o_task_recommended    OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get protocol tasks recommended details
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE                  Task Type
    * @param      I_id_protocol_process_elem   ID da tarefa
    * @param      I_ID_EPISODE                 Episode ID         
    * @param      O_TASK_REC_DETAIL            Detail information for specific task
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_rec_task_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_task_type                IN protocol_task.task_type%TYPE,
        i_id_protocol_process_elem IN table_number,
        i_id_episode               IN episode.id_episode%TYPE,
        o_task_rec_detail          OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Calculates the next recommendation date for a protocol task
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS_ELEM  Protocol process ID
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/09/27
    */
    FUNCTION reset_task_frequency
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol_process_elem IN protocol_process_element.id_protocol_process_elem%TYPE
    ) RETURN BOOLEAN;

    /**
    *  Change state of recomended tasks for a protocol
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_id_protocol_process_elem  Protocol process ID
    * @param      I_ID_ACTION                 Action ID
    * @param      I_ID_REQUEST                Request ID
    * @param      I_DT_REQUEST                Date of request
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel 
    * @param      i_transaction_id            New scheduler remote id.         
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     SB/TS
    * @version    0.2
    * @since      2007/07/13
    */
    FUNCTION set_rec_task_status
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol_process_elem IN table_number,
        i_id_action                IN table_number,
        i_id_request               IN table_number,
        i_dt_request               IN VARCHAR2,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_cancel_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes             IN VARCHAR2,
        i_transaction_id           IN VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Change state of recomended tasks for a protocol
    *  Wrapper for flash invocations. DO NOT USE OTHERWISE !!!
    *
    * @param      I_LANG                      Prefered languagie ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_id_protocol_process_elem  Protocol process ID
    * @param      I_ID_ACTION                 Action ID
    * @param      I_ID_REQUEST                Request ID
    * @param      I_DT_REQUEST                Date of request
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel         
    * @param      O_ERROR                     error
    *
    * @return     boolean
    * @author     CN
    * @version    0.2
    * @since      2009/03/09
    */
    FUNCTION set_rec_task_status
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol_process_elem IN table_number,
        i_id_action                IN table_number,
        i_id_request               IN table_number,
        i_dt_request               IN VARCHAR2,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_cancel_reason         IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes             IN VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Cancel recomended task for a protocol
    *
    * @param      I_LANG                 Preferred language ID
    * @param      I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS  ID of the protocol process
    * @param      I_ID_PROTOCOL_ELEMENT  ID of the protocol element
    * @param      i_id_episode           episode id
    * @param      i_id_cancel_reason     cancel reason that justifies the task cancel
    * @param      i_cancel_notes         cancel notes (free text) that justifies the task cancel            
    * @param      O_ERROR                Error message
    *
    * @return     Boolean
    * @author     TS
    * @version    1.0
    * @since      2009/03/06
    */
    FUNCTION cancel_rec_task
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process_element.id_protocol_process%TYPE,
        i_id_protocol_element IN protocol_process_element.id_protocol_element%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes        IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get context info regarding a protocol
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_protocol               protocol ID
    * @param      O_protocol_HELP                       Cursor with all help information / context
    * @param      IO_ID                        Application variable
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_protocol_help
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        o_protocol_help OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    *  Get history details for  a protocol task
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL_PROCESS       Process ID
    * @param      O_PROTOCOL_DETAIL           Cursor with all help information / context
    * @param      O_PROTOCOL_PROC_INFO        Cursor with protocol process information
    * @param      IO_ID                        Application variable
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION get_protocol_detail_hst
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol_process IN protocol_process.id_protocol_process%TYPE,
        o_protocol_detail     OUT pk_types.cursor_type,
        o_protocol_proc_info  OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Call run_batch function. To be called by a job.
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    *
    * @author     SB
    * @version    0.1
    * @since      2007/08/13
    */
    PROCEDURE run_batch_job
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    );

    /** 
    *  Check if a protocol can be recommended to a patient according its history
    *
    * @param      i_id_protocol   Protocol ID
    * @param      i_id_patient    Patient ID        
    *
    * @author     TS
    * @version    0.1
    * @since      2007/09/27
    */
    FUNCTION check_history_protocol
    (
        i_id_protocol protocol.id_protocol%TYPE,
        i_id_patient  protocol_process.id_patient%TYPE
    ) RETURN VARCHAR2;

    /**
    *  Pick up patients for specific protocol
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                 Patient to apply protocol to
    * @param      I_BATCH_DESC                 Batch Description
    * @param      I_ID_PROTOCOL                protocol ID
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */

    FUNCTION run_batch
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_batch_desc  IN protocol_batch.batch_desc%TYPE,
        i_id_protocol IN protocol.id_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Create manual protocol processes
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                protocol ID
    * @param      I_ID_EPISODE                 Episode ID
    * @param      I_ID_PATIENT                 Patient ID
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     TS
    * @version    0.2
    * @since      2007/07/13
    */
    FUNCTION create_protocol_proc_manual
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN table_number,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Create protocol process
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PROTOCOL                protocol ID
    * @param      I_ID_BATCH                   Batch ID
    * @param      I_ID_EPISODE                 Episode ID
    * @param      I_ID_PATIENT                 Patient ID
    * @param      I_FLG_INIT_STATUS            Protocol process initial status
    * @param      I_FLG_NESTED_PROTOCOL        Nested protocol (Y/N)
    * @param      O_ID_PROTOCOL_PROCESS        Protocol process ID
    * @param      O_ERROR                      Error message
    *
    * @return     boolean
    * @author     SB/TS
    * @version    0.2
    * @since      2007/07/13
    */
    FUNCTION create_protocol_process
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_protocol         IN protocol.id_protocol%TYPE,
        i_id_protocol_batch   IN protocol_batch.id_protocol_batch%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_flg_init_status     IN protocol_process.flg_status%TYPE,
        i_flg_nested_protocol IN protocol_process.flg_nested_protocol%TYPE,
        o_id_protocol_process OUT protocol_process.id_protocol_process%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Function. returns IMC for specific height and weight
    * @param      I_ID_UNIT_MEASURE_HEIGHT          Unit of measure of height
    * @param      I_HEIGHT                          Height
    * @param      I_ID_UNIT_MEASURE_WEIGHT          Unit of measure of weight
    * @param      I_WEIGHT                          Weight
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_imc
    (
        i_id_unit_measure_height IN protocol_criteria.id_height_unit_measure%TYPE,
        i_height                 IN protocol_criteria.min_height%TYPE,
        i_id_unit_measure_weight IN protocol_criteria.id_weight_unit_measure%TYPE,
        i_weight                 IN protocol_criteria.min_weight%TYPE
    ) RETURN NUMBER;

    /**
    *  Get multichoice for action
    *
    * @param      I_LANG                       Prefered languagie ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_SUBJECT                    Subject of action
    * @param      I_ID_STATE                   Original state from which we want an action
    * @param      O_ACTION                     Cursor with all protocol types
    * @param      O_ERROR                      error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_action
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_subject  IN table_varchar, --action.subject%TYPE,
        i_id_state IN action.from_state%TYPE,
        o_action   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get all recommended protocol
    *
    * @param      I_LANG                           Prefered languagie ID for this professional
    * @param      I_PROF                           Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_EPISODE                     Episode ID
    * @param      I_VALUE_PAT_NAME_SEARCH          String to search for patient name
    * @param      I_VALUE_RECOM_protocol_SEARCH  String to search for recommended protocol
    * @param      I_VALUE_PROTOCOL_TYPE_SEARCH   Sring to search for protocol type
    * @param      DT_SERVER                        Current server time
    * @param      O_PROTOCOL_RECOMMENDED          Recommended protocol of all users
    * @param      O_ERROR                          error
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_all_recommended_protocol
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_value_pat_name_search       IN VARCHAR2,
        i_value_recom_protocol_search IN VARCHAR2,
        i_value_protocol_type_search  IN VARCHAR2,
        dt_server                     OUT VARCHAR2,
        o_protocol_recommended        OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get frequency list for protocol tasks
    *
    * @param      I_LANG     Prefered languagie ID for this professional
    * @param      O_FREQ     Frequencies cursor
    * @param      O_ERROR    error
    *
    * @return     boolean
    * @author     SB
    * @version    0.1
    * @since      2007/07/31
    */
    FUNCTION get_protocol_task_freq_list
    (
        i_lang  IN language.id_language%TYPE,
        o_freq  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    -----------------------------------------------------------------------------
    -- Cursor with different criterias
    -----------------------------------------------------------------------------
    CURSOR c_generic_link
    (
        c_protocol               protocol.id_protocol%TYPE,
        c_protocol_criteria_type protocol_criteria.criteria_type%TYPE
    ) IS
        SELECT --prot_crit.id_protocol_criteria,
         prot_crit_lnk.id_protocol_criteria_link,
         prot_crit_lnk.id_link_other_criteria,
         prot_crit_lnk.id_link_other_criteria_type
          FROM protocol_criteria prot_crit, protocol_criteria_link prot_crit_lnk
         WHERE prot_crit.id_protocol = c_protocol
           AND prot_crit.criteria_type = c_protocol_criteria_type
           AND prot_crit.id_protocol_criteria = prot_crit_lnk.id_protocol_criteria;

    /**
    *  Get criteria info
    *
    * @param C_PROTOCOL                     ID of protocol
    * @param C_PROTOCOL_CRITERIA_TYPE       Criteria Type
    *
    * @return     PIPELINED type t_coll_protocol_generic
    * @author     SB
    * @version    0.1
    * @since      2007/07/13
    */
    FUNCTION get_other_criteria
    (
        c_protocol               protocol.id_protocol%TYPE,
        c_protocol_criteria_type protocol_criteria.criteria_type%TYPE
    ) RETURN t_coll_protocol_generic
        PIPELINED;

    /********************************************************************************************
     * Get Advanced Input for protocol.
     *
     * @param I_LANG                   Preferred language ID for this professional
     * @param I_PROF                   Object (professional ID, institution ID, software ID)
     * @param I_ID_ADVANCED_INPUT      Advanced input ID to be shown
     * @param I_FLG_TYPE               Advanced for (C)riterias or (T)asks
     * @param I_ID_ADVANCED_INPUT_LINK Tasks or Criterias links to get advanced input data
     * @param O_FIELDS                 Advanced input fields and it's configurations
     * @param O_FIELDS_DET             Advanced input fields details
     * @param O_ERROR                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         SB
     * @version                        0.1
     * @since                          2007/08/07
    **********************************************************************************************/
    FUNCTION get_protocol_advanced_input
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_advanced_input IN advanced_input.id_advanced_input%TYPE,
        i_flg_type          IN protocol_adv_input_value.flg_type%TYPE,
        i_id_adv_input_link IN table_number,
        o_fields            OUT pk_types.cursor_type,
        o_fields_det        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
     * Get field's value for the Advanced Input of protocols
     *
     * @param I_LANG                   Preferred language ID for this professional
     * @param I_PROF                   Object (professional ID, institution ID, software ID)
     * @param I_ID_ADVANCED_INPUT      Advanced Input ID
     * @param I_FLG_TYPE               Advanced for (C)riterias or (T)asks
     * @param I_ID_ADV_INPUT_LINK      Tasks or Criterias links to get advanced input data
     *
     * @return                         PIPELINED type t_coll_protocol_adv_input
     * 
     * @author                         SB/TS
     * @version                        0.1
     * @since                          2007/04/19
    **********************************************************************************************/

    FUNCTION get_adv_input_field_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              profissional,
        i_id_advanced_input IN advanced_input.id_advanced_input%TYPE,
        i_flg_type          IN protocol_adv_input_value.flg_type%TYPE,
        i_id_adv_input_link IN table_number
    ) RETURN t_coll_protocol_adv_input
        PIPELINED;

    /********************************************************************************************
     * Set Advanced Input field value for protocol.
     *
     * @param I_LANG                                Preferred language ID for this professional
     * @param I_PROF                                Object (professional ID, institution ID, software ID)
     * @param I_FLG_TYPE                            Advanced for (C)riterias or (T)asks
     * @param I_VALUE_TYPE                          Value type : D-Date, V-Varchar N-Number
     * @param I_DVALUE                              Date value
     * @param I_NVALUE                              Number value
     * @param I_VVALUE                              Varchar value
     * @param I_VALUE_DESC                          Value description
     * @param I_CRITERIA_VALUE_TYPE                 Criteria Value Type
     * @param I_ID_ADVANCED_INPUT                   Advanced Input ID
     * @param I_ID_ADVANCED_INPUT_FIELD             Advanced Input Field ID        
     * @param I_ID_ADVANCED_INPUT_FIELD_DET         Advanced Input Field ID Det    
     
     * @param O_ERROR                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         SB
     * @version                        0.1
     * @since                          2007/08/07
    **********************************************************************************************/
    FUNCTION set_protocol_adv_input_value
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_adv_input_link           IN protocol_adv_input_value.id_adv_input_link%TYPE,
        i_flg_type                    IN protocol_adv_input_value.flg_type%TYPE,
        i_value_type                  IN table_varchar,
        i_dvalue                      IN table_date,
        i_nvalue                      IN table_number,
        i_vvalue                      IN table_varchar,
        i_value_desc                  IN table_varchar,
        i_criteria_value_type         IN table_number,
        i_id_advanced_input           IN table_number,
        i_id_advanced_input_field     IN table_number,
        i_id_advanced_input_field_det IN table_number,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
     * Set active state for a specific protocol process element
     *
     * @param I_LANG                                Preferred language ID for this professional
     * @param I_PROF                                Object (professional ID, institution ID, software ID)
     * @param I_ID_PROTOCOL_PROCESS                 Protocol Process ID
     * @param I_ID_PROTOCOL_PROCESS_OLD             OLD element 
     * @param I_ID_PROTOCOL_PROCESS_NEW             New active element
     * @param I_FLG_ACTIVE_OLD                      Flag active for old element
     * @param I_FLG_ACTIVE_NEW                      Flag active for new element
     
     * @param O_ERROR                  Error message
     *
     * @return                         true or false on success or error
     * 
     * @author                         SB
     * @version                        0.1
     * @since                          2007/08/24
    */

    FUNCTION set_protocol_active_element
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_protocol_process     IN protocol_process_element.id_protocol_process%TYPE,
        i_id_protocol_element_old IN protocol_process_element.id_protocol_process%TYPE,
        i_id_protocol_element_new IN protocol_process_element.id_protocol_process%TYPE,
        i_flg_active_old          IN protocol_process_element.flg_active%TYPE,
        i_flg_active_new          IN protocol_process_element.flg_active%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all complaints that can be associated to the protocol
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                protocol id
    * @param      i_value                      search string
    * @param      o_complaints                 cursor with all complaints that can be associated to the protocols
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   30-Nov-2010
    ********************************************************************************************/
    FUNCTION get_complaint_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        i_value       IN VARCHAR2,
        o_complaints  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set protocol complaints
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                protocol id
    * @param      i_link_complaint             array with complaints
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   30-Nov-2010
    ********************************************************************************************/
    FUNCTION set_protocol_chief_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_protocol    IN protocol.id_protocol%TYPE,
        i_link_complaint IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all filters for frequent protocols screen
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_patient                    patient id
    * @param      i_episode                    episode id    
    * @param      o_filters                    cursor with all filters for frequent protocols screen
    
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   30-Nov-2010
    ********************************************************************************************/
    FUNCTION get_protocol_filters
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_filters OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    -------------------------------------------------------------------
    -- Exception for dml errors
    dml_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(dml_errors, -24381);
    g_error VARCHAR2(2000);
    -- Bulk fetch limit   
    g_bulk_fetch_rows PLS_INTEGER;

    -- Protocol type
    g_protocol_type_any NUMBER;
    -- Pathology type
    g_protocol_pathol_any NUMBER;
    -- Truncate string
    g_trunc_str VARCHAR2(30);

    -- Flg active types
    g_flag_active_initial   VARCHAR2(1 CHAR);
    g_flag_active_active    VARCHAR2(1 CHAR);
    g_flag_active_read      VARCHAR2(1 CHAR);
    g_flag_active_exec      VARCHAR2(1 CHAR);
    g_flag_active_ignored   VARCHAR2(1 CHAR);
    g_flag_active_cancelled VARCHAR2(1 CHAR);

    -- Link types   
    g_protocol_link_pathol      VARCHAR2(1 CHAR);
    g_protocol_link_envi        VARCHAR2(1 CHAR);
    g_protocol_link_prof        VARCHAR2(1 CHAR);
    g_protocol_link_spec        VARCHAR2(1 CHAR);
    g_protocol_link_type        VARCHAR2(1 CHAR);
    g_protocol_link_edit_prof   VARCHAR2(1 CHAR);
    g_protocol_link_chief_compl VARCHAR2(1 CHAR);

    -- frequent protocol filter types
    g_prot_filter_chief_compl VARCHAR2(1 CHAR);
    g_prot_filter_specialty   VARCHAR2(1 CHAR);
    g_prot_filter_frequent    VARCHAR2(1 CHAR);

    -- Diagnostics
    g_diag_available  VARCHAR2(1 CHAR);
    g_diag_select     VARCHAR2(1 CHAR);
    g_diag_not_select VARCHAR2(1 CHAR);
    g_diag_freq       VARCHAR2(1 CHAR);
    g_diag_req        VARCHAR2(1 CHAR);
    g_diag_type_icpc2 VARCHAR2(1 CHAR);
    -- Allergy
    g_ale_available  VARCHAR2(1 CHAR);
    g_ale_select     VARCHAR2(1 CHAR);
    g_ale_not_select VARCHAR2(1 CHAR);
    g_ale_freq       VARCHAR2(1 CHAR);
    -- Professional
    g_prof_selected VARCHAR2(1 CHAR);
    -- Criteria
    g_criteria_type_inc VARCHAR2(1 CHAR);
    g_criteria_type_exc VARCHAR2(1 CHAR);
    -- Generic
    g_active         VARCHAR2(1 CHAR);
    g_inactive       VARCHAR2(1 CHAR);
    g_available      VARCHAR2(1 CHAR);
    g_not_available  VARCHAR2(1 CHAR);
    g_selected       VARCHAR2(1 CHAR);
    g_not_selected   VARCHAR2(1 CHAR);
    g_selectedpt     VARCHAR2(1 CHAR);
    g_not_selectedpt VARCHAR2(1 CHAR);

    g_separator  VARCHAR2(10);
    g_separator2 VARCHAR2(10);
    g_separator3 VARCHAR2(10);
    g_bullet     VARCHAR2(10);

    g_all_institution      institution.id_institution%TYPE;
    g_all_software         software.id_software%TYPE;
    g_all_profile_template profile_template.id_profile_template%TYPE;
    g_all_markets          market.id_market%TYPE;

    -- Cancel flag
    g_cancelled     VARCHAR2(1 CHAR);
    g_not_cancelled VARCHAR2(1 CHAR);
    -- Criteria flag
    g_criteria_already_set      NUMBER;
    g_criteria_clear            NUMBER;
    g_criteria_already_crossset NUMBER;
    g_criteria_group_some       NUMBER;
    g_criteria_group_all        NUMBER;
    -- Link states
    g_link_state_new  NUMBER;
    g_link_state_del  NUMBER;
    g_link_state_keep NUMBER;
    -- Protocol states
    g_protocol_temp       protocol.flg_status%TYPE;
    g_protocol_finished   protocol.flg_status%TYPE;
    g_protocol_deleted    protocol.flg_status%TYPE;
    g_protocol_deprecated protocol.flg_status%TYPE;
    -- Other criteria types
    g_protocol_diagnosis       protocol_criteria_link.id_link_other_criteria_type%TYPE;
    g_protocol_analysis        protocol_criteria_link.id_link_other_criteria_type%TYPE;
    g_protocol_allergies       protocol_criteria_link.id_link_other_criteria_type%TYPE;
    g_protocol_exams           protocol_criteria_link.id_link_other_criteria_type%TYPE;
    g_protocol_drug            protocol_criteria_link.id_link_other_criteria_type%TYPE;
    g_protocol_other_exams     protocol_criteria_link.id_link_other_criteria_type%TYPE;
    g_protocol_diagnosis_nurse protocol_criteria_link.id_link_other_criteria_type%TYPE;
    -- Process task details type
    g_proc_task_det_freq     protocol_process_task_det.flg_detail_type%TYPE;
    g_proc_task_det_next_rec protocol_process_task_det.flg_detail_type%TYPE;
    -- Task type
    g_all_tasks                  NUMBER;
    g_task_analysis              NUMBER; -- Analises
    g_task_appoint               NUMBER; -- Consulta
    g_task_patient_education     NUMBER; -- Patient education
    g_task_img                   NUMBER; -- Imagem: exam
    g_task_vacc                  NUMBER; -- Imunizações: vaccine
    g_task_enfint                NUMBER; -- Intervenções de enfermagem
    g_task_drug                  NUMBER; -- Medicação : drug / tabelas infarmed
    g_task_otherexam             NUMBER; -- Outros exames : exam
    g_task_spec                  NUMBER; -- Pareceres : speciality
    g_task_rast                  NUMBER; -- Rastreios : not done yet
    g_task_drug_ext              NUMBER; -- Drug external
    g_task_proc                  NUMBER; -- Procedimentos
    g_task_fluid                 NUMBER; -- Soros
    g_task_monitorization        NUMBER; -- Monitorizacoes
    g_task_specialty_appointment NUMBER; -- consultas de especialidade

    -- Criteria
    g_crit_age                   NUMBER; -- idade
    g_crit_weight                NUMBER; -- peso
    g_crit_height                NUMBER; -- altura
    g_crit_imc                   NUMBER; -- IMC (índice de massa corporal)
    g_crit_sistolic_blood_press  NUMBER; -- Pressão arterial sistólica
    g_crit_diastolic_blood_press NUMBER; -- Pressão arterial diastólica

    -- Process States
    g_process_pending     protocol_process.flg_status%TYPE;
    g_process_recommended protocol_process.flg_status%TYPE;
    g_process_running     protocol_process.flg_status%TYPE;
    g_process_finished    protocol_process.flg_status%TYPE;
    g_process_suspended   protocol_process.flg_status%TYPE;
    g_process_canceled    protocol_process.flg_status%TYPE;
    g_process_scheduled   protocol_process.flg_status%TYPE;
    g_process_closed      protocol_process.flg_status%TYPE;

    -- Weights of process states
    g_process_running_weight     NUMBER;
    g_process_recommended_weight NUMBER;
    g_process_pending_weight     NUMBER;
    g_process_scheduled_weight   NUMBER;
    g_process_finished_weight    NUMBER;
    g_process_suspended_weight   NUMBER;
    g_process_canceled_weight    NUMBER;
    g_process_closed_weight      NUMBER;
    -- Gender
    g_gender_male   protocol_criteria.gender%TYPE;
    g_gender_female protocol_criteria.gender%TYPE;
    -- Unit of measure
    g_um_weight PLS_INTEGER;
    g_um_height PLS_INTEGER;
    -- Unit of measure
    g_imc_weight_default_um PLS_INTEGER;
    g_imc_height_default_um PLS_INTEGER;
    -- Blood pressure unit of measure
    g_blood_pressure_default_um PLS_INTEGER;
    -- Vital sign criterias
    g_weight_measure           PLS_INTEGER;
    g_height_measure           PLS_INTEGER;
    g_blood_pressure_s_measure PLS_INTEGER;
    g_blood_pressure_d_measure PLS_INTEGER;
    g_blood_pressure_measure   PLS_INTEGER;
    -- Min and max biometric values
    g_max_age              NUMBER;
    g_min_age              NUMBER;
    g_min_height           NUMBER;
    g_max_height           NUMBER;
    g_min_weight           NUMBER;
    g_max_weight           NUMBER;
    g_min_imc              NUMBER;
    g_max_imc              NUMBER;
    g_min_blood_pressure_s PLS_INTEGER;
    g_max_blood_pressure_s PLS_INTEGER;
    g_min_blood_pressure_d PLS_INTEGER;
    g_max_blood_pressure_d PLS_INTEGER;
    -- Batch types
    g_batch_all   VARCHAR2(1 CHAR); -- all protocol / all patients
    g_batch_1p_ag VARCHAR2(1 CHAR); -- one user /all protocol
    g_batch_1p_1g VARCHAR2(1 CHAR); -- one user /one protocol
    g_batch_ap_1g VARCHAR2(1 CHAR); -- all users /one protocol
    -- Process status
    g_process_active   VARCHAR2(1 CHAR);
    g_process_inactive VARCHAR2(1 CHAR);
    -- Generic variables for actions
    g_protocol sys_domain.code_domain%TYPE;
    g_task     sys_domain.code_domain%TYPE;

    -- Domains
    g_domain_gender             sys_domain.code_domain%TYPE;
    g_domain_type_media         sys_domain.code_domain%TYPE;
    g_domain_inc_gen            sys_domain.code_domain%TYPE;
    g_domain_exc_gen            sys_domain.code_domain%TYPE;
    g_domain_language           sys_domain.code_domain%TYPE;
    g_domain_professional_title sys_domain.code_domain%TYPE;
    g_domain_flg_protocol       sys_domain.code_domain%TYPE;
    g_domain_flg_protocol_elem  sys_domain.code_domain%TYPE;
    g_domain_task_type          sys_domain.code_domain%TYPE;
    g_domain_flg_type_rec       sys_domain.code_domain%TYPE;
    g_domain_allergy_type       sys_domain.code_domain%TYPE;
    g_domain_allergy_status     sys_domain.code_domain%TYPE;
    g_domain_diagnosis_status   sys_domain.code_domain%TYPE;
    g_domain_diagnosis_nature   sys_domain.code_domain%TYPE;
    g_domain_nurse_diag_status  sys_domain.code_domain%TYPE;
    g_domain_adv_input_freq     sys_domain.code_domain%TYPE;
    g_domain_prot_elem          sys_domain.code_domain%TYPE;
    g_domain_prot_connector     sys_domain.code_domain%TYPE;
    g_domain_prot_proc_active   sys_domain.code_domain%TYPE;
    g_domain_adv_input_flg_type sys_domain.code_domain%TYPE;
    g_domain_protocol_item_type sys_domain.code_domain%TYPE;

    -- Icons
    g_alert_icon   VARCHAR2(100);
    g_waiting_icon VARCHAR2(100);
    -- Generic protocols

    g_unknown_link_type   VARCHAR2(50);
    g_unknown_detail_type VARCHAR2(50);

    g_close_task             VARCHAR2(1 CHAR);
    g_cancel_task            VARCHAR2(1 CHAR);
    g_cancel_protocol        VARCHAR2(1 CHAR);
    g_state_cancel_operation NUMBER;

    -- Advanced Input configurations
    g_advanced_input_drug advanced_input.id_advanced_input%TYPE;

    -- Criteria Value
    g_protocol_d_type VARCHAR2(1 CHAR);
    g_protocol_n_type VARCHAR2(1 CHAR);
    g_protocol_v_type VARCHAR2(1 CHAR);
    -- Keypad Date
    g_date_keypad advanced_input_field.type%TYPE;
    -- Boolean values
    g_true  VARCHAR2(1 CHAR);
    g_false VARCHAR2(1 CHAR);
    -- Edit Protocol options
    g_message_edit_protocol      sys_message.code_message%TYPE;
    g_message_create_protocol    sys_message.code_message%TYPE;
    g_message_duplicate_protocol sys_message.code_message%TYPE;
    g_edit_protocol_option       VARCHAR2(1 CHAR);
    g_create_protocol_option     VARCHAR2(1 CHAR);
    g_duplicate_protocol_option  VARCHAR2(1 CHAR);

    -- Protocol edit options
    g_protocol_editable   VARCHAR2(1 CHAR);
    g_protocol_duplicable VARCHAR2(1 CHAR);
    g_protocol_viewable   VARCHAR2(1 CHAR);

    g_message_any       sys_message.code_message%TYPE;
    g_message_scheduled sys_message.code_message%TYPE;
    -- Exam types
    g_exam_only_img VARCHAR2(1 CHAR);
    -- Image status
    g_img_inactive VARCHAR2(1 CHAR);
    g_img_active   VARCHAR2(1 CHAR);
    -- Active states for measures
    g_patient_active VARCHAR2(1 CHAR);
    g_measure_active VARCHAR2(1 CHAR);
    -- Pat Allergy flg_status
    g_allergy_active  VARCHAR2(1 CHAR);
    g_allergy_passive VARCHAR2(1 CHAR);
    -- Nurse diagnosis flg_status
    g_nurse_active   VARCHAR2(1 CHAR);
    g_nurse_finished VARCHAR2(1 CHAR);
    g_nurse_solved   VARCHAR2(1 CHAR);
    -- Analysis criteria
    g_analysis_available analysis.flg_available%TYPE;
    g_analysis_selected  VARCHAR2(1 CHAR);
    g_samp_type_avail    sample_type.flg_available%TYPE;
    -- Nurse diagnosis criteria
    g_composition_diag_type VARCHAR2(1 CHAR);
    -- Exams
    g_exam_type_img            VARCHAR2(1 CHAR);
    g_exam_can_req             VARCHAR2(1 CHAR);
    g_exam_available           VARCHAR2(1 CHAR);
    g_exam_freq                VARCHAR2(1 CHAR);
    g_exam_selected            VARCHAR2(1 CHAR);
    g_exam_pregnant_ultrasound VARCHAR2(1 CHAR);

    -- Drug external
    g_yes  VARCHAR2(1 CHAR);
    g_no   VARCHAR2(1 CHAR);
    g_sch  VARCHAR2(50);
    g_cipe VARCHAR2(50);

    -- Type of elements
    g_element_task        VARCHAR2(1 CHAR);
    g_element_question    VARCHAR2(1 CHAR);
    g_element_warning     VARCHAR2(1 CHAR);
    g_element_instruction VARCHAR2(1 CHAR);
    g_element_header      VARCHAR2(1 CHAR);
    g_element_protocol    VARCHAR2(1 CHAR);
    -- Advanced Input type
    g_adv_input_type_tasks     VARCHAR2(1 CHAR);
    g_adv_input_type_criterias VARCHAR2(1 CHAR);

    -- Protocol type recommendation
    g_default_type_rec   protocol.flg_type_recommendation%TYPE;
    g_type_rec_manual    protocol.flg_type_recommendation%TYPE;
    g_type_rec_automatic protocol.flg_type_recommendation%TYPE;
    -- Advanced input field ID
    g_frequency_field              NUMBER;
    g_allergy_status_field         NUMBER;
    g_allergy_react_field          NUMBER;
    g_diagnosis_status_field       NUMBER;
    g_diagnosis_nature_field       NUMBER;
    g_nurse_diagnosis_status_field NUMBER;

    -- Type of patient problems
    g_pat_probl_not_capable VARCHAR2(1 CHAR);

    -- Appointments specialties
    g_prof_active             VARCHAR2(1 CHAR);
    g_external_appoint        VARCHAR2(1 CHAR);
    g_message_spec_appoint    sys_message.code_message%TYPE;
    g_message_foll_up_appoint sys_message.code_message%TYPE;

    -- CONFIGS in SYS_CONFIG
    g_config_func_consult_req sys_config.id_sys_config%TYPE;
    g_config_func_opinion     sys_config.id_sys_config%TYPE;
    g_config_max_diag_rownum  sys_config.id_sys_config%TYPE;

    -- Action subjects
    g_action_protocol_tasks action.subject%TYPE;

    -- Icon colors
    g_green_color VARCHAR2(1 CHAR);
    g_red_color   VARCHAR2(1 CHAR);

    -- State symbols
    g_icon      VARCHAR2(5);
    g_text_icon VARCHAR2(5);
    g_text      VARCHAR2(5);
    g_date      VARCHAR2(5);

    -- Type protocol items
    g_protocol_item_tasks    protocol_item_soft_inst.flg_item_type%TYPE;
    g_protocol_item_criteria protocol_item_soft_inst.flg_item_type%TYPE;

    -- Task frequency
    g_task_unique_freq sys_domain.val%TYPE;

    -- Schedule task
    g_scheduled     VARCHAR2(1 CHAR);
    g_not_scheduled VARCHAR2(1 CHAR);

    -- Tasks request
    g_img_request       VARCHAR2(1 CHAR);
    g_otherexam_request VARCHAR2(1 CHAR);
    g_proc_request      VARCHAR2(1 CHAR);
    g_drug_request      VARCHAR2(1 CHAR);
    g_drug_ext_request  VARCHAR2(1 CHAR);

    -- Nested protocol
    g_nested_protocol     protocol_process.flg_nested_protocol%TYPE;
    g_not_nested_protocol protocol_process.flg_nested_protocol%TYPE;

    -- Protocol duplication
    g_duplicate_protocol     VARCHAR2(1 CHAR);
    g_not_duplicate_protocol VARCHAR2(1 CHAR);

    -- Predefined protocol authors
    g_message_protocol_authors sys_message.code_message%TYPE;

    -- Any criteria detail value
    g_detail_any NUMBER;

    -- Pregnancy process
    g_pregnancy_process_active pat_pregnancy.flg_status%TYPE;
    g_error_message            VARCHAR2(50);
    g_all                      VARCHAR2(50);

    -- Opinion message
    g_message_opinion_any_prof sys_message.code_message%TYPE;

    -- NA message
    g_message_na sys_message.code_message%TYPE;

    -- pk_consult_req.get_subs_req_amb flg_type constants
    g_cons_followup VARCHAR2(1 CHAR) := 'S';
    g_cons_spec     VARCHAR2(1 CHAR) := 'E';

    g_flg_time_epis VARCHAR2(1 CHAR) := 'E';

    -- Log variables
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);
END pk_protocol;
/
