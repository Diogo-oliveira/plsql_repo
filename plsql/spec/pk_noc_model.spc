/*-- Last Change Revision: $Rev: 1658137 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:21:37 +0000 (seg, 10 nov 2014) $*/
CREATE OR REPLACE PACKAGE pk_noc_model IS

    -- Author  : ARIEL.MACHADO
    -- Created : 9/25/2013 3:57:48 PM
    -- Purpose : Nursing Outcomes Classification (NOC) Model: Methods to handle the classification data model

    -- Exceptions

    --An invalid NOC Domain not available in NOC_DOMAIN
    e_invalid_noc_domain EXCEPTION;

    --An invalid NOC Class not available in NOC_CLASS
    e_invalid_noc_class EXCEPTION;

    --An invalid NOC Outcome not available in NOC_OUTCOME
    e_invalid_noc_outcome EXCEPTION;

    --An invalid NOC Scale not available in NOC_SCALE
    e_invalid_noc_scale EXCEPTION;

    -- Public type declarations

    -- Public constant declarations

    -- Display the NOC code at start of the NOC Outcome label
    g_code_format_start CONSTANT sys_config.value%TYPE := 'S';
    -- Display the NOC code at end of the NOC Outcome label
    g_code_format_end CONSTANT sys_config.value%TYPE := 'E';
    -- Not display the NOC code in the NOC Outcome label
    g_code_format_none CONSTANT sys_config.value%TYPE := 'N';
    -- NOC code format mask        
    g_noc_code_format CONSTANT VARCHAR2(5 CHAR) := '0000';
    -- NOC Indicator code format mask            
    g_noc_indicator_code_format CONSTANT VARCHAR2(7 CHAR) := '000000';

    -- Default ALERT content as institution owner of the record
    k_inst_owner_default CONSTANT noc.id_inst_owner%TYPE := 0;
    -- Public variable declarations

    -- Public function and procedure declarations
    /**
    * Insert/Update NOC Domains
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version
    * @param    i_domain_code          NOC Domain Code
    * @param    i_name                 NOC Domain label
    * @param    i_definition           NOC Domain definition    
    * @param    i_rank                 Rank order    
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT    
    * @param    i_concept
    * @param    i_concept_version 
    * @param    i_concept_term 
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   10/7/2013
    */
    PROCEDURE insert_into_noc_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN noc_domain.id_terminology_version%TYPE,
        i_domain_code         IN noc_domain.domain_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN noc_domain.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN noc_domain.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN noc_domain.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN noc_domain.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NOC Class
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version 
    * @param    i_domain_code          NOC Domain Code
    * @param    i_class_code           NOC Class Code
    * @param    i_name                 NOC Class label
    * @param    i_definition           NOC Class definition
    * @param    i_rank                 Rank order
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version 
    * @param    i_concept_term 
    *
    * @throws  e_invalid_noc_domain
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   10/7/2013
    */
    PROCEDURE insert_into_noc_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN noc_class.id_terminology_version%TYPE,
        i_domain_code         IN noc_domain.domain_code%TYPE,
        i_class_code          IN noc_class.class_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN noc_class.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN noc_class.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN noc_class.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN noc_class.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NOC five-point Likert scale
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version 
    * @param    i_scale_code           NOC Scale Code
    * @param    i_scale_description    NOC Scale description 
    * @param    i_description_level_1  Description for scale level 1 
    * @param    i_description_level_2  Description for scale level 2  
    * @param    i_description_level_3  Description for scale level 3  
    * @param    i_description_level_4  Description for scale level 4 
    * @param    i_description_level_5  Description for scale level 5
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version 
    * @param    i_concept_term 
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   10/7/2013
    */
    PROCEDURE insert_into_noc_scale
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN noc_scale.id_terminology_version%TYPE,
        i_scale_code          IN noc_scale.scale_code%TYPE,
        i_scale_description   IN pk_translation.t_desc_translation,
        i_description_level_1 IN pk_translation.t_desc_translation,
        i_description_level_2 IN pk_translation.t_desc_translation,
        i_description_level_3 IN pk_translation.t_desc_translation,
        i_description_level_4 IN pk_translation.t_desc_translation,
        i_description_level_5 IN pk_translation.t_desc_translation,
        i_inst_owner          IN noc_scale.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN noc_scale.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN noc_scale.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NOC Outcome
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version
    * @param    i_class_code           NOC Class Code
    * @param    i_outcome_code         NOC Outcome Code
    * @param    i_scale_code           NOC Likert scale(s)
    * @param    i_name                 NOC Outcome label
    * @param    i_definition           NOC Outcome definition
    * @param    i_references           References
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version 
    * @param    i_concept_term 
    *
    * @throws  e_invalid_noc_class, e_invalid_noc_scale
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   10/7/2013
    */
    PROCEDURE insert_into_noc_outcome
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN noc_outcome.id_terminology_version%TYPE,
        i_class_code          IN noc_class.class_code%TYPE,
        i_outcome_code        IN noc_outcome.outcome_code%TYPE,
        i_scale_codes         IN table_varchar,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_references          IN noc_outcome.references%TYPE DEFAULT NULL,
        i_inst_owner          IN noc_outcome.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept             IN noc.id_concept%TYPE DEFAULT NULL,
        i_concept_version     IN noc_outcome.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN noc_outcome.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NOC Indicator
    *
    * @param    i_lang                   Language ID
    * @param    i_terminology_version    Terminology version
    * @param    i_outcome_code           NOC Outcome Code
    * @param    i_indicator_code         NOC Indicator Code
    * @param    i_outcome_indicator_code NOC Indicator Code within the NOC Outcome
    * @param    i_description            NOC Indicator description
    * @param    i_scale_code             NOC Scale Code used to determine Indicator scores. Default: uses the primary scale associated with NOC Outcome
    * @param    i_rank                   Rank order    
    * @param    i_inst_owner             Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version         
    * @param    i_concept_term           
    *
    * @throws  e_invalid_noc_outcome
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   10/24/2013
    */
    PROCEDURE insert_into_noc_indicator
    (
        i_lang                   IN language.id_language%TYPE,
        i_terminology_version    IN nic_activity.id_terminology_version%TYPE,
        i_outcome_code           IN noc_outcome.outcome_code%TYPE,
        i_indicator_code         IN noc_indicator.indicator_code%TYPE,
        i_outcome_indicator_code IN noc_outcome_indicator.outcome_indicator_code%TYPE,
        i_description            IN pk_translation.t_desc_translation,
        i_scale_code             IN noc_scale.scale_code%TYPE DEFAULT NULL,
        i_rank                   IN noc_outcome_indicator.rank%TYPE DEFAULT NULL,
        i_inst_owner             IN noc_indicator.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version        IN noc_indicator.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term           IN noc_indicator.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Gets the formatted  description of a NOC Outcome according the rule to include the NOC code and additional text if applicable
    *
    * @param    i_label               NOC Outcome Label 
    * @param    i_noc_code            NOC Code 
    * @param    i_code_format         Formatting rule to display the NOC Code
    * @param    i_additional_info     Additional text to include in the description 
    *
    * @value    i_code_format  {*} g_code_format_start {*} g_code_format_end {*} g_code_format_none
    *
    * @return   The formatted description of a given NOC Outcome
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    2/19/2014
    */
    FUNCTION format_noc_name
    (
        i_label           IN pk_translation.t_desc_translation,
        i_noc_code        IN noc_outcome.outcome_code%TYPE,
        i_code_format     IN VARCHAR2,
        i_additional_info IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache;

    /**
    * Gets the formatted description of a NOC Indicator according the rule to include the Indicator code and additional text if applicable
    *
    * @param    i_label                     NOC Indicator Description 
    * @param    i_outcome_indicator_code    Indicator Code 
    * @param    i_code_format               Formatting rule to display the indicator code
    * @param    i_additional_info           Additional text to include in the description 
    *
    * @value    i_code_format  {*} g_code_format_start {*} g_code_format_end {*} g_code_format_none
    *
    * @return   The formatted description of a given NOC Indicator
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    6/17/2014
    */
    FUNCTION format_indicator_name
    (
        i_label                  IN pk_translation.t_desc_translation,
        i_outcome_indicator_code IN noc_outcome_indicator.outcome_indicator_code%TYPE,
        i_code_format            IN VARCHAR2,
        i_additional_info        IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache;
    /**
    * Gets a NOC Outcome object
    *
    * @param    i_lang                 Language ID    
    * @param    i_noc_outcome          NOC Outcome ID
    *
    * @return   t_obj_noc_outcome    NOC Outcome object
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   2/28/2014
    */
    FUNCTION get_noc_outcome
    (
        i_lang        IN language.id_language%TYPE,
        i_noc_outcome IN noc_outcome.id_noc_outcome%TYPE
    ) RETURN t_obj_noc_outcome;

    /**
    * Gets NOC Outcome Code
    *
    * @param    i_noc_outcome    NOC Outcome ID
    *
    * @return   NOC Outcome Code
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    11/08/2013
    */
    FUNCTION get_outcome_code(i_noc_outcome IN noc_outcome.id_noc_outcome%TYPE) RETURN noc_outcome.outcome_code%TYPE;

    /**
    * Gets NOC Indicator Code
    *
    * @param    i_noc_indicator    NOC indicator ID
    *
    * @return   NOC Indicator Code
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    21/11/2013
    */
    FUNCTION get_indicator_code(i_noc_indicator IN noc_indicator.id_noc_indicator%TYPE)
        RETURN noc_indicator.indicator_code%TYPE;

    /**
    * Gets the code of the association between the outcome and indicator
    *
    * @param    i_noc_outcome    NOC Outcome ID
    * @param    i_noc_indicator  NOC indicator ID
    *
    * @return   NOC Outcome Indicator Code
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    21/11/2013
    */
    FUNCTION get_outcome_indicator_code
    (
        i_noc_outcome   IN noc_outcome_indicator.id_noc_outcome%TYPE,
        i_noc_indicator IN noc_outcome_indicator.id_noc_indicator%TYPE
    ) RETURN noc_outcome_indicator.outcome_indicator_code%TYPE;

    /**
    * Gets the NOC Outcome label
    *
    * @param    i_noc_outcome         NOC Outcome ID 
    * @param    i_code_format         Formatting rule to display the NOC Code
    * @param    i_additional_info     Additional text to include in the description 
               
    *
    * @return   The label of a given NOC Outcome
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    21/11/2013
    */
    FUNCTION get_outcome_name
    (
        i_noc_outcome     IN noc_outcome.id_noc_outcome%TYPE,
        i_code_format     IN VARCHAR2 DEFAULT g_code_format_none,
        i_additional_info IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache;

    /**
    * Gets NOC Indicator Name
    *
    * @param    i_noc_indicator    NOC Indicator ID
    *
    * @return   The translation of the name of a given Indicator
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    21/11/2013
    */
    FUNCTION get_indicator_name(i_noc_indicator IN noc_indicator.id_noc_indicator%TYPE)
        RETURN pk_translation.t_desc_translation result_cache;

    /**
    * Get the information of a given scale ID
    *    
    * @param    i_noc_scale            NOC Scale ID
    * @param    i_flg_option_none      Show option "None"? (Y) Yes (N) No     
    * @param    o_scale_info           The name and scale code of one NOC Scale ID
    * @param    o_scale_levels         Collection of levels scale of one NOC Scale ID
             
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   06/11/2013
    */
    PROCEDURE get_scale
    (
        i_noc_scale       IN noc_scale.id_noc_scale%TYPE,
        i_flg_option_none IN VARCHAR DEFAULT pk_alert_constant.g_yes,
        o_scale_info      OUT pk_types.cursor_type,
        o_scale_levels    OUT pk_types.cursor_type
    );

    /**
    * Gets a NOC Scale object
    *
    * @param    i_noc_scale            NOC Scale ID
    *
    * @return   t_obj_noc_scale        NOC Scale object
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   1/27/2014
    */
    FUNCTION get_scale(i_noc_scale IN noc_scale.id_noc_scale%TYPE) RETURN t_obj_noc_scale;

    /**
    * Get the name of a given scale level value
    *    
    * @param    i_lang                 Language ID
    * @param    i_noc_scale            NOC Scale ID
    * @param    i_scale_level_value    NOC Scale Level VALUE
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   06/11/2013
    */
    FUNCTION get_scale_level_name
    (
        i_lang              IN language.id_language%TYPE,
        i_noc_scale         IN noc_scale.id_noc_scale%TYPE,
        i_scale_level_value IN noc_scale_level.scale_level_value%TYPE
    ) RETURN VARCHAR2;
    /**
    * Gets the Scale ID that an NOC Outcome uses
    *    
    * @param    i_noc_outcome        NOC Outcome ID
    *
    * @return   NOC Scale ID
    *              
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   02/03/2014
    */
    FUNCTION get_outcome_scale(i_noc_outcome IN noc_outcome.id_noc_outcome%TYPE) RETURN noc_scale.id_noc_scale%TYPE;

    /**
    * Gets the Scale ID that an NOC Indicator associated with a NOC Outcome uses
    *    
    * @param    i_noc_outcome        NOC Outcome ID
    * @param    i_noc_indicator      NOC Indicator ID
    *
    * @return   NOC Scale ID
    *              
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   02/03/2014
    */
    FUNCTION get_indicator_scale
    (
        i_noc_outcome   IN noc_outcome.id_noc_outcome%TYPE,
        i_noc_indicator IN noc_indicator.id_noc_indicator%TYPE
    ) RETURN noc_scale.id_noc_scale%TYPE;

    /**
    * Gets the description of a scale level for a NOC Outcome
    *    
    * @param    i_lang                 Language ID     
    * @param    i_noc_outcome          NOC Outcome ID
    * @param    i_scale_level_value    Scale level value
    *
    * @return   The description of the scale level value
    *              
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   2/10/2014
    */
    FUNCTION get_outcome_scale_level_name
    (
        i_lang              IN language.id_language%TYPE,
        i_noc_outcome       IN noc_outcome.id_noc_outcome%TYPE,
        i_scale_level_value IN noc_scale_level.scale_level_value%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets the description of a scale level for a NOC Indicator
    *    
    * @param    i_lang                 Language ID     
    * @param    i_noc_outcome          NOC Outcome ID
    * @param    i_noc_indicator        NOC Indicator ID     
    * @param    i_scale_level_value    Scale level value
    *
    * @return   The description of the scale level value
    *              
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   2/10/2014
    */
    FUNCTION get_indicator_scale_level_name
    (
        i_lang              IN language.id_language%TYPE,
        i_noc_outcome       IN noc_outcome.id_noc_outcome%TYPE,
        i_noc_indicator     IN noc_indicator.id_noc_indicator%TYPE,
        i_scale_level_value IN noc_scale_level.scale_level_value%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets a NOC Indicator object that is associated with a NOC Outcome
    *    
    * @param    i_lang                 Language ID     
    * @param    i_noc_outcome          NOC Outcome ID
    * @param    i_noc_indicator        NOC Indicator ID     
    *
    * @return   t_obj_noc_indicator    NOC Indicator object
    *              
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   2/28/2014
    */
    FUNCTION get_noc_indicator
    (
        i_lang          IN language.id_language%TYPE,
        i_noc_outcome   IN noc_outcome.id_noc_outcome%TYPE,
        i_noc_indicator IN noc_indicator.id_noc_indicator%TYPE
    ) RETURN t_obj_noc_indicator;

    /**
    * Gets terminology information whose NOC Outcome belongs.
    *
    * @param    i_noc_outcome          NOC Outcome ID
    *
    * @return   Terminology infomation
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/14/2014
    */
    FUNCTION get_terminology_information(i_noc_outcome IN noc_outcome.id_noc_outcome%TYPE)
        RETURN pk_nnn_in.t_terminology_info_rec;

END pk_noc_model;
/
