CREATE OR REPLACE PACKAGE pk_rehab IS

    TYPE t_treatment_edit IS RECORD(
        id                          NUMBER(24),
        id_rehab_area_interv        NUMBER(24),
        desc_interv                 VARCHAR2(1000 CHAR),
        id_rehab_session_type       VARCHAR2(24 CHAR),
        desc_rehab_session_type     VARCHAR2(1000 CHAR),
        id_rehab_sch_need           NUMBER(24),
        instructions_desc           VARCHAR2(1000 CHAR),
        num_sessions                NUMBER(6),
        num_sessions_desc           VARCHAR2(50 CHAR),
        frequency_num               NUMBER(6),
        frequency_time_unit         VARCHAR2(1 CHAR),
        frequency_desc              VARCHAR2(1000 CHAR),
        priority_data               VARCHAR2(1 CHAR),
        priority_desc               VARCHAR2(50 CHAR),
        dt_begin                    VARCHAR2(50 CHAR),
        dt_begin_desc               VARCHAR2(50 CHAR),
        session_notes               VARCHAR2(1000 CHAR),
        exec_session_desc           NUMBER(6),
        exec_session_data           NUMBER(6),
        exec_institution_data       NUMBER(24),
        exec_institution_desc       VARCHAR2(50 CHAR),
        notes                       VARCHAR2(1000 CHAR),
        id_intervention             NUMBER(24),
        flg_laterality              VARCHAR2(1 CHAR),
        desc_laterality             VARCHAR2(50 CHAR),
        flg_laterality_mcdt         VARCHAR2(10 CHAR),
        not_order_reason_data       NUMBER(24),
        not_order_reason_desc       VARCHAR2(1000 CHAR),
        diagnosis_notes             VARCHAR2(1000 CHAR),
        id_alert_diagnosis          table_number,
        tbl_diagnosis_desc          table_varchar,
        id_clinical_purpose         NUMBER(24),
        clinical_purpose_notes      VARCHAR2(1000 CHAR),
        tbl_id_rehab_diagnosis      table_number,
        tbl_rehab_diagnosis_desc    table_varchar,
        rehab_diagnosis_desc_concat VARCHAR2(1000 CHAR),
        id_rehab_area               NUMBER(24),
        diagnosis_desc              VARCHAR2(4000 CHAR),
        flg_status                  VARCHAR2(1 CHAR),
        status_desc                 VARCHAR2(100 CHAR),
        scheduled_sessions          VARCHAR2(4000 CHAR),
        therapist                   VARCHAR2(1000 CHAR),
        cancel_reason_desc          VARCHAR2(1000 CHAR),
        cancel_reason_notes         VARCHAR2(1000 CHAR),
        id_pat_health_plan          NUMBER(24),
        id_pat_exemption            NUMBER(24),
        id_health_plan_entity       NUMBER(24),
        num_health_plan             VARCHAR2(1000),
        registry                    VARCHAR2(1000 CHAR));

    TYPE tbl_treatment_edit IS TABLE OF t_treatment_edit;

    /*    TYPE t_rehab_question_response IS RECORD(
        id_intervention  NUMBER(24),
        id_questionnaire NUMBER(24),
        id_response      NUMBER(24),
        notes            VARCHAR2(1000 CHAR),
        rank             NUMBER(12));
    
    TYPE tbl_rehab_question_response IS TABLE OF t_rehab_question_response;*/

    FUNCTION find_inst_rehab_areas
    (
        i_id_institution IN institution.id_institution%TYPE,
        i_id_rehab_area  IN rehab_area.id_rehab_area%TYPE DEFAULT NULL
    ) RETURN t_rehab_areas
        PIPELINED;

    FUNCTION find_rehab_interv
    (
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE
    ) RETURN t_rehab_intervs
        PIPELINED;

    FUNCTION find_prof_rehab_areas
    (
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE
    ) RETURN t_prof_rehab_areas
        PIPELINED;

    -- return the icon to be used in sessions
    FUNCTION get_rsn_icon
    (
        i_lang              IN language.id_language%TYPE,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_sessions          IN rehab_sch_need.sessions%TYPE,
        i_flg_status        IN rehab_sch_need.flg_status%TYPE
    ) RETURN VARCHAR2;

    -- return the text to be used in sessions icons
    FUNCTION get_rsn_icon_label
    (
        i_lang              IN language.id_language%TYPE,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_flg_status        IN rehab_sch_need.flg_status%TYPE,
        i_sessions          IN rehab_sch_need.sessions%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_rp_icon
    (
        i_lang              IN language.id_language%TYPE,
        i_id_rehab_presc    IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_sessions          IN rehab_sch_need.sessions%TYPE,
        i_flg_status        IN rehab_presc.flg_status%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * return the text to be used in treatment icons
    *
    * %param i_lang                   id_language
    * %param i_id_rehab_presc 
    * %param i_sessions 
    *
    * @return                         icon label
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION get_rp_icon_label
    (
        i_lang           IN language.id_language%TYPE,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_sessions       IN rehab_sch_need.sessions%TYPE,
        i_flg_status     IN rehab_presc.flg_status%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the label to be shown on treatments request grid by counting the number of sessions
    * that have been concluded or are being executed.
    *
    * %param i_lang                   id_language
    * %param i_prof 
    * %param i_id_rehab_presc
    * %param i_sessions 
    * %param i_flg_status
    *
    * @return                         icon label
    **********************************************************************************************/
    FUNCTION get_rp_icon_label
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_sessions       IN rehab_sch_need.sessions%TYPE,
        i_flg_status     IN rehab_presc.flg_status%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_rp_back_color
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_flg_status     IN rehab_presc.flg_status%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_rp_icon_color
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_flg_status     IN rehab_presc.flg_status%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_origin_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_schedule       IN epis_info.id_schedule%TYPE,
        o_id_episode_origin OUT rehab_plan.id_episode_origin%TYPE,
        o_id_schedule       OUT rehab_schedule.id_schedule%TYPE,
        o_id_epis_type      OUT episode.id_epis_type%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************************/

    FUNCTION get_rehab_interv_all
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_rehab_area          IN rehab_area.id_rehab_area%TYPE,
        i_intervention_parent IN intervention.id_intervention_parent%TYPE,
        i_id_codification     IN interv_codification.id_codification%TYPE,
        o_areas               OUT pk_types.cursor_type,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_interv_list
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_rehab_area          IN rehab_area.id_rehab_area%TYPE,
        i_intervention_parent IN intervention.id_intervention_parent%TYPE,
        i_id_codification     IN interv_codification.id_codification%TYPE,
        o_areas               OUT pk_types.cursor_type,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_interv_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_keyword         IN VARCHAR2,
        i_id_codification IN interv_codification.id_codification%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_rehab_interv_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_keyword         IN VARCHAR2,
        i_id_codification IN interv_codification.id_codification%TYPE
    ) RETURN t_tbl_rehab_interv_search;

    FUNCTION get_rehab_area_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_areas          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rehab_area_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN table_number,
        i_rehab_area  IN table_table_number,
        i_test        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_result  OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_rehab_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_short_name     IN VARCHAR2,
        i_description    IN VARCHAR2,
        i_flg_status     IN VARCHAR2,
        i_id_rehab_area  IN NUMBER,
        o_id_rehab_group OUT rehab_group.id_rehab_group%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_groups
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_rehab_group
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_group IN rehab_group.id_rehab_group%TYPE,
        i_short_name     IN VARCHAR2,
        i_description    IN VARCHAR2,
        i_flg_status     IN VARCHAR2,
        i_id_rehab_area  IN NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_groups_prof
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_groups OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rehab_groups_prof
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_groups IN table_number,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_sch_existing
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode_origin IN rehab_sch_need.id_episode_origin%TYPE,
        o_sch_needs         OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_treatment_plan_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN rehab_plan.id_patient%TYPE,
        i_id_episode        IN rehab_plan.id_episode_origin%TYPE,
        i_reports           IN VARCHAR2,
        o_id_episode_origin OUT rehab_plan.id_episode_origin%TYPE,
        o_sch_need          OUT pk_types.cursor_type,
        o_treat             OUT pk_types.cursor_type,
        o_notes             OUT pk_types.cursor_type,
        o_labels            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_treatment_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN rehab_plan.id_patient%TYPE,
        i_id_episode        IN rehab_plan.id_episode_origin%TYPE,
        o_id_episode_origin OUT rehab_plan.id_episode_origin%TYPE,
        o_sch_need          OUT pk_types.cursor_type,
        o_treat             OUT pk_types.cursor_type,
        o_notes             OUT pk_types.cursor_type,
        o_labels            OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_instructions_cfg
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_label     OUT pk_types.cursor_type,
        o_frequency OUT pk_types.cursor_type,
        o_priority  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_instructions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_format            IN VARCHAR2 DEFAULT 'PFSDN'
    ) RETURN VARCHAR2;

    FUNCTION get_rehab_area_name
    (
        i_lang          IN language.id_language%TYPE,
        i_id_rehab_area IN rehab_area.id_rehab_area%TYPE
    ) RETURN pk_translation.t_desc_translation;

    FUNCTION get_desc_epis_type
    (
        i_lang         IN language.id_language%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_rehab_sch_need_resp
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_rehab_group  IN rehab_group.id_rehab_group%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_rehab_presc_list
    (
        i_lang              IN language.id_language%TYPE,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_pending_sch_needs
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode_origin  IN rehab_sch_need.id_episode_origin%TYPE,
        o_needs_instructions OUT VARCHAR2,
        o_list               OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    --Returns a list of rehab needs open (waiting for scheduling) in this MFR plan
    --to be used in the grid pag.18
    FUNCTION get_pending_sch_needs_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_rehab_presc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN rehab_plan.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_rehab_area_interv IN table_number,
        i_id_rehab_sch_need    IN table_number,
        i_id_exec_institution  IN table_number,
        i_exec_per_session     IN table_number,
        i_presc_notes          IN table_varchar,
        i_sessions             IN table_number,
        i_frequency            IN table_number,
        i_flg_frequency        IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_date_begin           IN table_varchar,
        i_session_notes        IN table_varchar,
        i_session_type         IN table_varchar,
        i_id_codification      IN table_number,
        i_flg_laterality       IN table_varchar,
        i_id_not_order_reason  IN table_number DEFAULT NULL,
        o_id_rehab_presc       OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_rehab_presc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_root_name            IN VARCHAR2,
        i_tbl_records          IN table_number,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_tbl_val_mea          IN table_table_varchar,
        i_tbl_val_clob         IN table_table_clob DEFAULT NULL,
        i_tbl_val_array        IN tt_table_varchar DEFAULT NULL,
        i_tbl_val_array_desc   IN tt_table_varchar DEFAULT NULL,
        i_codification         IN rehab_presc.id_codification%TYPE,
        i_flg_action           IN VARCHAR2,
        i_clinical_question_pk IN table_number,
        i_clinical_question    IN table_varchar,
        i_response             IN table_table_varchar,
        o_id_rehab_presc       OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Creates a new rehab treatments prescription
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_patient             patient id
    * %param i_id_episode             current episode
    * %param i_id_rehab_area_interv   list of interventions
    * %param i_id_rehab_sch_need      list of schedule needs
    * %param i_id_exec_institution    list of institution where to execute
    * %param i_exec_per_session       list of number of executions per treeatment
    * %param i_presc_notes            list of treatment notes
    * %param i_sessions               list of sessions
    * %param i_frequency              list of frequencies
    * %param i_flg_frequency          list of frequency units
    * %param i_flg_priority           list of priorities
    * %param i_date_begin             list of begin date
    * %param i_session_notes          list of session notes
    * %param i_session_type           list of session types
    * %param o_id_rehab_presc         list of rehab prescriptions created
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION create_rehab_presc_internal
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_patient              IN rehab_plan.id_patient%TYPE,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_rehab_area_interv    IN table_number,
        i_id_rehab_sch_need       IN table_number,
        i_id_exec_institution     IN table_number,
        i_exec_per_session        IN table_number,
        i_presc_notes             IN table_varchar,
        i_sessions                IN table_number,
        i_frequency               IN table_number,
        i_flg_frequency           IN table_varchar,
        i_flg_priority            IN table_varchar,
        i_date_begin              IN table_varchar,
        i_session_notes           IN table_varchar,
        i_session_type            IN table_varchar,
        i_id_codification         IN table_number,
        i_flg_laterality          IN table_varchar,
        i_id_not_order_reason     IN table_number DEFAULT NULL,
        i_id_pat_health_plan      IN table_number DEFAULT NULL,
        i_id_pat_exemption        IN table_number DEFAULT NULL,
        i_diagnosis_notes         IN table_varchar DEFAULT NULL,
        i_diagnosis               IN pk_edis_types.table_in_epis_diagnosis DEFAULT NULL,
        i_clinical_purpose        IN table_number DEFAULT NULL,
        i_clinical_purpose_notes  IN table_varchar DEFAULT NULL,
        i_clinical_question       IN table_table_number DEFAULT NULL,
        i_response                IN table_table_number DEFAULT NULL,
        i_clinical_question_notes IN table_table_varchar DEFAULT NULL,
        i_tbl_icf                 IN table_table_number DEFAULT NULL,
        o_id_rehab_presc          OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reasons_miss_session
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_reasons_cancel_treat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_reasons OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_rehab_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_cancel_reason  IN rehab_schedule.id_cancel_reason%TYPE,
        i_notes             IN rehab_schedule.notes%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION missed_rehab_schedule
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_missed_reason  IN rehab_schedule.flg_status%TYPE,
        i_notes             IN rehab_schedule.notes%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_treatment_plan_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN rehab_notes.id_episode%TYPE,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_notes      IN rehab_notes.notes%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION create_rehab_session
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN rehab_plan.id_patient%TYPE,
        i_id_rehab_presc        IN table_number,
        i_id_episode            IN rehab_session.id_episode%TYPE,
        i_id_rehab_area_interv  IN table_number,
        i_id_rehab_session_type IN table_varchar,
        i_id_exec_prof          IN rehab_session.id_professional%TYPE,
        i_dt_begin              IN VARCHAR2,
        i_dt_end                IN VARCHAR2,
        i_duration              IN NUMBER,
        i_notes                 IN VARCHAR2,
        o_id_rehab_session      OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Edits the execution data of treatment session
    *
    * @param   i_lang              Professional preferred language
    * @param   i_prof              Professional identification and its context (institution and software)
    * @param   i_id_rehab_session  List of executions to edit        
    * @param   i_id_episode        Episode ID
    * @param   i_id_exec_prof      Profissional ID who execute the session
    * @param   i_dt_begin          Begin date
    * @param   i_dt_end            End dete
    * @param   i_duration          Elapsed time
    * @param   i_notes             Notes
    *
    * @param   o_error        Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   26-Jul-10
    */
    FUNCTION set_rehab_session
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_rehab_session IN table_number,
        i_id_episode       IN rehab_session.id_episode%TYPE,
        i_id_exec_prof     IN rehab_session.id_professional%TYPE,
        i_dt_begin         IN VARCHAR2,
        i_dt_end           IN VARCHAR2,
        i_duration         IN NUMBER,
        i_notes            IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_rehab_session
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_rehab_session IN table_number,
        i_id_cancel_reason IN rehab_session.id_cancel_reason%TYPE,
        i_notes            IN rehab_session.notes_cancel%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the detail of executions in a treatment session
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_rehab_presc     Prescribed treatment ID
    * @param   o_rehab_session_rec  Cursor with record info
    * @param   o_rehab_session_val  Cursor with session's executions info
    *
    * @param   o_error              Error information
    *
    * @return  True or False on success or error
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.0.3
    * @since   27-Jul-10
    */
    FUNCTION get_rehab_session_detail
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_presc       IN rehab_session.id_rehab_presc%TYPE,
        o_rehab_session_detail OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_rehab_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_rehab_presc   IN table_number,
        i_id_cancel_reason IN rehab_presc.id_cancel_reason%TYPE,
        i_notes            IN rehab_presc.notes_cancel%TYPE DEFAULT NULL,
        i_flg_discontinue  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_auto_cancel  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_commit       IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_rehab_sch_need
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_id_cancel_reason  IN rehab_sch_need.id_cancel_reason%TYPE,
        i_notes             IN rehab_sch_need.notes_cancel%TYPE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    -- retorna todos os tratamentos de uma necessidade de agendamento
    FUNCTION get_rehab_sch_need_treats
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN rehab_sch_need.id_episode_origin%TYPE,
        i_id_schedule IN rehab_schedule.id_schedule %TYPE,
        o_session     OUT pk_types.cursor_type,
        o_treats      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dt_init
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_dt_init OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION update_rehab_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_rehab_presc      IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_sch_need   IN rehab_presc.id_rehab_sch_need%TYPE,
        i_id_exec_institution IN rehab_presc.id_exec_institution%TYPE,
        i_exec_per_session    IN rehab_presc.exec_per_session%TYPE,
        i_notes               IN rehab_presc.notes%TYPE,
        i_flg_laterality      IN rehab_presc.flg_laterality%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    -- retorna todas as execuções de uma necessidade de agendamento
    FUNCTION get_rehab_sch_need_exec
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        o_executions        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    -- retorna todas as execuções de uma lista de requisições
    FUNCTION get_rehab_presc_exec
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN table_number,
        o_executions     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    -- get list of professionals and groups allocated to the areas
    FUNCTION get_prof_group_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_rehab_area IN table_number,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -- get list of professionals allocated to the areas
    FUNCTION get_prof_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_rehab_area IN table_number,
        o_prof_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    -- get list of time units hora(s), minuto(s)
    FUNCTION get_time_units
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_units OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    -- retorna os pacientes com tratamentos para hoje
    FUNCTION get_patients_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_all_patients IN VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_patients     OUT pk_types.cursor_type,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN;

    -- aloca um profissional ou um grupo a uma necessidade de agendamento
    FUNCTION set_alloc_prof_sch_need
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_id_resp           IN NUMBER,
        i_type              IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the detail for the Rehabilitation treatments
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_rehab_presc         Rehabilitaion prescription ID
    * @param o_rehab_treatment        Treatments details
    * @param o_rehab_treatment_prof   Professional details
    * @param o_rehab_session_detail
    *
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/07/
    **********************************************************************************************/
    FUNCTION get_rehab_treatment_detail
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE,
        o_rehab_treatment      OUT pk_types.cursor_type,
        o_rehab_treatment_prof OUT pk_types.cursor_type,
        o_rehab_session_detail OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_sch_sessions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Get the detail for the Rehabilitation sessions
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_rehab_sch_need      Rehabilitaion session ID
    * @param o_rehab_treatment        Treatments details
    * @param o_rehab_treatment_prof   Professional details
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/07/
    **********************************************************************************************/
    FUNCTION get_rehab_sch_need_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_sch_need  IN rehab_sch_need.id_rehab_sch_need%TYPE,
        o_rehab_session      OUT pk_types.cursor_type,
        o_rehab_session_prof OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the list of treatments for a given session
    *
    * @param i_lang                   Preferred language ID for this professional 
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_rehab_sch_need      Rehabilitaion session ID
    *
    *
    * @return                         Array with list of treatments
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/07/
    **********************************************************************************************/
    --TODO
    FUNCTION get_session_treatments
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE
    ) RETURN table_varchar;

    --details
    FUNCTION get_treatments_edit
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_rehab_presc  IN rehab_presc.id_rehab_presc%TYPE,
        o_rehab_treatment OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --Edit
    FUNCTION set_rehab_presc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        --
        i_id_rehab_presc          IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_area_interv    IN rehab_presc.id_rehab_area_interv%TYPE,
        i_id_rehab_sch_need       IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_id_exec_institution     IN rehab_presc.id_exec_institution%TYPE,
        i_exec_per_session        IN rehab_presc.exec_per_session%TYPE,
        i_presc_notes             IN rehab_presc.notes%TYPE,
        i_sessions                IN rehab_sch_need.sessions%TYPE,
        i_frequency               IN rehab_sch_need.frequency%TYPE,
        i_flg_frequency           IN rehab_sch_need.flg_frequency%TYPE,
        i_flg_priority            IN rehab_sch_need.flg_priority%TYPE,
        i_date_begin              IN VARCHAR2,
        i_session_notes           IN rehab_sch_need.notes%TYPE,
        i_session_type            IN rehab_sch_need.id_rehab_session_type%TYPE,
        i_flg_laterality          IN rehab_presc.flg_laterality%TYPE,
        i_id_not_order_reason     IN rehab_presc.id_not_order_reason%TYPE DEFAULT NULL,
        i_flg_commit              IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_id_pat_health_plan      IN rehab_presc.id_pat_health_plan%TYPE DEFAULT NULL,
        i_id_pat_exemption        IN rehab_presc.id_pat_exemption%TYPE DEFAULT NULL,
        i_diagnosis_notes         IN rehab_presc.diagnosis_notes%TYPE DEFAULT NULL,
        i_diagnosis               IN pk_edis_types.rec_in_epis_diagnosis DEFAULT NULL,
        i_clinical_purpose        IN rehab_presc.id_clinical_purpose%TYPE DEFAULT NULL,
        i_clinical_purpose_notes  IN rehab_presc.clinical_purpose_notes%TYPE DEFAULT NULL,
        i_clinical_question       IN table_number DEFAULT NULL,
        i_response                IN table_number DEFAULT NULL,
        i_clinical_question_notes IN table_varchar DEFAULT NULL,
        i_tbl_icf                 IN table_number DEFAULT NULL,
        --
        o_id_rehab_presc OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rehab_presc_nocommit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        --
        i_id_rehab_presc       IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_area_interv IN rehab_presc.id_rehab_area_interv%TYPE,
        i_id_rehab_sch_need    IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_id_exec_institution  IN rehab_presc.id_exec_institution%TYPE,
        i_exec_per_session     IN rehab_presc.exec_per_session%TYPE,
        i_presc_notes          IN rehab_presc.notes%TYPE,
        i_sessions             IN rehab_sch_need.sessions%TYPE,
        i_frequency            IN rehab_sch_need.frequency%TYPE,
        i_flg_frequency        IN rehab_sch_need.flg_frequency%TYPE,
        i_flg_priority         IN rehab_sch_need.flg_priority%TYPE,
        i_date_begin           IN VARCHAR2,
        i_session_notes        IN rehab_sch_need.notes%TYPE,
        i_session_type         IN rehab_sch_need.id_rehab_session_type%TYPE,
        i_flg_laterality       IN rehab_presc.flg_laterality%TYPE,
        i_id_not_order_reason  IN rehab_presc.id_not_order_reason%TYPE DEFAULT NULL,
        --
        o_id_rehab_presc OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * retorna os pacientes com tratamentos para hoje
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_type                   A-appointments S-Scheduled else NonScheduled
    * %param i_status                 from state
    * %param o_status                 List of to states
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION get_grid_workflow_status
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_type   IN VARCHAR2,
        i_status IN VARCHAR2,
        o_status OUT pk_types.cursor_type,
        o_error  OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION get_grid_workflow_icon
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_type   IN VARCHAR2,
        i_status IN VARCHAR2
        
    ) RETURN VARCHAR2;

    /**************************************************************************
    * Creates rehabilitation diagnosis associated to the patient episode      *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_episode                Episode id                              *
    * @param i_patient                Patient id                              *
    * @param i_icf                    List of ID of ICF component             *
    * @param i_iq_initial_incapacity  List of ID of the qualifier for initial *
    *                                 incapacity                              *
    * @param i_iqs_initial_incapacity List of ID of qualification scale for   *
    *                                 initial incapacity                      *
    * @param i_iq_expected_result     List of ID of the qualifier for expected*
    *                                 result                                  *
    * @param i_iqs_expected_result    List of ID of qualification scale for   *
    *                                 expected result                         *
    * @param i_iq_active_incapacity   List of ID of the qualifier for active  *
    *                                 incapacity                              *
    * @param i_iqs_active_incapacity  List of ID of qualification scale for   *
    *                                 active incapacity                       *       
    *                                                                         *
    * @param o_error                  Error message                           *
    * @param o_id_rehab_diagnosis     List of generated rehab diagnosis       *
    *                                 requests                                *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/16                              *
    **************************************************************************/
    FUNCTION create_rehab_diag
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_episode                IN episode.id_episode%TYPE,
        i_patient                IN patient.id_patient%TYPE,
        i_icf                    IN table_number,
        i_iq_initial_incapacity  IN table_number,
        i_iqs_initial_incapacity IN table_number,
        i_iq_expected_result     IN table_number,
        i_iqs_expected_result    IN table_number,
        i_iq_active_incapacity   IN table_number,
        i_iqs_active_incapacity  IN table_number,
        i_notes                  IN table_varchar,
        o_id_rehab_diagnosis     OUT table_number,
        o_flg_show               OUT VARCHAR2,
        o_msg                    OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Edits rehabilitation diagnosis data associated to the patient episode   *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_id_rehab_diagnosis     list of rehab dianossis identifiers to  *
    *                                 cancel                                  *
    * @param i_episode                Episode id                              *
    * @param i_icf                    List of ID of ICF component             *
    * @param i_iq_initial_incapacity  List of ID of the qualifier for initial *
    *                                 incapacity                              *
    * @param i_iqs_initial_incapacity List of ID of qualification scale for   *
    *                                 initial incapacity                      *
    * @param i_iq_expected_result     List of ID of the qualifier for expected*
    *                                 result                                  *
    * @param i_iqs_expected_result    List of ID of qualification scale for   *
    *                                 expected result                         *
    * @param i_iq_active_incapacity   List of ID of the qualifier for active  *
    *                                 incapacity                              *
    * @param i_iqs_active_incapacity  List of ID of qualification scale for   *
    *                                 active incapacity                       *       
    *                                                                         *
    * @param o_error                  Error message                           *
    * @param o_id_rehab_diagnosis     List of generated rehab diagnosis       *
    *                                 requests                                *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/16                              *
    **************************************************************************/
    FUNCTION set_rehab_diag
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_rehab_diagnosis     IN table_number,
        i_episode                IN episode.id_episode%TYPE,
        i_icf                    IN table_number,
        i_iq_initial_incapacity  IN table_number,
        i_iqs_initial_incapacity IN table_number,
        i_iq_expected_result     IN table_number,
        i_iqs_expected_result    IN table_number,
        i_iq_active_incapacity   IN table_number,
        i_iqs_active_incapacity  IN table_number,
        i_status                 IN table_varchar,
        i_notes                  IN table_varchar,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Cancels rehabilitation diagnosis data associated to the patient episode *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_id_rehab_diagnosis     list of rehab dianossis identifiers to  *
    *                                 cancel                                  *
    * @param i_episode                Episode id                              *
    *                                                                         *
    * @param o_error                  Error message                           *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/21                              *
    **************************************************************************/
    FUNCTION cancel_rehab_diag
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_rehab_diagnosis IN table_number,
        i_episode            IN episode.id_episode%TYPE,
        i_id_cancel_reason   IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes       IN rehab_diagnosis.notes_cancel%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Cancels rehabilitation diagnosis data associated to the patient episode *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_id_rehab_diagnosis     list of rehab diagnosis identifiers to  *
    *                                 cancel                                  *
    * @param i_episode                Episode id                              *
    *                                                                         *
    * @param o_error                  Error message                           *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/21                              *
    **************************************************************************/
    FUNCTION get_rehab_diag_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        o_rehab_diag OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Returns information to put in the Rehab Diagnosis Detail screen         *
    *                                                                         *
    * @param i_lang                   language id                             *
    * @param i_prof                   professional, software and              *
    *                                 institution ids                         *
    * @param i_rehab_diagnosis        Rehab diagnosis Id                      *
    *                                                                         *
    * @param o_error                  Error message                           *
    * @param o_rehab_diag_detail      Cursor with rehab diagnosis detail info *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2010/07/22                              *
    **************************************************************************/
    FUNCTION get_rehab_diag_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_rehab_diagnosis   IN rehab_diagnosis.id_rehab_diagnosis%TYPE,
        o_rehab_diag_detail OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    --

    -- This function can be used to edit a given treatment
    FUNCTION set_rehab_workflow_change
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        --
        i_workflow_type  IN VARCHAR2,
        i_from_state     IN VARCHAR2,
        i_to_state       IN VARCHAR2,
        i_id_rehab_grid  IN NUMBER,
        i_id_rehab_presc IN rehab_sch_need.id_rehab_sch_need%TYPE,
        --create_visit
        i_id_epis_origin    IN episode.id_episode%TYPE,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        --
        i_id_cancel_reason IN rehab_schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN rehab_schedule.notes%TYPE DEFAULT NULL,
        --
        i_transaction_id IN VARCHAR2,
        o_id_episode     OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    -- This function can be used to edit a given treatment
    FUNCTION set_rehab_wf_change_nocommit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        --
        i_workflow_type  IN VARCHAR2,
        i_from_state     IN VARCHAR2,
        i_to_state       IN VARCHAR2,
        i_id_rehab_grid  IN NUMBER,
        i_id_rehab_presc IN rehab_sch_need.id_rehab_sch_need%TYPE,
        --create_visit
        i_id_epis_origin    IN episode.id_episode%TYPE,
        i_id_rehab_schedule IN rehab_schedule.id_rehab_schedule%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        --
        i_id_cancel_reason IN rehab_schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN rehab_schedule.notes%TYPE DEFAULT NULL,
        --
        i_transaction_id IN VARCHAR2,
        o_id_episode     OUT episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_icf_list
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_icf                     IN icf_qualification_rel.id_icf%TYPE,
        i_id_icf_qualification_scale IN icf_qualification_rel.id_icf_qualification_scale%TYPE,
        i_flg_level                  IN icf_qualification_rel.flg_level%TYPE,
        o_qualif                     OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_rsn_flg_status
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_rehab_schedule_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Performs a search over active patients of Physical Medicine and Rehabilitation
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional's details
    * @param i_id_crit                Table with the criteria IDs
    * @param i_crit_cond              Criteria input
    * @param i_flg_state              Flag for Active (Y) or Inactive (N) patients
    * @param o_flg_show               Is there a message to be shown?
    * @param o_msg                    Message
    * @param o_msg_title              Message title
    * @param o_button                 Button to show with message
    * @param o_pat                    Patients list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION get_patients_mfr
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_crit   IN table_number,
        i_crit_cond IN table_varchar,
        i_flg_state IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_pat       OUT pk_types.cursor_type,
        o_error     OUT t_error_out
        
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Updates rehab_presc status when resuming, suspending or discontinuing a treatment
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_rehab_presc         treatment prescription
    * %param i_to_state               to state
    * %param i_notes                  notes about status change
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION update_rehab_presc_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN table_number,
        i_to_state       IN action.to_state%TYPE,
        i_notes          IN rehab_presc.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Accepts a rehab_presc proposal of suspension, discontinuation or edition
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_rehab_presc         treatment prescription
    * %param i_notes                  notes about status change
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION accept_rehab_presc_proposal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_notes          IN rehab_presc.notes_change%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Rejects a rehab_presc proposal of suspension, discontinuation or edition
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_rehab_presc         treatment prescription
    * %param i_notes                  notes about status change
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-08-21
    **********************************************************************************************/
    FUNCTION reject_rehab_presc_proposal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_notes          IN rehab_presc.notes_change%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Cancels a rehab_presc proposal of suspension, discontinuation or edition
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_rehab_presc         treatment prescription
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Joao Martins
    * @version                        v2.6.0.5.1.5
    * @since                          2011-02-10
    **********************************************************************************************/
    FUNCTION cancel_rehab_presc_proposal
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_presc_hist_value
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_rehab_presc_hist IN rehab_presc_hist.id_rehab_presc_hist%TYPE,
        i_code                IN VARCHAR2
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns information about a given request
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_request            Request ID
    * @param o_description           Description
    * @param o_instructions          Instructions
    * @param o_flg_status            Flg_status
    *                        
    * @author                        Joao Martins
    * @version                       v2.5.1.3
    * @since                         2011/01/31
    **********************************************************************************************/
    PROCEDURE get_therapeutic_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_request   IN NUMBER,
        o_description  OUT VARCHAR2,
        o_instructions OUT VARCHAR2,
        o_flg_status   OUT VARCHAR2
    );

    /**********************************************************************************************
    * Returns a list of rehab environmentsthat the professional is or can be allocated to in a given institution
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_institution         institution
    * %param o_environment            list of rehab environments
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1
    * @since                          2011-03-02
    **********************************************************************************************/
    FUNCTION get_rehab_environment_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_environment    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Sets the list of rehab environment that the professional is allocated to, in one or more institutions
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_institution            list of institutions to alloc the professional
    * %param i_rehab_area             for each institution a list of rehab environment to alloc the professional
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1
    * @since                          2011-03-02
    **********************************************************************************************/
    FUNCTION set_rehab_environment_prof
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_institution       IN table_number,
        i_rehab_environment IN table_table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_rehab_presc_nocommit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_rehab_presc   IN rehab_presc.id_rehab_presc%TYPE,
        i_id_cancel_reason IN rehab_presc.id_cancel_reason%TYPE,
        i_notes            IN rehab_presc.notes_cancel%TYPE DEFAULT NULL,
        i_flg_discontinue  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_auto_cancel  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_cancel        IN VARCHAR2 DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates the field that describes the status of a referral prescription.
    *
    * @param   i_lang                Language ID
    * @param   i_prof                Professional's details
    * @param   i_id_rehab_presc       Prescription ID
    * @param   i_flg_referral        Referral flag
    * @param   o_error               Error object
    *
    * @return                        True on success, false otherwise
    *
    * @author                        Nuno Neves
    * @version                       2.6.1.1
    * @since                         2011/06/13
    ********************************************************************************************/
    FUNCTION update_flg_referral
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_flg_referral   IN rehab_presc.flg_referral%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates the field laterality
    *
    * @param   i_lang                Language ID
    * @param   i_prof                Professional's details
    * @param   i_id_rehab_presc       Prescription ID
    * @param   i_flg_referral        Referral flag
    * @param   o_error               Error object
    *
    * @return                        True on success, false otherwise
    *
    * @author                        Joana Barroso
    * @version                       2.6.1.10
    * @since                         2012/08/14
    ********************************************************************************************/
    FUNCTION update_flg_laterality
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_flg_laterality IN rehab_presc.flg_laterality%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Updates the field that defines in which institution the procedure will be performed.
    *
    * @param   i_lang                Language ID
    * @param   i_prof                Professional's details
    * @param   i_id_rehab_presc_in   Prescription ID
    * @param   i_id_institution      Institution ID
    * @param   o_error               Error object
    *
    * @return                        True on success, false otherwise
    *
    * @author                        Nuno Neves
    * @version                       2.6.1.1
    * @since                         2011/06/13
    ********************************************************************************************/
    FUNCTION update_exec_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_id_institution IN rehab_presc.id_exec_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the information about schedule needs and requested/ongoing treatments
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_patient             patient id
    * %param i_id_episode             current episode
    * %param o_treat                  list of treatments
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1.1
    * @since                          2011-06-14
    **********************************************************************************************/
    FUNCTION get_rehab_treatment_referral
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_id_episode IN rehab_plan.id_episode_origin%TYPE,
        o_treat      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns the information about the status of a appointment considering if the patient is a contact
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_patient             patient id
    * %param i_flg_status             appointment status
    *
    * @return                         the status
    *
    * @author                         Elisabete Bugalho
    * @version                        2.6.1.1
    * @since                          2011-12-16
    **********************************************************************************************/

    FUNCTION get_rehab_app_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_status IN rehab_epis_encounter.flg_status%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the information about all rehab treats
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_id_patient             patient id
    * %param o_treat                  list of treatments
    * %param o_error                  error message
    *
    * @return                         TRUE on success, FALSE otherwise
    *
    * @author                         Nuno Neves
    * @version                        2.6.1.1
    * @since                          2012-02-10
    **********************************************************************************************/
    FUNCTION get_rehab_all_treat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        o_treat      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_prev_status_rph_int
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_rehab_presc_hist IN rehab_presc_hist.id_rehab_presc_hist%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Returns the information for the external prescriptions popup (if more than one for the same 
    * kind of codification).
    *
    * @param i_lang                ID language
    * @param i_prof                Professional
    * @param i_episode             Episode ID
    * @param i_id_rehab_presc      Prescription ID
    * @param o_show                Show popup?
    * @param o_messages            Titles and messages
    * @param o_interv              Cursor with the procedures
    * @param o_error               Error
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Joana Barroso
    * @version                     2.6.1.10
    * @since                       2012/08/16
    **********************************************************************************************/
    FUNCTION get_external_req
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        o_show           OUT VARCHAR2,
        o_messages       OUT pk_types.cursor_type,
        o_rehab          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Returns Institutions for rehab prescriptions  
    *
    * @param i_lang                ID language
    * @param i_prof                Professional
    * @param i_intervs             Array of requested Interventions
    * @param o_inst                Cursor with institutions
    * @param o_error               Error
    *
    * @return                      True on success, false otherwise
    *                        
    * @author                      Joana Barroso
    * @version                     2.6.3.5
    * @since                       2013/05/18
    **********************************************************************************************/

    FUNCTION get_rehab_inst
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_intervs IN table_number,
        o_inst    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_inst
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_intervs IN VARCHAR2,
        i_default IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * This function gets the total of scheduled sessions for an rehabilitation session detail, 
    *   and the rank for schedule ID parameter 
    *
    * @param i_lang                          language ID
    * @param i_id_schedule                   schedule ID
    * @param i_id_rehab_sch_need             Rehabilitaion session ID
    *
    * @return                                return a varchar with the rank/total   
    *        
    * @raises                
    *
    * @author                                CRISTINA.OLIVEIRA
    * @version                               V.2.6.4
    * @since                                 2014/11/07
    ********************************************************************************************/
    FUNCTION get_count_and_rank
    (
        i_lang              IN language.id_language%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE
    ) RETURN VARCHAR2;

    FUNCTION update_rehab_presc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN rehab_plan.id_patient%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_rehab_presc      IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_sch_need   IN rehab_presc.id_rehab_sch_need%TYPE,
        i_id_exec_institution IN rehab_presc.id_exec_institution%TYPE,
        i_exec_per_session    IN rehab_presc.exec_per_session%TYPE,
        i_presc_notes         IN rehab_presc.notes%TYPE,
        i_sessions            IN rehab_sch_need.sessions%TYPE,
        i_frequency           IN rehab_sch_need.frequency%TYPE,
        i_flg_frequency       IN rehab_sch_need.flg_frequency%TYPE,
        i_flg_priority        IN rehab_sch_need.flg_priority%TYPE,
        i_date_begin          IN VARCHAR2,
        i_session_notes       IN rehab_sch_need.notes%TYPE,
        i_session_type        IN rehab_sch_need.id_rehab_session_type%TYPE,
        i_flg_laterality      IN rehab_presc.flg_laterality%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /* *******************************************************************************************
    *  Get current state of clinical indication for rehabilitation for viewer checklist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_clinical_rehab
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_grid_lock
    (
        i_lang     language.id_language%TYPE,
        i_prof     profissional,
        i_tab_name VARCHAR2,
        i_id       NUMBER
    ) RETURN NUMBER;

    FUNCTION get_lock_description
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_presc     IN NUMBER,
        i_id_lock_main IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION inactivate_rehab_tasks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cross_actions_permissions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_subject     IN action.subject%TYPE,
        i_from_state  IN table_varchar,
        i_task_type   IN task_type.id_task_type%TYPE,
        i_rehab_presc IN table_number,
        o_actions     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --request
        o_rehab_request      OUT pk_types.cursor_type,
        o_rehab_request_prof OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_requests_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_requests      OUT pk_types.cursor_type,
        o_requests_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_epis_origin_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE init_params_patient_grids
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

    FUNCTION get_grid_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_all_patients     IN VARCHAR2,
        i_flg_type_profile IN VARCHAR2 DEFAULT NULL,
        o_date             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION get_extense_day_desc
    (
        i_lang IN language.id_language%TYPE,
        i_date IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE init_params_cdc_grid
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

    -- ************************************************
    FUNCTION get_rehab_treat_plan2
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_id_episode IN table_number
        --i_reports    IN VARCHAR2
    ) RETURN t_tbl_rehab_treat;

    FUNCTION get_rehab_treat_plan_all
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN rehab_plan.id_patient%TYPE,
        i_id_episode        IN table_number,
        i_id_episode_origin IN NUMBER
    ) RETURN t_tbl_rehab_treat;

    FUNCTION get_rehab_treat_plan1
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN rehab_plan.id_patient%TYPE,
        i_id_episode        IN table_number,
        i_id_episode_origin IN NUMBER
        --i_reports    IN VARCHAR2
    ) RETURN t_tbl_rehab_treat;

    FUNCTION order_by_treat(i_flg_status IN VARCHAR2) RETURN NUMBER;

    FUNCTION set_rehab_resp
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        --i_id_view     IN VARCHAR2,
        i_id_episode  IN NUMBER,
        i_id_schedule IN NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    -----------------------------------------------
    --Globals
    -----------------------------------------------
    g_error         VARCHAR2(4000);
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);
    g_exception EXCEPTION;

    g_sysdate_char VARCHAR2(50);
    g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;

    g_flg_add    CONSTANT rehab_area_inst.flg_add_remove%TYPE := 'A';
    g_flg_remove CONSTANT rehab_area_inst.flg_add_remove%TYPE := 'R';

    -- REHAB_SESSION - Execuções
    g_rehab_session_executed  CONSTANT rehab_presc.flg_status%TYPE := 'E';
    g_rehab_session_canceled  CONSTANT rehab_presc.flg_status%TYPE := 'C';
    g_rehab_session_scheduled CONSTANT rehab_presc.flg_status%TYPE := 'S';

    -- REHAB_PRESC - Tratamentos
    g_rehab_presc_begin          CONSTANT rehab_presc.flg_status%TYPE := 'B';
    g_rehab_presc_cancel         CONSTANT rehab_presc.flg_status%TYPE := 'C';
    g_rehab_presc_susp_prop      CONSTANT rehab_presc.flg_status%TYPE := 'P';
    g_rehab_presc_disc_prop      CONSTANT rehab_presc.flg_status%TYPE := 'Q';
    g_rehab_presc_edit_prop      CONSTANT rehab_presc.flg_status%TYPE := 'E';
    g_rehab_presc_ongoing_prop   CONSTANT rehab_presc.flg_status%TYPE := 'R';
    g_rehab_presc_discontinued   CONSTANT rehab_presc.flg_status%TYPE := 'D';
    g_rehab_presc_suspend        CONSTANT rehab_presc.flg_status%TYPE := 'S';
    g_rehab_presc_finished       CONSTANT rehab_presc.flg_status%TYPE := 'F';
    g_rehab_presc_ongoing        CONSTANT rehab_presc.flg_status%TYPE := 'O';
    g_rehab_presc_referral       CONSTANT rehab_presc.flg_status%TYPE := 'X';
    g_rehab_presc_not_order_reas CONSTANT rehab_presc.flg_status%TYPE := 'N';
    -- proposta de alteração ao Plano
    g_rehab_presc_edit_plan CONSTANT rehab_presc.flg_status%TYPE := 'E';

    --REHAB_PRESC_CHANGE - Propostas de alteração aos tratamentos
    g_rehab_presc_chg_proposal CONSTANT rehab_sch_need_change.flg_status_change%TYPE := 'P';
    g_rehab_presc_chg_accepted CONSTANT rehab_sch_need_change.flg_status_change%TYPE := 'A';
    g_rehab_presc_chg_rejected CONSTANT rehab_sch_need_change.flg_status_change%TYPE := 'R';
    g_rehab_presc_chg_canceled CONSTANT rehab_sch_need_change.flg_status_change%TYPE := 'C';

    -- REHAB_SCH_NEED - Sessões
    g_rehab_sch_need_dummy     CONSTANT rehab_sch_need.flg_status%TYPE := 'D'; --when adding treatments without schedule
    g_rehab_sch_need_wait_sch  CONSTANT rehab_sch_need.flg_status%TYPE := 'W';
    g_rehab_sch_need_scheduled CONSTANT rehab_sch_need.flg_status%TYPE := 'S';
    g_rehab_sch_need_cancel    CONSTANT rehab_sch_need.flg_status%TYPE := 'C';
    g_rehab_sch_need_no_sched  CONSTANT rehab_sch_need.flg_status%TYPE := 'N';

    --g_rehab_sch_need_empty        CONSTANT rehab_sch_need.flg_status%TYPE := 'E';
    --g_rehab_sch_need_partial      CONSTANT rehab_sch_need.flg_status%TYPE := 'P';
    --g_rehab_sch_need_infinity     CONSTANT rehab_sch_need.flg_status%TYPE := 'I';
    --g_rehab_sch_need_wait_sch_inf CONSTANT rehab_sch_need.flg_status%TYPE := 'X';

    -- REHAB_SCHEDULE - Agendamentos
    g_rehab_schedule_scheduled   CONSTANT rehab_presc.flg_status%TYPE := 'A';
    g_rehab_schedule_finished    CONSTANT rehab_presc.flg_status%TYPE := 'F';
    g_rehab_schedule_cancel      CONSTANT rehab_presc.flg_status%TYPE := 'C';
    g_rehab_schedule_justified   CONSTANT rehab_schedule.flg_status%TYPE := 'J';
    g_rehab_schedule_injustified CONSTANT rehab_schedule.flg_status%TYPE := 'I';

    -- REHAB_PLAN - Plano de tratamento
    g_rehab_plan_active   CONSTANT rehab_plan.flg_status%TYPE := 'A';
    g_rehab_plan_inactive CONSTANT rehab_plan.flg_status%TYPE := 'I';

    --REHAB_SCH_NEED_CHANGE - Propostas de alteração aos agendamentos
    g_rehab_sch_need_chg_proposal CONSTANT rehab_sch_need_change.flg_status_change%TYPE := 'P';
    g_rehab_sch_need_chg_accepted CONSTANT rehab_sch_need_change.flg_status_change%TYPE := 'A';
    g_rehab_sch_need_chg_rejected CONSTANT rehab_sch_need_change.flg_status_change%TYPE := 'R';

    --
    --g_flg_status_open        CONSTANT rehab_sch_need.flg_status%TYPE := 'O';
    --g_flg_status_scheduled   CONSTANT rehab_schedule.flg_status%TYPE := 'S';
    --g_flg_status_cancel      CONSTANT rehab_schedule.flg_status%TYPE := 'C';
    --g_flg_status_finished    CONSTANT rehab_schedule.flg_status%TYPE := 'F';

    -- Domains
    g_rehab_sch_need_flg_status CONSTANT sys_domain.code_domain%TYPE := 'REHAB_SCH_NEED.FLG_STATUS';
    g_rehab_presc_flg_status    CONSTANT sys_domain.code_domain%TYPE := 'REHAB_PRESC.FLG_STATUS';
    g_rehab_schedule_flg_status CONSTANT sys_domain.code_domain%TYPE := 'REHAB_SCHEDULE.FLG_STATUS';
    g_rehab_epis_enc_flg_status CONSTANT sys_domain.code_domain%TYPE := 'REHAB_EPIS_ENCOUNTER.FLG_STATUS';

    --Icons
    g_rehab_wait_icon CONSTANT sys_domain.img_name%TYPE := 'WaitingIcon';

    --rehab_diagnosis.flg_status (E - Executing, R - Resolved, T - Confirmed, C - Cancelled)
    g_rehab_diag_flg_status_e CONSTANT VARCHAR2(1) := 'E';
    g_rehab_diag_flg_status_r CONSTANT VARCHAR2(1) := 'R';
    g_rehab_diag_flg_status_t CONSTANT VARCHAR2(1) := 'T';
    g_rehab_diag_flg_status_c CONSTANT VARCHAR2(1) := 'C';

    --Rehab_workflow
    --appointment
    g_workflow_type_a CONSTANT VARCHAR2(1 CHAR) := 'A';
    --scheduled
    g_workflow_type_s CONSTANT VARCHAR2(1 CHAR) := 'S';
    --rehab_without_schedule
    g_workflow_type_w CONSTANT VARCHAR2(1 CHAR) := 'W';
    --HHC appointment
    g_workflow_type_h CONSTANT VARCHAR2(1 CHAR) := 'H';
    --rehab_epis_encounter_status
    g_rehab_epis_enc_status_a CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_rehab_epis_enc_status_b CONSTANT VARCHAR2(1 CHAR) := 'B';
    g_rehab_epis_enc_status_c CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_rehab_epis_enc_status_e CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_rehab_epis_enc_status_f CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_rehab_epis_enc_status_o CONSTANT VARCHAR2(1 CHAR) := 'O';
    g_rehab_epis_enc_status_s CONSTANT VARCHAR2(1 CHAR) := 'S';
    --
    g_category_therapist   CONSTANT prof_cat.id_category%TYPE := 23;
    g_category_coordinator CONSTANT prof_cat.id_category%TYPE := 24;
    g_category_registrar   CONSTANT prof_cat.id_category%TYPE := 4;

    g_epis_flg_status_inactive CONSTANT episode.flg_status%TYPE := 'I';

    g_sched_adm_disch CONSTANT schedule_outp.flg_state%TYPE := 'M';
    g_sched_hhc_disch CONSTANT schedule_outp.flg_state%TYPE := 'X';

    -- (G)ROUP or (P)ROF
    g_list_type_prof_abbr  CONSTANT VARCHAR2(1) := 'H';
    g_list_type_group_abbr CONSTANT VARCHAR2(1) := 'G';

    --Mental Therapist profile
    g_mental_therapsit_prof_templ CONSTANT NUMBER := 751;
    --chemical dependency counselour profile
    g_cdc_prof_templ          CONSTANT NUMBER := 746;
    g_speech_prof_templ       CONSTANT NUMBER := 801;
    g_occupational_prof_templ CONSTANT NUMBER := 800;
    g_coordinator_prof_templ  CONSTANT NUMBER := 49;

    g_all             CONSTANT NUMBER := 0;
    g_filter_lov_all  CONSTANT NUMBER := 100;
    g_filter_lov_outp CONSTANT NUMBER := 101;
    g_filter_lov_hhc  CONSTANT NUMBER := 1050;

    PROCEDURE init_params_patient_grids2
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

    PROCEDURE init_params_rehab_search
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

    FUNCTION get_rehab_treatment_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_rehab_treatment_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id      IN rehab_presc.id_rehab_presc%TYPE,
        i_area    IN dd_area.area%TYPE,
        i_reports IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_rehab_treatment_history
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        o_detail         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_diagnosis
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_rehab_presc      IN rehab_presc.id_rehab_presc%TYPE,
        i_id_rehab_presc_hist IN rehab_presc_hist.id_rehab_presc_hist%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION get_rehab_area_interv_hash
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_area_interv IN rehab_area_interv.id_rehab_area_interv%TYPE
    ) RETURN NUMBER;

    FUNCTION manage_most_frequent_rehab
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_area_interv IN rehab_area_interv.id_rehab_area_interv%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_rehab_favorite
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_area_interv IN rehab_area_interv.id_rehab_area_interv%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_favorite
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_rehab_area_interv IN rehab_area_interv.id_rehab_area_interv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_actions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_subject        IN action.subject%TYPE,
        i_from_state     IN action.from_state%TYPE,
        i_episode_origin IN episode.id_episode%TYPE,
        o_actions        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --************************************
    FUNCTION get_rehab_prof_name
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_id_prof             IN NUMBER,
        i_id_resp_prof        IN NUMBER,
        i_id_resp_rehab_group IN NUMBER,
        i_flg_type            IN VARCHAR2,
        i_id_episode_rehab    IN NUMBER,
        i_id_episode          IN NUMBER,
        i_id_patient          IN NUMBER,
        i_id_software         IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_questionnaire_id_content
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_response      IN response.id_response%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_rehab_response
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_questionnaire IN questionnaire_response.id_questionnaire%TYPE,
        i_intervention  IN intervention.id_intervention%TYPE,
        i_flg_time      IN VARCHAR2,
        i_inst_dest     IN institution.id_institution%TYPE
    ) RETURN table_varchar;

    FUNCTION get_rehab_response
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_notes IN interv_question_response.notes%TYPE
    ) RETURN interv_question_response.notes%TYPE;

    FUNCTION tf_get_clinical_questions
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_rehab_presc IN rehab_presc.id_rehab_presc%TYPE,
        i_flg_time       IN bp_question_response.flg_time%TYPE,
        i_flg_history    IN VARCHAR DEFAULT pk_alert_constant.g_no
    ) RETURN t_tbl_clinical_question;

    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT t_clin_quest_table,
        o_ds_target   OUT t_clin_quest_target_table,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_response_parent
    (
        i_lang          language.id_language%TYPE,
        i_prof          profissional,
        i_intervention  intervention.id_intervention%TYPE,
        i_questionnaire questionnaire.id_questionnaire%TYPE
    ) RETURN NUMBER;

    FUNCTION get_rehab_presc_quest_rank
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_intervention  IN interv_questionnaire.id_intervention%TYPE,
        i_questionnaire IN questionnaire.id_questionnaire%TYPE,
        i_flg_time      IN interv_questionnaire.flg_time%TYPE
    ) RETURN NUMBER;

    FUNCTION get_patient_icf
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_core_domain;

    FUNCTION get_request_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_int_name   IN table_varchar,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_rehab_treatment_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN rehab_plan.id_patient%TYPE,
        i_id_episode IN rehab_plan.id_episode_origin%TYPE,
        i_reports    IN VARCHAR2,
        o_treat      OUT pk_types.cursor_type,
        o_sch_need   OUT pk_types.cursor_type,
        o_notes      OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_visit_type_by_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_visit_prof_by_epis
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_status_icon
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_num_sessions   IN rehab_sch_need.sessions%TYPE,
        i_flg_status     IN rehab_sch_need.flg_status%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_rsn_icon_tooltip
    (
        i_lang              IN language.id_language%TYPE,
        i_id_rehab_sch_need IN rehab_sch_need.id_rehab_sch_need%TYPE,
        i_flg_status        IN rehab_sch_need.flg_status%TYPE,
        i_sessions          IN rehab_sch_need.sessions%TYPE
    ) RETURN VARCHAR2;
END pk_rehab;
/
