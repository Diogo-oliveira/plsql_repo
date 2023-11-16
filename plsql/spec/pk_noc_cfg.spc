/*-- Last Change Revision: $Rev: 1857413 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2018-07-27 09:59:52 +0100 (sex, 27 jul 2018) $*/
CREATE OR REPLACE PACKAGE pk_noc_cfg IS

    -- Author  : CRISTINA.OLIVEIRA
    -- Created : 30-10-2013 09:28:08
    -- Purpose : NOC Nursing Outcomes : Methods to handle the settings of institution for this classification

    -- Public type declarations
    TYPE t_noc_cfg_outcome_rec IS RECORD(
        id_noc_cfg_outcome     noc_cfg_outcome.id_noc_cfg_outcome%TYPE,
        flg_status             noc_cfg_outcome.flg_status%TYPE,
        dt_last_update         noc_cfg_outcome.dt_last_update%TYPE,
        id_noc_outcome         noc_outcome.id_noc_outcome%TYPE,
        id_terminology_version noc_outcome.id_terminology_version%TYPE,
        outcome_code           noc_outcome.outcome_code%TYPE,
        code_name              noc_outcome.code_name%TYPE,
        code_definition        noc_outcome.code_definition%TYPE,
        id_noc_scale           noc_outcome.id_noc_scale%TYPE,
        references             noc_outcome.references%TYPE,
        id_noc_class           noc_outcome.id_noc_class%TYPE,
        id_language            terminology_version.id_language%TYPE,
        flg_prn                noc_cfg_outcome.flg_prn%TYPE,
        code_notes_prn         noc_cfg_outcome.code_notes_prn%TYPE,
        flg_time               noc_cfg_outcome.flg_time%TYPE,
        flg_priority           noc_cfg_outcome.flg_priority%TYPE,
        id_order_recurr_option noc_cfg_outcome.id_order_recurr_option%TYPE);
    TYPE t_noc_cfg_outcome_coll IS TABLE OF t_noc_cfg_outcome_rec;
    TYPE t_noc_cfg_outcome_cur IS REF CURSOR RETURN t_noc_cfg_outcome_rec;

    TYPE t_noc_cfg_indicator_rec IS RECORD(
        id_noc_cfg_indicator   noc_cfg_indicator.id_noc_cfg_indicator%TYPE,
        flg_status             noc_cfg_indicator.flg_status%TYPE,
        dt_last_update         noc_cfg_indicator.dt_last_update%TYPE,
        id_noc_indicator       noc_indicator.id_noc_indicator%TYPE,
        id_terminology_version noc_indicator.id_terminology_version%TYPE,
        outcome_indicator_code noc_outcome_indicator.outcome_indicator_code%TYPE,
        code_description       noc_indicator.code_description%TYPE,
        flg_other              noc_indicator.flg_other%TYPE,
        id_noc_outcome         noc_outcome_indicator.id_noc_outcome%TYPE,
        id_noc_scale           noc_outcome_indicator.id_noc_scale%TYPE,
        rank                   noc_outcome_indicator.rank%TYPE,
        id_language            terminology_version.id_language%TYPE,
        flg_prn                noc_cfg_indicator.flg_prn%TYPE,
        code_notes_prn         noc_cfg_outcome.code_notes_prn%TYPE,
        flg_time               noc_cfg_indicator.flg_time%TYPE,
        flg_priority           noc_cfg_indicator.flg_priority%TYPE,
        id_order_recurr_option noc_cfg_indicator.id_order_recurr_option%TYPE);
    TYPE t_noc_cfg_indicator_coll IS TABLE OF t_noc_cfg_indicator_rec;
    TYPE t_noc_cfg_indicator_cur IS REF CURSOR RETURN t_noc_cfg_indicator_rec;

    -- Public constant declarations
    k_default_bulk_limit CONSTANT PLS_INTEGER := 100; --Default LIMIT option for bulk collect statements

    k_default_scale_level CONSTANT noc_scale_level.scale_level_value%TYPE := 5; --Suggests the max of the scale by default as the Exepected Outcome value (the best Goal's value)

    -- Public variable declarations
    g_terminology_nic CONSTANT terminology.internal_name%TYPE := 'NIC';
    -- Public function and procedure declarations

    /**
    * Gets the NOC Outcomes configured for an institution
    *
    * @param    i_inst   Institution ID
    * @param    i_soft   Software ID
    * @param    i_limit  Optional bulk collect limit. Default: Use the recommended default value.
    *   
    * @return   Collection of NIC Interventions (pipelined)
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   10/25/2013
    */
    FUNCTION tf_inst_outcome
    (
        i_inst  IN institution.id_institution%TYPE,
        i_soft  IN software.id_software%TYPE DEFAULT NULL,
        i_limit IN PLS_INTEGER DEFAULT pk_noc_cfg.k_default_bulk_limit
    ) RETURN t_noc_cfg_outcome_coll
        PIPELINED;

    /**
    * Gets the NOC Indicators configured for an institution
    *
    * @param    i_inst   Institution ID
    * @param    i_soft   Software ID
    * @param    i_limit  Optional bulk collect limit. Default: Use the recommended default value.
    *   
    * @return   Collection of NIC Interventions (pipelined)
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   10/25/2013
    */
    FUNCTION tf_inst_indicator
    (
        i_inst  IN institution.id_institution%TYPE,
        i_soft  IN software.id_software%TYPE DEFAULT NULL,
        i_limit IN PLS_INTEGER DEFAULT pk_noc_cfg.k_default_bulk_limit
    ) RETURN t_noc_cfg_indicator_coll
        PIPELINED;

    /**
    * Gets the NOC Indicators of a NOC Outcome configured for an institution
    *
    * @param    i_inst                 Institution ID
    * @param    i_soft                 Software ID
    * @param    i_noc_outcome          NOC Outcome ID
    * @param    i_limit                Optional bulk collect limit. Default: Use the recommended default value.
    *   
    * @return   Collection of NIC Interventions (pipelined)
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   10/25/2013
    */
    FUNCTION tf_inst_indicator
    (
        i_inst        IN institution.id_institution%TYPE,
        i_soft        IN software.id_software%TYPE DEFAULT NULL,
        i_noc_outcome IN noc_outcome.id_noc_outcome%TYPE,
        i_limit       IN PLS_INTEGER DEFAULT pk_noc_cfg.k_default_bulk_limit
    ) RETURN t_noc_cfg_indicator_coll
        PIPELINED;

    /**
    * Gets the NOC Outcomes configured for an institution
    *
    * @param    i_lang                 Language ID    
    * @param    i_prof                 Profissional
    * @param    i_include_inactive     Returns also diagnoses configured as inactive for the institution
    * @param    i_paging               Use paging ('Y' Yes; 'N' No) Default 'N' 
    * @param    i_startindex           The index of the first item. startIndex is 1-based
    * @param    i_items_per_page       The number of items per page
    * @param    o_interventions        Collection of NOC Ourcomes
    * @param    o_total_items          The total number of NOC Ourcomes available
    *
    * @value   i_include_inactive      {*} 'Y'  Include inactive outcome {*} 'N'  Exclude inactive outcomes
    * @value   i_paging                {*} 'Y'  Paging enabled {*} 'N'  No paging
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   30/10/2013
    */
    PROCEDURE get_noc_outcomes
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_include_inactive IN noc_cfg_outcome.flg_status%TYPE DEFAULT 'N',
        i_paging           IN VARCHAR2 DEFAULT 'N',
        i_startindex       IN NUMBER DEFAULT 1,
        i_items_per_page   IN NUMBER DEFAULT 10,
        o_outcomes         OUT pk_types.cursor_type,
        o_total_items      OUT NUMBER
    );

    /**
    * Gets a list of active NOC Outcomes that can be linked to a NANDA Diagnosis for a given institution.
    *    
    * @param    i_prof              Professional identification and its context (institution and software)        
    * @param    i_nan_diagnosis     NANDA Diagnosis ID
    * @param    o_outcomes          Collection of NOC Outcomes
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   30/10/2013
    */
    PROCEDURE get_noc_outcomes
    (
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        o_outcomes      OUT pk_types.cursor_type
    );

    /**
    * Gets a list of active NOC Indicators that can be linked to a NOC Outcoem for a given institution.
    *    
    * @param    i_prof              Professional identification and its context (institution and software)        
    * @param    i_noc_outcome       NOC Outcome ID
    * @param    o_indicators        Collection of NOC Indicators
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   30/10/2013
    */
    PROCEDURE get_noc_indicators
    (
        i_prof        IN profissional,
        i_noc_outcome IN noc_outcome.id_noc_outcome%TYPE,
        o_indicators  OUT pk_types.cursor_type
    );

    /**
    * Gets the NOC Outcomes configured for an institution
    *
    * @param    i_lang                 Language ID    
    * @param    i_prof                 Profissional
    * @param    i_include_inactive     Returns also diagnoses configured as inactive for the institution
    * @param    i_paging               Use paging ('Y' Yes; 'N' No) Default 'N' 
    * @param    i_startindex           The index of the first item. startIndex is 1-based
    * @param    i_items_per_page       The number of items per page
    * @param    o_indicators           Collection of NOC Indicators
    * @param    o_total_items          The total number of NOC Indicators available
    *
    * @value   i_include_inactive      {*} 'Y'  Include inactive indicator {*} 'N'  Exclude inactive indicator
    * @value   i_paging                {*} 'Y'  Paging enabled {*} 'N'  No paging
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   30/10/2013
    */
    PROCEDURE get_noc_indicators
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_include_inactive IN noc_cfg_indicator.flg_status%TYPE DEFAULT 'N',
        i_paging           IN VARCHAR2 DEFAULT 'N',
        i_startindex       IN NUMBER DEFAULT 1,
        i_items_per_page   IN NUMBER DEFAULT 10,
        o_indicators       OUT pk_types.cursor_type,
        o_total_items      OUT NUMBER
    );

    /**
    * Set NOC Outcome status to Active/Inactive for an institution
    *
    * @param    i_institution    Institution ID 
    * @param    i_noc_outcome    NOC Outcome ID 
    * @param    i_flg_status     Status
    *
    * @value   i_flg_status      {*} 'A'  Active {*} 'I'  Inactive
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   10/25/2013
    */
    PROCEDURE set_inst_outcome_status
    (
        i_institution IN noc_cfg_outcome.id_institution%TYPE,
        i_noc_outcome IN noc_cfg_outcome.id_noc_outcome%TYPE,
        i_flg_status  IN noc_cfg_outcome.flg_status%TYPE
    );

    /**
    * Set NOC Indicator status to Active/Inactive for an institution
    *
    * @param    i_institution    Institution ID 
    * @param    i_noc_indicator  NOC indicator ID 
    * @param    i_flg_status     Status
    *
    * @value   i_flg_status      {*} 'A'  Active {*} 'I'  Inactive
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   10/25/2013
    */
    PROCEDURE set_inst_indicator_status
    (
        i_institution   IN noc_cfg_indicator.id_institution%TYPE,
        i_noc_indicator IN noc_cfg_indicator.id_noc_indicator%TYPE,
        i_flg_status    IN noc_cfg_indicator.flg_status%TYPE
    );

    /**
    * Procedure that resolves bind variables required for the filter NOCOutcomesByInstitution
    *
    * @param    i_context_ids   Static contexts (i_prof, i_lang, i_episode,...)  
    * @param    i_context_vals  Custom contexts, sent from the user interface
    * @param    i_name          Name of the bind variable to ge 
    * @param    o_vc2           Varchar2 value returned by the procedure 
    * @param    o_num           Numeric value returned by the procedure 
    * @param    o_id            NUMBER(24) value returned by the procedure 
    * @param    o_tstz          Timestamp value returned by the procedure 
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   10/25/2013
    */
    PROCEDURE init_fltr_params_noc
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
    * Search NOC Outcomes by label or Code
    *
    * @param    i_inst              Institution ID
    * @param    i_soft              Software ID
    * @param    i_search            The string to be searched
    *   
    * @return   The correspondent matches from the NOC Outcomes
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    2/18/2014
    */
    FUNCTION get_search_by_code_or_text
    (
        i_inst   IN institution.id_institution%TYPE,
        i_soft   IN software.id_software%TYPE,
        i_search IN pk_translation.t_desc
    ) RETURN table_t_search;

    /**
    * Evaluates if a NOC Outcome and a NOC Indicator can be linked between them
    *
    * @param    i_prof                     Profissional
    * @param    i_noc_outcome              NOC Outcome ID
    * @param    i_noc_indicator            NOC indicator ID 
    *   
    * @return   'Y' if it is a valid linkage
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    12/27/2013
    */
    FUNCTION is_linkable_outcome_indicator
    (
        i_prof          IN profissional,
        i_noc_outcome   IN noc_outcome.id_noc_outcome%TYPE,
        i_noc_indicator IN noc_indicator.id_noc_indicator%TYPE
    ) RETURN VARCHAR2;

END pk_noc_cfg;
/
