/*-- Last Change Revision: $Rev: 2028626 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:58 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_dynamic_screen AS

    --
    -- PUBLIC CONSTANTS
    --

    -- Component types
    c_root_component CONSTANT ds_component.flg_component_type%TYPE := 'R';
    c_node_component CONSTANT ds_component.flg_component_type%TYPE := 'N';
    c_leaf_component CONSTANT ds_component.flg_component_type%TYPE := 'L';

    c_data_type_n   CONSTANT ds_component.flg_data_type%TYPE := 'N'; -- Number
    c_data_type_ms  CONSTANT ds_component.flg_data_type%TYPE := 'MS'; -- Multichoice of single selection
    c_data_type_mm  CONSTANT ds_component.flg_data_type%TYPE := 'MM'; -- Multichoice of multiple selection
    c_data_type_fr  CONSTANT ds_component.flg_data_type%TYPE := 'FR'; -- Form
    c_data_type_ft  CONSTANT ds_component.flg_data_type%TYPE := 'FT'; -- Free text
    c_data_type_dt  CONSTANT ds_component.flg_data_type%TYPE := 'DT'; -- Date time
    c_data_type_dtp CONSTANT ds_component.flg_data_type%TYPE := 'DTP'; -- Date time partial
    c_data_type_dp  CONSTANT ds_component.flg_data_type%TYPE := 'DP'; -- Date partial
    c_data_type_cmp CONSTANT ds_component.flg_data_type%TYPE := 'CMP'; -- Complication multichoice
    -- Multichoice types
    c_ms_data_type CONSTANT ds_component.flg_data_type%TYPE := c_data_type_ms;
    c_mo_data_type CONSTANT ds_component.flg_data_type%TYPE := 'MO';
    c_mt_data_type CONSTANT ds_component.flg_data_type%TYPE := 'MT';
    c_mr_data_type CONSTANT ds_component.flg_data_type%TYPE := 'MR';
    c_data_type_k  CONSTANT ds_component.flg_data_type%TYPE := 'K';
    c_data_type_mf CONSTANT ds_component.flg_data_type%TYPE := 'MF';

    -- Index values for the data structure
    c_n_columns           CONSTANT PLS_INTEGER := 9;
    c_name_idx            CONSTANT PLS_INTEGER := 1;
    c_desc_idx            CONSTANT PLS_INTEGER := 2;
    c_val_idx             CONSTANT PLS_INTEGER := 3;
    c_alt_val_idx         CONSTANT PLS_INTEGER := 4;
    c_hist_idx            CONSTANT PLS_INTEGER := 5;
    c_diag_desc_idx       CONSTANT PLS_INTEGER := 5;
    c_flg_other_idx       CONSTANT PLS_INTEGER := 6;
    c_other_diag_desc_idx CONSTANT PLS_INTEGER := 7;
    c_key                 CONSTANT PLS_INTEGER := 8;
    c_epis_diag_idx       CONSTANT PLS_INTEGER := 9;
    --

    k_dp_mode_mmyyyy CONSTANT VARCHAR2(0050) := 'PARTIAL_DATE_MMYYYY';
    k_dp_mode_yyyy   CONSTANT VARCHAR2(0050) := 'PARTIAL_DATE_YYYY';
    k_dp_mode_full   CONSTANT VARCHAR2(0050) := 'FULL_DATE';
    k_dt_output_01   CONSTANT VARCHAR2(0050 CHAR) := 'date_char_tsz';
    k_dt_output_02   CONSTANT VARCHAR2(0050 CHAR) := 'date_chr_short_read_tsz';

    -- Unit Measures IDs
    g_id_unit_measure_year  CONSTANT unit_measure.id_unit_measure%TYPE := 27217;
    g_id_unit_measure_month CONSTANT unit_measure.id_unit_measure%TYPE := 1127;
    g_id_unit_measure_week  CONSTANT unit_measure.id_unit_measure%TYPE := 10375;
    g_id_unit_measure_day   CONSTANT unit_measure.id_unit_measure%TYPE := 1039;
    g_id_unit_measure_hour  CONSTANT unit_measure.id_unit_measure%TYPE := 1041;

    g_event_mandatory CONSTANT VARCHAR2(1) := 'M';
    g_event_active    CONSTANT VARCHAR2(1) := 'A';
    g_event_inactive  CONSTANT VARCHAR2(1) := 'I';
    g_event_exclusive CONSTANT VARCHAR2(1) := 'E';

    g_age_min CONSTANT VARCHAR2(3) := 'MIN';
    g_age_max CONSTANT VARCHAR2(3) := 'MAX';
    -- PUBLIC FUNCTIONS
    --
    PROCEDURE set_data_key(i_value_key IN NUMBER);

    /**********************************************************************************************
    * Returns tree-like relations between components below a certain component
    *
    * @param        i_prof                   professional, software and institution ids
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        i_component_list         (Y/N) If Y(es) it returns only a list of child components
    *                                        and not the entire structure (defaults to N)
    *
    * @return       Tree-like relations between components
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION get_cmp_rel
    (
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_child%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_child%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL
    ) RETURN tf_ds_section;

    FUNCTION get_cmp_rel_child
    (
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_child%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_child%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL
    ) RETURN tf_ds_section;

    /**********************************************************************************************
    * Get a dynamic screen section structure
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        i_component_list         (Y/N) If Y(es) it returns only a list of child components
    *                                        and not the entire structure (defaults to N)
    * @param        o_section                Section components structure
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION get_ds_section
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
                        i_filter  in varchar2 default null,
        o_section        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION get_ds_section_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        o_section        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION get_ds_section_events_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION get_ds_section_events_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        o_section        OUT t_table_ds_sections,
        o_def_events     OUT t_table_ds_def_events,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION get_ds_section_complete_struct
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL,
                i_filter  in varchar2 default null, 
        o_section        OUT t_table_ds_sections,
        o_def_events     OUT t_table_ds_def_events,
        o_events         OUT t_table_ds_events,
        o_items_values   OUT t_table_ds_items_values,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ds_section_complete_struct
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_events         OUT pk_types.cursor_type,
        o_items_values   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_diag_str
    (
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar
    ) RETURN VARCHAR2;

    FUNCTION get_value_str
    (
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar,
        i_orig_val       IN VARCHAR2 DEFAULT NULL,
        i_alt_val        IN BOOLEAN DEFAULT FALSE
    ) RETURN VARCHAR2;

    --

    FUNCTION get_value_number
    (
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar,
        i_orig_val       IN NUMBER DEFAULT NULL,
        i_alt_val        IN BOOLEAN DEFAULT FALSE
    ) RETURN NUMBER;

    --

    FUNCTION get_value_tstz
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar,
        i_orig_val       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_alt_val        IN BOOLEAN DEFAULT FALSE,
        i_flg_partial_dt IN VARCHAR2 DEFAULT NULL
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    --

    FUNCTION add_value_tstz
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_data_val  IN table_table_varchar,
        i_name      IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_desc_mode IN VARCHAR2 DEFAULT k_dt_output_01,
        i_hist      IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    --

    FUNCTION add_value_prof
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN professional.id_professional%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    --

    FUNCTION add_value_sl
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN sys_list.id_sys_list%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;
    --

    FUNCTION add_value_slms
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN NUMBER,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    --

    FUNCTION add_value_text
    (
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN VARCHAR2,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    --

    FUNCTION add_value_fr
    (
        i_lang     IN language.id_language%TYPE,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN family_relationship.id_family_relationship%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    --
    FUNCTION add_value_k
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN NUMBER,
        i_um       IN NUMBER,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;
    --

    FUNCTION add_value_adt
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN NUMBER,
        i_type     IN VARCHAR2 DEFAULT NULL,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    FUNCTION add_value_epis_diagn
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    FUNCTION add_value_diagn
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_data_val   IN table_table_varchar,
        i_name       IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value      IN death_cause.id_death_cause%TYPE,
        i_value_hist IN death_cause_hist.id_death_cause_hist%TYPE,
        i_hist       IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    --

    FUNCTION add_value_pat_hist_diagn
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN pat_history_diagnosis.id_pat_history_diagnosis%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    --

    FUNCTION add_value_org_tis
    (
        i_lang     IN language.id_language%TYPE,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN organ_tissue.id_organ_tissue%TYPE,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    --

    FUNCTION get_registry_prof_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_registry_date IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_prof_registry IN professional.id_professional%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_status    IN VARCHAR2,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel  IN CLOB,
        o_prof_data     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION get_death_registry_prof_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_tbl_id    IN table_number,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION get_organ_donor_prof_data
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_tbl_id    IN table_number,
        o_prof_data OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_ds_items_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL
    ) RETURN t_table_ds_items_values;
    /**********************************************************************************************
    * Determines if the patient age is within the limits defined to the ds_component or ds_cmp_mkt_rel
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional info
    * @param i_pat_age                Patient age
    * @param i_age_limit              Limit to check (minimum or maximum)
    * @param i_limit_type             (MIN) Check minimum; (MAX) Check maximum;
    *
    * @return                         Y - Value within the limits; N - Value not within the limits.
    *
    * @author                         Sergio Dias
    * @version                        2.6.3.8.5
    * @since                          Nov/26/2013
    **********************************************************************************************/
    FUNCTION check_age_limits
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_pat_age    IN NUMBER,
        i_age_limit  IN NUMBER,
        i_limit_type IN VARCHAR2
    ) RETURN VARCHAR2;
    /**********************************************************************************************
    * Get a dynamic screen section structure
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        i_component_list         (Y/N) If Y(es) it returns only a list of child components
    *                                        and not the entire structure (defaults to N)
    * @param        o_section                Section components structure
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION tf_ds_sections
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL,
                i_filter  in varchar2 default null
    ) RETURN t_table_ds_sections;

    FUNCTION tf_ds_sections1
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL
    ) RETURN t_table_ds_sections;

    /**********************************************************************************************
    * Get a dynamic screen section structure
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    *
    * @return       Component record
    *
    * @author       Alexandre Santos
    * @version      2.6.1
    * @since        26-12-2012
    **********************************************************************************************/
    FUNCTION get_ds_section_rec
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component
    ) RETURN t_rec_ds_sections;

    /**********************************************************************************************
    * Get dynamic screen section events
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        o_events                 Section events
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION tf_ds_events_cmf
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component
    ) RETURN t_table_ds_events;

    FUNCTION tf_ds_events
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_patient        IN NUMBER DEFAULT NULL,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL
    ) RETURN t_table_ds_events;

    /**********************************************************************************************
    * Get dynamic screen section default events
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        i_component_list         (Y/N) If Y(es) it returns only the default events for
    *                                        the child components
    *                                        and not for all componentsthe entire structure (defaults to N(o))
    * @param        o_def_events             Section default events
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        07-Jun-2010
    **********************************************************************************************/
    FUNCTION tf_ds_def_events
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_component_root IN ds_cmpt_mkt_rel.internal_name_parent%TYPE DEFAULT NULL
    ) RETURN t_table_ds_def_events;

    /**********************************************************************************************
    * Get ds_event id. This function is used in triage to create dynamic events to vital signs fields
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids
    * @param        i_component_name         Component internal name
    * @param        i_value                  Event value
    *
    * @return       Event id
    *
    * @author       Alexandre Santos
    * @version      2.6.1
    * @since        31-01-2013
    **********************************************************************************************/
    FUNCTION get_ds_event_id
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_child%TYPE,
        i_value          IN ds_event.value%TYPE
    ) RETURN ds_event.id_ds_event%TYPE;

    /**********************************************************************************************
    * Calculate the correct component rank
    *
    * @param        i_tbl_section         Section table
    * @param        i_ds_cmpt_mkt_rel     PK column
    *
    * @return       Rank of the request PK
    *
    * @author       Alexandre Santos
    * @version      2.6.3
    * @since        05-08-2013
    **********************************************************************************************/
    FUNCTION get_section_rank
    (
        i_tbl_section     IN t_table_ds_sections,
        i_ds_cmpt_mkt_rel IN ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE
    ) RETURN ds_cmpt_mkt_rel.rank%TYPE;

    FUNCTION check_unit_measure_fields
    (
        i_unit_measure         IN NUMBER,
        i_unit_measure_subtype IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_dyn_umea
    (
        i_lang                 IN NUMBER,
        i_prof                 IN profissional,
        i_ds_component         IN NUMBER,
        i_unit_measure         IN NUMBER,
        i_unit_measure_subtype IN NUMBER
    ) RETURN t_tbl_dyn_umea;

    FUNCTION add_value_fc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN NUMBER,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    FUNCTION get_dp_mode(i_date IN VARCHAR2) RETURN VARCHAR2;

    FUNCTION get_dt_format
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_component_name IN VARCHAR2,
        i_data_val       IN table_table_varchar
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get a dynamic root node from first section
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   professional, software and institution ids
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    *
    * @return       array : first pos is component name, second pos is flg_component_type
    *
    * @author       Carlos Ferreira
    * @version      2.7.1
    * @since        24-08-2017
    **********************************************************************************************/
    FUNCTION get_ds_section_root
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_component_name IN VARCHAR2,
        i_component_type IN VARCHAR2 DEFAULT c_node_component
    ) RETURN table_varchar;

    FUNCTION process_mx_partial_dt
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_dt_exists IN VARCHAR2,
        i_value     IN death_registry.dt_death%TYPE,
        i_dt_format IN VARCHAR2,
        i_type      IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION check_age_value
    (
        i_age_min_value IN NUMBER,
        i_age_max_value IN NUMBER,
        i_gender1       IN VARCHAR2,
        i_gender2       IN VARCHAR2,
        i_pat_gender    IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_id_epis_diag
    (
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar
    ) RETURN VARCHAR2;

    FUNCTION add_values_all
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_data_val IN table_table_varchar,
        i_name     IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_value    IN NUMBER,
        i_text     IN VARCHAR2,
        i_hist     IN NUMBER DEFAULT NULL
    ) RETURN table_table_varchar;

    FUNCTION get_ds_rep_section
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_section_name   IN VARCHAR2,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT c_node_component,
        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_patient        IN patient.id_patient%TYPE DEFAULT NULL,
        o_section        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rep_component_desc
    (
        i_lang               IN NUMBER,
        i_section_name       IN VARCHAR2,
        i_id_ds_cmpt_kmt_rel IN NUMBER
    ) RETURN VARCHAR2;
    
    -- ****************************************************
    FUNCTION get_component_desc
    (
        i_lang         IN NUMBER,
        i_ds_component IN NUMBER
    ) RETURN VARCHAR2;

END pk_dynamic_screen;
/
