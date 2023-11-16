/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_discharge_inst IS

    -- Author  : PEDRO.TEIXEIRA
    -- Created : 18-02-2010 11:20:04
    -- Purpose : Manage discharge institutions

    /********************************************************************************************
    * This function returns true if i_discharge_dest has associated institutions
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge_dest  ID_DISCHARGE_DEST   
    *
    * @return                   TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    18/02/2010
    ********************************************************************************************/
    FUNCTION has_disch_dest_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge_dest IN discharge_dest.id_discharge_dest%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns Y or N depending ig the discharge is a transference discharge or not
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       ID_DISCHARGE
    *
    * @return                   TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    16/03/2010
    ********************************************************************************************/
    FUNCTION check_is_transf_discharge
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function to associate a discharge_dest with institution_ext
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge_dest  discharge_dest.id_discharge_dest
    * @param IN   i_institution_ext institution_ext.id_institution_ext
    * @param IN   i_software        software.id_software
    * @param IN   i_institution     institution.id_institution
    *
    * @return
    *
    * @author                   Pedro Teixeira
    * @since                    18/02/2010
    ********************************************************************************************/
    FUNCTION assoc_disch_dest_with_inst
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge_dest  IN discharge_dest.id_discharge_dest%TYPE,
        i_institution_ext IN institution_ext.id_institution_ext%TYPE,
        i_software        IN software.id_software%TYPE,
        i_institution     IN institution.id_institution%TYPE,
        o_disch_dest_inst OUT disch_dest_inst.id_disch_dest_inst%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function return possible actions when selected a discharge destination with available institutions
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge_dest  ID_DISCHARGE_DEST  - either i_discharge_dest or i_disch_reas_dest must not be null
    * @param IN   i_disch_reas_dest ID_DISCH_REAS_DEST
    *
    * @param OUT  o_disch_options   returns the options list when chosing a discharge destination
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    18/02/2010
    ********************************************************************************************/
    FUNCTION get_disch_dest_options
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge_dest  IN discharge_dest.id_discharge_dest%TYPE,
        i_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE, -- connection table between discharge_reason & discharge_dest
        o_disch_options   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns the list of available institution for the specific discharge destination
    * this function is necessary when selected the option "A definir por terceiros" where only the id_discharge is available
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       ID_DISCHARGE
    *
    * @param OUT  o_dest_inst       list of available institution for the specific discharge destination
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    16/03/2010
    ********************************************************************************************/
    FUNCTION get_institution_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_dti_notes OUT discharge_detail.dti_notes%TYPE,
        o_dest_inst OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns the list of available institution for the specific discharge destination
    * this function must exist because when it's called the discharge is not yet created
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge_dest  ID_DISCHARGE_DEST  - either i_discharge_dest or i_disch_reas_dest must not be null
    * @param IN   i_disch_reas_dest ID_DISCH_REAS_DEST
    *
    * @param OUT  o_dest_inst       list of available institution for the specific discharge destination
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    18/02/2010
    ********************************************************************************************/
    FUNCTION get_institution_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge_dest  IN discharge_dest.id_discharge_dest%TYPE,
        i_disch_reas_dest IN disch_reas_dest.id_disch_reas_dest%TYPE,
        o_dest_inst       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns the list of ramaining institutions not selected in the first instance
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    *
    * @param OUT  o_dest_inst       list of available institution for the specific discharge destination
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    18/02/2010
    ********************************************************************************************/
    FUNCTION get_inst_remaining_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_dti_notes OUT discharge_detail.dti_notes%TYPE,
        o_dest_inst OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns the list of ramaining institutions not selected in the first instance
    * with indication if they where suggested by the social worker
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    *
    * @param OUT  o_dest_inst       list of available institution for the specific discharge destination
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    16/03/2010
    ********************************************************************************************/
    FUNCTION get_inst_suggested_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_dti_notes OUT discharge_detail.dti_notes%TYPE,
        o_dest_inst OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the list of destination institutions of a Discharge
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    *
    * @param OUT  o_dest_inst       list of destination institutions of a Discharge
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    23/02/2010
    ********************************************************************************************/
    FUNCTION get_disch_transf_inst_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_transf_inst       OUT pk_types.cursor_type,
        o_discharge         OUT discharge.id_discharge%TYPE,
        o_flg_inst_transfer OUT discharge_detail.flg_inst_transfer%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns the last transference state (for doctor transf grid)
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    *
    * @param OUT  o_dest_inst       list of destination institutions of a Discharge
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    01/03/2010
    ********************************************************************************************/
    FUNCTION get_disch_transf_inst_active
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        o_transf_inst OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function updates the institution transfer state
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    *
    * @param OUT  o_dest_inst       list of destination institutions of a Discharge
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    01/03/2010
    ********************************************************************************************/
    FUNCTION update_disch_transf_inst
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_discharge              IN disch_transf_inst.id_discharge%TYPE,
        i_disch_transf_inst      IN disch_transf_inst.id_disch_transf_inst%TYPE,
        i_admitted               IN VARCHAR2, -- Y - Yes; N - No
        i_id_refused_reason      IN disch_transf_inst.id_refused_reason%TYPE,
        i_notes                  IN disch_transf_inst.notes%TYPE,
        i_granted_transportation IN VARCHAR2, -- Y - Yes; N - No
        o_is_last_record         OUT VARCHAR2, -- Y - Yes; N - No 
        o_prof_has_permission    OUT VARCHAR2, -- Y - Yes; N - No
        o_show_alert_message     OUT VARCHAR2, -- Y - show Error
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to return the institution list creation options, when no more institutions exists in the list:
    * Criar nova lista / Sugerir nova lista / Pedir nova lista
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @param OUT  o_transf_inst_options  options list
    * @return                            TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    23/02/2010
    ********************************************************************************************/
    FUNCTION get_transf_inst_options
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_transf_inst_options OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *     * This function returns de DTI detail. Grupos: Dados da instituição, Dados da alta, Dados da transferência
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_disch_dest_inst DTI ID
    *
    * @param OUT  o_dest_inst       list of destination institutions of a Discharge
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    01/03/2010
    ********************************************************************************************/
    FUNCTION get_disch_transf_inst_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_disch_transf_inst IN disch_transf_inst.id_disch_transf_inst%TYPE,
        o_dti_det           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function returns de DTI detail: Dados da instituição / Motivo da transferência / Dados da transferência
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_disch_dest_inst DTI ID
    *
    * @param OUT  o_dest_inst       list of destination institutions of a Discharge
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    01/03/2010
    ********************************************************************************************/
    FUNCTION get_inst_admission_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_disch_transf_inst IN disch_transf_inst.id_disch_transf_inst%TYPE,
        o_dti_det           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Create discharge transference alert
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Episode ID
    * @param IN   i_sys_alert       Alert ID
    * @param IN   i_prof_id         Professional to whom this alert is targeted
    *
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    24/02/2010
    ********************************************************************************************/
    FUNCTION create_generic_alert
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        i_sys_alert IN sys_alert.id_sys_alert%TYPE,
        i_prof_id   IN professional.id_professional%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Delete discharge transference alert
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Episode ID
    * @param IN   i_sys_alert       Alert ID
    *
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    24/02/2010
    ********************************************************************************************/
    FUNCTION delete_generic_alert
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        i_sys_alert IN sys_alert.id_sys_alert%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  verifies is a certain event exists
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Episode ID
    * @param IN   i_sys_alert       Alert ID
    *
    * @return                       TRUE if has associated institution, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    24/02/2010
    ********************************************************************************************/
    FUNCTION exists_generic_alert
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        i_sys_alert IN sys_alert.id_sys_alert%TYPE
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Determines if the professional has permission to create a transference list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @return                       TRUE if has permission, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    10/03/2010
    ********************************************************************************************/
    FUNCTION prof_can_create_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Determines if the professional has permission to suggest a transference list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @return                       TRUE if has permission, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    10/03/2010
    ********************************************************************************************/
    FUNCTION prof_can_suggest_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Determines if the professional has permission to suggest a transference list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @return                       TRUE if has permission, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    10/03/2010
    ********************************************************************************************/
    FUNCTION prof_has_permissions
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Determines if any professional has permissions to create a transfer list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    *
    * @return                       TRUE if has permission, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    12/03/2010
    ********************************************************************************************/
    FUNCTION prof_has_create_permissions
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function insert into DISCH_TRANSF_INST a fixed institution resulted from a discharge without institution validation
    * this function is called:
    *      - when a physician makes a discharge without institution validation 
    *
    * @param IN   i_lang               Language ID
    * @param IN   i_prof               Professional ID
    * @param IN   i_discharge          Discharge ID
    * @param IN   i_inst_name          institution name
    *
    * @return                       TRUE if destination institution inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    29/04/2010
    ********************************************************************************************/
    FUNCTION set_dti_stated_inst
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_inst_name      IN disch_transf_inst.free_text_inst%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_dti_stated_inst
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        i_inst_name IN disch_transf_inst.free_text_inst%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function insert updates discharhe_detail with the id_epis_diagnosis 
    *
    * @param IN   i_lang               Language ID
    * @param IN   i_prof               Professional ID
    * @param IN   i_discharge          Discharge ID
    * @param IN   i_epis_diagnosis     Epis diagnosis ID
    *
    * @return                       TRUE if destination institution inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    29/07/2010
    ********************************************************************************************/
    FUNCTION set_dti_epis_diagnosis
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function insert into DISCH_TRANSF_INST listed destination institutions
    * this function is called:
    *      - when a physician creates a institution list
    *      - after requestin for a social worker to create a list (request_other_prof_create_list)
    *              the social worker analyses the request and creates a list
    *
    * @param IN   i_lang               Language ID
    * @param IN   i_prof               Professional ID
    * @param IN   i_discharge          Discharge ID
    * @param IN   i_disch_dest_inst    table with destination institutions ID's
    * @param IN   i_disch_rank         rank of destination institutions ID's
    * @param IN   i_other_inst_name    institution name when "other" is selected
    * @param OUT  o_show_alert_message if the list was already created then show alert message
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    22/02/2010
    ********************************************************************************************/
    FUNCTION set_dti_new_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_discharge          IN discharge.id_discharge%TYPE,
        i_disch_dest_inst    IN table_number,
        i_disch_rank         IN table_number,
        i_other_inst_name    IN disch_transf_inst.free_text_inst%TYPE,
        i_epis_diagnosis     IN epis_diagnosis.id_epis_diagnosis%TYPE,
        i_dti_notes          IN discharge_detail.dti_notes%TYPE,
        o_show_alert_message OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Social Worker (or other professional with creation permission) suggests a new institution list
    * for physician approval
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    * @param IN   i_other_inst_name institution name when "other" is selected
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION set_dti_new_list_suggested
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge       IN discharge.id_discharge%TYPE,
        i_disch_dest_inst IN table_number,
        i_disch_rank      IN table_number,
        i_other_inst_name IN disch_transf_inst.free_text_inst%TYPE,
        i_dti_notes       IN discharge_detail.dti_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Social Worker (or other professional with creation permission) creates a new institutions list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    * @param IN   i_other_inst_name institution name when "other" is selected
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION set_dti_new_list_created
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge       IN discharge.id_discharge%TYPE,
        i_disch_dest_inst IN table_number,
        i_disch_rank      IN table_number,
        i_other_inst_name IN disch_transf_inst.free_text_inst%TYPE,
        i_dti_notes       IN discharge_detail.dti_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * After a request from the social worker the physician creates a new list
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    * @param IN   i_other_inst_name institution name when "other" is selected
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION set_dti_new_list_requested
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge       IN discharge.id_discharge%TYPE,
        i_disch_dest_inst IN table_number,
        i_disch_rank      IN table_number,
        i_other_inst_name IN disch_transf_inst.free_text_inst%TYPE,
        i_dti_notes       IN discharge_detail.dti_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Generic function to insert discharge institutions (called by the other functions)
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_disch_dest_inst table with destination institutions ID's
    * @param IN   i_disch_rank      rank of destination institutions ID's
    * @param IN   i_other_inst_name institution name when "other" is selected
    * @param IN   i_flg_status      status of the inserted records (of the discharge institutions)
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION set_dti_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_discharge       IN discharge.id_discharge%TYPE,
        i_disch_dest_inst IN table_number,
        i_disch_rank      IN table_number,
        i_other_inst_name IN disch_transf_inst.free_text_inst%TYPE,
        i_flg_status      IN disch_transf_inst.flg_status%TYPE,
        i_dti_notes       IN discharge_detail.dti_notes%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Function to call when a social worker requests a new list to the physician
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION request_new_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Physician function
    * Function to call when the physician requests other professional to create transference list
    * this function only needs to handle the alert creation
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION request_other_prof_create_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_epis_diagnosis IN epis_diagnosis.id_epis_diagnosis%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION request_other_prof_create_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Apdates discharge transfer status
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    * @param IN   i_flg_status      Discharge transfer status
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    15/03/2010
    ********************************************************************************************/
    FUNCTION update_disch_transf_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_discharge  IN discharge.id_discharge%TYPE,
        i_flg_status IN discharge_detail.flg_inst_transfer_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancels all data related with the discharge: alerts and transf_inst
    *
    * @param IN   i_lang            Language ID
    * @param IN   i_prof            Professional ID
    * @param IN   i_discharge       Discharge ID
    *
    * @return                       TRUE if list of destination institutions inserted, FALSE otherwise
    *
    * @author                   Pedro Teixeira
    * @since                    17/03/2010
    ********************************************************************************************/
    FUNCTION cancel_transf_discharge
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_discharge IN discharge.id_discharge%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    ---------------------------------------- GLOBAL VALUES ----------------------------------------------
    /* Current timestamp */
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(1000 CHAR);
    g_exception EXCEPTION;
    g_found BOOLEAN;

    g_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no  CONSTANT VARCHAR2(1 CHAR) := 'N';

    -- FLG_STATUS
    g_transf_status_concluded     CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_transf_status_pending       CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_transf_status_refused       CONSTANT VARCHAR2(1 CHAR) := 'R';
    g_transf_status_canceled      CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_transf_status_suggested     CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_transf_status_not_available CONSTANT VARCHAR2(1 CHAR) := 'N';

    -- FLG_STATUS ICON
    g_transf_concluded_icon     CONSTANT sys_domain.img_name%TYPE := 'CheckIcon';
    g_transf_pending_icon       CONSTANT sys_domain.img_name%TYPE := 'WaitingIcon';
    g_transf_not_available_icon CONSTANT sys_domain.img_name%TYPE := 'WaitingIcon';
    g_transf_refused_icon       CONSTANT sys_domain.img_name%TYPE := 'DeclinedIcon';
    g_transf_canceled_icon      CONSTANT sys_domain.img_name%TYPE := 'CancelIcon';
    g_transf_suggested_icon     CONSTANT sys_domain.img_name%TYPE := 'ApprovalDataPendingIcon';
    -- WaitingMedicalApproval

    -- FLG_TYPE
    g_transf_type_insitutional CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_transf_type_free_text    CONSTANT VARCHAR2(1 CHAR) := 'T';

    -- ALERT
    -- social worker
    g_disch_transf_inst_alert      CONSTANT sys_alert.id_sys_alert%TYPE := 85;
    g_other_prof_transf_list_alert CONSTANT sys_alert.id_sys_alert%TYPE := 89;
    -- physician
    g_concluded_transf_alert CONSTANT sys_alert.id_sys_alert%TYPE := 86;
    g_suggested_transf_alert CONSTANT sys_alert.id_sys_alert%TYPE := 87;
    g_requested_transf_alert CONSTANT sys_alert.id_sys_alert%TYPE := 88;

    -- dest_options messages
    --g_dest_option_institution CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_T067'; -- Instituição
    --g_dest_option_undefined   CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_T068'; -- Indefinido
    --g_dest_option_other_prof  CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_T069'; -- A definir por terceiros

    g_dest_option_create_list     CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_T067'; -- A definir por mim (com verificação de vaga)
    g_dest_option_direct          CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_T068'; -- A definir por mim (sem verificação de vaga)
    g_dest_option_other_prof_list CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_T069'; -- A definir por outro profissional (com verificação de vaga)

    -- transf options messages
    g_transf_option_create  CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_T091'; -- Criar nova lista
    g_transf_option_sugest  CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_T092'; -- Sugerir nova lista
    g_transf_option_request CONSTANT sys_message.code_message%TYPE := 'DISCHARGE_T093'; -- Pedir nova lista

    g_transf_create_flg  CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_transf_sugest_flg  CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_transf_request_flg CONSTANT VARCHAR2(1 CHAR) := 'R';

    -- Sys Domain constants
    g_domain_dti_flg_status       CONSTANT sys_domain.code_domain%TYPE := 'DISCH_TRANSF_INST.FLG_STATUS';
    g_domain_dd_flg_transf_status CONSTANT sys_domain.code_domain%TYPE := 'DISCHARGE_DETAIL.FLG_TRANSFER_STATUS';

    -- Prof Categories
    g_prof_cat_registrar     CONSTANT category.id_category%TYPE := 4; -- Administrativo
    g_prof_cat_physician     CONSTANT category.id_category%TYPE := 1; -- Médico
    g_prof_cat_nurse         CONSTANT category.id_category%TYPE := 2; -- Enfermeiro
    g_prof_cat_social_worker CONSTANT category.id_category%TYPE := 25; -- Assistente Social

    -- Sys config permissions
    g_dti_create_registrar     CONSTANT sys_config.id_sys_config%TYPE := 'DISCH_TRANSF_LIST_CREATE_PERMISSION_REGISTRAR';
    g_dti_create_nurse         CONSTANT sys_config.id_sys_config%TYPE := 'DISCH_TRANSF_LIST_CREATE_PERMISSION_NURSE';
    g_dti_create_social_worker CONSTANT sys_config.id_sys_config%TYPE := 'DISCH_TRANSF_LIST_CREATE_PERMISSION_SOCIAL_WORKER';

    g_dti_suggest_registrar     CONSTANT sys_config.id_sys_config%TYPE := 'DISCH_TRANSF_LIST_SUGGEST_PERMISSION_REGISTRAR';
    g_dti_suggest_nurse         CONSTANT sys_config.id_sys_config%TYPE := 'DISCH_TRANSF_LIST_SUGGEST_PERMISSION_NURSE';
    g_dti_suggest_social_worker CONSTANT sys_config.id_sys_config%TYPE := 'DISCH_TRANSF_LIST_SUGGEST_PERMISSION_SOCIAL_WORKER';

END pk_discharge_inst;
/
