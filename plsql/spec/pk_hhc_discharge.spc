/*-- Last Change Revision: $Rev: 1849312 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-06-26 16:15:18 +0100 (ter, 26 jun 2018) $*/

CREATE OR REPLACE PACKAGE pk_hhc_discharge IS

    -- Author  : PEDRO.TEIXEIRA
    -- Created : 30/01/2020 16:09:03
    -- Purpose : Handle HHC Discharge

    g_disch_status_active   CONSTANT VARCHAR2(0001 CHAR) := 'A'; --  Approved
    g_disch_status_canceled CONSTANT VARCHAR2(0001 CHAR) := 'C'; --  Canceled

    g_flg_ins CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_flg_upd CONSTANT VARCHAR2(1 CHAR) := 'U';

    g_action_add    CONSTANT NUMBER := 235534143;
    g_action_edit   CONSTANT NUMBER := 235534144;
    g_action_cancel CONSTANT NUMBER := 235534145;

    g_ds_hhc_services_received    CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_SERVICES_RECEIVED';
    g_ds_hhc_services_specify     CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_SERVICES_SPECIFY';
    g_ds_hhc_pat_caregiver_educ   CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_PAT_CAREGIVER_EDUCATION';
    g_ds_hhc_summary_care_prov    CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_SUMMARY_CARE_PROVIDED';
    g_ds_hhc_discharge_goals      CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_DISCHARGE_GOALS';
    g_ds_hhc_discharge_reason     CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_DISCHARGE_REASON';
    g_ds_hhc_date_time_death      CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_DATE_TIME_DEATH';
    g_ds_hhc_place_death          CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_PLACE_DEATH';
    g_ds_hhc_pat_condition_summ   CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_PAT_CONDITION_SUMMARY';
    g_ds_hhc_pat_caregiver_eval   CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_PAT_CAREGIVER_EVALUATION';
    g_ds_hhc_specify_independence CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_SPECIFY_INDEPENDENCE';
    g_ds_hhc_specify_knowledge    CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_SPECIFY_KNOWLEDGE';
    g_ds_hhc_specify_other        CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_SPECIFY_OTHER';
    g_ds_hhc_action_cri_not_met   CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_ACTION_CRITERIA_NOT_MET';
    g_ds_hhc_pat_continue_under   CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_PAT_CONTINUE_UNDER';
    g_ds_hhc_medication_on_disch  CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_MEDICATION_ON_DISCHARGE';
    g_ds_hhc_other_notes          CONSTANT VARCHAR2(200 CHAR) := 'DS_HHC_OTHER_NOTES';

    g_sd_hhc_services_received  CONSTANT VARCHAR2(200 CHAR) := 'HHC_SERVICES_RECEIVED';
    g_sd_hhc_discharge_goals    CONSTANT VARCHAR2(200 CHAR) := 'HHC_DISCHARGE_GOALS';
    g_sd_hhc_discharge_reason   CONSTANT VARCHAR2(200 CHAR) := 'HHC_DISCHARGE_REASON';
    g_sd_hhc_pat_caregiver_eval CONSTANT VARCHAR2(200 CHAR) := 'HHC_PAT_CAREGIVER_EVALUATION';
    g_sd_hhc_pat_continue_under CONSTANT VARCHAR2(200 CHAR) := 'HHC_PAT_CONTINUE_UNDER';

    g_id_disch_reason_det_type CONSTANT hhc_det_type.id_hhc_det_type%TYPE := 55;

    g_det_level_1    CONSTANT VARCHAR2(10 CHAR) := 'L1';
    g_det_level_2    CONSTANT VARCHAR2(10 CHAR) := 'L2';
    g_det_level_2b   CONSTANT VARCHAR2(10 CHAR) := 'L2B';
    g_det_level_2n   CONSTANT VARCHAR2(10 CHAR) := 'L2N';
    g_det_level_3    CONSTANT VARCHAR2(10 CHAR) := 'L3';
    g_det_level_3b   CONSTANT VARCHAR2(10 CHAR) := 'L3B';
    g_det_level_3n   CONSTANT VARCHAR2(10 CHAR) := 'L3N';
    g_det_level_4    CONSTANT VARCHAR2(10 CHAR) := 'L4';
    g_det_level_4b   CONSTANT VARCHAR2(10 CHAR) := 'L4B';
    g_det_level_4n   CONSTANT VARCHAR2(10 CHAR) := 'L4N';
    g_det_level_prof CONSTANT VARCHAR2(10 CHAR) := 'LP';
    g_det_white_line CONSTANT VARCHAR2(10 CHAR) := 'WL';

    -- HHC Det Types
    g_hhc_det_type_dt CONSTANT VARCHAR2(10 CHAR) := 'DT';

    /*******************************************************************************************
    *******************************************************************************************/
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

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_edit_values
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_root_name        IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_add_values
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_root_name IN VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_discharge_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_disch_list      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_actions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        o_actions          OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_detail_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_detail_hist_group
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_group         IN epis_hhc_discharge_h.id_group%TYPE,
        i_first_element    IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN t_tab_dd_data_rank;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_detail_cancel
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_cancel_reason IN epis_hhc_discharge.id_cancel_reason%TYPE,
        i_cancel_notes     IN epis_hhc_discharge.cancel_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN t_tab_dd_data_rank;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_detail_doc_prof
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof_discharge IN epis_hhc_discharge.id_prof_discharge%TYPE,
        i_dt_discharge      IN epis_hhc_discharge.dt_discharge%TYPE,
        i_flg_use_upd       IN VARCHAR DEFAULT pk_alert_constant.g_no,
        o_error             OUT t_error_out
    ) RETURN t_tab_dd_data_rank;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_report_data
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_detail          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_report_data
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION set_cancel_hhd_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_cancel_reason IN epis_out_on_pass.id_cancel_reason%TYPE,
        i_cancel_notes     IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION save_hhc_discharge
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        id_epis_hhc_req       IN epis_hhc_req.id_epis_hhc_req%TYPE,
        id_epis_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_tbl_mkt_rel         IN table_number,
        i_value               IN table_table_varchar,
        i_value_clob          IN table_clob,
        o_result              OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION set_hhc_discharge
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_hhc_req       IN epis_hhc_req.id_epis_hhc_req%TYPE,
        i_id_epis_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_internal_name_childs  IN table_varchar,
        i_value                 IN table_table_varchar,
        i_value_clob            IN table_clob,
        i_id_types              IN table_number,
        o_id_epis_hhc_discharge OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION set_hhc_disch_det
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_flg_ins_upd           IN VARCHAR2 DEFAULT g_flg_ins,
        i_dt_creation           IN epis_hhc_disch_det.dt_creation%TYPE,
        i_id_epis_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_internal_name_childs  IN table_varchar,
        i_value                 IN table_table_varchar,
        i_value_clob            IN table_clob,
        i_id_types              IN table_number,
        i_id_group              IN epis_hhc_disch_det_h.id_group%TYPE
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION ins_hhc_discharge
    (
        i_id_hhc_discharge  IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_epis_hhc_req   IN epis_hhc_discharge.id_epis_hhc_req%TYPE,
        i_flg_status        IN epis_hhc_discharge.flg_status%TYPE,
        i_id_prof_discharge IN epis_hhc_discharge.id_prof_discharge%TYPE,
        i_dt_discharge      IN epis_hhc_discharge.dt_discharge%TYPE,
        i_id_prof_cancel    IN epis_hhc_discharge.id_prof_cancel%TYPE DEFAULT NULL,
        i_id_cancel_reason  IN epis_hhc_discharge.id_cancel_reason%TYPE DEFAULT NULL,
        i_cancel_notes      IN epis_hhc_discharge.cancel_notes%TYPE DEFAULT NULL, -- CLOB
        i_dt_cancel         IN epis_hhc_discharge.dt_cancel%TYPE DEFAULT NULL,
        i_id_group          IN epis_hhc_disch_det_h.id_group%TYPE
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION upd_hhc_discharge
    (
        i_id_hhc_discharge  IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_epis_hhc_req   IN epis_hhc_discharge.id_epis_hhc_req%TYPE DEFAULT NULL,
        i_flg_status        IN epis_hhc_discharge.flg_status%TYPE DEFAULT NULL,
        i_id_prof_discharge IN epis_hhc_discharge.id_prof_discharge%TYPE DEFAULT NULL,
        i_dt_discharge      IN epis_hhc_discharge.dt_discharge%TYPE DEFAULT NULL,
        i_id_prof_cancel    IN epis_hhc_discharge.id_prof_cancel%TYPE DEFAULT NULL,
        i_id_cancel_reason  IN epis_hhc_discharge.id_cancel_reason%TYPE DEFAULT NULL,
        i_cancel_notes      IN epis_hhc_discharge.cancel_notes%TYPE DEFAULT NULL,
        i_dt_cancel         IN epis_hhc_discharge.dt_cancel%TYPE DEFAULT NULL,
        i_id_prof_creation  IN epis_hhc_discharge_h.id_prof_creation%TYPE DEFAULT NULL,
        i_dt_creation       IN epis_hhc_discharge_h.dt_creation%TYPE DEFAULT NULL,
        i_id_group          IN epis_hhc_disch_det_h.id_group%TYPE
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    PROCEDURE ins_upd_hhc_disc_internal
    (
        i_flg_ins_upd       IN VARCHAR2 DEFAULT g_flg_ins,
        i_flg_hist          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_hhc_discharge  IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_epis_hhc_req   IN epis_hhc_discharge.id_epis_hhc_req%TYPE,
        i_flg_status        IN epis_hhc_discharge.flg_status%TYPE,
        i_id_prof_discharge IN epis_hhc_discharge.id_prof_discharge%TYPE,
        i_dt_discharge      IN epis_hhc_discharge.dt_discharge%TYPE,
        i_id_prof_cancel    IN epis_hhc_discharge.id_prof_cancel%TYPE DEFAULT NULL,
        i_id_cancel_reason  IN epis_hhc_discharge.id_cancel_reason%TYPE DEFAULT NULL,
        i_cancel_notes      IN epis_hhc_discharge.cancel_notes%TYPE DEFAULT NULL, -- CLOB
        i_dt_cancel         IN epis_hhc_discharge.dt_cancel%TYPE DEFAULT NULL,
        i_id_prof_creation  IN epis_hhc_discharge_h.id_prof_creation%TYPE DEFAULT NULL,
        i_dt_creation       IN epis_hhc_discharge_h.dt_creation%TYPE DEFAULT NULL,
        i_id_group          IN epis_hhc_disch_det_h.id_group%TYPE
    );

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION ins_hhc_disch_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_hhc_discharge IN epis_hhc_disch_det.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE,
        i_value            IN table_varchar,
        i_hhc_text         IN epis_hhc_disch_det.hhc_text%TYPE,
        i_id_prof_creation IN epis_hhc_disch_det.id_prof_creation%TYPE,
        i_dt_creation      IN epis_hhc_disch_det.dt_creation%TYPE,
        i_id_group         IN epis_hhc_disch_det_h.id_group%TYPE
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    PROCEDURE ins_hhc_disch_det_internal
    (
        i_id_hhc_disch_det IN epis_hhc_disch_det.id_hhc_disch_det%TYPE,
        i_id_hhc_discharge IN epis_hhc_disch_det.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE,
        i_hhc_value        IN epis_hhc_disch_det.hhc_value%TYPE,
        i_hhc_text         IN epis_hhc_disch_det.hhc_text%TYPE,
        i_hhc_date_time    IN epis_hhc_disch_det.hhc_date_time%TYPE,
        i_id_prof_creation IN epis_hhc_disch_det.id_prof_creation%TYPE,
        i_dt_creation      IN epis_hhc_disch_det.dt_creation%TYPE
    );

    /*******************************************************************************************
    *******************************************************************************************/
    PROCEDURE ins_hhc_disch_det_hist
    (
        i_id_hhc_disch_det IN epis_hhc_disch_det_h.id_hhc_disch_det%TYPE,
        i_id_hhc_discharge IN epis_hhc_disch_det_h.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det_h.id_hhc_det_type%TYPE,
        i_hhc_value        IN epis_hhc_disch_det_h.hhc_value%TYPE,
        i_hhc_text         IN epis_hhc_disch_det_h.hhc_text%TYPE,
        i_hhc_date_time    IN epis_hhc_disch_det.hhc_date_time%TYPE,
        i_id_prof_creation IN epis_hhc_disch_det_h.id_prof_creation%TYPE,
        i_dt_creation      IN epis_hhc_disch_det_h.dt_creation%TYPE,
        id_group           IN epis_hhc_disch_det_h.id_group%TYPE
    );

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION set_hhc_team_discharge_alert
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_hhc_req IN NUMBER,
        i_episode         IN episode.id_episode%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    *******************************************************************************************/
    FUNCTION get_episode_by_id_epis_hhc_req
    (
        i_lang            IN language.id_language%TYPE,
        i_id_epis_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE
    ) RETURN episode.id_episode%TYPE;

    --------------------------------------------------------------------------------------
    FUNCTION get_val_t
    (
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE
    ) RETURN VARCHAR2;

    --------------------------------------------------------------------------------------
    FUNCTION get_val_dt
    (
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    --------------------------------------------------------------------------------------
    FUNCTION get_val_d
    (
        i_id_hhc_discharge IN epis_hhc_discharge.id_hhc_discharge%TYPE,
        i_id_hhc_det_type  IN epis_hhc_disch_det.id_hhc_det_type%TYPE
    ) RETURN table_varchar;

END pk_hhc_discharge;
/
