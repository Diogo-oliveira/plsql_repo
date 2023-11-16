/*-- Last Change Revision: $Rev: 1658137 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:21:37 +0000 (seg, 10 nov 2014) $*/

CREATE OR REPLACE PACKAGE pk_nan_model IS

    -- Author  : ARIEL.MACHADO
    -- Created : 7/4/2013 5:20:41 PM
    -- Purpose : NANDA-I Nursing Diagnoses Model: Methods to handle the classification data model

    -- Exceptions

    --An invalid NANDA Domain not available in NAN_DOMAIN
    e_invalid_nanda_domain EXCEPTION;

    --An invalid NANDA Class not available in NAN_CLASS
    e_invalid_nanda_class EXCEPTION;

    --An invalid NANDA Diagnosis not available in NAN_DIAGNOSIS
    e_invalid_nanda_diagnosis EXCEPTION;

    -- Public type declarations

    TYPE t_nan_domain_rec IS RECORD(
        id_nan_domain     nan_domain.id_nan_domain%TYPE,
        domain_code       nan_domain.domain_code%TYPE,
        domain_name       pk_translation.t_desc_translation,
        domain_definition pk_translation.t_desc_translation);
    TYPE t_nan_domain_coll IS TABLE OF t_nan_domain_rec;
    TYPE t_nan_domain_cur IS REF CURSOR RETURN t_nan_domain_rec;

    TYPE t_nan_class_rec IS RECORD(
        id_nan_class     nan_class.id_nan_class%TYPE,
        class_code       nan_class.class_code%TYPE,
        class_name       pk_translation.t_desc_translation,
        class_definition pk_translation.t_desc_translation,
        id_nan_domain    nan_class.id_nan_domain%TYPE);
    TYPE t_nan_class_coll IS TABLE OF t_nan_class_rec;
    TYPE t_nan_class_cur IS REF CURSOR RETURN t_nan_class_rec;

    TYPE t_nan_diagnosis_rec IS RECORD(
        id_nan_diagnosis     nan_diagnosis.id_nan_diagnosis%TYPE,
        diagnosis_code       nan_diagnosis.diagnosis_code%TYPE,
        diagnosis_name       pk_translation.t_desc_translation,
        diagnosis_definition pk_translation.t_desc_translation,
        year_approved        nan_diagnosis.year_approved%TYPE,
        year_revised         nan_diagnosis.year_revised%TYPE,
        loe                  nan_diagnosis.loe%TYPE,
        references           nan_diagnosis.references%TYPE,
        id_nan_class         nan_diagnosis.id_nan_diagnosis%TYPE);
    TYPE t_nan_diagnosis_coll IS TABLE OF t_nan_diagnosis_rec;
    TYPE t_nan_diagnosis_cur IS REF CURSOR RETURN t_nan_diagnosis_rec;

    TYPE t_nan_diagnosis_info_rec IS RECORD(
        domain_code          nan_domain.domain_code%TYPE,
        domain_name          pk_translation.t_desc_translation,
        domain_definition    pk_translation.t_desc_translation,
        class_code           nan_class.class_code%TYPE,
        class_name           pk_translation.t_desc_translation,
        class_definition     pk_translation.t_desc_translation,
        diagnosis_code       nan_diagnosis.diagnosis_code%TYPE,
        diagnosis_name       pk_translation.t_desc_translation,
        diagnosis_definition pk_translation.t_desc_translation,
        year_approved        nan_diagnosis.year_approved%TYPE,
        year_revised         nan_diagnosis.year_revised%TYPE,
        loe                  nan_diagnosis.loe%TYPE,
        references           nan_diagnosis.references%TYPE);
    TYPE t_nan_diagnosis_info_cur IS REF CURSOR RETURN t_nan_diagnosis_info_rec;

    -- Public constant declarations

    -- Display the NANDA code at start of the NANDA Diagnosis label
    g_code_format_start CONSTANT sys_config.value%TYPE := 'S';
    -- Display the NANDA code at end of the NANDA Diagnosis label
    g_code_format_end CONSTANT sys_config.value%TYPE := 'E';
    -- Not display the NANDA code in the NANDA Diagnosis label
    g_code_format_none CONSTANT sys_config.value%TYPE := '';
    -- NANDA code format mask    
    g_nanda_code_format CONSTANT VARCHAR2(5 CHAR) := '00000';

    -- Default ALERT content as institution owner of the record
    k_inst_owner_default CONSTANT nan.id_inst_owner%TYPE := 0;

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Insert/Update NANDA Domains
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version
    * @param    i_domain_code          NANDA Domain Code
    * @param    i_name                 NANDA Domain label
    * @param    i_definition           NANDA Domain definition
    * @param    i_rank                 Rank order    
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT    
    * @param    i_concept
    * @param    i_concept_version 
    * @param    i_concept_term 
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/4/2013
    */
    PROCEDURE insert_into_nan_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_domain.id_terminology_version%TYPE,
        i_domain_code         IN nan_domain.domain_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN nan_domain.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN nan_domain.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nan_domain.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_domain.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NANDA Class
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version 
    * @param    i_domain_code          NANDA Domain Code
    * @param    i_class_code           NANDA Class Code
    * @param    i_name                 NANDA Class label
    * @param    i_definition           NANDA Class definition 
    * @param    i_rank                 Rank order
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version 
    * @param    i_concept_term 
    *
    * @throws  e_invalid_nanda_domain
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/5/2013
    */
    PROCEDURE insert_into_nan_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        i_domain_code         IN nan_domain.domain_code%TYPE,
        i_class_code          IN nan_class.class_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN nan_class.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN nan_class.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nan_class.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_class.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NANDA Diagnosis
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version
    * @param    i_class_code           NANDA Class Code
    * @param    i_diagnosis_code       NANDA Diagnosis Code
    * @param    i_name                 NANDA Diagnosis label
    * @param    i_definition           NANDA Diagnosis definition
    * @param    i_year_approved        Year approved
    * @param    i_year_revised         Year revised
    * @param    i_loe                  Level of Evidence Criteria
    * @param    i_references           References
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version 
    * @param    i_concept_term 
    *
    * @throws  e_invalid_nanda_class
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/10/2013
    */
    PROCEDURE insert_into_nan_diagnosis
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        i_class_code          IN nan_class.class_code%TYPE,
        i_diagnosis_code      IN nan_diagnosis.diagnosis_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_year_approved       IN nan_diagnosis.year_approved%TYPE DEFAULT NULL,
        i_year_revised        IN nan_diagnosis.year_revised%TYPE DEFAULT NULL,
        i_loe                 IN nan_diagnosis.loe%TYPE DEFAULT NULL,
        i_references          IN nan_diagnosis.references%TYPE DEFAULT NULL,
        i_inst_owner          IN nan_class.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept             IN nan.id_concept%TYPE DEFAULT NULL,
        i_concept_version     IN nan_class.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_class.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NANDA Defined characteristics for nursing diagnoses
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version
    * @param    i_diagnosis_code       NANDA Diagnosis Code
    * @param    i_def_char_code        Defining Characteristic code
    * @param    i_description          Defining Characteristic description
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version 
    * @param    i_concept_term
    *
    * @throws  e_invalid_nanda_diagnosis
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   9/25/2013
    */
    PROCEDURE insert_into_def_characteristic
    
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_def_chars.id_terminology_version%TYPE,
        i_diagnosis_code      IN nan_diagnosis.diagnosis_code%TYPE,
        i_def_char_code       IN nan_def_chars.def_char_code%TYPE,
        i_description         IN pk_translation.t_desc_translation,
        i_inst_owner          IN nan_def_chars.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nan_def_chars.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_def_chars.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NANDA Related factors for nursing diagnoses
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version
    * @param    i_diagnosis_code       NANDA Diagnosis Code
    * @param    i_rel_factor_code      Related Factor code
    * @param    i_description          Related Factor description
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version 
    * @param    i_concept_term
    *
    * @throws  e_invalid_nanda_diagnosis
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   9/25/2013
    */
    PROCEDURE insert_into_related_factors
    
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_related_factor.id_terminology_version%TYPE,
        i_diagnosis_code      IN nan_diagnosis.diagnosis_code%TYPE,
        i_rel_factor_code     IN nan_related_factor.rel_factor_code%TYPE,
        i_description         IN pk_translation.t_desc_translation,
        i_inst_owner          IN nan_related_factor.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nan_related_factor.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_related_factor.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NANDA Risk factors for nursing diagnoses
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version
    * @param    i_diagnosis_code       NANDA Diagnosis Code
    * @param    i_risk_factor_code     Risk Factor code
    * @param    i_description          Risk Factor description
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version 
    * @param    i_concept_term
    *
    * @throws  e_invalid_nanda_diagnosis
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   9/25/2013
    */
    PROCEDURE insert_into_risk_factors
    
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_risk_factor.id_terminology_version%TYPE,
        i_diagnosis_code      IN nan_diagnosis.diagnosis_code%TYPE,
        i_risk_factor_code    IN nan_risk_factor.risk_factor_code%TYPE,
        i_description         IN pk_translation.t_desc_translation,
        i_inst_owner          IN nan_risk_factor.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nan_risk_factor.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nan_risk_factor.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Gets the formatted  description of a NANDA Diagnosis according the rule to include the NANDA code and additional text if applicable
    *
    * @param    i_label              NANDA Diagnosis Label 
    * @param    i_nanda_code         NANDA Code 
    * @param    i_code_format         Formatting rule to display the NANDA Code
    * @param    i_additional_info     Additional text to include in the description 
    *
    * @value    i_code_format  {*} g_code_format_start {*} g_code_format_end {*} g_code_format_none
    *    
    * @return   The formatted description of a given NANDA Diagnosis
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    2/18/2014
    */
    FUNCTION format_nanda_name
    (
        i_label           IN pk_translation.t_desc_translation,
        i_nanda_code      IN nan_diagnosis.diagnosis_code%TYPE,
        i_code_format     IN VARCHAR2,
        i_additional_info IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache;

    /**
    * Gets the NANDA Domains
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version 
    * @param    o_data                 Ref-Cursor with collection of NANDA Domains
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/8/2013
    */
    PROCEDURE get_nan_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_domain.id_terminology_version%TYPE,
        o_data                OUT t_nan_domain_cur
    );

    /**
    * Gets the NANDA Domain
    *
    * @param    i_lang                 Language ID    
    * @param    i_terminology_version  Terminology version 
    * @param    i_domain_code          NANDA Domain Code
    * @param    o_data                 Ref-Cursor with the NANDA Domain
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/8/2013
    */
    PROCEDURE get_nan_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_domain.id_terminology_version%TYPE,
        i_domain_code         IN nan_domain.domain_code%TYPE,
        o_data                OUT t_nan_domain_cur
    );

    /**
    * Gets the NANDA Classes
    *
    * @param    i_lang                 Language ID    
    * @param    i_terminology_version  Terminology version 
    * @param    o_data                 Ref-Cursor with collection of NANDA Classes
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/8/2013
    */
    PROCEDURE get_nan_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        o_data                OUT t_nan_class_cur
    );

    /**
    * Gets the NANDA Classes that belong to a NANDA Domain
    *
    * @param    i_lang                 Language ID    
    * @param    i_terminology_version  Terminology version 
    * @param    i_domain_code          NANDA Domain Code
    * @param    o_data                 Ref-Cursor with collection of NANDA Classes    
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/8/2013
    */
    PROCEDURE get_nan_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        i_domain_code         IN nan_domain.domain_code%TYPE,
        o_data                OUT t_nan_class_cur
    );

    /**
    * Gets the NANDA Class
    *
    * @param    i_lang                 Language ID    
    * @param    i_terminology_version  Terminology version 
    * @param    i_class_code           NANDA Class Code
    * @param    o_data                 Ref-Cursor with the NANDA Class    
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/8/2013
    */
    PROCEDURE get_nan_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        i_class_code          IN nan_class.class_code%TYPE,
        o_data                OUT t_nan_class_cur
    );

    /**
    * Gets the NANDA Diagnoses that belong to a NANDA Class
    *
    * @param    i_lang                 Language ID    
    * @param    i_terminology_version  Terminology version 
    * @param    i_class_code           NANDA Class Code
    * @param    i_paging               Use paging ('Y' Yes; 'N' No) Default 'N' 
    * @param    i_startindex           The index of the first item. startIndex is 1-based
    * @param    i_items_per_page       The number of items per page
    * @param    o_data                 Collection of NANDA Diagnosis
    * @param    o_total_items          The total number of NANDA Diagnosis available
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/8/2013
    */
    PROCEDURE get_nan_diagnosis
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nan_class.id_terminology_version%TYPE,
        i_class_code          IN nan_class.class_code%TYPE,
        i_paging              IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_startindex          IN NUMBER DEFAULT 1,
        i_items_per_page      IN NUMBER DEFAULT 10,
        o_data                OUT t_nan_diagnosis_cur,
        o_total_items         OUT NUMBER
    );

    /**
    * Gets a NANDA Diagnosis object
    *
    * @param    i_lang                 Language ID    
    * @param    i_nan_diagnosis        NANDA Diagnosis ID
    *
    * @return   t_obj_nan_diagnosis    NANDA Diagnosis object
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   1/27/2014
    */
    FUNCTION get_nan_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE
    ) RETURN t_obj_nan_diagnosis;
    /**
    * Gets the defined characteristics for a NANDA nursing diagnosis
    *
    * @param    i_lang             Language ID 
    * @param    i_nan_diagnosis    NANDA Diagnosis ID
    * @param    i_paging           Use paging ('Y' Yes; 'N' No) Default 'N' 
    * @param    i_startindex       The index of the first item. startIndex is 1-based
    * @param    i_items_per_page   The number of items per page 
    * @param    o_data             Cursor with a list of defined characteristics
    * @param    o_total_items      The total number of defined characteristics available for the NANDA Diagnosis        
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   9/27/2013
    */
    PROCEDURE get_defined_characteristics
    (
        i_lang           IN language.id_language%TYPE,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_startindex     IN NUMBER DEFAULT 1,
        i_items_per_page IN NUMBER DEFAULT 10,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER
    );

    /**
    * Gets the Related Factors for a NANDA nursing diagnosis
    *
    * @param    i_lang             Language ID 
    * @param    i_nan_diagnosis    NANDA Diagnosis ID
    * @param    i_paging           Use paging ('Y' Yes; 'N' No) Default 'N' 
    * @param    i_startindex       The index of the first item. startIndex is 1-based
    * @param    i_items_per_page   The number of items per page 
    * @param    o_data             Cursor with a list of related factors
    * @param    o_total_items      The total number of related factors available for the NANDA Diagnosis        
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   9/30/2013
    */
    PROCEDURE get_related_factors
    (
        i_lang           IN language.id_language%TYPE,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_startindex     IN NUMBER DEFAULT 1,
        i_items_per_page IN NUMBER DEFAULT 10,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER
    );

    /**
    * Gets the Risk Factors for a NANDA nursing diagnosis
    *
    * @param    i_lang             Language ID 
    * @param    i_nan_diagnosis    NANDA Diagnosis ID
    * @param    i_paging           Use paging ('Y' Yes; 'N' No) Default 'N' 
    * @param    i_startindex       The index of the first item. startIndex is 1-based
    * @param    i_items_per_page   The number of items per page 
    * @param    o_data             Cursor with a list of risk factors
    * @param    o_total_items      The total number of risk factors available for the NANDA Diagnosis        
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   9/30/2013
    */
    PROCEDURE get_risk_factors
    (
        i_lang           IN language.id_language%TYPE,
        i_nan_diagnosis  IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_paging         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_startindex     IN NUMBER DEFAULT 1,
        i_items_per_page IN NUMBER DEFAULT 10,
        o_data           OUT pk_types.cursor_type,
        o_total_items    OUT NUMBER
    );

    /**
    * Gets NANDA Diagnosis Code
    *
    * @param    i_nan_diagnosis    NANDA Diagnosis ID
    *
    * @return   NANDA Code
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    11/04/2013
    */
    FUNCTION get_nanda_code(i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE)
        RETURN nan_diagnosis.diagnosis_code%TYPE;

    /**
    * Gets NANDA Diagnosis label
    *
    * @param    i_nan_diagnosis       NANDA Diagnosis ID 
    * @param    i_code_format         Formatting rule to display the NANDA Code
    * @param    i_additional_info     Additional text to include in the description 
    *
    * @return   The label of a given NANDA Diagnosis
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    21/11/2013
    */
    FUNCTION get_nan_diagnosis_name
    (
        i_nan_diagnosis   IN nan_diagnosis.id_nan_diagnosis%TYPE,
        i_code_format     IN VARCHAR2 DEFAULT g_code_format_none,
        i_additional_info IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache;

    /**
    * Gets terminology information whose NANDA diagnosis belongs.
    *
    * @param    i_nan_diagnosis       NANDA Diagnosis ID 
    *
    * @return   Terminology infomation
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/14/2014
    */
    FUNCTION get_terminology_information(i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE)
        RETURN pk_nnn_in.t_terminology_info_rec;

END pk_nan_model;
/
