/*-- Last Change Revision: $Rev: 2028681 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:18 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_epis_out_on_pass IS

    /**********************************************************************************************
    * Initialize params for filters - Epis out on pass
    *
    * @param i_context_ids            array with context ids
    * @param i_context_vals           array with context values
    * @param i_name                   parammeter name 
    * 
    * @param o_vc2                    varchar2 value
    * @param o_num                    number value
    * @param o_id                     number value
    * @param o_tstz                   timestamp value
    *
    * @author                        Adriana Ramos
    * @since                         10/04/2019
    **********************************************************************************************/
    PROCEDURE init_params_epis_out_on_pass
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /********************************************************************************************
    * Process EPIS_OUT_ON_PASS data gov events - EPIS_OUT_ON_PASS_H inserts/updates
    *
    * @author          Adriana Ramos
    * @since           10/04/2019
    ********************************************************************************************/
    PROCEDURE set_epis_out_on_pass_h
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /********************************************************************************************
    * Return rank of the status
    *
    * @author          Adriana Ramos
    * @since           12/04/2019
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_rank
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_status IN epis_out_on_pass.id_status%TYPE
    ) RETURN NUMBER;

    /**
    * Check if start action can be active
    * Used by workflows framework
    *
    * @author  Adriana Ramos
    * @since   16/04/2019
    */
    FUNCTION check_can_start
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if edit action can be active
    * Used by workflows framework
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              id_epis_out_on_pass information
    *
    * @RETURN  VARCHAR2             'A' - transition allowed 'D' - transition denied
    *
    * @author  Adriana Ramos
    * @since   16/04/2019
    */
    FUNCTION check_can_edit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if complete action can be active
    * Used by workflows framework
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              id_epis_out_on_pass information
    *
    * @RETURN  VARCHAR2             'A' - transition allowed 'D' - transition denied
    *
    * @author  Adriana Ramos
    * @since   16/04/2019
    */
    FUNCTION check_can_complete
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    /**
    * Check if cancel action can be active
    * Used by workflows framework
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)   
    * @param   i_workflow           Workflow identifier
    * @param   i_status_begin       Initial transition status
    * @param   i_status_end         Final transition status
    * @param   i_workflow_action    Workflow action identifier
    * @param   i_category           Category identifier
    * @param   i_profile            Profile template identifier        
    * @param   i_func               Functionality identifier
    * @param   i_param              id_epis_out_on_pass information
    *
    * @RETURN  VARCHAR2             'A' - transition allowed 'D' - transition denied
    *
    * @author  Adriana Ramos
    * @since   16/04/2019
    */
    FUNCTION check_can_cancel
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_workflow        IN wf_transition_config.id_workflow%TYPE,
        i_status_begin    IN wf_transition_config.id_status_begin%TYPE,
        i_status_end      IN wf_transition_config.id_status_end%TYPE,
        i_workflow_action IN wf_transition_config.id_workflow_action%TYPE,
        i_category        IN wf_transition_config.id_category%TYPE,
        i_profile         IN wf_transition_config.id_profile_template%TYPE,
        i_func            IN wf_transition_config.id_functionality%TYPE,
        i_param           IN table_varchar
    ) RETURN VARCHAR2;

    FUNCTION check_transition
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_workflow         IN print_list_job.id_workflow%TYPE,
        i_id_status_begin     IN print_list_job.id_status%TYPE,
        i_id_status_end       IN print_list_job.id_status%TYPE,
        i_id_workflow_action  IN wf_workflow_action.id_workflow_action%TYPE,
        i_id_category         IN category.id_category%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_action_active
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_action           IN action.id_action%TYPE,
        i_internal_name       IN action.internal_name%TYPE,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Return the actions
    *
    * @author          Adriana Ramos
    * @since           15/04/2019
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_actions             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Checks if the episode is out on pass
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)        
    * @param   i_id_episode    Episode identifier
    *
    * @return  varchar2        'Y'- episode is Out on pass 'N'- episode is not Out on pass
    *
    * @author  CRISTINA.OLIVEIRA
    * @since   22/04/2019
    **********************************************************************************************/
    FUNCTION check_epis_out_on_pass_active
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_out_on_pass.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * set cancel the epis_out_on_pass
    *
    * @author          Adriana Ramos
    * @since           22/04/2019
    ********************************************************************************************/
    FUNCTION set_cancel_epis_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_id_cancel_reason    IN epis_out_on_pass.id_cancel_reason%TYPE,
        i_cancel_reason       IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_out_on_pass_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN epis_out_on_pass.id_episode%TYPE,
        o_dt_in               OUT epis_out_on_pass.dt_in%TYPE,
        o_dt_out              OUT epis_out_on_pass.dt_out%TYPE,
        o_total_allowed_hours OUT epis_out_on_pass.total_allowed_hours%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update the epis_out_on_pass
    *
    * @author          Adriana Ramos
    * @since           23/04/2019
    ********************************************************************************************/
    FUNCTION update_epis_out_on_pass
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_epis_out_on_pass        IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_id_request_reason          IN epis_out_on_pass.id_request_reason%TYPE,
        i_request_reason             IN VARCHAR2,
        i_dt_out                     IN epis_out_on_pass.dt_out%TYPE,
        i_dt_in                      IN epis_out_on_pass.dt_in%TYPE,
        i_total_allowed_hours        IN epis_out_on_pass.total_allowed_hours%TYPE,
        i_flg_attending_physic_agree IN epis_out_on_pass.flg_attending_physic_agree%TYPE,
        i_id_requested_by            IN epis_out_on_pass.id_requested_by%TYPE,
        i_requested_by               IN VARCHAR2,
        i_patient_contact_number     IN epis_out_on_pass.patient_contact_number%TYPE,
        i_other_notes                IN VARCHAR2,
        i_note_admission_office      IN VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * create the epis_out_on_pass
    *
    * @author          Adriana Ramos
    * @since           24/04/2019
    ********************************************************************************************/
    FUNCTION create_epis_out_on_pass
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_patient                 IN epis_out_on_pass.id_patient%TYPE,
        i_id_episode                 IN epis_out_on_pass.id_episode%TYPE,
        i_id_request_reason          IN epis_out_on_pass.id_request_reason%TYPE,
        i_request_reason             IN VARCHAR2,
        i_dt_out                     IN epis_out_on_pass.dt_out%TYPE,
        i_dt_in                      IN epis_out_on_pass.dt_in%TYPE,
        i_total_allowed_hours        IN epis_out_on_pass.total_allowed_hours%TYPE,
        i_flg_attending_physic_agree IN epis_out_on_pass.flg_attending_physic_agree%TYPE,
        i_id_requested_by            IN epis_out_on_pass.id_requested_by%TYPE,
        i_requested_by               IN VARCHAR2,
        i_patient_contact_number     IN epis_out_on_pass.patient_contact_number%TYPE,
        i_other_notes                IN VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * complete the epis_out_on_pass
    *
    * @author          Adriana Ramos
    * @since           26/04/2019
    ********************************************************************************************/
    FUNCTION complete_epis_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_dt_in_returned      IN epis_out_on_pass.dt_in_returned%TYPE,
        i_id_conclude_reason  IN epis_out_on_pass.id_conclude_reason%TYPE,
        i_conclude_notes      IN VARCHAR2,
        i_flg_all_med_adm     IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * start the epis_out_on_pass
    *
    * @author          Adriana Ramos
    * @since           26/04/2019
    ********************************************************************************************/
    FUNCTION start_epis_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_start_notes         IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Return icon of the status
    *
    * @author          Adriana Ramos
    * @since           14/05/2019
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_icon
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_status IN epis_out_on_pass.id_status%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Gets info about out on pass per id.
    *
    * @param   i_lang          Professional preferred language
    * @param   i_prof          Professional identification and its context (institution and software)        
    * @param   i_id_epis_out_on_pass    Epis out on pass detail record identifier
    * @param   o_info          Output cursor with out on pass info.
    * @param   o_error         error
    *
    * @return  true (sucess), false (error)
    *
    * @author  CRISTINA.OLIVEIRA
    * @since   21/05/2019
    **********************************************************************************************/
    FUNCTION get_epis_out_on_pass_info
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_info                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Gets info about out on pass per id.
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_id_epis_out_on_pass    Epis out on pass detail record identifier
    * @param   o_info                   Output cursor with out on pass data.
    * @param   o_error                  Error
    *
    * @return   true (sucess), false (error)
    *
    * @author  CRISTINA.OLIVEIRA
    * @since   23/05/2019
    **********************************************************************************************/
    FUNCTION get_epis_out_on_pass_data
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_data                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Epis-oop Detail
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_id_epis_out_on_pass    Epis out on pass detail record identifier
    * @param   o_detail                 Output cursor with detail data
    * @param   o_error                  Error
    *
    * @return   true (sucess), false (error)
    *
    * @author  Pedro Teixeira
    * @since   12/06/2019
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Epis-oop Detail History
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   i_id_epis_out_on_pass    Epis out on pass detail record identifier
    * @param   o_detail                 Output cursor with detail data
    * @param   o_error                  Error
    *
    * @return   true (sucess), false (error)
    *
    * @author  Pedro Teixeira
    * @since   12/06/2019
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Epis-oop Report
    *
    * @param   i_lang                   Professional preferred language
    * @param   i_prof                   Professional identification and its context (institution and software)        
    * @param   o_detail                 Output cursor with detail data
    * @param   o_error                  Error
    *
    * @return   true (sucess), false (error)
    *
    * @author  Pedro Teixeira
    * @since   12/06/2019
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_rep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_out_on_pass.id_episode%TYPE,
        i_flg_hist   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_detail_prod_and_instr
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          epis_out_on_pass.id_episode%TYPE,
        i_id_epis_out_on_pass epis_out_on_pass.id_epis_out_on_pass%TYPE
    ) RETURN table_varchar;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_detail_descr
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_data_code_message        IN dd_content.data_code_message%TYPE,
        i_id_ds_component          IN dd_content.id_ds_component%TYPE,
        i_data_source_val          IN VARCHAR2,
        i_data_source_val_old      IN VARCHAR2,
        i_flg_type                 IN dd_content.flg_type%TYPE,
        i_c_n                      IN VARCHAR2,
        i_level                    IN VARCHAR2,
        i_flg_data_source_as_descr IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    /**
    * Check if add button can be active
    *
    * @param   i_lang             Professional preferred language
    * @param   i_prof             Professional identification and its context (institution and software)   
    * @param   i_id_episode       Episode identifier
    * @param   i_id_patient       Patient identifier
    *
    * @RETURN  VARCHAR2             'Y' - can be active / 'N' - can't be active
    *
    * @author  Adriana Ramos
    * @since   04/07/2019
    */
    FUNCTION check_can_add
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN epis_out_on_pass.id_episode%TYPE,
        i_id_patient  IN epis_out_on_pass.id_patient%TYPE,
        o_flg_can_add OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION get_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    -------------------------------------------------------------------------------------------

    g_det_level_1    CONSTANT VARCHAR2(10 CHAR) := 'L1';
    g_det_level_2    CONSTANT VARCHAR2(10 CHAR) := 'L2';
    g_det_level_2    CONSTANT VARCHAR2(10 CHAR) := 'L3';
    g_det_level_prof CONSTANT VARCHAR2(10 CHAR) := 'LP';
    g_det_white_line CONSTANT VARCHAR2(10 CHAR) := 'WL';

    g_attending_agree      CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_attending_not_agree  CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_flg_validation_error CONSTANT VARCHAR2(1 CHAR) := 'E';

    g_ds_request_reason         CONSTANT ds_component.id_ds_component%TYPE := 880;
    g_ds_request_reason_other   CONSTANT ds_component.id_ds_component%TYPE := 1077;
    g_ds_requested_by           CONSTANT ds_component.id_ds_component%TYPE := 888;
    g_ds_request_by_other       CONSTANT ds_component.id_ds_component%TYPE := 1078;
    g_ds_dt_out                 CONSTANT ds_component.id_ds_component%TYPE := 881;
    g_ds_dt_in                  CONSTANT ds_component.id_ds_component%TYPE := 882;
    g_ds_total_allowed_hours    CONSTANT ds_component.id_ds_component%TYPE := 883;
    g_ds_patient_contact_number CONSTANT ds_component.id_ds_component%TYPE := 889;
    g_ds_attending_physic_agree CONSTANT ds_component.id_ds_component%TYPE := 884;
    g_ds_note_admission_office  CONSTANT ds_component.id_ds_component%TYPE := 885;
    g_ds_other_notes            CONSTANT ds_component.id_ds_component%TYPE := 886;

    g_action_edit    CONSTANT action.id_action%TYPE := 235533986;
    g_action_submit  CONSTANT action.id_action%TYPE := 235534028;
    g_action_default CONSTANT action.id_action%TYPE := 235533990;

    g_requested_by_patient        CONSTANT NUMBER(24) := 3071;
    g_requested_by_legal_guardian CONSTANT NUMBER(24) := 3072;
    g_requested_by_next_of_kint   CONSTANT NUMBER(24) := 3073;

END pk_epis_out_on_pass;
/
