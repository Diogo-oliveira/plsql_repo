/*-- Last Change Revision: $Rev: 2028599 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_diagnosis_core IS

    -- Author  : JOSE.SILVA
    -- Created : 30-08-2011 11:34:51

    --Public types declarations
    SUBTYPE flag_type IS VARCHAR2(100 CHAR);

    --
    g_found        BOOLEAN;
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    -- Public variable declarations
    g_diag_other CONSTANT diagnosis.flg_other%TYPE := 'Y';

    g_filter_complaint CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_filter_freq      CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_filter_pesq      CONSTANT VARCHAR2(1 CHAR) := 'P';

    g_flat_mode CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_tree_mode CONSTANT VARCHAR2(1 CHAR) := 'T';

    g_diag_select   CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_diag_select_m CONSTANT VARCHAR2(1 CHAR) := 'M';

    g_diag_call_viewer CONSTANT VARCHAR2(1 CHAR) := 'V';

    g_action_edit     CONSTANT action.from_state%TYPE := 'E';
    g_action_cancel   CONSTANT action.from_state%TYPE := 'C';
    g_action_reassess CONSTANT action.from_state%TYPE := 'R';

    g_cfg_single_prim_diag CONSTANT sys_config.id_sys_config%TYPE := 'SINGLE_PRIMARY_DIAGNOSIS';
    g_cfg_rows_limit       CONSTANT sys_config.id_sys_config%TYPE := 'NUM_RECORD_SEARCH';

    g_def_rows_limit CONSTANT PLS_INTEGER := 150;

    g_diag_create_mode           CONSTANT VARCHAR2(1) := 'D'; --Diagnosis creation
    g_diag_edit_mode_status      CONSTANT VARCHAR2(1) := 'S'; --Diagnosis Status edit
    g_diag_edit_mode_type        CONSTANT VARCHAR2(1) := 'T'; --Diagnosis Type edit
    g_diag_edit_mode_edit        CONSTANT VARCHAR2(1) := 'E'; --Diagnosis edition
    g_diag_edit_mode_retreatment CONSTANT VARCHAR2(1) := 'R'; --Cancer diagnosis retreatment - Add new staging
    g_diag_edit_mode_staging     CONSTANT VARCHAR2(1) := 'G'; --Cancer diagnosis - Staging edition

    g_diag_cancel_diag    CONSTANT VARCHAR2(1) := 'C'; --Cancel diagnosis
    g_diag_cancel_staging CONSTANT VARCHAR2(1) := 'H'; --Cancer diagnosis - Cancel staging

    g_staging_retreatment_type CONSTANT VARCHAR2(1) := 'R';
    g_staging_other_type       CONSTANT VARCHAR2(1) := 'O';

    -- CONCEPT TYPES    
    g_cancer_type CONSTANT diagnosis.concept_type_int_name%TYPE := 'CANCER_DIAGNOSIS';
    g_diagn_type  CONSTANT diagnosis.concept_type_int_name%TYPE := 'DIAGNOSIS';
    g_trauma_type CONSTANT diagnosis.concept_type_int_name%TYPE := 'CONSEQUENCE_OF_EXTERNAL_CAUSE';

    g_diag_type_cancer    CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_diag_type_acc_emerg CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_diag_type_diag      CONSTANT VARCHAR2(1 CHAR) := 'D';

    g_diag_preferred_term  CONSTANT alert_diagnosis.flg_icd9%TYPE := 'Y';
    g_diag_reportable_term CONSTANT alert_diagnosis.flg_icd9%TYPE := 'R';
    g_diag_synonym_term    CONSTANT alert_diagnosis.flg_icd9%TYPE := 'N';

    -- STAGING RETURN TYPES
    g_stage_ret_full_info CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_stage_ret_only_ids  CONSTANT VARCHAR2(1 CHAR) := 'I';

    g_diag_list_searchable     CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_diag_list_most_freq      CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_diag_list_preg_most_freq CONSTANT VARCHAR2(1 CHAR) := 'G';

    g_most_freq_diag CONSTANT diagnosis_content.flg_type_dep_clin%TYPE := 'M';
    g_most_freq_preg CONSTANT diagnosis_content.flg_type_dep_clin%TYPE := 'G';

    -- DIAGNOSES SEARCH CONSTANT ARGS
    g_namespace_diag_search CONSTANT VARCHAR2(200 CHAR) := 'DIAGNOSES_SEARCH';

    g_institution              CONSTANT VARCHAR2(200 CHAR) := 'INSTITUTION';
    g_software                 CONSTANT VARCHAR2(200 CHAR) := 'SOFTWARE';
    g_language                 CONSTANT VARCHAR2(200 CHAR) := 'LANGUAGE';
    g_pat_age                  CONSTANT VARCHAR2(200 CHAR) := 'PAT_AGE';
    g_pat_gender               CONSTANT VARCHAR2(200 CHAR) := 'PAT_GENDER';
    g_tbl_flg_terminologies    CONSTANT VARCHAR2(200 CHAR) := 'TBL_FLG_TERMINOLOGIES';
    g_term_task_type           CONSTANT VARCHAR2(200 CHAR) := 'TERM_TASK_TYPE';
    g_flg_type_alert_diagnosis CONSTANT VARCHAR2(200 CHAR) := 'FLG_TYPE_ALERT_DIAGNOSIS';
    g_flg_type_dep_clin        CONSTANT VARCHAR2(200 CHAR) := 'FLG_TYPE_DEP_CLIN';
    g_synonym_list_enable      CONSTANT VARCHAR2(200 CHAR) := 'SYNONYM_LIST_ENABLE';
    g_include_other_diagnosis  CONSTANT VARCHAR2(200 CHAR) := 'INCLUDE_OTHER_DIAGNOSIS';
    g_only_other_diags         CONSTANT VARCHAR2(200 CHAR) := 'ONLY_OTHER_DIAGS';
    g_tbl_dep_clin_serv        CONSTANT VARCHAR2(200 CHAR) := 'TBL_DEP_CLIN_SERV';
    g_tbl_diagnosis            CONSTANT VARCHAR2(200 CHAR) := 'TBL_DIAGNOSIS';
    g_tbl_alert_diagnosis      CONSTANT VARCHAR2(200 CHAR) := 'TBL_ALERT_DIAGNOSIS';
    g_row_limit                CONSTANT VARCHAR2(200 CHAR) := 'ROW_LIMIT';
    g_parent_diagnosis         CONSTANT VARCHAR2(200 CHAR) := 'PARENT_DIAGNOSIS';
    g_only_diag_filter_by_prt  CONSTANT VARCHAR2(200 CHAR) := 'ONLY_DIAG_FILTER_BY_PRT';
    g_validate_max_age         CONSTANT VARCHAR2(200 CHAR) := 'VALIDATE_MAX_AGE';
    g_terminologies_lang       CONSTANT VARCHAR2(200 CHAR) := 'TERMINOLOGIES_LANG';
    g_text_search              CONSTANT VARCHAR2(200 CHAR) := 'TEXT_SEARCH';
    g_format_text              CONSTANT VARCHAR2(200 CHAR) := 'FORMAT_TEXT';
    g_tbl_dcs_has_rows         CONSTANT VARCHAR2(200 CHAR) := 'TBL_DEP_CLIN_SERV_HAS_ROWS';
    g_tbl_diag_has_rows        CONSTANT VARCHAR2(200 CHAR) := 'TBL_DIAGNOSIS_HAS_ROWS';
    g_tbl_adiag_has_rows       CONSTANT VARCHAR2(200 CHAR) := 'TBL_ALERT_DIAGNOSIS_HAS_ROWS';

    g_scope_patient CONSTANT VARCHAR2(1) := 'P';
    g_scope_visit   CONSTANT VARCHAR2(1) := 'V';
    g_scope_episode CONSTANT VARCHAR2(1) := 'E';

    g_cfg_synonym_list_enable CONSTANT sys_config.id_sys_config%TYPE := 'DIAGNOSIS_SYNONYMS_LIST_ENABLE';

    g_preg_out_type_a CONSTANT VARCHAR2(2 CHAR) := 'AB'; -- abortion;
    g_preg_out_type_d CONSTANT VARCHAR2(1 CHAR) := 'B'; -- delivery;
    g_preg_out_type_b CONSTANT VARCHAR2(2 CHAR) := 'BT'; -- both (abortion and delivery);

    TYPE t_rec_diagnosis_notes_cda IS RECORD(
        id_diagnosis_notes epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        diagnosis_notes    epis_diagnosis_notes.notes%TYPE,
        dt_reg_str         VARCHAR2(14 CHAR),
        dt_reg_tstz        epis_diagnosis_notes.dt_create%TYPE,
        dt_reg_formatted   VARCHAR2(1000 CHAR));

    TYPE t_coll_diagnosis_notes_cda IS TABLE OF t_rec_diagnosis_notes_cda;

    /**
    * Check if diagnosis is registered by area
    *
    * @param i_lang                Language identifier
    * @param i_prof                Professional identifier
    * @param i_episode             Episode identifier
    * @param i_diagnosis           Diagnosis identifier
    * @param i_flg_type            Diagnosis type
    * @param i_desc_diag           Diagnosis description
    * @param i_diagnosis_condition Diagnosis condition id
    * @param i_sub_analysis        Sub analisys identifier
    * @param i_anatomical_area     Anatomical area id
    * @param i_anatomical_side     Anatomical side ir
    *
    * @return               'Y' - yes; 'N' - no
    *
    * @author               Gisela Couto
    * @version              2.6.4.2.1
    * @since                2014/10/17
    */
    FUNCTION check_if_diag_registered
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_diagnosis           IN epis_diagnosis.id_diagnosis%TYPE,
        i_flg_type            IN epis_diagnosis.flg_type%TYPE,
        i_desc_diag           IN epis_diagnosis.desc_epis_diagnosis%TYPE,
        i_diagnosis_condition IN epis_diagnosis.id_diagnosis_condition%TYPE,
        i_sub_analysis        IN epis_diagnosis.id_sub_analysis%TYPE,
        i_anatomical_area     IN epis_diagnosis.id_anatomical_area%TYPE,
        i_anatomical_side     IN epis_diagnosis.id_anatomical_side%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the terminologies available in the given functionality
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_task_type                 Functionality id
    *
    * @return  Terminologies flags table
    *
    * @author  Alexandre Santos
    * @version v2.6.3
    * @since   05-11-2013
    */
    FUNCTION get_diag_terminologies
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN task_type.id_task_type%TYPE DEFAULT pk_alert_constant.g_task_diagnosis
    ) RETURN table_varchar;

    /**
    * Get the terminologies data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_tbl_task_type             Table with functionalities id's
    *
    * @return  Table with terminologies data
    *
    * @author  Alexandre Santos
    * @version v2.6.3
    * @since   05-11-2013
    */
    FUNCTION tf_diag_terminologies
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_tbl_task_type IN table_number DEFAULT table_number(pk_alert_constant.g_task_diagnosis)
    ) RETURN t_table_terminology;

    /**
    * Get the terminologies data
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_tbl_task_type             Table with functionalities id's
    * @param   i_id_content                Tabe with id contents
    *
    * @return  Table with terminologies data
    *
    * @author  Pedro Fernandes
    * @version v2.6.5.0.6
    * @since   06-10-2015
    */
    FUNCTION tf_diag_terminologies
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_tbl_task_type  IN table_number,
        i_tbl_id_content IN table_varchar,
        i_relation_type  IN VARCHAR2
    ) RETURN t_table_diag_terminology;
    /**********************************************************************************************
    * Get the type of diagnosis
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_concept_type           concept type (specified during content creation)
    * @param i_diagnosis              diagnosis ID
    *
    * @return                         Diagnosis type: C - Cancer
    *                                                 A - Accident and Emergency
    *                                                 D - Diagnosis
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3
    * @since                          08-08-2013
    **********************************************************************************************/
    FUNCTION get_diag_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_concept_type IN diagnosis.concept_type_int_name%TYPE,
        i_diagnosis    IN diagnosis.id_diagnosis%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Checks if a specific diagnosis is a cancer diagnosis
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_concept_type           concept type (specified during content creation)
    * @param i_diagnosis              diagnosis ID
    *
    * @return                         Is it a cancer diagnosis? (Y)es or (N)o
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          29-02-2012
    **********************************************************************************************/
    FUNCTION check_diag_cancer
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_concept_type IN diagnosis.concept_type_int_name%TYPE,
        i_diagnosis    IN diagnosis.id_diagnosis%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get node and leaf internal name
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_diag_type              Diagnosis type
    *
    * @i_diag_type                    C - Cancer
    *                                 A - Accident and Emergency
    *                                 D - Diagnosis
    *
    * @return                         Leaf path
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3
    * @since                          22-08-2013
    **********************************************************************************************/
    FUNCTION get_ds_leaf_path
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_diag_type           IN VARCHAR2,
        i_allow_complications IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB;

    /**********************************************************************************************
    * Get node and leaf internal name
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_diagnosis              Diagnosis id
    *
    * @return                         Leaf path
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3
    * @since                          02-04-2014
    **********************************************************************************************/
    FUNCTION get_ds_leaf_path
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE
    ) RETURN CLOB;

    /**********************************************************************************************
    * Get diagnoses types
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_tbl_diagnosis          Table of diagnosis id's
    * @param o_diag_type              For each received diagnosis tells the diagnosis type and ds leaf path
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.3
    * @since                          22-08-2013
    **********************************************************************************************/
    FUNCTION get_diag_type
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_tbl_diagnosis IN table_number,
        o_diag_type     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets the history specific notes
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids 
    * @param i_epis_diagnosis         episode diagnosis ID           
    * @param i_dt_creation            history creation date
    * @param i_flg_status             history diagnosis status
    * @param i_notes                  history diagnosis notes
    *
    * @return                         specific notes
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/11/06
    **********************************************************************************************/
    FUNCTION get_hist_specific_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_diagnosis IN epis_diagnosis_hist.id_epis_diagnosis%TYPE,
        i_dt_creation    IN epis_diagnosis_hist.dt_creation_tstz%TYPE,
        i_flg_status     IN epis_diagnosis_hist.flg_status%TYPE,
        i_notes          IN epis_diagnosis_hist.notes%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets the register date of a diagnosis
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids 
    * @param i_flg_status             episode diagnosis status           
    * @param i_dt_epis_diagnosis      diagnosis date (in investigation)
    * @param i_dt_confirmed           diagnosis date (confirmed)
    * @param i_dt_cancel              diagnosis date (cancelled)
    * @param i_dt_base                diagnosis date (base)
    * @param i_dt_rulled_out          diagnosis date (rulled out)
    *
    * @return                         record date
    *                        
    * @author                         José Silva
    * @version                        2.6.1.3 
    * @since                          13-10-2011
    **********************************************************************************************/
    FUNCTION get_dt_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_status        IN epis_diagnosis.flg_status%TYPE,
        i_dt_epis_diagnosis IN epis_diagnosis.dt_epis_diagnosis_tstz%TYPE,
        i_dt_confirmed      IN epis_diagnosis.dt_confirmed_tstz%TYPE,
        i_dt_cancel         IN epis_diagnosis.dt_cancel_tstz%TYPE,
        i_dt_base           IN epis_diagnosis.dt_base_tstz%TYPE,
        i_dt_rulled_out     IN epis_diagnosis.dt_rulled_out_tstz%TYPE
    ) RETURN epis_diagnosis.dt_epis_diagnosis_tstz%TYPE;

    /**********************************************************************************************
    * Gets the professional that registered the diagnosis
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids 
    * @param i_flg_status             episode diagnosis status           
    * @param i_professional_diag      professional ID (in investigation)
    * @param i_prof_confirmed         professional ID (confirmed)
    * @param i_professional_cancel    professional ID (cancelled)
    * @param i_prof_base              professional ID (base)
    * @param i_prof_rulled_out        professional ID (rulled out)
    *
    * @return                         professional ID
    *                        
    * @author                         José Silva
    * @version                        2.6.1.3 
    * @since                          13-10-2011
    **********************************************************************************************/
    FUNCTION get_prof_diagnosis
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_status          IN epis_diagnosis.flg_status%TYPE,
        i_professional_diag   IN epis_diagnosis.id_professional_diag%TYPE,
        i_prof_confirmed      IN epis_diagnosis.id_prof_confirmed%TYPE,
        i_professional_cancel IN epis_diagnosis.id_professional_cancel%TYPE,
        i_prof_base           IN epis_diagnosis.id_prof_base%TYPE,
        i_prof_rulled_out     IN epis_diagnosis.id_prof_rulled_out%TYPE
    ) RETURN epis_diagnosis.id_professional_diag%TYPE;

    /********************************************************************************************
    * Get the last history ID of an episode diagnosis record
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional identification and its context (institution and software)
    * @param i_epis_diagnosis         Episode diagnosis ID
    * 
    * @return                         Diagnosis history ID
    * 
    * @author                         José Silva
    * @version                        2.6.1.2   
    * @since                          2007/09/21
    **********************************************************************************************/
    FUNCTION get_last_epis_diag_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE;
    --  
    /********************************************************************************************
    * builds a standard formatted diagnosis description that is displayed to the user (with or without code and synonym indication)
    *
    * @param i_lang           language id
    * @param i_prof           professional id (type: professional id, institution id and software id)
    * @param i_desc           diagnosis description
    * @param i_code           diagnosis code
    * @param i_flg_other      flag which indicates if the diagnosis is "Other" or an official one
    * @param i_flg_std_diag   flag which indicates if the diagnosis is the standard one or one of the synonyms
    * @param i_epis_diag      When filled adds additional information to diagnosis, for instance, the state description and date (ALERT-81543)
    * @param i_flg_past_hist  Show the description in the past history area: Yes or No
    * @param i_ed_rowtype     Row type sent in Global search trigger
    * @param i_flg_show_if_principal   Show 'Principal diagnosis' when aplicable, i_show_aditional_info as to be 'Y'
    * @param i_flg_status              For show Active,Inactive... status
    * @param i_flg_type                For show problem-P,past hisotry medical-H
    * 
    * @return                 formatted text containing the diagnosis description
    * 
    * @author                 Sergio Dias
    * @version                2.0
    * @since                  7/Fev/2012
    **********************************************************************************************/
    FUNCTION std_diag_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_diagnosis          IN diagnosis.id_diagnosis%TYPE DEFAULT NULL,
        i_desc                  IN pk_translation.t_desc_translation,
        i_code                  IN diagnosis.code_icd%TYPE,
        i_flg_other             IN diagnosis.flg_other%TYPE,
        i_flg_std_diag          IN alert_diagnosis.flg_icd9%TYPE,
        i_epis_diag             IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_show_aditional_info   IN VARCHAR2,
        i_flg_past_hist         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_search_mode       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_term_code    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_ae_diag_info IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_ed_rowtype            IN epis_diagnosis%ROWTYPE DEFAULT NULL,
        i_flg_show_if_principal IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_show_dt_initial   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_status            IN VARCHAR2 DEFAULT NULL,
        i_flg_type              IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;
    --  
    /************************************************************************************************************
    * Gets the diagnosis description that is displayed to the user in a specific task and institution language
    *
    * @param i_lang                    language id
    * @param i_prof                    professional id (type: professional id, institution id and software id)
    * @param i_id_alert_diagnosis      alert_diagnosis id
    * @param i_code_diagnosis          Diagnosis code for translation
    * @param i_diagnosis_language      Diagnosis Language
    * @param i_id_task_type            Task Type ID
    *
    * @return                          text containing the diagnosis description
    * 
    * @author                 Sergio Dias
    * @version                1.0   
    * @since                  13/Fev/2012
    *************************************************************************************************************/
    FUNCTION get_alert_diag_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE,
        i_code_diagnosis     IN diagnosis.code_diagnosis%TYPE DEFAULT NULL,
        i_diagnosis_language IN language.id_language%TYPE DEFAULT NULL,
        i_id_task_type       IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2;
    --    
    /**********************************************************************************************
    * Gets the list of complications available in the pregnancy record creation/edition 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_show_diagnosis         shows diagnosis list: Y - yes, N - no 
    *
    * @return                         diagnosis ID and description
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2011/03/25
    **********************************************************************************************/
    FUNCTION get_pregn_diag_diff_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_show_diagnosis IN VARCHAR2
    ) RETURN t_coll_values_domain_mkt;

    /********************************************************************************************
    * Function that returns diagnosis for an episode array
    * Note : used in admission surgery request functionality
    * Based in get_epis_diag function
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_id_episode             Array of episode ID
    * @param i_show_cancelled         Show cancelled/rulled out records: (Y)es or (N)o
    *
    * @param o_diag                   Cursor with diagnoses' information
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         Filipe Silva
    * @version                        2.5.1.5  
    * @since                          2011/03/31
    **********************************************************************************************/
    FUNCTION get_epis_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN table_number,
        i_show_cancelled IN VARCHAR2,
        o_diag           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    --
    /********************************************************************************************
    * Function that gives all the information registered in a diagnosis record
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param i_epis_diag_hist         episode diagnosis ID (history record)
    *
    * @return                         diagnosis general info
    *
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2012/02/27
    **********************************************************************************************/
    FUNCTION get_epis_diag
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diag_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE
    ) RETURN pk_edis_types.rec_epis_diagnosis;
    --
    /********************************************************************************************
    * Function that returns diagnosis based on an record of Episode diagnosis records
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_epis_diag              Array of episode diagnosis ID
    * @param i_epis_diag_hist         Show cancelled/rulled out records: (Y)es or (N)o
    * @param o_epis_diag              Cursor with diagnoses' information
    * @param o_error                  Error message
    *
    * @return                         true or false
    *
    * @author                         José Silva
    * @version                        2.6.1.2  
    * @since                          2011/09/20
    **********************************************************************************************/
    FUNCTION get_epis_diag_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_diag      IN table_number,
        i_epis_diag_hist IN table_number,
        o_epis_diag      OUT pk_edis_types.p_epis_diagnosis_cur,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diagnosis_path
    (
        i_lang      IN language.id_language%TYPE,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE,
        i_diag_mode IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
    * Get final diagnoses (entries info) of patient's family members. 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_current_episode    Current episode ID
    * @param   i_patient            Patient ID
    * @param   i_order              Indicates the chronological order of records returned ('ASC' Ascending , 'DESC' Descending) Default 'DESC'
    *
    * @return  Information about entries (professional, record date, status, etc.)
    *
    * @author  ARIEL.MACHADO
    * @version v2.6.0.4
    * @since   11/22/2010
    */
    FUNCTION tf_final_diag_pat_family_reg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_current_episode IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_order           IN VARCHAR2 DEFAULT 'DESC'
    ) RETURN pk_touch_option.t_coll_doc_area_register
        PIPELINED;

    /**
    * Get final diagnoses (entries values) of patient's family members. 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_patient            Patient ID
    *
    * @return  Information about data values saved in entries
    *
    * @author  ARIEL.MACHADO
    * @version v2.6.0.4
    * @since   11/22/2010
    */
    FUNCTION tf_final_diag_pat_family_val
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN pk_touch_option.t_coll_doc_area_val
        PIPELINED;

    /**********************************************************************************************
    * Get the histology code based in the morphology ID
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_morphology             morphology ID
    *
    * @return                         histology description
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2012/03/27
    **********************************************************************************************/
    FUNCTION get_code_histology
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_morphology IN diagnosis.id_diagnosis%TYPE
    ) RETURN diagnosis.code_icd%TYPE;

    /**********************************************************************************************
    * Get the formatted icdo diagnosis
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_code_topography        topography concept code
    * @param i_code_histology         histology concept code
    * @param i_code_behaviour         behaviour concept code
    * @param i_code_hist_grade        histological grade code
    * @param i_desc_morphology        morphology description
    * @param i_desc_topography        topography description
    *
    * @return                         diagnosis description based in the ICDO standard
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2012/03/27
    **********************************************************************************************/
    FUNCTION get_desc_diag_icdo
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_code_topography IN diagnosis.code_icd%TYPE,
        i_code_histology  IN diagnosis.code_icd%TYPE,
        i_code_behaviour  IN diagnosis.code_icd%TYPE,
        i_code_hist_grade IN diagnosis.code_icd%TYPE,
        i_desc_morphology IN VARCHAR2,
        i_desc_topography IN VARCHAR2
    ) RETURN diagnosis.code_icd%TYPE;

    /********************************************************************************************
    * Function that gives the staging general info of a specific diagnosis
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_flg_call               screen which called this method: V - viewer, D - detail
    * @param i_epis_diag              episode diagnosis ID
    * @param i_epis_diag_hist         episode diagnosis ID (history record)
    * @param i_flg_ret_type           type of info to return: F - full info, I - only IDs
    *
    * @return                         staging records
    *
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2012/02/23
    **********************************************************************************************/
    FUNCTION get_epis_diag_stagings
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_call       IN VARCHAR2,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diag_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        i_flg_ret_type   IN VARCHAR2 DEFAULT 'F'
    ) RETURN pk_edis_types.tab_epis_diag_staging;

    /********************************************************************************************
    * Function that gives all the information registered in a diagnosis record
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param i_epis_diag_hist         episode diagnosis ID (history record)
    * @param i_rec_epis_stag          staging record (calculated earlier before fetching the rest of the diagnosis info)
    * @param o_rec_epis_stag          staging record
    * @param o_tab_epis_tumors        tumors data
    * @param o_rec_epis_diag          diagnosis general info
    * @param o_error                  Error message
    *
    * @return                         true or false
    *
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2012/02/27
    **********************************************************************************************/
    FUNCTION get_epis_diag_rec
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_epis_diag           IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diag_hist      IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        i_rec_epis_stag       IN pk_edis_types.rec_epis_diag_staging,
        i_flg_edit_mode       IN VARCHAR2 DEFAULT NULL,
        o_rec_epis_stag       OUT pk_edis_types.rec_epis_diag_staging,
        o_tab_epis_tumors     OUT pk_edis_types.tab_epis_diag_tumors,
        o_rec_epis_diag       OUT pk_edis_types.rec_epis_diagnosis,
        o_tab_epis_diag_compl OUT pk_edis_types.table_out_complications,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that gives all the information registered in a diagnosis record
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_epis_diag              episode diagnosis ID
    * @param i_epis_diag_hist         episode diagnosis ID (history record)
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_epis_diag_rec
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_epis_diag_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE DEFAULT NULL
    ) RETURN pk_edis_types.rec_in_epis_diagnosis;

    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_params                 Table of XML with all input parameters
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_params IN table_clob
    ) RETURN pk_edis_types.table_in_epis_diagnosis;

    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                patient ID
    * @param i_episode                episode ID
    * @param i_diagnosis              Table with diagnosis ID
    * @param i_task_type              task type ID
    * @param i_cdr_call               cdr call ID
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_diagnosis       IN table_table_number,
        i_alert_diagnosis IN table_table_number DEFAULT NULL,
        i_desc_diag       IN table_table_varchar DEFAULT NULL,
        i_task_type       IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call        IN cdr_call.id_cdr_call%TYPE DEFAULT NULL
    ) RETURN pk_edis_types.table_in_epis_diagnosis;

    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                patient ID
    * @param i_episode                episode ID
    * @param i_diagnosis              Table with diagnosis ID
    * @param i_task_type              task type ID
    * @param i_cdr_call               cdr call ID
    * @param i_id_epis_diagnosis      epis_diagnosis ID
    * @param i_flg_status             Table with diagnosis status
    * @param i_spec_notes             Table with diagnosis notes
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_diagnosis         IN table_number,
        i_alert_diagnosis   IN table_number DEFAULT NULL,
        i_desc_diag         IN table_varchar DEFAULT NULL,
        i_task_type         IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call          IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_flg_status        IN table_varchar DEFAULT NULL,
        i_spec_notes        IN table_varchar DEFAULT NULL,
        i_dt_diag           IN table_varchar DEFAULT NULL
    ) RETURN pk_edis_types.rec_in_epis_diagnosis;

    /********************************************************************************************
    * Returns the epis diagnosis record used as input parameter in save functions with the default values
    * for the given diagnosis
    * ATTENTION: This function shouldn't be used by default, please consult EDIS team before using it
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_patient                patient ID
    * @param i_episode                episode ID
    * @param i_diagnosis              diagnosis ID
    * @param i_task_type              task type ID
    * @param i_cdr_call               cdr call ID
    * @param i_id_epis_diagnosis      epis_diagnosis ID
    * @param i_flg_status             Diagnosis status
    * @param i_spec_notes             Diagnosis notes
    *
    * @return                         Epis diagnosis record used as input parameter in save functions
    *
    * @author                         Alexandre Santos
    * @version                        2.6.2
    * @since                          2012/03/21
    **********************************************************************************************/
    FUNCTION get_diag_rec
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_diagnosis         IN diagnosis.id_diagnosis%TYPE,
        i_alert_diagnosis   IN alert_diagnosis.id_alert_diagnosis%TYPE DEFAULT NULL,
        i_desc_diag         IN epis_diagnosis.desc_epis_diagnosis%TYPE DEFAULT NULL,
        i_task_type         IN NUMBER DEFAULT pk_alert_constant.g_task_diagnosis,
        i_cdr_call          IN cdr_call.id_cdr_call%TYPE DEFAULT NULL,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_flg_status        IN epis_diagnosis.flg_status%TYPE DEFAULT NULL,
        i_spec_notes        IN epis_diagnosis.notes%TYPE DEFAULT NULL
    ) RETURN pk_edis_types.rec_in_epis_diagnosis;

    /********************************************************************************************
    * Function that gives the staging general info of a specific diagnosis
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param i_flg_call               screen which called this method: V - viewer, D - detail
    * @param o_epis_diagnosis         diagnosis data
    * @param o_error                  error message
    *
    * @return                         true or false
    *
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          2012/02/27
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_flg_call       IN VARCHAR2,
        o_epis_diagnosis OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the diagnosis info to be placed in the viewer grid
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                patient id
    * @param i_episode                episode id
    * @param i_epis_diag              diagnosis episode id
    * @param o_diag_staging           diangosis staging info
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          29-Mar-2012
    **********************************************************************************************/
    FUNCTION get_diag_viewer_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_epis_diag    IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_diag_staging OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get staging basis type based on the given id
    *
    * @param i_staging_basis          Staging basis id
    *
    * @return                         Staging basis type
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.2.1 
    * @since                          2012/03/09
    **********************************************************************************************/
    FUNCTION get_staging_basis_type
    (
        i_prof          IN profissional,
        i_staging_basis IN epis_diag_stag.id_staging_basis%TYPE
    ) RETURN flag_type;

    /**********************************************************************************************
    * Get staging basis number, if it's a retreatment it will increment the current saved value 
    * otherwise it will return the saved value or if there is no saved value the default one
    *
    * @param i_epis_diagnosis         Epis diagnosis id
    * @param i_epis_diagnosis_hist    Epis diagnosis hist id
    * @param i_staging_basis          Staging basis id
    * @param i_flg_edit_mode          Edit mode
    *
    * @return                         Staging basis number that will be saved in DB
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.2.1 
    * @since                          2012/03/09
    **********************************************************************************************/
    FUNCTION get_staging_basis_num
    (
        i_prof                IN profissional,
        i_epis_diagnosis      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diagnosis_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        i_staging_basis       IN epis_diag_stag.id_staging_basis%TYPE,
        i_flg_edit_mode       IN flag_type
    ) RETURN epis_diag_stag.num_staging_basis%TYPE;

    /**********************************************************************************************
    * Get staging basis rank
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_staging_basis          Staging basis id
    *
    * @return                         Staging basis rank
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.2.1 
    * @since                          2012/03/09
    **********************************************************************************************/
    FUNCTION get_staging_basis_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_staging_basis IN epis_diag_stag.id_staging_basis%TYPE
    ) RETURN diagnosis_ea.rank%TYPE;

    /**********************************************************************************************
    * Checks if a given staging basis is available for registration
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_staging_basis          Staging basis id
    * @param i_epis_st_basis          List of staging basis registered in the episode
    * @param i_flg_edit_mode          type of edition (values available as constants in the package SPEC)
    *
    * @return                         Staging basis is available: (Y)es or (N)o
    *                        
    * @author                         Alexandre Santos
    * @version                        2.6.2.1 
    * @since                          2012/Apr/02
    **********************************************************************************************/
    FUNCTION check_staging_basis_avail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_staging_basis IN epis_diag_stag.id_staging_basis%TYPE,
        i_epis_st_basis IN pk_edis_types.tab_epis_diag_staging,
        i_flg_edit_mode IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    **********************************************************************************************/
    PROCEDURE add_output_param
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_epis_diagnosis      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diagnosis_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE,
        i_tumor_num           IN epis_diag_tumors.tumor_num%TYPE DEFAULT NULL,
        i_tumor_num_hist      IN epis_diag_tumors.tumor_num%TYPE DEFAULT NULL,
        i_diag_stag           IN epis_diag_stag.num_staging_basis%TYPE DEFAULT NULL,
        i_diag_stag_hist      IN epis_diag_stag.num_staging_basis%TYPE DEFAULT NULL,
        i_stag_pfactor        IN epis_diag_stag_pfact.id_field%TYPE DEFAULT NULL,
        i_stag_pfactor_hist   IN epis_diag_stag_pfact.id_field%TYPE DEFAULT NULL,
        i_dt_record           IN epis_diagnosis_hist.dt_creation_tstz%TYPE,
        i_id_complication     epis_diag_complications.id_complication%TYPE DEFAULT NULL,
        i_comp_description    VARCHAR2 DEFAULT NULL,
        i_comp_code           VARCHAR2 DEFAULT NULL,
        i_comp_rank           epis_diag_complications.rank%TYPE DEFAULT NULL,
        i_problem_msg         IN VARCHAR2 DEFAULT NULL,
        i_problem_msg_title   IN VARCHAR2 DEFAULT NULL,
        i_problem_flg_show    IN VARCHAR2 DEFAULT NULL,
        i_problem_button      IN VARCHAR2 DEFAULT NULL,
        io_params             IN OUT NOCOPY pk_edis_types.table_out_epis_diags
    );

    /********************************************************************************************
    * Verifies if there are diagnoses registered on episodes of the same visit/previsous episode and adds them to the new episode
    * This function will be call whenever is created a new episode and whenever it's added or edited a diagnosis
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                Episode ID
    * @param i_tbl_epis_diagnosis     Epis diagnosis ID's created or changed; 
    *                                 If this column is null or the table_number has 0 elements means that's a new episode 
    *                                 and it will import the diagnoses of the the same visit/previous episode
    * @param o_error                  Error message
    *
    * @return                         true or false para sucesso ou erro
    *
    * @author                         Alexandre Santos
    * @version                        1.0   
    * @since                          2010/01/25
    **********************************************************************************************/
    FUNCTION set_visit_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_tbl_epis_diagnosis IN pk_edis_types.table_out_epis_diags,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Encapsulates the logic of saving (create/update/cancel) a diagnosis
    * (CALLED BY: PL/SQL)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_epis_diagnoses        Epis diagnoses record
    * @param   o_params                Output parameters record
    * @param   o_error                 Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    *
    * @author  Alexandre Santos
    * @version 2.6.2.1
    * @since   27-02-2012
    */
    FUNCTION set_epis_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis_diagnoses IN pk_edis_types.rec_in_epis_diagnoses,
        o_params         OUT pk_edis_types.table_out_epis_diags,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the options for the actions button in the diagnosis grid 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis_diagnosis         episode diagnosis ID
    * @param o_diag_actions           actions list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          27-02-2012
    **********************************************************************************************/
    FUNCTION get_diag_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_diag_actions   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the most recent note registered in the episode 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode ID
    * @param i_epis_diag              episode diagnosis ID
    * @param i_epis_diag_hist         episode diagnosis ID (history record)
    *
    * @return                         diagnosis note
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          29-02-2012
    **********************************************************************************************/
    FUNCTION get_epis_diag_note
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_diag      IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_epis_diag_hist IN epis_diagnosis_hist.id_epis_diagnosis_hist%TYPE
    ) RETURN epis_diagnosis.notes%TYPE;

    /**********************************************************************************************
    * Get the notes registered in the diagnosis area 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode ID
    * @param o_diag_notes             diagnosis notes list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          28-02-2012
    **********************************************************************************************/
    FUNCTION get_epis_diag_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_flg_type   IN epis_diagnosis.flg_type%TYPE DEFAULT NULL,
        o_diag_notes OUT pk_edis_types.t_cur_diag_notes,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Sets the diagnosis notes  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode ID
    * @param i_epis_diag_notes        previous diagnosis notes ID (if it is an edition)
    * @param i_notes                  registered notes
    * @param o_epis_diag_notes        diagnosis notes ID that was saved
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          28-02-2012
    **********************************************************************************************/
    FUNCTION set_epis_diag_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_diag_notes IN epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        i_notes           IN epis_diagnosis_notes.notes%TYPE,
        o_epis_diag_notes OUT epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel the diagnosis notes  
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis_diag_notes        diagnosis notes ID to be cancelled
    * @param i_cancel_reason          cancel reason
    * @param i_notes                  cancel notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          28-02-2012
    **********************************************************************************************/
    FUNCTION cancel_diag_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_epis_diag_notes IN epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        i_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        i_notes           IN epis_diagnosis_notes.notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get all the cancer diagnoses registered previously in a patient
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_patient                Patient id
    * @param o_diags                  Diagnoses description list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/Apr/12
    **********************************************************************************************/
    FUNCTION get_pat_prev_cancer_diag
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_diags   OUT table_varchar,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * List all diagnosis registered in a patient
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_id_patient             Patient id
    * @param i_show_only_cancer       Show only cancer diagnoses: (Y)es or (N)o
    * @param i_order_by_final_type    Order the grid by 
    * @param o_cursor                 Diagnoses list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/Mar/29
    **********************************************************************************************/
    FUNCTION get_pat_diagnosis_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN patient.id_patient%TYPE,
        i_show_only_cancer    IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_order_by_final_type IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_order_by_status     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_cursor              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * List all diagnosis registered in an episode
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param o_list                   Diagnoses list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2012/02/29
    **********************************************************************************************/
    FUNCTION get_epis_diagnosis_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN epis_diagnosis.flg_type%TYPE,
        o_list     OUT NOCOPY pk_edis_types.diagnosis_cur,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_count_epis_diagnosis_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN epis_diagnosis.flg_type%TYPE,
        o_count    OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets all configurations related with diagnosis
    * NOTE: This function makes DML operations so don't use it directly in a query
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_flg_type               Filter type: 
    *                                                      M - most frequent 
    *                                                      C - complaint diagnosis
    * @param i_patient                Patient ID
    * @param i_episode                Episode ID
    *                        
    * @return                         diagnosis list
    * 
    * @author                         José Silva
    * @version                        2.6.2
    * @since                          02-Mar-2012
    **********************************************************************************************/
    FUNCTION tf_get_diag_configurations
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_type  IN diagnosis_dep_clin_serv.flg_type%TYPE,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_diag_type IN epis_diagnosis.flg_type%TYPE,
        i_complaint IN table_number DEFAULT NULL
    ) RETURN t_coll_diagnosis_config;

    /**********************************************************************************************
    * List the most frequent diagnosis of a specific category
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_patient                Patient id
    * @param i_episode                Episode id
    * @param o_diagnosis              Diagnoses list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2012/03/02
    **********************************************************************************************/
    FUNCTION get_freq_diag_cat
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get the diagnosis code 
    *
    * @param i_diagnosis              diagnosis ID (corresponding to ID_CONCEPT_VERSION in the new model)
    * @param i_institution            institution ID
    * @param i_software               software ID
    *
    * @return                         diagnosis code
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/18
    **********************************************************************************************/
    FUNCTION get_diagnosis_code
    (
        i_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN diagnosis_ea.concept_code%TYPE;

    /**********************************************************************************************
    * Get the diagnosis code 
    *
    * @param i_diagnosis              term/alert_diagnosis ID
    * @param i_institution            institution ID
    * @param i_software               software ID
    *
    * @return                         diagnosis code
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/28
    **********************************************************************************************/
    FUNCTION get_term_diagnosis_code
    (
        i_alert_diagnosis IN diagnosis.id_diagnosis%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        i_software        IN software.id_software%TYPE
    ) RETURN diagnosis_ea.concept_code%TYPE;

    /**********************************************************************************************
    * Get the parent diagnosis (to be used in the views that simultate the old column DIAGNOSIS.ID_DIAGNOSIS_PARENT)
    *
    * @param i_diagnosis              diagnosis ID (corresponding to ID_CONCEPT_VERSION in the new model)
    * @param i_institution            institution ID
    * @param i_software               software ID
    *
    * @return                         diagnosis parent ID
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2012/03/07
    **********************************************************************************************/
    FUNCTION get_diagnosis_parent
    (
        i_diagnosis   IN diagnosis.id_diagnosis%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE
    ) RETURN diagnosis.id_diagnosis%TYPE;

    /**********************************************************************************************
    * Get the histology description based in the morphology ID
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_morphology             morphology ID
    *
    * @return                         histology description
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2012/03/18
    **********************************************************************************************/
    FUNCTION get_desc_histology
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_morphology IN diagnosis.id_diagnosis%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the staging group based on the different staging parameteres
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Object (professional ID, institution ID, software ID)
    * @param i_pfactors                  Prognostic factors
    * @param i_tnm                       Registered TNM
    * @param i_show_sgroup_not_avail_msg Show staging group message not available
    *
    * @return                         staging group description/code/ID
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2012/03/19
    **********************************************************************************************/
    FUNCTION get_desc_staging_group
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_pfactors                  IN pk_edis_types.table_in_prog_factor,
        i_tnm                       IN pk_edis_types.rec_in_tnm,
        i_show_sgroup_not_avail_msg IN BOOLEAN DEFAULT FALSE
    ) RETURN pk_edis_types.rec_diag_staging_group;

    /**********************************************************************************************
    * Get the staging group based on the different staging parameteres
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_tnm                    Registered TNM
    *
    * @return                         tnm description
    *
    * @author                         José Silva
    * @version                        1.0
    * @since                          2012/03/19
    **********************************************************************************************/
    FUNCTION get_desc_tnm
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tnm             IN pk_edis_types.rec_in_tnm,
        i_flg_mult_tumors IN epis_diagnosis.flg_mult_tumors%TYPE,
        i_num_prim_tumors IN epis_diagnosis.num_primary_tumors%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the staging info based on the different staging parameteres
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_staging_basis          Staging basis ID
    * @param i_desc_tnm               TNM description
    * @param i_desc_staging_group     Staging group description
    *
    * @return                         tnm description
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/19
    **********************************************************************************************/
    FUNCTION get_desc_staging_info
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_staging_basis      IN diagnosis.id_diagnosis%TYPE,
        i_desc_tnm           IN VARCHAR2,
        i_desc_staging_group IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the options available in the diagnosis filter
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @param i_episode                Episode ID
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param o_options                Filter options
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        1.0   
    * @since                          2011/01/26
    **********************************************************************************************/
    FUNCTION get_diag_filter_options
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_flg_type IN VARCHAR2,
        o_options  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the related diagnosis associated with the diagnosis note
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_episode                Episode ID
    * @param i_dt_diag_notes          Diagnoses notes ID
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         José Silva
    * @version                        2.6.2.1  
    * @since                          2012-Mar-23
    **********************************************************************************************/
    FUNCTION get_note_associated_diags
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_type      IN epis_diagnosis.flg_type%TYPE DEFAULT NULL,
        i_dt_diag_notes IN epis_diagnosis_notes.dt_create%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the diagnosis ID of a specific term
    *
    * @param i_alert_diagnosis        alert_diagnosis/term ID
    * @param i_institution            institution ID
    * @param i_software               software ID
    *
    * @return                         diagnosis ID
    *
    * @author                         José Silva
    * @version                        2.6.2.1
    * @since                          2012/03/26
    **********************************************************************************************/
    FUNCTION get_term_diagnosis_id
    (
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        i_software        IN software.id_software%TYPE
    ) RETURN diagnosis.id_diagnosis%TYPE;

    /**********************************************************************************************
    * get actions of the diagnosis general notes
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_task_request           task request id (monitorization id)
    * @param       o_actions                actions cursor info 
    * @param       o_error                  error message
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                26-Mar-2012
    **********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN epis_diagnosis_notes.id_epis_diagnosis_notes%TYPE,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * get actions of the final diagnosis 
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_task_request           task request id (epis_diagnosis)
    * @param       o_actions                actions cursor info 
    * @param       o_error                  error message
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Sofia Mendes
    * @version                              2.6.3
    * @since                                29-Nov-2012
    **********************************************************************************************/
    FUNCTION get_actions_final_diags
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Return record diagnosis
    *
    * @param       i_rec_epis_diag          Epis diagnosis record
    *
    * @return      t_table_diagnosis        Diagnosis table
    *
    * @author                               Alexandre Santos
    * @version                              2.6.2.1
    * @since                                03-04-2012
    **********************************************************************************************/
    FUNCTION tf_diagnosis(i_rec_epis_diag IN pk_edis_types.rec_in_epis_diagnosis) RETURN t_table_diagnoses;

    /**********************************************************************************************
    * get a existing id_epis_diagnosis according to the input parameters
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_episode                Episode id
    * @param       i_diagnosis              Diagnosis id
    * @param       i_desc_diag              Diagnosis description
    * @param       i_flg_type               Diagnosis type
    *
    * @return      boolean                  id_epis_diagnosis if exists; otherwise NULL
    *
    * @author                               Alexandre Santos
    * @version                              2.6.2
    * @since                                27-06-2012
    **********************************************************************************************/
    FUNCTION get_existing_epis_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_diagnosis IN epis_diagnosis.id_diagnosis%TYPE,
        i_desc_diag IN epis_diagnosis.desc_epis_diagnosis%TYPE,
        i_flg_type  IN epis_diagnosis.flg_type%TYPE
    ) RETURN epis_diagnosis.id_epis_diagnosis%TYPE;

    /**********************************************************************************************
    * Gets an existing id_epis_diagnosis according to the given description and flg_type
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_episode                Episode id
    * @param       i_desc_diag              Diagnosis description
    * @param       i_flg_type               Diagnosis type
    *
    * @return      boolean                  id_epis_diagnosis if exists; otherwise NULL
    *
    **********************************************************************************************/
    FUNCTION get_existing_epis_diag
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_desc_diag IN epis_diagnosis.desc_epis_diagnosis%TYPE,
        i_flg_type  IN epis_diagnosis.flg_type%TYPE
    ) RETURN epis_diagnosis.id_epis_diagnosis%TYPE;

    /**********************************************************************************************
    * get the professional that created the diagnosis
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_id_epis_diagnosis      diagnosis
    *
    * @return      profissional             professional that created diagnosis
    *
    * @author                               Elisabete Bugalho
    * @version                              2.6.3
    * @since                                21-01-2013
    **********************************************************************************************/

    FUNCTION get_prof_create_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN epis_diagnosis.id_professional_diag%TYPE;

    /**********************************************************************************************
    * get the creaded diagnosis date
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_id_epis_diagnosis      diagnosis
    *
    * @return      profissional             professional that created diagnosis
    *
    * @author                               Elisabete Bugalho
    * @version                              2.6.3
    * @since                                21-01-2013
    **********************************************************************************************/

    FUNCTION get_dt_create_diagnosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE
    ) RETURN epis_diagnosis.dt_epis_diagnosis_tstz%TYPE;

    /**********************************************************************************************
    * checks if a given diagnosis was registered in previous episodes
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_patient                patient id
    * @param       i_episode                episode id   
    * @param       i_id_diagnosis           diagnosis id
    * @param       i_id_alert_diagnosis     id alert diagnosis
    *
    * @return      profissional            Y/N
    *
    * @author                               Elisabete Bugalho
    * @version                              2.6.3
    * @since                                25-01-2013
    **********************************************************************************************/

    FUNCTION check_previous_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN epis_diagnosis.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_id_alert_diagnosis IN epis_diagnosis.id_alert_diagnosis%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * List all diagnosis registered in an episode
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param i_criteria               search criteria
    * @param i_format_text            
    *
    * @return                         Diagnoses list
    *
    * @author                               Elisabete Bugalho
    * @version                              2.6.3
    * @since                                21-01-2013
    **********************************************************************************************/
    FUNCTION tb_get_epis_diagnosis_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_scope              IN episode.id_episode%TYPE,
        i_flg_scope             IN VARCHAR2,
        i_flg_type              IN epis_diagnosis.flg_type%TYPE,
        i_criteria              IN VARCHAR2,
        i_format_text           IN VARCHAR2,
        i_translation_desc_only IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_tbl_status            IN table_varchar DEFAULT NULL
    ) RETURN t_coll_episode_diagnosis;

    FUNCTION tb_get_epis_diagnosis_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_scope   IN episode.id_episode%TYPE,
        i_flg_scope  IN VARCHAR2,
        i_flg_type   IN epis_diagnosis.flg_type%TYPE,
        i_tbl_status IN table_varchar DEFAULT NULL
    ) RETURN t_coll_episode_diagnosis;

    /**********************************************************************************************
    * List active diagnosis registered in an episode
    *
    * @param i_lang                   Id language
    * @param i_prof                   Professional, software and institution ids
    * @param i_episode                Episode id
    * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param i_criteria               search criteria
    * @param i_format_text            
    *
    * @return                         Active Diagnoses list
    *
    * @author                               Joel Lopes
    * @version                              2.6.3
    * @since                                12-02-2014
    **********************************************************************************************/
    FUNCTION tb_get_epis_diagnosis_cda
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_pat               IN patient.id_patient%TYPE DEFAULT NULL,
        i_episode           IN episode.id_episode%TYPE,
        i_flg_type          IN epis_diagnosis.flg_type%TYPE,
        i_criteria          IN VARCHAR2,
        i_format_text       IN VARCHAR2,
        i_flg_visit_or_epis IN VARCHAR2 DEFAULT 'E'
    ) RETURN t_coll_episode_diagnosis_cda;

    /********************************************************************************************
    * Function that returns the terminology abbreviation for a diagnosis
    *
    * @param i_lang                   language ID
    * @param id_diagnosis             Diagnosis ID
    *
    * @return                         Translation
    *
    * @author                         Sergio Dias
    * @version                        2.6.3.8.4
    * @since                          Nov/11/2013
    **********************************************************************************************/
    FUNCTION get_terminology_abbreviation
    (
        i_lang       IN language.id_language%TYPE,
        id_diagnosis IN diagnosis.id_diagnosis%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_id_diag_condition
    (
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE
    ) RETURN concept_version.id_concept_version%TYPE;

    FUNCTION get_id_sub_analysis
    (
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE
    ) RETURN concept_version.id_concept_version%TYPE;

    /********************************************************************************************
    * Constroi a descricao do diagnostico que deve ser mostrada (com ou sem codigo)
    *
    * @param i_desc                   Descricao do diagnostico
    * @param i_code                   Codigo do ICD
    * @param i_show_code              Flag que indica se o codigoo do diagnostico deve ser visualizado
    * @param i_flg_other              Flag que indica se o diagnostico e do tipo "outro"
    * @param i_aditional_info         Aditional information regarding the diagnose (ALERT-81543)
    * 
    * @return                         Descricao que vai ser mostrada
    * 
    * @author                         Luis Oliveira
    * @version                        1.0   
    * @since                          2007/06/06
    **********************************************************************************************/
    FUNCTION diag_desc
    (
        i_desc           IN pk_translation.t_desc_translation,
        i_code           IN diagnosis.code_icd%TYPE,
        i_show_code      IN sys_config.value%TYPE,
        i_flg_other      IN diagnosis.flg_other%TYPE,
        i_aditional_info IN VARCHAR2 DEFAULT NULL,
        i_cancer_info    IN VARCHAR2 DEFAULT NULL,
        i_term_code      IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get FLG_ICD9 of the given concept_term
    *
    * @param i_alert_diagnosis        Concept term
    * 
    * @return                         FLG_ICD9
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.3   
    * @since                          2014/03/13
    **********************************************************************************************/
    FUNCTION get_flg_std_diag(i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE) RETURN VARCHAR2;

    FUNCTION get_diag_from_epis_diag
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_diagnosis  IN table_number,
        o_diagnosis       OUT table_number,
        o_alert_diagnosis OUT table_number,
        o_desc_detail     OUT table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function that returns the last episode identifier that contains the last diagnosis documented
    * by software 
    *
    * @param i_lang                   language identifier
    * @param i_prof                   Professional identifier
    * @param i_patient                Patient identifier
    * @param i_software               Software identifier
    * @param i_diag_type              Diagnosis Type: D-Final, P-Diferential
    *
    * @return                         Last episode identifier
    *
    * @author                         Gisela Couto
    * @version                        2.6.4.2.2
    * @since                          Oct/29/2014
    **********************************************************************************************/
    FUNCTION get_lst_epis_doc_diag_by_soft
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_software  IN software.id_software%TYPE,
        i_diag_type IN VARCHAR2
    ) RETURN episode.id_episode%TYPE;
    /********************************************************************************************
    * Function that returns the informtaion of diagnosis by id_epis_diagnosis
    *
    * @param i_lang                   language ID
    * @param i_prof                   Object (professional, Institution and Software)
    * @param i_episode                episode ID
     * @param i_flg_type               Diagnosis type: P - differential, D - final
    * @param i_epis_diag              episode diagnosis ID
     *
    * @return                         diagnosis general info
    *
    *
    * @author                         Elisabete Bugalho
    * @version                        2.7.0
    * @since                          16/11/2016
    **********************************************************************************************/
    FUNCTION get_epis_diag_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_type  IN epis_diagnosis.flg_type%TYPE,
        i_epis_diag IN table_number,
        o_epis_diag OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_diag_trauma
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN diagnosis.id_diagnosis%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Listar os diagnósticos definitivos do episódio
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_epis                   episode id
    * @param i_preg_out_type          type Abortion (A) or Delivery(D)
    * @param o_exists                 IF exists, return 'Y', otherwise, return 'N'
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Pedro Henriques
    * @version                        1.0 
    * @since                          2017/07/27
    **********************************************************************************************/
    FUNCTION get_final_diag_abort_deliv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis          IN episode.id_episode%TYPE,
        i_preg_out_type IN pat_pregnancy.flg_preg_out_type%TYPE,
        i_diagnosis     IN table_number,
        o_exists        OUT VARCHAR2,
        o_count         OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_diag_abort_or_deliv
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_diagnosis IN table_number,
        o_flg_type  OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_diagnosis_notes_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2
    ) RETURN t_coll_diagnosis_notes_cda
        PIPELINED;

    /***************************************************************************************
    ***************************************************************************************/
    PROCEDURE insert_diagnosis
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_rec_epis_diag       IN pk_edis_types.rec_in_epis_diagnosis,
        io_new_epis_diag_rows IN OUT table_varchar,
        o_epis_diagnosis      OUT epis_diagnosis.id_epis_diagnosis%TYPE,
        io_params             IN OUT NOCOPY pk_edis_types.table_out_epis_diags,
        o_error               OUT t_error_out
    );

    /***************************************************************************************
    ***************************************************************************************/
    PROCEDURE insert_diagnosis_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_rec_epis_diag IN pk_edis_types.rec_in_epis_diagnosis,
        io_params       IN OUT NOCOPY pk_edis_types.table_out_epis_diags,
        o_error         OUT t_error_out
    );

    /***************************************************************************************
    ***************************************************************************************/
    PROCEDURE manage_epis_diagnosis_rank
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE DEFAULT NULL,
        i_id_episode        IN epis_diagnosis.id_episode%TYPE,
        i_dt_record         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_process_hist  IN BOOLEAN DEFAULT TRUE
    );

    /***************************************************************************************
    ***************************************************************************************/
    PROCEDURE manage_epis_diagnosis_is_compl
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN epis_diagnosis.id_episode%TYPE,
        i_flg_type       IN epis_diagnosis.flg_type%TYPE,
        i_removed_compl  IN table_number,
        i_inserted_compl IN table_number
    );

END pk_diagnosis_core;
/
