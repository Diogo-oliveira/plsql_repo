/*-- Last Change Revision: $Rev: 2028766 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:48 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_lab_tech AS

    /*
    * Fills the lab tests grid task table
    *
    * @param     i_lang               Language id
    * @param     i_prof               Professional
    * @param     i_patient            Patient id
    * @param     i_episode            Episode id
    * @param     i_analysis_req       Lab tests' order id
    * @param     i_analysis_req_det   Lab tests' order detail id
    * @param     o_error              Error message
    
    * @return    true or false on success or error
    *
    * @author    Gustavo Serrano
    * @version   2.4.2
    * @since     2008/03/12
    */

    FUNCTION set_lab_test_grid_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req     IN analysis_req.id_analysis_req%TYPE,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE set_lab_test_episode_status
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /*
    * Returns the technician's grid
    *
    * @param     i_lang    Language id
    * @param     i_prof    Professional
    * @param     o_list    Cursor
    * @param     o_error   Error message
    
    * @return    true or false on success or error
    *
    * @author    Rui Neves
    * @version   2.5
    * @since     2006/09/15
    */

    FUNCTION get_technician_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_patient_by_harvest_barcode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_barcode IN harvest.barcode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the lab tests that can be scheduled or rescheduled for a patient
    *
    * @param     i_lang      Language id
    * @param     i_prof      Professional
    * @param     i_patient   Patient id
    * @param     o_list      Cursor
    * @param     o_error     Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.7.4.6
    * @since     2018/11/16
    */

    FUNCTION get_lab_test_to_schedule_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of active patients with at least one lab test order
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_id_sys_btn_crit   Search criteria chosen
    * @param     i_crit_val          Search criteria
    * @param     o_list              Cursor
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    *
    * @author    Ana Matos
    * @version   2.5
    * @since     2009/10/23
    */

    FUNCTION get_epis_active_ltech
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of inactive patients with at least one lab test order
    *
    * @param     i_lang              Language id
    * @param     i_prof              Professional
    * @param     i_id_sys_btn_crit   Search criteria chosen
    * @param     i_crit_val          Search criteria
    * @param     o_list              Cursor
    * @param     o_error             Error message
    
    * @return    true or false on success or error
    *
    * @author    Susana Seixas
    * @version   2.5
    * @since     2007/07/26
    */

    FUNCTION get_epis_inactive_ltech
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_col_request
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_status        IN analysis_req_det.flg_status%TYPE,
        i_flg_time_harvest  IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_referral      IN analysis_req_det.flg_referral%TYPE,
        i_flg_status_h      IN harvest.flg_status%TYPE,
        i_flg_status_result IN analysis_result.flg_status%TYPE,
        i_dt_req_tstz       IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req_tstz  IN analysis_req.dt_pend_req_tstz%TYPE,
        i_dt_target_tstz    IN analysis_req_det.dt_target_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_col_harvest
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_status            IN analysis_req_det.flg_status%TYPE,
        i_flg_time_harvest      IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_h          IN harvest.flg_status%TYPE,
        i_dt_req_tstz           IN analysis_req.dt_req_tstz%TYPE,
        i_dt_pend_req_tstz      IN analysis_req.dt_pend_req_tstz%TYPE,
        i_dt_target_tstz        IN analysis_req_det.dt_target_tstz%TYPE,
        i_dt_harvest            IN harvest.dt_harvest_tstz%TYPE,
        i_dt_begin_tstz_m       IN movement.dt_begin_tstz%TYPE,
        i_dt_mov_begin_tstz     IN movement.dt_begin_tstz%TYPE,
        i_dt_end_tstz           IN movement.dt_end_tstz%TYPE,
        i_dt_lab_reception_tstz IN movement.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_col_transport
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_flg_status        IN analysis_req_det.flg_status%TYPE,
        i_flg_time_harvest  IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_h      IN harvest.flg_status%TYPE,
        i_dt_begin_tstz_m   IN movement.dt_begin_tstz%TYPE,
        i_dt_mov_begin_tstz IN movement.dt_begin_tstz%TYPE,
        i_dt_harvest        IN harvest.dt_harvest_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_col_execute
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_time_harvest      IN analysis_req_det.flg_time_harvest%TYPE,
        i_flg_status_h          IN harvest.flg_status%TYPE,
        i_dt_end_tstz           IN movement.dt_end_tstz%TYPE,
        i_dt_lab_reception_tstz IN movement.dt_begin_tstz%TYPE,
        i_dt_harvest            IN harvest.dt_harvest_tstz%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE init_params_grid
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

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_found        BOOLEAN;

END pk_lab_tech;
/
