/*-- Last Change Revision: $Rev: 2055401 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-22 09:43:55 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_opinion IS

    SUBTYPE obj_name IS VARCHAR2(30);
    SUBTYPE debug_msg IS VARCHAR2(4000);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_opinion_prof_accept  CONSTANT opinion_prof.flg_type%TYPE := 'E';
    g_opinion_prof_reject  CONSTANT opinion_prof.flg_type%TYPE := 'X';
    g_opinion_prof_approve CONSTANT opinion_prof.flg_type%TYPE := 'V';
    g_opinion_prof_refuse  CONSTANT opinion_prof.flg_type%TYPE := 'N';

    g_dashes    CONSTANT sys_message.desc_message%TYPE := '--';
    g_dash      CONSTANT sys_message.desc_message%TYPE := ' - ';
    g_semicolon CONSTANT sys_message.desc_message%TYPE := '; ';
    g_error VARCHAR2(1000 CHAR);
    g_package_owner           CONSTANT obj_name := 'ALERT';
    g_package_name            CONSTANT obj_name := pk_alertlog.who_am_i();
    g_prof_active             CONSTANT professional.flg_state%TYPE := 'A';
    g_opinion_req             CONSTANT opinion.flg_state%TYPE := 'R';
    g_opinion_req_read        CONSTANT opinion.flg_state%TYPE := 'F';
    g_opinion_reply           CONSTANT opinion.flg_state%TYPE := 'P';
    g_opinion_replied         CONSTANT VARCHAR2(1) := 'L';
    g_opinion_reply_read      CONSTANT opinion.flg_state%TYPE := 'A';
    g_opinion_cancel          CONSTANT opinion.flg_state%TYPE := 'C';
    g_opinion_rejected        CONSTANT opinion.flg_state%TYPE := 'X';
    g_opinion_over            CONSTANT opinion.flg_state%TYPE := 'O';
    g_opinion_accepted        CONSTANT opinion.flg_state%TYPE := 'E';
    g_opinion_approved        CONSTANT opinion.flg_state%TYPE := 'V';
    g_opinion_not_approved    CONSTANT opinion.flg_state%TYPE := 'N';
    g_flg_type_nutritionist   CONSTANT opinion.flg_type%TYPE := 'U';
    g_flg_type_case_manager   CONSTANT opinion.flg_type%TYPE := 'C';
    g_opin_prof_read          CONSTANT opinion_prof.flg_type%TYPE := 'R';
    g_opin_prof_reply         CONSTANT opinion_prof.flg_type%TYPE := 'P';
    g_opin_prof_reply_read    CONSTANT opinion_prof.flg_type%TYPE := 'F';
    g_opin_prof_conclusion    CONSTANT opinion_prof.flg_type%TYPE := 'C';
    g_opin_prof_a             CONSTANT opinion_prof.flg_type%TYPE := 'A';
    g_unknown                 CONSTANT opinion_prof.flg_face_to_face%TYPE := 'U';
    g_prof_doctor             CONSTANT category.flg_type%TYPE := 'D';
    g_prof_nutri              CONSTANT category.flg_type%TYPE := 'U';
    g_prof_cm                 CONSTANT category.flg_type%TYPE := 'Q';
    g_opinion_f_t_f_available CONSTANT sys_message.desc_message%TYPE := 'OPINION_FACE_TO_FACE_AVAILABLE';
    g_exception EXCEPTION;
    g_status_active     CONSTANT sys_message.desc_message%TYPE := 'A';
    g_status_inactive   CONSTANT sys_message.desc_message%TYPE := 'I';
    g_status_cancel     CONSTANT sys_message.desc_message%TYPE := 'C';
    g_status_reject     CONSTANT sys_message.desc_message%TYPE := 'R';
    g_status_accepted   CONSTANT sys_message.desc_message%TYPE := 'E';
    g_status_declined   CONSTANT sys_message.desc_message%TYPE := 'X';
    g_status_approved   CONSTANT sys_message.desc_message%TYPE := 'V';
    g_status_completed  CONSTANT sys_message.desc_message%TYPE := 'O';
    g_status_predefined CONSTANT VARCHAR(2 CHAR) := 'PD';
    --
    g_follow_by_me_add CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_follow_by_me_rem CONSTANT VARCHAR2(1 CHAR) := 'R';

    -- follow up request reason field fill types
    g_reason_free_text   CONSTANT VARCHAR2(1 CHAR) := 'T';
    g_reason_multichoice CONSTANT VARCHAR2(1 CHAR) := 'M';

    -- dietitian requests opinion type
    g_ot_dietitian CONSTANT opinion_type.id_opinion_type%TYPE := 1;
    -- case manager requests opinion type
    g_ot_case_manager CONSTANT opinion_type.id_opinion_type%TYPE := 2;
    -- social worker requests opinion type
    g_ot_social_worker CONSTANT opinion_type.id_opinion_type%TYPE := 3;
    -- activity therapist requests opinion type
    g_ot_activity_therapist CONSTANT opinion_type.id_opinion_type%TYPE := 4;
    -- psychology requests opinion type
    g_ot_psychology CONSTANT opinion_type.id_opinion_type%TYPE := 5;
    -- social worker requests opinion type with dynamic screen
    g_ot_social_worker_ds CONSTANT opinion_type.id_opinion_type%TYPE := 10;

    g_ot_occupational_therapy CONSTANT opinion_type.id_opinion_type%TYPE := 11;
    g_ot_physical_therapy     CONSTANT opinion_type.id_opinion_type%TYPE := 12;
    g_ot_speech_therapy       CONSTANT opinion_type.id_opinion_type%TYPE := 13;
    g_ot_cdc                  CONSTANT opinion_type.id_opinion_type%TYPE := 7;
    g_ot_mental               CONSTANT opinion_type.id_opinion_type%TYPE := 9;
    g_ot_religious            CONSTANT opinion_type.id_opinion_type%TYPE := 8;
    g_ot_rehabilitation       CONSTANT opinion_type.id_opinion_type%TYPE := 6;

    --Dynamic screen root for social worker requests
    g_ds_root_social_worker CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_SOCIAL';
    --Dynamic screen elements
    g_ds_prof_list           CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_PROF_LIST';
    g_ds_reason              CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_REASON';
    g_ds_reason_ft           CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_REASON_FT';
    g_ds_equipment_needed    CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_EQUIPMENT';
    g_ds_equipment_needed_ft CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_EQUIPMENT_FT';
    g_ds_notes               CONSTANT ds_component.internal_name%TYPE := 'DS_FOLLOW_UP_REQUEST_NOTES';

    --Dynamic screen element types
    g_ds_check_box_type           CONSTANT ds_component.flg_data_type%TYPE := 'CB';
    g_ds_single_multi_choice_type CONSTANT ds_component.flg_data_type%TYPE := 'MS';
    g_ds_clob_type                CONSTANT ds_component.flg_data_type%TYPE := 'LO';
    g_ds_free_text_type           CONSTANT ds_component.flg_data_type%TYPE := 'FT';

    -- "any" professional identifier
    g_any_prof CONSTANT professional.id_professional%TYPE := -1;

    -- sys_alerts for follow-up requests
    g_alert_needs_approval   CONSTANT sys_alert.id_sys_alert%TYPE := 91;
    g_alert_approval_reply   CONSTANT sys_alert.id_sys_alert%TYPE := 92;
    g_alert_acceptance_reply CONSTANT sys_alert.id_sys_alert%TYPE := 93;
    g_alert_needs_acceptance CONSTANT sys_alert.id_sys_alert%TYPE := 94;

    c_co_sign_type_opinion        CONSTANT co_sign_task.flg_type%TYPE := 'OP';
    g_sys_config_consult_co_sign  CONSTANT sys_config.id_sys_config%TYPE := 'CONSULTSRESPONSE_CO_SIGN';
    g_alert_type_consult_question CONSTANT sys_alert.id_sys_alert%TYPE := 8;

    g_prof_list_group_by_specialty CONSTANT sys_config.value%TYPE := 'S';
    g_prof_list_group_by_clin_serv CONSTANT sys_config.value%TYPE := 'C';

    g_opinion_prof_state_domain CONSTANT sys_domain.code_domain%TYPE := 'OPINION_PROF.FLG_TYPE';
    g_opinion_state_domain      CONSTANT sys_domain.code_domain%TYPE := 'OPINION.FLG_STATE.REQUEST';
    g_opinion_consults          CONSTANT sys_domain.code_domain%TYPE := 'OPINION.FLG_STATE';
    g_opinion_consults_shortcut CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 51;
    g_opinion_priority          CONSTANT sys_domain.code_domain%TYPE := 'OPINION.FLG_PRIORITY';

    g_alert_end_followup CONSTANT sys_alert.id_sys_alert%TYPE := 328;

    TYPE consult_dif IS RECORD(
        
        speciality_b           sys_message.desc_message%TYPE,
        speciality_a           sys_message.desc_message%TYPE,
        request_reason_b       sys_message.desc_message%TYPE,
        request_reason_a       sys_message.desc_message%TYPE,
        request_reason_ft_b    sys_message.desc_message%TYPE,
        request_reason_ft_a    sys_message.desc_message%TYPE,
        name_prof_questioned_b sys_message.desc_message%TYPE,
        name_prof_questioned_a sys_message.desc_message%TYPE,
        notes_b                CLOB,
        notes_a                CLOB,
        state_b                sys_message.desc_message%TYPE,
        state_a                sys_message.desc_message%TYPE,
        notes_cancel_b         sys_message.desc_message%TYPE,
        notes_cancel_a         sys_message.desc_message%TYPE,
        cancel_reason_b        sys_message.desc_message%TYPE,
        cancel_reason_a        sys_message.desc_message%TYPE,
        registered_b           sys_message.desc_message%TYPE,
        registered_a           sys_message.desc_message%TYPE,
        create_time            sys_message.desc_message%TYPE);

    TYPE consult_dif_table IS TABLE OF consult_dif INDEX BY BINARY_INTEGER;

    TYPE consult_type IS RECORD(
        
        request_title        sys_message.desc_message%TYPE,
        opinion_type         sys_message.desc_message%TYPE,
        speciality           sys_message.desc_message%TYPE,
        request_reason       sys_message.desc_message%TYPE,
        request_reason_ft    sys_message.desc_message%TYPE,
        name_prof_questioned sys_message.desc_message%TYPE,
        notes                CLOB,
        state                sys_message.desc_message%TYPE,
        fu_notes             sys_message.desc_message%TYPE,
        notes_cancel         sys_message.desc_message%TYPE,
        cancel_reason        sys_message.desc_message%TYPE,
        registered           sys_message.desc_message%TYPE,
        create_time          sys_message.desc_message%TYPE);

    /************************************************************************************************************
    * This function returns the specialities for the the professionals that can give a consult (opinion).
    *
    * @param      i_lang            Current language
    * @param      i_prof            Professional that makes the request (profissional, institution and software id's)
    * @param      o_spec            Specialities output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     CRS
    * @version    1.0
    * @since      2005/03/09
    ************************************************************************************************************/
    FUNCTION get_spec_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_spec  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_spec_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_spec_list_by_config
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain;

    /************************************************************************************************************
    * This function returns the professionals for a speciality that can give a consult (opinion).
    * And excludes the professional that makes the request.
    *
    * @param      i_lang            Current language
    * @param      i_prof            Professional that makes the request (profissional, institution and software id's)
    * @param      i_speciality      Speciality id for the consult
    * @param      o_prof            Professionals output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     CRS
    * @version    1.0
    * @since      2005/03/10
    ************************************************************************************************************/
    FUNCTION get_prof_spec_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_speciality IN speciality.id_speciality%TYPE,
        o_prof       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_prof_spec_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_speciality IN speciality.id_speciality%TYPE,
        o_error      OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_prof_spec_list_by_config
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_speciality IN speciality.id_speciality%TYPE
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * Get opinion professional description
    *
    * @param    i_lang                preferred language ID
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_opinion_prof        opinion professional ID
    *
    * @return   varchar2              opinion professional description
    *
    * @author                         Tiago Silva
    * @since                          2010/08/06
    ********************************************************************************************/
    FUNCTION get_opinion_prof_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion_prof IN professional.id_professional%TYPE
    ) RETURN professional.name%TYPE;

    --
    FUNCTION create_opinion
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_flg_origin_req       IN VARCHAR2 DEFAULT 'D',
        i_flg_update           IN VARCHAR2 DEFAULT 'N',
        i_opinion              IN opinion.id_opinion%TYPE DEFAULT NULL,
        o_opinion              OUT opinion.id_opinion%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_opinion
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN opinion.id_episode%TYPE,
        i_prof_questions   IN profissional,
        i_prof_questioned  IN opinion.id_prof_questioned%TYPE,
        i_speciality       IN opinion.id_speciality%TYPE,
        i_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_desc             IN opinion.desc_problem%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_flg_type         IN opinion.flg_type%TYPE,
        i_flg_priority     IN opinion.flg_priority%TYPE DEFAULT 'N',
        i_flg_origin_req   IN VARCHAR2 DEFAULT 'D',
        i_flg_update       IN VARCHAR2 DEFAULT 'N',
        i_opinion          IN opinion.id_opinion%TYPE DEFAULT NULL,
        o_opinion          OUT opinion.id_opinion%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_opinion
    (
        i_lang             IN language.id_language%TYPE,
        i_episode          IN opinion.id_episode%TYPE,
        i_prof_questions   IN profissional,
        i_prof_questioned  IN opinion.id_prof_questioned%TYPE,
        i_speciality       IN opinion.id_speciality%TYPE,
        i_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_desc             IN opinion.desc_problem%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_commit_data      IN VARCHAR2,
        i_diag             IN table_number,
        i_patient          IN opinion.id_patient%TYPE,
        i_flg_type         IN opinion.flg_type%TYPE DEFAULT 'O',
        i_dt_creation      IN opinion.dt_problem_tstz%TYPE DEFAULT current_timestamp,
        i_flg_priority     IN opinion.flg_priority%TYPE DEFAULT 'N',
        i_flg_origin_req   IN VARCHAR2 DEFAULT 'D',
        i_flg_update       IN VARCHAR2 DEFAULT 'N',
        i_opinion          IN opinion.id_opinion%TYPE DEFAULT NULL,
        o_opinion          OUT opinion.id_opinion%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_opinion_from_order_set
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN opinion.id_episode%TYPE,
        i_id_opinion IN opinion.id_opinion%TYPE,
        o_opinion    OUT opinion.id_opinion%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_opinion_copy_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN opinion.id_opinion%TYPE,
        o_opinion      OUT opinion.id_opinion%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_opin_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_opinion          IN opinion.id_opinion%TYPE,
        i_prof             IN profissional,
        i_desc             IN opinion.desc_problem%TYPE,
        i_flg_face_to_face IN opinion_prof.flg_face_to_face%TYPE DEFAULT g_unknown,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_opin_prof_int
    (
        i_lang             IN language.id_language%TYPE,
        i_opinion          IN opinion.id_opinion%TYPE,
        i_prof             IN profissional,
        i_desc             IN opinion.desc_problem%TYPE,
        i_flg_face_to_face IN opinion_prof.flg_face_to_face%TYPE,
        i_commit_data      IN VARCHAR2,
        i_dt_reply         IN opinion_prof.dt_opinion_prof_tstz%TYPE DEFAULT current_timestamp,
        o_opinion_prof     OUT opinion_prof.id_opinion_prof%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets all episode opinions to the 'replied' status
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Jos� Silva
    * @version               2.5.0.7.8
    * @since                 30-09-2010
    ********************************************************************************************/
    FUNCTION set_opinion_auto_reply
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_opinion_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_opinion IN opinion.id_opinion%TYPE,
        o_flg_status OUT opinion.flg_state%TYPE,
        -- o_desc_status  OUT VARCHAR2,
        -- o_flg_text     OUT VARCHAR2,
        -- o_color_status OUT VARCHAR2,
        o_status_string OUT VARCHAR2,
        o_flg_finished  OUT VARCHAR2,
        o_flg_canceled  OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_opinion
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN opinion.id_episode%TYPE,
        i_prof       IN profissional,
        i_patient    IN opinion.id_patient%TYPE,
        i_flg_type   IN opinion.flg_type%TYPE DEFAULT 'O',
        i_flg_status IN table_varchar DEFAULT NULL,
        o_opinion    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_opinion_by_prof
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_limit_max IN NUMBER,
        i_limit_min IN NUMBER,
        o_opinion   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_opin_prof
    (
        i_lang      IN language.id_language%TYPE,
        i_opinion   IN opinion.id_opinion%TYPE,
        i_prof      IN profissional,
        o_opinion   OUT pk_types.cursor_type,
        o_opin_prof OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_opin_prof
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_opinion
    (
        i_lang    IN language.id_language%TYPE,
        i_opinion IN opinion.id_opinion%TYPE,
        i_prof    IN profissional,
        i_notes   IN opinion.notes_cancel%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_opinion
    (
        i_lang          IN language.id_language%TYPE,
        i_opinion       IN opinion.id_opinion%TYPE,
        i_prof          IN profissional,
        i_cancel_reason IN opinion.id_cancel_reason%TYPE DEFAULT NULL,
        i_notes         IN opinion.notes_cancel%TYPE,
        i_flg_type      IN opinion.flg_type%TYPE DEFAULT 'O',
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_opinion
    (
        i_lang          IN language.id_language%TYPE,
        i_opinion       IN opinion.id_opinion%TYPE,
        i_prof          IN profissional,
        i_notes         IN opinion.notes_cancel%TYPE,
        i_cancel_reason IN opinion.id_cancel_reason%TYPE,
        i_dt_cancel     IN opinion.dt_cancel_tstz%TYPE DEFAULT current_timestamp,
        i_commit_data   IN VARCHAR2,
        i_flg_type      IN opinion.flg_type%TYPE DEFAULT 'O',
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_face_to_face_available
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_face_to_face OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_face_to_face_default
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Checks if a case is requestable. The logged professional and current patient are considered.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_prof_cat         logged professional category
    * @param i_patient          patient identifier
    * @param o_avail            'Y', if cases are requestable, 'N' otherwise
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/08/18
    ********************************************************************************************/
    FUNCTION check_cm_req
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        i_patient  IN opinion.id_patient%TYPE,
        o_avail    OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Retrieve options for requesting a new case.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param o_reason           list of reasons for the request
    * @param o_manager          list of case managers
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/08/19
    ********************************************************************************************/
    FUNCTION get_cm_req_options
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN opinion.id_patient%TYPE,
        o_reason  OUT pk_types.cursor_type,
        o_manager OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Retrieve case management request origin (<software> - <clinical_service>).
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_episode          episode identifier
    *
    * @return                   '<software> - <clinical_service>' shaped string
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/08/19
    ********************************************************************************************/
    FUNCTION get_cm_req_origin
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN epis_info.id_episode%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************
    * Retrieves a case management request reasons, comma separated.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    *
    * @return                   case management request reasons, comma separated
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/08/21
    ********************************************************************************************/
    FUNCTION get_cm_req_reason
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************
    * Retrieves history of operations made in a case management request.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param o_hist             cursor (info, details)
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/08/19
    ********************************************************************************************/
    FUNCTION get_cm_req_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        o_hist    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Create a case management request.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_episode          episode identifier
    * @param i_patient          patient identifier
    * @param i_diag             list of associated reasons
    * @param i_cm_prof          case manager identifier
    * @param i_notes            request notes
    * @param o_opinion          create opinion identifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/08/19
    ********************************************************************************************/
    FUNCTION create_cm_req
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN opinion.id_episode%TYPE,
        i_patient IN opinion.id_patient%TYPE,
        i_diag    IN table_number,
        i_cm_prof IN opinion.id_prof_questions%TYPE,
        i_notes   IN opinion.desc_problem%TYPE,
        o_opinion OUT opinion.id_opinion%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Cancel a case management request.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param i_cancel_reason    cancel reason identifier
    * @param i_notes            request notes
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/08/31
    ********************************************************************************************/
    FUNCTION cancel_cm_req
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_opinion       IN opinion.id_opinion%TYPE,
        i_cancel_reason IN opinion.id_cancel_reason%TYPE,
        i_notes         IN opinion.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Ends the request. or undo end
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          Id opinion
    * @param i_flg_type         Flg_Type : C - Completed A - end of request cancellation
    * @param i_commit_data      if must do commit Y - True N - False
    * @param o_opinion          create opinion identifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Elisabete Bugalho
    * @version                   2.5.0.7
    * @since                    26-10-2009
    ********************************************************************************************/
    FUNCTION create_prof_conclusion_int
    (
        i_lang         IN language.id_language%TYPE,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_prof         IN profissional,
        i_flg_type     IN opinion_prof.flg_type%TYPE,
        i_commit_data  IN VARCHAR2,
        o_opinion_prof OUT opinion_prof.id_opinion_prof%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Retrieves required data for the case management request's answer.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_opinion               opinion identifier
    * @param o_request               cursor (request data)
    * @param o_refuse_list           cursor (refuse list)
    * @param o_level_list            cursor (urgency levels list)
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.6.0.1
    * @since                         09-10-2010
    **********************************************************************************************/
    FUNCTION get_req_answer
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_opinion    IN opinion.id_opinion%TYPE,
        o_request    OUT pk_types.cursor_type,
        o_level_list OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get the consult requests list for a given episode.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient id
    * @param i_episode          episode id
    * @param i_show_cancelled   set 'Y' to show cancelled records 
    * @param o_consult_req      consult requests
    * @param o_error            error
    *   
    * @author                 Paulo Teixeira
    * @version                2.6.0.1
    * @since                  2010/04/08
    */
    FUNCTION get_consult_requests_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN opinion.id_patient%TYPE,
        i_episode        IN opinion.id_episode%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_consult_req    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get a consult requests record history.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient id
    * @param i_episode          episode id   
    * @param i_opinion          opinion id
    * @param o_consult_req      consult request first state
    * @param o_consult_req_hist consult request history
    * @param o_consult_req_approve consult approve history
    * @param o_consult_req_accept consult accept history
    * @param o_consult_req_comp consult request accompaniment
    * @param o_error            error
    *
    * @author                 Paulo Teixeira
    * @version                2.6.0.1
    * @since                  2010/04/08
    */
    FUNCTION get_consult_requests_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patient             IN opinion.id_patient%TYPE,
        i_episode             IN opinion.id_episode%TYPE,
        i_opinion             IN opinion.id_opinion%TYPE,
        o_consult_req         OUT pk_types.cursor_type,
        o_consult_req_hist    OUT table_table_varchar,
        o_consult_req_approve OUT pk_types.cursor_type,
        o_consult_req_accept  OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get a consult requests record history.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient id
    * @param i_episode          episode id   
    * @param i_opinion          opinion id
    * @param o_consult_req      consult request current state
    * @param o_consult_req_comp consult request accompaniment
    * @param o_error            error
    *
    * @author                 Paulo Teixeira
    * @version                2.6.0.1
    * @since                  2010/04/08
    */
    FUNCTION get_consult_requests_general
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN opinion.id_patient%TYPE,
        i_episode          IN opinion.id_episode%TYPE,
        i_opinion          IN opinion.id_opinion%TYPE,
        o_consult_req      OUT pk_types.cursor_type,
        o_consult_req_comp OUT table_table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get a consult requests record to reports.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient id
    * @param i_episode          episode id   
    * @param i_opinion          opinion id
    * @param o_consult_req      consult request current state
    * @param o_consult_req_comp consult request accompaniment
    * @param o_error            error
    *
    * @author                 Joel Lopes
    * @version                2.6.0.1
    * @since                  2013/02/03
    */
    FUNCTION get_cons_req_general_report
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN opinion.id_patient%TYPE,
        i_episode          IN opinion.id_episode%TYPE,
        i_opinion          IN opinion.id_opinion%TYPE,
        o_consult_req      OUT pk_types.cursor_type,
        o_consult_req_comp OUT table_table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Retrieves a case management request reasons, comma separated.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion_hist     opinion_hist identifier
    *
    * @return                   case management request reasons, comma separated
    *
    * @author                   Pedro Carneiro
    * @version                   2.5.0.7
    * @since                    2009/08/21
    ********************************************************************************************/
    FUNCTION get_cm_req_reason_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion_hist IN opinion_hist.id_opinion_hist%TYPE
    ) RETURN VARCHAR2;

    /*******************************************************************************************
    * Answers (accepts/rejects) a case management request.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param i_patient          patient identifier
    * @param i_flg_state        Acceptance (E - accept / X - Reject )
    * @param i_management_level management level identifier
    * @param i_notes            answer notes
    * @param i_cancel_reason    refuse reason
    * @param i_transaction_id   remote SCH 3.0 transaction id
    * @param i_do_commit        perform commit inside this function
    * @param o_opinion          opinion identifier
    * @param o_opinion_prof     opinion prof identifier
    * @param o_episode          episode identifier
    * @param o_epis_encounter   episode encounter dentifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Elisabete Bugalho
    * @version                  2.6.0.1
    * @since                    09-04-2010
    ********************************************************************************************/
    FUNCTION set_request_answer
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion_prof.id_opinion%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_flg_state        IN opinion.flg_state%TYPE,
        i_management_level IN opinion.id_management_level%TYPE,
        i_notes            IN opinion_prof.desc_reply%TYPE,
        i_cancel_reason    IN opinion_prof.id_cancel_reason%TYPE,
        i_transaction_id   IN VARCHAR2,
        i_do_commit        IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_dt_opinion       IN TIMESTAMP DEFAULT NULL,
        o_opinion_prof     OUT opinion_prof.id_opinion_prof%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_epis_encounter   OUT epis_encounter.id_epis_encounter%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Check if a follow-up request needs approval.
    *
    * @param i_prof           requester professional structure
    * @param i_opinion_type   follow-up request type
    *
    * @return                 Y if approval is needed, N otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/09
    */
    FUNCTION check_approval_need
    (
        i_prof         IN profissional,
        i_opinion_type IN opinion.id_opinion_type%TYPE
    ) RETURN opinion_type_prof.flg_approve%TYPE;

    /*
    * Check if new follow-up request can be created.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_patient        patient identifier
    * @param o_create         create flag
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/12
    */
    FUNCTION check_create_request
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get list of follow-up requests approvers.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_patient        patient identifier
    * @param i_episode        episode identifier
    *
    * @return                 list of approvers
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/12
    */
    FUNCTION get_approvers_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE := NULL
    ) RETURN table_number;

    /*
    * Get list of actions for the follow-up requests screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_patient        patient identifier
    * @param i_opinion        follow-up request identifier
    * @param o_actions        actions cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/12
    */
    FUNCTION get_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_opinion IN opinion.id_opinion%TYPE,
        o_actions OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get list of follow-up request types, for the create button.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_patient        patient identifier
    * @param o_types          types cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/12
    */
    FUNCTION get_request_types
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_types   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Show user warnings prior to creating a new follow-up request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_patient        patient identifier
    * @param i_opinion_type   patient identifier
    * @param o_flg_show       'Y', when warnings exist.
    * @param o_msg            warning message
    * @param o_msg_title      warning message title
    * @param o_popup_title    warning popup title
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/12
    */
    FUNCTION get_warnings
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_opinion_type IN opinion.id_opinion_type%TYPE,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_popup_title  OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_detail_description
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_type      IN ds_component.flg_data_type%TYPE,
        i_internal_name IN ds_component.internal_name%TYPE,
        i_code_domain   IN ds_component.code_domain%TYPE,
        i_value         IN opinion_ds.value%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_consult_request_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    /*
    * Get request information, for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion        opinion identifier
    * @param i_opinion_type   patient identifier
    * @param o_spec           specialties cursor
    * @param o_spec_enable    enable specialty field? (Y/N)
    * @param o_reason_type    reason field fill type (T/M)
    * @param o_opinion        opinion cursor
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/13
    */
    FUNCTION get_consult_request_edit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        o_spec         OUT pk_types.cursor_type,
        o_spec_enable  OUT VARCHAR2,
        o_reason_type  OUT VARCHAR2,
        o_opinion      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set request.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_patient        patient identifier
    * @param i_opinion        opinion identifier
    * @param i_opinion_type   opinion type identifier
    * @param i_clin_serv      clinical service identifier
    * @param i_reason_ft      request reason (free text)
    * @param i_reason_mc      request reason (multichoice)
    * @param i_prof_id        questioned professional identifier
    * @param i_notes          request notes
    * @param i_do_commit      perform commit inside this function
    * @param i_followup_auto  automatic follow-up 
    * @param o_opinion        created opinion identifier
    * @param o_opinion_hist   created opinion history identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/13
    */
    FUNCTION set_consult_request
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_opinion             IN opinion.id_opinion%TYPE,
        i_opinion_type        IN opinion_type.id_opinion_type%TYPE,
        i_clin_serv           IN opinion.id_clinical_service%TYPE,
        i_reason_ft           IN opinion.desc_problem%TYPE,
        i_reason_mc           IN table_number,
        i_tbl_alert_diagnosis IN table_number,
        i_reason_mc_desc      IN table_varchar DEFAULT NULL,
        i_prof_id             IN opinion.id_prof_questioned%TYPE,
        i_notes               IN opinion.notes%TYPE,
        i_do_commit           IN VARCHAR2,
        i_followup_auto       IN VARCHAR2,
        i_dt_problem          IN TIMESTAMP DEFAULT NULL,
        i_tbl_ds_cmpt_mkt_rel IN table_number DEFAULT NULL,
        i_tbl_val             IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob        IN table_clob DEFAULT NULL,
        o_opinion             OUT opinion.id_opinion%TYPE,
        o_opinion_hist        OUT opinion_hist.id_opinion_hist%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_consult_request
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_opinion             IN opinion.id_opinion%TYPE,
        i_opinion_type        IN opinion_type.id_opinion_type%TYPE,
        i_tbl_ds_cmpt_mkt_rel IN table_number,
        i_tbl_val             IN table_table_varchar DEFAULT NULL,
        i_tbl_val_desc        IN table_table_varchar DEFAULT NULL,
        i_tbl_val_clob        IN table_clob DEFAULT NULL,
        o_opinion             OUT opinion.id_opinion%TYPE,
        o_opinion_hist        OUT opinion_hist.id_opinion_hist%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function cancels the passed opinion
    *
    * @param      i_lang           language identifier
    * @param      i_prof           logged professional structure
    * @param      i_opinion        Id opinion
    * @param      i_opinion_type   opinion type identifier
    * @param      i_notes_cancel   cancel notes
    * @param      i_cancel_reason  Id cancel reason
    * @param      o_error          error
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.6.0.1
    * @since      13-04-2010
    ************************************************************************************************************/
    FUNCTION set_opinion_canceled
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_opinion       IN opinion.id_opinion%TYPE,
        i_opinion_type  IN opinion_type.id_opinion_type%TYPE,
        i_notes_cancel  IN opinion.notes_cancel%TYPE,
        i_cancel_reason IN opinion.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function cancels the passed opinion
    * Equal to the set_opinion_canceled, without validating if the professional that is cancelling the request
    * is the same one that created the registry.
    *
    * @param      i_lang           language identifier
    * @param      i_prof           logged professional structure
    * @param      i_opinion        Id opinion
    * @param      i_opinion_type   opinion type identifier
    * @param      i_notes_cancel   cancel notes
    * @param      i_cancel_reason  Id cancel reason
    * @param      o_error          error
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Sofia Mendes
    * @version    2.6.0.3
    * @since      12-Jul-2010
    ************************************************************************************************************/
    FUNCTION set_opinion_canc_no_val
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion.id_opinion%TYPE,
        i_opinion_type     IN opinion_type.id_opinion_type%TYPE,
        i_notes_cancel     IN opinion.notes_cancel%TYPE,
        i_cancel_reason    IN opinion.id_cancel_reason%TYPE,
        i_flg_cancel_event IN VARCHAR2 DEFAULT 'Y',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function sets the oppinion as "approved" (used by the professional responsible for the episode)
    *
    * @param      i_lang           language identifier
    * @param      i_prof           logged professional structure
    * @param      i_opinion        Id opinion
    * @param      i_notes          approve notes
    * @param      o_error          error
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.6.0.1
    * @since      13-04-2010
    ************************************************************************************************************/
    FUNCTION set_opinion_approved
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        i_notes   IN opinion_prof.desc_reply%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************
    * This function sets the oppinion as "refused" (used by the professional responsible for the episode)
    *
    * @param      i_lang           language identifier
    * @param      i_prof           logged professional structure
    * @param      i_opinion        Id opinion
    * @param      i_notes          refuse notes
    * @param      i_cancel_reason  Id refuse reason
    * @param      o_error          error
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Pedro Teixeira
    * @version    2.6.0.1
    * @since      13-04-2010
    ************************************************************************************************************/
    FUNCTION set_opinion_refused
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_opinion       IN opinion.id_opinion%TYPE,
        i_notes         IN opinion_prof.desc_reply%TYPE,
        i_cancel_reason IN opinion.id_cancel_reason%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set consult request state. For database internal use only.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion        opinion identifier
    * @param i_state          opinion state
    * @param i_set_oprof      create opinion_prof answer? Y/N
    * @param o_opinion_hist   created opinion history identifier
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/13
    */
    FUNCTION set_consult_request_state
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_state        IN opinion.flg_state%TYPE,
        i_set_oprof    IN VARCHAR2 := pk_alert_constant.g_yes,
        o_opinion_hist OUT opinion_hist.id_opinion_hist%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get applicable professionals list,
    * for consult request creation/edition.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion_type   opinion type identifier
    * @param i_clin_serv      clinical service identifier
    * @param o_prof_list      professional list
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/04/13
    */
    FUNCTION get_prof_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        o_prof_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_opinion_type  IN opinion_type.id_opinion_type%TYPE,
        i_internal_name IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_prof_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE
    ) RETURN t_tbl_core_domain;

    /*
    * Build status string for social assistance requests. Internal use only.
    * Made public to be used in SQL statements.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_status         request status
    * @param i_dt_req         request date
    *
    * @return                 request status string
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/02/24
    */
    FUNCTION get_req_status_str
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_state          IN opinion.flg_state%TYPE,
        i_dt_req         IN opinion.dt_last_update%TYPE,
        i_opinion_type   IN opinion.id_opinion_type%TYPE,
        i_prof_questions IN opinion.id_prof_questions%TYPE,
        i_episode        IN opinion.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get the Follow-up requests summary, concatenated as a String (CLOB).
    * The information includes: Diagnosis, Intervention plans, Follow-up notes and Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = Social Worker)
    * @ param i_opinion_type          Type of request
    * @ param o_follow_up_request_summary  Array with all information, where each 
    *                                      position has a diferent type of data.
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/04/21
    **********************************************************************************************/
    FUNCTION get_follow_up_req_sum_str
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_opinion_type              IN opinion_type.id_opinion_type%TYPE,
        o_follow_up_request_summary OUT table_clob,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Answers (accepts/rejects) a case management request. overload created so that we can send in our own remote transaction.
    * This function simply calls the original one.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param i_patient          patient identifier
    * @param i_flg_state        Acceptance (E - accept / X - Reject )
    * @param i_management_level management level identifier
    * @param i_notes            answer notes
    * @param i_cancel_reason    refuse reason
    * @param o_opinion          opinion identifier
    * @param o_opinion_prof     opinion prof identifier
    * @param o_episode          episode identifier
    * @param o_epis_encounter   episode encounter dentifier
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Telmo Castro
    * @version                  2.6.0.1
    * @since                    27-04-2010
    ********************************************************************************************/
    FUNCTION set_request_answer
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_opinion          IN opinion_prof.id_opinion%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_flg_state        IN opinion.flg_state%TYPE,
        i_management_level IN opinion.id_management_level%TYPE,
        i_notes            IN opinion_prof.desc_reply%TYPE,
        i_cancel_reason    IN opinion_prof.id_cancel_reason%TYPE,
        o_opinion_prof     OUT opinion_prof.id_opinion_prof%TYPE,
        o_episode          OUT episode.id_episode%TYPE,
        o_epis_encounter   OUT epis_encounter.id_epis_encounter%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Retrieves the detail of operations made in a case management request (Reports).
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_opinion          opinion identifier
    * @param o_hist             cursor (info, details)
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Elisabete Bugalho
    * @version                  2.5.0.7.4
    * @since                    23-04-2010
    ********************************************************************************************/
    FUNCTION get_cm_req_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        o_hist    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Checks if there is some activity therapy request in the state: requested or approved    
    *    
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_id_episode       episode identifier
    *
    * @returns                'Y', there is a request in state requested or approved, or 'N' otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  27-Mai-2010    
    */
    FUNCTION check_opinion_state
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get the opinion id associated to a given episode.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_episode            Episode identifier
    * @param i_id_opinion_type       Opinion type identifier
    * @param i_flg_state             List of Opinion states to be included
    * @param o_id_opinion            Opinion identifier
    * @param o_error                 error
    *
    * @return                        false, if errors occur, or true, otherwise.
    *
    * @author                        Sofia Mendes
    * @version                       2.6.0.3
    * @since                         11-Jun-2010
    **********************************************************************************************/
    FUNCTION get_opinion_id_by_state
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        i_flg_states      IN table_varchar,
        o_id_opinion      OUT opinion.id_opinion%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * checks if approval is required. If yes, sends an alert to the approvers list
    * To be used when creating a request by the Activity Therapist.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure    
    * @param i_patient        patient identifier
    * @param i_id_episode     episode identifier
    * @param i_opinion        opinion identifier
    * @param i_opinion_type   opinion type identifier
    * @param o_flg_approve    Y- approval is needed. N-otherwise
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  14-Jun-2010
    */
    FUNCTION set_request_alert
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        o_flg_approve  OUT opinion_type_prof.flg_approve%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get Activity Therapist requests list.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             list of episodes
    * @param i_id_opinion_type        Id opinion type
    * @param i_start_date             Time period begin
    * @param i_end_date               Time period end
    * @param o_requests               requests cursor   
    * @param o_error                  error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  21-Jun-2010
    */
    FUNCTION get_request_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN table_number,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        i_start_date      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_requests        OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get the request state.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_id_episode     list of episodes    
    * @param i_states         Request states to be considered
    * @param o_id_opinion     Request identifiers
    * @param o_flg_state      Request states
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  25-Jun-2010
    */
    FUNCTION get_request_states
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN opinion.id_episode%TYPE,
        i_states          IN table_varchar,
        i_id_opinion_type IN opinion.id_opinion_type%TYPE,
        --o_id_opinion OUT table_number,
        --o_flg_state  OUT table_varchar,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Gets total number of unanswered opinions
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_episode          opinion identifier
    * @param o_hist             cursor (info, details)
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @author                   Alexandre Santos
    * @version                  2.5.0.7.8
    * @since                    06-09-2010
    ********************************************************************************************/
    FUNCTION get_total_unanswered_opinions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    /**
    * Resets consults requests. Used in ALERT RESET.
    *
    * @param i_lang             language identifier
    * @param i_table_id_opinion opinion identifiers
    * @param i_id_dummy_episode reset episode identifier
    * @param l_id_dummy_patient reset patient identifier
    * @param o_error            error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.4
    * @since                2010/11/15
    */
    FUNCTION reset_consult_req
    (
        i_lang             IN language.id_language%TYPE,
        i_table_id_opinion IN table_number,
        i_id_dummy_episode IN episode.id_episode%TYPE,
        l_id_dummy_patient IN patient.id_patient%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Calculate buttons status in opinions grid
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_id_prof_questions     ID of the professional that asked for the opinion
    * @param i_id_prof_questioned    ID of the professional that was asked 
    * @param i_id_specialty          ID of the specialty that was requested
    * @param i_flg_status            Current record status
    *
    * @return               flg_cancel | flg_ok | flg_co_sign_active;
    *
    * @author               Sergio Dias
    * @version              2.6.1.
    * @since                18/03/2011
    */
    FUNCTION get_buttons_state
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof_questions   IN opinion.id_prof_questions%TYPE,
        i_id_prof_questioned  IN opinion.id_prof_questioned%TYPE,
        i_id_specialty        IN opinion.id_speciality%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_flg_status          IN opinion.flg_state%TYPE
    ) RETURN VARCHAR2;

    /**
    * Calculate professionals that can answer the question
    *
    * @param i_lang           Language ID
    * @param i_prof           Professional ID
    * @param i_id_episode     Episode ID
    * @param i_id_opinion     Opinion ID 
    * @param o_prof_list      Professional listing
    * @param o_error          Error control
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author               Sergio Dias
    * @version              2.6.1.
    * @since                18/03/2011
    */
    FUNCTION get_answer_profs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_opinion IN opinion.id_opinion%TYPE,
        o_prof_list  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Calculate buttons status in opinions grid
    *
    * @param i_lang                Language ID
    * @param i_prof                Professional ID
    * @param i_id_episode          Episode ID
    * @param i_id_opinion          Opinion ID 
    * @param i_desc                Question description 
    * @param i_flg_face_to_face    Face to face flag
    * @param i_id_prof_questioned  ID of the professional that was asked the question
    * @param i_id_order_type       Order type ID 
    * @param i_dt_opinion          Date when the opinion was answered
    * @param o_error               Error control
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author               Sergio Dias
    * @version              2.6.1.
    * @since                18/03/2011
    */
    FUNCTION create_opinion_co_sign
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_opinion         IN opinion.id_opinion%TYPE,
        i_desc               IN opinion.desc_problem%TYPE,
        i_flg_face_to_face   IN opinion_prof.flg_face_to_face%TYPE DEFAULT g_unknown,
        i_id_prof_questioned IN opinion_prof.id_prof_co_sign%TYPE,
        i_id_order_type      IN order_type.id_order_type%TYPE,
        i_dt_opinion         IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_consult_request
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_patient      IN patient.id_patient%TYPE,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        i_clin_serv    IN opinion.id_clinical_service%TYPE,
        i_reason_ft    IN opinion.desc_problem%TYPE,
        i_reason_mc    IN table_number,
        i_prof_id      IN opinion.id_prof_questioned%TYPE,
        i_notes        IN opinion.notes%TYPE,
        o_opinion      OUT opinion.id_opinion%TYPE,
        o_opinion_hist OUT opinion_hist.id_opinion_hist%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get the description of a consult to use on single pages import mechanismpo
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_opinion        opinion identifier
    * @param i_opinion_type   patient identifier
    * @param i_flg_short      Short descritpion or long descritpion (Y - short description)
    * @param i_flg_description Flag that indicates if the description condition must be followed
    * @param i_description_condition Condition for the description
    * @param i_flg_desc_for_dblock Flag that indicates if the description is for the dblock or not
    *
    * @return                 Consult description
    *
    * @author                 S�rgio Santos
    * @version                2.6.2
    * @since                  2012/08/22
    */
    FUNCTION get_sp_consult_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_opinion               IN opinion.id_opinion%TYPE,
        i_opinion_type          IN opinion_type.id_opinion_type%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        i_flg_desc_for_dblock   IN pk_types.t_flg_char,
        i_flg_short             IN VARCHAR2 DEFAULT 'N'
    ) RETURN CLOB;

    /************************************************************************************************************
    * This function returns the clinical services of the professionals that can give a consult (opinion).
    *
    * @param      i_lang            Current language
    * @param      i_prof            Professional that makes the request (profissional, institution and software id's)
    * @param      o_spec            Clinical services output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Sergio Dias
    * @version    2.6.3.9
    * @since      Dec/9/2013
    ************************************************************************************************************/
    FUNCTION get_clin_serv_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clin_serv_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_tbl_core_domain;

    FUNCTION get_clin_serv_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE
    ) RETURN t_tbl_core_domain;

    /************************************************************************************************************
    * This function returns the professionals for a clinical service that can give a consult (opinion)
    *
    * @param      i_lang            Current language
    * @param      i_prof            Professional that makes the request (profissional, institution and software id's)
    * @param      i_speciality      Speciality id for the consult
    * @param      o_prof            Professionals output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     CRS
    * @version    1.0
    * @since      2005/03/10
    ************************************************************************************************************/
    FUNCTION get_prof_clin_serv_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_clin_serv_id IN clinical_service.id_clinical_service%TYPE,
        o_prof         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_clin_serv_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_clin_serv_id IN clinical_service.id_clinical_service%TYPE,
        o_error        OUT t_error_out
    ) RETURN t_tbl_core_domain;

    /************************************************************************************************************
    * This function returns if has one or more profissional.
    *
    * @param      i_lang            Current language
    * @param      i_prof            Professional that makes the request (profissional, institution and software id's)
    * @param      o_spec            Clinical services output cursor
    * @param      o_error           Error messages cursor
    *
    * @return     True if sucess, false otherwise
    *
    * @author     Jorge Silva
    * @version    2.6.3.14
    * @since      28/03/2014
    ************************************************************************************************************/
    FUNCTION get_has_multiple_prof
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_clin_serv    IN clinical_service.id_clinical_service%TYPE,
        i_opinion_type IN opinion_type.id_opinion_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Gets the requested consultations
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    *
    * @o_consults             List of Consults 
    * @o_actions              List of possible actions   
    * @param o_error          Error message     
    *
    * @return                 true or false on success or error
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.3.8.2
    * @since                  2015/01/27
    **********************************************************************************************/
    FUNCTION get_requested_opinion
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_consults OUT pk_types.cursor_type,
        o_actions  OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates the status of several constultation requests
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_opinion        List of consultation request
    * @param i_action         List of associated actions
    *
    * @param o_error          Error message     
    *
    * @return                 true or false on success or error
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.3.8.2
    * @since                  2015/01/27
    **********************************************************************************************/

    FUNCTION set_opinion_answer
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_opinion      IN table_number,
        i_action       IN table_varchar,
        o_sys_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_opinion_delete_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_request IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets a string with all consults request and the current status
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    *
    * @return                 String with all consults
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.3.8.2
    * @since                  2015/01/28
    **********************************************************************************************/
    FUNCTION get_consultations_tooltip
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_epis_last_opinion
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_data       OUT t_rec_epis_last_opinion,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_last_opinion_popup
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_opinion_status_string
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_state       IN opinion.flg_state%TYPE,
        i_dt_problem_tstz IN opinion.dt_problem_tstz%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_opinion_viewer_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_opinion IN opinion.id_opinion%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_ordered_list_opinion
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_opinion_prof
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_opinion      IN opinion.id_opinion%TYPE,
        i_flg_type     IN opinion_prof.flg_type%TYPE,
        i_domain_state IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_epis_prof_req_opinions
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_limit_max IN NUMBER,
        i_limit_min IN NUMBER,
        o_opinion   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks the existence of a consultation for a given professional 
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    *
    * @return                 Y/N
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.3.6
    * @since                  2018/07/18
    **********************************************************************************************/

    FUNCTION check_opinion_prof
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks the existence of a follow up request for a given professional 
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    *
    * @return                 Y/N
    *
    * @author                 Elisabete Bugalho
    * @version                2.7.4.7
    * @since                  2019/01/12
    **********************************************************************************************/

    FUNCTION check_follow_up_prof
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Checks if the patient is on list of professional (My patient list) AND return the message
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_id_schedule    schedule identifier
    * @param o_flg_in_my_list flag to identify is patient is ON my list ( R (in my patient list)  or A (not IN my patient list))
    * @param o_message        message to show ON pop up
    * @return                 boolean
    *
    * @author                 Nuno Coelho
    * @version                2.7.4.7
    * @since                  2019/03/28
    **********************************************************************************************/

    FUNCTION get_follow_episode_by_me
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        o_flg_in_my_list OUT VARCHAR2,
        o_message        OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_opin_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_opinion          IN opinion.id_opinion%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN epis_info.id_episode%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_desc             IN opinion.desc_problem%TYPE,
        i_flg_face_to_face IN opinion_prof.flg_face_to_face%TYPE DEFAULT g_unknown,
        i_flag_active      IN VARCHAR2, --(Resposta ('A','R'))
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_opin_prof
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_opinion              IN opinion.id_opinion%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_flag_active          IN VARCHAR2, --(Resposta ('A','R'))
        o_opinion_prof         OUT opinion_prof.id_opinion_prof%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION inactivate_opinion
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_last_update
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_opinion IN opinion.id_opinion%TYPE
    ) RETURN NUMBER;

    FUNCTION get_opinion_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_opinion_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_opinion IN opinion.id_opinion%TYPE,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_consult_for_reply
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_order_set_consult_form
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_consult_instruction
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_opinion           IN opinion.id_opinion%TYPE,
        o_task_instructions OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_consult_title
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_opinion   IN opinion.id_opinion%TYPE,
        o_task_desc OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

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

    PROCEDURE init_params_epis_list
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

    FUNCTION get_buttons_state_ok
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof_questions   IN opinion.id_prof_questions%TYPE,
        i_id_prof_questioned  IN opinion.id_prof_questioned%TYPE,
        i_id_specialty        IN opinion.id_speciality%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_flg_status          IN opinion.flg_state%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_buttons_state_cancel
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_prof_questions   IN opinion.id_prof_questions%TYPE,
        i_id_prof_questioned  IN opinion.id_prof_questioned%TYPE,
        i_id_specialty        IN opinion.id_speciality%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_flg_status          IN opinion.flg_state%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_reason_request_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_core_domain;

    FUNCTION check_opinion_mandatory_field
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_task_request      IN opinion.id_opinion%TYPE,
        i_flg_process_tasks IN VARCHAR2,
        o_check             OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

END pk_opinion;
/
