/*-- Last Change Revision: $Rev: 2028852 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_patient_education_ux IS

    FUNCTION check_params
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_time   IN VARCHAR2,
        i_start_date IN VARCHAR2,
        i_duration   IN VARCHAR2,
        i_end_date   IN VARCHAR2,
        o_params     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    --
    PROCEDURE create_suggestion
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_id_episode         IN nurse_tea_req.id_episode%TYPE,
        i_id_nurse_tea_topic IN table_number,
        i_trig_by            IN table_clob,
        i_id_context         IN nurse_tea_req.id_context%TYPE,
        o_id_nurse_tea_req   OUT table_number
    );

    --
    FUNCTION create_request
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN nurse_tea_req.id_episode%TYPE,
        i_topics                IN table_number,
        i_compositions          IN table_table_number,
        i_diagnoses             IN table_clob,
        i_to_be_performed       IN table_varchar,
        i_start_date            IN table_varchar,
        i_notes                 IN table_varchar,
        i_description           IN table_clob,
        i_order_recurr          IN table_number,
        i_draft                 IN VARCHAR2 DEFAULT 'N',
        i_id_nurse_tea_req_sugg IN table_number,
        i_desc_topic_aux        IN table_varchar,
        i_not_order_reason      IN table_number,
        o_id_nurse_tea_req      OUT table_number,
        o_id_nurse_tea_topic    OUT table_number,
        o_title_topic           OUT table_varchar,
        o_desc_diagnosis        OUT table_varchar,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_request
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_draft                IN VARCHAR2 DEFAULT 'N',
        i_topics               IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_tbl_val_array        IN tt_table_varchar DEFAULT NULL,
        i_flg_edition          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_tbl_nurse_tea_req    IN table_number DEFAULT NULL,
        o_id_nurse_tea_req     OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION cancel_patient_education
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN nurse_tea_req.notes_close%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_diagnosis_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2;

    --
    FUNCTION get_id_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN table_number;

    FUNCTION get_desc_diagnosis
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN table_varchar;
    --

    --
    FUNCTION get_domain_flg_time
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_values OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_domain_flg_time
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain;

    FUNCTION get_default_domain_time
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_val      OUT VARCHAR2,
        o_desc_val OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_request_for_update
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_patient_education_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_register         OUT pk_types.cursor_type,
        o_detail           OUT pk_types.cursor_type,
        o_main             OUT pk_types.cursor_type,
        o_data             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_patient_education_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_patient_education_det_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_detail           OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_patient_education_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_hhc_req IN epis_hhc_req.id_epis_hhc_req%TYPE DEFAULT NULL,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_patient_education_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_patient_education_all_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    --
    /*  FUNCTION get_patient_education_timeline(i_lang       IN language.id_language%TYPE,
                                          i_prof       IN profissional,
                                          i_id_episode IN episode.id_episode%TYPE,
                                          i_start_date IN VARCHAR2,
                                          i_end_date   IN VARCHAR2,
                                          o_view       OUT pk_types.cursor_type,
                                          o_tasks      OUT pk_types.cursor_type,
                                          o_error      OUT t_error_out)
    RETURN BOOLEAN;*/

    --
    FUNCTION get_topic_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_topic_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_keyword         IN VARCHAR2,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_subject_topic_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_subject      IN nurse_tea_subject.id_nurse_tea_subject%TYPE,
        i_flg_show_others IN VARCHAR2 DEFAULT 'Y',
        o_subjects        OUT pk_types.cursor_type,
        o_topics          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_subject
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE
    ) RETURN CLOB;

    --
    FUNCTION get_documentation_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_goals            OUT pk_types.cursor_type,
        o_methods          OUT pk_types.cursor_type,
        o_given_to         OUT pk_types.cursor_type,
        o_deliverables     OUT pk_types.cursor_type,
        o_understanding    OUT pk_types.cursor_type,
        o_info             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_documentation_goals
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_documentation_methods
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_documentation_given_to
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_documentation_addit_res
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_doc_level_understanding
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain;

    --
    FUNCTION set_documentation_exec
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_nurse_tea_req   IN nurse_tea_det.id_nurse_tea_req%TYPE,
        i_subject            IN table_varchar,
        i_id_nurse_tea_opt   IN table_number,
        i_free_text          IN table_clob,
        i_dt_start           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        i_duration           IN NUMBER,
        i_unit_meas_duration IN NUMBER,
        i_description        IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_documentation_exec
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_nurse_tea_req     IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_mea          IN table_table_varchar,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_order_for_execution
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_nurse_tea_topic   IN table_number,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_tbl_val_mea          IN table_table_varchar,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION set_ignore_suggestion
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION update_request
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN nurse_tea_req.id_episode%TYPE,
        i_id_nurse_tea_req IN table_number,
        i_topics           IN table_number,
        i_compositions     IN table_table_number,
        i_diagnoses        IN table_clob,
        i_to_be_performed  IN table_varchar,
        i_start_date       IN table_varchar,
        i_notes            IN table_varchar,
        i_description      IN table_clob,
        i_order_recurr     IN table_number,
        i_upd_flg_status   IN VARCHAR2 DEFAULT 'Y',
        i_not_order_reason IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    ----------------------------------------------------------
    FUNCTION set_nurse_tea_req_status
    (
        i_lang          IN language.id_language%TYPE,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE insert_ntr_hist
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    );

    /******************************************************************************/
    FUNCTION create_nurse_tea_req
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN nurse_tea_req.id_episode%TYPE,
        i_prof_req         IN profissional,
        i_dt_begin_str     IN VARCHAR2,
        i_notes_req        IN nurse_tea_req.notes_req%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        o_id_nurse_tea_req OUT nurse_tea_req.id_nurse_tea_req%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_subject_by_id_topic
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_topic IN nurse_tea_topic.id_nurse_tea_topic%TYPE,
        o_subject  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns available actions according with patient education request's status
    *
    * @param   i_lang           Professional preferred language
    * @param   i_prof           Professional identification and its context (institution and software)
    * @param   i_nurse_tea_req  Patient education request IDs
    * @param   o_actions        Available actions
    * @param   o_error          Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.1.5
    * @since   07-11-2011
    */
    FUNCTION get_request_actions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN table_number,
        i_id_episode    IN episode.id_episode%TYPE,
        i_id_hhc_req    IN epis_hhc_req.id_epis_hhc_req%TYPE,
        o_actions       OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diagnosis_cancel
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_composition_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_nurse_tea_req IN nurse_tea_req.id_nurse_tea_req%TYPE
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

    PROCEDURE init_params_topic_list
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

    --

    g_sysdate DATE;
    g_error   VARCHAR2(100);
    g_package_owner CONSTANT VARCHAR2(5) := 'ALERT';
    g_package_name  CONSTANT VARCHAR2(20) := 'PK_PATIENT_EDUCATION';
    g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;

    g_exception EXCEPTION;

    g_selected   CONSTANT prof_dep_clin_serv.flg_status%TYPE := 'S';
    g_searchable CONSTANT nurse_tea_top_soft_inst.flg_type%TYPE := 'P';
    g_frequent   CONSTANT nurse_tea_top_soft_inst.flg_type%TYPE := 'M';

    g_nurse_tea_req_sug   CONSTANT nurse_tea_req.flg_status%TYPE := 'S';
    g_nurse_tea_req_pend  CONSTANT nurse_tea_req.flg_status%TYPE := 'D';
    g_nurse_tea_req_act   CONSTANT nurse_tea_req.flg_status%TYPE := 'A';
    g_nurse_tea_req_fin   CONSTANT nurse_tea_req.flg_status%TYPE := 'F';
    g_nurse_tea_req_canc  CONSTANT nurse_tea_req.flg_status%TYPE := 'C';
    g_nurse_tea_req_ign   CONSTANT nurse_tea_req.flg_status%TYPE := 'I';
    g_nurse_tea_req_draft CONSTANT nurse_tea_req.flg_status%TYPE := 'Z';

    g_nurse_tea_det_pend CONSTANT nurse_tea_det.flg_status%TYPE := 'D';
    g_nurse_tea_det_exec CONSTANT nurse_tea_det.flg_status%TYPE := 'E';
    g_nurse_tea_det_canc CONSTANT nurse_tea_det.flg_status%TYPE := 'C';
    g_nurse_tea_det_ign  CONSTANT nurse_tea_det.flg_status%TYPE := 'I';

    g_flg_time_before  CONSTANT nurse_tea_req.flg_time%TYPE := 'B';
    g_flg_time_episode CONSTANT nurse_tea_req.flg_time%TYPE := 'E';
    g_flg_time_next    CONSTANT nurse_tea_req.flg_time%TYPE := 'N';

    g_sys_domain_req_flg_status   CONSTANT sys_domain.code_domain%TYPE := 'NURSE_TEA_REQ.FLG_STATUS';
    g_sys_domain_det_flg_status   CONSTANT sys_domain.code_domain%TYPE := 'NURSE_TEA_DET.FLG_STATUS';
    g_sys_domain_flg_time         CONSTANT sys_domain.code_domain%TYPE := 'NURSE_TEA_REQ.FLG_TIME';
    g_sys_domain_flg_deliverables CONSTANT sys_domain.code_domain%TYPE := 'NURSE_TEA_DET.FLG_DELIVERABLES';

    g_flg_validation_error CONSTANT VARCHAR2(1 CHAR) := 'E';

    g_yes VARCHAR2(1) := 'Y';
    g_no  VARCHAR2(1) := 'N';

    -- max size used to truncate clob fields
    g_trunc_clob_max_size CONSTANT NUMBER := 32767;

END pk_patient_education_ux;
/
