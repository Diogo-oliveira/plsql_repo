/*-- Last Change Revision: $Rev: 2028706 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_guidelines IS

    /** 
    *  Convert date strings to date format
    *
    * @param C_date   String of date
    *
    * @return     TIMESTAMP WITH LOCAL TIME ZONE
    * @author     SB
    * @version    0.1
    * @since      2007/04/26
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
    *  Returns string with specific link type content separated by defined separator
    *
    * @param I_LANG                 Language
    * @param I_PROF                 Professional structure
    * @param I_ID_GUIDELINE         Guideline
    * @param I_LINK_TYPE            Type of Link
    * @param I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/02/06
    */
    FUNCTION get_link_id_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_link_type    IN guideline_link.link_type%TYPE,
        i_separator    IN VARCHAR2
    ) RETURN VARCHAR2;

    /** 
    *  Returns string with the details of an item (guideline task or criteria) 
    *  between brackets and separated by defined separator
    *
    * @param  I_LANG          Language
    * @param  I_PROF          Professional structure
    * @param  I_TYPE_ITEM     Type of the guideline item (C)riteria or (T)ask
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
        i_type_item IN guideline_adv_input_value.flg_type%TYPE,
        i_id_item   IN guideline_adv_input_value.id_adv_input_link%TYPE,
        i_separator IN VARCHAR2
    ) RETURN VARCHAR2;

    /** 
    *  Returns string with specific link criteria type content separated by defined separator
    *
    * @param  I_LANG                       Language
    * @param  I_PROF                       Professional structure
    * @param  I_ID_GUIDELINE               Guideline
    * @param  I_CRIT_TYPE                  Type of Criteria: Inclusion or Exclusion
    * @param  I_ID_CRIT_OTHER_TYPE         ID of other type of criteria        
    * @param  I_BULLET                     Bullet for the criteria list
    * @param  I_SEPARATOR                  Separator between criteria
    * @param  I_FLG_DETAILS                Define if details should appear    
    * @param  I_ID_LINK_OTHER_CRITERIA     ID of other criteria
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.2
    * @since      2007/02/23
    */
    FUNCTION get_criteria_link_id_str
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        i_crit_type              IN guideline_criteria.criteria_type%TYPE,
        i_id_crit_other_type     IN guideline_criteria_link.id_link_other_criteria_type%TYPE,
        i_bullet                 IN VARCHAR2,
        i_separator              IN VARCHAR2,
        i_flg_details            IN VARCHAR2,
        i_id_link_other_criteria IN guideline_criteria_link.id_link_other_criteria%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /** 
    *  Returns string with specific task ID content 
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_GUIDELINE_PROCESS ID of guideline process
    * @param  I_ID_TASK              ID of task
    * @param  I_TASK_TYPE            Type of task
    * @param  I_TASK_CODICATION      Task codification
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_task_id_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_task           IN guideline_task_link.id_task_link%TYPE,
        i_task_type         IN guideline_task_link.task_type%TYPE,
        i_task_codification IN guideline_task_link.task_codification%TYPE
    ) RETURN VARCHAR2;

    /** 
    *  Returns string with specific task content separated by defined separator
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_GUIDELINE         Guideline
    * @param  I_TASK_TYPE            Type of task
    * @param  I_SEPARATOR            Separator between diferent elements of string
    * @param  I_FLG_NOTES            Define if notes should appear
    * @param  I_FLG_DETAILS          Define if details should appear
    * @param  I_ID_TASK              ID of task
    * @param  I_TASK_CODICATION      Task codification
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_task_id_str
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_guideline      IN guideline.id_guideline%TYPE,
        i_task_type         IN guideline_task_link.task_type%TYPE,
        i_separator         IN VARCHAR2,
        i_flg_notes         IN VARCHAR2,
        i_flg_details       IN VARCHAR2,
        i_id_task           IN guideline_task_link.id_task_link%TYPE DEFAULT NULL,
        i_task_codification IN guideline_task_link.task_codification%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /** 
    *  Returns string with author of a specified guideline
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_GUIDELINE         Guideline
    * @param  I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/03/27
    */

    FUNCTION get_context_author_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_separator    IN VARCHAR2
    ) RETURN VARCHAR2;

    /** 
    *  Returns string with picture name separated by defined separator
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_GUIDELINE         Guideline
    * @param  I_SEPARATOR            Separator between diferent elements of string
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/04/16
    */

    FUNCTION get_image_str
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_separator    IN VARCHAR2
    ) RETURN VARCHAR2;

    /** 
    *  Returns string with specific criteria_type
    *
    * @param  I_LANG                 Language
    * @param  I_PROF                 Professional structure
    * @param  I_ID_CRITERIA_TYPE     Criteria type ID
    *
    * @return     VARCHAR2
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_criteria_type_desc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_criteria_type IN guideline_criteria_type.id_guideline_criteria_type%TYPE
    ) RETURN VARCHAR2;

    /** 
    *  Create specific guideline
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Object (ID of professional, ID of institution, ID of software)
    * @param      I_DUPLICATE_FLG              Duplicate guideline (Y/N)    
    
    * @param      O_ID_GUIDELINE               identifier of guideline created
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/06
    */
    FUNCTION create_guideline
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_guideline  IN guideline.id_guideline%TYPE,
        i_duplicate_flg IN VARCHAR2,
        ---
        o_id_guideline OUT guideline.id_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Set specific guideline main attributes
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_GUIDELINE_DESC             Guideline description       
    * @param      I_ID_GUIDELINE_TYPE          Guideline Type
    * @param      I_LINK_ENVIRONMENT           Guideline environment link        
    * @param      I_LINK_SPECIALTY             Guideline specialty link
    * @param      I_LINK_PROFESSIONAL          Guideline professional link
    * @param      I_LINK_EDIT_PROF             Guideline edit professional link
    * @param      I_TYPE_RECOMMEDNATION        Guideline type of recommendation
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/22
    */
    FUNCTION set_guideline_main
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        i_guideline_desc IN guideline.guideline_desc%TYPE,
        --  i_id_guideline_type IN guideline.id_guideline_type%TYPE,
        i_link_type IN table_number,
        -- to review if we need more than one ID
        i_link_environment    IN table_number,
        i_link_specialty      IN table_number,
        i_link_professional   IN table_number,
        i_link_edit_prof      IN table_number,
        i_type_recommendation IN guideline.flg_type_recommendation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Set specific guideline main pathology
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE                  Guideline ID
    * @param      I_LINK_PATHOLOGY             Pathology link ID     
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/16
    */
    FUNCTION set_guideline_main_pathology
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        i_link_pathology IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get guideline items to be shown
    *
    * @param      I_LANG      Preferred language ID for this professional
    * @param      I_PROF      Object (ID of professional, ID of institution, ID of software)
    * @param      O_ITEMS     List of items to be shown
    * @param      O_ERROR     error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/08/28
    */
    FUNCTION get_guideline_items
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_items OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get guideline main attributes
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    
    * @param      O_GUIDELINE_MAIN             Guideline main attributes cursor
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_main
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        o_guideline_main OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Obtain all guidelines by title
    *
    * @param      I_LANG                 Preferred language ID for this professional
    * @param      I_PROF                 object (ID of professional, ID of institution, ID of software)
    * @param      I_VALUE                Value to search for        
    * @param      I_ID_PATIENT           Patient ID   
    * @param      O_GUIDELINES           cursor with all guidelines
    * @param      O_ERROR                error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/04
    */
    FUNCTION get_guideline_by_title
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_value      IN VARCHAR2,
        i_id_patient IN guideline_process.id_patient%TYPE,
        o_guidelines OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get all guideline types
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_GUIDELINE_TYPE             Cursor with all guideline types
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/04
    */
    FUNCTION get_guideline_type_all
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_guideline_type OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get pathologies of a specific type of guidelines
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_TYPE          ID of guideline type
    * @param      I_ID_PATIENT                 Patient ID
    * @param      O_GUIDELINE_PATHOL           Cursor with pathologies
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.4
    * @since      2007/05/04
    */
    FUNCTION get_guideline_pathologies
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_guideline_type IN guideline_link.id_link%TYPE,
        i_id_patient        IN guideline_process.id_patient%TYPE,
        o_guideline_pathol  OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get all guidelines by type and pathology
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_TYPE          ID of guideline type
    * @param      I_ID_GUIDELINE_PATHO         ID of guideline pathology
    * @param      I_ID_PATIENT                 Patient ID   
    * @param      O_GUIDELINE_PATHOL           Cursor with pathologies
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/04
    */
    FUNCTION get_guideline_by_type_patho
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_guideline_type   IN guideline_link.id_link%TYPE,
        i_id_guideline_pathol IN guideline_link.id_link%TYPE,
        i_id_patient          IN guideline_process.id_patient%TYPE,
        o_guidelines          OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Gets guideline pathology ids
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    
    * @param      O_PATHOLOGY_ID               Guideline pathology ids
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_pathology_id
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
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
    *  Set guideline criteria
    *
    * @param      I_LANG                         Preferred language ID for this professional
    * @param      I_PROF                         Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE                 Guideline ID
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
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/16
    */
    FUNCTION set_guideline_criteria
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_guideline                IN guideline.id_guideline%TYPE,
        i_criteria_type               IN guideline_criteria.criteria_type%TYPE,
        i_gender                      IN guideline_criteria.gender%TYPE,
        i_min_age                     IN guideline_criteria.min_age%TYPE,
        i_max_age                     IN guideline_criteria.max_age%TYPE,
        i_min_weight                  IN guideline_criteria.min_weight%TYPE,
        i_max_weight                  IN guideline_criteria.max_weight%TYPE,
        i_id_weight_unit_measure      IN guideline_criteria.id_weight_unit_measure%TYPE,
        i_min_height                  IN guideline_criteria.min_height%TYPE,
        i_max_height                  IN guideline_criteria.max_height%TYPE,
        i_id_height_unit_measure      IN guideline_criteria.id_height_unit_measure%TYPE,
        i_imc_min                     IN guideline_criteria.imc_min%TYPE,
        i_imc_max                     IN guideline_criteria.imc_max%TYPE,
        i_id_blood_press_unit_measure IN guideline_criteria.id_blood_pressure_unit_measure%TYPE,
        i_min_blood_pressure_s        IN guideline_criteria.min_blood_pressure_s%TYPE,
        i_max_blood_pressure_s        IN guideline_criteria.max_blood_pressure_s%TYPE,
        i_min_blood_pressure_d        IN guideline_criteria.min_blood_pressure_d%TYPE,
        i_max_blood_pressure_d        IN guideline_criteria.max_blood_pressure_d%TYPE,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Set guideline criteria
    *
    * @param      I_LANG                        Preferred language ID for this professional
    * @param      I_PROF                        Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE                Guideline ID
    * @param      I_CRITERIA_TYPE               Criteria Type: Inclusion / Exclusion
    * @param      I_ID_LINK_OTHER_CRITERIA      Other criterias link
    * @param      I_ID_LINK_OTHER_CRITERIA_TYPE Type of other criteria link
    
    * @param      O_ID_GUID_CRITERIA_LINK       New ID of each criteria
    * @param      O_ERROR                       error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */

    FUNCTION set_guideline_criteria_other
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_guideline                IN guideline.id_guideline%TYPE,
        i_criteria_type               IN guideline_criteria.criteria_type%TYPE,
        i_id_link_other_criteria      IN table_varchar,
        i_id_link_other_criteria_type IN table_number,
        o_id_guid_criteria_link       OUT table_number,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get guideline criteria
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_CRITERIA_TYPE              Criteria Type: Inclusion / Exclusion
    
    * @param      O_GUIDELINE_CRITERIA         Cursor for guideline criteria
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */

    FUNCTION get_guideline_criteria
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_guideline       IN guideline.id_guideline%TYPE,
        i_criteria_type      IN guideline_criteria.criteria_type%TYPE,
        o_guideline_criteria OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get guideline criteria
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_GUIDELINE_CRITERIA         Cursor for guideline criteria
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/20
    */
    FUNCTION get_guideline_criteria_all
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        o_guideline_criteria_all OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get guideline tasks
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_TASK_TYPE                  Task type list wanted
    * @param      O_GUIDELINE_TASK             Cursor for guideline tasks
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/29
    */
    FUNCTION get_guideline_task_all
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_guideline       IN guideline.id_guideline%TYPE,
        i_task_type          IN guideline_task_link.task_type%TYPE,
        o_guideline_task_all OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Delete guideline task
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_TASK_LINK     Guideline task link ID
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/03/11
    */
    FUNCTION delete_guideline_task
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline_task_link IN table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Set guideline task
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_TASK_LINK               Task link ID
    * @param      I_TASK_TYPE                  Task Type
    * @param      I_TASK_NOTES                 Task notes
    * @param      I_ID_TASK_ATTACH             Auxiliary IDs associated to the tasks
    * @param      I_TASK_CODIFICATION          Codification IDs associated to the tasks
    * @param      O_ID_GUID_TASK_LINK          New ID of each task
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION set_guideline_task
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_guideline      IN guideline.id_guideline%TYPE,
        i_id_task_link      IN table_varchar,
        i_task_type         IN guideline_task_link.task_type%TYPE,
        i_task_notes        IN table_varchar,
        i_id_task_attach    IN table_number,
        i_task_codification IN table_number,
        o_id_guid_task_link OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get guideline task
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    
    * @param      O_GUIDELINE_TASK             Cursor for guideline tasks
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_task
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        o_guideline_task OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Set guideline context
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
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
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION set_guideline_context
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_guideline       IN guideline.id_guideline%TYPE,
        i_context_desc       IN guideline.context_desc%TYPE,
        i_context_title      IN guideline.context_title%TYPE,
        i_context_ebm        IN guideline.id_guideline_ebm%TYPE,
        i_context_adaptation IN guideline.context_adaptation%TYPE,
        i_context_type_media IN guideline.context_type_media%TYPE,
        --        i_context_author_last_name  IN guideline_context_author.last_name%TYPE,
        --        i_context_author_first_name IN guideline_context_author.first_name%TYPE,
        i_context_editor            IN guideline.context_editor%TYPE,
        i_context_edition_site      IN guideline.context_edition_site%TYPE,
        i_context_edition           IN guideline.context_edition%TYPE,
        i_dt_context_edition        IN guideline.dt_context_edition%TYPE,
        i_context_access            IN guideline.context_access%TYPE,
        i_id_context_language       IN guideline.id_context_language%TYPE,
        i_context_subtitle          IN guideline.context_subtitle%TYPE,
        i_id_context_assoc_language IN guideline.id_context_associated_language%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get guideline context
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_GUIDELINE_CONTEXT          Cursor for guideline context
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/27
    */
    FUNCTION get_guideline_context
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_guideline      IN guideline.id_guideline%TYPE,
        o_guideline_context OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Set guideline context author
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_CONTEXT_AUTHOR_LAST_NAME   Context author last name
    * @param      I_CONTEXT_AUTHOR_FIRST_NAME  Context author first name
    * @param      I_CONTEXT_AUTHOR_TITLE       Context author title
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION set_guideline_context_author
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline              IN guideline.id_guideline%TYPE,
        i_context_author_last_name  IN table_varchar,
        i_context_author_first_name IN table_varchar,
        i_context_author_title      IN table_varchar,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get guideline context author
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_GUIDELINE_CONTEXT_AUTHOR          Cursor for guideline context
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/27
    */
    FUNCTION get_guideline_context_author
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_guideline             IN guideline.id_guideline%TYPE,
        o_guideline_context_author OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Sets a guideline as definitive
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               ID of guideline to set as final
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION set_guideline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_task_type IN guideline_action_category.task_type%TYPE
    ) RETURN VARCHAR2;

    /** 
    *  Verify if the user can make actions (has permissions) to a given task type
    *
    * @param      I_LANG            Preferred language ID for this professional
    * @param      I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE       Task type ID
    *
    * @return     VARCHAR2:        'Y': the user has permissions on this type of task, 'N' the user has no permissions on this type of task
    *
    * @author     Tiago Silva
    * @version    1.0
    * @since      2010/04/27
    */
    FUNCTION check_task_type_permissions
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN guideline_action_category.task_type%TYPE
    ) RETURN VARCHAR2;

    /** 
    *  Check if it is possible to cancel a guideline process
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS       Guideline process ID
    *
    * @return     VARCHAR2:                    'Y': guideline can be canceled, 'N' guideline cannot be canceled
    *
    * @author     Tiago Silva
    * @version    1.0
    * @since      2010/04/27
    */
    FUNCTION check_cancel_guideline_proc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_guideline_process IN guideline_process.id_guideline_process%TYPE
    ) RETURN VARCHAR2;

    /** 
    *  Cancel guideline / mark as deleted
    *
    * @param      I_LANG              Preferred language ID for this professional
    * @param      I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE      ID of guideline.
    * @param      O_ERROR             error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION cancel_guideline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get multichoice for guideline types
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE      ID of guideline.        
    * @param      O_GUIDELINE_TYPE             Cursor with all guideline types
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        o_guideline_type OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get multichoice for environment
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE      ID of guideline.        
    * @param      o_guideline_environment      Cursor with all environment availables
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_environment_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_environment OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Get multichoice for specialty
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE              ID of guideline.
    * @param      O_GUIDELINE_SPECIALTY       Cursor with all specialty available
    
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     SB/TS
    * @version    0.2
    * @since      2007/02/23
    */
    FUNCTION get_guideline_specialty_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_guideline        IN guideline.id_guideline%TYPE,
        o_guideline_specialty OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get multichoice for professional
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE      ID of guideline.        
    * @param      O_GUIDELINE_PROFESSIONAL     Cursor with all professional categories availables
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_guideline_prof_list
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        o_guideline_professional OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get multichoice for professionals that will be able to edit Guidelines
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE      ID of guideline.        
    * @param      O_GUIDELINE_PROFESSIONAL     Cursor with all professional categories availables
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/02/26
    */
    FUNCTION get_guideline_edit_prof_list
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        o_guideline_professional OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get multichoice for types of Guideline recommendation
    *
    * @param      I_LANG                  Preferred language ID for this professional
    * @param      I_PROF                  Object (ID of professional, ID of institution, ID of software)
    * @param      O_GUIDELINE_REC_MODE    Cursor with types of recommendation
    * @param      O_ERROR                 Error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/02/26
    */
    FUNCTION get_guideline_type_rec_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_guideline_type_rec OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get multichoice for EBM
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               ID of guideline.        
    * @param      O_GUIDELINE_EBM              Cursor with all EBM values availables
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/27
    */
    FUNCTION get_guideline_ebm_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_guideline  IN guideline.id_guideline%TYPE,
        o_guideline_ebm OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get multichoice for Gender
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_CRITERIA_TYPE              Criteria Type : I- Incusion E - Exclusion
    * @param      O_GUIDELINE_GENDER           Cursor with all Genders
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/29
    */
    FUNCTION get_gender_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_criteria_type    IN guideline_criteria.criteria_type%TYPE,
        o_guideline_gender OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get multichoice for type of media
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_GUIDELINE_TM               Cursor with all Genders
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/29
    */
    FUNCTION get_type_media_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_guideline_tm OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get multichoice for guideline edit options
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_OPTIONS                    Cursor with all options
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/06/04
    */

    FUNCTION get_guideline_edit_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_options OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get multichoice for languages
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      O_LANGUAGES                  Cursor with all languages
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/29
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
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      O_TITLE                      Title cursor
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION get_prof_title_list
    (
        i_lang  IN language.id_language%TYPE,
        o_title OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get frequency list for guideline tasks
    *
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_FREQ     Frequencies cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/19
    */

    FUNCTION get_guideline_task_freq_list
    (
        i_lang  IN language.id_language%TYPE,
        o_freq  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get status list for allergy criterias
    *
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/24
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
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_REACTS   Reactions cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/24
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
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/24
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
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_NATURES  Natures cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/24
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
    * @param      I_LANG     Preferred language ID for this professional
    * @param      O_STATUS   Status cursor
    * @param      O_ERROR    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/24
    */
    FUNCTION get_nurse_diag_status_list
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
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION get_count_allergies
    (
        i_prof         profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_id_allergy   IN allergy.id_allergy%TYPE,
        i_market       PLS_INTEGER
    ) RETURN NUMBER;

    /** 
    *  Checks difference between number of diagnoses and criteria diagnoses choosen
    *
    * @param      I_ID_GUIDELINE   Guideline ID
    * @param      I_FLG_TYPE       Diagnoses type
    *
    * @return     NUMBER
    * @author     TS
    * @version    0.1
    * @since      2007/11/26
    */
    FUNCTION get_count_diagnoses
    (
        i_id_guideline guideline.id_guideline%TYPE,
        i_diags_type   diagnosis.flg_type%TYPE
    ) RETURN NUMBER;

    /** 
    *  Checks difference between number of nurse diagnosis and criteria nurse diagnosis choosen
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_NURSE_DIAG              Nurse diagnosis ID
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION get_count_nurse_diag
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_guideline  guideline.id_guideline%TYPE,
        i_id_nurse_diag NUMBER
    ) RETURN NUMBER;

    /** 
    *  Checks difference between number of analysis and criteria 
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_SAMPLE_TYPE             Sample type ID
    * @param      I_ID_EXAM_CAT                Exam category
    *
    * @return     NUMBER
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION get_count_analysis_sample
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   guideline.id_guideline%TYPE,
        i_id_sample_type sample_type.id_sample_type%TYPE,
        i_id_exam_cat    exam_cat.id_exam_cat%TYPE
    ) RETURN NUMBER;

    /** 
    *  Search specific criterias
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_CRITERIA_TYPE              Criteria type - 'I'nclusion / 'E'xclusion
    * @param      I_GUIDELINE_CRITERIA_SEARCH  Criteria search topics
    * @param      I_VALUE_SEARCH               Values to search
    * @param      o_flg_show                   shows warning message: Y - yes, N - No
    * @param      o_msg                        message text
    * @param      o_msg_title                  message title
    * @param      o_button                     buttons to show: N-No, R-Read, C-Confirmed
    * @param      O_CRITERIA_SEARCH            Cursor with all elements of specific criteria
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB/TS
    * @version    0.3
    * @since      2007/02/06
    */
    FUNCTION get_criteria_search
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline              IN guideline.id_guideline%TYPE,
        i_criteria_type             IN guideline_criteria.criteria_type%TYPE, -- Inclusion / exclusion
        i_guideline_criteria_search IN table_varchar,
        i_value_search              IN table_varchar,
        o_flg_show                  OUT VARCHAR2,
        o_msg                       OUT VARCHAR2,
        o_msg_title                 OUT VARCHAR2,
        o_button                    OUT VARCHAR2,
        o_criteria_search           OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get criteria types
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE                  Guideline ID        
    * @param      O_CRITERIA_TYPE              cursor with all criteria types
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/23
    */
    FUNCTION get_criteria_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_guideline  IN guideline.id_guideline%TYPE,
        o_criteria_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Obtain all pathologies by search code
    *
    * @param      I_LANG                     Preferred language ID for this professional
    * @param      I_PROF                     object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELI               Guideline ID
    * @param      I_VALUE_CODE               Value with code to search for
    * @param      O_PATHOLOGY_BY_SEARCH      cursor with all pathologies
    * @param      O_ERROR                    error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/08/08
    */
    FUNCTION get_pathology_by_code
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_guideline      IN guideline.id_guideline%TYPE,
        i_value_code        IN VARCHAR2,
        o_pathology_by_code OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Obtain all pathologies by search
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_VALUE                      Value to be searched in database
    * @param      O_PATHOLOGY_BY_SEARCH      cursor with all pathologies
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/06
    */
    FUNCTION get_pathology_by_search
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_guideline        IN guideline.id_guideline%TYPE,
        i_value               IN VARCHAR2,
        o_pathology_by_search OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Obtain all pathologies by group
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_PARENT                  Parent ID
    * @param      I_VALUE                      Value to be searched in database
    * @param      O_PATHOLOGY_BY_GROUP         cursor with all pathologies
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/07/25
    */
    FUNCTION get_pathology_by_group
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_guideline       IN guideline.id_guideline%TYPE,
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
    *  Obtain all guidelines by pathology
    *
    * @param      I_LANG               Preferred language ID for this professional
    * @param      I_PROF               object (ID of professional, ID of institution, ID of software)
    * @param      I_VALUE              Value to search for
    * @param      O_GUIDELINES         cursor with all guidelines classified by type
    * @param      O_ERROR              error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/06
    */
    FUNCTION get_guideline_by_pathology
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_value      IN VARCHAR2,
        o_guidelines OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Clean temp guidelines 
    *
    * @param      I_LANG              Preferred language ID for this professional
    * @param      I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE      ID of guideline.
    * @param      I_DATE_OFFSET       Date with offset in days
    * @param      O_ERROR             error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/27
    */
    FUNCTION clean_guideline_temp
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_date_offset  IN guideline.dt_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Verify if task request is scheduled.
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)  
    * @param      I_TASK_TYPE                  Task Type
    * @param      I_ID_REQUEST                 Request ID of the task
    * @param      O_ERROR                      error
    *
    * @return     VARCHAR2
    * @author     TS
    * @version    0.1
    * @since      2007/06/13
    */
    FUNCTION get_task_request_schedule
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_task_type  IN guideline_process_task.task_type%TYPE,
        i_id_request IN guideline_process_task.id_request%TYPE
    ) RETURN VARCHAR2;

    /** 
    *  Update all guideline processes status (including tasks)
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                Patient ID
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/25
    */
    FUNCTION update_all_guide_proc_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN guideline_process.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get recommended guidelines
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                 Patient ID
    * @param      I_VALUE                      String to search for
    * @param      I_NUM_REG                    Max number of returned results
    * @param      I_SHOW_CANCEL_GUIDES         Show canceled guidelines (Y/N)   
    * @param      DT_SERVER                    Current server time    
    * @param      O_GUIDELINE_RECOMMENDED      Guideline recommended for specific user
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_recommended_guidelines
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN guideline_process.id_patient%TYPE,
        i_value                 IN VARCHAR2,
        i_num_reg               IN NUMBER,
        i_show_cancel_guides    IN VARCHAR2,
        dt_server               OUT VARCHAR2,
        o_guideline_recommended OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Change state of recomended guideline
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS      ID of guideline process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel       
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION set_rec_guideline_status
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_guideline_process IN guideline_process.id_guideline_process%TYPE,
        i_id_action            IN action.id_action%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes         IN VARCHAR2,
        i_transaction_id       IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  cancel recomended guideline
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS      ID of guideline process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel 
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/28
    */
    FUNCTION cancel_rec_guideline
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_guideline_process IN guideline_process.id_guideline_process%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes         IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all frequent guidelines
    *
    * @param      i_lang                      preferred language id for this professional
    * @param      i_prof                      object (id of professional, id of institution, id of software)
    * @param      i_id_patient                patient id
    * @param      i_id_episode                episode id   
    * @param      i_flg_filter                guidelines filter   
    * @param      i_value                     value to search for        
    * @param      o_guideline_frequent        guidelines cursor
    * @param      o_error                     error
    *
    * @value      i_flg_filter                {*} 'C' filtered by chief complaint
    *                                         {*} 'S' filtered by i_prof specialty 
    *                                         {*} 'F' all frequent guidelines
    * 
    * @return     boolean                     true or false on success or error
    *
    * @author     Tiago Silva
    * @since      18-May-2007
    ********************************************************************************************/
    FUNCTION get_guideline_frequent
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN guideline_process.id_patient%TYPE,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_filter         IN VARCHAR2,
        i_value              IN VARCHAR2,
        o_guideline_frequent OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Verify if a guideline task is available for the software, institution and professional
    *
    * @param      I_LANG             Prefered language ID for this professional
    * @param      I_PROF             Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE        Type of the task
    * @param      I_ID_TASK          Task ID
    * @param      I_ID_TASK_ATTACH   Auxiliary ID associated to the task
    * @param      I_TASK_CODIFICATION   Codification ID associated to the task    
    * @param      i_id_episode       ID of the current episode
    *
    * @return     VARCHAR2 (Y - available / N - not available)
    * @author     TS
    * @version    0.2
    * @since      2007/11/05
    */
    FUNCTION get_task_avail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_type         IN guideline_task_link.task_type%TYPE,
        i_id_task           IN guideline_task_link.id_task_link%TYPE,
        i_id_task_attach    IN guideline_task_link.id_task_attach%TYPE,
        i_task_codification IN guideline_task_link.task_codification%TYPE,
        i_id_episode        IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /** 
    *  Get guideline tasks recommended
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS       ID of guideline process
    * @param      i_id_episode                 ID of the current episode
    * @param      DT_SERVER                    Current server time    
    * @param      O_GUIDELINE_RECOMMENDED      Guideline recomended for specific user
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_recommended_tasks
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_guideline_process IN table_number,
        i_id_episode           IN episode.id_episode%TYPE,
        dt_server              OUT VARCHAR2,
        o_task_recommended     OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get guideline tasks recommended details
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_TASK_TYPE                  Task Type
    * @param      I_ID_GUIDELINE_PROCESS_TASK  ID da tarefa
    * @param      I_ID_EPISODE                 Episode ID     
    * @param      O_TASK_REC_DETAIL            Detail information for specific task
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/04/13
    */
    FUNCTION get_rec_task_detail
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_task_type                 IN guideline_process_task.task_type%TYPE,
        i_id_guideline_process_task IN table_number,
        i_id_episode                IN episode.id_episode%TYPE,
        o_task_rec_detail           OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Calculates the next recommendation date for a guideline task
    *
    * @param      I_LANG                       Prefered language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS_TASK  Guideline process task ID
    *
    * @return     boolean
    * @author     TS
    * @version    0.1
    * @since      2007/11/06
    */
    FUNCTION reset_task_frequency
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process_task IN guideline_process_task.id_guideline_process_task%TYPE
    ) RETURN BOOLEAN;

    /** 
    *  Change state of recommended tasks for a guideline
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS_TASK Guideline process ID
    * @param      I_ID_ACTION                 Action ID 
    * @param      I_ID_REQUEST                Request ID
    * @param      I_DT_REQUEST                Date of request
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel   
    * @param      O_ERROR                     error
    *
    * @return     BOOLEAN
    * @author     SB/TS
    * @version    0.2
    * @since      2007/03/29
    */
    FUNCTION set_rec_task_status
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process_task IN table_number,
        i_id_action                 IN table_number,
        i_id_request                IN table_number,
        i_dt_request                IN VARCHAR2,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_cancel_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes              IN VARCHAR2,
        i_transaction_id            IN VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Change state of recommended tasks for a guideline
    *  Flash WRAPPER.DO NOT USE OTHERWISE.
    */
    FUNCTION set_rec_task_status
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process_task IN table_number,
        i_id_action                 IN table_number,
        i_id_request                IN table_number,
        i_dt_request                IN VARCHAR2,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_cancel_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes              IN VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  cancel recomended task for a guideline
    *
    * @param      i_lang                      preferred language id for this professional
    * @param      i_prof                      object (id of professional, id of institution, id of software)
    * @param      i_id_guideline_process_task id of guideline process
    * @param      i_id_episode                episode id
    * @param      i_id_cancel_reason          cancel reason that justifies the task cancel
    * @param      i_cancel_notes              cancel notes (free text) that justifies the task cancel   
    * @param      o_error                     error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/29
    */
    FUNCTION cancel_rec_task
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process_task IN guideline_process_task.id_guideline_process_task%TYPE,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_cancel_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes              IN VARCHAR2,
        i_transaction_id            IN VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /* Flash wrapper for cancel_rec_task.Do not use otherwise */
    FUNCTION cancel_rec_task
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process_task IN guideline_process_task.id_guideline_process_task%TYPE,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_cancel_reason          IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes              IN VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get context info regarding a guideline
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_GUIDELINE_HELP                       Cursor with all help information / context
    * @param      IO_ID                        Application variable
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    */
    FUNCTION get_guideline_help
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        o_guideline_help OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Get history details for  a guideline task
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE_PROCESS       Process ID
    * @param      I_ID_GUIDELINE_PROCESS_TASK  Process task ID    
    * @param      O_GUIDELINE_DETAIL           Cursor with all help information / context
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB/TS
    * @version    0.2
    * @since      2007/02/28
    */
    FUNCTION get_guideline_detail_hst
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_guideline_process      IN guideline_process.id_guideline_process%TYPE,
        i_id_guideline_process_task IN table_number,
        o_guideline_detail          OUT pk_types.cursor_type,
        o_guideline_proc_info       OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Procedure. Call run_batch function. For being called by a job
    *
    * @param      i_lang        Preferred language ID for this professional
    * @param      i_prof        Object (ID of professional, ID of institution, ID of software)
    *
    * @author     TS
    * @version    0.1
    * @since      2007/06/01
    */
    PROCEDURE run_batch_job
    (
        i_lang language.id_language%TYPE,
        i_prof profissional
    );

    /** 
    *  Check if a guideline can be recommended to a patient according its history
    *
    * @param      i_lang        Preferred language ID for this professional
    * @param      i_prof        Object (ID of professional, ID of institution, ID of software)
    * @param      i_id_guideline Guideline ID
    * @param      i_id_patient        Patient ID        
    *
    * @author     TS
    * @version    0.1
    * @since      2007/09/22
    */
    FUNCTION check_history_guideline
    (
        i_id_guideline guideline.id_guideline%TYPE,
        i_id_patient   guideline_process.id_patient%TYPE
    ) RETURN VARCHAR2;

    /** 
    *  Pick up patients for specific guidelines
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                 Patient to apply guideline to
    * @param      I_BATCH_DESC                 Batch Description        
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     Rui Spratley
    * @version    2.5.0.7
    * @since      2009/10/24
    */
    FUNCTION run_batch
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_batch_desc   IN guideline_batch.batch_desc%TYPE,
        i_id_guideline IN guideline.id_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Pick up patients for specific guidelines (internal use only)
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_PATIENT                 Patient to apply guideline to
    * @param      I_BATCH_DESC                 Batch Description        
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_FLG_CREATE_PROCESS         Flag to indicate if the guideline process shall be created
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/02/28
    * @change     2009/10/24 Rui Spratley 2.5.0.7
    */
    FUNCTION run_batch_internal
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_batch_desc         IN guideline_batch.batch_desc%TYPE,
        i_id_guideline       IN guideline.id_guideline%TYPE,
        i_flg_create_process IN BOOLEAN DEFAULT TRUE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Create manual guideline processes
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_EPISODE                 Episode ID
    * @param      I_ID_PATIENT                 Patient ID
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/11
    */
    FUNCTION create_guideline_proc_manual
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN table_number,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /** 
    *  Create guideline process
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_GUIDELINE               Guideline ID
    * @param      I_ID_BATCH                   Batch ID
    * @param      I_ID_EPISODE                 Episode ID
    * @param      I_ID_PATIENT                 Patient ID
    * @param      I_FLG_INIT_STATUS                 Guideline process initial status
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/07
    */
    FUNCTION create_guideline_process
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_guideline    IN guideline.id_guideline%TYPE,
        i_id_batch        IN guideline_batch.id_batch%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_flg_init_status IN guideline_process.flg_status%TYPE,
        o_error           OUT t_error_out
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
    * @since      2007/03/02
    */
    FUNCTION get_imc
    (
        i_id_unit_measure_height IN guideline_criteria.id_height_unit_measure%TYPE,
        i_height                 IN guideline_criteria.min_height%TYPE,
        i_id_unit_measure_weight IN guideline_criteria.id_weight_unit_measure%TYPE,
        i_weight                 IN guideline_criteria.min_weight%TYPE
    ) RETURN NUMBER;

    /** 
    *  Get multichoice for action
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_subject                    Subject of action
    * @param      I_ID_state                   Original state from which we want an action        
    * @param      O_ACTION                     Cursor with all guideline types
    * @param      O_ERROR                      error
    *
    * @return     BOOLEAN
    * @author     SB
    * @version    0.1
    * @since      2007/03/13
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

    -----------------------------------------------------------------------------
    -- Cursor with different criterias    
    -----------------------------------------------------------------------------
    CURSOR c_generic_link
    (
        c_guideline               guideline.id_guideline%TYPE,
        c_guideline_criteria_type guideline_criteria.criteria_type%TYPE
    ) IS
        SELECT --guid_crit.id_guideline_criteria,
        --guid_crit.flg_other_criteria,
         guid_crit_lnk.id_guideline_criteria_link,
         guid_crit_lnk.id_link_other_criteria,
         guid_crit_lnk.id_link_other_criteria_type
          FROM guideline_criteria guid_crit, guideline_criteria_link guid_crit_lnk
         WHERE guid_crit.id_guideline = c_guideline
           AND guid_crit.criteria_type = c_guideline_criteria_type
           AND guid_crit.id_guideline_criteria = guid_crit_lnk.id_guideline_criteria;

    /** 
    *  Get criteria info 
    *
    * @param C_GUIDELINE                     ID of Guideline
    * @param C_GUIDELINE_CRITERIA_TYPE       Criteria Type
    *
    * @return     Type t_coll_guidelines_generic (PIPELINED)
    * @author     SB
    * @version    0.1
    * @since      2007/04/19
    */
    FUNCTION get_other_criteria
    (
        c_guideline               guideline.id_guideline%TYPE,
        c_guideline_criteria_type guideline_criteria.criteria_type%TYPE
    ) RETURN t_coll_guidelines_generic
        PIPELINED;

    -----------------------------------------------------------------------------     

    /**
     * Get Advanced Input for guideline.
     *
     * @param I_LANG                   Preferred language ID for this professional
     * @param I_PROF                   Object (professional ID, institution ID, software ID)
     * @param I_ID_ADVANCED_INPUT      Advanced input ID to be shown
     * @param I_FLG_TYPE               Advanced for (C)riterias or (T)asks
     * @param I_ID_ADVANCED_INPUT_LINK Tasks or Criterias links with to get advanced input data
     * @param O_FIELDS                 Advanced input fields and it's configurations
     * @param O_ERROR                  Error message
     *
     * @return                         true or false on success or error (BOOLEAN)
     * 
     * @author                         SB/TS
     * @version                        0.1
     * @since                          2007/04/19
    */
    FUNCTION get_guideline_advanced_input
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_advanced_input IN advanced_input.id_advanced_input%TYPE,
        i_flg_type          IN guideline_adv_input_value.flg_type%TYPE,
        i_id_adv_input_link IN table_number,
        o_fields            OUT pk_types.cursor_type,
        o_fields_det        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * Get field's value for the Advanced Input of guidelines
     *
     * @param I_LANG                   Preferred language ID for this professional
     * @param I_PROF                   Object (professional ID, institution ID, software ID)
     * @param I_ID_ADVANCED_INPUT      Advanced Input ID
     * @param I_FLG_TYPE               Advanced for (C)riterias or (T)asks
     * @param I_ID_ADV_INPUT_LINK      Tasks or Criterias links to get advanced input data
     *
     * @return                         type t_coll_guidelines_adv_input (PIPELINED)
     * 
     * @author                         SB/TS
     * @version                        0.1
     * @since                          2007/04/19
    */
    FUNCTION get_adv_input_field_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              profissional,
        i_id_advanced_input IN advanced_input.id_advanced_input%TYPE,
        i_flg_type          IN guideline_adv_input_value.flg_type%TYPE,
        i_id_adv_input_link IN table_number
    ) RETURN t_coll_guidelines_adv_input
        PIPELINED;

    /**
     * Set Advanced Input field value for guideline.
     *
     * @param I_LANG                                Preferred language ID for this professional
     * @param I_PROF                                Object (professional ID, institution ID, software ID)
     * @param I_FLG_TYPE                            Advanced for (C)riterias or (T)asks
     * @param I_ID_GUIDELINE_CRITERIA_LINK          Guideline criteria Link ID
     * @param I_VALUE_TYPE                          Value type : D-Date, V-Varchar N-Number
     * @param I_DVALUE                              Date value
     * @param I_NVALUE                              Number value
     * @param I_VVALUE                              Varchar value
     * @param I_VALUE_DESC                          Value description
     * @param I_CRITERIA_VALUE_TYPE                 Criteria Value Type
     * @param I_ID_ADVANCED_INPUT                   Advanced Input ID
     * @param I_ID_ADVANCED_INPUT_FIELD             Advanced Input Field ID        
     * @param O_ERROR                  Error message
     *
     * @return                         true or false on success or error (BOOLEAN)
     * 
     * @author                         SB/TS
     * @version                        0.1
     * @since                          2007/04/20
    **********************************************************************************************/
    FUNCTION set_guideline_adv_input_value
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_adv_input_link           IN guideline_adv_input_value.id_adv_input_link%TYPE,
        i_flg_type                    IN guideline_adv_input_value.flg_type%TYPE,
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

    /** 
    *  Get all recommended guidelines
    *
    * @param      I_LANG                           Preferred language ID for this professional
    * @param      I_PROF                           Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_EPISODE                     Episode ID
    * @param      I_VALUE_PAT_NAME_SEARCH          String to search for patient name
    * @param      I_VALUE_RECOM_GUIDELINES_SEARCH  String to search for recommended guidelines
    * @param      I_VALUE_GUIDELINES_TYPE_SEARCH   Sring to search for guidelines type
    * @param      DT_SERVER                        Current server time    
    * @param      O_GUIDELINE_RECOMMENDED          Recommended guidelines of all users
    * @param      O_ERROR                          error
    *
    * @return     BOOLEAN
    * @author     TS
    * @version    0.1
    * @since      2007/05/2
    */
    FUNCTION get_all_recommended_guidelines
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_value_pat_name_search    IN VARCHAR2,
        i_value_recom_guide_search IN VARCHAR2,
        i_value_guide_type_search  IN VARCHAR2,
        dt_server                  OUT VARCHAR2,
        o_guidelines_recommended   OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all complaints that can be associated to the guidelines
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               guideline id
    * @param      i_value                      search string
    * @param      o_complaints                 cursor with all complaints that can be associated to the guidelines
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   26-Nov-2010
    ********************************************************************************************/
    FUNCTION get_complaint_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        i_value        IN VARCHAR2,
        o_complaints   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set guideline complaints
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               guideline id
    * @param      i_link_complaint             array with complaints
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   29-Nov-2010
    ********************************************************************************************/
    FUNCTION set_guideline_chief_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        i_link_complaint IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all filters for frequent guidelines screen
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_patient                    patient id
    * @param      i_episode                    episode id    
    * @param      o_filters                    cursor with all filters for frequent guidelines screen
    
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   29-Nov-2010
    ********************************************************************************************/
    FUNCTION get_guideline_filters
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_filters OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    --------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------

    g_error           VARCHAR2(2000);
    g_bulk_fetch_rows PLS_INTEGER;

    -- Link types
    g_guide_link_pathol          VARCHAR2(1 CHAR);
    g_guide_link_envi            VARCHAR2(1 CHAR);
    g_guide_link_prof            VARCHAR2(1 CHAR);
    g_guide_link_spec            VARCHAR2(1 CHAR);
    g_guide_link_type            VARCHAR2(1 CHAR);
    g_guide_link_edit_prof       VARCHAR2(1 CHAR);
    g_guide_link_chief_complaint VARCHAR2(1 CHAR);

    -- frequent guideline filter types
    g_guide_filter_chief_compl VARCHAR2(1 CHAR);
    g_guide_filter_specialty   VARCHAR2(1 CHAR);
    g_guide_filter_frequent    VARCHAR2(1 CHAR);

    -- Guideline type
    g_id_guide_type_any NUMBER;

    -- Pathology type
    g_id_guide_pathol_any NUMBER;

    -- Truncate string
    g_trunc_str VARCHAR2(30);

    -- Diagnostics
    g_diag_available  VARCHAR2(1 CHAR);
    g_diag_select     VARCHAR2(1 CHAR);
    g_diag_not_select VARCHAR2(1 CHAR);
    g_diag_freq       VARCHAR2(1 CHAR);
    g_diag_req        VARCHAR2(1 CHAR);
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
    g_separator      VARCHAR2(10);
    g_separator2     VARCHAR2(10);
    g_separator3     VARCHAR2(10);
    g_bullet         VARCHAR2(10);

    g_all_institution      institution.id_institution%TYPE;
    g_all_software         software.id_software%TYPE;
    g_all_profile_template profile_template.id_profile_template%TYPE;
    g_all_markets          market.id_market%TYPE;

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
    -- Gyideline states
    g_guideline_temp       guideline.flg_status%TYPE;
    g_guideline_finished   guideline.flg_status%TYPE;
    g_guideline_deleted    guideline.flg_status%TYPE;
    g_guideline_deprecated guideline.flg_status%TYPE;
    -- Process States
    g_process_pending     guideline_process.flg_status%TYPE;
    g_process_recommended guideline_process.flg_status%TYPE;
    g_process_running     guideline_process.flg_status%TYPE;
    g_process_finished    guideline_process.flg_status%TYPE;
    g_process_suspended   guideline_process.flg_status%TYPE;
    g_process_canceled    guideline_process.flg_status%TYPE;
    g_process_scheduled   guideline_process.flg_status%TYPE;
    g_process_closed      guideline_process.flg_status%TYPE;

    -- Weights of process states
    g_process_running_weight     NUMBER;
    g_process_recommended_weight NUMBER;
    g_process_pending_weight     NUMBER;
    g_process_scheduled_weight   NUMBER;
    g_process_finished_weight    NUMBER;
    g_process_suspended_weight   NUMBER;
    g_process_canceled_weight    NUMBER;
    g_process_closed_weight      NUMBER;

    -- Other criteria types
    g_guideline_diagnosis       guideline_criteria_link.id_link_other_criteria_type%TYPE;
    g_guideline_analysis        guideline_criteria_link.id_link_other_criteria_type%TYPE;
    g_guideline_allergies       guideline_criteria_link.id_link_other_criteria_type%TYPE;
    g_guideline_exams           guideline_criteria_link.id_link_other_criteria_type%TYPE;
    g_guideline_drug            guideline_criteria_link.id_link_other_criteria_type%TYPE;
    g_guideline_other_exams     guideline_criteria_link.id_link_other_criteria_type%TYPE;
    g_guideline_diagnosis_nurse guideline_criteria_link.id_link_other_criteria_type%TYPE;
    -- gender
    g_gender_male   guideline_criteria.gender%TYPE;
    g_gender_female guideline_criteria.gender%TYPE;
    -- Exam types
    g_exam_only_img VARCHAR2(1 CHAR);

    -- TASK TYPE
    g_all_tasks                  NUMBER;
    g_task_analysis              NUMBER; -- Analises
    g_task_appoint               NUMBER; -- Consultas
    g_task_patient_education     NUMBER; -- Patient education
    g_task_img                   NUMBER; -- Imagem: exam
    g_task_vacc                  NUMBER; -- Imunizações: vaccine
    g_task_enfint                NUMBER; -- Intervenções de enfermagem
    g_task_drug                  NUMBER; -- Medicação : drug / tabelas infarmed
    g_task_otherexam             NUMBER; -- Outros exames : exam
    g_task_spec                  NUMBER; -- Pareceres : speciality
    g_task_rast                  NUMBER; -- Rastreios : not done yet
    g_task_drug_ext              NUMBER; -- Medicação exterior
    g_task_proc                  NUMBER; -- Procedimentos
    g_task_fluid                 NUMBER; -- Soros
    g_task_monitorization        NUMBER; -- monitorizacoes
    g_task_specialty_appointment NUMBER; -- consultas de especialidade

    -- CRITERIA
    g_crit_age                   NUMBER; -- idade
    g_crit_weight                NUMBER; -- peso
    g_crit_height                NUMBER; -- altura
    g_crit_imc                   NUMBER; -- IMC (índice de massa corporal)
    g_crit_sistolic_blood_press  NUMBER; -- Pressão arterial sistólica
    g_crit_diastolic_blood_press NUMBER; -- Pressão arterial diastólica

    -- Image status
    g_img_inactive VARCHAR2(1 CHAR);
    g_img_active   VARCHAR2(1 CHAR);

    -- Unit of measure    
    g_task_exec     VARCHAR2(1 CHAR);
    g_task_inform   VARCHAR2(1 CHAR);
    g_task_executed VARCHAR2(1 CHAR);

    -- Unit of measure    
    g_imc_weight_default_um     PLS_INTEGER;
    g_imc_height_default_um     PLS_INTEGER;
    g_blood_pressure_default_um PLS_INTEGER;

    -- Vital sign criterias
    g_weight_measure           PLS_INTEGER;
    g_height_measure           PLS_INTEGER;
    g_blood_pressure_s_measure PLS_INTEGER;
    g_blood_pressure_d_measure PLS_INTEGER;
    g_min_blood_pressure_s     PLS_INTEGER;
    g_max_blood_pressure_s     PLS_INTEGER;
    g_min_blood_pressure_d     PLS_INTEGER;
    g_max_blood_pressure_d     PLS_INTEGER;
    g_blood_pressure_measure   PLS_INTEGER;

    -- Active states for measures
    g_patient_active VARCHAR2(1 CHAR);
    g_measure_active VARCHAR2(1 CHAR);
    -- Min and max biometric values
    g_max_age    NUMBER;
    g_min_age    NUMBER;
    g_min_height NUMBER;
    g_max_height NUMBER;
    g_min_weight NUMBER;
    g_max_weight NUMBER;
    g_min_imc    NUMBER;
    g_max_imc    NUMBER;

    -- Batch types
    g_batch_all   VARCHAR2(1 CHAR); -- all guidelines / all patients
    g_batch_1p_ag VARCHAR2(1 CHAR); -- one user /all guidelines
    g_batch_1p_1g VARCHAR2(1 CHAR); -- one user /one guidelines
    g_batch_ap_1g VARCHAR2(1 CHAR); -- all users /one guidelines

    -- Process status
    g_process_active   VARCHAR2(1 CHAR);
    g_process_inactive VARCHAR2(1 CHAR);

    -- Pat Allergy flg_status
    g_allergy_active  VARCHAR2(1 CHAR);
    g_allergy_passive VARCHAR2(1 CHAR);

    -- Nurse diagnosis flg_status
    g_nurse_active VARCHAR2(1 CHAR);
    g_nurse_solved VARCHAR2(1 CHAR);

    -- Cancel flag
    g_cancelled     VARCHAR2(1 CHAR);
    g_not_cancelled VARCHAR2(1 CHAR);

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

    -- Tasks and guidelines action domais
    g_guideline_actions VARCHAR2(50);
    g_task_actions      VARCHAR2(50);

    g_domain_flg_guideline      sys_domain.code_domain%TYPE;
    g_domain_flg_guideline_task sys_domain.code_domain%TYPE;
    g_domain_task_type          sys_domain.code_domain%TYPE;
    g_domain_flg_type_rec       sys_domain.code_domain%TYPE;

    g_unknown_link_type   VARCHAR2(50);
    g_unknown_detail_type VARCHAR2(50);

    -- Domains
    g_domain_gender              sys_domain.code_domain%TYPE;
    g_domain_type_media          sys_domain.code_domain%TYPE;
    g_domain_inc_gen             sys_domain.code_domain%TYPE;
    g_domain_exc_gen             sys_domain.code_domain%TYPE;
    g_domain_language            sys_domain.code_domain%TYPE;
    g_domain_professional_title  sys_domain.code_domain%TYPE;
    g_sch                        VARCHAR2(50);
    g_cipe                       VARCHAR2(50);
    g_alert_icon                 VARCHAR2(100);
    g_waiting_icon               VARCHAR2(100);
    g_domain_adv_input_freq      sys_domain.code_domain%TYPE;
    g_domain_allergy_type        sys_domain.code_domain%TYPE;
    g_domain_allergy_status      sys_domain.code_domain%TYPE;
    g_domain_diagnosis_status    sys_domain.code_domain%TYPE;
    g_domain_diagnosis_nature    sys_domain.code_domain%TYPE;
    g_domain_nurse_diag_status   sys_domain.code_domain%TYPE;
    g_domain_adv_input_flg_type  sys_domain.code_domain%TYPE;
    g_domain_guideline_item_type sys_domain.code_domain%TYPE;
    g_domain_take                sys_domain.code_domain%TYPE;
    g_domain_time                sys_domain.code_domain%TYPE;
    g_domain_status              sys_domain.code_domain%TYPE;
    g_presc_flg_type             sys_domain.code_domain%TYPE;

    -- Drug external
    g_yes VARCHAR2(1 CHAR);
    g_no  VARCHAR2(1 CHAR);

    -- Local drug 
    g_drug             VARCHAR2(1 CHAR);
    g_det_req          VARCHAR2(1 CHAR);
    g_det_pend         VARCHAR2(1 CHAR);
    g_det_exe          VARCHAR2(1 CHAR);
    g_drug_presc_det_a VARCHAR2(1 CHAR);
    g_flg_time_epis    VARCHAR2(1 CHAR);
    g_flg_freq         VARCHAR2(1 CHAR);

    -- Cancel recommendations
    g_close_task             VARCHAR2(1 CHAR);
    g_cancel_task            VARCHAR2(1 CHAR);
    g_cancel_guideline       VARCHAR2(1 CHAR);
    g_state_cancel_operation NUMBER;

    -- Advanced Input configurations
    g_adv_input_type_tasks     guideline_adv_input_value.flg_type%TYPE;
    g_adv_input_type_criterias guideline_adv_input_value.flg_type%TYPE;

    -- Criteria Value
    g_guideline_d_type VARCHAR2(1 CHAR);
    g_guideline_n_type VARCHAR2(1 CHAR);
    g_guideline_v_type VARCHAR2(1 CHAR);

    -- Keypad Date 
    g_date_keypad advanced_input_field.type%TYPE;

    -- BOOLEAN values
    g_true  VARCHAR2(1 CHAR);
    g_false VARCHAR2(1 CHAR);

    -- Edit Guideline options
    g_message_edit_guideline      sys_message.code_message%TYPE;
    g_message_create_guideline    sys_message.code_message%TYPE;
    g_message_duplicate_guideline sys_message.code_message%TYPE;
    g_edit_guideline_option       VARCHAR2(1 CHAR);
    g_create_guideline_option     VARCHAR2(1 CHAR);
    g_duplicate_guideline_option  VARCHAR2(1 CHAR);

    -- Guideline edit options
    g_guideline_editable   VARCHAR2(1 CHAR);
    g_guideline_duplicable VARCHAR2(1 CHAR);
    g_guideline_viewable   VARCHAR2(1 CHAR);

    g_message_any       sys_message.code_message%TYPE;
    g_message_scheduled sys_message.code_message%TYPE;

    -- Guideline type recommendation
    g_default_type_rec   guideline.flg_type_recommendation%TYPE;
    g_type_rec_manual    guideline.flg_type_recommendation%TYPE;
    g_type_rec_automatic guideline.flg_type_recommendation%TYPE;

    -- Process task details type
    g_proc_task_det_freq     guideline_process_task_det.flg_detail_type%TYPE;
    g_proc_task_det_next_rec guideline_process_task_det.flg_detail_type%TYPE;

    -- Advanced input field ID
    g_frequency_field              NUMBER;
    g_allergy_status_field         NUMBER;
    g_allergy_react_field          NUMBER;
    g_diagnosis_status_field       NUMBER;
    g_diagnosis_nature_field       NUMBER;
    g_nurse_diagnosis_status_field NUMBER;

    -- Type of patient problems
    g_pat_probl_not_capable VARCHAR(1);

    -- Appointments specialties
    g_prof_active             VARCHAR2(1 CHAR);
    g_external_appoint        VARCHAR2(1 CHAR);
    g_message_spec_appoint    sys_message.code_message%TYPE;
    g_message_foll_up_appoint sys_message.code_message%TYPE;

    -- Error message
    g_message_error sys_message.code_message%TYPE;

    -- All message
    g_message_all sys_message.code_message%TYPE;

    -- NOTES message
    g_message_notes sys_message.code_message%TYPE;

    -- Opinion message
    g_message_opinion_any_prof sys_message.code_message%TYPE;

    -- NA message
    g_message_na sys_message.code_message%TYPE;

    -- CONFIGS in SYS_CONFIG
    g_config_func_consult_req sys_config.id_sys_config%TYPE;

    g_config_func_opinion    sys_config.id_sys_config%TYPE;
    g_config_max_diag_rownum sys_config.id_sys_config%TYPE;

    -- Action subjects
    g_action_guideline_tasks action.subject%TYPE;

    -- Icon colors
    g_green_color VARCHAR2(1 CHAR);
    g_red_color   VARCHAR2(1 CHAR);

    -- State symbols
    g_icon      VARCHAR2(5);
    g_text_icon VARCHAR2(5);
    g_text      VARCHAR2(5);
    g_date      VARCHAR2(5);

    -- Type guideline items
    g_guideline_item_tasks    guideline_item_soft_inst.flg_item_type%TYPE;
    g_guideline_item_criteria guideline_item_soft_inst.flg_item_type%TYPE;

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

    -- Predefined guideline authors
    g_message_guideline_authors sys_message.code_message%TYPE;

    -- Any criteria detail value
    g_detail_any NUMBER;

    -- Pregnancy process
    g_pregnancy_process_active pat_pregnancy.flg_status%TYPE;

    -- log mechanism
    g_log_object_owner VARCHAR2(50);
    g_log_object_name  VARCHAR2(50);

    -- Shortcut for guidelines
    g_guideline_shortcut sys_shortcut.id_sys_shortcut%TYPE;

    -- Exception for dml errors
    dml_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(dml_errors, -24381);

END pk_guidelines;
/
