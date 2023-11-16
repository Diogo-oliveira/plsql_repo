/*-- Last Change Revision: $Rev: 2028737 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_image_tech AS

    /*
    * Fills grid task image exams table
    *
    * @param      i_lang           Language
    * @param      i_prof           Profissional
    * @param      i_patient        Patient id
    * @param      i_episode        Episode id
    * @param      i_exam_req       Order exam id
    * @param      i_exam_req_det   Order exam detail id
    * @param      o_error          Error
    *
    * @return     boolean
    * @author     Ana Matos
    * @version    2.4.3
    * @since      2008/03/13
    */

    FUNCTION set_exam_grid_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_exam_req     IN exam_req.id_exam_req%TYPE,
        i_exam_req_det IN exam_req_det.id_exam_req_det%TYPE,
        i_flg_type     IN exam.flg_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE set_exam_episode_status
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
    * @author    Ana Matos
    * @version   2.5
    * @since     2008/03/20
    */

    FUNCTION get_technician_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the exams that can be scheduled or rescheduled for a patient
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

    FUNCTION get_exam_to_schedule_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of active patients with at least one exam order
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

    FUNCTION get_epis_active_itech
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_epis_active_itech
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_where IN VARCHAR2,
        i_from  IN VARCHAR2
    ) RETURN t_coll_episactiveitech;

    FUNCTION get_col_request
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_status_req_det IN exam_req_det.flg_status%TYPE,
        i_flg_status_mov     IN movement.flg_status%TYPE,
        i_flg_time_req       IN exam_req.flg_time%TYPE,
        i_flg_referral       IN exam_req_det.flg_referral%TYPE,
        i_flg_status_r       IN result_status.value%TYPE,
        i_dt_req_tstz        IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req_tstz   IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin_tstz      IN exam_req.dt_begin_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_col_transport
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_status_req_det IN exam_req_det.flg_status%TYPE,
        i_flg_status_mov     IN movement.flg_status%TYPE,
        i_flg_time_req       IN exam_req.flg_time%TYPE,
        i_flg_referral       IN exam_req_det.flg_referral%TYPE,
        i_flg_status_r       IN result_status.value%TYPE,
        i_dt_req_mov_tstz    IN movement.dt_req_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_col_execute
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_flg_status_req_det IN exam_req_det.flg_status%TYPE,
        i_flg_status_mov     IN movement.flg_status%TYPE,
        i_flg_time_req       IN exam_req.flg_time%TYPE,
        i_flg_referral       IN exam_req_det.flg_referral%TYPE,
        i_flg_status_r       IN result_status.value%TYPE,
        i_dt_end_mov_tstz    IN movement.dt_end_tstz%TYPE,
        i_dt_req_tstz        IN exam_req.dt_req_tstz%TYPE,
        i_dt_pend_req_tstz   IN exam_req.dt_pend_req_tstz%TYPE,
        i_dt_begin_tstz      IN exam_req.dt_begin_tstz%TYPE
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

    PROCEDURE init_params_sched_req
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

    g_no_results BOOLEAN;
    g_overlimit  BOOLEAN;

END pk_image_tech;
/
