/*-- Last Change Revision: $Rev: 2029030 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:23 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_ux_epis_out_on_pass IS

    g_request_reason_ds_id         CONSTANT pk_types.t_low_num := 880;
    g_requested_by_ds_id           CONSTANT pk_types.t_low_num := 888;
    g_dt_out_ds_id                 CONSTANT pk_types.t_low_num := 881;
    g_dt_in_ds_id                  CONSTANT pk_types.t_low_num := 882;
    g_total_allowed_days_ds_id     CONSTANT pk_types.t_low_num := 883;
    g_pat_contact_number_ds_id     CONSTANT pk_types.t_low_num := 889;
    g_attending_physic_agree_ds_id CONSTANT pk_types.t_low_num := 884;
    g_note_admission_office_ds_id  CONSTANT pk_types.t_low_num := 885;
    g_other_notes_ds_id            CONSTANT pk_types.t_low_num := 886;
    g_request_reason_other_ds_id   CONSTANT pk_types.t_low_num := 1077;
    g_requested_by_other_ds_id     CONSTANT pk_types.t_low_num := 1078;

    /********************************************************************************************
    * Return the actions
    *
    * @author          Adriana Ramos
    * @since           2019/04/18
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_actions             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set cancel on the epis_out_on_pass
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

    /********************************************************************************************
    * set the epis_out_on_pass
    *
    * @author          Adriana Ramos
    * @since           24/04/2019
    ********************************************************************************************/
    FUNCTION set_epis_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN epis_out_on_pass.id_patient%TYPE,
        i_id_episode          IN epis_out_on_pass.id_episode%TYPE,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_cmpt_mkt_rel        IN table_number,
        i_values              IN table_table_varchar,
        o_error               OUT t_error_out
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
        i_id_episode          IN epis_out_on_pass.id_episode%TYPE,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_dt_in_returned      IN VARCHAR2,
        i_id_conclude_reason  IN epis_out_on_pass.id_conclude_reason%TYPE,
        i_conclude_notes      IN VARCHAR2,
        i_flg_adm_medication  IN VARCHAR2,
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
        i_id_episode          IN epis_out_on_pass.id_episode%TYPE,
        i_id_presc            IN table_number,
        i_dt_out              IN VARCHAR2,
        i_dt_in               IN VARCHAR2,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        i_start_notes         IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_presc_out_on_pass
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_presc_data          OUT pk_types.cursor_type,
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
    * Function to return the prescriptions out ou pass to complete
    *
    * @param      i_lang                Língua registada como preferência do profissional
    * @param      I_PROF                Profissional que acede
    * @param      i_id_epis_out_on_pass Epis out on pass detail record identifier
    * @param      o_presc_data          Output cursor with prescriptions info.
    * @param      O_ERROR               erro
    *
    * @return     boolean
    * @author     CRISTINA.OLIVEIRA
    * @since      2019-05-23
    ********************************************************************************************/
    FUNCTION get_presc_out_on_pass_complete
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_presc_data          OUT pk_types.cursor_type,
        o_server_time         OUT VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
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
    ********************************************************************************************/
    FUNCTION get_epis_out_on_pass_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_out_on_pass IN epis_out_on_pass.id_epis_out_on_pass%TYPE,
        o_detail              OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    ********************************************************************************************/
    FUNCTION check_can_add
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN epis_out_on_pass.id_episode%TYPE,
        i_id_patient  IN epis_out_on_pass.id_patient%TYPE,
        o_flg_can_add OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

END pk_ux_epis_out_on_pass;
/
