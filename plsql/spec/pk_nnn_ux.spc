/*-- Last Change Revision: $Rev: 1658137 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:21:37 +0000 (seg, 10 nov 2014) $*/

CREATE OR REPLACE PACKAGE pk_nnn_ux IS

    -- Author  : ARIEL.MACHADO
    -- Created : 9/27/2013 2:34:04 PM
    -- Purpose : NANDA NIC NOC Classifications : Methods for UX

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Gets a list of NANDA Domains according with active NANDA diagnoses for a given institution.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    o_data              Ref-Cursor with collection of NANDA Domains
    * @param    o_error             Error info
    *
    * @return   True or False on success or error
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    10/30/2013
    */
    FUNCTION get_nan_domains
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a list of NANDA Classes that belong to a NANDA Domain according with active NANDA diagnoses for a given institution.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_nan_domain        NANDA Domain ID
    * @param    o_data              Ref-Cursor with collection of NANDA Classes    
    * @param    o_error             Error info
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    10/30/2013
    */
    FUNCTION get_nan_classes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_nan_domain IN nan_class.id_nan_domain%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a list of active NANDA Diagnoses that belong to a NANDA Class for a given institution.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)        
    * @param    i_nan_class         NANDA Class ID
    * @param    i_paging            Use paging ('Y' Yes; 'N' No)
    * @param    i_startindex        The index of the first item. startIndex is 1-based
    * @param    i_items_per_page    The number of items per page
    * @param    o_data              Collection of NANDA Diagnosis
    * @param    o_total_items       The total number of NANDA Diagnosis available
    * @param    o_error             Error info
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    10/30/2013
    */
    FUNCTION get_nan_diagnoses
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_nan_class      IN nan_diagnosis.id_nan_class%TYPE,
        i_paging         IN VARCHAR2,
        i_startindex     IN NUMBER,
        i_items_per_page IN NUMBER,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets information about a NANDA Diagnosis
    *
    * @param    i_lang             Language ID  
    * @param    i_prof             Professional identification and its context (institution and software)    
    * @param    i_nan_diagnosis    NANDA Diagnosis ID
    * @param    o_title            Content help title    
    * @param    o_content_help     Content help about NANDA Diagnosis in HTML format
    * @param    o_error            Error information
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    6/25/2014
    */
    FUNCTION get_nan_diagnosis_info
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        o_title         OUT VARCHAR2,
        o_content_help  OUT CLOB,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a list of Defined Characteristics for a given NANDA Diagnosis.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_nan_diagnosis     NANDA Diagnosis ID
    * @param    i_paging            Use paging ('Y' Yes; 'N' No)
    * @param    i_startindex        When paging enabled, the index of the first item. startIndex is 1-based
    * @param    i_items_per_page    When paging enabled, the number of items per page 
    * @param    o_data              Cursor with list of defined characteristics    
    * @param    o_total_items       The total number of NANDA Defined Characteristics available    
    * @param    o_error             Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    9/27/2013
    */
    FUNCTION get_defined_characteristics
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2,
        i_startindex     IN NUMBER,
        i_items_per_page IN NUMBER,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a list of Related Factors for a given NANDA Diagnosis.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_nan_diagnosis     NANDA Diagnosis ID
    * @param    i_paging            Use paging ('Y' Yes; 'N' No)
    * @param    i_startindex        When paging enabled, the index of the first item. startIndex is 1-based
    * @param    i_items_per_page    When paging enabled, the number of items per page 
    * @param    o_data              Cursor with list of related factors
    * @param    o_total_items       The total number of NANDA Related Factors available        
    * @param    o_error             Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    9/30/2013
    */
    FUNCTION get_related_factors
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2,
        i_startindex     IN NUMBER,
        i_items_per_page IN NUMBER,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a list of Risk Factors for a given NANDA Diagnosis.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_nan_diagnosis     NANDA Diagnosis ID
    * @param    i_paging            Use paging ('Y' Yes; 'N' No)
    * @param    i_startindex        When paging enabled, the index of the first item. startIndex is 1-based
    * @param    i_items_per_page    When paging enabled, the number of items per page 
    * @param    o_data              Cursor with list of risk factors
    * @param    o_total_items       The total number of NANDA Risk Factors available        
    * @param    o_error             Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    9/30/2013
    */
    FUNCTION get_risk_factors
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2,
        i_startindex     IN NUMBER,
        i_items_per_page IN NUMBER,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a list of active NOC Outcomes that can be linked to a NANDA Diagnosis for a given institution.
    *    
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)        
    * @param    i_nan_diagnosis     NANDA Diagnosis ID
    * @param    o_data              Collection of NOC Outcomes
    * @param    o_error             Error info     
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   4/14/2014
    */
    FUNCTION get_noc_outcomes
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets information about a NOC Outcome
    *
    * @param    i_lang           Language ID  
    * @param    i_prof           Professional identification and its context (institution and software)
    * @param    i_noc_outcome    NOC Outcome ID
    * @param    o_title          Content help title    
    * @param    o_content_help   Content help about NOC Outcome in HTML format
    * @param    o_error          Error information
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    6/25/2014
    */
    FUNCTION get_noc_outcome_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_noc_outcome  IN noc_outcome.id_noc_outcome%TYPE,
        o_title        OUT VARCHAR2,
        o_content_help OUT CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a list of active NOC Indicators that can be linked to a NOC Outcoem for a given institution.
    *    
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)        
    * @param    i_noc_outcome       NOC Outcome ID
    * @param    o_data              Collection of NOC Indicators
    * @param    o_error             Error info     
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   4/14/2014
    */
    FUNCTION get_noc_indicators
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_noc_outcome IN noc_outcome.id_noc_outcome %TYPE,
        o_data        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the information of a given NOC Likert scale used in Outcomes and Indicators to measure patient status
    *    
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)             
    * @param    i_noc_scale         NOC Scale ID
    * @param    i_flg_option_none   Show option "None"? 
    * @param    o_scale_info        The name and scale code of one NOC Scale ID
    * @param    o_scale_levels      Collection of levels scale of one NOC Scale ID
    * @param    o_error             Error info
    *
    * @value    i_flg_option_none {*} pk_alert_constant.g_yes {*} pk_alert_constant.g_no
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   5/13/2014
    */
    FUNCTION get_noc_scale
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_noc_scale       IN noc_scale.id_noc_scale%TYPE,
        i_flg_option_none IN VARCHAR,
        o_scale_info      OUT pk_types.cursor_type,
        o_scale_levels    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a list of active NIC Interventions that can be linked to a NANDA Diagnosis and, if defined, to a NOC Outcome for a given institution.
    *    
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)        
    * @param    i_nan_diagnosis     NIC Intervention ID
    * @param    i_noc_outcome       NANDA Diagnosis ID. Defined to use NNN-Linkages, or NULL to use NANDA/NIC-Linkages
    * @param    o_data              Collection of NIC Activities
    * @param    o_error             Error info     
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   6/13/2014
    */
    FUNCTION get_nic_interventions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_noc_outcome   IN noc_outcome.id_noc_outcome%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets information about a NIC Intervention
    *
    * @param    i_lang                Language ID  
    * @param    i_prof                Professional identification and its context (institution and software)
    * @param    i_nic_intervention    NOC Outcome ID
    * @param    o_title               Content help title    
    * @param    o_content_help        Content help about NIC Intervention in HTML format
    * @param    o_error               Error information
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    6/25/2014
    */
    FUNCTION get_nic_intervention_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        o_title            OUT VARCHAR2,
        o_content_help     OUT CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a list of active NIC Activities that can be linked to a NIC Intervention for a given institution.     
    *    
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)        
    * @param    i_nic_intervention  NIC Intervention ID
    * @param    o_data              Collection of NIC Activities
    * @param    o_error             Error info     
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   6/13/2014
    */
    FUNCTION get_nic_activities
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        o_data             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the available PRN options.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    o_list                         Cursor with a list of available PRN options
    * @param    o_error                        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/12/2013    
    */
    FUNCTION get_prn_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the available execution time options.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    o_list                         Cursor with a list of available execution time options
    * @param    o_error                        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/12/2013    
    */
    FUNCTION get_time_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_time  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the available priority options.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    o_list                         Cursor with a list of available priority options
    * @param    o_error                        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   5/27/2014
    */
    FUNCTION get_priority_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the available status for a NANDA diagnosis.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    o_list                         List of diagnosis status: (a)ctive, (i)nactive, (r)esolved
    * @param    o_error                        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   2/7/2014
    */
    FUNCTION get_diag_eval_status_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Gets a string that describes the instructions of an NNN Outcome/Indicator/Activity request.
    *    
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_flg_priority                 Flag that indicates the priority of a task: (N)ormal, (U)rgent, (E)mergent
    * @param    i_flg_prn                      Flag that indicates wether the task is PRN or not
    * @param    i_notes_prn                    Notes to indicate when a PRN order should be activated
    * @param    i_flg_time                     Execution time to evaluate the task: In current (E)pisode, (B)etween episodes, (N)ext episode. 
    * @param    i_order_recurr_plan            Order recurrence plan ID for defined frequency in the instructions             
    * @param    o_instructions                 The instructions in a formatted string
    * @param    o_error                        Error information
    * 
    * @return  True or False on success or error
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    6/2/2014
    */
    FUNCTION get_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_priority      IN nnn_epis_activity.flg_priority%TYPE,
        i_flg_prn           IN nnn_epis_activity.flg_prn%TYPE,
        i_notes_prn         IN CLOB,
        i_flg_time          IN nnn_epis_activity.flg_time%TYPE,
        i_order_recurr_plan IN nnn_epis_activity.id_order_recurr_plan%TYPE,
        o_instructions      OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the patient's nursing care plan.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_episode           Episode ID
    * @param    o_diagnosis         Cursor with list of Nursing Diagnoses
    * @param    o_outcome           Cursor with list of Nursing Outcomes
    * @param    o_indicator         Cursor with list of Nursing Indicators 
    * @param    o_intervention      Cursor with list of Nursing Interventions
    * @param    o_activity          Cursor with list of Nursing Activities
    * @param    o_error             Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   10/4/2013
    */
    FUNCTION get_pat_nursing_careplan
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_diagnosis    OUT pk_types.cursor_type,
        o_outcome      OUT pk_types.cursor_type,
        o_indicator    OUT pk_types.cursor_type,
        o_intervention OUT pk_types.cursor_type,
        o_activity     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets an evaluations view of the patient's nursing care plan. 
    * The output is intended to be visualized in a timeline view (rows and columns).
    *
    * Notice #columns <> #records. May exists several evaluations performed on the same date, and therefore, belong to the same column.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_episode           Episode ID
    * @param    i_paging            Use paging
    * @param    i_start_column      First column. Just considered when paging is used.
    * @param    i_num_columns       Number of columns (distinct evaluation's time) to be retrieved. Just considered when paging is used.
    * @param    o_rows              Cursor with list of items in the care plan
    * @param    o_cols              Cursor with list of evaluations for each item. 
    * @param    o_error             Error information
    *
    * @value    i_paging {*} pk_alert_constant.g_yes {*} pk_alert_constant.g_no
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   02/05/2014
    */
    FUNCTION get_pat_evaluations_view
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_paging       IN VARCHAR2,
        i_start_column IN NUMBER,
        i_num_columns  IN NUMBER,
        o_rows         OUT pk_types.cursor_type,
        o_cols         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets a plan view of the patient's nursing care plan. 
    * The output is intended to be visualized in a timeline view (rows and columns).
    *
    * Notice #columns <> #records. May exists several evaluations performed on the same date, and therefore, belong to the same column.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_episode           Episode ID
    * @param    i_paging            Use paging
    * @param    i_start_column      First column. Just considered when paging is used.
    * @param    i_num_columns       Number of columns (distinct evaluation's time) to be retrieved. Just considered when paging is used.
    * @param    o_rows              Cursor with list of items in the care plan
    * @param    o_cols              Cursor with list of evaluations for each item. 
    * @param    o_error             Error information
    *
    * @value    i_paging {*} pk_alert_constant.g_yes {*} pk_alert_constant.g_no
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   02/05/2014
    */
    FUNCTION get_pat_plan_view
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_paging       IN VARCHAR2,
        i_start_column IN NUMBER,
        i_num_columns  IN NUMBER,
        o_rows         OUT pk_types.cursor_type,
        o_cols         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the patient's nursing diagnoses that are with unresolved status (active, inactive).
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_episode           Episode ID
    * @param    o_diagnosis         Cursor with list of unresolved Nursing Diagnoses
    * @param    o_error             Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   4/16/2014
    */
    FUNCTION get_pat_unresolved_diagnosis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the patient's nursing outcomes linked to diagnoses that are with unresolved status (active, inactive).
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_episode           Episode ID
    * @param    o_outcome           Cursor with list of Nursing Outcomes
    * @param    o_error             Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   6/13/2014
    */
    FUNCTION get_pat_unresolved_outcome
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_outcome OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Checks if a NANDA Diagnosis already exists in the patient's nursing care plan.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID
    * @param    i_episode                      Episode ID
    * @param    i_nan_diagnosis                NANDA diagnosis ID
    * @param    o_exists                       There exists the NANDA Diagnosis
    * @param    o_error                        Error information
    *
    * @value    o_exists {*} (Y) The NANDA diagnosis is already defined in the in the patient's nursing care plan {*} (N) The NANDA diagnosis does not exist in the patient's nursing care plan
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   11/04/2013
    */
    FUNCTION check_epis_nan_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_nan_diagnosis IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE,
        o_exists        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the institution's standard nursing care plans.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    o_sncp                         Cursor with list of Nursing Care Plans defined by tyhs institution
    * @param    o_error                        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   10/4/2013
    */
    FUNCTION get_inst_nursing_careplans
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_sncp  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets list of available actions, from a given state. When specifying more than one state,
    * it groups the actions, according to their availability. This enables support
    * for "bulk" state changes.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_subject           Action subject
    * @param    i_lst_from_state    List of selected states
    * @param    i_lst_entries       List of selected entries
    * @param    o_actions           Cursor with a list of available actions
    * @param    o_error             Error information        
    *
    * @return   True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   12/18/2013
    */
    FUNCTION get_actions_permissions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_subject        IN action.subject%TYPE,
        i_lst_from_state IN table_varchar,
        i_lst_entries    IN table_number,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the list of available actions for the Staging Area acording with the selected item.
    * This procedures evaluates whether the "Link" action should be active or not in accordance with the selected item 
    * and if there are potential linkable items in the staging area.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_subject           Action subject
    * @param    i_staging_data      JSON Document(plain text) with the information of the selected item and the others what are in the staging area
    * @param    o_actions           Cursor with a list of available actions
    * @param    o_error             Error information            
    *
    * @return   True or False on success or error
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   2/17/2014
    */
    FUNCTION get_actions_staging_area
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_subject      IN action.subject%TYPE,
        i_staging_data IN CLOB,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets the list of available actions for the "Add button"(+) of the Patient Care Plan.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    o_actions           Cursor with a list of available actions
    * @param    o_error             Error information            
    *
    * @return   True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   4/2/2014
    */
    FUNCTION get_actions_add_button
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the filter options for list NIC Interventions when we want to add them to a nursing care plan.
    *
    * There are two ways for list NIC Interventions:
    *    - Using as input a NANDA Diagnosis, thereby listing the Interventions associated with it (NANDA/NIC Linkages)
    *    - Using as input a NOC Outcome, in turn, is linked to a NANDA Diagnosis, thereby listing the Interventions associated with this tuple (NANDA/NOC/NIC Linkages) 
    * This function returns these options evaluating if the nursing care plan already has NOC Outcomes in order to displays the second one as active.
    *   
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_episode           Episode ID
    * @param    o_diagnosis         Cursor with list of Nursing Diagnoses    
    * @param    o_error             Error information            
    *
    * @return   True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   6/13/2014
    */
    FUNCTION get_nic_filter_dropdown
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_dropdown OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates and returns a recurrence plan with default instructions for each NOC Outcome, NOC Indicator and NIC Activity.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_lst_outcome                  List of NOC Outcomes
    * @param    i_lst_indicator                List of NOC Indicators
    * @param    i_lst_activity                 List of NIC Activities
    * @param    o_default_outcome_instruct     Default instructions for NOC Outcomes 
    * @param    o_default_indicator_instruct   Default instructions for NOC Indicators
    * @param    o_default_activity_instruct    Default instructions for NIC Activities
    * @param    o_error             Error information    
    *
    * @return   True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   4/30/2014
    */
    FUNCTION create_default_instructions
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_lst_outcome                IN table_number,
        i_lst_indicator              IN table_number,
        i_lst_activity               IN table_number,
        o_default_outcome_instruct   OUT pk_types.cursor_type,
        o_default_indicator_instruct OUT pk_types.cursor_type,
        o_default_activity_instruct  OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Creates or updates a nursing patient's plan of care with NANDA, NOC and NIC content.
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_patient           Patient ID
    * @param    i_episode           Episode ID
    * @param    i_jsn_careplan      Care plan content in JSON
    * @param    o_error             Error information    
    *
    * @return   True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   12/18/2013
    */
    FUNCTION create_care_plan
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_jsn_careplan IN CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info detail about a NANDA Diagnosis included in a patient's nursing care plan.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diagnosis   Careplan's NANDA Diagnosis ID
    * @param    i_flg_detail_type      Type of information to obtain from methods of detail
    * @param    o_detail               The details of the selected NANDA diagnosis
    * @param    o_error                Error information
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/21/2014
    */
    FUNCTION get_epis_nan_diagnosis_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        i_flg_detail_type    IN VARCHAR2,
        o_detail             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info detail about a NANDA Diagnosis evaluation.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diag_eval   Careplan's NANDA Diagnosis Evaluation ID
    * @param    i_flg_detail_type      Type of information to obtain from methods of detail
    * @param    o_detail               The details of the selected NANDA diagnosis evaluation
    * @param    o_error                Error information    
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/18/2014
    */
    FUNCTION get_epis_nan_diagnosis_evl_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        i_flg_detail_type    IN VARCHAR2,
        o_detail             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info detail about a NOC Outcome included in a patient's nursing care plan.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome     Careplan's NOC Outcome ID
    * @param    i_flg_detail_type      Type of information to obtain from methods of detail
    * @param    o_detail               The details of the selected NOC outcome
    * @param    o_error                Error information
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/28/2014
    */
    FUNCTION get_epis_noc_outcome_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_flg_detail_type  IN VARCHAR2,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info detail about a NOC Outcome evaluation
    *
    * @param    i_lang                      Professional preferred language
    * @param    i_prof                      Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome_eval     Careplan's NOC Outcome Evaluation ID
    * @param    i_flg_detail_type           Type of information to obtain from methods of detail
    * @param    o_detail                    The details of the selected NOC outcome evaluation
    * @param    o_error                     Error information    
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/27/2014
    */
    FUNCTION get_epis_noc_outcome_eval_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        i_flg_detail_type       IN VARCHAR2,
        o_detail                OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info detail about a NOC Indicator included in a patient's nursing care plan.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_indicator   Careplan's NOC Indicator ID
    * @param    i_flg_detail_type      Type of information to obtain from methods of detail
    * @param    o_detail               The details of the selected NOC indicator
    * @param    o_error                Error information
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/28/2014
    */
    FUNCTION get_epis_noc_indicator_det
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_flg_detail_type    IN VARCHAR2,
        o_detail             OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info detail about a NOC Indicator evaluation
    *
    * @param    i_lang                      Professional preferred language
    * @param    i_prof                      Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome          Associated Careplan's Outcome ID (the scale descriptions depends on associated Outcome)
    * @param    i_nnn_epis_ind_eval         Careplan's Indicator Evaluation ID
    * @param    i_flg_detail_type           Type of information to obtain from methods of detail
    * @param    o_detail                    The details of the selected NOC indicator evaluation
    * @param    o_error                     Error information
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @return   True or False on success or error
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/17/2014
    */
    FUNCTION get_epis_noc_indicator_evl_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        i_flg_detail_type   IN VARCHAR2,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info detail about a NIC Intervention included in a patient's nursing care plan.
    *
    * @param    i_lang                    Professional preferred language
    * @param    i_prof                    Professional identification and its context (institution and software)
    * @param    i_nnn_epis_intervention   Careplan's NIC Intervention ID
    * @param    i_flg_detail_type         Type of information to obtain from methods of detail
    * @param    o_detail                  The details of the selected NIC intervention
    * @param    o_error                   Error information
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/28/2014
    */
    FUNCTION get_epis_nic_intervention_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_flg_detail_type       IN VARCHAR2,
        o_detail                OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info detail about a NIC Activity included in a patient's nursing care plan.
    *
    * @param    i_lang                    Professional preferred language
    * @param    i_prof                    Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity       Careplan's NIC Activity ID
    * @param    i_flg_detail_type         Type of information to obtain from methods of detail
    * @param    o_detail                  The details of the selected NIC activity
    * @param    o_error                   Error information
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/28/2014
    */
    FUNCTION get_epis_nic_activity_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_flg_detail_type   IN VARCHAR2,
        o_detail            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info detail about a NIC Activity execution in a patient's nursing care plan.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity_det    Careplan's NIC Activity execution ID
    * @param    i_flg_detail_type          Type of information to obtain from methods of detail
    * @param    o_detail                   The details of the selected NIC activity
    * @param    o_error                    Error information
    *
    * @value    i_flg_detail_type {*} pk_nnn_core.g_detail_type_current_info {*} pk_nnn_core.g_detail_type_history_changes
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    10/15/2014
    */
    FUNCTION get_epis_nic_activity_det_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_activity_det IN nnn_epis_activity_det.id_nnn_epis_activity_det%TYPE,
        i_flg_detail_type       IN VARCHAR2,
        o_detail                OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Gets info about a NANDA Diagnosis included in a patient's nursing care plan.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diagnosis   Careplan's NANDA Diagnosis ID
    * @param    o_diagnosis            The details of the selected NANDA diagnosis
    * @param    o_error                Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    2/21/2014
    */
    FUNCTION get_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        o_diagnosis          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates a NANDA Diagnosis in a patient's nursing care plan.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nan_diagnosis         NANDA diagnosis ID
    * @param    i_nnn_epis_diagnosis    Careplan's NANDA Diagnosis ID
    * @param    i_dt_diagnosis          Diagnosis date    
    * @param    i_notes                 Notes
    * @param    i_flg_req_status        Request status
    * @param    o_nnn_epis_diagnosis    Returns the updated Careplan's NANDA Diagnosis ID
    * @param    o_error                 Error information    
    *
    * @value    i_flg_req_status {*} pk_nnn_constant.g_req_status_ordered {*} pk_nnn_constant.g_req_status_draft
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    2/21/2014
    */
    FUNCTION set_diagnosis_update
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nan_diagnosis      IN nnn_epis_diagnosis.id_nan_diagnosis%TYPE,
        i_dt_diagnosis       IN VARCHAR2,
        i_nnn_epis_diagnosis IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        i_notes              IN nnn_epis_diagnosis.edited_diagnosis_name%TYPE,
        i_flg_req_status     IN nnn_epis_diagnosis.flg_req_status%TYPE,
        o_nnn_epis_diagnosis OUT nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a set of NANDA Diagnosis and all associated NOC Outcomes and NIC Interventions that are not being shared with other diagnoses.
    *
    * @param    i_lang                  Professional preferred language    
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_lst_epis_diag         Collection of diagnoses identifiers that we want to cancel
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    o_error                 Error information    
    *
    * @return   True or False on success or error
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    FUNCTION set_diagnosis_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_lst_epis_diag IN table_number,
        i_cancel_reason IN nnn_epis_diagnosis.id_cancel_reason%TYPE,
        i_cancel_notes  IN nnn_epis_diagnosis.cancel_notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates or updates an evaluation of NANDA Nursing Diagnosis in a patient's nursing care plan.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_diagnosis    Careplan's NANDA Diagnosis ID 
    * @param    i_nnn_epis_diag_eval    Careplan's NANDA Diagnosis Evaluation ID. Declared to update an existing evaluation or NULL to create a new one
    * @param    i_flg_status            Diagnosis status
    * @param    i_dt_evaluation         Evaluation date 
    * @param    i_notes                 Notes
    * @param    i_lst_nan_relf          List of Related Factors for the NANDA nursing diagnosis
    * @param    i_lst_nan_riskf         List of Risk Factors for the NANDA nursing diagnosis
    * @param    i_lst_nan_defc          List of Defined characteristics for the NANDA nursing diagnosis
    * @param    o_nnn_epis_diag_eval    Returns the created or updated Careplan's NANDA Diagnosis Evaluation ID
    * @param    o_error                 Error information    
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/3/2014
    */
    FUNCTION set_diagnosis_evaluate
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diag_eval.id_nnn_epis_diagnosis%TYPE,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        i_flg_status         IN nnn_epis_diag_eval.flg_status%TYPE,
        i_dt_evaluation      IN VARCHAR2,
        i_notes              IN CLOB,
        i_lst_nan_relf       IN table_number,
        i_lst_nan_riskf      IN table_number,
        i_lst_nan_defc       IN table_number,
        o_nnn_epis_diag_eval OUT nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates an evaluation of NANDA Nursing Diagnosis in a patient's nursing care plan using the information of the last evaluation (if any)and the status indicated in the input parameter.
    *
    * This method is only inteded to be used for actions like "Mark as Active", "Mark as Inactive", "Mark as Resolved"
    * to create a new evaluation, so as assumption the new diagnosis status must be different from de last one.
    * Otherwise shoud use the full method pk_nnn_ux.set_diagnosis_evaluate.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_diagnosis    Careplan's NANDA Diagnosis ID 
    * @param    i_flg_status            Diagnosis status
    * @param    o_nnn_epis_diag_eval    Returns the created Careplan's NANDA Diagnosis Evaluation ID
    * @param    o_error                 Error information
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/13/2014
    */
    FUNCTION set_diagnosis_evaluate_st
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_nnn_epis_diagnosis IN nnn_epis_diag_eval.id_nnn_epis_diagnosis%TYPE,
        i_flg_status         IN nnn_epis_diag_eval.flg_status%TYPE,
        o_nnn_epis_diag_eval OUT nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a set of NANDA Diagnosis evaluations.
    *
    * @param    i_lang                  Professional preferred language    
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_lst_epis_diag_eval    Collection of diagnosis evaluation IDs that we want to cancel
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    o_error                 Error information    
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/06/2014
    */
    FUNCTION set_diagnosis_eval_cancel
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_lst_epis_diag_eval IN table_number,
        i_cancel_reason      IN nnn_epis_diag_eval.id_cancel_reason%TYPE,
        i_cancel_notes       IN nnn_epis_diag_eval.cancel_notes%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Gets info about an evaluation of a NANDA Diagnosis in a patient's nursing care plan.
    *    
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_diag_eval   Careplan's NANDA Diagnosis Evaluation ID that we want to retrieve
    * @param    o_eval                 Information about the nursing diagnosis evaluation
    * @param    o_error                Error information    
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    3/3/2014
    */
    FUNCTION get_diagnosis_evaluate
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_diag_eval IN nnn_epis_diag_eval.id_nnn_epis_diag_eval%TYPE,
        o_eval               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info about a NOC Outcome included in a patient's nursing care plan.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome     Careplan's NOC Outcome ID
    * @param    o_outcome              The details of the selected NOC outcome
    * @param    o_error                Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/6/2014
    */
    FUNCTION get_outcome
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        o_outcome          OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates a NOC Nursing Outcome in a patient's nursing care plan.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID 
    * @param    i_episode                      Episode ID 
    * @param    i_noc_outcome                  NOC Outcome ID
    * @param    i_nnn_epis_outcome             Careplan's NOC Outcome ID. Declared to update an existing nursing outcome or NULL to create a new one     
    * @param    i_episode_origin               Episode ID where the activity was registered 
    * @param    i_episode_destination          Episode ID where the activity is going to be performed
    * @param    i_flg_prn                      Flag that indicates wether the Outcome is PRN or not
    * @param    i_notes_prn                    Notes to indicate when a PRN order should be activated
    * @param    i_flg_time                     Execution time to evaluate the outcome: In current (E)pisode, (B)etween episodes, (N)ext episode. 
    * @param    i_flg_priority                 Flag that indicates the priority of an Outcome: (N)ormal, (U)rgent, (E)mergent
    * @param    i_order_recurr_plan            Order recurrence plan ID for defined frequency in the instructions             
    * @param    i_flg_req_status               Request status
    * @param    o_nnn_epis_outcome             Returns the updated Careplan's NOC Outcome ID
    * @param    o_error                        Error information
    *
    * @value    i_flg_prn {*} pk_alert_constant.g_no {*} pk_alert_constant.g_yes
    * @value    i_flg_time {*} pk_nnn_constant.g_time_performed_episode {*} pk_nnn_constant.g_time_performed_between {*} pk_nnn_constant.g_time_performed_next_epis
    * @value    i_flg_priority {*} pk_nnn_constant.g_priority_normal {*} pk_nnn_constant.g_priority_urgent {*} pk_nnn_constant.g_priority_emergent
    * @value    i_flg_req_status {*} pk_nnn_constant.g_req_status_ordered {*} pk_nnn_constant.g_req_status_draft {*} pk_nnn_constant.g_req_status_ongoing  {*} pk_nnn_constant.g_req_status_suspended
    *
    * @return   True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   5/6/2013    
    */
    FUNCTION set_outcome_update
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_outcome.id_patient%TYPE,
        i_episode             IN nnn_epis_outcome.id_episode%TYPE,
        i_noc_outcome         IN nnn_epis_outcome.id_noc_outcome%TYPE,
        i_nnn_epis_outcome    IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_episode_origin      IN nnn_epis_outcome.id_episode_origin%TYPE,
        i_episode_destination IN nnn_epis_outcome.id_episode_destination%TYPE,
        i_flg_prn             IN nnn_epis_outcome.flg_prn%TYPE,
        i_notes_prn           IN CLOB,
        i_flg_time            IN nnn_epis_outcome.flg_time%TYPE,
        i_flg_priority        IN nnn_epis_outcome.flg_priority%TYPE,
        i_order_recurr_plan   IN nnn_epis_outcome.id_order_recurr_plan%TYPE,
        i_flg_req_status      IN nnn_epis_outcome.flg_req_status%TYPE,
        o_nnn_epis_outcome    OUT nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a set of NOC Outcomes and all associated NOC Indicators that are not being shared with other outcomes.
    *
    * @param    i_lang                  Professional preferred language    
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_outcome  Collection of outcomes identifiers that we want to cancel
    * @param    i_cancel_reason         Cancellation reason identifier.
    * @param    i_cancel_notes          Notes describing the reason of the cancellation.
    * @param    o_error                 Error information
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    FUNCTION set_outcome_cancel
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_lst_nnn_epis_outcome IN table_number,
        i_cancel_reason        IN nnn_epis_outcome.id_cancel_reason%TYPE,
        i_cancel_notes         IN nnn_epis_outcome.cancel_notes%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets as "On-Hold" a set of NOC Outcomes.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_outcome     Collection of outcomes identifiers that we want to hold
    * @param    o_error                    Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    FUNCTION set_outcome_hold
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN nnn_epis_outcome.id_patient%TYPE,
        i_episode              IN nnn_epis_outcome.id_episode%TYPE,
        i_lst_nnn_epis_outcome IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Resumes from "On-Hold" state a set of NOC Outcomes.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_outcome     Collection of outcomes identifiers that we want to resume
    * @param    o_error                    Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    FUNCTION set_outcome_resume
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN nnn_epis_outcome.id_patient%TYPE,
        i_episode              IN nnn_epis_outcome.id_episode%TYPE,
        i_lst_nnn_epis_outcome IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Gets info to use in the next evaluation of a NOC Outcome in a patient's nursing care plan.
    *    
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome         Careplan's NOC Outcome
    * @param    o_eval                     Information about the next evaluation
    * @param    o_error                    Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/9/2014
    */
    FUNCTION get_next_outcome_eval_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nnn_epis_outcome IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE,
        o_eval             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates or updates an evaluation of NOC Outcome in a patient's nursing care plan.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_outcome      Careplan's NOC Outcome ID 
    * @param    i_nnn_epis_outcome_eval Careplan's NOC Outcome Evaluation ID. Declared to update an existing evaluation or NULL to create a new one
    * @param    i_dt_evaluation         Evaluation date 
    * @param    i_target_value          Outcome Target rating: Likert scale (1 to 5)
    * @param    i_outcome_value         Outcome overall rating: Likert scale (1 to 5)
    * @param    i_notes                 Notes
    * @param    o_nnn_epis_outcome_eval Returns the created or updated Careplan's NOC Outcome Evaluation ID
    * @param    o_error                 Error information    
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/7/2014
    */
    FUNCTION set_outcome_evaluate
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_outcome_eval.id_patient%TYPE,
        i_episode               IN nnn_epis_outcome_eval.id_episode%TYPE,
        i_nnn_epis_outcome      IN nnn_epis_outcome_eval.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        i_dt_evaluation         IN VARCHAR2,
        i_target_value          IN nnn_epis_outcome_eval.target_value%TYPE,
        i_outcome_value         IN nnn_epis_outcome_eval.outcome_value%TYPE,
        i_notes                 IN CLOB,
        o_nnn_epis_outcome_eval OUT nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a set of NOC Outcome evaluations.
    *
    * @param    i_lang                         Professional preferred language    
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_outcome_eval    Collection of outcome evaluation IDs that we want to cancel
    * @param    i_cancel_reason                Cancellation reason identifier.
    * @param    i_cancel_notes                 Notes describing the reason of the cancellation.
    * @param    o_error                        Error information
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/06/2014
    */
    FUNCTION set_outcome_eval_cancel
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_lst_nnn_epis_outcome_eval IN table_number,
        i_cancel_reason             IN nnn_epis_outcome_eval.id_cancel_reason%TYPE,
        i_cancel_notes              IN nnn_epis_outcome_eval.cancel_notes%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Gets info about an evaluation of a NOC Outcome in a patient's nursing care plan.
    *    
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome_eval    Careplan's NOC Outcome Evaluation ID that we want to retrieve
    * @param    o_eval                     Information about the nursing outcome evaluation
    * @param    o_error                    Error information    
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/6/2014
    */
    FUNCTION get_outcome_evaluate
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_nnn_epis_outcome_eval IN nnn_epis_outcome_eval.id_nnn_epis_outcome_eval%TYPE,
        o_eval                  OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Checks if goals were achieved for NOC outcomes/indicators that are associated with a NANDA Diagnosis.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)    
    * @param    i_nnn_epis_diagnosis    Careplan's NANDA Diagnosis ID
    * @param    o_flg_goals_archieved   Returns 'N' if at least one goal was not achieved
    * @param    o_goals_status          Cursor with information about expected outcomes and current evaluation
    * @param    o_error             Error information        
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    2/10/2014
    */
    FUNCTION check_outcome_goals_achieved
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_nnn_epis_diagnosis  IN nnn_epis_diagnosis.id_nnn_epis_diagnosis%TYPE,
        o_flg_goals_archieved OUT VARCHAR2,
        o_goals_status        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info about a NOC Indicator included in a patient's nursing care plan.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_indicator   Careplan's NOC Indicator ID
    * @param    o_indicator            The details of the selected NOC indicator
    * @param    o_error                Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/2/2014
    */
    FUNCTION get_indicator
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_indicator IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        o_indicator          OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates a NOC Nursing Indicator in a patient's nursing care plan.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID 
    * @param    i_episode                      Episode ID 
    * @param    i_noc_indicator                NOC Indicator ID
    * @param    i_nnn_epis_indicator           Careplan's NOC Indicator ID
    * @param    i_episode_origin               Episode ID where the activity was registered 
    * @param    i_episode_destination          Episode ID where the activity is going to be performed
    * @param    i_flg_prn                      Flag that indicates wether the Outcome is PRN or not
    * @param    i_notes_prn                    Notes to indicate when a PRN order should be activated
    * @param    i_flg_time                     Execution time to evaluate the outcome: In current (E)pisode, (B)etween episodes, (N)ext episode. 
    * @param    i_flg_priority                 Flag that indicates the priority of an Outcome: (N)ormal, (U)rgent, (E)mergent
    * @param    i_order_recurr_plan            Order recurrence plan ID for defined frequency in the instructions
    * @param    i_flg_req_status               Request status
    * @param    o_nnn_epis_indicator           Returns the updated Careplan's NOC Indicator ID
    * @param    o_error                        Error information    
    *
    * @value    i_flg_prn {*} pk_alert_constant.g_no {*} pk_alert_constant.g_yes
    * @value    i_flg_time {*} pk_nnn_constant.g_time_performed_episode {*} pk_nnn_constant.g_time_performed_between {*} pk_nnn_constant.g_time_performed_next_epis
    * @value    i_flg_priority {*} pk_nnn_constant.g_priority_normal {*} pk_nnn_constant.g_priority_urgent {*} pk_nnn_constant.g_priority_emergent
    * @value    i_flg_req_status {*} pk_nnn_constant.g_req_status_ordered {*} pk_nnn_constant.g_req_status_draft {*} pk_nnn_constant.g_req_status_ongoing  {*} pk_nnn_constant.g_req_status_suspended
    *
    * @return   True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   5/6/2013    
    */
    FUNCTION set_indicator_update
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_indicator.id_patient%TYPE,
        i_episode             IN nnn_epis_indicator.id_episode%TYPE,
        i_noc_indicator       IN nnn_epis_indicator.id_noc_indicator%TYPE,
        i_nnn_epis_indicator  IN nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        i_episode_origin      IN nnn_epis_indicator.id_episode_origin%TYPE,
        i_episode_destination IN nnn_epis_indicator.id_episode_destination%TYPE,
        i_flg_prn             IN nnn_epis_indicator.flg_prn%TYPE,
        i_notes_prn           IN CLOB,
        i_flg_time            IN nnn_epis_indicator.flg_time%TYPE,
        i_flg_priority        IN nnn_epis_indicator.flg_priority%TYPE,
        i_order_recurr_plan   IN nnn_epis_indicator.id_order_recurr_plan%TYPE,
        i_flg_req_status      IN nnn_epis_indicator.flg_req_status%TYPE,
        o_nnn_epis_indicator  OUT nnn_epis_indicator.id_nnn_epis_indicator%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a set of NIC Indicators.
    *
    * @param    i_lang                      Professional preferred language     
    * @param    i_prof                      Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_indicator    Collection of indicators identifiers that we want to cancel
    * @param    i_cancel_reason             Cancellation reason identifier.
    * @param    i_cancel_notes              Notes describing the reason of the cancellation.
    * @param    o_error                     Error information     
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    25/11/2013 
    */
    FUNCTION set_indicator_cancel
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN patient.id_patient%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_lst_nnn_epis_indicator IN table_number,
        i_cancel_reason          IN nnn_epis_indicator.id_cancel_reason%TYPE,
        i_cancel_notes           IN nnn_epis_indicator.cancel_notes%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets as "On-Hold" a set of NOC Indicators.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_indicator   Collection of indicator identifiers that we want to hold
    * @param    o_error                    Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    FUNCTION set_indicator_hold
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN nnn_epis_indicator.id_patient%TYPE,
        i_episode                IN nnn_epis_indicator.id_episode%TYPE,
        i_lst_nnn_epis_indicator IN table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Resumes from "On-Hold" state a set of NOC Indicators.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_indicator   Collection of indicator identifiers that we want to resume
    * @param    o_error                    Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    FUNCTION set_indicator_resume
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_patient                IN nnn_epis_indicator.id_patient%TYPE,
        i_episode                IN nnn_epis_indicator.id_episode%TYPE,
        i_lst_nnn_epis_indicator IN table_number,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Gets info to use in the next evaluation of a NOC Indicator in a patient's nursing care plan.
    *    
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome         Careplan's NOC Outcome
    * @param    i_nnn_epis_indicator       Careplan's NOC Indicator ID    
    * @param    o_eval                     Information about the next evaluation
    * @param    o_error                    Error information    
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/11/2014
    */
    FUNCTION get_next_indicator_eval_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_nnn_epis_outcome   IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        o_eval               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates or updates an evaluation of NOC Indicator in a patient's nursing care plan.
    *
    * @param    i_lang                  Professional preferred language
    * @param    i_prof                  Professional identification and its context (institution and software)
    * @param    i_patient               Patient ID
    * @param    i_episode               Episode ID
    * @param    i_nnn_epis_indicator    Careplan's NOC Indicator ID 
    * @param    i_nnn_epis_ind_eval     Careplan's NOC Indicator Evaluation ID. Declared to update an existing evaluation or NULL to create a new one
    * @param    i_dt_evaluation         Evaluation date 
    * @param    i_target_value          Indicator Target rating: Likert scale (1 to 5)
    * @param    i_indicator_value       Indicator overall rating: Likert scale (1 to 5)
    * @param    i_notes                 Notes
    * @param    i_flg_status            Evaluation status        
    * @param    o_nnn_epis_ind_eval     Returns the created or updated Careplan's NOC Indicator Evaluation ID
    * @param    o_error                 Error information    
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/7/2014
    */
    FUNCTION set_indicator_evaluate
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN nnn_epis_ind_eval.id_patient%TYPE,
        i_episode            IN nnn_epis_ind_eval.id_episode%TYPE,
        i_nnn_epis_indicator IN nnn_epis_ind_eval.id_nnn_epis_indicator%TYPE,
        i_nnn_epis_ind_eval  IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        i_dt_evaluation      IN VARCHAR2,
        i_target_value       IN nnn_epis_ind_eval.target_value%TYPE,
        i_indicator_value    IN nnn_epis_ind_eval.indicator_value%TYPE,
        i_notes              IN CLOB,
        o_nnn_epis_ind_eval  OUT nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a set of NIC Indicator evaluations.
    *
    * @param    i_lang                      Professional preferred language     
    * @param    i_prof                      Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_ind_eval     Collection of indicator evaluation IDs that we want to cancel
    * @param    i_cancel_reason             Cancellation reason identifier.
    * @param    i_cancel_notes              Notes describing the reason of the cancellation.
    * @param    o_error                     Error information     
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/06/2014
    */
    FUNCTION set_indicator_eval_cancel
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_lst_nnn_epis_ind_eval IN table_number,
        i_cancel_reason         IN nnn_epis_ind_eval.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_ind_eval.cancel_notes%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Gets info about an evaluation of a NOC Indicator in a patient's nursing care plan.
    *    
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_nnn_epis_outcome          Associated Careplan's Outcome ID (the scale descriptions depends on associated Outcome)
    * @param    i_nnn_epis_ind_eval        Careplan's NOC Indicator Evaluation ID that we want to retrieve
    * @param    o_eval                     Information about the nursing indicator evaluation
    * @param    o_error                    Error information    
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/6/2014
    */
    FUNCTION get_indicator_evaluate
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_outcome  IN nnn_epis_outcome.id_nnn_epis_outcome%TYPE,
        i_nnn_epis_ind_eval IN nnn_epis_ind_eval.id_nnn_epis_ind_eval%TYPE,
        o_eval              OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Cancels a set of NIC Interventions and all associated NIC Activities that are not being shared with other interventions.
    *
    * @param    i_lang                         Professional preferred language     
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_intervention    Collection of interventions identifiers that we want to cancel
    * @param    i_cancel_reason                Cancellation reason identifier.
    * @param    i_cancel_notes                 Notes describing the reason of the cancellation.
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    14/11/2013 
    */
    FUNCTION set_intervention_cancel
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        i_cancel_reason             IN nnn_epis_intervention.id_cancel_reason%TYPE,
        i_cancel_notes              IN nnn_epis_intervention.cancel_notes%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets as "On-Hold" a set of NIC Interventions.
    *
    * @param    i_lang                       Professional preferred language
    * @param    i_prof                       Professional identification and its context (institution and software)
    * @param    i_patient                    Patient ID
    * @param    i_episode                    Episode ID         
    * @param    i_lst_nnn_epis_intervention  Collection of intervention identifiers that we want to hold
    * @param    o_error                      Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/16/2014
    */
    FUNCTION set_intervention_hold
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_intervention.id_patient%TYPE,
        i_episode                   IN nnn_epis_intervention.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Resumes from "On-hold" state a set of NIC Interventions.
    *
    * @param    i_lang                       Professional preferred language
    * @param    i_prof                       Professional identification and its context (institution and software)
    * @param    i_patient                    Patient ID
    * @param    i_episode                    Episode ID         
    * @param    i_lst_nnn_epis_intervention  Collection of intervention identifiers that we want to resume
    * @param    o_error                      Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/16/2014
    */
    FUNCTION set_intervention_resume
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_intervention.id_patient%TYPE,
        i_episode                   IN nnn_epis_intervention.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets info about a NIC Activity included in a patient's nursing care plan.
    *
    * @param    i_lang                 Professional preferred language
    * @param    i_prof                 Professional identification and its context (institution and software)
    * @param    i_nnn_epis_activity    Careplan's NIC Activity ID
    * @param    o_activity             The details of the selected NIC activity
    * @param    o_error                Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/20/2014
    */
    FUNCTION get_activity
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_nnn_epis_activity IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        o_activity          OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Updates a NIC Activity to a patient's nursing care plan.
    *
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_patient                      Patient ID 
    * @param    i_episode                      Episode ID 
    * @param    i_nic_activity                 NIC Activity ID 
    * @param    i_nnn_epis_activity            Careplan's NIC Activity ID
    * @param    i_episode_origin               Episode ID where the activity was registered 
    * @param    i_episode_destination          Episode ID where the activity is going to be performed
    * @param    i_flg_prn                      Flag that indicates wether the Outcome is PRN or not
    * @param    i_notes_prn                    Notes to indicate when a PRN order should be activated
    * @param    i_flg_time                     Execution time to evaluate the outcome: In current (E)pisode, (B)etween episodes, (N)ext episode. 
    * @param    i_flg_priority                 Flag that indicates the priority of an Outcome: (N)ormal, (U)rgent, (E)mergent
    * @param    i_order_recurr_plan            Order recurrence plan ID for defined frequency in the instructions 
    * @param    i_flg_req_status               Request status
    * @param    o_nnn_epis_outcome             Returns the updated Careplan's NIC Activity ID
    * @param    o_error                        Error information
    *
    * @value    i_flg_prn {*} pk_alert_constant.g_no {*} pk_alert_constant.g_yes
    * @value    i_flg_time {*} pk_nnn_constant.g_time_performed_episode {*} pk_nnn_constant.g_time_performed_between {*} pk_nnn_constant.g_time_performed_next_epis
    * @value    i_flg_priority {*} pk_nnn_constant.g_priority_normal {*} pk_nnn_constant.g_priority_urgent {*} pk_nnn_constant.g_priority_emergent
    * @value    i_flg_req_status {*} pk_nnn_constant.g_req_status_ordered {*} pk_nnn_constant.g_req_status_draft {*} pk_nnn_constant.g_req_status_ongoing  {*} pk_nnn_constant.g_req_status_suspended
    *
    * @return   True or False on success or error
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   6/20/2014
    */
    FUNCTION set_activity_update
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN nnn_epis_activity.id_patient%TYPE,
        i_episode             IN nnn_epis_activity.id_episode%TYPE,
        i_nic_activity        IN nnn_epis_activity.id_nic_activity%TYPE,
        i_nnn_epis_activity   IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        i_episode_origin      IN nnn_epis_activity.id_episode_origin%TYPE,
        i_episode_destination IN nnn_epis_activity.id_episode_destination%TYPE,
        i_flg_prn             IN nnn_epis_activity.flg_prn%TYPE,
        i_notes_prn           IN CLOB,
        i_flg_time            IN nnn_epis_activity.flg_time%TYPE,
        i_flg_priority        IN nnn_epis_activity.flg_priority%TYPE,
        i_order_recurr_plan   IN nnn_epis_activity.id_order_recurr_plan%TYPE,
        i_flg_req_status      IN nnn_epis_activity.flg_req_status%TYPE,
        o_nnn_epis_activity   OUT nnn_epis_activity.id_nnn_epis_activity%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a set of NIC Activities.
    *
    * @param    i_lang                      Professional preferred language     
    * @param    i_prof                      Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_activity     Collection of activities identifiers that we want to cancel
    * @param    i_cancel_reason             Cancellation reason identifier.
    * @param    i_cancel_notes              Notes describing the reason of the cancellation.
    * @param    o_error                     Error information          
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    25/11/2013 
    */
    FUNCTION set_activity_cancel
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_lst_nnn_epis_activity IN table_number,
        i_cancel_reason         IN nnn_epis_activity.id_cancel_reason%TYPE,
        i_cancel_notes          IN nnn_epis_activity.cancel_notes%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Sets as "On-Hold" a set of NIC Activities.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_activity    Collection of activities identifiers that we want to hold
    * @param    o_error                    Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    FUNCTION set_activity_hold
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_activity.id_patient%TYPE,
        i_episode               IN nnn_epis_activity.id_episode%TYPE,
        i_lst_nnn_epis_activity IN table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Resumes from "On-hold" state a set of NIC Activities.
    *
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID         
    * @param    i_lst_nnn_epis_activity    Collection of activities identifiers that we want to resume
    * @param    o_error                    Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    5/15/2014
    */
    FUNCTION set_activity_resume
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN nnn_epis_activity.id_patient%TYPE,
        i_episode               IN nnn_epis_activity.id_episode%TYPE,
        i_lst_nnn_epis_activity IN table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Gets info about NIC Activities in a patient's nursing care plan.
    *    
    * @param    i_lang                         Professional preferred language
    * @param    i_prof                         Professional identification and its context (institution and software)
    * @param    i_lst_nnn_epis_intervention    Collection of Careplan's NIC Intervention ID
    * @param    i_lst_nnn_epis_activity        Collection of Careplan's NIC Activity ID
    * @param    o_info                         Information about the NIC Activities
    * @param    o_error                        Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    9/29/2014
    */
    FUNCTION get_activity_info
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_outcome.id_patient%TYPE,
        i_episode                   IN nnn_epis_outcome.id_episode%TYPE,
        i_lst_nnn_epis_intervention IN table_number,
        i_lst_nnn_epis_activity     IN table_number,
        o_info                      OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Gets info to be used in the next execution of a NIC Activity in a patient's nursing care plan.
    *    
    * @param    i_lang                     Professional preferred language
    * @param    i_prof                     Professional identification and its context (institution and software)
    * @param    i_patient                  Patient ID
    * @param    i_episode                  Episode ID             
    * @param    i_nnn_epis_intervention    Careplan's NIC Intervention ID    
    * @param    i_nnn_epis_activity        Careplan's NIC Activity ID
    * @param    o_exec_info                Information about the next execution
    * @param    o_activity_tasks           If a tasklist, returns the list of activity tasks
    * @param    o_vs_info                  Vital sign-related information    
    * @param    o_error                    Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    9/29/2014
    */
    FUNCTION get_next_activity_exec_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN episode.id_episode%TYPE,
        i_nnn_epis_intervention IN nnn_epis_intervention.id_nnn_epis_intervention%TYPE,
        i_nnn_epis_activity     IN nnn_epis_activity.id_nnn_epis_activity%TYPE,
        o_exec_info             OUT pk_types.cursor_type,
        o_activity_tasks        OUT pk_types.cursor_type,
        o_vs_info               OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Creates or updates a collection of executions of NIC Activities in a patient's nursing care plan.
    *
    * @param    i_lang                          Professional preferred language
    * @param    i_prof                          Professional identification and its context (institution and software)
    * @param    i_patient                       Patient ID
    * @param    i_episode                       Episode ID
    * @param    i_jsn_input_params              Collection of input parameters in JSON
    * @param    o_lst_nnn_epis_activity_det     Collection of Careplan's NIC Activity execution ID
    * @param    o_error                         Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    6/17/2014
    */
    FUNCTION set_activity_execute
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN nnn_epis_activity_det.id_patient%TYPE,
        i_episode                   IN nnn_epis_activity_det.id_episode%TYPE,
        i_jsn_input_params          IN CLOB,
        o_lst_nnn_epis_activity_det OUT table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a set of NIC Activity executions.
    *
    * @param    i_lang                      Professional preferred language     
    * @param    i_prof                      Professional identification and its context (institution and software)
    * @param    lst_nnn_epis_activity_det   Collection of activity execution IDs that we want to cancel
    * @param    i_cancel_reason             Cancellation reason identifier.
    * @param    i_cancel_notes              Notes describing the reason of the cancellation.
    * @param    o_error                     Error information          
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    11/06/2014
    */
    FUNCTION set_activity_exec_cancel
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_lst_nnn_epis_activity_det IN table_number,
        i_cancel_reason             IN nnn_epis_activity_det.id_cancel_reason%TYPE,
        i_cancel_notes              IN nnn_epis_activity_det.cancel_notes%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Calculates the duration and the end date of a NIC Activity execution
    *
    * @param    i_lang               
    * @param    i_prof                              Professional preferred language
    * @param    i_dt_start_date                     Professional identification and its context (institution and software)
    * @param    i_duration                          Start date defined by the user
    * @param    i_unit_meas_duration                Duration defined by the user
    * @param    i_dt_end_date                       Duration unit measure defined by the user
    * @param    o_dt_start_date                     End date defined by the user
    * @param    o_duration                          Calculated start date
    * @param    o_duration_desc                     Duration considered in this interval
    * @param    o_unit_meas_duration                Duration unit measure considered in this interval
    * @param    o_dt_end_date                       Calculated end date
    * @param    o_error                             Error information
    *
    * @return   True or False on success or error
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    10/02/2014
    */
    FUNCTION calculate_duration
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_dt_start_date      IN VARCHAR2,
        i_duration           IN pk_types.t_med_num,
        i_unit_meas_duration IN nic_cfg_activity.id_unit_measure_duration%TYPE,
        i_dt_end_date        IN VARCHAR2,
        o_dt_start_date      OUT VARCHAR2,
        o_duration           OUT pk_types.t_med_num,
        o_duration_desc      OUT pk_types.t_big_byte,
        o_unit_meas_duration OUT nic_cfg_activity.id_unit_measure_duration%TYPE,
        o_dt_end_date        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

END pk_nnn_ux;
/
