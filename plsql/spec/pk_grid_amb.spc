/*-- Last Change Revision: $Rev: 2028705 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_grid_amb IS

    TYPE rec_status_list IS RECORD(
        label      VARCHAR2(100 CHAR),
        data       VARCHAR2(100 CHAR),
        icon       VARCHAR2(100 CHAR),
        flg_action VARCHAR2(100 CHAR));

    k_lf VARCHAR2(0010 CHAR) := chr(10);

    g_nurdaytask_sql VARCHAR2(32000) := 'select id_schedule        id_schedule,' || k_lf ||
                                        'id_patient         id_patient ,' || k_lf || 'id_episode         id_episode,' || k_lf ||
                                        'num_proc           num_proc,' || k_lf || 'name               name,' || k_lf ||
                                        'name_to_sort       name_to_sort,' || k_lf || 'pat_ndo            pat_ndo,' || k_lf ||
                                        'pat_nd_icon        pat_nd_icon,' || k_lf || 'gender             gender,' || k_lf ||
                                        'pat_age            pat_age,' || k_lf || 'photo              photo,' || k_lf ||
                                        'cons_type          cons_type,' || k_lf || 'cont_type          cont_type,' || k_lf ||
                                        'dt_last_contact    dt_last_contact,' || k_lf ||
                                        'flg_state          flg_state,' || k_lf || 'flg_sched          flg_sched,' || k_lf ||
                                        'img_state          img_state,' || k_lf || 'drug_presc         drug_presc,' || k_lf ||
                                        'interv_presc       interv_presc,' || k_lf || 'monit              monit,' || k_lf ||
                                        'nurse_act          nurse_act,' || k_lf ||
                                        'icnp_interv_presc  icnp_interv_presc,' || k_lf ||
                                        'dt_server          dt_server,' || k_lf || 'room               room,' || k_lf ||
                                        'wr_call            wr_call,' || k_lf || 'flg_nurse          flg_nurse,' || k_lf ||
                                        'flg_button_cancel  flg_button_cancel,' || k_lf ||
                                        'flg_button_detail  flg_button_detail,' || k_lf ||
                                        'flg_cancel         flg_cancel,' || k_lf ||
                                        'flg_contact_type   flg_contact_type,' || k_lf ||
                                        'icon_contact_type  icon_contact_type' || k_lf || 'from v_outpnurdaytasks';

    g_sql VARCHAR2(32000) := 'SELECT id_schedule id_schedule,' || k_lf || 'id_patient id_patient,' || k_lf ||
                             'num_clin_record num_clin_record,' || k_lf || 'id_episode id_episode,' || k_lf ||
                             'flg_ehr flg_ehr,' || k_lf || 'dt_efectiv dt_efectiv,' || k_lf || 'NAME  name,' || k_lf ||
                             'name_to_sort name_to_sort,' || k_lf || 'pat_ndo pat_ndo,' || k_lf ||
                             'pat_nd_icon  pat_nd_icon,' || k_lf || 'gender    gender,' || k_lf || 'pat_age   pat_age,' || k_lf ||
                             'photo     photo,' || k_lf || 'flg_contact  flg_contact,' || k_lf ||
                             'cons_type cons_type,' || k_lf || 'dt_target dt_target,' || k_lf ||
                             'dt_schedule_begin  dt_schedule_begin,' || k_lf || 'flg_state flg_state,' || k_lf ||
                             'flg_sched flg_sched,' || k_lf || 'img_state img_state,' || k_lf || 'img_sched img_sched,' || k_lf ||
                             'flg_temp  flg_temp,' || k_lf || 'dt_server dt_server,' || k_lf || 'desc_temp desc_temp,' || k_lf ||
                             'desc_drug_presc    desc_drug_presc,' || k_lf || 'desc_interv_presc  desc_interv_presc,' || k_lf ||
                             'desc_analysis_req  desc_analysis_req,' || k_lf || 'desc_exam_req      desc_exam_req,' || k_lf ||
                             'RANK  rank,' || k_lf || 'wr_call  wr_call,' || k_lf || 'doctor_name  doctor_name,' || k_lf ||
                             'reason  reason,' || k_lf || 'dt_begin  dt_begin,' || k_lf ||
                             'visit_reason  visit_reason,' || k_lf || 'dt dt,' || k_lf ||
                             'therapeutic_doctor therapeutic_doctor,' || k_lf || 'patient_presence  patient_presence,' || k_lf ||
                             'resp_icon resp_icon,' || k_lf || 'desc_room desc_room,' || k_lf ||
                             'designated_provider designated_provider,' || k_lf || 'flg_contact_type flg_contact_type,' || k_lf ||
                             'icon_contact_type  icon_contact_type,' || k_lf || 'presence_desc  presence_desc,' || k_lf ||
                             'name_prof name_prof,' || k_lf || 'name_nurse name_nurse,' || k_lf ||
                             'prof_team prof_team,' || k_lf || 'name_prof_tooltip  name_prof_tooltip,' || k_lf ||
                             'name_nurse_tooltip name_nurse_tooltip,' || k_lf ||
                             'prof_team_tooltip  prof_team_tooltip,' || k_lf || 'desc_ana_exam_req  desc_ana_exam_req,' || k_lf ||
                             'id_group  id_group,' || k_lf || 'flg_group_header   flg_group_header,' || k_lf ||
                             'extend_icon  extend_icon,' || k_lf || 'prof_follow_add  prof_follow_add,' || k_lf ||
                             'prof_follow_remove prof_follow_remove,' || k_lf || 'sch_event_desc  sch_event_desc,' || k_lf ||
                             'flg_type_appoint_edition  flg_type_appoint_edition,' || k_lf || 'i_lang  i_lang,' || k_lf ||
                             'id_professional  id_professional,' || k_lf || 'epis_status   epis_status,' || k_lf ||
                             'epis_id_room  epis_id_room,' || k_lf || 'id_dep_clin_serv  id_dep_clin_serv ' || k_lf ||
                             ' FROM v_outpgridpatients t' || k_lf ||
                             ' JOIN (SELECT /*+ OPT_ESTIMATE(TABLE p ROWS=1) */ p.id_patient, p.position ' || k_lf ||
                             ' FROM TABLE(pk_adt.get_patients(:l_lang, profissional(:l_prof_id,:l_institution,:l_software), :VALUE_01)) p ) ps ' || k_lf ||
                             ' ON ps.id_patient = t.id_patient' || k_lf ||
                             'WHERE t.dt BETWEEN  to_date(:l_dt_min,''yyyymmddHH24miss'') AND TO_DATE(:l_dt_max,''yyyymmddHH24miss'') ' || k_lf ||
                             'ORDER BY t.rank, t.dt, t.dt_begin';

    -- Public variable declarations EMR-437
    g_owner   VARCHAR2(0050);
    g_error   VARCHAR2(4000);
    g_package VARCHAR2(0050);

    -- schedule
    g_sched_scheduled   CONSTANT schedule_outp.flg_state%TYPE := 'A';
    g_sched_efectiv     CONSTANT schedule_outp.flg_state%TYPE := 'E';
    g_sched_med_disch   CONSTANT schedule_outp.flg_state%TYPE := 'D';
    g_sched_adm_disch   CONSTANT schedule_outp.flg_state%TYPE := 'M';
    g_sched_nurse_disch CONSTANT schedule_outp.flg_state%TYPE := 'P';
    g_sched_wait        CONSTANT schedule_outp.flg_state%TYPE := 'C';
    g_sched_nurse_prev  CONSTANT schedule_outp.flg_state%TYPE := 'W';
    g_sched_nurse       CONSTANT schedule_outp.flg_state%TYPE := 'N';
    g_sched_nurse_end   CONSTANT schedule_outp.flg_state%TYPE := 'P';
    g_sched_cons        CONSTANT schedule_outp.flg_state%TYPE := 'T';
    g_sched_nutri_disch CONSTANT schedule_outp.flg_state%TYPE := 'U';
    g_flg_state_p       CONSTANT schedule_outp.flg_state%TYPE := 'P';

    g_flg_sched_a CONSTANT schedule_outp.flg_sched%TYPE := 'A';
    g_flg_sched_w CONSTANT schedule_outp.flg_sched%TYPE := 'W';

    g_sched_canc CONSTANT schedule.flg_status%TYPE := 'C';
    g_sched_temp CONSTANT schedule.flg_status%TYPE := 'T';

    g_schdl_outp_state_domain     CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE_OUTP.FLG_STATE';
    g_schdl_outp_sched_domain     CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE_OUTP.FLG_SCHED';
    g_schdl_outp_state_act_domain CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE_OUTP.FLG_STATE_ACTION';
    g_schdl_nurse_state_domain    CONSTANT sys_domain.code_domain%TYPE := 'SCHEDULE_OUTP.FLG_NURSE_ACTION';
    g_domain_sch_presence         CONSTANT sys_domain.code_domain%TYPE := 'SCH_GROUP.FLG_CONTACT_TYPE';

    g_nurse_scheduled CONSTANT VARCHAR2(1 CHAR) := 'A';

    -- category
    g_flg_doctor CONSTANT category.flg_type%TYPE := pk_alert_constant.g_cat_type_doc;
    g_flg_nurse  CONSTANT category.flg_type%TYPE := pk_alert_constant.g_cat_type_nurse;

    -- epis
    g_epis_canc CONSTANT episode.flg_status%TYPE := pk_alert_constant.g_epis_status_cancel;

    g_flg_ehr CONSTANT episode.flg_ehr%TYPE := pk_ehr_access.g_flg_ehr_ehr;

    -- task
    g_task_analysis CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_task_exam     CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_task_harvest  CONSTANT VARCHAR2(1 CHAR) := 'H';

    -- bollean
    g_yes      CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no       CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_selected CONSTANT VARCHAR2(1 CHAR) := 'S';

    g_wr_available_y            CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_sys_config_wr             CONSTANT sys_config.id_sys_config%TYPE := 'WL_WAITING_ROOM_AVAILABLE';
    g_epis_flg_appointment_type CONSTANT sys_domain.code_domain%TYPE := 'EPISODE.FLG_APPOINTMENT_TYPE';
    g_null_appointment_type     CONSTANT episode.flg_appointment_type%TYPE := 'N';

    --
    g_sch_event_therap_decision CONSTANT sch_event.id_sch_event%TYPE := 20;

    g_team_type_care CONSTANT prof_team.flg_type%TYPE := 'C';

    g_startup_sys_shortcut CONSTANT sys_shortcut.id_sys_shortcut%TYPE := 38;
    g_day_in_seconds       CONSTANT NUMBER := 86399; -- 23:59:59 in seconds
    g_yyyymmdd             CONSTANT NUMBER := 8; -- to extract yyyymmdd from serialized date
    --
    g_analysis_exam_icon_grid_rank sys_domain.code_domain%TYPE := 'ANALYSIS_EXAM_ICON_GRID_RANK';
    g_cf_pat_gender_abbr CONSTANT sys_config.id_sys_config%TYPE := 'PATIENT.GENDER.ABBR';

    -- Author  : PEDRO.TEIXEIRA
    -- Created : 21-10-2009 09:05:16
    -- Purpose : Remove ambulatory functions from PK_GRID

    /**
    * Get room description.
    *
    * @param i_lang         language identifier
    * @param i_room         room identifier
    *
    * @return               room translation.
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.6
    * @since                2011/06/13
    */
    FUNCTION get_room_desc
    (
        i_lang IN language.id_language%TYPE,
        i_room IN room.id_room%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**********************************************************************************************
    * Doctor grids for CARE. Adapted from PK_GRID.DOCTOR_EFECTIV.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_dt                     date
    * @param i_type                   search type
    * @param i_prof_cat_type          professional category type (as given by PK_LOGIN.GET_PROF_PREF)
    * @param o_doc                    grid array
    * @param o_error                  error
    *
    * @value i_type                   {*} 'C' Schedules for clinical service {*} 'D' Schedules for professional
    *
    * @return                         false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                         Pedro Carneiro
    * @version                         1.0
    * @since                          2009/04/07
    **********************************************************************************************/
    FUNCTION doctor_efectiv_care
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_body_title    OUT VARCHAR2,
        o_body_detail   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Nurse grids for CARE. Adapted from PK_GRID.NURSE_EFECTIV.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_dt                     date
    * @param i_prof_cat_type          professional category type (as given by PK_LOGIN.GET_PROF_PREF)
    * @param o_doc                    grid array
    * @param o_error                  error
    *
    * @value i_type                   {*} 'C' Schedules for clinical service {*} 'D' Schedules for professional
    *
    * @return                         false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                         Pedro Carneiro
    * @version                         1.0
    * @since                          2009/04/07
    **********************************************************************************************/
    FUNCTION nurse_efectiv_care
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_type          IN VARCHAR2,
        o_doc           OUT pk_types.cursor_type,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_body_title    OUT VARCHAR2,
        o_body_detail   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Nurse grids for CARE. Adapted from PK_GRID.NURSE_PRESC_BETW.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param o_doc                    grid array
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                         Pedro Carneiro
    * @version                         1.0
    * @since                          2009/04/07
    **********************************************************************************************/
    FUNCTION nurse_presc_betw_care
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_doc   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Retunrs day description
    *
    * @param IN   i_lang        Language ID
    * @param IN   i_date        Date to process
    *
    * @return                   Day description
    *
    * @author                   Pedro Teixeira
    * @since                    2009/10/21
    ********************************************************************************************/
    FUNCTION get_extense_day_desc
    (
        i_lang IN language.id_language%TYPE,
        i_date IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION doctor_efectiv_pp
    (
        i_lang          IN language.id_language%TYPE,
        i_epis_type     IN schedule_outp.id_epis_type%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_body_title    OUT VARCHAR2,
        o_body_detail   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION doctor_efectiv_pp_my_rooms
    (
        i_lang          IN language.id_language%TYPE,
        i_epis_type     IN schedule_outp.id_epis_type%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_body_title    OUT VARCHAR2,
        o_body_detail   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /**********************************************************************************************
    * Determines if theres a specific shortcut for the institution, if so then return true
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param o_show_viewer            'Y': show
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                         Pedro Teixeira
    * @version                        1.0
    * @since                          2010/01/21
    **********************************************************************************************/
    FUNCTION show_adm_startup_viewer
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_show_viewer OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get social worker's appointments.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_dt             date
    * @param i_prof_cat_type  logged professional category
    * @param o_doc            cursor
    * @param o_flg_show       date browser warning related data
    * @param o_msg_title      date browser warning related data
    * @param o_body_title     date browser warning related data
    * @param o_body_detail    date browser warning related data
    * @param o_error          error
    *
    * @returns                false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/01/20
    */
    FUNCTION social_efectiv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_body_title    OUT VARCHAR2,
        o_body_detail   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get dietitian appointments.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_dt             date
    * @param i_prof_cat_type  logged professional category
    * @param o_doc            cursor
    * @param o_flg_show       date browser warning related data
    * @param o_msg_title      date browser warning related data
    * @param o_body_title     date browser warning related data
    * @param o_body_detail    date browser warning related data
    * @param o_error          error
    *
    * @returns                false, if errors occur, or true otherwise
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.0.1
    * @since                  07-04-2010
    */
    FUNCTION nutritionist_efectiv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_body_title    OUT VARCHAR2,
        o_body_detail   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Set a schedule's patient presence.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_episode      episode identifier
    * @param i_schedule     schedule identifier
    * @param i_flg_enc_type encounter type flag
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5
    * @since                2010/12/10
    */
    FUNCTION set_sched_presence
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_schedule     IN schedule.id_schedule%TYPE,
        i_flg_enc_type IN sch_group.flg_contact_type%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Get patient presence domain.
    *
    * @param i_lang         language identifier
    * @param i_patient      patient identifier
    * @param i_schedule     schedule identifier
    * @param o_data         domain data cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.0.5
    * @since                2010/12/14
    */
    FUNCTION get_sched_presence_domain
    (
        i_lang     IN language.id_language%TYPE,
        i_patient  IN patient.id_patient%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        o_data     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a nurse's appointments. A "my patients" approach for nurses.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_prof_cat     logged professional category
    * @param i_date         actual episode identifier
    * @param o_grid         grid array
    * @param o_flg_show     navigation warning available? Y/N
    * @param o_msg_title    navigation warning message title
    * @param o_body_title   navigation warning body title
    * @param o_body_detail  navigation warning body detail
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.6
    * @since                2011/06/13
    */
    FUNCTION get_nurse_appointment
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_prof_cat    IN category.flg_type%TYPE,
        i_date        IN VARCHAR2,
        o_grid        OUT pk_types.cursor_type,
        o_flg_show    OUT sys_message.desc_message%TYPE,
        o_msg_title   OUT sys_message.desc_message%TYPE,
        o_body_title  OUT sys_message.desc_message%TYPE,
        o_body_detail OUT sys_message.desc_message%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get a schedule detail. Used in the no show registration popup.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_schedule     schedule identifier
    * @param o_detail       detail cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1.2
    * @since                2011/08/31
    */
    FUNCTION get_schedule_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        o_detail   OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Get todays nurse's appointments .
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_date                   date's appointment
    * @param o_grid         grid array
    * @param o_flg_show     navigation warning available? Y/N
    * @param o_msg_title    navigation warning message title
    * @param o_body_title   navigation warning body title
    * @param o_body_detail  navigation warning body detail
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        1.0
    * @since                          2011/08/30
    **********************************************************************************************/

    FUNCTION nurse_appointment
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_date        IN VARCHAR2,
        o_grid        OUT pk_types.cursor_type,
        o_flg_show    OUT sys_message.desc_message%TYPE,
        o_msg_title   OUT sys_message.desc_message%TYPE,
        o_body_title  OUT sys_message.desc_message%TYPE,
        o_body_detail OUT sys_message.desc_message%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************** 
    * Returns a list of days with appointments
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param o_date                   days list
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                         Paulo Teixeira
    * @since                          2011/10/12
    **********************************************************************************************/
    FUNCTION nurse_appointment_dates
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_date  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************** 
    * Returns a list of days with appointments
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param I_TYPE           tipo de pesquisa: D - consultas agendadas para o médico,C - consultas agendadas para os serv. clínicos do médico
    * @param I_PROF_CAT_TYPE  Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF   
    * @param o_date           days list
    * @param o_error          error
    *
    * @return                 false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                 Paulo Teixeira
    * @since                  2011/10/12
    **********************************************************************************************/
    FUNCTION doctor_efectiv_pp_dates
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_date          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION doctor_efectiv_pp_dates_old
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_date          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************** 
    * Returns a list of days with appointments
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param I_PROF_CAT_TYPE  Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF   
    * @param o_date           days list
    * @param o_error          error
    *
    * @return                 false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                 Paulo Teixeira
    * @since                  2011/10/12
    **********************************************************************************************/
    FUNCTION doctor_efectiv_pp_mr_dates
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_date          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************** 
    * Returns grid task count
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_id_episode     episode id
    * @param i_id_visit       visit id
    * @param i_prof_cat_type  Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF   
    * @param i_sysdate_char_short date
    *
    * @return                 number
    *
    * @author                 Paulo Teixeira
    * @since                  2011/10/13
    **********************************************************************************************/
    FUNCTION get_grid_task_count
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_visit           IN episode.id_visit%TYPE,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_sysdate_char_short IN VARCHAR2
    ) RETURN NUMBER;
    /********************************************************************************************** 
    * Returns nurse_efectiv_care_dates
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param I_TYPE           'R' MY ROOMS , 'N' my speciality   
    * @param o_date           days list
    * @param o_error          error
    *
    * @return                 false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                 Paulo Teixeira
    * @since                  2011/10/12
    **********************************************************************************************/
    FUNCTION nurse_efectiv_care_dates
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_date  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************** 
    * Returns a list of days with appointments
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_prof_cat     logged professional category    
    * @param o_date                   days list
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                         Paulo Teixeira
    * @since                          2011/10/12
    **********************************************************************************************/
    FUNCTION get_nurse_appointment_dates
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        o_date     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************** 
    * Returns a list of days with appointments
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param I_TYPE           tipo de pesquisa: D - consultas agendadas para o médico,C - consultas agendadas para os serv. clínicos do médico
    * @param I_PROF_CAT_TYPE  Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF   
    * @param o_date           days list
    * @param o_error          error
    *
    * @return                 false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                 Paulo Teixeira
    * @since                  2011/10/12
    **********************************************************************************************/
    FUNCTION doctor_efectiv_care_dates
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_date          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************** 
    * Returns the configuration for grid header
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    *
    * @param o_label_resp             Label for responsability
    * @return                         the list
    *
    * @raises
    *
    * @author                         Elisabete Bugalho
    * @since                          2011/11/14
    **********************************************************************************************/
    FUNCTION get_grid_config
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_label_resp OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns a string with the responsible professionals, formatted according to the place
    * where it will be displayed (grids, tooltips).
    *
    * @param   i_lang                     Language ID
    * @param   i_prof                     Professional data
    * @param   i_prof_cat                 Professional category
    * @param   i_id_episode               Episode ID
    * @param   i_id_professional          Main responsible professional ID (specialist physician or nurse)
    * @param   i_hand_off_type            Type of hand-off (N) Normal (M) Multiple
    * @param   i_format                   Format text to show in (G) Grids (T) Tooltips
    *                        
    * @return  Formatted string
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.1.6
    * @since                          16-11-2011
    **********************************************************************************************/
    FUNCTION get_responsibles_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_prof_cat        IN category.flg_type%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_hand_off_type   IN sys_config.value%TYPE,
        i_format          IN VARCHAR2
    ) RETURN VARCHAR2;
    /********************************************************************************************** 
    * Returns a list of days with appointments
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_type           {*} 'D' Consults for this paramedical
    *                         {*} 'C' Consults for all paramedical    
    * @param o_date                   days list
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                         Paulo Teixeira
    * @since                          2011/10/12
    **********************************************************************************************/
    FUNCTION paramedical_efectiv_dates
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_date  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get_group_state_icon
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_id_group          group identifier
    *
    * @return  icon
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION get_group_state_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_group IN schedule.id_group%TYPE,
        i_rank     IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * get_pat_status_list
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_id_group          group identifier
    * @param    i_context           context D doctor grid, nurse grid
    *
    * @param o_list                 list cursor
    * @param o_error                  Error message
    *
    * @return  icon
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION get_group_status_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_group IN schedule.id_group%TYPE,
        i_context  IN VARCHAR2,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * set_group_status_list
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_data              data value from popup get_group_status_list
    * @param    i_id_group       group identifier schedule
    *
    * @param o_error                  Error message
    *
    * @return  icon
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION set_group_status_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_data             IN VARCHAR2,
        i_id_group         IN schedule.id_group%TYPE,
        i_id_cancel_reason IN schedule.id_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE,
        i_context          IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * set_pat_group_note_nc
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_id_group_note     group note identifier     
    * @param    i_id_group       group identifier schedule
    * @param    i_flg_action     action I-insert; U-update
    *
    * @param o_error                  Error message
    *
    * @return  icon
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/11
    **********************************************************************************************/
    FUNCTION set_pat_group_note_nc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_group      IN schedule.id_group%TYPE,
        i_id_group_note IN group_note.id_group_note%TYPE,
        i_flg_action    IN VARCHAR2,
        i_note          IN group_note.notes%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Send a consult_request to history
    *
    * @param      i_lang               Língua registada como preferência do profissional
    * @param      i_prof               profissional identifier
    * @param      i_group_note       group note row
    *
    * @param  o_error              mensagem de erro
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/06/21
    **********************************************************************************************/
    FUNCTION send_group_note_to_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_group_note IN group_note%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * set_group_note
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_note              data value from popup get_group_status_list
    * @param    i_id_group       group identifier schedule
    * @param    i_flg_create        flag that indicates if is a create (Y) or update (N)
    *
    * @param o_error                  Error message
    *
    * @return  icon
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    * @update  Vanessa Barsottelli
    **********************************************************************************************/

    FUNCTION set_grid_appointment
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_group    IN schedule.id_group%TYPE, -- used to change group presence can be null        
        i_field_id    IN table_varchar,
        i_field_value IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_group_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_group      IN schedule.id_group%TYPE,
        i_note          IN group_note.notes%TYPE,
        i_flg_create    IN VARCHAR2,
        o_id_group_note OUT group_note.id_group_note%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get_group_actions
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_id_group          group identifier
    *
    * @param o_list                 list cursor
    * @param o_error                  Error message
    *
    * @return  icon
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION get_group_actions
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_group IN schedule.id_group%TYPE,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get_group_state_icon
    *
    * @param    I_group_ids           TABLE_NUMBER group_ids 
    *
    * @return  TABLE_NUMBER schedule_ids
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION get_schedule_ids(i_group_ids IN table_number) RETURN table_number;
    /********************************************************************************************
    * has_permissions
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_id_schedule          schedule identifier
    * @param    i_context           D-doctor; N-Nurse; A-Administrativo
    * @param    i_data              state to check
    *
    * @return  Y/N
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION has_permissions
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_context     IN VARCHAR2,
        i_data        IN VARCHAR2
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * get_status_list
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_id_schedule          group identifier
    * @param    i_context
    *
    * @param o_status                 list cursor
    * @param o_error                  Error message
    *
    * @return  icon
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION get_status_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        i_context     IN VARCHAR2,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * get_group_notes_det
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_data         cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1
    * @since                2010/08/13
    */
    FUNCTION get_group_notes_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_data    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * get_prof_team_det
    *
    * @param i_prof         logged professional structure
    *
    * @return  TABLE_NUMBER professional_ids
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION get_prof_team_det(i_prof IN profissional) RETURN table_number;
    /********************************************************************************************
    * get_grid_task_if
    *
    * @return  NUMBER 
    *
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION get_grid_task_if
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        i_sysdate_char_short IN VARCHAR2,
        i_id_visit           IN visit.id_visit%TYPE,
        i_clin_rec_req       IN grid_task.clin_rec_req%TYPE,
        i_clin_rec_transp    IN grid_task.clin_rec_transp%TYPE,
        i_drug_presc         IN grid_task.drug_presc%TYPE,
        i_drug_req           IN grid_task.drug_req%TYPE,
        i_drug_transp        IN grid_task.drug_transp%TYPE,
        i_hemo_req           IN grid_task.hemo_req%TYPE,
        i_intervention       IN grid_task.intervention%TYPE,
        i_material_req       IN grid_task.material_req%TYPE,
        i_monitorization     IN grid_task.monitorization%TYPE,
        i_movement           IN grid_task.movement%TYPE,
        i_nurse_activity     IN grid_task.nurse_activity%TYPE,
        i_teach_req          IN grid_task.teach_req%TYPE
    ) RETURN NUMBER;
    /********************************************************************************************
    * get_group_presence_icon
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_id_group          group identifier
    *
    * @return  icon
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION get_group_presence_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_group IN schedule.id_group%TYPE,
        i_rank     IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * is_group_app
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_id_group          group identifier
    *
    * @return  icon
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION is_group_app
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_episode  IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;
    -------------------------------------------------------------------------------------------------
    PROCEDURE initialize_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    -------------------------------------------------------------------------------------------------

    /********************************************************************************************
    * wr_call
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_wr_call           return 'Y' or 'N'
    *
    * @return  date in format: YYYYMMDD
    * @author  Joel Lopes
    * @version 2.5.2
    * @since  2014/07/10
    **********************************************************************************************/
    FUNCTION wr_call
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_wr_call IN VARCHAR2,
        i_dt      IN VARCHAR2
    ) RETURN VARCHAR2;
    -------------------------------------------------------------------------------------------------

    FUNCTION get_change_grid_info
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_group             IN sch_group.id_group%TYPE,
        i_type_appoint_edition IN VARCHAR2 DEFAULT 'Y',
        o_info                 OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;
    -------------------------------------------------------------------------------------------------
    FUNCTION get_presence_status_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_group    IN schedule.id_group%TYPE DEFAULT NULL,
        i_context     IN VARCHAR2 DEFAULT 'P',
        i_id_schedule IN schedule.id_schedule%TYPE DEFAULT NULL,
        i_id_patient  IN patient.id_patient%TYPE DEFAULT NULL,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    -------------------------------------------------------------------------------------------------   
    /********************************************************************************************
    * get_group_presence_icon
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_id_group          group identifier
    *
    * @return  icon
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/

    FUNCTION get_group_presence_val
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_group IN schedule.id_group%TYPE,
        i_rank     IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2;
    -------------------------------------------------------------------------------------------------   
    FUNCTION get_wr_call
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_waiting_room_available    IN sys_config.value%TYPE,
        i_waiting_room_sys_external IN sys_config.value%TYPE,
        i_id_episode                IN episode.id_episode%TYPE,
        i_flg_state                 IN schedule_outp.flg_state%TYPE,
        i_flg_ehr                   IN episode.flg_ehr%TYPE,
        i_id_dcs_requested          IN schedule.id_dcs_requested%TYPE
    ) RETURN VARCHAR2;

    /**********************************************************************************************
    * Get Id lock .
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_tab_name               lck_main (field func_name)
    * @param id                       id lock value
    *
    * @return                         NUMBER
    *                        
    * @author                         Pedro Henriques
    * @version                        2.7.1.2
    * @since                          2017/07/20
    **********************************************************************************************/
    FUNCTION get_grid_lock
    (
        i_lang     language.id_language%TYPE,
        i_prof     profissional,
        i_tab_name VARCHAR2,
        i_id       NUMBER
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Get todays  parammedical appointments (nutrition, social and rehabilitation) .
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_date                   date's appointment
    * @param o_grid         grid array
    * @param o_flg_show     navigation warning available? Y/N
    * @param o_msg_title    navigation warning message title
    * @param o_body_title   navigation warning body title
    * @param o_body_detail  navigation warning body detail
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Elisabete Bugalho
    * @version                        2.6.5.2
    * @since                          2016/09/06
    **********************************************************************************************/
    FUNCTION paramedical_appointment
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_dt          IN VARCHAR2,
        o_grid        OUT pk_types.cursor_type,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_body_title  OUT VARCHAR2,
        o_body_detail OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************** 
    * Returns a list of days with paramedical appointments
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param o_date                   days list
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                         Elisabete Bugalho
    * @since                          2016/09/16
    **********************************************************************************************/
    FUNCTION paramedical_appointment_dates
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_date  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the status list for each paramedical appointment
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_id_schedule       id_schedule 
    * @param    i_id_patient        Patient ID
    * @param    i_id_episode        Episode ID
    * @param    i_id_epis_type      Episode Type ID
    * @param    i_flg_status        Status 
    * @param    i_flg_type          Type 
    *
    * @param o_status                 list cursor
    * @param o_error                  Error message
    *
    * @return                      false if errors occur, true otherwise
    * @author                      Elisabete Bugalho
    * @version                     2.6.5.2
    * @since                       2016/09/06
    **********************************************************************************************/

    FUNCTION get_param_status_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_flg_status   IN VARCHAR2,
        i_flg_type     IN VARCHAR2,
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*EMR-437*/
    FUNCTION get_sch_ids
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_type_appointments IN VARCHAR2
    ) RETURN table_number;

    /*EMR-437*/
    FUNCTION get_reason
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE setsql(i_sql IN VARCHAR2);
    FUNCTION getsql RETURN VARCHAR2;

    /**
    * Initialize parameters to be used in the grid query of ORIS
    *
    * @param i_context_ids  identifier used in array of context
    * @param i_context_keys Content of the array context
    * @param i_context_vals Values  of the array context
    * @param i_name         variable for bind in the query
    * @param o_vc2          returned value if varchar
    * @param o_num          returned value if number
    * @param o_id           returned value if ID
    * @param o_tstz         returned value if date
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/04/19
    */
    PROCEDURE init_params_patient_grids
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_keys IN table_varchar DEFAULT NULL,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_prof_dcs(i_prof_id IN NUMBER) RETURN table_number;

    FUNCTION get_group_ids
    (
        i_prof IN profissional,
        i_dt01 IN schedule_outp.dt_target_tstz%TYPE,
        i_dt09 IN schedule_outp.dt_target_tstz%TYPE
    ) RETURN table_number;

    FUNCTION get_group_ids_old
    (
        i_prof IN profissional,
        i_dt01 IN schedule_outp.dt_target_tstz%TYPE,
        i_dt09 IN schedule_outp.dt_target_tstz%TYPE
    ) RETURN table_number;

    FUNCTION get_schedule_by_group_ids
    (
        i_prof IN profissional,
        i_dt01 IN schedule_outp.dt_target_tstz%TYPE,
        i_dt09 IN schedule_outp.dt_target_tstz%TYPE
    ) RETURN table_number;

    /********************************************************************************************** 
    * Returns a list of days with appointments
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param I_PROF_CAT_TYPE  Tipo de categoria do profissional, tal como é retornada em PK_LOGIN.GET_PROF_PREF   
    * @param o_date           days list
    * @param o_error          error
    *
    * @return                 false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                 Carlos Ferreira
    * @since                  2018/10/18
    **********************************************************************************************/
    FUNCTION get_dates_for_amb_grid
    (
        i_mode          IN VARCHAR2,
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_date          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    
	/**
    * Get psychologist appointments.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_dt             date
    * @param i_prof_cat_type  logged professional category
    * @param o_doc            cursor
    * @param o_flg_show       date browser warning related data
    * @param o_msg_title      date browser warning related data
    * @param o_body_title     date browser warning related data
    * @param o_body_detail    date browser warning related data
    * @param o_error          error
    *
    * @returns                false, if errors occur, or true otherwise
    *
    * @author                 Elisabete Bugalho
    * @version                2.6.0.1
    * @since                  07-04-2010
    */
    FUNCTION psychologist_efectiv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_body_title    OUT VARCHAR2,
        o_body_detail   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get respiratory appointments.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_dt             date
    * @param i_prof_cat_type  logged professional category
    * @param o_doc            cursor
    * @param o_flg_show       date browser warning related data
    * @param o_msg_title      date browser warning related data
    * @param o_body_title     date browser warning related data
    * @param o_body_detail    date browser warning related data
    * @param o_error          error
    *
    * @returns                false, if errors occur, or true otherwise
    *
    * @version                2.7.5.0
    * @since                  18-02-2018
    */
    FUNCTION rt_efectiv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_body_title    OUT VARCHAR2,
        o_body_detail   OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

END pk_grid_amb;
/
