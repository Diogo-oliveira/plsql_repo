/*-- Last Change Revision: $Rev: 1857413 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2018-07-27 09:59:52 +0100 (sex, 27 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_nic_cfg IS

    -- Author  : CRISTINA.OLIVEIRA
    -- Created : 25/10/2013 10:42:19 AM
    -- Purpose : NIC Nursing Interventions : Methods to handle the settings of institution for this classification

    -- Public type declarations
    TYPE t_nic_cfg_intervention_rec IS RECORD(
        id_nic_cfg_intervention nic_cfg_intervention.id_nic_cfg_intervention%TYPE,
        flg_status              nic_cfg_intervention.flg_status%TYPE,
        dt_last_update          nic_cfg_intervention.dt_last_update%TYPE,
        id_nic_intervention     nic_intervention.id_nic_intervention%TYPE,
        id_terminology_version  nic_intervention.id_terminology_version%TYPE,
        intervention_code       nic_intervention.intervention_code%TYPE,
        code_name               nic_intervention.code_name%TYPE,
        code_definition         nic_intervention.code_definition%TYPE,
        references              nic_intervention.references%TYPE,
        id_nic_class            nic_class_interv.id_nic_class%TYPE,
        id_language             terminology_version.id_language%TYPE);
    TYPE t_nic_cfg_intervention_coll IS TABLE OF t_nic_cfg_intervention_rec;
    TYPE t_nic_cfg_intervention_cur IS REF CURSOR RETURN t_nic_cfg_intervention_rec;

    TYPE t_nic_cfg_activity_rec IS RECORD(
        id_nic_cfg_activity    nic_cfg_activity.id_nic_cfg_activity%TYPE,
        flg_status             nic_cfg_activity.flg_status%TYPE,
        dt_last_update         nic_cfg_activity.dt_last_update%TYPE,
        id_nic_activity        nic_activity.id_nic_activity%TYPE,
        id_terminology_version nic_activity.id_terminology_version%TYPE,
        interv_activity_code   nic_interv_activity.interv_activity_code%TYPE,
        code_description       nic_activity.code_description%TYPE,
        flg_tasklist           nic_activity.flg_tasklist%TYPE,
        rank                   nic_interv_activity.rank%TYPE,
        id_language            terminology_version.id_language%TYPE,
        flg_prn                nic_cfg_activity.flg_prn%TYPE,
        code_notes_prn         nic_cfg_activity.code_notes_prn%TYPE,
        flg_time               nic_cfg_activity.flg_time%TYPE,
        flg_priority           nic_cfg_activity.flg_priority%TYPE,
        id_order_recurr_option nic_cfg_activity.id_order_recurr_option%TYPE,
        flg_doc_type           nic_cfg_activity.flg_doc_type%TYPE,
        doc_parameter          nic_cfg_activity.doc_parameter%TYPE);
    TYPE t_nic_cfg_activity_coll IS TABLE OF t_nic_cfg_activity_rec;
    TYPE t_nic_cfg_activity_cur IS REF CURSOR RETURN t_nic_cfg_activity_rec;

    TYPE t_nic_activity_doctype IS RECORD(
        flg_tasklist       nic_activity.flg_tasklist%TYPE,
        flg_doc_type       nic_cfg_activity.flg_doc_type%TYPE,
        desc_doc_type      pk_translation.t_desc_translation,
        doc_parameter      nic_cfg_activity.doc_parameter%TYPE,
        desc_doc_parameter pk_translation.t_desc_translation,
        id_doc_area        doc_area.id_doc_area%TYPE);

    TYPE t_nic_cfg_actv_supply IS RECORD(
        id_nic_activity      nic_activity.id_nic_activity%TYPE,
        id_nic_othr_activity nic_cfg_actv_supply.id_nic_othr_activity%TYPE,
        id_supply            nic_cfg_actv_supply.id_supply%TYPE,
        quantity             nic_cfg_actv_supply.quantity%TYPE,
        desc_supply          pk_translation.t_desc_translation,
        id_supply_soft_inst  supply_soft_inst.id_supply_soft_inst%TYPE);
    TYPE t_nic_cfg_actv_supply_coll IS TABLE OF t_nic_cfg_actv_supply;
    TYPE t_nic_cfg_actv_supply_cur IS REF CURSOR RETURN t_nic_cfg_actv_supply;

    -- Public constant declarations 
    k_default_bulk_limit CONSTANT PLS_INTEGER := 100; --Default LIMIT option for bulk collect statements

    g_activity_doctype_free_text  CONSTANT nic_cfg_activity.flg_doc_type%TYPE := 'N'; --    Activity execution documented by free-text notes
    g_activity_doctype_template   CONSTANT nic_cfg_activity.flg_doc_type%TYPE := 'T'; --    Activity execution documented by Touch-option templates
    g_activity_doctype_vital_sign CONSTANT nic_cfg_activity.flg_doc_type%TYPE := 'V'; --    Activity execution documented by Vital Sign measurements
    g_activity_doctype_biometrics CONSTANT nic_cfg_activity.flg_doc_type%TYPE := 'B'; --    Activity execution documented by Biometrics measurements    

    g_dom_activity_flg_doc_type CONSTANT sys_domain.code_domain%TYPE := 'NIC_CFG_ACTIVITY.FLG_DOC_TYPE'; -- Documentation type for NIC Activities

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Gets the NIC Interventions configured for an institution
    *
    * @param    i_inst   Institution ID
    * @param    i_soft                 Software ID
    * @param   i_limit                 Optional bulk collect limit. Default: Use the recommended default value.
    * @param   i_ignore_parent_class   Ignore the parent NIC Class and return just one row for each NIC Intervention regardless of they are included in more than one class. 
    *                                  NIC Interventions are grouped hierarchically into classes within domains 
    *                                  but there are a few interventions located in more than one class. 
    *                                  The flag i_ignore_parent_class is used to return just the distinct NIC Interventions 
    *                                  regardless of they are included in more than one class.
    *                                  Notice when i_ignore_parent_class = 'Y' the field id_nic_class will be null.
    *   
    * @value    i_ignore_parent_class      {*} 'Y' Returns one row for each NIC Intervention  {*} 'N'  Returns multiple rows of the NIC Intervention, one for each NIC class that is related
    *
    * @return  Collection of NIC Interventions (pipelined)
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   25/10/2013
    */
    FUNCTION tf_inst_intervention
    (
        i_inst                IN institution.id_institution%TYPE,
        i_soft                IN software.id_software%TYPE DEFAULT NULL,
        i_limit               IN PLS_INTEGER DEFAULT pk_nic_cfg.k_default_bulk_limit,
        i_ignore_parent_class IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_nic_cfg_intervention_coll
        PIPELINED;

    /**
    * Gets the NIC Activities configured for an institution
    *
    * @param    i_inst   Institution ID
    * @param    i_soft   Software ID
    * @param    i_nic_intervention  NIC Intervention ID
    * @param    i_limit  Optional bulk collect limit. Default: Use the recommended default value.
    *   
    * @return   Collection of NIC Interventions (pipelined)
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   25/10/2013
    */
    FUNCTION tf_inst_activity
    (
        i_inst             IN institution.id_institution%TYPE,
        i_soft             IN software.id_software%TYPE DEFAULT NULL,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        i_limit            IN PLS_INTEGER DEFAULT pk_nic_cfg.k_default_bulk_limit
    ) RETURN t_nic_cfg_activity_coll
        PIPELINED;

    /**
    * Gets the NIC Activities configured for an institution
    *
    * @param    i_inst   Institution ID
    * @param    i_soft   Software ID
    * @param    i_limit  Optional bulk collect limit. Default: Use the recommended default value.
    *   
    * @return   Collection of NIC Interventions (pipelined)
    *    
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   25/10/2013
    */
    FUNCTION tf_inst_activity
    (
        i_inst  IN institution.id_institution%TYPE,
        i_soft  IN software.id_software%TYPE DEFAULT NULL,
        i_limit IN PLS_INTEGER DEFAULT pk_nic_cfg.k_default_bulk_limit
    ) RETURN t_nic_cfg_activity_coll
        PIPELINED;

    /**
    * Gets the NIC Interventions configured for an institution
    *
    * @param    i_lang                 Language ID    
    * @param    i_prof                 Profissional
    * @param    i_include_inactive     Returns also diagnoses configured as inactive for the institution
    * @param    i_paging               Use paging ('Y' Yes; 'N' No) Default 'N' 
    * @param    i_startindex           The index of the first item. startIndex is 1-based
    * @param    i_items_per_page       The number of items per page
    * @param    o_interventions        Collection of NIC Intervention
    * @param    o_total_items          The total number of NIC Intervention available
    *
    * @value    i_include_inactive      {*} 'Y'  Include inactive diagnoses {*} 'N'  Exclude inactive diagnoses
    * @value    i_paging                {*} 'Y'  Paging enabled {*} 'N'  No paging
    *    
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    28/10/2013
    */
    PROCEDURE get_inst_interventions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_include_inactive IN nan_cfg_diagnosis.flg_status%TYPE DEFAULT 'N',
        i_paging           IN VARCHAR2 DEFAULT 'N',
        i_startindex       IN NUMBER DEFAULT 1,
        i_items_per_page   IN NUMBER DEFAULT 10,
        o_interventions    OUT pk_types.cursor_type,
        o_total_items      OUT NUMBER
    );

    /**
    * Gets the NIC Interventions configured in NAN_NOC_NIC_LINKAGE for an institution 
    * and NOC Outcome ID/NAN Diagnosis ID
    *    
    * @param    i_prof           Profissional
    * @param    i_noc_outcome    NOC Outcome ID
    * @param    i_nan_diagnosis  NAN Diagnosis ID
    *    
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    30/10/2013
    */
    PROCEDURE get_inst_interventions
    (
        i_prof          IN profissional,
        i_noc_outcome   IN noc_outcome.id_noc_outcome %TYPE,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        o_interventions OUT pk_types.cursor_type
    );

    /**
    * Gets the NIC Interventions configured in NAN_NOC_NIC_LINKAGE for an institution and NAN Diagnosis ID
    *    
    * @param    i_prof           Profissional
    * @param    i_nan_diagnosis  NAN Diagnosis ID
    *    
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    30/10/2013
    */
    PROCEDURE get_inst_interventions
    (
        i_prof          IN profissional,
        i_nan_diagnosis IN nan_diagnosis.id_nan_diagnosis%TYPE,
        o_interventions OUT pk_types.cursor_type
    );

    /**
    * Gets the NIC Activities configured for an institution and NIC Intervention ID
    *    
    * @param    i_prof              Profissional
    * @param    i_nic_intervention  NIC Intervention ID
    *    
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    30/10/2013
    */
    PROCEDURE get_inst_activities
    (
        i_prof             IN profissional,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        o_activities       OUT pk_types.cursor_type
    );

    /**
    * Gets the NIC Activities configured for an institution 
    *
    * @param    i_lang                 Language ID    
    * @param    i_prof                 Profissional
    * @param    i_include_inactive     Returns also diagnoses configured as inactive for the institution
    * @param    i_paging               Use paging ('Y' Yes; 'N' No) Default 'N' 
    * @param    i_startindex           The index of the first item. startIndex is 1-based
    * @param    i_items_per_page       The number of items per page
    * @param    o_activities           Collection of NIC Activities
    * @param    o_total_items          The total number of NIC Activities available
    *
    * @value    i_include_inactive      {*} 'Y'  Include inactive diagnoses {*} 'N'  Exclude inactive diagnoses
    * @value    i_paging                {*} 'Y'  Paging enabled {*} 'N'  No paging
    *    
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    28/10/2013
    */
    PROCEDURE get_inst_activities
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_include_inactive IN nan_cfg_diagnosis.flg_status%TYPE DEFAULT 'N',
        i_paging           IN VARCHAR2 DEFAULT 'N',
        i_startindex       IN NUMBER DEFAULT 1,
        i_items_per_page   IN NUMBER DEFAULT 10,
        o_activities       OUT pk_types.cursor_type,
        o_total_items      OUT NUMBER
    );

    /**
    * Gets list of child activities tasks of a NIC Activity that acts as a parent in the context of an Intervention for an  institution
    *    
    * @param    i_prof              Profissional
    * @param    i_nic_intervention  NIC Intervention ID
    * @param    i_nic_activity      NIC Activity ID that was defined as tasklist (this activity acts as a parent)
    * @param    o_activity_tasks    List of child NIC activities defined as tasks
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    9/29/2014
    */
    PROCEDURE get_inst_activity_tasks
    (
        i_prof             IN profissional,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        i_nic_activity     IN nic_activity.id_nic_activity%TYPE,
        o_activity_tasks   OUT pk_types.cursor_type
    );

    /**
    * Set NIC Intervention status to Active/Inactive for an institution and NIC Intervention ID
    *
    * @param    i_institution       Institution ID 
    * @param    i_nic_intervention  NIC Intervention ID 
    * @param    i_flg_status        Status
    *
    * @value    i_flg_status           {*} 'A'  Active {*} 'I'  Inactive
    *    
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    25/10/2013
    */
    PROCEDURE set_inst_intervention_status
    (
        i_institution      IN nic_cfg_intervention.id_institution%TYPE,
        i_nic_intervention IN nic_cfg_intervention.id_nic_intervention%TYPE,
        i_flg_status       IN nic_cfg_intervention.flg_status%TYPE
    );

    /**
    * Set NIC Activity status to Active/Inactive for an institution
    * and NIC Intervention ID/NIC Activity ID
    *
    * @param    i_institution       Institution ID 
    * @param    i_nic_intervention  NIC Intervention ID 
    * @param    i_nic_activity      NIC Activity ID 
    * @param    i_flg_status        Status
    *
    * @value    i_flg_status           {*} 'A'  Active {*} 'I'  Inactive
    *    
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    25/10/2013
    */
    PROCEDURE set_inst_activity_status
    (
        i_institution  IN nic_cfg_activity.id_institution%TYPE,
        i_nic_activity IN nic_cfg_activity.id_nic_activity%TYPE,
        i_flg_status   IN nic_cfg_activity.flg_status%TYPE
    );

    /**
    * Procedure that resolves bind variables required for the filter NICInterventionByInstitution
    *
    * @param    i_context_ids   Static contexts (i_prof, i_lang, i_episode,...)  
    * @param    i_context_vals  Custom contexts, sent from the user interface
    * @param    i_name          Name of the bind variable to ge 
    * @param    o_vc2           Varchar2 value returned by the procedure 
    * @param    o_num           Numeric value returned by the procedure 
    * @param    o_id            NUMBER(24) value returned by the procedure 
    * @param    o_tstz          Timestamp value returned by the procedure 
    *    
    * @author   CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since    25/10/2013
    */
    PROCEDURE init_fltr_params_nic
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
    * Search NIC Intervention by label or Code
    *
    * @param    i_inst              Institution ID
    * @param    i_soft              Software ID
    * @param    i_search            The string to be searched
    *   
    * @return   The correspondent matches from the NIC Interventions
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    2/20/2014
    */
    FUNCTION get_search_by_code_or_text
    (
        i_inst   IN institution.id_institution%TYPE,
        i_soft   IN software.id_software%TYPE,
        i_search IN pk_translation.t_desc
    ) RETURN table_t_search;

    /**
    * Evaluates if a NIC Intervention and a NIC Activity can be linked between them
    *
    * @param    i_prof                     Profissional
    * @param    i_nic_intervention        NIC Intervention ID 
    * @param    i_nic_activity            NIC Activity ID 
    *   
    * @return   'Y' if it is a valid linkage
    *    
    * @author   ARIEL.MACHADO
    * @version  2.6.4.3
    * @since    12/27/2013
    */
    FUNCTION is_linkable_interv_activity
    (
        i_prof             IN profissional,
        i_nic_intervention IN nic_intervention.id_nic_intervention%TYPE,
        i_nic_activity     IN nic_activity.id_nic_activity%TYPE
    ) RETURN VARCHAR2;

    /**
    * Gets information about type of documentation to be used when executing a NIC Activity
    *
    * @param    i_lang              Language ID
    * @param    i_prof              Professional
    * @param    i_subject           Action subject
    * @param    i_nic_activity      NIC Activity ID
    *
    * @return  Record with info about documentation type to be used
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   01/10/2014
    */
    FUNCTION get_activity_doctype
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_nic_activity IN nic_activity.id_nic_activity%TYPE
    ) RETURN t_nic_activity_doctype;

    /**
    * Gets information about average duration of a NIC Activity
    *
    * @param    i_lang              Language ID
    * @param    i_prof              Professional
    * @param    i_nic_activity      NIC Activity ID
    * @param    o_avg_duration      Average Duration or zero if average wasn't defined for this activity
    * @param    o_uom_duration      Unit of measure ID used to define the avg duration (minute, hour, day, week, month, year)
    *
    * @author  ARIEL.MACHADO
    * @version  2.6.4.3
    * @since   09/26/2014
    */
    PROCEDURE get_activity_avg_duration
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_nic_activity IN nic_activity.id_nic_activity%TYPE,
        o_avg_duration OUT nic_cfg_activity.avg_duration%TYPE,
        o_uom_duration OUT nic_cfg_activity.id_unit_measure_duration%TYPE
    );

    /**
    * Gets a list of supplies associated a list of NIC Activities 
    *
    * @param    i_lang              Language ID
    * @param    i_prof              Professional
    * @param    i_lst_nic_activity  list NIC Activity ID
    *
    * @return  t_coll_obj_nic_activity_supply    NIC Activity Supply collection object
    *
    * @author  CRISTINA.OLIVEIRA
    * @version  2.6.4.3
    * @since   04/04/2014
    */
    FUNCTION tf_nic_activity_supply
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_lst_nic_activity IN table_number
    ) RETURN t_coll_obj_nic_activity_supply;
END pk_nic_cfg;
/
