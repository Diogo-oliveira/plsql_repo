/*-- Last Change Revision: $Rev: 2029029 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:23 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ux_death_registry AS

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
    * @param        o_component_name         Component internal name
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
        o_component_name OUT ds_cmpt_mkt_rel.internal_name_parent%TYPE,
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
        i_patient IN patient.id_patient%TYPE,
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
        o_component_name OUT ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_events         OUT pk_types.cursor_type,
        o_items_values   OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_flg_show       OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_error          OUT t_error_out
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
        o_component_name OUT ds_cmpt_mkt_rel.internal_name_parent%TYPE,
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
    * @param        o_component_name         Component internal name
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
        o_component_name OUT ds_cmpt_mkt_rel.internal_name_parent%TYPE,
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
        i_record         IN death_registry.id_death_registry%TYPE,
        o_component_name OUT ds_cmpt_mkt_rel.internal_name_parent%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_data_val       OUT table_table_varchar,
        o_prof_data      OUT pk_types.cursor_type,
        o_dr_wf          OUT table_table_varchar,
        o_sys_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the contagious diseases list
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        o_diagnosis              Cursor with diagnosis list for contagious diseases
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        08-Jun-2010
    **********************************************************************************************/
    FUNCTION get_contagious_diseases
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the patient contagious diseases list
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   Professional, software and institution ids
    * @param        i_patient                Patient id
    * @param        o_diagnosis              Cursor with the patient diagnosis list for
    *                                        contagious diseases
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *
    * @author       Filipe Machado
    * @version      2.6.0.3
    * @since        09-Jun-2010
    **********************************************************************************************/
    FUNCTION get_pat_contagious_diseases
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_diagnosis OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dr_section_add
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN NUMBER,
        o_section OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

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

    /**********************************************************************************************
    * This function validates patient age betweenfixed intervals for norm24
    *
    * @param        i_lang                   Language id
    * @param        i_prof                   profissional
    * @param        i_patient                Patient ID
    * @param        i_flg_Death              value of popup ( input of user )
    * @param        o_flg_show               The warning screen should appear? Y - yes, N - No
    * @param        o_msg                    Warning message
    * @param        o_error                  Error information
    *
    * @return       TRUE if sucess, FALSE otherwise
    *                        
    * @author       Carlos Ferreira
    * @version      2.7.X.X - NOM024
    * @since        23/08//2017
    **********************************************************************************************/
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

END pk_ux_death_registry;
/
