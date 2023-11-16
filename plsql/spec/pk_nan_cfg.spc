/*-- Last Change Revision: $Rev: 1857468 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2018-07-27 11:17:37 +0100 (sex, 27 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_nan_cfg IS

    -- Author  : ARIEL.MACHADO
    -- Created : 10/7/2013 3:20:20 PM
    -- Purpose : NANDA-I Nursing Diagnoses : Methods to handle the settings of institution for this classification

    -- Exceptions

    --Missing configuration in MSI_NNN_TERM_VERSION to indicate the terminology version of NANDA/NIC/NOC/NNNLinkages used by institution/software
    e_missing_cfg_term_version EXCEPTION;

    -- Public type declarations

    TYPE t_nan_cfg_diagnosis_rec IS RECORD(
        id_nan_cfg_diagnosis   nan_cfg_diagnosis.id_nan_cfg_diagnosis%TYPE,
        flg_status             nan_cfg_diagnosis.flg_status%TYPE,
        dt_last_update         nan_cfg_diagnosis.dt_last_update%TYPE,
        id_nan_diagnosis       nan_diagnosis.id_nan_diagnosis%TYPE,
        id_terminology_version nan_diagnosis.id_terminology_version%TYPE,
        diagnosis_code         nan_diagnosis.diagnosis_code%TYPE,
        code_name              nan_diagnosis.code_name%TYPE,
        code_definition        nan_diagnosis.code_definition%TYPE,
        year_approved          nan_diagnosis.year_approved %TYPE,
        year_revised           nan_diagnosis.year_revised %TYPE,
        loe                    nan_diagnosis.loe%TYPE,
        references             nan_diagnosis.references%TYPE,
        id_nan_class           nan_diagnosis.id_nan_class%TYPE,
        id_language            terminology_version.id_language%TYPE);
    TYPE t_nan_cfg_diagnosis_coll IS TABLE OF t_nan_cfg_diagnosis_rec;
    TYPE t_nan_cfg_diagnosis_cur IS REF CURSOR RETURN t_nan_cfg_diagnosis_rec;

    -- Public constant declarations

    -- Default LIMIT option for bulk collect statements
    k_default_bulk_limit CONSTANT PLS_INTEGER := 100;

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Gets the NANDA Diagnoses configured for an institution
    *
    * @param    i_inst              Institution ID
    * @param    i_soft              Software ID
    * @param    i_limit             Optional bulk collect limit. Default: Use the recommended default value.   
    *   
    * @return   Collection of NANDA Diagnosis (pipelined)
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    10/9/2013
    */
    FUNCTION tf_inst_diagnosis
    (
        i_inst  IN institution.id_institution%TYPE,
        i_soft  IN software.id_software%TYPE DEFAULT NULL,
        i_limit IN PLS_INTEGER DEFAULT pk_nan_cfg.k_default_bulk_limit
    ) RETURN t_nan_cfg_diagnosis_coll
        PIPELINED;

    /**
    * Gets a list of NANDA Domains according with active NANDA diagnoses for a given institution
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    o_data              Ref-Cursor with collection of NANDA Domains
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    7/8/2013
    */
    PROCEDURE get_nan_domains
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        o_data OUT pk_nan_model.t_nan_domain_cur
    );

    /**
    * Gets a list of NANDA Classes that belong to a NANDA Domain according with active NANDA diagnoses for a given institution
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_nan_domain        NANDA Domain ID
    * @param    o_data              Ref-Cursor with collection of NANDA Classes
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    7/8/2013
    */
    PROCEDURE get_nan_classes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_nan_domain IN nan_class.id_nan_domain%TYPE,
        o_data       OUT pk_nan_model.t_nan_class_cur
    );

    /**
    * Gets the NANDA Diagnoses configured for an institution and, optionally, belonging to a NANDA Class
    *
    * @param    i_lang              Professional preferred language
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_nan_class         Returns only NANDA Diagnoses that belong to this NANDA Class. When NULL returns all diagnoses
    * @param    i_include_inactive  Returns also diagnoses configured as inactive for the institution
    * @param    i_paging            Use paging ('Y' Yes; 'N' No) Default 'N' 
    * @param    i_startindex        The index of the first item. startIndex is 1-based
    * @param    i_items_per_page    The number of items per page
    * @param    o_diagnosis         Collection of NANDA Diagnosis
    * @param    o_total_items       The total number of NANDA Diagnosis available
    *
    * @value    i_include_inactive  {*} 'Y'  Include inactive diagnoses {*} 'N'  Exclude inactive diagnoses
    * @value    i_paging            {*} 'Y'  Paging enabled {*} 'N'  No paging
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    10/8/2013
    */
    PROCEDURE get_nan_diagnoses
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_nan_class        IN nan_class.id_nan_class%TYPE DEFAULT NULL,
        i_include_inactive IN nan_cfg_diagnosis.flg_status%TYPE DEFAULT 'N',
        i_paging           IN VARCHAR2 DEFAULT 'N',
        i_startindex       IN NUMBER DEFAULT 1,
        i_items_per_page   IN NUMBER DEFAULT 10,
        o_diagnosis        OUT pk_types.cursor_type,
        o_total_items      OUT NUMBER
    );

    /**
    * Set NANDA diagnosis status to Active/Inactive for an institution
    *
    * @param    i_institution       Institution ID 
    * @param    i_nan_diagnosis     NANDA Diagnosis ID 
    * @param    i_flg_status        Status
    *
    * @value    i_flg_status        {*} 'A'  Active {*} 'I'  Inactive
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    10/8/2013
    */
    PROCEDURE set_inst_diagnosis_status
    (
        i_institution   IN nan_cfg_diagnosis.id_institution%TYPE,
        i_nan_diagnosis IN nan_cfg_diagnosis.id_nan_diagnosis%TYPE,
        i_flg_status    IN nan_cfg_diagnosis.flg_status%TYPE
    );

    /**
    * Procedure that resolves bind variables required for the filter NANDADiagnosisByInstitution
    *
    * @param    i_context_ids       Static contexts (i_prof, i_lang, i_episode,...)  
    * @param    i_context_vals      Custom contexts, sent from the user interface
    * @param    i_name              Name of the bind variable to ge 
    * @param    o_vc2               Varchar2 value returned by the procedure 
    * @param    o_num               Numeric value returned by the procedure 
    * @param    o_id                NUMBER(24) value returned by the procedure 
    * @param    o_tstz              Timestamp value returned by the procedure 
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    10/11/2013
    */
    PROCEDURE init_fltr_params_nanda
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
    * Search NANDA Diagnosis by label or Code
    *
    * @param    i_inst              Institution ID
    * @param    i_soft              Software ID
    * @param    i_search            The string to be searched
    *   
    * @return   The correspondent matches from the NANDA Diagnoses.
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
    * Evaluates if a NANDA Diagnosis and a NOC Outcome can be linked between them
    *
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_nan_diagnosis     NANDA Diagnosis ID 
    * @param    i_noc_outcome       NOC Outcome ID
    *   
    * @return   'Y' if it is a valid linkage
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    12/30/2013
    */
    FUNCTION is_linkable_diagnosis_outcome
    (
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_noc_outcome   IN noc_outcome.id_noc_outcome%TYPE
    ) RETURN VARCHAR2;

    /**
    * Evaluates if a NANDA Diagnosis and a NIC Intervention can be linked between them
    *
    * @param    i_prof              Professional identification and its context (institution and software)
    * @param    i_nan_diagnosis     NANDA Diagnosis ID 
    * @param    i_nic_intervention  NIC Intervention ID
    *   
    * @return   'Y' if it is a valid linkage
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    12/30/2013
    */
    FUNCTION is_linkable_diagnosis_interv
    (
        i_prof             IN profissional,
        i_nan_diagnosis    IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE
    ) RETURN VARCHAR2;

END pk_nan_cfg;
/
