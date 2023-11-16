/*-- Last Change Revision: $Rev: 1658137 $*/
/*-- Last Change by: $Author: ariel.machado $*/
/*-- Date of last change: $Date: 2014-11-10 11:21:37 +0000 (seg, 10 nov 2014) $*/

CREATE OR REPLACE PACKAGE pk_nic_model IS

    -- Author  : ARIEL.MACHADO
    -- Created : 9/25/2013 3:52:33 PM
    -- Purpose : Nursing Interventions Classification (NIC) Model : Methods to handle the classification data model

    -- Exceptions

    --An invalid NIC Domain not available in NIC_DOMAIN
    e_invalid_nic_domain EXCEPTION;

    --An invalid NIC Class not available in NIC_CLASS
    e_invalid_nic_class EXCEPTION;

    --An invalid NIC Intervention not available in NIC_INTERVENTION
    e_invalid_nic_intervention EXCEPTION;

    --An invalid parent NIC Activity not available in NIC_ACTIVITY or not defined as tasklist
    e_invalid_parent_nic_activity EXCEPTION;

    -- Public type declarations

    -- Public constant declarations

    -- Display the NIC code at start of the NIC Intervention label
    g_code_format_start CONSTANT sys_config.value%TYPE := 'S';
    -- Display the NIC code at end of the NIC Intervention label
    g_code_format_end CONSTANT sys_config.value%TYPE := 'E';
    -- Not display the NIC code in the NIC Intervention label
    g_code_format_none CONSTANT sys_config.value%TYPE := 'N';
    -- NIC code format mask
    g_nic_code_format CONSTANT VARCHAR2(4 CHAR) := '0000';

    -- Default ALERT content as institution owner of the record
    k_inst_owner_default CONSTANT nic.id_inst_owner%TYPE := 0;
    -- Public variable declarations

    -- Public function and procedure declarations
    /**
    * Insert/Update NIC Domains
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version
    * @param    i_domain_code          NIC Domain Code
    * @param    i_name                 NIC Domain label
    * @param    i_definition           NIC Domain definition
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
    PROCEDURE insert_into_nic_domain
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nic_domain.id_terminology_version%TYPE,
        i_domain_code         IN nic_domain.domain_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN nic_domain.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN nic_domain.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nic_domain.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nic_domain.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NIC Class
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version 
    * @param    i_domain_code          NIC Domain Code
    * @param    i_class_code           NIC Class Code
    * @param    i_name                 NIC Class label
    * @param    i_definition           NIC Class definition 
    * @param    i_rank                 Rank order
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version 
    * @param    i_concept_term 
    *
    * @throws  e_invalid_nic_domain
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   10/7/2013
    */
    PROCEDURE insert_into_nic_class
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nic_class.id_terminology_version%TYPE,
        i_domain_code         IN nic_domain.domain_code%TYPE,
        i_class_code          IN nic_class.class_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_rank                IN nic_class.rank%TYPE DEFAULT NULL,
        i_inst_owner          IN nic_class.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version     IN nic_class.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nic_class.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NIC Intervention
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version
    * @param    i_class_code           NIC Class Code
    * @param    i_intervention_code    NIC Intervention Code
    * @param    i_name                 NIC Intervention label
    * @param    i_definition           NIC Intervention definition
    * @param    i_references           References
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version 
    * @param    i_concept_term 
    *
    * @throws  e_invalid_nic_class
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   10/7/2013
    */
    PROCEDURE insert_into_nic_intervention
    (
        i_lang                IN language.id_language%TYPE,
        i_terminology_version IN nic_intervention.id_terminology_version%TYPE,
        i_class_code          IN nic_class.class_code%TYPE,
        i_intervention_code   IN nic_intervention.intervention_code%TYPE,
        i_name                IN pk_translation.t_desc_translation,
        i_definition          IN pk_translation.t_desc_translation,
        i_references          IN nic_intervention.references%TYPE DEFAULT NULL,
        i_inst_owner          IN nic_intervention.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept             IN nic.id_concept%TYPE DEFAULT NULL,
        i_concept_version     IN nic_intervention.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term        IN nic_intervention.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Insert/Update NIC Activity
    *
    * @param    i_lang                 Language ID
    * @param    i_terminology_version  Terminology version
    * @param    i_intervention_code    NIC Intervention Code
    * @param    i_activity_code        NIC Activity Code
    * @param    i_interv_activity_code NIC Activity Code within the NIC Intervention
    * @param    i_description          NIC Activity description
    * @param    i_flg_tasklist         This activity acts as a parent and involves a list of child activities as tasks. When value = "Y" this activity does not form part of the NIC Classification.
    * @param    i_flg_task             This activity acts as a child task.
    * @param    i_parent_activity_code The activity code of the parent that was defined as taskslist. Only used when i_flg_task=Y.
    * @param    i_inst_owner           Institution owner of the concept. Default 0 - ALERT
    * @param    i_concept_version 
    * @param    i_concept_term 
    *
    * @throws  e_invalid_nic_intervention, e_invalid_parent_nic_activity
    *    
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   10/7/2013
    */
    PROCEDURE insert_into_nic_activity
    (
        i_lang                 IN language.id_language%TYPE,
        i_terminology_version  IN nic_activity.id_terminology_version%TYPE,
        i_intervention_code    IN nic_intervention.intervention_code%TYPE,
        i_activity_code        IN nic_activity.activity_code%TYPE,
        i_interv_activity_code IN nic_interv_activity.interv_activity_code%TYPE,
        i_rank                 IN nic_interv_activity.rank%TYPE,
        i_description          IN pk_translation.t_desc_translation,
        i_flg_tasklist         IN nic_activity.flg_tasklist%TYPE DEFAULT pk_alert_constant.g_no,
        i_flg_task             IN nic_interv_activity.flg_task%TYPE DEFAULT pk_alert_constant.g_no,
        i_parent_activity_code IN nic_activity.activity_code%TYPE DEFAULT NULL,
        i_inst_owner           IN nic_activity.id_inst_owner%TYPE DEFAULT k_inst_owner_default,
        i_concept_version      IN nic_activity.id_concept_version%TYPE DEFAULT NULL,
        i_concept_term         IN nic_activity.id_concept_term%TYPE DEFAULT NULL
    );

    /**
    * Gets the formatted  description of a NIC Intervention according the rule to include the NIC code and additional text if applicable
    *
    * @param    i_label               NIC Intervention Label 
    * @param    i_nic_code            NIC Code 
    * @param    i_code_format         Formatting rule to display the NIC Code
    * @param    i_additional_info     Additional text to include in the description
    *
    * @value    i_code_format  {*} g_code_format_start {*} g_code_format_end {*} g_code_format_none
    *
    * @return   The formatted description of a given NIC Intervention
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since    2/20/2014
    */
    FUNCTION format_nic_name
    (
        i_label           IN pk_translation.t_desc_translation,
        i_nic_code        IN nic_intervention.intervention_code%TYPE,
        i_code_format     IN VARCHAR2,
        i_additional_info IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache;

    /**
    * Gets NIC Intervention Code
    *
    * @param    i_nic_intervention    NIC Intervention ID
    *
    * @return   NIC Intervention Code
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    13/11/2013
    */
    FUNCTION get_intervention_code(i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE)
        RETURN nic_intervention.intervention_code%TYPE;

    /**
    * Gets NIC Activity Code
    *
    * @param    i_nic_activity    NIC Activity ID
    *
    * @return   NIC Activity Code
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    13/11/2013
    */
    FUNCTION get_activity_code(i_nic_activity IN nic_activity.id_nic_activity%TYPE) RETURN nic_activity.activity_code%TYPE;

    /**
    * Gets the code of the association between the intervention and activity
    *
    * @param    i_nic_intervention    NIC Intervention ID
    * @param    i_nic_activity        NIC Activity ID
    *
    * @return   NIC Intervention Activity Code
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    13/11/2013
    */
    FUNCTION get_interv_activity_code
    (
        i_nic_intervention IN nic_interv_activity.id_nic_intervention%TYPE,
        i_nic_activity     IN nic_interv_activity.id_nic_activity%TYPE
    ) RETURN nic_interv_activity.interv_activity_code%TYPE;

    /**
    * Gets the NIC Intervention label
    *
    * @param    i_nic_intervention    NIC Intervention ID 
    * @param    i_code_format         Formatting rule to display the NIC Code
    * @param    i_additional_info     Additional text to include in the description 
           
    *
    * @return   The label of a given NIC intervention
    *
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3  
    * @since    2/11/2014
    */
    FUNCTION get_intervention_name
    (
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        i_code_format      IN VARCHAR2 DEFAULT g_code_format_none,
        i_additional_info  IN VARCHAR2 DEFAULT NULL
    ) RETURN pk_translation.t_desc_translation result_cache;

    /**
    * Gets NIC Activity Name
    *
    * @param    i_nic_activity    NIC Activity ID
    *
    * @return   The translation of the name of a given Activity
    *
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3 
    * @since    21/11/2013
    */
    FUNCTION get_activity_name(i_nic_activity IN nic_activity.id_nic_activity%TYPE)
        RETURN pk_translation.t_desc_translation result_cache;

    /**
    * Gets a NIC Intervention object
    *
    * @param    i_lang                    Language ID    
    * @param    i_nic_intervention        NIC Intervention ID
    *
    * @return   t_obj_nic_intervention    NIC Intervention object
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   3/3/2014
    */
    FUNCTION get_nic_intervention
    (
        i_lang             IN language.id_language%TYPE,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE
    ) RETURN t_obj_nic_intervention;

    /**
    * Gets a NIC Activity object
    *
    * @param    i_lang                Language ID    
    * @param    i_nic_intervention    NIC Intervention ID
    * @param    i_nic_activity        NIC Activity ID    
    *
    * @return   t_obj_nic_activity    NIC Intervention object
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   3/3/2014
    */
    FUNCTION get_nic_activity
    (
        i_lang             IN language.id_language%TYPE,
        i_nic_intervention IN nic_interv_activity.id_nic_intervention%TYPE,
        i_nic_activity     IN nic_interv_activity.id_nic_activity%TYPE
    ) RETURN t_obj_nic_activity;

    /**
    * Check if this NIC Activity acts as a parent and involves a list of child activities as tasks.
    *
    * @param    i_nic_activity        NIC Activity ID    
    *
    * @return   is_tasklist
    
    * @value    is_tasklist {*} pk_alert_constant.g_yes {*} pk_alert_constant.g_no
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   9/26/2014
    */
    FUNCTION is_tasklist(i_nic_activity IN nic_activity.id_nic_activity%TYPE) RETURN nic_activity.flg_tasklist%TYPE result_cache;

    /**
    * Gets terminology information whose NIC Intervention belongs.
    *
    * @param    i_nic_intervention    NIC Intervention ID
    *
    * @return   Terminology infomation
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3 
    * @since   7/14/2014
    */
    FUNCTION get_terminology_information(i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE)
        RETURN pk_nnn_in.t_terminology_info_rec;
END pk_nic_model;
/
