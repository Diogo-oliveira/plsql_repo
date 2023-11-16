/*-- Last Change Revision: $Rev: 2028591 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_death_registry AS

    --
    -- PUBLIC CONSTANTS
    --

    -- Flag for signaling death as the reason for workflows suspension
    c_flg_reason_death CONSTANT VARCHAR2(1 CHAR) := 'D';
    -- Generic message for cancel reason by death
    c_code_msg_death CONSTANT sys_message.code_message%TYPE := 'PATIENT_DEATH_M002';

    --
    -- PUBLIC FUNCTIONS
    --

    /**********************************************************************************************
    * Returns the patient death registry id
    *
    * @param        i_lang                   Language id
    * @param        i_patient                Patient id
    * @param        o_death_registry         Death registry id (null if patient has none)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_death_registry
    (
        i_lang           IN language.id_language%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        o_death_registry OUT death_registry.id_death_registry%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns death registry summary
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_component_name         Component internal name
    * @param        i_component_type         Component type (defaults to node component type)
    * @param        o_section                Section components structure
    * @param        o_data_val               Components values
    * @param        o_prof_data              Professional who has made the changes (name,
    *                                        speciality and date of changes)
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_dr_summary
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION get_dr_section_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_section OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION get_dr_section_events_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_section    OUT pk_types.cursor_type,
        o_def_events OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION get_dr_section_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN NUMBER,
        i_death_registry IN NUMBER,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_events         OUT pk_types.cursor_type,
        o_items_values   OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION set_dr_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_death_registry IN NUMBER,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_data_val       IN table_table_varchar,
        o_id_section     OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Set suspension action id for a patient death registry
    *
    * @param        i_lang                   Language id
    * @param        i_death_registry         Death registry id
    * @param        i_id_susp_action         Suspension action id
    * @param        o_death_registry         Updated death registry id
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        22-Jun-2010
    **********************************************************************************************/
    FUNCTION set_death_registry_susp_action
    (
        i_lang           IN language.id_language%TYPE,
        i_death_registry IN death_registry.id_death_registry%TYPE,
        i_id_susp_action IN death_registry.id_susp_action%TYPE,
        o_death_registry OUT death_registry.id_death_registry%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns patient final diagnosis for this episode
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_episode                Episode id
    * @param        o_diagnosis              Cursor with patient final diagnosis
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        10-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_disch_diagnosis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancel death registry
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        i_episode                Episode id
    * @param        i_cancel_reason          Cancel reason id
    * @param        i_notes_cancel           Cancel notes
    * @param        i_component_name         Component internal name
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        17-Jun-2010
    **********************************************************************************************/
    FUNCTION cancel_death_registry
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_death_registry IN NUMBER,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel   IN death_registry.notes_cancel%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_susp_action    OUT death_registry.id_susp_action%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --

    FUNCTION get_dr_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        i_record         IN death_registry.id_death_registry%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_dr_wf          OUT table_table_varchar,
        o_sys_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Changes the episode id in a death registry (This function should only be called
    * by pk_match.set_match_core)
    *
    * @param        i_lang                   Language id
    * @param        i_new_episode            New episode id
    * @param        i_old_episode            Old episode id
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Paulo Fonseca
    * @version      2.6.0.3
    * @since        16-Jul-2010
    **********************************************************************************************/
    FUNCTION change_dr_episode_id
    (
        i_lang        IN language.id_language%TYPE,
        i_new_episode IN organ_donor.id_episode%TYPE,
        i_old_episode IN organ_donor.id_episode%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_datatype(i_id_ds_comp IN NUMBER) RETURN VARCHAR2;

    PROCEDURE set_dyn_data
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_death_registry IN NUMBER,
        i_data_val          IN table_table_varchar,
        i_section           IN VARCHAR2
    );

    /**********************************************************************************************
    * Get death dynamic cause 
    *
    * @return       structure with dynamic info
    *                        
    * @author       Carlos Ferreira
    * @version      2.7.0
    * @since        29-11-2016
    **********************************************************************************************/
    FUNCTION get_dyn_data
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_death_registry IN NUMBER,
        i_data_val       IN table_table_varchar
    ) RETURN table_table_varchar;

    -- ***********************************************************
    FUNCTION get_section_status
    (
        i_prof          IN profissional,
        i_internal_name IN VARCHAR2,
        i_patient       IN NUMBER,
        i_type          IN VARCHAR2 DEFAULT 'A'
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get list of section with associated status.
    *
    * @return       structure with dynamic info
    *                        
    * @author       Carlos Ferreira
    * @version      2.7.0
    * @since        01-12-2016
    **********************************************************************************************/
    FUNCTION get_dr_section_add
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        --        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        --        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        --        i_component_list IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_patient IN patient.id_patient%TYPE,
        o_section OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_death_data_fetal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_death_registry IN NUMBER,
        i_status         IN death_registry.flg_status%TYPE DEFAULT NULL,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_death_registry_row_f(i_death_registry IN death_registry.id_death_registry%TYPE DEFAULT NULL)
        RETURN death_registry%ROWTYPE;

    PROCEDURE set_death_history_det_h
    (
        i_death_registry      IN NUMBER,
        i_death_registry_hist IN NUMBER
    );

    FUNCTION get_death_data_folio(i_patient IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_cause_mx
    (
        i_id_death_registry IN NUMBER,
        i_rank              IN NUMBER,
        i_field             IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_fetal_cause_type
    (
        i_id_death_registry IN NUMBER,
        i_order             IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_death_data_folio_by_id(i_id_death_registry IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_death_data_inst_clues
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        o_clues_data  OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * This function validates if the selected death_cause is valid according to patient age
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   profissional
    * @param        i_patient                Patient ID
    * @param        o_flg_show               The warning screen should appear? Y - yes, N - No
    * @param        o_msg                    Warning message
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Elisabete Bugalho
    * @version      2.7.0.1 - NOM024
    * @since        28/07/2017
    **********************************************************************************************/

    FUNCTION check_valid_death_diagnosis
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN epis_diagnosis.id_patient%TYPE,
        i_id_diagnosis       IN diagnosis.id_diagnosis%TYPE,
        i_id_alert_diagnosis IN epis_diagnosis.id_alert_diagnosis%TYPE,
        i_component          IN ds_component.internal_name%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg                OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION check_diag_p
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN;

    FUNCTION check_anomalies
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN;

    FUNCTION check_mandatory_folio
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN;

    FUNCTION check_range_death_diag
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN;

    FUNCTION check_relationship
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN;

    FUNCTION check_age_range
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_patient   IN NUMBER,
        i_flg_death IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    -- function v_patient_Death
    FUNCTION get_data_time_illness
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_mode IN VARCHAR2,
        i_tipo IN VARCHAR2,
        i_data IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION check_fetal_anomalies
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN;

    FUNCTION validate_cert_date
    (
        i_name    IN VARCHAR2,
        i_value   IN NUMBER,
        i_section IN VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION check_causes
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN;

    FUNCTION check_fields_min_len
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER,
        i_section IN VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION check_fields_min_len_equal
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER,
        i_section IN VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION get_mx_name_from_list
    (
        i_lang     IN NUMBER,
        i_prof     IN profissional,
        i_value    IN VARCHAR2,
        i_name     IN VARCHAR2,
        i_flag     IN VARCHAR2,
        i_group_id IN NUMBER,
        i_id_ne    IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

    -- ******************************************************
    -- Validations of date from General Death and Fetal death ( MX )
    FUNCTION check_dates
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER,
        i_section IN VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION get_mother_folio
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        i_field IN VARCHAR2,
        i_value IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_field_value
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_field IN VARCHAR2,
        i_value IN VARCHAR2,
        i_flg_4 IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION check_folio_birth_value
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_patient    IN NUMBER,
        i_value      IN VARCHAR2 DEFAULT NULL,
        i_flg_origin IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_cert_order_number
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_type     IN VARCHAR2,
        i_question IN VARCHAR2,
        i_value    IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_procedure_desc
    (
        i_lang  IN language.id_language%TYPE,
        i_id_dr IN death_registry.id_death_registry%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_code_by_federal_entity
    (
        i_lang      IN language.id_language%TYPE,
        i_id_dr     IN death_registry.id_death_registry%TYPE,
        i_comp_name IN ds_component.internal_name%TYPE,
        i_type      IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION check_diag_no_cbd
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        i_id_dr   IN NUMBER
    ) RETURN BOOLEAN;
    
    FUNCTION get_death_item_values
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_section          IN t_table_ds_sections,
        i_tbl_items_values IN OUT t_table_ds_items_values,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_component_desc
    (
        i_lang         IN NUMBER,
        i_ds_component IN NUMBER
    ) RETURN VARCHAR2;    

    -- CMF ***************
    FUNCTION get_dr_rep_summary
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_section_name   IN VARCHAR2,
        i_component_name IN ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        i_component_type IN ds_cmpt_mkt_rel.flg_component_type_parent%TYPE DEFAULT pk_dynamic_screen.c_node_component,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rep_component_desc
    (
        i_lang               IN NUMBER,
        i_section_name       IN VARCHAR2,
        i_id_ds_cmpt_kmt_rel IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_all_diag_string
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2;

END pk_death_registry;
/
