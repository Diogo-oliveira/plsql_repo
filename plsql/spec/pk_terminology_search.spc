/*-- Last Change Revision: $Rev: 1949268 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2020-05-12 17:18:16 +0100 (ter, 12 mai 2020) $*/
CREATE OR REPLACE PACKAGE pk_terminology_search IS
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;
    --
    g_search_type_complaint CONSTANT VARCHAR2(1) := 'C';
    g_search_type_clin_serv CONSTANT VARCHAR2(1) := 'S';
    g_alert_context         CONSTANT VARCHAR2(30 CHAR) := 'ALERT_CONTEXT';
    g_namespace_diag_filter CONSTANT VARCHAR2(30 CHAR) := 'DIAGNOSES_FILTER';
    g_lang                  CONSTANT VARCHAR2(30 CHAR) := 'PK_TERM_SEARCH.LANG';
    g_prof_id               CONSTANT VARCHAR2(30 CHAR) := 'PK_TERM_SEARCH.PROF_ID';
    g_institution           CONSTANT VARCHAR2(30 CHAR) := 'PK_TERM_SEARCH.INSTITUTION';
    g_software              CONSTANT VARCHAR2(30 CHAR) := 'PK_TERM_SEARCH.SOFTWARE';
    g_patient               CONSTANT VARCHAR2(30 CHAR) := 'PK_TERM_SEARCH.PATIENT';
    g_episode               CONSTANT VARCHAR2(30 CHAR) := 'PK_TERM_SEARCH.EPISODE';
    g_text_search           CONSTANT VARCHAR2(30 CHAR) := 'PK_TERM_SEARCH.TEXT_SEARCH';
    g_epis_diag_type        CONSTANT VARCHAR2(30 CHAR) := 'PK_TERM_SEARCH.EPIS_DIAG_TYPE';
    --
    g_diag_list_searchable     CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_diag_list_most_freq      CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_diag_list_preg_most_freq CONSTANT VARCHAR2(1 CHAR) := 'G';
    --
    g_most_freq_diag CONSTANT diagnosis_content.flg_type_dep_clin%TYPE := 'M';
    g_most_freq_preg CONSTANT diagnosis_content.flg_type_dep_clin%TYPE := 'G';
    --
    g_medical_diagnosis_type   CONSTANT diagnosis_content.flg_type_alert_diagnosis%TYPE := 'M';
    g_cong_anom_diagnosis_type CONSTANT diagnosis_content.flg_type_alert_diagnosis%TYPE := 'A';
    g_surgical_diagnosis_type  CONSTANT diagnosis_content.flg_type_alert_diagnosis%TYPE := 'S';
    --
    g_searchable_diag      CONSTANT diagnosis_content.flg_type_dep_clin%TYPE := 'P';
    g_searchable_past_hist CONSTANT diagnosis_content.flg_type_dep_clin%TYPE := 'H';

    /**************************************************************************
    * Initializes parameters for Diagnoses filters
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Sergio Dias
    * @version                       2.6.4.2
    * @since                         Oct-8-2014
    **************************************************************************/
    PROCEDURE init_params_diagnosis
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /********************************************************************************************
    * Loads context variables used by filter functions
    *
    * @param o_lang                  Language identifier
    * @param o_prof                  Professional information
    * @param o_profile_template      Profile template ID
    * @param o_id_patient            Patient ID
    * @param o_episode               Episode ID
    * @param o_text_search           Text used in the application to filter the content
    * @param o_epis_diag_type        Diagnosis type (epis_diagnosis.flg_type)
    *
    * @author                        Sergio Dias
    * @version                       2.6.4.2
    * @since                         Oct-8-2014
    ********************************************************************************************/
    PROCEDURE load_search_values
    (
        o_lang             OUT language.id_language%TYPE,
        o_prof             OUT profissional,
        o_profile_template OUT profile_template.id_profile_template%TYPE,
        o_id_patient       OUT patient.id_patient%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_text_search      OUT VARCHAR2,
        o_epis_diag_type   OUT epis_diagnosis.flg_type%TYPE
    );

    /**************************************************************************************************************
    * Creates 'with previous records' string 
    *
    * @param i_lang                     Language identifier
    * @param i_id_task_type             Area - Problems (60), Past medical history (62), Diagnoses (63)
    * @param i_date_tstz                Date when diagnoses was registered/Date of initial diagnosis
    *
    * @return                           Returns complete string 
    *                        
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            23/09/2014
    **************************************************************************************************************/
    FUNCTION get_with_prev_rec_msg
    (
        i_lang         IN language.id_language%TYPE,
        i_id_task_type IN NUMBER,
        i_date_tstz    IN VARCHAR2
    ) RETURN VARCHAR2;

    /***********************************************************************************************
    * Loads "problem type" field in Problems confirmation screen
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   Professional information
    * @param i_patient                Patient ID
    * @param i_id_diagnoses           Diagnosis ID
    * @param i_id_alert_diagnoses     Alert_diagnosis ID
    * 
    * @param o_areas_domain           Returns areas available in the multichoice
    * @param o_diagnoses_types        For each diagnosis, returns areas where it is configured
    * @param o_diagnoses_warning      Returns header warning value
    * @param o_error                  Error information
    *
    * @author                         Sergio Dias
    * @version                        2.6.4.2
    * @since                          Oct-9-2014
    ***********************************************************************************************/
    FUNCTION get_diagnoses_types
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_id_diagnoses       IN table_number,
        i_id_alert_diagnoses IN table_number,
        o_areas_domain       OUT pk_types.cursor_type,
        o_diagnoses_types    OUT table_table_varchar,
        o_diagnoses_warning  OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /***********************************************************************************************
    * Loads diagnoses information to be used in diagnoses listing
    *
    * @param i_lang                           Language identifier
    * @param i_prof                           Professional information
    * @param i_patient                        Patient ID
    * @param i_format_text                    Highlight search text Y/N
    * @param i_terminologies_task_types       Terminologies in use by the inst/soft for the given functionalities (Task_types)
    * @param i_term_task_type                 Area of the application where the term will be shown
    * @param i_list_type                      Type of list to be returned
    * @param i_synonym_list_enable            Enable/disable synonyms result sets
    * @param i_synonym_search_enable          Enable/disable synonyms in search sets
    * @param i_include_other_diagnosis        Include other diagnoses in the result set
    * @param i_tbl_terminologies              Filter by flg_terminology (NULL for all terminologies). This is useful when the user 
    *                                           has a multichoice with the available terminologies and can select them
    *
    * @param o_inst                           Return institution
    * @param o_soft                           Return software
    * @param o_pat_age                        Return patient age
    * @param o_pat_gender                     Return patient gender
    * @param o_tbl_flg_terminologies          Return available terminologies
    * @param o_term_task_type                 Return termonilogy task type
    * @param o_flg_type_alert_diagnosis       Return flg_type_alert_diagnosis
    * @param o_flg_type_dep_clin              Return flg_type_dep_clin
    * @param o_synonym_list_enable            Enable/disable synonyms result sets
    * @param o_synonym_search_enable          Enable/disable synonyms in search sets
    * @param o_include_other_diagnosis        Include other diagnoses in the result set
    * @param o_tbl_prof_dep_clin_serv         Return professional dep_clin_serv information
    * @param o_terminologies_lang             Return terminologies language
    * @param o_format_text                    Highlight search text Y/N
    * @param o_validate_max_age               Return if it should validate maximum age
    *
    * @author                         Sergio Dias
    * @version                        2.6.4.2
    * @since                          Oct-9-2014
    ***********************************************************************************************/
    PROCEDURE get_diagnoses_default_args
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_format_text              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_terminologies_task_types IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_term_task_type           IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_list_type                IN VARCHAR2 DEFAULT g_diag_list_searchable,
        i_synonym_list_enable      IN sys_config.value%TYPE DEFAULT NULL,
        i_synonym_search_enable    IN sys_config.value%TYPE DEFAULT NULL,
        i_include_other_diagnosis  IN sys_config.value%TYPE DEFAULT NULL,
        i_tbl_terminologies        IN table_varchar DEFAULT NULL,
        o_inst                     OUT institution.id_institution%TYPE,
        o_soft                     OUT software.id_software%TYPE,
        o_pat_age                  OUT NUMBER,
        o_pat_gender               OUT patient.gender%TYPE,
        o_tbl_flg_terminologies    OUT table_varchar,
        o_term_task_type           OUT task_type.id_task_type%TYPE,
        o_flg_type_alert_diagnosis OUT diagnosis_content.flg_type_alert_diagnosis%TYPE,
        o_flg_type_dep_clin        OUT diagnosis_content.flg_type_dep_clin%TYPE,
        o_synonym_list_enable      OUT sys_config.value%TYPE,
        o_synonym_search_enable    OUT sys_config.value%TYPE,
        o_include_other_diagnosis  OUT sys_config.value%TYPE,
        o_tbl_prof_dep_clin_serv   OUT table_number,
        o_terminologies_lang       OUT language.id_language%TYPE,
        o_format_text              OUT VARCHAR2,
        o_validate_max_age         OUT VARCHAR2
    );

    /***********************************************************************************************
    * Sets context information to be used later in content queries
    *
    * @param i_institution                   Institution ID
    * @param i_software                      Software ID
    * @param i_pat_age                       Patient age
    * @param i_pat_gender                    Patient gender
    * @param i_term_task_type                Terminology task type
    * @param i_flg_type_alert_diagnosis      Alert diagnosis flag type
    * @param i_flg_type_dep_clin             msi_concept_term flag
    * @param i_synonym_list_enable           Enable/disable synonyms result sets
    * @param i_include_other_diagnosis       Include other diagnoses in the result set
    * @param i_only_other_diags              Include only other diagnoses in the result set
    * @param i_tbl_dep_clin_serv             dep_clin_serv IDs table
    * @param i_tbl_diagnosis                 Filter by this group of diagnoses id's (NULL for all diagnoses)
    * @param i_tbl_alert_diagnosis           Filter by this group of alert diagnoses id's (NULL for all diagnoses)
    * @param i_row_limit                     Limit the number of rows returned (NULL return all)
    * @param i_parent_diagnosis              Return only the child records of the given parent diag (NULL returns all)
    * @param i_only_diag_filter_by_prt       Return only diagnoses filtered by i_parent_diagnosis
    * @param i_validate_max_age              Indicates if the query should validate maximum age
    * @param i_terminologies_lang            Terminology language
    * @param i_text_search                   Search string used by the user
    * @param i_format_text                   Highlight search text Y/N
    *
    * @author                         Sergio Dias
    * @version                        2.6.4.2
    * @since                          Oct-9-2014
    ***********************************************************************************************/
    PROCEDURE set_diag_search_args
    (
        i_institution              IN institution.id_institution%TYPE,
        i_software                 IN software.id_software%TYPE,
        i_pat_age                  IN NUMBER,
        i_pat_gender               IN patient.gender%TYPE,
        i_term_task_type           IN task_type.id_task_type%TYPE,
        i_flg_type_alert_diagnosis IN diagnosis_content.flg_type_alert_diagnosis%TYPE,
        i_flg_type_dep_clin        IN diagnosis_content.flg_type_dep_clin%TYPE,
        i_synonym_list_enable      IN sys_config.value%TYPE,
        i_include_other_diagnosis  IN sys_config.value%TYPE,
        i_only_other_diags         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_tbl_dep_clin_serv        IN table_number,
        i_tbl_diagnosis            IN table_number,
        i_tbl_alert_diagnosis      IN table_number,
        i_row_limit                IN NUMBER,
        i_parent_diagnosis         IN diagnosis.id_diagnosis_parent%TYPE,
        i_only_diag_filter_by_prt  IN VARCHAR2,
        i_validate_max_age         IN VARCHAR2,
        i_terminologies_lang       IN language.id_language%TYPE,
        i_text_search              IN VARCHAR2,
        i_format_text              IN VARCHAR2,
        i_language                 IN language.id_language%TYPE DEFAULT NULL
    );

    /***********************************************************************************************
    * Returns diagnoses table
    *
    * @param i_tbl_diagnosis            Diagnoses ID table
    * @param i_tbl_alert_diagnosis      Alert diagnoses ID table
    * @param i_tbl_terminologies        Terminologies table
    * @param i_tbl_dep_clin_serv        Dep_clin_serv table
    *
    * @return                           Diagnoses table
    *
    * @author                         Sergio Dias
    * @version                        2.6.4.2
    * @since                          Oct-9-2014
    ***********************************************************************************************/
    FUNCTION tf_diagnoses_cnt
    (
        i_tbl_diagnosis       IN table_number,
        i_tbl_alert_diagnosis IN table_number,
        i_tbl_terminologies   IN table_varchar,
        i_tbl_dep_clin_serv   IN table_number
    ) RETURN t_table_diag_cnt;

    /**********************************************************************************************
    * Diagnosis search using an input value
    *
    * @param i_lang                     language identifier
    * @param i_prof                     logged professional structure
    * @param i_patient                  patient ID
    * @param i_text_search              search input
    * @param i_format_text              Apply styles to diagnoses names? Y/N
    * @param i_terminologies_task_types Terminologies in use by the inst/soft for the given functionalities (Task_types)
    * @param i_term_task_type           Area of the application where the term will be shown
    * @param i_flg_show_term_code       Is to concatenate the terminology code to the diagnosis description
    * @param i_list_type                Type of list to be returned
    * @param i_synonym_list_enable      Enable/disable synonyms in result sets
    * @param i_synonym_search_enable    Enable/disable synonyms in search sets
    * @param i_include_other_diagnosis  Include other diagnoses in result sets
    * @param i_tbl_diagnosis            Filter by this group of diagnoses id's (NULL for all diagnoses)
    * @param i_tbl_alert_diagnosis      Filter by this group of alert diagnoses id's (NULL for all diagnoses)
    * @param i_tbl_terminologies        Filter by flg_terminology (NULL for all terminologies). This is useful when the user 
    *                                   has a multichoice with the available terminologies and can select them
    * @param i_row_limit                Limit the number of rows returned (NULL return all) 
    * @param i_parent_diagnosis         Return only the child records of the given parent diag (NULL returns all)
    * @param i_only_diag_filter_by_prt  Return only diagnoses filtered by i_parent_diagnosis
    *
    * @values i_list_type               S - Searchable diagnoses list
    *                                   F - Most frequent diagnoses list
    *                                   G - Pregnancy most frequent diagnoses list
    *
    * @return                           Diagnoses searchable table
    *                        
    * @author                           Alexandre Santos
    * @version                          2.6.3
    * @since                            2013/11/08
    **********************************************************************************************/
    FUNCTION tf_diagnoses_search
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_text_search              IN VARCHAR2 DEFAULT NULL,
        i_format_text              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_terminologies_task_types IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_term_task_type           IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_flg_show_term_code       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_list_type                IN VARCHAR2 DEFAULT g_diag_list_searchable,
        i_synonym_list_enable      IN sys_config.value%TYPE DEFAULT NULL,
        i_synonym_search_enable    IN sys_config.value%TYPE DEFAULT NULL,
        i_include_other_diagnosis  IN sys_config.value%TYPE DEFAULT NULL,
        i_tbl_diagnosis            IN table_number DEFAULT NULL,
        i_tbl_alert_diagnosis      IN table_number DEFAULT NULL,
        i_tbl_terminologies        IN table_varchar DEFAULT NULL,
        i_row_limit                IN NUMBER DEFAULT NULL,
        i_parent_diagnosis         IN diagnosis.id_diagnosis_parent%TYPE DEFAULT NULL,
        i_only_diag_filter_by_prt  IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_diag_cnt;

    /**********************************************************************************************
    * Diagnosis search using an input value
    *
    * @param i_lang                     language identifier
    * @param i_prof                     logged professional structure
    * @param i_patient                  patient ID
    * @param i_text_search              search input
    * @param i_format_text              Apply styles to diagnoses names? Y/N
    * @param i_terminologies_task_types Terminologies in use by the inst/soft for the given functionalities (Task_types)
    * @param i_term_task_type           Area of the application where the term will be shown
    * @param i_flg_show_term_code       Is to concatenate the terminology code to the diagnosis description
    * @param i_list_type                Type of list to be returned
    * @param i_synonym_list_enable      Enable/disable synonyms in result sets
    * @param i_synonym_search_enable    Enable/disable synonyms in search sets
    * @param i_include_other_diagnosis  Include other diagnoses in result sets
    * @param i_tbl_diagnosis            Filter by this group of diagnoses id's (NULL for all diagnoses)
    * @param i_tbl_alert_diagnosis      Filter by this group of alert diagnoses id's (NULL for all diagnoses)
    * @param i_tbl_terminologies        Filter by flg_terminology (NULL for all terminologies). This is useful when the user 
    *                                   has a multichoice with the available terminologies and can select them
    * @param i_row_limit                Limit the number of rows returned (NULL return all) 
    * @param i_parent_diagnosis         Return only the child records of the given parent diag (NULL returns all)
    * @param i_only_diag_filter_by_prt  Return only diagnoses filtered by i_parent_diagnosis
    *
    * @values i_list_type               S - Searchable diagnoses list
    *                                   F - Most frequent diagnoses list
    *                                   G - Pregnancy most frequent diagnoses list
    *
    * @return                           Diagnoses searchable table
    *                        
    * @author                           Alexandre Santos
    * @version                          2.6.3
    * @since                            2013/11/08
    **********************************************************************************************/
    FUNCTION tf_diagnoses_list
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_text_search              IN VARCHAR2 DEFAULT NULL,
        i_format_text              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_terminologies_task_types IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_term_task_type           IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis,
        i_flg_show_term_code       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_list_type                IN VARCHAR2 DEFAULT g_diag_list_searchable,
        i_synonym_list_enable      IN sys_config.value%TYPE DEFAULT NULL,
        i_synonym_search_enable    IN sys_config.value%TYPE DEFAULT NULL,
        i_include_other_diagnosis  IN sys_config.value%TYPE DEFAULT NULL,
        i_tbl_diagnosis            IN table_number DEFAULT NULL,
        i_tbl_alert_diagnosis      IN table_number DEFAULT NULL,
        i_tbl_terminologies        IN table_varchar DEFAULT NULL,
        i_row_limit                IN NUMBER DEFAULT NULL,
        i_parent_diagnosis         IN diagnosis.id_diagnosis_parent%TYPE DEFAULT NULL,
        i_only_diag_filter_by_prt  IN VARCHAR2 DEFAULT NULL
    ) RETURN t_coll_diagnosis_config;

    /********************************************************************************************************
    * Gets all diagnosis registered in the current episode.
    *
    * @return                           Returns an episode's diagnoses
    *                                   (used in v_episode_all_diagnoses)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_episode_diagnoses RETURN t_table_diag_cnt;

    /********************************************************************************************************
    * Gets all the problems configured for the episode's complaint
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_complaint_problems)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_complaint_problems RETURN t_table_diag_cnt;

    FUNCTION tf_get_complaint_problems RETURN t_table_diag_cnt;

    /********************************************************************************************************
    * Gets all the past medical history diagnoses configured for the episode's complaint
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_complaint_past_medical)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_complaint_past_med RETURN t_table_diag_cnt;

    /********************************************************************************************************
    * Gets all the past surgical history diagnoses configured for the episode's complaint
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_complaint_past_surgical)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_complaint_past_surg RETURN t_table_diag_cnt;

    /********************************************************************************************************
    * Gets all the problems diagnoses configured for the episode's clinical service
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_clin_serv_problems)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_clin_serv_problems RETURN t_table_diag_cnt;

    FUNCTION tf_get_clin_serv_problems RETURN t_table_diag_cnt;

    /********************************************************************************************************
    * Gets all the past medical history diagnoses configured for the episode's clinical service
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_clin_serv_past_medical)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_clin_serv_past_med RETURN t_table_diag_cnt;

    /********************************************************************************************************
    * Gets all the past surgical history diagnoses configured for the episode's clinical service
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_clin_serv_past_surgical)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    ********************************************************************************************************/
    FUNCTION tf_clin_serv_past_surg RETURN t_table_diag_cnt;

    /**************************************************************************************************************************
    * Gets all the diagnoses configured for a task type
    *
    * @param i_task_type                Task type ID to filter content
    * @param i_list_type                Search type (g_diag_list_searchable/g_diag_list_most_freq/g_diag_list_preg_most_freq)
    *
    * @return                           Returns diagnoses list
    *                                   (used in v_clin_serv_past_surgical)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            Oct-9-2014
    **************************************************************************************************************************/
    FUNCTION tf_all_content
    (
        i_task_type IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_problems,
        i_list_type IN VARCHAR2 DEFAULT g_diag_list_searchable
    ) RETURN t_table_diag_cnt;

    /**************************************************************************************************************************
    * Gets all the diagnoses configured for a task type
    *
    * @param i_origin                   Request origin: D-Diagnoses/P-Problems
    * @param i_list_type                Search type (g_diag_list_searchable/g_diag_list_most_freq/g_diag_list_preg_most_freq)
    *
    * @return                           Returns diagnoses list
    *                                   Used in: V_PROBLEMS_ALL_CONTENT
    *
    * @version                          2.8.0.0
    * @since                            Jul-01-2019
    **************************************************************************************************************************/
    FUNCTION tf_get_all_content
    (
        i_origin    IN VARCHAR2, --Origem: Diagnósticos/Problems
        i_list_type IN VARCHAR2 DEFAULT g_diag_list_searchable
    ) RETURN t_table_diag_cnt;

    /********************************************************************************************************
    * Gets all patient diferential diagnosis registered in the current episode.
    *
    * @return                           Returns a patient's differential diagnoses
    *                                   (used in the final diagnoses screen filter)
    *                        
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            11/09/2014
    ********************************************************************************************************/
    FUNCTION tf_patient_diagnoses_diff RETURN t_coll_diagnosis_config;

    /********************************************************************************************************
    * Gets all patient final diagnosis with 'Confirmed' status registered in the current and previous visits.
    *
    * @return                           Returns a patient's final diagnoses
    *                                   (used in the differential diagnoses screen filter)
    *                        
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            11/09/2014
    ********************************************************************************************************/
    FUNCTION tf_patient_diagnoses_final RETURN t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Gets patient past medical history/Problems and diagnosis registered in problems area information
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Current professional
    * @param i_patient         Patient identifier
    * @param i_criteria        Text to search
    *
    * @return                  Returns t_table_diag_cnt with all information
    *                        
    * @author                  Gisela Couto
    * @version                 2.6.4.2
    * @since                   23/09/2014
    **************************************************************************************************************/
    FUNCTION get_patient_hist_prob
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_criteria IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_diag_cnt;

    /**************************************************************************************************************
    * Gets patient past medical history/Problems and diagnosis registered in problems area information
    *
    * @return                           Returns t_table_diag_cnt with all information
    *                        
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            23/09/2014
    **************************************************************************************************************/
    FUNCTION get_patient_hist_prob RETURN t_table_diag_cnt;

    /**************************************************************************************************************
    * Patient problems and past history table function
    *
    * @return                           Returns a patient's problems and past history
    *                                   (used in the differential and final diagnoses screens filters)
    *                        
    * @author                           Gisela Couro
    * @version                          2.6.4.2
    * @since                            23/09/2014
    **************************************************************************************************************/
    FUNCTION tf_patient_hist_prob(i_filter_diagnosis IN VARCHAR2 DEFAULT pk_alert_constant.g_yes)
        RETURN t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Gets most frequent diagnosis by diagnosis type (C - Chief Complaint, M - Clinical Service)
    *
    * @return                           Returns the most frequent diagnosis table by diagnosis type
    *                        
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            11/09/2014
    **************************************************************************************************************/
    FUNCTION tf_get_diagnosis_by_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_flg_type    IN diagnosis_dep_clin_serv.flg_type%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_text_search IN translation.desc_lang_1%TYPE,
        i_diag_type   IN epis_diagnosis.flg_type%TYPE
    ) RETURN t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Get most frequent patient diagnoses/problems by chief complaint 
    *
    * @return                           Returns the most frequent diagnoses by clinical service
    *                                   (used in the differential and final diagnoses screens filters)
    *                        
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            11/09/2014
    **************************************************************************************************************/
    FUNCTION tf_complaint_diagnoses RETURN t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Get most frequent patient diagnoses/problems by clinical service 
    *
    * @return                           Returns the most frequent diagnoses by clinical service
    *                                   (used in the differential and final diagnoses screens filters)
    *                        
    * @author                           Gisela Couto
    * @version                          2.6.4.2
    * @since                            11/09/2014
    **************************************************************************************************************/
    FUNCTION tf_clin_serv_diagnoses RETURN t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Returns all diagnoses content
    *
    * @return                           Returns the all diagnoses 
    *                                   (used in v_diagnosis_all_content)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2
    * @since                            11/09/2014
    **************************************************************************************************************/
    FUNCTION tf_all_diagnoses RETURN t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Validates if a diagnosis record content is valid considering current terminology configuration
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional information
    * @param i_tbl_epis_diagnosis   Transaccional records IDs
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_diagnoses
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_tbl_epis_diagnosis IN table_number
    ) RETURN t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Validates if a record content is valid considering current terminology configuration
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional information
    * @param i_tbl_transaccional_ids   Transaccional records IDs
    * @param i_task_type               Task type identifier
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_content
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tbl_transaccional_ids IN table_number,
        i_task_type             IN task_type.id_task_type%TYPE
    ) RETURN t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Validates if a past medical history record content is valid considering current terminology configuration
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional information
    * @param i_tbl_transaccional_ids   Transaccional records IDs
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_past_medical_hist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tbl_transaccional_ids IN table_number
    ) RETURN t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Validates if a past surgical history record content is valid considering current terminology configuration
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional information
    * @param i_tbl_transaccional_ids   Transaccional records IDs
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_past_surgic_hist
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tbl_transaccional_ids IN table_number
    ) RETURN t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Validates if a birth history record content is valid considering current terminology configuration
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional information
    * @param i_tbl_transaccional_ids   Transaccional records IDs
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_cong_anomalies
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tbl_transaccional_ids IN table_number
    ) RETURN t_coll_diagnosis_config;

    /**************************************************************************************************************
    * Validates if a problems record content is valid considering current terminology configuration
    *
    * @param i_lang                    Language ID
    * @param i_prof                    Professional information
    * @param i_tbl_transaccional_ids   Transaccional records IDs
    *
    * @return                           Returns the valid content information (does not return invalid records)
    *                        
    * @author                           Sergio Dias
    * @version                          2.6.4.2.2
    * @since                            30/11/2014
    **************************************************************************************************************/
    FUNCTION tf_get_valid_problems
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_tbl_transaccional_ids IN table_number
    ) RETURN t_coll_diagnosis_config;

    FUNCTION tf_concept_by_id_content
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_task_type     IN table_number,
        i_id_content    IN table_varchar,
        i_relation_type IN VARCHAR2
    ) RETURN t_tbl_concept_term;

    FUNCTION get_diagnoses_list
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_text_search              IN VARCHAR2 DEFAULT NULL,
        i_format_text              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_terminologies_task_types IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_tbl_term_task_type       IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_list_type                IN VARCHAR2 DEFAULT g_diag_list_searchable,
        i_tbl_alert_diagnosis      IN table_number DEFAULT NULL,
        i_tbl_terminologies        IN table_varchar DEFAULT NULL,
        i_row_limit                IN NUMBER DEFAULT NULL,
        i_parent_diagnosis         IN diagnosis.id_diagnosis_parent%TYPE DEFAULT NULL,
        i_only_diag_filter_by_prt  IN VARCHAR2 DEFAULT NULL,
        i_tbl_dep_clin_serv        IN table_number DEFAULT NULL,
        i_tbl_clin_serv            IN table_number DEFAULT NULL,
        i_tbl_complaint            IN table_number DEFAULT NULL,
        i_context_type             IN VARCHAR2 DEFAULT pk_ts_logic.k_ctx_type_s_searchable,
        i_diag_area                IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_not_defined
    ) RETURN t_coll_diagnosis_config;

    FUNCTION get_diagnoses_search
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN patient.id_patient%TYPE,
        i_text_search              IN VARCHAR2 DEFAULT NULL,
        i_format_text              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_terminologies_task_types IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_tbl_term_task_type       IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis),
        i_list_type                IN VARCHAR2 DEFAULT g_diag_list_searchable,
        i_tbl_alert_diagnosis      IN table_number DEFAULT NULL,
        i_tbl_terminologies        IN table_varchar DEFAULT NULL,
        i_row_limit                IN NUMBER DEFAULT NULL,
        i_parent_diagnosis         IN diagnosis.id_diagnosis_parent%TYPE DEFAULT NULL,
        i_only_diag_filter_by_prt  IN VARCHAR2 DEFAULT NULL,
        i_tbl_dep_clin_serv        IN table_number DEFAULT NULL,
        i_tbl_clin_serv            IN table_number DEFAULT NULL,
        i_tbl_complaint            IN table_number DEFAULT NULL,
        i_tbl_adiags_exclude       IN table_number DEFAULT NULL,
        i_context_type             IN VARCHAR2 DEFAULT pk_ts_logic.k_ctx_type_s_searchable,
        i_diag_area                IN VARCHAR2 DEFAULT pk_alert_constant.g_diag_area_not_defined
    ) RETURN t_table_diag_cnt;    

END pk_terminology_search;
/
