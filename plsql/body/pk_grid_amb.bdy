/*-- Last Change Revision: $Rev: 2027175 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:22 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_grid_amb IS

    /*EMR-437*/
    g_discharge_active         VARCHAR2(0050);
    g_software_intern_name     VARCHAR2(0050);
    g_epis_flg_status_active   VARCHAR2(0050);
    g_epis_flg_status_inactive VARCHAR2(0050);
    g_epis_flg_status_temp     VARCHAR2(0050);
    g_epis_flg_status_canceled VARCHAR2(0050);
    g_active                   VARCHAR2(0050);
    g_prof                     profissional;
    g_lang                     language.id_language%TYPE;

    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char  VARCHAR2(30 CHAR);
    g_package_owner VARCHAR2(30 CHAR);
    g_package_name  VARCHAR2(30 CHAR);
    g_exception EXCEPTION;
    g_found BOOLEAN;

    k_get_date_mode_my       CONSTANT VARCHAR2(0050 CHAR) := 'MY';
    k_get_date_mode_all      CONSTANT VARCHAR2(0050 CHAR) := 'ALL';
    k_get_date_mode_nurs_app CONSTANT VARCHAR2(0050 CHAR) := 'NURSE_APPOINTMENT';

    g_type_my_appointments  CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_type_all_appointments CONSTANT VARCHAR2(1 CHAR) := 'C';

    --Appointment ongoing
    g_sched_state VARCHAR2(1 CHAR) := 'T';

    g_flg_contact_video VARCHAR2(1 CHAR) := 'V';

    g_domain_pat_gender_abbr CONSTANT sys_domain.code_domain%TYPE := 'PATIENT.GENDER.ABBR';

    g_epis_type_nurse epis_type.id_epis_type%TYPE;

    g_format_g VARCHAR2(1 CHAR) := 'G';
    g_format_t VARCHAR2(1 CHAR) := 'T';

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
    ) RETURN pk_translation.t_desc_translation IS
        l_ret pk_translation.t_desc_translation;
    
        CURSOR c_room IS
            SELECT coalesce(r.desc_room_abbreviation,
                            pk_translation.get_translation(i_lang, r.code_abbreviation),
                            r.desc_room,
                            pk_translation.get_translation(i_lang, r.code_room)) room_desc
              FROM room r
             WHERE r.id_room = i_room;
    BEGIN
        IF i_room IS NULL
        THEN
            l_ret := NULL;
        ELSE
            OPEN c_room;
            FETCH c_room
                INTO l_ret;
            CLOSE c_room;
        END IF;
    
        RETURN l_ret;
    END get_room_desc;

    /**
    * Get a grid's date bounds for a given day.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_dt           grid input date (current date is used when null)
    * @param o_dt_min       minimum date
    * @param o_dt_max       maximum date
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2012/02/29
    */
    PROCEDURE get_date_bounds
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_dt     IN VARCHAR2,
        o_dt_min OUT schedule_outp.dt_target_tstz%TYPE,
        o_dt_max OUT schedule_outp.dt_target_tstz%TYPE
    ) IS
    BEGIN
        o_dt_min := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                     i_timestamp => nvl(pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                      i_prof      => i_prof,
                                                                                                      i_timestamp => i_dt,
                                                                                                      i_timezone  => NULL),
                                                                        g_sysdate_tstz));
        -- the date max as to be 23:59:59 (that in seconds is 86399 seconds)                                                                        
        o_dt_max := pk_date_utils.add_to_ltstz(i_timestamp => o_dt_min,
                                               i_amount    => g_day_in_seconds,
                                               i_unit      => 'SECOND');
    
    END get_date_bounds;

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
    ) RETURN BOOLEAN IS
        l_waiting_room_sys_external sys_config.value%TYPE := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM',
                                                                                     i_prof);
        l_waiting_room_available    VARCHAR2(10);
        l_dt_min                    schedule_outp.dt_target_tstz%TYPE;
        l_dt_max                    schedule_outp.dt_target_tstz%TYPE;
        --variavel que indica de nos devemos deslocar para a area antiga quando estamos em episódios não efectivados
        l_to_old_area             VARCHAR2(1);
        l_reasongrid              VARCHAR2(1);
        l_show_med_disch          sys_config.value%TYPE;
        l_handoff_type            sys_config.value%TYPE;
        l_therap_decision_consult translation.code_translation%TYPE;
        l_group_ids               table_number := table_number();
        l_schedule_ids            table_number := table_number();
        l_sch_t640                sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
    BEGIN
        g_sysdate_tstz    := current_timestamp;
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        ---------------------------------
        g_error        := 'GET G_SYSDATE';
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error                  := 'IS WAITING ROOM AVAILABLE';
        l_waiting_room_available := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
    
        ---------------------------------
        g_error := 'CALL get_date_bounds';
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
        ---------------------------------
        g_error          := 'GET CONFIG DEFINITIONS';
        l_to_old_area    := pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof);
        l_reasongrid     := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID', i_prof);
        l_show_med_disch := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID', i_prof), g_yes);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        ---------------------------------
        SELECT pk_translation.get_translation(i_lang, se.code_sch_event_abrv)
          INTO l_therap_decision_consult
          FROM sch_event se
         WHERE se.id_sch_event = g_sch_event_therap_decision;
    
        g_error := 'OPEN o_doc - ' || i_type;
        IF i_type = g_type_my_appointments
        THEN
        
            SELECT DISTINCT s.id_group
              BULK COLLECT
              INTO l_group_ids
              FROM schedule_outp sp
              JOIN schedule s
                ON s.id_schedule = sp.id_schedule
              JOIN sch_group sg
                ON sg.id_schedule = s.id_schedule
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              JOIN epis_type et
                ON sp.id_epis_type = et.id_epis_type
              LEFT JOIN epis_info ei
                ON s.id_schedule = ei.id_schedule
               AND ei.id_patient = sg.id_patient
              LEFT JOIN episode e
                ON ei.id_episode = e.id_episode
               AND e.id_patient = ei.id_patient
               AND e.flg_ehr != g_flg_ehr
              LEFT JOIN sch_prof_outp spo
                ON spo.id_schedule_outp = sp.id_schedule_outp
             WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND sp.id_software = i_prof.software
               AND sp.id_epis_type != g_epis_type_nurse
               AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
               AND (l_show_med_disch = g_yes OR
                   (l_show_med_disch = g_no AND
                   pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
               AND s.id_instit_requested = i_prof.institution
               AND (pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                     i_prof,
                                                                                     ei.id_episode,
                                                                                     i_prof_cat_type,
                                                                                     l_handoff_type),
                                                 i_prof.id) != -1 OR
                   (ei.id_professional IS NULL AND spo.id_professional = i_prof.id))
               AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
               AND se.flg_is_group = pk_alert_constant.g_yes
               AND s.id_group IS NOT NULL;
        
            l_schedule_ids := get_schedule_ids(l_group_ids);
        
            OPEN o_doc FOR
                SELECT t.id_schedule,
                       t.id_patient,
                       t.num_clin_record,
                       t.id_episode,
                       t.flg_ehr,
                       t.dt_efectiv,
                       t.name,
                       t.name_to_sort,
                       t.pat_ndo,
                       t.pat_nd_icon,
                       t.gender,
                       t.pat_age,
                       t.photo,
                       t.cons_type,
                       t.dt_target,
                       t.flg_state,
                       t.flg_sched,
                       t.img_state,
                       t.img_sched,
                       t.dt_server,
                       wr_call(i_lang, i_prof, t.wr_call, i_dt) wr_call,
                       t.dt_begin,
                       t.visit_reason,
                       t.desc_sched,
                       t.cont_type,
                       t.resp_icon,
                       t.desc_room,
                       t.designated_provider,
                       t.doctor_name,
                       t.flg_contact_type,
                       t.icon_contact_type,
                       t.flg_contact,
                       t.therapeutic_doctor,
                       t.id_group,
                       t.flg_group_header,
                       t.extend_icon,
                       t.prof_follow_add,
                       t.prof_follow_remove
                  FROM (SELECT s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode id_episode,
                               e.flg_ehr,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       e.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)) dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) flg_state,
                               sp.flg_sched,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                           pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                             i_prof,
                                                                                             ei.id_dep_clin_serv,
                                                                                             e.flg_ehr,
                                                                                             pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                             e.flg_ehr)),
                                                           i_lang) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               g_sysdate_char dt_server,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                                  g_sched_scheduled,
                                                                  NULL,
                                                                  e.dt_begin_tstz),
                                                           i_prof.institution,
                                                           i_prof.software) dt_begin,
                               decode(l_reasongrid,
                                      g_no,
                                      NULL,
                                      pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                  i_prof,
                                                                                                                  ei.id_episode,
                                                                                                                  s.id_schedule),
                                                                       4000)) visit_reason,
                               pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                               decode(e.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(e.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  sg.id_patient,
                                                                  decode(e.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_normal,
                                                                         ei.id_episode,
                                                                         decode(l_to_old_area, g_yes, NULL, ei.id_episode))) designated_provider,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               sg.flg_contact_type,
                               pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               NULL therapeutic_doctor,
                               0 id_group,
                               pk_alert_constant.g_no flg_group_header,
                               NULL extend_icon,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               sp.dt_target_tstz,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                          JOIN epis_type et
                            ON sp.id_epis_type = et.id_epis_type
                          LEFT JOIN epis_info ei
                            ON s.id_schedule = ei.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON ei.id_episode = e.id_episode
                           AND e.id_patient = ei.id_patient
                           AND e.flg_ehr != g_flg_ehr
                          LEFT JOIN sch_prof_outp spo
                            ON spo.id_schedule_outp = sp.id_schedule_outp
                         WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                           AND sp.id_software = i_prof.software
                           AND sp.id_epis_type != g_epis_type_nurse
                           AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                           AND (l_show_med_disch = g_yes OR
                               (l_show_med_disch = g_no AND
                               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
                           AND s.id_instit_requested = i_prof.institution
                           AND (pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                 i_prof,
                                                                                                 ei.id_episode,
                                                                                                 i_prof_cat_type,
                                                                                                 l_handoff_type),
                                                             i_prof.id) != -1 OR
                               (ei.id_professional IS NULL AND spo.id_professional = i_prof.id) OR
                               (pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) =
                               pk_alert_constant.g_yes))
                           AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                           AND s.id_sch_event NOT IN (g_sch_event_therap_decision)
                           AND se.flg_is_group = pk_alert_constant.g_no
                        --group elements
                        UNION ALL
                        SELECT s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode id_episode,
                               e.flg_ehr,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       e.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)) dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      g_sched_canc,
                                      pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                               sp.flg_sched,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS', s.flg_status, i_lang),
                                      pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                                  pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                    i_prof,
                                                                                                    ei.id_dep_clin_serv,
                                                                                                    e.flg_ehr,
                                                                                                    pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                    e.flg_ehr)),
                                                                  i_lang)) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               g_sysdate_char dt_server,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               
                               pk_date_utils.date_send_tsz(i_lang,
                                                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                                  g_sched_scheduled,
                                                                  NULL,
                                                                  e.dt_begin_tstz),
                                                           i_prof.institution,
                                                           i_prof.software) dt_begin,
                               decode(l_reasongrid,
                                      g_no,
                                      NULL,
                                      pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                  i_prof,
                                                                                                                  ei.id_episode,
                                                                                                                  s.id_schedule),
                                                                       4000)) visit_reason,
                               pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                               decode(e.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(e.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               NULL desc_room, --decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  sg.id_patient,
                                                                  decode(e.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_normal,
                                                                         ei.id_episode,
                                                                         decode(l_to_old_area, g_yes, NULL, ei.id_episode))) designated_provider,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               sg.flg_contact_type,
                               pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               NULL therapeutic_doctor,
                               s.id_group,
                               pk_alert_constant.g_no flg_group_header,
                               'ExtendIcon' extend_icon,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               sp.dt_target_tstz,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_alert_constant.g_no prof_follow_remove
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN epis_type et
                            ON sp.id_epis_type = et.id_epis_type
                          LEFT JOIN epis_info ei
                            ON s.id_schedule = ei.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON ei.id_episode = e.id_episode
                           AND e.id_patient = ei.id_patient
                          LEFT JOIN sch_prof_outp spo
                            ON spo.id_schedule_outp = sp.id_schedule_outp
                         WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                               d.column_value
                                                FROM TABLE(l_group_ids) d)
                        --header elements
                        UNION ALL
                        SELECT NULL id_schedule, --s.id_schedule,
                               NULL id_patient, --sg.id_patient,
                               NULL num_clin_record, --(SELECT cr.num_clin_record FROM clin_record cr WHERE cr.id_patient = sg.id_patient AND cr.id_institution = i_prof.institution AND rownum < 2) num_clin_record,
                               NULL id_episode, --decode(e.flg_ehr,pk_ehr_access.g_flg_ehr_normal,ei.id_episode,decode(l_to_old_area, g_yes, NULL, ei.id_episode)) id_episode,
                               e.flg_ehr,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       e.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)) dt_efectiv,
                               l_sch_t640 name, -- pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               l_sch_t640 name_to_sort, -- pk_patient.get_pat_name_to_sort(i_lang,i_prof,sg.id_patient,ei.id_episode,s.id_schedule) name_to_sort,
                               NULL pat_ndo, --  pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               NULL pat_nd_icon, --  pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               NULL gender, --  (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender FROM patient pat WHERE sg.id_patient = pat.id_patient) gender,
                               NULL pat_age, --   pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               NULL photo, --  pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               'A' flg_state,
                               sp.flg_sched,
                               get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               g_sysdate_char dt_server,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                                  g_sched_scheduled,
                                                                  NULL,
                                                                  e.dt_begin_tstz),
                                                           i_prof.institution,
                                                           i_prof.software) dt_begin,
                               decode(l_reasongrid,
                                      g_no,
                                      NULL,
                                      pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                  i_prof,
                                                                                                                  ei.id_episode,
                                                                                                                  s.id_schedule),
                                                                       4000)) visit_reason,
                               pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                               decode(e.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(e.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  sg.id_patient,
                                                                  decode(e.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_normal,
                                                                         ei.id_episode,
                                                                         decode(l_to_old_area, g_yes, NULL, ei.id_episode))) designated_provider,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               NULL flg_contact_type, --sg.flg_contact_type,
                               get_group_presence_icon(i_lang, i_prof, s.id_group, pk_alert_constant.g_no) icon_contact_type,
                               NULL flg_contact, --pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               NULL therapeutic_doctor,
                               s.id_group,
                               pk_alert_constant.g_yes flg_group_header,
                               NULL extend_icon,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               sp.dt_target_tstz,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_alert_constant.g_no prof_follow_remove
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN epis_type et
                            ON sp.id_epis_type = et.id_epis_type
                          LEFT JOIN epis_info ei
                            ON s.id_schedule = ei.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON ei.id_episode = e.id_episode
                           AND e.id_patient = ei.id_patient
                          LEFT JOIN sch_prof_outp spo
                            ON spo.id_schedule_outp = sp.id_schedule_outp
                         WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                                  d.column_value
                                                   FROM TABLE(l_schedule_ids) d)
                        --
                        UNION ALL
                        SELECT s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode id_episode,
                               e.flg_ehr,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       e.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)) dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                  FROM dep_clin_serv dcs, clinical_service cs
                                 WHERE dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                                   AND cs.id_clinical_service = dcs.id_clinical_service) cons_type,
                               
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) flg_state,
                               sp.flg_sched,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                           pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                             i_prof,
                                                                                             ei.id_dep_clin_serv,
                                                                                             e.flg_ehr,
                                                                                             pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                             e.flg_ehr)),
                                                           i_lang) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               g_sysdate_char dt_server,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                                  g_sched_scheduled,
                                                                  NULL,
                                                                  e.dt_begin_tstz),
                                                           i_prof.institution,
                                                           i_prof.software) dt_begin,
                               l_therap_decision_consult visit_reason,
                               pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                               decode(e.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(e.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  sg.id_patient,
                                                                  decode(e.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_normal,
                                                                         ei.id_episode,
                                                                         decode(l_to_old_area, g_yes, NULL, ei.id_episode))) designated_provider,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               sg.flg_contact_type,
                               pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               '(' ||
                               pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) || ')' therapeutic_doctor,
                               0 id_group,
                               pk_alert_constant.g_no flg_group_header,
                               NULL extend_icon,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               sp.dt_target_tstz,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove
                        
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN epis_type et
                            ON sp.id_epis_type = et.id_epis_type
                          LEFT JOIN epis_info ei
                            ON s.id_schedule = ei.id_schedule
                        --AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON ei.id_episode = e.id_episode
                           AND e.id_patient = ei.id_patient
                           AND e.flg_ehr != g_flg_ehr
                          LEFT JOIN sch_resource sr
                            ON sr.id_schedule = s.id_schedule
                         WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                           AND sp.id_software = i_prof.software
                           AND sp.id_epis_type != g_epis_type_nurse
                           AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                           AND (l_show_med_disch = g_yes OR
                               (l_show_med_disch = g_no AND
                               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
                           AND s.id_instit_requested = i_prof.institution
                           AND sr.id_professional = i_prof.id
                           AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                           AND s.id_sch_event = g_sch_event_therap_decision) t
                 ORDER BY t.order_state, t.dt_target_tstz, t.dt_begin;
        
        ELSIF i_type = g_type_all_appointments
        THEN
        
            SELECT DISTINCT s.id_group
              BULK COLLECT
              INTO l_group_ids
              FROM schedule_outp sp
              JOIN schedule s
                ON s.id_schedule = sp.id_schedule
              JOIN sch_group sg
                ON sg.id_schedule = s.id_schedule
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              JOIN epis_type et
                ON sp.id_epis_type = et.id_epis_type
              LEFT JOIN epis_info ei
                ON s.id_schedule = ei.id_schedule
               AND ei.id_patient = sg.id_patient
              LEFT JOIN episode e
                ON ei.id_episode = e.id_episode
               AND e.id_patient = ei.id_patient
               AND e.flg_ehr != g_flg_ehr
             WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND sp.id_software = i_prof.software
               AND sp.id_epis_type != g_epis_type_nurse
               AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
               AND (l_show_med_disch = g_yes OR
                   (l_show_med_disch = g_no AND
                   pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
               AND s.id_instit_requested = i_prof.institution
               AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
               AND EXISTS (SELECT 0
                      FROM prof_dep_clin_serv pdcs
                     WHERE pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                       AND pdcs.id_dep_clin_serv = ei.id_dep_clin_serv)
               AND se.flg_is_group = pk_alert_constant.g_yes
               AND s.id_group IS NOT NULL;
        
            l_schedule_ids := get_schedule_ids(l_group_ids);
        
            OPEN o_doc FOR
                SELECT t.id_schedule,
                       t.id_patient,
                       t.num_clin_record,
                       t.id_episode,
                       t.dt_efectiv,
                       t.name,
                       t.name_to_sort,
                       t.pat_ndo,
                       t.pat_nd_icon,
                       t.gender,
                       t.pat_age,
                       t.photo,
                       t.cons_type,
                       t.dt_target,
                       t.flg_state,
                       t.flg_sched,
                       t.img_state,
                       t.img_sched,
                       t.dt_server,
                       wr_call(i_lang, i_prof, t.wr_call, i_dt) wr_call,
                       t.dt_begin,
                       t.visit_reason,
                       t.desc_sched,
                       t.cont_type,
                       t.resp_icon,
                       t.desc_room,
                       t.designated_provider,
                       t.doctor_name,
                       t.flg_contact_type,
                       t.icon_contact_type,
                       t.flg_contact,
                       t.id_group,
                       t.flg_group_header,
                       t.extend_icon,
                       t.prof_follow_add,
                       t.prof_follow_remove
                  FROM (SELECT s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       e.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)) dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang)
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               pk_grid.get_pre_nurse_appointment(i_lang,
                                                                 i_prof,
                                                                 ei.id_dep_clin_serv,
                                                                 e.flg_ehr,
                                                                 pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                               sp.flg_sched,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                           pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                             i_prof,
                                                                                             ei.id_dep_clin_serv,
                                                                                             e.flg_ehr,
                                                                                             pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                             e.flg_ehr)),
                                                           i_lang) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               g_sysdate_char dt_server,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_begin,
                               decode(l_reasongrid,
                                      g_no,
                                      NULL,
                                      pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                  i_prof,
                                                                                                                  ei.id_episode,
                                                                                                                  s.id_schedule),
                                                                       4000)) visit_reason,
                               pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                               decode(e.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(e.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, ei.id_episode) designated_provider,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               sg.flg_contact_type,
                               pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               0 id_group,
                               pk_alert_constant.g_no flg_group_header,
                               NULL extend_icon,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               sp.dt_target_tstz,
                               decode(pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule),
                                      pk_alert_constant.g_no,
                                      decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                              i_prof,
                                                                                                              ei.id_episode,
                                                                                                              i_prof_cat_type,
                                                                                                              l_handoff_type,
                                                                                                              pk_alert_constant.g_yes),
                                                                          i_prof.id),
                                             -1,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no),
                                      pk_alert_constant.g_no) prof_follow_add,
                               pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                          JOIN epis_type et
                            ON sp.id_epis_type = et.id_epis_type
                          LEFT JOIN epis_info ei
                            ON s.id_schedule = ei.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON ei.id_episode = e.id_episode
                           AND e.id_patient = ei.id_patient
                           AND e.flg_ehr != g_flg_ehr
                         WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                           AND sp.id_software = i_prof.software
                           AND sp.id_epis_type != g_epis_type_nurse
                           AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                           AND (l_show_med_disch = g_yes OR
                               (l_show_med_disch = g_no AND
                               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
                           AND s.id_instit_requested = i_prof.institution
                           AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                           AND EXISTS (SELECT 0
                                  FROM prof_dep_clin_serv pdcs
                                 WHERE pdcs.id_professional = i_prof.id
                                   AND pdcs.flg_status = g_selected
                                   AND pdcs.id_dep_clin_serv = ei.id_dep_clin_serv)
                           AND se.flg_is_group = pk_alert_constant.g_no
                        UNION ALL
                        --GROUP ELEMENTS
                        SELECT s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       e.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)) dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang)
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      g_sched_canc,
                                      pk_grid.get_pre_nurse_appointment(i_lang,
                                                                        i_prof,
                                                                        ei.id_dep_clin_serv,
                                                                        e.flg_ehr,
                                                                        pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                        e.flg_ehr))) flg_state,
                               sp.flg_sched,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS', s.flg_status, i_lang),
                                      pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                                  pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                    i_prof,
                                                                                                    ei.id_dep_clin_serv,
                                                                                                    e.flg_ehr,
                                                                                                    pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                    e.flg_ehr)),
                                                                  i_lang)) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               g_sysdate_char dt_server,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_begin,
                               decode(l_reasongrid,
                                      g_no,
                                      NULL,
                                      pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                  i_prof,
                                                                                                                  ei.id_episode,
                                                                                                                  s.id_schedule),
                                                                       4000)) visit_reason,
                               pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                               decode(e.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(e.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               NULL desc_room, --decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, ei.id_episode) designated_provider,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               sg.flg_contact_type,
                               pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               s.id_group,
                               pk_alert_constant.g_no flg_group_header,
                               'ExtendIcon' extend_icon,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               sp.dt_target_tstz,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_alert_constant.g_no prof_follow_remove
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN epis_type et
                            ON sp.id_epis_type = et.id_epis_type
                          LEFT JOIN epis_info ei
                            ON s.id_schedule = ei.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON ei.id_episode = e.id_episode
                           AND e.id_patient = ei.id_patient
                         WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                               d.column_value
                                                FROM TABLE(l_group_ids) d)
                        --GROUP HEADER 
                        UNION ALL
                        SELECT NULL id_schedule, --s.id_schedule,
                               NULL id_patient, --sg.id_patient,
                               NULL num_clin_record, --(SELECT cr.num_clin_record FROM clin_record cr WHERE cr.id_patient = sg.id_patient AND cr.id_institution = i_prof.institution AND rownum < 2) num_clin_record,
                               NULL id_episode, --ei.id_episode,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       e.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)) dt_efectiv,
                               l_sch_t640 name, --  pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               l_sch_t640 name_to_sort, --pk_patient.get_pat_name_to_sort(i_lang,i_prof,sg.id_patient,ei.id_episode,s.id_schedule) name_to_sort,
                               NULL pat_ndo, --pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               NULL pat_nd_icon, --pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               NULL gender, --(SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) FROM patient pat WHERE sg.id_patient = pat.id_patient) gender,
                               NULL pat_age, --pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               NULL photo, --pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               'A' flg_state,
                               sp.flg_sched,
                               get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               g_sysdate_char dt_server,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_begin,
                               decode(l_reasongrid,
                                      g_no,
                                      NULL,
                                      pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                  i_prof,
                                                                                                                  ei.id_episode,
                                                                                                                  s.id_schedule),
                                                                       4000)) visit_reason,
                               pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                               decode(e.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(e.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, ei.id_episode) designated_provider,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               NULL flg_contact_type, --sg.flg_contact_type,
                               get_group_presence_icon(i_lang, i_prof, s.id_group, pk_alert_constant.g_no) icon_contact_type,
                               NULL flg_contact, --pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               s.id_group,
                               pk_alert_constant.g_yes flg_group_header,
                               NULL extend_icon,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               sp.dt_target_tstz,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_alert_constant.g_no prof_follow_remove
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN epis_type et
                            ON sp.id_epis_type = et.id_epis_type
                          LEFT JOIN epis_info ei
                            ON s.id_schedule = ei.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON ei.id_episode = e.id_episode
                           AND e.id_patient = ei.id_patient
                         WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                                  d.column_value
                                                   FROM TABLE(l_schedule_ids) d)
                        --
                        ) t
                 ORDER BY t.order_state, t.dt_target_tstz, t.dt_begin;
        
        ELSIF i_type = 'R'
        THEN
            SELECT DISTINCT s.id_group
              BULK COLLECT
              INTO l_group_ids
              FROM schedule_outp sp
              JOIN schedule s
                ON s.id_schedule = sp.id_schedule
              JOIN sch_group sg
                ON sg.id_schedule = s.id_schedule
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              JOIN epis_type et
                ON sp.id_epis_type = et.id_epis_type
              LEFT JOIN epis_info ei
                ON s.id_schedule = ei.id_schedule
               AND ei.id_patient = sg.id_patient
              LEFT JOIN episode e
                ON ei.id_episode = e.id_episode
               AND e.id_patient = ei.id_patient
               AND e.flg_ehr != g_flg_ehr
              LEFT JOIN sch_prof_outp spo
                ON spo.id_schedule_outp = sp.id_schedule_outp
             WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND sp.id_software = i_prof.software
               AND sp.id_epis_type != g_epis_type_nurse
               AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
               AND (l_show_med_disch = g_yes OR
                   (l_show_med_disch = g_no AND
                   pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
               AND s.id_instit_requested = i_prof.institution
               AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
               AND EXISTS (SELECT 0
                      FROM prof_room pr
                     WHERE pr.id_professional = i_prof.id
                       AND ei.id_room = pr.id_room)
               AND se.flg_is_group = pk_alert_constant.g_yes
               AND s.id_group IS NOT NULL;
        
            l_schedule_ids := get_schedule_ids(l_group_ids);
        
            OPEN o_doc FOR
                SELECT t.id_schedule,
                       t.id_patient,
                       t.num_clin_record,
                       t.id_episode,
                       t.flg_ehr,
                       t.dt_efectiv,
                       t.name,
                       t.name_to_sort,
                       t.pat_ndo,
                       t.pat_nd_icon,
                       t.gender,
                       t.pat_age,
                       t.photo,
                       t.cons_type,
                       t.dt_target,
                       t.flg_state,
                       t.flg_sched,
                       t.img_state,
                       t.img_sched,
                       t.dt_server,
                       wr_call(i_lang, i_prof, t.wr_call, i_dt) wr_call,
                       t.dt_begin,
                       t.visit_reason,
                       t.desc_sched,
                       t.cont_type,
                       t.resp_icon,
                       t.desc_room,
                       t.designated_provider,
                       t.doctor_name,
                       t.flg_contact_type,
                       t.icon_contact_type,
                       t.flg_contact,
                       t.id_group,
                       t.flg_group_header,
                       t.extend_icon,
                       t.prof_follow_add,
                       t.prof_follow_remove
                  FROM (SELECT s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode id_episode,
                               e.flg_ehr,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       e.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)) dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) flg_state,
                               sp.flg_sched,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                           pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                             i_prof,
                                                                                             ei.id_dep_clin_serv,
                                                                                             e.flg_ehr,
                                                                                             pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                             e.flg_ehr)),
                                                           i_lang) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               g_sysdate_char dt_server,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                                  g_sched_scheduled,
                                                                  NULL,
                                                                  e.dt_begin_tstz),
                                                           i_prof.institution,
                                                           i_prof.software) dt_begin,
                               decode(l_reasongrid,
                                      g_no,
                                      NULL,
                                      pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                  i_prof,
                                                                                                                  ei.id_episode,
                                                                                                                  s.id_schedule),
                                                                       4000)) visit_reason,
                               pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                               decode(e.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(e.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  sg.id_patient,
                                                                  decode(e.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_normal,
                                                                         ei.id_episode,
                                                                         decode(l_to_old_area, g_yes, NULL, ei.id_episode))) designated_provider,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               sg.flg_contact_type,
                               pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               0 id_group,
                               pk_alert_constant.g_no flg_group_header,
                               NULL extend_icon,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               sp.dt_target_tstz,
                               decode(pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule),
                                      pk_alert_constant.g_no,
                                      decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                              i_prof,
                                                                                                              ei.id_episode,
                                                                                                              i_prof_cat_type,
                                                                                                              l_handoff_type,
                                                                                                              pk_alert_constant.g_yes),
                                                                          i_prof.id),
                                             -1,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no),
                                      pk_alert_constant.g_no) prof_follow_add,
                               pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                          JOIN epis_type et
                            ON sp.id_epis_type = et.id_epis_type
                          LEFT JOIN epis_info ei
                            ON s.id_schedule = ei.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON ei.id_episode = e.id_episode
                           AND e.id_patient = ei.id_patient
                           AND e.flg_ehr != g_flg_ehr
                          LEFT JOIN sch_prof_outp spo
                            ON spo.id_schedule_outp = sp.id_schedule_outp
                         WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                           AND sp.id_software = i_prof.software
                           AND sp.id_epis_type != g_epis_type_nurse
                           AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                           AND (l_show_med_disch = g_yes OR
                               (l_show_med_disch = g_no AND
                               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
                           AND s.id_instit_requested = i_prof.institution
                           AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                           AND EXISTS (SELECT 0
                                  FROM prof_room pr
                                 WHERE pr.id_professional = i_prof.id
                                   AND ei.id_room = pr.id_room)
                           AND se.flg_is_group = pk_alert_constant.g_no
                        --GROUP ELEMENTS
                        UNION ALL
                        SELECT s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode id_episode,
                               e.flg_ehr,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       e.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)) dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      g_sched_canc,
                                      pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                               sp.flg_sched,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS', s.flg_status, i_lang),
                                      pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                                  pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                    i_prof,
                                                                                                    ei.id_dep_clin_serv,
                                                                                                    e.flg_ehr,
                                                                                                    pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                    e.flg_ehr)),
                                                                  i_lang)) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               g_sysdate_char dt_server,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                                  g_sched_scheduled,
                                                                  NULL,
                                                                  e.dt_begin_tstz),
                                                           i_prof.institution,
                                                           i_prof.software) dt_begin,
                               decode(l_reasongrid,
                                      g_no,
                                      NULL,
                                      pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                  i_prof,
                                                                                                                  ei.id_episode,
                                                                                                                  s.id_schedule),
                                                                       4000)) visit_reason,
                               pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                               decode(e.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(e.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               NULL desc_room, -- decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  sg.id_patient,
                                                                  decode(e.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_normal,
                                                                         ei.id_episode,
                                                                         decode(l_to_old_area, g_yes, NULL, ei.id_episode))) designated_provider,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               sg.flg_contact_type,
                               pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               s.id_group,
                               pk_alert_constant.g_no flg_group_header,
                               'ExtendIcon' extend_icon,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               sp.dt_target_tstz,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_alert_constant.g_no prof_follow_remove
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN epis_type et
                            ON sp.id_epis_type = et.id_epis_type
                          LEFT JOIN epis_info ei
                            ON s.id_schedule = ei.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON ei.id_episode = e.id_episode
                           AND e.id_patient = ei.id_patient
                          LEFT JOIN sch_prof_outp spo
                            ON spo.id_schedule_outp = sp.id_schedule_outp
                         WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                               d.column_value
                                                FROM TABLE(l_group_ids) d)
                        --GROUP HEADER
                        UNION ALL
                        SELECT NULL id_schedule, --s.id_schedule,
                               NULL id_patient, --sg.id_patient,
                               NULL num_clin_record, --(SELECT cr.num_clin_record FROM clin_record cr WHERE cr.id_patient = sg.id_patient AND cr.id_institution = i_prof.institution AND rownum < 2) num_clin_record,
                               NULL id_episode, --decode(e.flg_ehr,pk_ehr_access.g_flg_ehr_normal,ei.id_episode,decode(l_to_old_area, g_yes, NULL, ei.id_episode)) id_episode,
                               e.flg_ehr,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      pk_date_utils.date_char_hour_tsz(i_lang,
                                                                       e.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)) dt_efectiv,
                               l_sch_t640 name, -- pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               l_sch_t640 name_to_sort, --pk_patient.get_pat_name_to_sort(i_lang,i_prof,sg.id_patient,ei.id_episode,s.id_schedule) name_to_sort,
                               NULL pat_ndo, --pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               NULL pat_nd_icon, --pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               NULL gender, --(SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender FROM patient pat WHERE sg.id_patient = pat.id_patient) gender,
                               NULL pat_age, --pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               NULL photo, --pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               'A' flg_state,
                               sp.flg_sched,
                               get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               g_sysdate_char dt_server,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               pk_date_utils.date_send_tsz(i_lang,
                                                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                                  g_sched_scheduled,
                                                                  NULL,
                                                                  e.dt_begin_tstz),
                                                           i_prof.institution,
                                                           i_prof.software) dt_begin,
                               decode(l_reasongrid,
                                      g_no,
                                      NULL,
                                      pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                  i_prof,
                                                                                                                  ei.id_episode,
                                                                                                                  s.id_schedule),
                                                                       4000)) visit_reason,
                               pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                               decode(e.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(e.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  sg.id_patient,
                                                                  decode(e.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_normal,
                                                                         ei.id_episode,
                                                                         decode(l_to_old_area, g_yes, NULL, ei.id_episode))) designated_provider,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               NULL flg_contact_type, --sg.flg_contact_type,
                               get_group_presence_icon(i_lang, i_prof, s.id_group, pk_alert_constant.g_no) icon_contact_type,
                               NULL flg_contact, --pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               s.id_group,
                               pk_alert_constant.g_yes flg_group_header,
                               NULL extend_icon,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               sp.dt_target_tstz,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_alert_constant.g_no prof_follow_remove
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN epis_type et
                            ON sp.id_epis_type = et.id_epis_type
                          LEFT JOIN epis_info ei
                            ON s.id_schedule = ei.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON ei.id_episode = e.id_episode
                           AND e.id_patient = ei.id_patient
                          LEFT JOIN sch_prof_outp spo
                            ON spo.id_schedule_outp = sp.id_schedule_outp
                         WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                                  d.column_value
                                                   FROM TABLE(l_schedule_ids) d)
                        --
                        ) t
                 ORDER BY t.order_state, t.dt_target_tstz, t.dt_begin;
        ELSE
            pk_types.open_my_cursor(o_doc);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DOCTOR_EFECTIV_CARE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END doctor_efectiv_care;

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
    * @value i_type                   {*} 'R' MY ROOMS , 'N' my speciality
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
    ) RETURN BOOLEAN IS
        l_waiting_room_sys_external sys_config.value%TYPE := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM',
                                                                                     i_prof);
        l_dt_min                    schedule_outp.dt_target_tstz%TYPE;
        l_dt_max                    schedule_outp.dt_target_tstz%TYPE;
        l_cancel_sched              sys_config.value%TYPE;
        l_show_med_disch            sys_config.value%TYPE;
        l_use_team_filter           sys_config.value%TYPE;
        l_handoff_type              sys_config.value%TYPE;
        l_show_nurse_disch          sys_config.value%TYPE := nvl(pk_sysconfig.get_config('SHOW_NURSE_DISCHARGED_GRID',
                                                                                         i_prof),
                                                                 g_no);
        l_waiting_room_available    sys_config.value%TYPE;
        l_group_ids                 table_number := table_number();
        l_schedule_ids              table_number := table_number();
        l_sch_t640                  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
        l_professional_ids          table_number := table_number();
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'CALL get_date_bounds';
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        g_error           := 'GET CONFIG DEFINITIONS';
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
        l_cancel_sched    := pk_sysconfig.get_config('FLG_CANCEL_SCHEDULE', i_prof);
        l_show_med_disch  := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID', i_prof), g_yes);
        l_use_team_filter := pk_sysconfig.get_config('ENABLE_TEAM_FILTER_GRID', i_prof);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        l_waiting_room_available := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
        ---------------------------------
        l_professional_ids := get_prof_team_det(i_prof);
    
        IF i_type = 'N'
        THEN
        
            SELECT DISTINCT s.id_group
              BULK COLLECT
              INTO l_group_ids
              FROM schedule_outp sp
              JOIN schedule s
                ON s.id_schedule = sp.id_schedule
              JOIN sch_prof_outp ps
                ON sp.id_schedule_outp = ps.id_schedule_outp
              JOIN professional p
                ON p.id_professional = ps.id_professional
              JOIN sch_group sg
                ON sg.id_schedule = sp.id_schedule
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              LEFT JOIN epis_info ei
                ON s.id_schedule = ei.id_schedule
               AND ei.id_patient = sg.id_patient
              LEFT JOIN episode e
                ON ei.id_episode = e.id_episode
               AND e.flg_status != g_epis_canc
               AND e.flg_ehr != g_flg_ehr
               AND e.id_patient = ei.id_patient
              JOIN prof_dep_clin_serv pdcs
                ON s.id_dcs_requested = pdcs.id_dep_clin_serv
              JOIN prof_cat pc
                ON p.id_professional = pc.id_professional
              JOIN category c
                ON pc.id_category = c.id_category
             WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND sp.id_software = i_prof.software
               AND s.id_instit_requested = i_prof.institution
               AND pdcs.id_professional = i_prof.id
               AND pdcs.flg_status = g_selected
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
               AND (sp.id_epis_type = g_epis_type_nurse OR (s.flg_status != g_sched_canc AND e.dt_cancel_tstz IS NULL))
               AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                   decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                   l_show_nurse_disch = g_yes)
               AND (l_show_med_disch = g_yes OR
                   (l_show_med_disch = g_no AND
                   pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
               AND pc.id_institution = i_prof.institution
               AND (l_use_team_filter = g_no OR
                   ps.id_professional IN (SELECT /*+OPT_ESTIMATE (TABLE k ROWS=0.00000000001)*/
                                            k.column_value
                                             FROM TABLE(l_professional_ids) k))
               AND (sp.id_epis_type = g_epis_type_nurse OR (ei.id_episode IS NOT NULL))
               AND se.flg_is_group = pk_alert_constant.g_yes
               AND s.id_group IS NOT NULL;
        
            l_schedule_ids := get_schedule_ids(l_group_ids);
        
            g_error := 'OPEN o_doc';
            OPEN o_doc FOR
                SELECT t.id_schedule,
                       t.id_patient,
                       t.id_episode,
                       t.num_proc,
                       t.name,
                       t.name_to_sort,
                       t.pat_ndo,
                       t.pat_nd_icon,
                       t.gender,
                       t.pat_age,
                       t.photo,
                       t.cons_type,
                       t.cont_type,
                       t.dt_target,
                       t.flg_state,
                       t.flg_sched,
                       t.prof_cat,
                       t.prof_name,
                       t.dt_efectiv,
                       t.dt_efectiv_compl,
                       t.img_state,
                       t.desc_drug_vaccine_req,
                       t.desc_nur_interv_monit_tea,
                       t.desc_ana_exam_req,
                       t.dt_server,
                       t.room,
                       wr_call(i_lang, i_prof, t.wr_call, i_dt) wr_call,
                       t.flg_nurse,
                       t.flg_button_ok,
                       t.flg_button_cancel,
                       t.flg_button_detail,
                       t.flg_cancel,
                       t.desc_mov,
                       t.resp_icon,
                       t.desc_room,
                       t.designated_provider,
                       t.flg_contact_type,
                       t.icon_contact_type,
                       t.flg_contact,
                       t.id_group,
                       t.flg_group_header,
                       t.extend_icon,
                       t.prof_follow_add,
                       t.prof_follow_remove
                  FROM (SELECT dt.id_schedule,
                               dt.id_patient,
                               dt.id_episode id_episode,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = dt.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND cr.flg_status = pk_alert_constant.g_active
                                   AND rownum < 2) num_proc,
                               dt.name,
                               dt.name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, dt.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, dt.id_patient) pat_nd_icon,
                               pk_sysdomain.get_domain(g_domain_pat_gender_abbr, gender, i_lang) gender,
                               pk_patient.get_pat_age(i_lang, dt.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) photo,
                               pk_translation.get_translation(i_lang, dt.code_clinical_service) cons_type,
                               decode(dt.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(dt.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_target_tstz, i_prof) dt_target,
                               decode(dt.flg_status,
                                      g_sched_canc,
                                      g_sched_canc,
                                      pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr)) flg_state,
                               dt.flg_sched,
                               pk_translation.get_translation(i_lang, dt.code_category) prof_cat,
                               dt.nick_name prof_name,
                               CASE
                                    WHEN dt.id_episode_ei IS NOT NULL THEN
                                     decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                            g_sched_scheduled,
                                            NULL,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             dt.dt_begin_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software))
                                    ELSE
                                     NULL
                                END dt_efectiv,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_begin_tstz, i_prof) dt_efectiv_compl,
                               dt.img_state,
                               decode(pk_grid.get_prioritary_task(i_lang,
                                                                  substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                                                  substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                                                  NULL,
                                                                  g_flg_doctor),
                                      substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                      pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.drug_presc),
                                      substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                      pk_grid.convert_grid_task_str(i_lang, i_prof, dt.drug_req)) desc_drug_vaccine_req,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  dt.icnp_intervention,
                                                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                                                              i_prof,
                                                                                                                              dt.nurse_activity,
                                                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                          i_prof,
                                                                                                                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                      i_prof,
                                                                                                                                                                                      dt.intervention,
                                                                                                                                                                                      dt.monitorization,
                                                                                                                                                                                      NULL,
                                                                                                                                                                                      g_flg_doctor),
                                                                                                                                                          dt.teach_req,
                                                                                                                                                          NULL,
                                                                                                                                                          g_flg_doctor),
                                                                                                                              NULL,
                                                                                                                              g_flg_doctor),
                                                                                                  NULL,
                                                                                                  g_flg_doctor)) desc_nur_interv_monit_tea,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               g_sysdate_char dt_server,
                               nvl(dt.desc_room, get_room_desc(i_lang, dt.sch_room)) room,
                               dt.wr_call,
                               decode(dt.id_epis_type, g_epis_type_nurse, g_yes, g_no) flg_nurse,
                               decode(dt.id_epis_type,
                                      g_epis_type_nurse,
                                      decode(dt.flg_status, g_sched_canc, g_no, g_yes),
                                      g_yes) flg_button_ok,
                               decode(l_cancel_sched,
                                      g_yes,
                                      decode(dt.id_epis_type,
                                             g_epis_type_nurse,
                                             decode(decode(dt.flg_status,
                                                           g_sched_canc,
                                                           g_sched_canc,
                                                           pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr)),
                                                    g_nurse_scheduled,
                                                    g_yes,
                                                    g_no),
                                             g_no),
                                      g_no) flg_button_cancel,
                               decode(dt.id_epis_type,
                                      g_epis_type_nurse,
                                      decode(dt.flg_status, g_sched_canc, g_yes, g_no),
                                      g_no) flg_button_detail,
                               decode(dt.flg_status, g_sched_canc, g_yes, g_no) flg_cancel,
                               pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.movement) desc_mov,
                               resp_icon,
                               desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  dt.id_patient,
                                                                  decode(dt.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_scheduled,
                                                                         NULL,
                                                                         dt.id_episode)) designated_provider,
                               dt.flg_contact_type,
                               pk_sysdomain.get_img(i_lang, g_domain_sch_presence, dt.flg_contact_type) icon_contact_type,
                               pk_adt.is_contact(i_lang, i_prof, dt.id_patient) flg_contact,
                               decode(dt.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               dt.dt_target_tstz,
                               0 id_group,
                               pk_alert_constant.g_no flg_group_header,
                               NULL extend_icon,
                               decode(pk_prof_follow.get_follow_episode_by_me(i_prof, dt.id_episode, dt.id_schedule),
                                      pk_alert_constant.g_no,
                                      decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                              i_prof,
                                                                                                              dt.id_episode,
                                                                                                              i_prof_cat_type,
                                                                                                              l_handoff_type,
                                                                                                              pk_alert_constant.g_yes),
                                                                          i_prof.id),
                                             -1,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no),
                                      pk_alert_constant.g_no) prof_follow_add,
                               pk_prof_follow.get_follow_episode_by_me(i_prof, dt.id_episode, dt.id_schedule) prof_follow_remove
                          FROM (SELECT s.id_schedule,
                                       e.flg_ehr,
                                       e.id_episode,
                                       pat.id_patient,
                                       sp.dt_target_tstz,
                                       pk_patient.get_pat_name(i_lang,
                                                               i_prof,
                                                               pat.id_patient,
                                                               e.id_episode,
                                                               s.id_schedule) name,
                                       pk_patient.get_pat_name_to_sort(i_lang,
                                                                       i_prof,
                                                                       pat.id_patient,
                                                                       e.id_episode,
                                                                       s.id_schedule) name_to_sort,
                                       pat.gender,
                                       cs.code_clinical_service,
                                       s.schedule_cancel_notes,
                                       s.flg_status,
                                       sp.flg_state,
                                       sp.flg_sched,
                                       c.code_category,
                                       p.nick_name,
                                       ei.id_episode id_episode_ei,
                                       e.dt_begin_tstz,
                                       sp.id_epis_type,
                                       s.id_dcs_requested,
                                       gt.drug_presc,
                                       gt.drug_req,
                                       gt.icnp_intervention,
                                       gt.nurse_activity,
                                       gt.intervention,
                                       gt.monitorization,
                                       gt.teach_req,
                                       e.id_visit,
                                       s.schedule_cancel_notes canc_notes,
                                       e.flg_appointment_type,
                                       gt.movement,
                                       pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                                       s.id_room sch_room,
                                       decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                                       sg.flg_contact_type,
                                       decode(sp.id_epis_type,
                                              g_epis_type_nurse,
                                              pk_sysdomain.get_ranked_img(g_schdl_nurse_state_domain,
                                                                          decode(s.flg_status,
                                                                                 g_sched_canc,
                                                                                 g_sched_canc,
                                                                                 pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                 e.flg_ehr)),
                                                                          i_lang),
                                              pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                                          pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                            i_prof,
                                                                                                            ei.id_dep_clin_serv,
                                                                                                            e.flg_ehr,
                                                                                                            pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                            e.flg_ehr)),
                                                                          i_lang)) img_state,
                                       pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                               i_prof                      => i_prof,
                                                               i_waiting_room_available    => l_waiting_room_available,
                                                               i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                               i_id_episode                => ei.id_episode,
                                                               i_flg_state                 => sp.flg_state,
                                                               i_flg_ehr                   => e.flg_ehr,
                                                               i_id_dcs_requested          => s.id_dcs_requested) wr_call
                                  FROM schedule_outp sp
                                  JOIN schedule s
                                    ON s.id_schedule = sp.id_schedule
                                  JOIN sch_prof_outp ps
                                    ON sp.id_schedule_outp = ps.id_schedule_outp
                                  JOIN professional p
                                    ON p.id_professional = ps.id_professional
                                
                                  JOIN sch_group sg
                                    ON sg.id_schedule = sp.id_schedule
                                  JOIN sch_event se
                                    ON s.id_sch_event = se.id_sch_event
                                  LEFT JOIN epis_info ei
                                    ON s.id_schedule = ei.id_schedule
                                  JOIN dep_clin_serv dcs
                                    ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                                   AND ei.id_patient = sg.id_patient
                                  JOIN patient pat
                                    ON pat.id_patient = sg.id_patient
                                  JOIN clinical_service cs
                                    ON cs.id_clinical_service = dcs.id_clinical_service
                                
                                  LEFT JOIN episode e
                                    ON ei.id_episode = e.id_episode
                                   AND e.flg_status != g_epis_canc
                                   AND e.flg_ehr != g_flg_ehr
                                   AND e.id_patient = ei.id_patient
                                  JOIN prof_dep_clin_serv pdcs
                                    ON ei.id_dep_clin_serv = pdcs.id_dep_clin_serv
                                  LEFT JOIN grid_task gt
                                    ON e.id_episode = gt.id_episode
                                  LEFT JOIN discharge d
                                    ON e.id_episode = d.id_episode
                                   AND d.dt_cancel_tstz IS NULL
                                  JOIN prof_cat pc
                                    ON p.id_professional = pc.id_professional
                                  JOIN category c
                                    ON pc.id_category = c.id_category
                                 WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                                   AND sp.id_software = i_prof.software
                                   AND s.id_instit_requested = i_prof.institution
                                   AND pdcs.id_professional = i_prof.id
                                   AND pdcs.flg_status = g_selected
                                   AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                                   AND (sp.id_epis_type = g_epis_type_nurse OR
                                       (s.flg_status != g_sched_canc AND e.dt_cancel_tstz IS NULL))
                                   AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                                       decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                                       l_show_nurse_disch = g_yes)
                                   AND (l_show_med_disch = g_yes OR
                                       (l_show_med_disch = g_no AND
                                       pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
                                   AND pc.id_institution = i_prof.institution
                                   AND (l_use_team_filter = g_no OR
                                       ps.id_professional IN (SELECT /*+OPT_ESTIMATE (TABLE k ROWS=0.00000000001)*/
                                                                k.column_value
                                                                 FROM TABLE(l_professional_ids) k))
                                   AND (sp.id_epis_type = g_epis_type_nurse OR (ei.id_episode IS NOT NULL))
                                   AND se.flg_is_group = pk_alert_constant.g_no) dt
                        --group elements
                        UNION ALL
                        SELECT dt.id_schedule,
                               dt.id_patient,
                               dt.id_episode id_episode,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = dt.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND cr.flg_status = pk_alert_constant.g_active
                                   AND rownum < 2) num_proc,
                               dt.name,
                               dt.name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, dt.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, dt.id_patient) pat_nd_icon,
                               pk_sysdomain.get_domain(g_domain_pat_gender_abbr, gender, i_lang) gender,
                               pk_patient.get_pat_age(i_lang, dt.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) photo,
                               pk_translation.get_translation(i_lang, dt.code_clinical_service) cons_type,
                               decode(dt.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(dt.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_target_tstz, i_prof) dt_target,
                               decode(dt.flg_status,
                                      g_sched_canc,
                                      g_sched_canc,
                                      pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr)) flg_state,
                               dt.flg_sched,
                               pk_translation.get_translation(i_lang, dt.code_category) prof_cat,
                               dt.nick_name prof_name,
                               CASE
                                    WHEN dt.id_episode_ei IS NOT NULL THEN
                                     decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                            g_sched_scheduled,
                                            NULL,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             dt.dt_begin_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software))
                                    ELSE
                                     NULL
                                END dt_efectiv,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_begin_tstz, i_prof) dt_efectiv_compl,
                               dt.img_state,
                               decode(pk_grid.get_prioritary_task(i_lang,
                                                                  substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                                                  substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                                                  NULL,
                                                                  g_flg_doctor),
                                      substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                      pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.drug_presc),
                                      substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                      pk_grid.convert_grid_task_str(i_lang, i_prof, dt.drug_req)) desc_drug_vaccine_req,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  dt.icnp_intervention,
                                                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                                                              i_prof,
                                                                                                                              dt.nurse_activity,
                                                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                          i_prof,
                                                                                                                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                      i_prof,
                                                                                                                                                                                      dt.intervention,
                                                                                                                                                                                      dt.monitorization,
                                                                                                                                                                                      NULL,
                                                                                                                                                                                      g_flg_doctor),
                                                                                                                                                          dt.teach_req,
                                                                                                                                                          NULL,
                                                                                                                                                          g_flg_doctor),
                                                                                                                              NULL,
                                                                                                                              g_flg_doctor),
                                                                                                  NULL,
                                                                                                  g_flg_doctor)) desc_nur_interv_monit_tea,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               g_sysdate_char dt_server,
                               NULL room, -- nvl(dt.desc_room, get_room_desc(i_lang, dt.sch_room)) room,
                               dt.wr_call,
                               decode(dt.id_epis_type, g_epis_type_nurse, g_yes, g_no) flg_nurse,
                               decode(dt.id_epis_type,
                                      g_epis_type_nurse,
                                      decode(dt.flg_status, g_sched_canc, g_no, g_yes),
                                      g_yes) flg_button_ok,
                               decode(l_cancel_sched,
                                      g_yes,
                                      decode(dt.id_epis_type,
                                             g_epis_type_nurse,
                                             decode(decode(dt.flg_status,
                                                           g_sched_canc,
                                                           g_sched_canc,
                                                           pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr)),
                                                    g_nurse_scheduled,
                                                    g_yes,
                                                    g_no),
                                             g_no),
                                      g_no) flg_button_cancel,
                               decode(dt.id_epis_type,
                                      g_epis_type_nurse,
                                      decode(dt.flg_status, g_sched_canc, g_yes, g_no),
                                      g_no) flg_button_detail,
                               decode(dt.flg_status, g_sched_canc, g_yes, g_no) flg_cancel,
                               pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.movement) desc_mov,
                               resp_icon,
                               desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  dt.id_patient,
                                                                  decode(dt.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_scheduled,
                                                                         NULL,
                                                                         dt.id_episode)) designated_provider,
                               dt.flg_contact_type,
                               pk_sysdomain.get_img(i_lang, g_domain_sch_presence, dt.flg_contact_type) icon_contact_type,
                               pk_adt.is_contact(i_lang, i_prof, dt.id_patient) flg_contact,
                               decode(dt.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               dt.dt_target_tstz,
                               dt.id_group,
                               pk_alert_constant.g_no flg_group_header,
                               'ExtendIcon' extend_icon,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_alert_constant.g_no prof_follow_remove
                          FROM (SELECT s.id_schedule,
                                       e.flg_ehr,
                                       e.id_episode,
                                       pat.id_patient,
                                       sp.dt_target_tstz,
                                       pk_patient.get_pat_name(i_lang,
                                                               i_prof,
                                                               pat.id_patient,
                                                               e.id_episode,
                                                               s.id_schedule) name,
                                       pk_patient.get_pat_name_to_sort(i_lang,
                                                                       i_prof,
                                                                       pat.id_patient,
                                                                       e.id_episode,
                                                                       s.id_schedule) name_to_sort,
                                       pat.gender,
                                       cs.code_clinical_service,
                                       s.schedule_cancel_notes,
                                       s.flg_status,
                                       sp.flg_state,
                                       sp.flg_sched,
                                       c.code_category,
                                       p.nick_name,
                                       ei.id_episode id_episode_ei,
                                       e.dt_begin_tstz,
                                       sp.id_epis_type,
                                       s.id_dcs_requested,
                                       gt.drug_presc,
                                       gt.drug_req,
                                       gt.icnp_intervention,
                                       gt.nurse_activity,
                                       gt.intervention,
                                       gt.monitorization,
                                       gt.teach_req,
                                       e.id_visit,
                                       s.schedule_cancel_notes canc_notes,
                                       e.flg_appointment_type,
                                       gt.movement,
                                       pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                                       s.id_room sch_room,
                                       NULL desc_room, -- decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                                       sg.flg_contact_type,
                                       decode(sp.id_epis_type,
                                              g_epis_type_nurse,
                                              pk_sysdomain.get_ranked_img(g_schdl_nurse_state_domain,
                                                                          decode(s.flg_status,
                                                                                 g_sched_canc,
                                                                                 g_sched_canc,
                                                                                 pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                 e.flg_ehr)),
                                                                          i_lang),
                                              decode(s.flg_status,
                                                     g_sched_canc,
                                                     pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS',
                                                                                 s.flg_status,
                                                                                 i_lang),
                                                     pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                                                 pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                                   i_prof,
                                                                                                                   ei.id_dep_clin_serv,
                                                                                                                   e.flg_ehr,
                                                                                                                   pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                                   e.flg_ehr)),
                                                                                 i_lang))) img_state,
                                       pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                               i_prof                      => i_prof,
                                                               i_waiting_room_available    => l_waiting_room_available,
                                                               i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                               i_id_episode                => ei.id_episode,
                                                               i_flg_state                 => sp.flg_state,
                                                               i_flg_ehr                   => e.flg_ehr,
                                                               i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                                       s.id_group
                                  FROM schedule_outp sp
                                  JOIN schedule s
                                    ON s.id_schedule = sp.id_schedule
                                  JOIN sch_prof_outp ps
                                    ON sp.id_schedule_outp = ps.id_schedule_outp
                                  JOIN professional p
                                    ON p.id_professional = ps.id_professional
                                
                                  JOIN sch_group sg
                                    ON sg.id_schedule = sp.id_schedule
                                  LEFT JOIN epis_info ei
                                    ON s.id_schedule = ei.id_schedule
                                   AND ei.id_patient = sg.id_patient
                                  JOIN dep_clin_serv dcs
                                    ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                                  JOIN patient pat
                                    ON pat.id_patient = sg.id_patient
                                  JOIN clinical_service cs
                                    ON cs.id_clinical_service = dcs.id_clinical_service
                                
                                  LEFT JOIN episode e
                                    ON ei.id_episode = e.id_episode
                                  JOIN prof_dep_clin_serv pdcs
                                    ON ei.id_dep_clin_serv = pdcs.id_dep_clin_serv
                                   AND pdcs.id_professional = i_prof.id
                                   AND pdcs.flg_status = g_selected
                                  LEFT JOIN grid_task gt
                                    ON e.id_episode = gt.id_episode
                                  LEFT JOIN discharge d
                                    ON e.id_episode = d.id_episode
                                   AND d.dt_cancel_tstz IS NULL
                                  JOIN prof_cat pc
                                    ON p.id_professional = pc.id_professional
                                   AND pc.id_institution = i_prof.institution
                                  JOIN category c
                                    ON pc.id_category = c.id_category
                                 WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                                       d.column_value
                                                        FROM TABLE(l_group_ids) d)) dt
                        --group header
                        UNION ALL
                        SELECT NULL id_schedule, --dt.id_schedule,
                               NULL id_patient, -- dt.id_patient,
                               NULL id_episode, -- decode(dt.flg_ehr, pk_ehr_access.g_flg_ehr_scheduled, NULL, dt.id_episode) id_episode,
                               NULL num_proc, --(SELECT cr.num_clin_record FROM clin_record cr WHERE cr.id_patient = dt.id_patient AND cr.id_institution = i_prof.institution AND cr.flg_status = pk_alert_constant.g_active AND rownum < 2) num_proc,
                               l_sch_t640 name, --dt.name,
                               l_sch_t640 name_to_sort, --  dt.name_to_sort,
                               NULL pat_ndo, --   pk_adt.get_pat_non_disc_options(i_lang, i_prof, dt.id_patient) pat_ndo,
                               NULL pat_nd_icon, --  pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, dt.id_patient) pat_nd_icon,
                               NULL gender, --   pk_sysdomain.get_domain(g_domain_pat_gender_abbr, gender, i_lang) gender,
                               NULL pat_age, --  pk_patient.get_pat_age(i_lang, dt.id_patient, i_prof) pat_age,
                               NULL photo, --     pk_patphoto.get_pat_photo(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) photo,
                               pk_translation.get_translation(i_lang, dt.code_clinical_service) cons_type,
                               decode(dt.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(dt.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_target_tstz, i_prof) dt_target,
                               dt.flg_state,
                               dt.flg_sched,
                               pk_translation.get_translation(i_lang, dt.code_category) prof_cat,
                               dt.nick_name prof_name,
                               CASE
                                    WHEN dt.id_episode_ei IS NOT NULL THEN
                                     decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                            g_sched_scheduled,
                                            NULL,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             dt.dt_begin_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software))
                                    ELSE
                                     NULL
                                END dt_efectiv,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_begin_tstz, i_prof) dt_efectiv_compl,
                               dt.img_state,
                               decode(pk_grid.get_prioritary_task(i_lang,
                                                                  substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                                                  substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                                                  NULL,
                                                                  g_flg_doctor),
                                      substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                      pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.drug_presc),
                                      substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                      pk_grid.convert_grid_task_str(i_lang, i_prof, dt.drug_req)) desc_drug_vaccine_req,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  dt.icnp_intervention,
                                                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                                                              i_prof,
                                                                                                                              dt.nurse_activity,
                                                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                          i_prof,
                                                                                                                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                      i_prof,
                                                                                                                                                                                      dt.intervention,
                                                                                                                                                                                      dt.monitorization,
                                                                                                                                                                                      NULL,
                                                                                                                                                                                      g_flg_doctor),
                                                                                                                                                          dt.teach_req,
                                                                                                                                                          NULL,
                                                                                                                                                          g_flg_doctor),
                                                                                                                              NULL,
                                                                                                                              g_flg_doctor),
                                                                                                  NULL,
                                                                                                  g_flg_doctor)) desc_nur_interv_monit_tea,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               g_sysdate_char dt_server,
                               nvl(dt.desc_room, get_room_desc(i_lang, dt.sch_room)) room,
                               /*decode(l_waiting_room_available,
                               g_wr_available_y,
                               decode(l_waiting_room_sys_external,
                                      g_yes,
                                      g_yes,
                                      pk_wlcore.get_available_for_call(i_lang,
                                                                       i_prof,
                                                                       dt.id_episode,
                                                                       dt.flg_state,
                                                                       dt.flg_ehr)),
                               pk_alert_constant.g_no)*/
                               dt.wr_call,
                               decode(dt.id_epis_type, g_epis_type_nurse, g_yes, g_no) flg_nurse,
                               g_no flg_button_ok,
                               decode(l_cancel_sched,
                                      g_yes,
                                      decode(dt.id_epis_type,
                                             g_epis_type_nurse,
                                             decode(decode(dt.flg_status,
                                                           g_sched_canc,
                                                           g_sched_canc,
                                                           pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr)),
                                                    g_nurse_scheduled,
                                                    g_yes,
                                                    g_no),
                                             g_no),
                                      g_no) flg_button_cancel,
                               g_no flg_button_detail,
                               decode(dt.flg_status, g_sched_canc, g_yes, g_no) flg_cancel,
                               pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.movement) desc_mov,
                               resp_icon,
                               desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  dt.id_patient,
                                                                  decode(dt.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_scheduled,
                                                                         NULL,
                                                                         dt.id_episode)) designated_provider,
                               NULL flg_contact_type, --sg.flg_contact_type,
                               get_group_presence_icon(i_lang, i_prof, dt.id_group, pk_alert_constant.g_no) icon_contact_type,
                               NULL flg_contact, --pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               decode(dt.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               dt.dt_target_tstz,
                               dt.id_group,
                               pk_alert_constant.g_yes flg_group_header,
                               NULL extend_icon,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_alert_constant.g_no prof_follow_remove
                          FROM (SELECT s.id_schedule,
                                       e.flg_ehr,
                                       e.id_episode,
                                       pat.id_patient,
                                       sp.dt_target_tstz,
                                       pk_patient.get_pat_name(i_lang,
                                                               i_prof,
                                                               pat.id_patient,
                                                               e.id_episode,
                                                               s.id_schedule) name,
                                       pk_patient.get_pat_name_to_sort(i_lang,
                                                                       i_prof,
                                                                       pat.id_patient,
                                                                       e.id_episode,
                                                                       s.id_schedule) name_to_sort,
                                       pat.gender,
                                       cs.code_clinical_service,
                                       s.schedule_cancel_notes,
                                       s.flg_status,
                                       'A' flg_state,
                                       sp.flg_sched,
                                       c.code_category,
                                       p.nick_name,
                                       ei.id_episode id_episode_ei,
                                       e.dt_begin_tstz,
                                       sp.id_epis_type,
                                       s.id_dcs_requested,
                                       gt.drug_presc,
                                       gt.drug_req,
                                       gt.icnp_intervention,
                                       gt.nurse_activity,
                                       gt.intervention,
                                       gt.monitorization,
                                       gt.teach_req,
                                       e.id_visit,
                                       s.schedule_cancel_notes canc_notes,
                                       e.flg_appointment_type,
                                       gt.movement,
                                       pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                                       s.id_room sch_room,
                                       decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                                       sg.flg_contact_type,
                                       get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                                       pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                               i_prof                      => i_prof,
                                                               i_waiting_room_available    => l_waiting_room_available,
                                                               i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                               i_id_episode                => ei.id_episode,
                                                               i_flg_state                 => sp.flg_state,
                                                               i_flg_ehr                   => e.flg_ehr,
                                                               i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                                       s.id_group
                                  FROM schedule_outp sp
                                  JOIN schedule s
                                    ON s.id_schedule = sp.id_schedule
                                  JOIN sch_prof_outp ps
                                    ON sp.id_schedule_outp = ps.id_schedule_outp
                                  JOIN professional p
                                    ON p.id_professional = ps.id_professional
                                
                                  JOIN sch_group sg
                                    ON sg.id_schedule = sp.id_schedule
                                  LEFT JOIN epis_info ei
                                    ON s.id_schedule = ei.id_schedule
                                   AND ei.id_patient = sg.id_patient
                                  JOIN dep_clin_serv dcs
                                    ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                                  JOIN patient pat
                                    ON pat.id_patient = sg.id_patient
                                  JOIN clinical_service cs
                                    ON cs.id_clinical_service = dcs.id_clinical_service
                                
                                  LEFT JOIN episode e
                                    ON ei.id_episode = e.id_episode
                                  JOIN prof_dep_clin_serv pdcs
                                    ON ei.id_dep_clin_serv = pdcs.id_dep_clin_serv
                                   AND pdcs.id_professional = i_prof.id
                                   AND pdcs.flg_status = g_selected
                                  LEFT JOIN grid_task gt
                                    ON e.id_episode = gt.id_episode
                                  LEFT JOIN discharge d
                                    ON e.id_episode = d.id_episode
                                   AND d.dt_cancel_tstz IS NULL
                                  JOIN prof_cat pc
                                    ON p.id_professional = pc.id_professional
                                   AND pc.id_institution = i_prof.institution
                                  JOIN category c
                                    ON pc.id_category = c.id_category
                                 WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                                          d.column_value
                                                           FROM TABLE(l_schedule_ids) d)) dt
                        --                           
                        ) t
                 ORDER BY t.order_state, t.dt_target_tstz;
        
        ELSIF i_type = 'R'
        THEN
        
            SELECT DISTINCT s.id_group
              BULK COLLECT
              INTO l_group_ids
              FROM schedule_outp sp
              JOIN schedule s
                ON s.id_schedule = sp.id_schedule
              JOIN sch_prof_outp ps
                ON sp.id_schedule_outp = ps.id_schedule_outp
              JOIN professional p
                ON p.id_professional = ps.id_professional
            
              JOIN sch_group sg
                ON sg.id_schedule = sp.id_schedule
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              LEFT JOIN epis_info ei
                ON s.id_schedule = ei.id_schedule
               AND ei.id_patient = sg.id_patient
              JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
              JOIN patient pat
                ON pat.id_patient = sg.id_patient
              JOIN clinical_service cs
                ON cs.id_clinical_service = dcs.id_clinical_service
            
              LEFT JOIN episode e
                ON ei.id_episode = e.id_episode
               AND e.flg_status != g_epis_canc
               AND e.flg_ehr != g_flg_ehr
               AND e.id_patient = ei.id_patient
              LEFT JOIN grid_task gt
                ON e.id_episode = gt.id_episode
              LEFT JOIN discharge d
                ON e.id_episode = d.id_episode
               AND d.dt_cancel_tstz IS NULL
              JOIN prof_cat pc
                ON p.id_professional = pc.id_professional
              JOIN category c
                ON pc.id_category = c.id_category
             WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND sp.id_software = i_prof.software
               AND s.id_instit_requested = i_prof.institution
               AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
               AND (sp.id_epis_type = g_epis_type_nurse OR (s.flg_status != g_sched_canc AND e.dt_cancel_tstz IS NULL))
               AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                   decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                   l_show_nurse_disch = g_yes)
               AND (l_show_med_disch = g_yes OR
                   (l_show_med_disch = g_no AND
                   pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
               AND pc.id_institution = i_prof.institution
               AND EXISTS (SELECT 0
                      FROM prof_room pr
                     WHERE pr.id_professional = i_prof.id
                       AND ei.id_room = pr.id_room)
               AND (l_use_team_filter = g_no OR
                   ps.id_professional IN (SELECT /*+OPT_ESTIMATE (TABLE k ROWS=0.00000000001)*/
                                            k.column_value
                                             FROM TABLE(l_professional_ids) k))
               AND (sp.id_epis_type = g_epis_type_nurse OR (ei.id_episode IS NOT NULL))
               AND se.flg_is_group = pk_alert_constant.g_yes
               AND s.id_group IS NOT NULL;
        
            l_schedule_ids := get_schedule_ids(l_group_ids);
        
            OPEN o_doc FOR
                SELECT t.id_schedule,
                       t.id_patient,
                       t.id_episode,
                       t.num_proc,
                       t.name,
                       t.name_to_sort,
                       t.pat_ndo,
                       t.pat_nd_icon,
                       t.gender,
                       t.pat_age,
                       t.photo,
                       t.cons_type,
                       t.cont_type,
                       t.dt_target,
                       t.flg_state,
                       t.flg_sched,
                       t.prof_cat,
                       t.prof_name,
                       t.dt_efectiv,
                       t.dt_efectiv_compl,
                       t.img_state,
                       t.desc_drug_vaccine_req,
                       t.desc_nur_interv_monit_tea,
                       t.desc_ana_exam_req,
                       t.dt_server,
                       t.room,
                       wr_call(i_lang, i_prof, t.wr_call, i_dt) wr_call,
                       t.flg_nurse,
                       t.flg_button_ok,
                       t.flg_button_cancel,
                       t.flg_button_detail,
                       t.flg_cancel,
                       t.desc_mov,
                       t.resp_icon,
                       t.desc_room,
                       t.designated_provider,
                       t.flg_contact_type,
                       t.icon_contact_type,
                       t.id_group,
                       t.flg_group_header,
                       t.extend_icon,
                       t.prof_follow_add,
                       t.prof_follow_remove
                  FROM (SELECT dt.id_schedule,
                               dt.id_patient,
                               dt.id_episode id_episode,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = dt.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND cr.flg_status = pk_alert_constant.g_active
                                   AND rownum < 2) num_proc,
                               dt.name,
                               dt.name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, dt.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, dt.id_patient) pat_nd_icon,
                               pk_sysdomain.get_domain(g_domain_pat_gender_abbr, gender, i_lang) gender,
                               pk_patient.get_pat_age(i_lang, dt.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) photo,
                               pk_translation.get_translation(i_lang, dt.code_clinical_service) cons_type,
                               decode(dt.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(dt.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_target_tstz, i_prof) dt_target,
                               decode(dt.flg_status,
                                      g_sched_canc,
                                      g_sched_canc,
                                      pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr)) flg_state,
                               dt.flg_sched,
                               pk_translation.get_translation(i_lang, dt.code_category) prof_cat,
                               dt.nick_name prof_name,
                               CASE
                                    WHEN dt.id_episode_ei IS NOT NULL THEN
                                     decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                            g_sched_scheduled,
                                            NULL,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             dt.dt_begin_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software))
                                    ELSE
                                     NULL
                                END dt_efectiv,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_begin_tstz, i_prof) dt_efectiv_compl,
                               dt.img_state,
                               decode(pk_grid.get_prioritary_task(i_lang,
                                                                  substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                                                  substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                                                  NULL,
                                                                  g_flg_doctor),
                                      substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                      pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.drug_presc),
                                      substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                      pk_grid.convert_grid_task_str(i_lang, i_prof, dt.drug_req)) desc_drug_vaccine_req,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  dt.icnp_intervention,
                                                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                                                              i_prof,
                                                                                                                              dt.nurse_activity,
                                                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                          i_prof,
                                                                                                                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                      i_prof,
                                                                                                                                                                                      dt.intervention,
                                                                                                                                                                                      dt.monitorization,
                                                                                                                                                                                      NULL,
                                                                                                                                                                                      g_flg_doctor),
                                                                                                                                                          dt.teach_req,
                                                                                                                                                          NULL,
                                                                                                                                                          g_flg_doctor),
                                                                                                                              NULL,
                                                                                                                              g_flg_doctor),
                                                                                                  NULL,
                                                                                                  g_flg_doctor)) desc_nur_interv_monit_tea,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               g_sysdate_char dt_server,
                               nvl(dt.desc_room, get_room_desc(i_lang, dt.sch_room)) room,
                               dt.wr_call,
                               decode(dt.id_epis_type, g_epis_type_nurse, g_yes, g_no) flg_nurse,
                               decode(dt.id_epis_type,
                                      g_epis_type_nurse,
                                      decode(dt.flg_status, g_sched_canc, g_no, g_yes),
                                      g_yes) flg_button_ok,
                               decode(l_cancel_sched,
                                      g_yes,
                                      decode(dt.id_epis_type,
                                             g_epis_type_nurse,
                                             decode(decode(dt.flg_status,
                                                           g_sched_canc,
                                                           g_sched_canc,
                                                           pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr)),
                                                    g_nurse_scheduled,
                                                    g_yes,
                                                    g_no),
                                             g_no),
                                      g_no) flg_button_cancel,
                               decode(dt.id_epis_type,
                                      g_epis_type_nurse,
                                      decode(dt.flg_status, g_sched_canc, g_yes, g_no),
                                      g_no) flg_button_detail,
                               decode(dt.flg_status, g_sched_canc, g_yes, g_no) flg_cancel,
                               pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.movement) desc_mov,
                               resp_icon,
                               desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  dt.id_patient,
                                                                  decode(dt.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_scheduled,
                                                                         NULL,
                                                                         dt.id_episode)) designated_provider,
                               dt.flg_contact_type,
                               pk_sysdomain.get_img(i_lang, g_domain_sch_presence, dt.flg_contact_type) icon_contact_type,
                               decode(dt.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               dt.dt_target_tstz,
                               0 id_group,
                               pk_alert_constant.g_no flg_group_header,
                               NULL extend_icon,
                               decode(pk_prof_follow.get_follow_episode_by_me(i_prof, dt.id_episode, dt.id_schedule),
                                      pk_alert_constant.g_no,
                                      decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                              i_prof,
                                                                                                              dt.id_episode,
                                                                                                              i_prof_cat_type,
                                                                                                              l_handoff_type,
                                                                                                              pk_alert_constant.g_yes),
                                                                          i_prof.id),
                                             -1,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no),
                                      pk_alert_constant.g_no) prof_follow_add,
                               pk_prof_follow.get_follow_episode_by_me(i_prof, dt.id_episode, dt.id_schedule) prof_follow_remove
                          FROM (SELECT s.id_schedule,
                                       e.flg_ehr,
                                       e.id_episode,
                                       pat.id_patient,
                                       sp.dt_target_tstz,
                                       pk_patient.get_pat_name(i_lang,
                                                               i_prof,
                                                               pat.id_patient,
                                                               e.id_episode,
                                                               s.id_schedule) name,
                                       pk_patient.get_pat_name_to_sort(i_lang,
                                                                       i_prof,
                                                                       pat.id_patient,
                                                                       e.id_episode,
                                                                       s.id_schedule) name_to_sort,
                                       pat.gender,
                                       cs.code_clinical_service,
                                       s.schedule_cancel_notes,
                                       s.flg_status,
                                       sp.flg_state,
                                       sp.flg_sched,
                                       c.code_category,
                                       p.nick_name,
                                       ei.id_episode id_episode_ei,
                                       e.dt_begin_tstz,
                                       sp.id_epis_type,
                                       s.id_dcs_requested,
                                       gt.drug_presc,
                                       gt.drug_req,
                                       gt.icnp_intervention,
                                       gt.nurse_activity,
                                       gt.intervention,
                                       gt.monitorization,
                                       gt.teach_req,
                                       e.id_visit,
                                       s.schedule_cancel_notes canc_notes,
                                       e.flg_appointment_type,
                                       gt.movement,
                                       pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                                       s.id_room sch_room,
                                       decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                                       sg.flg_contact_type,
                                       decode(sp.id_epis_type,
                                              g_epis_type_nurse,
                                              pk_sysdomain.get_ranked_img(g_schdl_nurse_state_domain,
                                                                          decode(s.flg_status,
                                                                                 g_sched_canc,
                                                                                 g_sched_canc,
                                                                                 pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                 e.flg_ehr)),
                                                                          i_lang),
                                              pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                                          pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                            i_prof,
                                                                                                            ei.id_dep_clin_serv,
                                                                                                            e.flg_ehr,
                                                                                                            pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                            e.flg_ehr)),
                                                                          i_lang)) img_state,
                                       pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                               i_prof                      => i_prof,
                                                               i_waiting_room_available    => l_waiting_room_available,
                                                               i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                               i_id_episode                => ei.id_episode,
                                                               i_flg_state                 => sp.flg_state,
                                                               i_flg_ehr                   => e.flg_ehr,
                                                               i_id_dcs_requested          => s.id_dcs_requested) wr_call
                                  FROM schedule_outp sp
                                  JOIN schedule s
                                    ON s.id_schedule = sp.id_schedule
                                  JOIN sch_prof_outp ps
                                    ON sp.id_schedule_outp = ps.id_schedule_outp
                                  JOIN professional p
                                    ON p.id_professional = ps.id_professional
                                  JOIN sch_group sg
                                    ON sg.id_schedule = sp.id_schedule
                                  JOIN sch_event se
                                    ON s.id_sch_event = se.id_sch_event
                                  LEFT JOIN epis_info ei
                                    ON s.id_schedule = ei.id_schedule
                                   AND ei.id_patient = sg.id_patient
                                  JOIN dep_clin_serv dcs
                                    ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                                  JOIN patient pat
                                    ON pat.id_patient = sg.id_patient
                                  JOIN clinical_service cs
                                    ON cs.id_clinical_service = dcs.id_clinical_service
                                
                                  LEFT JOIN episode e
                                    ON ei.id_episode = e.id_episode
                                   AND e.flg_status != g_epis_canc
                                   AND e.flg_ehr != g_flg_ehr
                                   AND e.id_patient = ei.id_patient
                                  LEFT JOIN grid_task gt
                                    ON e.id_episode = gt.id_episode
                                  LEFT JOIN discharge d
                                    ON e.id_episode = d.id_episode
                                   AND d.dt_cancel_tstz IS NULL
                                  JOIN prof_cat pc
                                    ON p.id_professional = pc.id_professional
                                  JOIN category c
                                    ON pc.id_category = c.id_category
                                 WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                                   AND sp.id_software = i_prof.software
                                   AND s.id_instit_requested = i_prof.institution
                                   AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                                   AND (sp.id_epis_type = g_epis_type_nurse OR
                                       (s.flg_status != g_sched_canc AND e.dt_cancel_tstz IS NULL))
                                   AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                                       decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                                       l_show_nurse_disch = g_yes)
                                   AND (l_show_med_disch = g_yes OR
                                       (l_show_med_disch = g_no AND
                                       pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
                                   AND pc.id_institution = i_prof.institution
                                   AND EXISTS
                                 (SELECT 0
                                          FROM prof_room pr
                                         WHERE pr.id_professional = i_prof.id
                                           AND ei.id_room = pr.id_room)
                                   AND (l_use_team_filter = g_no OR
                                       ps.id_professional IN (SELECT /*+OPT_ESTIMATE (TABLE k ROWS=0.00000000001)*/
                                                                k.column_value
                                                                 FROM TABLE(l_professional_ids) k))
                                   AND (sp.id_epis_type = g_epis_type_nurse OR (ei.id_episode IS NOT NULL))
                                   AND se.flg_is_group = pk_alert_constant.g_no) dt
                        --group elements
                        UNION ALL
                        SELECT dt.id_schedule,
                               dt.id_patient,
                               dt.id_episode id_episode,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = dt.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND cr.flg_status = pk_alert_constant.g_active
                                   AND rownum < 2) num_proc,
                               dt.name,
                               dt.name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, dt.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, dt.id_patient) pat_nd_icon,
                               pk_sysdomain.get_domain(g_domain_pat_gender_abbr, gender, i_lang) gender,
                               pk_patient.get_pat_age(i_lang, dt.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) photo,
                               pk_translation.get_translation(i_lang, dt.code_clinical_service) cons_type,
                               decode(dt.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(dt.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_target_tstz, i_prof) dt_target,
                               decode(dt.flg_status,
                                      g_sched_canc,
                                      g_sched_canc,
                                      pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr)) flg_state,
                               dt.flg_sched,
                               pk_translation.get_translation(i_lang, dt.code_category) prof_cat,
                               dt.nick_name prof_name,
                               CASE
                                    WHEN dt.id_episode_ei IS NOT NULL THEN
                                     decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                            g_sched_scheduled,
                                            NULL,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             dt.dt_begin_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software))
                                    ELSE
                                     NULL
                                END dt_efectiv,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_begin_tstz, i_prof) dt_efectiv_compl,
                               dt.img_state,
                               decode(pk_grid.get_prioritary_task(i_lang,
                                                                  substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                                                  substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                                                  NULL,
                                                                  g_flg_doctor),
                                      substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                      pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.drug_presc),
                                      substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                      pk_grid.convert_grid_task_str(i_lang, i_prof, dt.drug_req)) desc_drug_vaccine_req,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  dt.icnp_intervention,
                                                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                                                              i_prof,
                                                                                                                              dt.nurse_activity,
                                                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                          i_prof,
                                                                                                                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                      i_prof,
                                                                                                                                                                                      dt.intervention,
                                                                                                                                                                                      dt.monitorization,
                                                                                                                                                                                      NULL,
                                                                                                                                                                                      g_flg_doctor),
                                                                                                                                                          dt.teach_req,
                                                                                                                                                          NULL,
                                                                                                                                                          g_flg_doctor),
                                                                                                                              NULL,
                                                                                                                              g_flg_doctor),
                                                                                                  NULL,
                                                                                                  g_flg_doctor)) desc_nur_interv_monit_tea,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               g_sysdate_char dt_server,
                               NULL room, --nvl(dt.desc_room, get_room_desc(i_lang, dt.sch_room)) room,
                               dt.wr_call,
                               decode(dt.id_epis_type, g_epis_type_nurse, g_yes, g_no) flg_nurse,
                               decode(dt.id_epis_type,
                                      g_epis_type_nurse,
                                      decode(dt.flg_status, g_sched_canc, g_no, g_yes),
                                      g_yes) flg_button_ok,
                               decode(l_cancel_sched,
                                      g_yes,
                                      decode(dt.id_epis_type,
                                             g_epis_type_nurse,
                                             decode(decode(dt.flg_status,
                                                           g_sched_canc,
                                                           g_sched_canc,
                                                           pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr)),
                                                    g_nurse_scheduled,
                                                    g_yes,
                                                    g_no),
                                             g_no),
                                      g_no) flg_button_cancel,
                               decode(dt.id_epis_type,
                                      g_epis_type_nurse,
                                      decode(dt.flg_status, g_sched_canc, g_yes, g_no),
                                      g_no) flg_button_detail,
                               decode(dt.flg_status, g_sched_canc, g_yes, g_no) flg_cancel,
                               pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.movement) desc_mov,
                               resp_icon,
                               desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  dt.id_patient,
                                                                  decode(dt.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_scheduled,
                                                                         NULL,
                                                                         dt.id_episode)) designated_provider,
                               dt.flg_contact_type,
                               pk_sysdomain.get_img(i_lang, g_domain_sch_presence, dt.flg_contact_type) icon_contact_type,
                               decode(dt.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               dt.dt_target_tstz,
                               dt.id_group,
                               pk_alert_constant.g_no flg_group_header,
                               'ExtendIcon' extend_icon,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_alert_constant.g_no prof_follow_remove
                          FROM (SELECT s.id_schedule,
                                       e.flg_ehr,
                                       e.id_episode,
                                       pat.id_patient,
                                       sp.dt_target_tstz,
                                       pk_patient.get_pat_name(i_lang,
                                                               i_prof,
                                                               pat.id_patient,
                                                               e.id_episode,
                                                               s.id_schedule) name,
                                       pk_patient.get_pat_name_to_sort(i_lang,
                                                                       i_prof,
                                                                       pat.id_patient,
                                                                       e.id_episode,
                                                                       s.id_schedule) name_to_sort,
                                       pat.gender,
                                       cs.code_clinical_service,
                                       s.schedule_cancel_notes,
                                       s.flg_status,
                                       sp.flg_state,
                                       sp.flg_sched,
                                       c.code_category,
                                       p.nick_name,
                                       ei.id_episode id_episode_ei,
                                       e.dt_begin_tstz,
                                       sp.id_epis_type,
                                       s.id_dcs_requested,
                                       gt.drug_presc,
                                       gt.drug_req,
                                       gt.icnp_intervention,
                                       gt.nurse_activity,
                                       gt.intervention,
                                       gt.monitorization,
                                       gt.teach_req,
                                       e.id_visit,
                                       s.schedule_cancel_notes canc_notes,
                                       e.flg_appointment_type,
                                       gt.movement,
                                       pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                                       s.id_room sch_room,
                                       NULL desc_room, --decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                                       sg.flg_contact_type,
                                       decode(sp.id_epis_type,
                                              g_epis_type_nurse,
                                              pk_sysdomain.get_ranked_img(g_schdl_nurse_state_domain,
                                                                          decode(s.flg_status,
                                                                                 g_sched_canc,
                                                                                 g_sched_canc,
                                                                                 pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                 e.flg_ehr)),
                                                                          i_lang),
                                              decode(s.flg_status,
                                                     g_sched_canc,
                                                     pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS',
                                                                                 s.flg_status,
                                                                                 i_lang),
                                                     pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                                                 pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                                   i_prof,
                                                                                                                   ei.id_dep_clin_serv,
                                                                                                                   e.flg_ehr,
                                                                                                                   pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                                   e.flg_ehr)),
                                                                                 i_lang))) img_state,
                                       pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                               i_prof                      => i_prof,
                                                               i_waiting_room_available    => l_waiting_room_available,
                                                               i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                               i_id_episode                => ei.id_episode,
                                                               i_flg_state                 => sp.flg_state,
                                                               i_flg_ehr                   => e.flg_ehr,
                                                               i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                                       s.id_group
                                  FROM schedule_outp sp
                                  JOIN schedule s
                                    ON s.id_schedule = sp.id_schedule
                                  JOIN sch_prof_outp ps
                                    ON sp.id_schedule_outp = ps.id_schedule_outp
                                  JOIN professional p
                                    ON p.id_professional = ps.id_professional
                                
                                  JOIN sch_group sg
                                    ON sg.id_schedule = sp.id_schedule
                                  LEFT JOIN epis_info ei
                                    ON s.id_schedule = ei.id_schedule
                                   AND ei.id_patient = sg.id_patient
                                  JOIN dep_clin_serv dcs
                                    ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                                  JOIN patient pat
                                    ON pat.id_patient = sg.id_patient
                                  JOIN clinical_service cs
                                    ON cs.id_clinical_service = dcs.id_clinical_service
                                
                                  LEFT JOIN episode e
                                    ON ei.id_episode = e.id_episode
                                  LEFT JOIN grid_task gt
                                    ON e.id_episode = gt.id_episode
                                  LEFT JOIN discharge d
                                    ON e.id_episode = d.id_episode
                                   AND d.dt_cancel_tstz IS NULL
                                  JOIN prof_cat pc
                                    ON p.id_professional = pc.id_professional
                                   AND pc.id_institution = i_prof.institution
                                  JOIN category c
                                    ON pc.id_category = c.id_category
                                 WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                                       d.column_value
                                                        FROM TABLE(l_group_ids) d)) dt
                        --group header
                        UNION ALL
                        SELECT NULL id_schedule, --dt.id_schedule,
                               NULL id_patient, --dt.id_patient,
                               NULL id_episode, --decode(dt.flg_ehr, pk_ehr_access.g_flg_ehr_scheduled, NULL, dt.id_episode) id_episode,
                               NULL num_proc, --(SELECT cr.num_clin_record FROM clin_record cr WHERE cr.id_patient = dt.id_patient AND cr.id_institution = i_prof.institution AND cr.flg_status = pk_alert_constant.g_active AND rownum < 2) num_proc,
                               l_sch_t640 name, --dt.name,
                               l_sch_t640 name_to_sort, -- dt.name_to_sort,
                               NULL pat_ndo, -- pk_adt.get_pat_non_disc_options(i_lang, i_prof, dt.id_patient) pat_ndo,
                               NULL pat_nd_icon, -- pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, dt.id_patient) pat_nd_icon,
                               NULL gender, -- pk_sysdomain.get_domain(g_domain_pat_gender_abbr, gender, i_lang) gender,
                               NULL pat_age, -- pk_patient.get_pat_age(i_lang, dt.id_patient, i_prof) pat_age,
                               NULL photo, -- pk_patphoto.get_pat_photo(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) photo,
                               pk_translation.get_translation(i_lang, dt.code_clinical_service) cons_type,
                               decode(dt.id_episode,
                                      NULL,
                                      '',
                                      pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                              nvl(dt.flg_appointment_type, g_null_appointment_type),
                                                              i_lang)) cont_type,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_target_tstz, i_prof) dt_target,
                               dt.flg_state flg_state,
                               dt.flg_sched,
                               pk_translation.get_translation(i_lang, dt.code_category) prof_cat,
                               dt.nick_name prof_name,
                               CASE
                                    WHEN dt.id_episode_ei IS NOT NULL THEN
                                     decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                            g_sched_scheduled,
                                            NULL,
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             dt.dt_begin_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software))
                                    ELSE
                                     NULL
                                END dt_efectiv,
                               pk_date_utils.date_send_tsz(i_lang, dt.dt_begin_tstz, i_prof) dt_efectiv_compl,
                               dt.img_state,
                               decode(pk_grid.get_prioritary_task(i_lang,
                                                                  substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                                                  substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                                                  NULL,
                                                                  g_flg_doctor),
                                      substr(dt.drug_presc, instr(dt.drug_presc, '|') + 1),
                                      pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.drug_presc),
                                      substr(dt.drug_req, instr(dt.drug_req, '|') + 1),
                                      pk_grid.convert_grid_task_str(i_lang, i_prof, dt.drug_req)) desc_drug_vaccine_req,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  dt.icnp_intervention,
                                                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                                                              i_prof,
                                                                                                                              dt.nurse_activity,
                                                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                          i_prof,
                                                                                                                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                      i_prof,
                                                                                                                                                                                      dt.intervention,
                                                                                                                                                                                      dt.monitorization,
                                                                                                                                                                                      NULL,
                                                                                                                                                                                      g_flg_doctor),
                                                                                                                                                          dt.teach_req,
                                                                                                                                                          NULL,
                                                                                                                                                          g_flg_doctor),
                                                                                                                              NULL,
                                                                                                                              g_flg_doctor),
                                                                                                  NULL,
                                                                                                  g_flg_doctor)) desc_nur_interv_monit_tea,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 dt.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               g_sysdate_char dt_server,
                               nvl(dt.desc_room, get_room_desc(i_lang, dt.sch_room)) room,
                               dt.wr_call,
                               decode(dt.id_epis_type, g_epis_type_nurse, g_yes, g_no) flg_nurse,
                               g_no flg_button_ok,
                               decode(l_cancel_sched,
                                      g_yes,
                                      decode(dt.id_epis_type,
                                             g_epis_type_nurse,
                                             decode(decode(dt.flg_status,
                                                           g_sched_canc,
                                                           g_sched_canc,
                                                           pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr)),
                                                    g_nurse_scheduled,
                                                    g_yes,
                                                    g_no),
                                             g_no),
                                      g_no) flg_button_cancel,
                               g_no flg_button_detail,
                               decode(dt.flg_status, g_sched_canc, g_yes, g_no) flg_cancel,
                               pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.movement) desc_mov,
                               resp_icon,
                               desc_room,
                               pk_patient.get_designated_provider(i_lang,
                                                                  i_prof,
                                                                  dt.id_patient,
                                                                  decode(dt.flg_ehr,
                                                                         pk_ehr_access.g_flg_ehr_scheduled,
                                                                         NULL,
                                                                         dt.id_episode)) designated_provider,
                               NULL flg_contact_type, --sg.flg_contact_type,
                               get_group_presence_icon(i_lang, i_prof, dt.id_group, pk_alert_constant.g_no) icon_contact_type,
                               decode(dt.flg_status,
                                      g_sched_canc,
                                      3,
                                      decode(pk_grid.get_schedule_real_state(dt.flg_state, dt.flg_ehr),
                                             g_sched_med_disch,
                                             2,
                                             1)) order_state,
                               dt.dt_target_tstz,
                               dt.id_group,
                               pk_alert_constant.g_yes flg_group_header,
                               NULL extend_icon,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_alert_constant.g_no prof_follow_remove
                          FROM (SELECT s.id_schedule,
                                       e.flg_ehr,
                                       e.id_episode,
                                       pat.id_patient,
                                       sp.dt_target_tstz,
                                       pk_patient.get_pat_name(i_lang,
                                                               i_prof,
                                                               pat.id_patient,
                                                               e.id_episode,
                                                               s.id_schedule) name,
                                       pk_patient.get_pat_name_to_sort(i_lang,
                                                                       i_prof,
                                                                       pat.id_patient,
                                                                       e.id_episode,
                                                                       s.id_schedule) name_to_sort,
                                       pat.gender,
                                       cs.code_clinical_service,
                                       s.schedule_cancel_notes,
                                       s.flg_status,
                                       'A' flg_state,
                                       sp.flg_sched,
                                       c.code_category,
                                       p.nick_name,
                                       ei.id_episode id_episode_ei,
                                       e.dt_begin_tstz,
                                       sp.id_epis_type,
                                       s.id_dcs_requested,
                                       gt.drug_presc,
                                       gt.drug_req,
                                       gt.icnp_intervention,
                                       gt.nurse_activity,
                                       gt.intervention,
                                       gt.monitorization,
                                       gt.teach_req,
                                       e.id_visit,
                                       s.schedule_cancel_notes canc_notes,
                                       e.flg_appointment_type,
                                       gt.movement,
                                       pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                                       s.id_room sch_room,
                                       decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                                       sg.flg_contact_type,
                                       get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                                       pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                               i_prof                      => i_prof,
                                                               i_waiting_room_available    => l_waiting_room_available,
                                                               i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                               i_id_episode                => ei.id_episode,
                                                               i_flg_state                 => sp.flg_state,
                                                               i_flg_ehr                   => e.flg_ehr,
                                                               i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                                       s.id_group
                                  FROM schedule_outp sp
                                  JOIN schedule s
                                    ON s.id_schedule = sp.id_schedule
                                  JOIN sch_prof_outp ps
                                    ON sp.id_schedule_outp = ps.id_schedule_outp
                                  JOIN professional p
                                    ON p.id_professional = ps.id_professional
                                  JOIN sch_group sg
                                    ON sg.id_schedule = sp.id_schedule
                                  LEFT JOIN epis_info ei
                                    ON s.id_schedule = ei.id_schedule
                                   AND ei.id_patient = sg.id_patient
                                  JOIN dep_clin_serv dcs
                                    ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                                  JOIN patient pat
                                    ON pat.id_patient = sg.id_patient
                                  JOIN clinical_service cs
                                    ON cs.id_clinical_service = dcs.id_clinical_service
                                
                                  LEFT JOIN episode e
                                    ON ei.id_episode = e.id_episode
                                  LEFT JOIN grid_task gt
                                    ON e.id_episode = gt.id_episode
                                  LEFT JOIN discharge d
                                    ON e.id_episode = d.id_episode
                                   AND d.dt_cancel_tstz IS NULL
                                  JOIN prof_cat pc
                                    ON p.id_professional = pc.id_professional
                                   AND pc.id_institution = i_prof.institution
                                  JOIN category c
                                    ON pc.id_category = c.id_category
                                 WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                                          d.column_value
                                                           FROM TABLE(l_schedule_ids) d)) dt
                        --
                        ) t
                 ORDER BY t.order_state, t.dt_target_tstz;
        ELSE
            pk_types.open_my_cursor(o_doc);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'NURSE_EFECTIV_CARE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END nurse_efectiv_care;

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
    ) RETURN BOOLEAN IS
        l_use_team_filter           sys_config.value%TYPE;
        l_epis_type                 schedule_outp.id_epis_type%TYPE;
        l_waiting_room_available    sys_config.value%TYPE;
        l_professional_ids          table_number := table_number();
        l_waiting_room_sys_external sys_config.value%TYPE := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM',
                                                                                     i_prof);
    BEGIN
        g_error                  := 'GET configs';
        g_sysdate_tstz           := current_timestamp;
        g_sysdate_char           := pk_date_utils.date_send_tsz(i_lang => i_lang,
                                                                i_date => g_sysdate_tstz,
                                                                i_prof => i_prof);
        g_epis_type_nurse        := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
        l_use_team_filter        := pk_sysconfig.get_config('ENABLE_TEAM_FILTER_GRID', i_prof);
        l_epis_type              := pk_sysconfig.get_config('EPIS_TYPE', i_prof);
        l_waiting_room_available := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
    
        l_professional_ids := get_prof_team_det(i_prof);
    
        g_error := 'OPEN o_doc';
        OPEN o_doc FOR
            SELECT dt.id_schedule,
                   dt.id_patient,
                   dt.id_episode,
                   (SELECT cr.num_clin_record
                      FROM clin_record cr
                     WHERE cr.id_patient = dt.id_patient
                       AND cr.id_institution = i_prof.institution
                       AND rownum < 2) num_proc,
                   pk_patient.get_pat_name(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, dt.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, dt.id_patient) pat_nd_icon,
                   dt.gender,
                   pk_patient.get_pat_age(i_lang, dt.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, dt.id_patient, dt.id_episode, dt.id_schedule) photo,
                   (SELECT pk_episode.get_cs_desc(i_lang, i_prof, dt.id_episode)
                      FROM dual) cons_type,
                   (SELECT pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                   nvl(dt.flg_appointment_type, g_null_appointment_type),
                                                   i_lang)
                      FROM dual) cont_type,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt.dt_begin_tstz, i_prof) dt_last_contact,
                   dt.flg_state,
                   dt.flg_sched,
                   decode(dt.id_epis_type,
                          g_epis_type_nurse,
                          pk_sysdomain.get_ranked_img(g_schdl_nurse_state_domain, dt.flg_state, i_lang),
                          pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                      pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                        i_prof,
                                                                                        dt.id_dep_clin_serv,
                                                                                        dt.flg_ehr,
                                                                                        dt.flg_state),
                                                      i_lang)) img_state,
                   decode(dt.drug_presc,
                          NULL,
                          NULL,
                          pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.gt_drug_presc)) drug_presc,
                   decode(dt.interv_presc,
                          NULL,
                          NULL,
                          pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.gt_interv_presc)) interv_presc,
                   decode(dt.monit, NULL, NULL, pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.gt_monit)) monit,
                   decode(dt.nurse_act,
                          NULL,
                          NULL,
                          pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, dt.gt_nurse_act)) nurse_act,
                   NULL icnp_interv_presc,
                   g_sysdate_char dt_server,
                   get_room_desc(i_lang, dt.id_room) room,
                   dt.wr_call,
                   decode(dt.id_epis_type, g_epis_type_nurse, g_yes, g_no) flg_nurse,
                   g_yes flg_button_ok,
                   g_no flg_button_cancel,
                   g_no flg_button_detail,
                   g_no flg_cancel,
                   dt.flg_contact_type,
                   (SELECT pk_sysdomain.get_img(i_lang, g_domain_sch_presence, dt.flg_contact_type)
                      FROM dual) icon_contact_type
              FROM ( -- tasks to execute on episode of request
                    SELECT s.id_schedule,
                            sg.id_patient,
                            e.id_episode,
                            p.gender,
                            sp.id_epis_type,
                            pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) flg_state,
                            sp.flg_sched,
                            --s.id_dcs_requested,
                            ei.id_dep_clin_serv,
                            e.flg_ehr,
                            e.dt_begin_tstz,
                            e.flg_appointment_type,
                            nvl(ei.id_room, s.id_room) id_room,
                            sg.flg_contact_type,
                            decode(gtb.flg_drug, g_yes, pk_grid.exist_prescription(i_lang, i_prof, e.id_episode, 'D')) drug_presc,
                            gt.drug_presc gt_drug_presc,
                            --NULL interv_presc,
                            --NULL gt_interv_presc,
                            decode(gtb.flg_interv, g_yes, pk_grid.exist_prescription(i_lang, i_prof, e.id_episode, 'I')) interv_presc,
                            gt.intervention gt_interv_presc,
                            decode(gtb.flg_monitor, g_yes, pk_grid.exist_prescription(i_lang, i_prof, e.id_episode, 'M')) monit,
                            gt.monitorization gt_monit,
                            decode(gtb.flg_nurse_act, g_yes, pk_grid.exist_prescription(i_lang, i_prof, e.id_episode, 'N')) nurse_act,
                            gt.nurse_activity gt_nurse_act,
                            pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                    i_prof                      => i_prof,
                                                    i_waiting_room_available    => l_waiting_room_available,
                                                    i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                    i_id_episode                => ei.id_episode,
                                                    i_flg_state                 => sp.flg_state,
                                                    i_flg_ehr                   => e.flg_ehr,
                                                    i_id_dcs_requested          => s.id_dcs_requested) wr_call
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON sp.id_schedule = s.id_schedule
                      JOIN sch_group sg
                        ON sp.id_schedule = sg.id_schedule
                      JOIN epis_info ei
                        ON sp.id_schedule = ei.id_schedule
                      JOIN sch_prof_outp ps
                        ON sp.id_schedule_outp = ps.id_schedule_outp
                      JOIN prof_dep_clin_serv pdcs
                        ON ei.id_dep_clin_serv = pdcs.id_dep_clin_serv
                       AND s.id_instit_requested = pdcs.id_institution
                      JOIN patient p
                        ON sg.id_patient = p.id_patient
                    
                      JOIN episode e
                        ON ei.id_episode = e.id_episode
                      JOIN grid_task_between gtb
                        ON ei.id_episode = gtb.id_episode
                      JOIN grid_task gt
                        ON ei.id_episode = gt.id_episode
                     WHERE sp.id_software = i_prof.software
                       AND s.flg_status != pk_schedule.g_sched_status_cache -- agendamentos temporários (SCH 3.0)
                       AND s.id_instit_requested = i_prof.institution
                       AND sp.id_epis_type IN (l_epis_type, g_epis_type_nurse)
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                       AND e.flg_ehr IN (pk_visit.g_flg_ehr_n, pk_visit.g_flg_ehr_s)
                       AND e.flg_status IN
                           (pk_alert_constant.g_epis_status_active, pk_alert_constant.g_epis_status_inactive)
                       AND (l_use_team_filter = g_no OR
                           ps.id_professional IN (SELECT /*+OPT_ESTIMATE (TABLE k ROWS=0.00000000001)*/
                                                    k.column_value
                                                     FROM TABLE(l_professional_ids) k))
                    UNION ALL
                    -- tasks to execute on intervention episodes
                    SELECT ei.id_schedule,
                            p.id_patient,
                            e.id_episode,
                            p.gender,
                            e.id_epis_type,
                            NULL flg_state,
                            NULL flg_sched,
                            ei.id_dcs_requested,
                            e.flg_ehr,
                            e.dt_begin_tstz,
                            e.flg_appointment_type,
                            ei.id_room,
                            NULL flg_contact_type,
                            NULL drug_presc,
                            NULL gt_drug_presc,
                            decode(gtb.flg_interv, g_yes, pk_grid.exist_prescription(i_lang, i_prof, e.id_episode, 'I')) interv_presc,
                            gt.intervention gt_interv_presc,
                            NULL monit,
                            NULL gt_monit,
                            NULL nurse_act,
                            NULL gt_nurse_act,
                            pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                    i_prof                      => i_prof,
                                                    i_waiting_room_available    => l_waiting_room_available,
                                                    i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                    i_id_episode                => ei.id_episode,
                                                    i_flg_state                 => sp.flg_state,
                                                    i_flg_ehr                   => e.flg_ehr,
                                                    i_id_dcs_requested          => s.id_dcs_requested) wr_call
                      FROM episode e
                      JOIN epis_info ei
                        ON e.id_episode = ei.id_episode
                      JOIN patient p
                        ON e.id_patient = p.id_patient
                      JOIN grid_task_between gtb
                        ON e.id_episode = gtb.id_episode
                      JOIN grid_task gt
                        ON e.id_episode = gt.id_episode
                      LEFT JOIN schedule s
                        ON ei.id_schedule = s.id_schedule
                      LEFT JOIN schedule_outp sp
                        ON sp.id_schedule = s.id_schedule
                     WHERE e.id_epis_type = pk_procedures_constant.g_episode_type_interv
                       AND e.flg_ehr IN (pk_visit.g_flg_ehr_n, pk_visit.g_flg_ehr_s)
                       AND e.flg_status = pk_alert_constant.g_epis_status_active
                       AND e.id_institution = i_prof.institution
                       AND ei.id_software = i_prof.software) dt
             WHERE dt.drug_presc IS NOT NULL
                OR dt.interv_presc IS NOT NULL
                OR dt.monit IS NOT NULL
                OR dt.nurse_act IS NOT NULL
             ORDER BY pk_grid.min_dt_treatment(i_lang, i_prof, dt.id_episode);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'NURSE_PRESC_BETW_CARE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END nurse_presc_betw_care;

    /********************************************************************************************
    * Returns extense day description
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
    ) RETURN VARCHAR2 IS
    
        l_day_index   INTEGER;
        l_month_index INTEGER;
        l_day_desc    VARCHAR2(200);
        l_month_desc  VARCHAR2(200);
        l_day_num     VARCHAR2(200);
        l_year_num    VARCHAR2(200);
    
    BEGIN
        l_day_index   := pk_date_utils.week_day_standard(i_date => to_timestamp_tz(i_date, 'yyyymmddhh24miss'));
        l_month_index := to_char(to_date(i_date, 'yyyymmddhh24miss'), 'MM');
    
        l_day_num  := to_char(to_date(i_date, 'yyyymmddhh24miss'), 'dd');
        l_year_num := to_char(to_date(i_date, 'yyyymmddhh24miss'), 'yyyy');
    
        --------------------------------------------------------------------
        -- day name by index
        CASE l_day_index
            WHEN 1 THEN
                l_day_desc := pk_message.get_message(i_lang, 'SCH_MONTHVIEW_SEG');
            WHEN 2 THEN
                l_day_desc := pk_message.get_message(i_lang, 'SCH_MONTHVIEW_TER');
            WHEN 3 THEN
                l_day_desc := pk_message.get_message(i_lang, 'SCH_MONTHVIEW_QUA');
            WHEN 4 THEN
                l_day_desc := pk_message.get_message(i_lang, 'SCH_MONTHVIEW_QUI');
            WHEN 5 THEN
                l_day_desc := pk_message.get_message(i_lang, 'SCH_MONTHVIEW_SEX');
            WHEN 6 THEN
                l_day_desc := pk_message.get_message(i_lang, 'SCH_MONTHVIEW_SAB');
            WHEN 7 THEN
                l_day_desc := pk_message.get_message(i_lang, 'SCH_MONTHVIEW_DOM');
            ELSE
                RETURN NULL;
        END CASE;
    
        --------------------------------------------------------------------
        -- month name by index
        l_month_desc := pk_message.get_message(i_lang, 'SCH_MONTH_' || l_month_index);
    
        --------------------------------------------------------------------
        -- return result
        RETURN l_day_desc || ', ' || l_day_num || ' ' || l_month_desc || ' ' || l_year_num;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_extense_day_desc;

    /******************************************************************************
       OBJECTIVO:   Grelha do médico, para ver consultas agendadas
              e já efectivadas
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                             I_EPIS_TYPE - Tipo de episódio (CE, URG, ...)
             I_PROF - prof q acede
             I_DT - data
             I_TYPE - tipo de pesquisa: D - consultas agendadas para o médico,
                          C - consultas agendadas para os serv. clínicos do médico
             I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                   como é retornada em PK_LOGIN.GET_PROF_PREF
                    SAIDA:   O_DOC - array
                             O_ERROR - erro
    
      CRIAÇÃO: CRS 2005/04/20
      ALTERAÇÃO: CRS 2006/07/20 Excluir episódios cancelados
                 LG 2007/05/30 Devolve dois novos campos, nome do médico e motivo de agendamento. Usado nas grelhas PP USA
                 RL 2007/11/23 Alterar para aparecerem os pacientes agendados para o dia para o médico, e não só os efectivados
                 Eduardo Lourenco 2007/11/23 Returns the reason notes from CONSULT_REQ or EPIS_COMPLAINT if none. 
      NOTAS: Nesta grelha visualizam-se os agendamentos do dia:
        - agendados para o médico e já efectivados, c/ ou s/ alta médica, sem
                alta administrativa ou com alta administrativa se ainda tiverem workflow pendente.
    *********************************************************************************/

    -- **********************************************
    FUNCTION get_group_ids_old
    (
        i_prof IN profissional,
        i_dt01 IN schedule_outp.dt_target_tstz%TYPE,
        i_dt09 IN schedule_outp.dt_target_tstz%TYPE
    ) RETURN table_number IS
        l_return           table_number;
        l_id_dcs           table_number;
        l_show_nurse_disch VARCHAR2(1000 CHAR);
        l_show_med_disch   VARCHAR2(1000 CHAR);
        l_epis_type_nurse  VARCHAR2(1000 CHAR);
        l_dt_min           schedule_outp.dt_target_tstz%TYPE;
        l_dt_max           schedule_outp.dt_target_tstz%TYPE;
    BEGIN
    
        l_dt_min := i_dt01;
        l_dt_max := i_dt09;
    
        --l_sch_t640 := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
        l_show_nurse_disch := nvl(pk_sysconfig.get_config('SHOW_NURSE_DISCHARGED_GRID', i_prof), g_no);
        l_show_med_disch   := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID', i_prof), g_yes);
        --l_waiting_room_sys_external  := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM', i_prof);
    
        l_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        SELECT DISTINCT s.id_group
          BULK COLLECT
          INTO l_return
          FROM schedule_outp sp
          JOIN schedule s
            ON s.id_schedule = sp.id_schedule
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
          LEFT JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
          LEFT JOIN episode e
            ON e.id_episode = ei.id_episode
           AND e.flg_ehr != g_flg_ehr
          LEFT JOIN grid_task gt
            ON gt.id_episode = ei.id_episode
         WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
           AND sp.id_software = i_prof.software
              -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico
           AND sp.id_epis_type != l_epis_type_nurse
           AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
           AND s.id_instit_requested = i_prof.institution
           AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
           AND EXISTS (SELECT 0
                  FROM prof_dep_clin_serv pdcs
                 WHERE pdcs.id_professional = i_prof.id
                   AND pdcs.flg_status = g_selected
                   AND pdcs.id_dep_clin_serv = ei.id_dep_clin_serv)
           AND 1 = decode(ei.id_episode,
                          NULL,
                          1,
                          (SELECT COUNT(0)
                             FROM episode epis
                            WHERE epis.flg_status != g_epis_canc
                              AND epis.id_episode = ei.id_episode))
           AND se.flg_is_group = pk_alert_constant.g_yes
           AND s.id_group IS NOT NULL
           AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
               decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
               l_show_nurse_disch = g_yes)
           AND (l_show_med_disch = g_yes OR
               (l_show_med_disch = g_no AND
               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch));
    
        RETURN l_return;
    
    END get_group_ids_old;

    -- *********************************************************************
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
    ) RETURN BOOLEAN IS
    
        l_waiting_room_available sys_config.value%TYPE;
        l_sysdate_char_short     VARCHAR2(8);
        l_dt_min                 schedule_outp.dt_target_tstz%TYPE;
        l_dt_max                 schedule_outp.dt_target_tstz%TYPE;
    
        --variavel que indica de nos devemos deslocar para a area antiga quando estamos em episódios não efectivados
        l_to_old_area             VARCHAR2(1);
        l_reasongrid              VARCHAR2(1);
        l_therap_decision_consult translation.code_translation%TYPE;
        l_no_present_patient      sys_message.desc_message%TYPE;
        l_handoff_type            sys_config.value%TYPE;
        l_config_show_resident CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
        l_show_resident_physician   sys_config.value%TYPE;
        l_group_ids                 table_number := table_number();
        l_schedule_ids              table_number := table_number();
        l_sch_t640                  sys_message.desc_message%TYPE;
        l_id_category               category.id_category%TYPE;
        l_type_appoint_edition      VARCHAR2(1 CHAR);
        l_show_nurse_disch          sys_config.value%TYPE;
        l_show_med_disch            sys_config.value%TYPE;
        l_waiting_room_sys_external sys_config.value%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        l_sch_t640                  := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
        l_show_nurse_disch          := nvl(pk_sysconfig.get_config('SHOW_NURSE_DISCHARGED_GRID', i_prof), g_no);
        l_show_med_disch            := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID', i_prof), g_yes);
        l_waiting_room_sys_external := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM', i_prof);
    
        ---------------------------------
        g_error := 'CALL get_date_bounds';
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        l_sysdate_char_short     := pk_date_utils.to_char_insttimezone(i_prof, g_sysdate_tstz, 'YYYYMMDD');
        g_error                  := 'GET configs';
        l_waiting_room_available := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
        --l_to_old_area            := pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof);
        l_reasongrid         := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID', i_prof);
        g_epis_type_nurse    := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
        l_no_present_patient := pk_message.get_message(i_lang, 'THERAPEUTIC_DECISION_T017');
        l_id_category        := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        IF instr(pk_sysconfig.get_config('ALLOW_MY_ROOM_SPECIALITY_GRID_TYPE_APPOINT_EDITION',
                                         i_prof.institution,
                                         i_prof.software),
                 '|' || l_id_category || '|') > 0
        THEN
            l_type_appoint_edition := pk_alert_constant.g_yes;
        ELSE
            l_type_appoint_edition := pk_alert_constant.g_no;
        END IF;
    
        -- Consultas de decisao terapeutica 
        SELECT pk_translation.get_translation(i_lang, se.code_sch_event_abrv)
          INTO l_therap_decision_consult
          FROM sch_event se
         WHERE se.id_sch_event = g_sch_event_therap_decision;
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => i_prof);
    
        g_error := 'OPEN o_doc - ' || i_type;
        IF i_type = g_type_my_appointments
        THEN
        
            SELECT DISTINCT s.id_group
              BULK COLLECT
              INTO l_group_ids
              FROM schedule_outp sp
              JOIN schedule s
                ON s.id_schedule = sp.id_schedule
              JOIN sch_group sg
                ON sg.id_schedule = s.id_schedule
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              LEFT JOIN epis_info ei
                ON ei.id_schedule = s.id_schedule
               AND ei.id_patient = sg.id_patient
              LEFT JOIN episode e
                ON e.id_episode = ei.id_episode
               AND e.flg_ehr != g_flg_ehr
              LEFT JOIN sch_prof_outp spo
                ON spo.id_schedule_outp = sp.id_schedule_outp
             WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                          g_sched_adm_disch,
                          get_grid_task_count(i_lang,
                                              i_prof,
                                              ei.id_episode,
                                              e.id_visit,
                                              i_prof_cat_type,
                                              l_sysdate_char_short),
                          1) = 1
               AND sp.id_software = i_prof.software
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico                     
               AND sp.id_epis_type != g_epis_type_nurse
               AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, g_sched_canc)
               AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
               AND s.id_instit_requested = i_prof.institution
               AND (pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                     i_prof,
                                                                                     ei.id_episode,
                                                                                     i_prof_cat_type,
                                                                                     l_handoff_type,
                                                                                     pk_alert_constant.g_yes),
                                                 i_prof.id) != -1 OR
                   (ei.id_professional IS NULL AND spo.id_professional = i_prof.id))
               AND se.flg_is_group = pk_alert_constant.g_yes
               AND s.id_group IS NOT NULL
               AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                   decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                   l_show_nurse_disch = g_yes)
               AND (l_show_med_disch = g_yes OR
                   (l_show_med_disch = g_no AND
                   pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch));
        
            l_schedule_ids := get_schedule_ids(l_group_ids);
        
            OPEN o_doc FOR
                SELECT t.id_schedule,
                       t.id_patient,
                       t.num_clin_record,
                       t.id_episode,
                       t.flg_ehr,
                       t.dt_efectiv,
                       t.name,
                       t.name_to_sort,
                       t.pat_ndo,
                       t.pat_nd_icon,
                       t.gender,
                       t.pat_age,
                       t.photo,
                       t.flg_contact,
                       t.cons_type,
                       t.dt_target,
                       t.dt_schedule_begin,
                       t.flg_state,
                       t.flg_sched,
                       t.img_state,
                       t.img_sched,
                       t.flg_temp,
                       t.dt_server,
                       t.desc_temp,
                       t.desc_drug_presc,
                       t.desc_interv_presc,
                       t.desc_analysis_req,
                       t.desc_exam_req,
                       t.rank,
                       wr_call(i_lang, i_prof, t.wr_call, i_dt) wr_call,
                       t.doctor_name,
                       nvl(t.reason, t.visit_reason) reason,
                       t.dt_begin,
                       t.visit_reason,
                       t.dt,
                       t.therapeutic_doctor,
                       t.patient_presence,
                       t.resp_icon,
                       t.desc_room,
                       pk_patient.get_designated_provider(i_lang, i_prof, t.id_patient, t.id_episode) designated_provider,
                       t.flg_contact_type,
                       CASE
                            WHEN t.flg_group_header = pk_alert_constant.g_yes THEN
                             get_group_presence_icon(i_lang, i_prof, t.id_group, pk_alert_constant.g_no)
                            ELSE
                             pk_sysdomain.get_img(i_lang, g_domain_sch_presence, t.flg_contact_type)
                        END icon_contact_type,
                       pk_sysdomain.get_domain(g_domain_sch_presence, t.flg_contact_type, i_lang) presence_desc,
                       t.name_prof,
                       t.name_nurse,
                       t.prof_team,
                       t.name_prof_tooltip,
                       t.name_nurse_tooltip,
                       t.prof_team_tooltip,
                       t.desc_ana_exam_req,
                       t.id_group,
                       t.flg_group_header,
                       t.extend_icon,
                       t.prof_follow_add,
                       t.prof_follow_remove,
                       t.sch_event_desc,
                       l_type_appoint_edition flg_type_appoint_edition --, t.id_epis_type
                  FROM (SELECT sp.id_epis_type,
                               s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode id_episode,
                               e.flg_ehr,
                               CASE
                                    WHEN ei.id_episode IS NOT NULL THEN
                                     decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                            g_sched_scheduled,
                                            '',
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             e.dt_begin_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software))
                                    ELSE
                                     NULL
                                END dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               pk_date_utils.date_char_tsz(i_lang,
                                                           sp.dt_target_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_schedule_begin,
                               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) flg_state,
                               sp.flg_sched,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                           pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                             i_prof,
                                                                                             ei.id_dep_clin_serv,
                                                                                             e.flg_ehr,
                                                                                             pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                             e.flg_ehr)),
                                                           i_lang) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               'N' flg_temp,
                               g_sysdate_char dt_server,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
                               
                               CASE
                                    WHEN gt.id_episode IS NOT NULL THEN
                                     pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                                    ELSE
                                     NULL
                                END desc_drug_presc,
                               CASE
                                    WHEN gt.id_episode IS NOT NULL THEN
                                     pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                            i_prof,
                                                                            pk_grid.get_prioritary_task(i_lang,
                                                                                                        i_prof,
                                                                                                        gt.icnp_intervention,
                                                                                                        pk_grid.get_prioritary_task(i_lang,
                                                                                                                                    i_prof,
                                                                                                                                    gt.nurse_activity,
                                                                                                                                    pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                i_prof,
                                                                                                                                                                pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                            i_prof,
                                                                                                                                                                                            gt.intervention,
                                                                                                                                                                                            gt.monitorization,
                                                                                                                                                                                            NULL,
                                                                                                                                                                                            g_flg_doctor),
                                                                                                                                                                gt.teach_req,
                                                                                                                                                                NULL,
                                                                                                                                                                g_flg_doctor),
                                                                                                                                    NULL,
                                                                                                                                    g_flg_doctor),
                                                                                                        NULL,
                                                                                                        g_flg_doctor))
                                    ELSE
                                     NULL
                                END desc_interv_presc,
                               CASE
                                    WHEN gt.id_episode IS NOT NULL THEN
                                     pk_grid.visit_grid_task_str(i_lang,
                                                                 i_prof,
                                                                 e.id_visit,
                                                                 g_task_analysis,
                                                                 i_prof_cat_type)
                                    ELSE
                                     NULL
                                END desc_analysis_req,
                               CASE
                                    WHEN gt.id_episode IS NOT NULL THEN
                                     pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_exam, i_prof_cat_type)
                                    ELSE
                                     NULL
                                END desc_exam_req,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_adm_disch,
                                      3,
                                      g_sched_med_disch,
                                      2,
                                      1) rank,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               -- Updated By Eduardo Lourenco
                               (SELECT substr(concatenate(decode(nvl(ec.id_complaint,
                                                                     decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                                 NULL,
                                                                 ec.patient_complaint,
                                                                 pk_translation.get_translation(i_lang,
                                                                                                'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                nvl(ec.id_complaint,
                                                                                                    decode(s2.flg_reason_type,
                                                                                                           'C',
                                                                                                           s2.id_reason,
                                                                                                           NULL)))) || '; '),
                                              1,
                                              length(concatenate(decode(nvl(ec.id_complaint,
                                                                            decode(s2.flg_reason_type,
                                                                                   'C',
                                                                                   s2.id_reason,
                                                                                   NULL)),
                                                                        NULL,
                                                                        ec.patient_complaint,
                                                                        pk_translation.get_translation(i_lang,
                                                                                                       'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                       nvl(ec.id_complaint,
                                                                                                           decode(s2.flg_reason_type,
                                                                                                                  'C',
                                                                                                                  s2.id_reason,
                                                                                                                  NULL))) || '; '))) -
                                              length('; '))
                                  FROM schedule s2
                                  LEFT JOIN epis_info ei2
                                    ON ei2.id_schedule = s2.id_schedule
                                  LEFT JOIN epis_complaint ec
                                    ON ec.id_episode = ei2.id_episode
                                 WHERE s2.id_schedule = s.id_schedule
                                   AND nvl(ec.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active) reason,
                               -----
                               CASE
                                    WHEN ei.id_episode IS NOT NULL THEN
                                     pk_date_utils.date_send_tsz(i_lang,
                                                                 decode(pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                        e.flg_ehr),
                                                                        g_sched_scheduled,
                                                                        NULL,
                                                                        e.dt_begin_tstz),
                                                                 i_prof.institution,
                                                                 i_prof.software)
                                    ELSE
                                     NULL
                                END dt_begin,
                               decode(l_reasongrid,
                                      g_yes,
                                      pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                  i_prof,
                                                                                                                  ei.id_episode,
                                                                                                                  s.id_schedule),
                                                                       4000)) visit_reason,
                               sp.dt_target_tstz dt,
                               NULL therapeutic_doctor,
                               decode(s.flg_present, 'N', l_no_present_patient) patient_presence,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               sg.flg_contact_type,
                               -- Display number of responsible PHYSICIANS for the episode, 
                               -- if institution is using the multiple hand-off mechanism,
                               -- along with the name of the main responsible for the patient.
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional, spo.id_professional),
                                                    l_handoff_type,
                                                    'G') name_prof,
                               -- Only display the name of the responsible nurse, for all hand-off mechanisms
                               pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                               -- Team name or Resident physician(s)
                               decode(l_show_resident_physician,
                                      pk_alert_constant.g_yes,
                                      pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                 i_prof,
                                                                                 ei.id_episode,
                                                                                 l_handoff_type,
                                                                                 pk_hand_off_core.g_resident,
                                                                                 'G'),
                                      pk_prof_teams.get_prof_current_team(i_lang,
                                                                          i_prof,
                                                                          e.id_department,
                                                                          ei.id_software,
                                                                          nvl(ei.id_professional, spo.id_professional),
                                                                          ei.id_first_nurse_resp)) prof_team,
                               
                               -- Display text in tooltips
                               -- 1) Responsible physician(s)
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional, spo.id_professional),
                                                    l_handoff_type,
                                                    'T') name_prof_tooltip,
                               -- 2) Responsible nurse
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_nurse,
                                                    ei.id_episode,
                                                    ei.id_first_nurse_resp,
                                                    l_handoff_type,
                                                    'T') name_nurse_tooltip,
                               -- 3) Responsible team 
                               pk_hand_off_core.get_team_str(i_lang,
                                                             i_prof,
                                                             e.id_department,
                                                             ei.id_software,
                                                             ei.id_professional,
                                                             ei.id_first_nurse_resp,
                                                             l_handoff_type,
                                                             NULL) prof_team_tooltip,
                               0 id_group,
                               pk_alert_constant.g_no flg_group_header,
                               NULL extend_icon,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove,
                               pk_schedule_common.get_translation_alias(i_lang,
                                                                        i_prof,
                                                                        se.id_sch_event,
                                                                        se.code_sch_event) sch_event_desc
                        
                        -- Only display the name of                               
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                          LEFT JOIN epis_info ei
                            ON ei.id_schedule = s.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON e.id_episode = ei.id_episode
                           AND e.flg_ehr != g_flg_ehr
                          LEFT JOIN sch_prof_outp spo
                            ON spo.id_schedule_outp = sp.id_schedule_outp
                          LEFT JOIN grid_task gt
                            ON gt.id_episode = ei.id_episode
                          LEFT JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                         WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                           AND decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_adm_disch,
                                      get_grid_task_count(i_lang,
                                                          i_prof,
                                                          ei.id_episode,
                                                          e.id_visit,
                                                          i_prof_cat_type,
                                                          l_sysdate_char_short),
                                      1) = 1
                           AND sp.id_software = i_prof.software
                              -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico                     
                           AND sp.id_epis_type != g_epis_type_nurse
                           AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, g_sched_canc)
                           AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                           AND s.id_instit_requested = i_prof.institution
                           AND (pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                 i_prof,
                                                                                                 ei.id_episode,
                                                                                                 i_prof_cat_type,
                                                                                                 l_handoff_type,
                                                                                                 pk_alert_constant.g_yes),
                                                             i_prof.id) != -1 OR
                               (ei.id_professional IS NULL AND spo.id_professional = i_prof.id) OR
                               (pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) =
                               pk_alert_constant.g_yes))
                           AND s.id_sch_event NOT IN (g_sch_event_therap_decision)
                           AND se.flg_is_group = pk_alert_constant.g_no
                        --
                        UNION ALL
                        -- group elements
                        SELECT sp.id_epis_type,
                               s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode id_episode,
                               e.flg_ehr,
                               CASE
                                   WHEN ei.id_episode IS NOT NULL THEN
                                    decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                           g_sched_scheduled,
                                           '',
                                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                                            e.dt_begin_tstz,
                                                                            i_prof.institution,
                                                                            i_prof.software))
                                   ELSE
                                    NULL
                               END dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               pk_date_utils.date_char_tsz(i_lang,
                                                           sp.dt_target_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_schedule_begin,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      g_sched_canc,
                                      pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                               sp.flg_sched,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS', s.flg_status, i_lang),
                                      pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                                  pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                    i_prof,
                                                                                                    ei.id_dep_clin_serv,
                                                                                                    e.flg_ehr,
                                                                                                    pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                    e.flg_ehr)),
                                                                  i_lang)) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               'N' flg_temp,
                               g_sysdate_char dt_server,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
                               
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                                   ELSE
                                    NULL
                               END desc_drug_presc,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                           i_prof,
                                                                           pk_grid.get_prioritary_task(i_lang,
                                                                                                       i_prof,
                                                                                                       gt.icnp_intervention,
                                                                                                       pk_grid.get_prioritary_task(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   gt.nurse_activity,
                                                                                                                                   pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                               i_prof,
                                                                                                                                                               pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                           i_prof,
                                                                                                                                                                                           gt.intervention,
                                                                                                                                                                                           gt.monitorization,
                                                                                                                                                                                           NULL,
                                                                                                                                                                                           g_flg_doctor),
                                                                                                                                                               gt.teach_req,
                                                                                                                                                               NULL,
                                                                                                                                                               g_flg_doctor),
                                                                                                                                   NULL,
                                                                                                                                   g_flg_doctor),
                                                                                                       NULL,
                                                                                                       g_flg_doctor))
                                   ELSE
                                    NULL
                               END desc_interv_presc,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.visit_grid_task_str(i_lang,
                                                                i_prof,
                                                                e.id_visit,
                                                                g_task_analysis,
                                                                i_prof_cat_type)
                                   ELSE
                                    NULL
                               END desc_analysis_req,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_exam, i_prof_cat_type)
                                   ELSE
                                    NULL
                               END desc_exam_req,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_adm_disch,
                                      3,
                                      g_sched_med_disch,
                                      2,
                                      1) rank,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               -- Updated By Eduardo Lourenco
                               (SELECT substr(concatenate(decode(nvl(ec.id_complaint,
                                                                     decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                                 NULL,
                                                                 ec.patient_complaint,
                                                                 pk_translation.get_translation(i_lang,
                                                                                                'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                nvl(ec.id_complaint,
                                                                                                    decode(s2.flg_reason_type,
                                                                                                           'C',
                                                                                                           s2.id_reason,
                                                                                                           NULL)))) || '; '),
                                              1,
                                              length(concatenate(decode(nvl(ec.id_complaint,
                                                                            decode(s2.flg_reason_type,
                                                                                   'C',
                                                                                   s2.id_reason,
                                                                                   NULL)),
                                                                        NULL,
                                                                        ec.patient_complaint,
                                                                        pk_translation.get_translation(i_lang,
                                                                                                       'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                       nvl(ec.id_complaint,
                                                                                                           decode(s2.flg_reason_type,
                                                                                                                  'C',
                                                                                                                  s2.id_reason,
                                                                                                                  NULL))) || '; '))) -
                                              length('; '))
                                  FROM schedule s2
                                  LEFT JOIN epis_info ei2
                                    ON ei2.id_schedule = s2.id_schedule
                                  LEFT JOIN epis_complaint ec
                                    ON ec.id_episode = ei2.id_episode
                                 WHERE s2.id_schedule = s.id_schedule
                                   AND nvl(ec.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active) reason,
                               -----
                               CASE
                                   WHEN ei.id_episode IS NOT NULL THEN
                                    pk_date_utils.date_send_tsz(i_lang,
                                                                decode(pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                       e.flg_ehr),
                                                                       g_sched_scheduled,
                                                                       NULL,
                                                                       e.dt_begin_tstz),
                                                                i_prof.institution,
                                                                i_prof.software)
                                   ELSE
                                    NULL
                               END dt_begin,
                               decode(l_reasongrid,
                                      g_yes,
                                      pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                  i_prof,
                                                                                                                  ei.id_episode,
                                                                                                                  s.id_schedule),
                                                                       4000)) visit_reason,
                               sp.dt_target_tstz dt,
                               NULL therapeutic_doctor,
                               decode(s.flg_present, 'N', l_no_present_patient) patient_presence,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               NULL desc_room, --decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               sg.flg_contact_type,
                               -- Display number of responsible PHYSICIANS for the episode, 
                               -- if institution is using the multiple hand-off mechanism,
                               -- along with the name of the main responsible for the patient.
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional, spo.id_professional),
                                                    l_handoff_type,
                                                    'G') name_prof,
                               -- Only display the name of the responsible nurse, for all hand-off mechanisms
                               pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                               -- Team name or Resident physician(s)
                               decode(l_show_resident_physician,
                                      pk_alert_constant.g_yes,
                                      pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                 i_prof,
                                                                                 ei.id_episode,
                                                                                 l_handoff_type,
                                                                                 pk_hand_off_core.g_resident,
                                                                                 'G'),
                                      pk_prof_teams.get_prof_current_team(i_lang,
                                                                          i_prof,
                                                                          e.id_department,
                                                                          ei.id_software,
                                                                          nvl(ei.id_professional, spo.id_professional),
                                                                          ei.id_first_nurse_resp)) prof_team,
                               
                               -- Display text in tooltips
                               -- 1) Responsible physician(s)
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional, spo.id_professional),
                                                    l_handoff_type,
                                                    'T') name_prof_tooltip,
                               -- 2) Responsible nurse
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_nurse,
                                                    ei.id_episode,
                                                    ei.id_first_nurse_resp,
                                                    l_handoff_type,
                                                    'T') name_nurse_tooltip,
                               -- 3) Responsible team 
                               pk_hand_off_core.get_team_str(i_lang,
                                                             i_prof,
                                                             e.id_department,
                                                             ei.id_software,
                                                             ei.id_professional,
                                                             ei.id_first_nurse_resp,
                                                             l_handoff_type,
                                                             NULL) prof_team_tooltip,
                               s.id_group,
                               pk_alert_constant.g_no flg_group_header,
                               'ExtendIcon' extend_icon,
                               pk_alert_constant.get_no prof_follow_add,
                               pk_alert_constant.get_no prof_follow_remove,
                               pk_schedule_common.get_translation_alias(i_lang,
                                                                        i_prof,
                                                                        se.id_sch_event,
                                                                        se.code_sch_event) sch_event_desc
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          LEFT JOIN epis_info ei
                            ON ei.id_schedule = s.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON e.id_episode = ei.id_episode
                          LEFT JOIN sch_prof_outp spo
                            ON spo.id_schedule_outp = sp.id_schedule_outp
                          LEFT JOIN grid_task gt
                            ON gt.id_episode = ei.id_episode
                          LEFT JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                         WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                               d.column_value
                                                FROM TABLE(l_group_ids) d)
                           AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, g_sched_canc)
                        UNION ALL
                        -- group HEADER
                        SELECT sp.id_epis_type,
                               NULL id_schedule, --s.id_schedule,
                               NULL id_patient, -- sg.id_patient,
                               NULL num_clin_record, --(SELECT cr.num_clin_record FROM clin_record cr WHERE cr.id_patient = sg.id_patient AND cr.id_institution = i_prof.institution AND rownum < 2) num_clin_record,
                               NULL id_episode, --decode(e.flg_ehr,pk_ehr_access.g_flg_ehr_normal,ei.id_episode,decode(l_to_old_area, g_yes, NULL, ei.id_episode)) id_episode,
                               e.flg_ehr,
                               CASE
                                   WHEN ei.id_episode IS NOT NULL THEN
                                    decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                           g_sched_scheduled,
                                           '',
                                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                                            e.dt_begin_tstz,
                                                                            i_prof.institution,
                                                                            i_prof.software))
                                   ELSE
                                    NULL
                               END dt_efectiv,
                               l_sch_t640 name, -- pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               l_sch_t640 name_to_sort, --pk_patient.get_pat_name_to_sort(i_lang,i_prof,sg.id_patient,ei.id_episode,s.id_schedule) name_to_sort,
                               NULL pat_ndo, --pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               NULL pat_nd_icon, --pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               NULL gender, --(SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender FROM patient pat WHERE sg.id_patient = pat.id_patient) gender,
                               NULL pat_age, --pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               NULL photo, --pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               NULL flg_contact, --pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               pk_date_utils.date_char_tsz(i_lang,
                                                           sp.dt_target_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_schedule_begin,
                               'A' flg_state,
                               sp.flg_sched,
                               get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               'N' flg_temp,
                               g_sysdate_char dt_server,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
                               
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                                   ELSE
                                    NULL
                               END desc_drug_presc,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                           i_prof,
                                                                           pk_grid.get_prioritary_task(i_lang,
                                                                                                       i_prof,
                                                                                                       gt.icnp_intervention,
                                                                                                       pk_grid.get_prioritary_task(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   gt.nurse_activity,
                                                                                                                                   pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                               i_prof,
                                                                                                                                                               pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                           i_prof,
                                                                                                                                                                                           gt.intervention,
                                                                                                                                                                                           gt.monitorization,
                                                                                                                                                                                           NULL,
                                                                                                                                                                                           g_flg_doctor),
                                                                                                                                                               gt.teach_req,
                                                                                                                                                               NULL,
                                                                                                                                                               g_flg_doctor),
                                                                                                                                   NULL,
                                                                                                                                   g_flg_doctor),
                                                                                                       NULL,
                                                                                                       g_flg_doctor))
                                   ELSE
                                    NULL
                               END desc_interv_presc,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.visit_grid_task_str(i_lang,
                                                                i_prof,
                                                                e.id_visit,
                                                                g_task_analysis,
                                                                i_prof_cat_type)
                                   ELSE
                                    NULL
                               END desc_analysis_req,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_exam, i_prof_cat_type)
                                   ELSE
                                    NULL
                               END desc_exam_req,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_adm_disch,
                                      3,
                                      g_sched_med_disch,
                                      2,
                                      1) rank,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               -- Updated By Eduardo Lourenco
                               '' reason,
                               -----
                               CASE
                                   WHEN ei.id_episode IS NOT NULL THEN
                                    pk_date_utils.date_send_tsz(i_lang,
                                                                decode(pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                       e.flg_ehr),
                                                                       g_sched_scheduled,
                                                                       NULL,
                                                                       e.dt_begin_tstz),
                                                                i_prof.institution,
                                                                i_prof.software)
                                   ELSE
                                    NULL
                               END dt_begin,
                               '' visit_reason,
                               sp.dt_target_tstz dt,
                               NULL therapeutic_doctor,
                               decode(s.flg_present, 'N', l_no_present_patient) patient_presence,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               NULL flg_contact_type, --sg.flg_contact_type,
                               -- Display number of responsible PHYSICIANS for the episode, 
                               -- if institution is using the multiple hand-off mechanism,
                               -- along with the name of the main responsible for the patient.
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional, spo.id_professional),
                                                    l_handoff_type,
                                                    'G') name_prof,
                               -- Only display the name of the responsible nurse, for all hand-off mechanisms
                               pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                               -- Team name or Resident physician(s)
                               decode(l_show_resident_physician,
                                      pk_alert_constant.g_yes,
                                      pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                 i_prof,
                                                                                 ei.id_episode,
                                                                                 l_handoff_type,
                                                                                 pk_hand_off_core.g_resident,
                                                                                 'G'),
                                      pk_prof_teams.get_prof_current_team(i_lang,
                                                                          i_prof,
                                                                          e.id_department,
                                                                          ei.id_software,
                                                                          nvl(ei.id_professional, spo.id_professional),
                                                                          ei.id_first_nurse_resp)) prof_team,
                               
                               -- Display text in tooltips
                               -- 1) Responsible physician(s)
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional, spo.id_professional),
                                                    l_handoff_type,
                                                    'T') name_prof_tooltip,
                               -- 2) Responsible nurse
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_nurse,
                                                    ei.id_episode,
                                                    ei.id_first_nurse_resp,
                                                    l_handoff_type,
                                                    'T') name_nurse_tooltip,
                               -- 3) Responsible team 
                               pk_hand_off_core.get_team_str(i_lang,
                                                             i_prof,
                                                             e.id_department,
                                                             ei.id_software,
                                                             ei.id_professional,
                                                             ei.id_first_nurse_resp,
                                                             l_handoff_type,
                                                             NULL) prof_team_tooltip,
                               s.id_group,
                               pk_alert_constant.g_yes flg_group_header,
                               NULL extend_icon,
                               pk_alert_constant.get_no prof_follow_add,
                               pk_alert_constant.get_no prof_follow_remove,
                               pk_schedule_common.get_translation_alias(i_lang,
                                                                        i_prof,
                                                                        se.id_sch_event,
                                                                        se.code_sch_event) sch_event_desc
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          LEFT JOIN epis_info ei
                            ON ei.id_schedule = s.id_schedule
                           AND ei.id_patient = sg.id_patient
                          LEFT JOIN episode e
                            ON e.id_episode = ei.id_episode
                          LEFT JOIN sch_prof_outp spo
                            ON spo.id_schedule_outp = sp.id_schedule_outp
                          LEFT JOIN grid_task gt
                            ON gt.id_episode = ei.id_episode
                          LEFT JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                         WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                                  d.column_value
                                                   FROM TABLE(l_schedule_ids) d)
                        --
                        UNION ALL
                        SELECT sp.id_epis_type,
                               s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode id_episode,
                               e.flg_ehr,
                               CASE
                                   WHEN ei.id_episode IS NOT NULL THEN
                                    decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                           g_sched_scheduled,
                                           '',
                                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                                            e.dt_begin_tstz,
                                                                            i_prof.institution,
                                                                            i_prof.software))
                                   ELSE
                                    NULL
                               END dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                                  FROM dep_clin_serv dcs, clinical_service cs
                                 WHERE dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                                   AND cs.id_clinical_service = dcs.id_clinical_service) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               pk_date_utils.date_char_tsz(i_lang,
                                                           sp.dt_target_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_schedule_begin,
                               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) flg_state,
                               sp.flg_sched,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                           pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                             i_prof,
                                                                                             ei.id_dep_clin_serv,
                                                                                             e.flg_ehr,
                                                                                             pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                             e.flg_ehr)),
                                                           i_lang) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               'N' flg_temp,
                               g_sysdate_char dt_server,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
                               
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                                   ELSE
                                    NULL
                               END desc_drug_presc,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                           i_prof,
                                                                           pk_grid.get_prioritary_task(i_lang,
                                                                                                       i_prof,
                                                                                                       gt.icnp_intervention,
                                                                                                       pk_grid.get_prioritary_task(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   gt.nurse_activity,
                                                                                                                                   pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                               i_prof,
                                                                                                                                                               pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                           i_prof,
                                                                                                                                                                                           gt.intervention,
                                                                                                                                                                                           gt.monitorization,
                                                                                                                                                                                           NULL,
                                                                                                                                                                                           g_flg_doctor),
                                                                                                                                                               gt.teach_req,
                                                                                                                                                               NULL,
                                                                                                                                                               g_flg_doctor),
                                                                                                                                   NULL,
                                                                                                                                   g_flg_doctor),
                                                                                                       NULL,
                                                                                                       g_flg_doctor))
                                   ELSE
                                    NULL
                               END desc_interv_presc,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.visit_grid_task_str(i_lang,
                                                                i_prof,
                                                                e.id_visit,
                                                                g_task_analysis,
                                                                i_prof_cat_type)
                                   ELSE
                                    NULL
                               END desc_analysis_req,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_exam, i_prof_cat_type)
                                   ELSE
                                    NULL
                               END desc_exam_req,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_adm_disch,
                                      3,
                                      g_sched_med_disch,
                                      2,
                                      1) rank,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               -- Updated By Eduardo Lourenco
                               (SELECT substr(concatenate(decode(nvl(ec.id_complaint,
                                                                     decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                                 NULL,
                                                                 ec.patient_complaint,
                                                                 pk_translation.get_translation(i_lang,
                                                                                                'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                nvl(ec.id_complaint,
                                                                                                    decode(s2.flg_reason_type,
                                                                                                           'C',
                                                                                                           s2.id_reason,
                                                                                                           NULL)))) || '; '),
                                              1,
                                              length(concatenate(decode(nvl(ec.id_complaint,
                                                                            decode(s2.flg_reason_type,
                                                                                   'C',
                                                                                   s2.id_reason,
                                                                                   NULL)),
                                                                        NULL,
                                                                        ec.patient_complaint,
                                                                        pk_translation.get_translation(i_lang,
                                                                                                       'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                       nvl(ec.id_complaint,
                                                                                                           decode(s2.flg_reason_type,
                                                                                                                  'C',
                                                                                                                  s2.id_reason,
                                                                                                                  NULL))) || '; '))) -
                                              length('; '))
                                  FROM schedule s2
                                  LEFT JOIN epis_info ei2
                                    ON ei2.id_schedule = s2.id_schedule
                                  LEFT JOIN epis_complaint ec
                                    ON ec.id_episode = ei2.id_episode
                                 WHERE s2.id_schedule = s.id_schedule
                                   AND nvl(ec.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active) reason,
                               ------
                               CASE
                                   WHEN ei.id_episode IS NOT NULL THEN
                                    pk_date_utils.date_send_tsz(i_lang,
                                                                decode(pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                       e.flg_ehr),
                                                                       g_sched_scheduled,
                                                                       NULL,
                                                                       e.dt_begin_tstz),
                                                                i_prof.institution,
                                                                i_prof.software)
                                   ELSE
                                    NULL
                               END dt_begin,
                               l_therap_decision_consult visit_reason,
                               sp.dt_target_tstz dt,
                               '(' ||
                               pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) || ')' therapeutic_doctor,
                               decode(s.flg_present, 'N', l_no_present_patient) patient_presence,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               sg.flg_contact_type,
                               -- Display number of responsible PHYSICIANS for the episode, 
                               -- if institution is using the multiple hand-off mechanism,
                               -- along with the name of the main responsible for the patient.
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional,
                                                        (SELECT ps.id_professional
                                                           FROM sch_prof_outp ps
                                                          WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                            AND rownum = 1)),
                                                    l_handoff_type,
                                                    'G') name_prof,
                               -- Only display the name of the responsible nurse, for all hand-off mechanisms
                               pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                               -- Team name or Resident physician(s)
                               decode(l_show_resident_physician,
                                      pk_alert_constant.g_yes,
                                      pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                 i_prof,
                                                                                 ei.id_episode,
                                                                                 l_handoff_type,
                                                                                 pk_hand_off_core.g_resident,
                                                                                 'G'),
                                      pk_prof_teams.get_prof_current_team(i_lang,
                                                                          i_prof,
                                                                          e.id_department,
                                                                          ei.id_software,
                                                                          nvl(ei.id_professional,
                                                                              (SELECT ps.id_professional
                                                                                 FROM sch_prof_outp ps
                                                                                WHERE ps.id_schedule_outp =
                                                                                      sp.id_schedule_outp
                                                                                  AND rownum = 1)),
                                                                          ei.id_first_nurse_resp)) prof_team,
                               
                               -- Display text in tooltips
                               -- 1) Responsible physician(s)
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional,
                                                        (SELECT ps.id_professional
                                                           FROM sch_prof_outp ps
                                                          WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                            AND rownum = 1)),
                                                    l_handoff_type,
                                                    'T') name_prof_tooltip,
                               -- 2) Responsible nurse
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_nurse,
                                                    ei.id_episode,
                                                    ei.id_first_nurse_resp,
                                                    l_handoff_type,
                                                    'T') name_nurse_tooltip,
                               -- 3) Responsible team 
                               pk_hand_off_core.get_team_str(i_lang,
                                                             i_prof,
                                                             e.id_department,
                                                             ei.id_software,
                                                             nvl(ei.id_professional,
                                                                 (SELECT ps.id_professional
                                                                    FROM sch_prof_outp ps
                                                                   WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                                     AND rownum = 1)),
                                                             ei.id_first_nurse_resp,
                                                             l_handoff_type,
                                                             NULL) prof_team_tooltip,
                               0 id_group,
                               pk_alert_constant.g_no flg_group_header,
                               NULL extend_icon,
                               pk_alert_constant.g_no prof_follow_add,
                               pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove,
                               pk_schedule_common.get_translation_alias(i_lang,
                                                                        i_prof,
                                                                        se.id_sch_event,
                                                                        se.code_sch_event) sch_event_desc
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          LEFT JOIN epis_info ei
                            ON ei.id_schedule = s.id_schedule
                          LEFT JOIN episode e
                            ON e.id_episode = ei.id_episode
                           AND e.flg_ehr != g_flg_ehr
                          LEFT JOIN sch_resource sr
                            ON sr.id_schedule = s.id_schedule
                          LEFT JOIN grid_task gt
                            ON gt.id_episode = ei.id_episode
                          LEFT JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                         WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                           AND decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_adm_disch,
                                      get_grid_task_count(i_lang,
                                                          i_prof,
                                                          ei.id_episode,
                                                          e.id_visit,
                                                          i_prof_cat_type,
                                                          l_sysdate_char_short),
                                      1) = 1
                           AND sp.id_software = i_prof.software
                              -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico                     
                           AND sp.id_epis_type != g_epis_type_nurse
                           AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                           AND s.id_instit_requested = i_prof.institution
                           AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                           AND s.id_sch_event = g_sch_event_therap_decision
                           AND sr.id_professional = i_prof.id) t
                 WHERE (pk_grid.get_schedule_real_state(t.flg_state, t.flg_ehr) !=
                       decode(t.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                       l_show_nurse_disch = g_yes)
                   AND (l_show_med_disch = g_yes OR
                       (l_show_med_disch = g_no AND
                       pk_grid.get_schedule_real_state(t.flg_state, t.flg_ehr) != g_sched_med_disch))
                 ORDER BY t.rank, t.dt, t.dt_begin;
        
        ELSIF i_type = g_type_all_appointments
        THEN
        
            l_group_ids := get_group_ids(i_prof, l_dt_min, l_dt_max);
        
            l_schedule_ids := get_schedule_ids(l_group_ids);
        
            OPEN o_doc FOR
                SELECT t.id_schedule,
                       t.id_patient,
                       t.num_clin_record,
                       t.id_episode,
                       t.dt_efectiv,
                       t.name,
                       t.name_to_sort,
                       t.pat_ndo,
                       t.pat_nd_icon,
                       t.gender,
                       t.pat_age,
                       t.photo,
                       t.flg_contact,
                       t.cons_type,
                       t.dt_target,
                       t.dt_schedule_begin,
                       t.flg_state,
                       t.flg_sched,
                       t.img_state,
                       t.img_sched,
                       t.flg_temp,
                       t.dt_server,
                       t.desc_temp,
                       t.desc_drug_presc,
                       t.desc_interv_presc,
                       t.desc_analysis_req,
                       t.desc_exam_req,
                       t.rank,
                       wr_call(i_lang, i_prof, t.wr_call, i_dt) wr_call,
                       t.doctor_name,
                       t.reason,
                       t.dt_begin,
                       t.visit_reason,
                       t.dt,
                       t.therapeutic_doctor,
                       t.patient_presence,
                       t.desc_room,
                       -- ALERT- 256002 - Mário when i_type='C' not showing the icon added the parameters for that
                       t.flg_contact_type,
                       CASE
                            WHEN t.flg_group_header = pk_alert_constant.g_yes THEN
                             get_group_presence_icon(i_lang, i_prof, t.id_group, pk_alert_constant.g_no)
                            ELSE
                             (SELECT pk_sysdomain.get_img(i_lang, g_domain_sch_presence, t.flg_contact_type)
                                FROM dual)
                        END icon_contact_type,
                       pk_sysdomain.get_domain(g_domain_sch_presence, t.flg_contact_type, i_lang) presence_desc,
                       pk_patient.get_designated_provider(i_lang, i_prof, t.id_patient, t.id_episode) designated_provider,
                       --t.flg_contact,
                       t.name_prof,
                       t.name_nurse,
                       t.prof_team,
                       t.name_prof_tooltip,
                       t.name_nurse_tooltip,
                       t.prof_team_tooltip,
                       t.desc_ana_exam_req,
                       t.resp_icon,
                       t.id_group,
                       t.flg_group_header,
                       t.extend_icon,
                       t.prof_follow_add,
                       t.prof_follow_remove,
                       t.sch_event_desc,
                       l_type_appoint_edition flg_type_appoint_edition
                  FROM (SELECT sp.id_epis_type,
                               e.flg_ehr,
                               s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode,
                               CASE
                                    WHEN ei.id_episode IS NOT NULL THEN
                                     decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                            g_sched_scheduled,
                                            '',
                                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                                             e.dt_begin_tstz,
                                                                             i_prof.institution,
                                                                             i_prof.software))
                                    ELSE
                                     NULL
                                END dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang)
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               pk_date_utils.date_char_tsz(i_lang,
                                                           sp.dt_target_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_schedule_begin,
                               pk_grid.get_pre_nurse_appointment(i_lang,
                                                                 i_prof,
                                                                 ei.id_dep_clin_serv,
                                                                 e.flg_ehr,
                                                                 pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                               sp.flg_sched,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                           pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                             i_prof,
                                                                                             ei.id_dep_clin_serv,
                                                                                             e.flg_ehr,
                                                                                             pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                             e.flg_ehr)),
                                                           i_lang) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               'N' flg_temp,
                               g_sysdate_char dt_server,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
                               
                               CASE
                                    WHEN gt.id_episode IS NOT NULL THEN
                                     pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                                    ELSE
                                     NULL
                                END desc_drug_presc,
                               CASE
                                    WHEN gt.id_episode IS NOT NULL THEN
                                     pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                            i_prof,
                                                                            pk_grid.get_prioritary_task(i_lang,
                                                                                                        i_prof,
                                                                                                        gt.icnp_intervention,
                                                                                                        pk_grid.get_prioritary_task(i_lang,
                                                                                                                                    i_prof,
                                                                                                                                    gt.nurse_activity,
                                                                                                                                    pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                i_prof,
                                                                                                                                                                pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                            i_prof,
                                                                                                                                                                                            gt.intervention,
                                                                                                                                                                                            gt.monitorization,
                                                                                                                                                                                            NULL,
                                                                                                                                                                                            g_flg_doctor),
                                                                                                                                                                gt.teach_req,
                                                                                                                                                                NULL,
                                                                                                                                                                g_flg_doctor),
                                                                                                                                    NULL,
                                                                                                                                    g_flg_doctor),
                                                                                                        NULL,
                                                                                                        g_flg_doctor))
                                    ELSE
                                     NULL
                                END desc_interv_presc,
                               CASE
                                    WHEN gt.id_episode IS NOT NULL THEN
                                     pk_grid.visit_grid_task_str(i_lang,
                                                                 i_prof,
                                                                 e.id_visit,
                                                                 g_task_analysis,
                                                                 i_prof_cat_type)
                                    ELSE
                                     NULL
                                END desc_analysis_req,
                               CASE
                                    WHEN gt.id_episode IS NOT NULL THEN
                                     pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_exam, i_prof_cat_type)
                                    ELSE
                                     NULL
                                END desc_exam_req,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr), g_sched_med_disch, 2, 1) rank,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               -- Updated By Eduardo Lourenco
                               (SELECT substr(concatenate(decode(ec.id_complaint,
                                                                 NULL,
                                                                 ec.patient_complaint,
                                                                 pk_translation.get_translation(i_lang,
                                                                                                'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                ec.id_complaint)) || '; '),
                                              1,
                                              length(concatenate(decode(ec.id_complaint,
                                                                        NULL,
                                                                        ec.patient_complaint,
                                                                        pk_translation.get_translation(i_lang,
                                                                                                       'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                       ec.id_complaint) || '; '))) -
                                              length('; '))
                                  FROM epis_complaint ec
                                 WHERE ec.id_episode = ei.id_episode
                                   AND ec.flg_status = pk_alert_constant.g_active) reason,
                               CASE
                                    WHEN ei.id_episode IS NOT NULL THEN
                                     pk_date_utils.date_send_tsz(i_lang,
                                                                 e.dt_begin_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software)
                                    ELSE
                                     NULL
                                END dt_begin,
                               decode(s.id_sch_event,
                                      g_sch_event_therap_decision,
                                      l_therap_decision_consult,
                                      decode(l_reasongrid,
                                             g_no,
                                             NULL,
                                             pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                         i_prof,
                                                                                                                         ei.id_episode,
                                                                                                                         s.id_schedule),
                                                                              4000))) visit_reason,
                               sp.dt_target_tstz dt,
                               decode(s.id_sch_event,
                                      g_sch_event_therap_decision,
                                      '(' || pk_therapeutic_decision.get_prof_name_resp(i_lang,
                                                                                        i_prof,
                                                                                        ei.id_episode,
                                                                                        s.id_schedule) || ')') therapeutic_doctor,
                               decode(s.flg_present, 'N', l_no_present_patient) patient_presence,
                               sp.dt_target_tstz,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               -- ALERT- 256002 - Mário when i_type='C' not showing the icon added the parameters for that                              
                               sg.flg_contact_type, --added                              
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               -- Display number of responsible PHYSICIANS for the episode, 
                               -- if institution is using the multiple hand-off mechanism,
                               -- along with the name of the main responsible for the patient.
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional,
                                                        (SELECT ps.id_professional
                                                           FROM sch_prof_outp ps
                                                          WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                            AND rownum = 1)),
                                                    l_handoff_type,
                                                    'G') name_prof,
                               -- Only display the name of the responsible nurse, for all hand-off mechanisms
                               pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                               -- Team name or Resident physician(s)
                               decode(l_show_resident_physician,
                                      pk_alert_constant.g_yes,
                                      pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                 i_prof,
                                                                                 ei.id_episode,
                                                                                 l_handoff_type,
                                                                                 pk_hand_off_core.g_resident,
                                                                                 'G'),
                                      pk_prof_teams.get_prof_current_team(i_lang,
                                                                          i_prof,
                                                                          e.id_department,
                                                                          ei.id_software,
                                                                          nvl(ei.id_professional,
                                                                              (SELECT ps.id_professional
                                                                                 FROM sch_prof_outp ps
                                                                                WHERE ps.id_schedule_outp =
                                                                                      sp.id_schedule_outp
                                                                                  AND rownum = 1)),
                                                                          ei.id_first_nurse_resp)) prof_team,
                               
                               -- Display text in tooltips
                               -- 1) Responsible physician(s)
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional,
                                                        (SELECT ps.id_professional
                                                           FROM sch_prof_outp ps
                                                          WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                            AND rownum = 1)),
                                                    l_handoff_type,
                                                    'T') name_prof_tooltip,
                               -- 2) Responsible nurse
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_nurse,
                                                    ei.id_episode,
                                                    ei.id_first_nurse_resp,
                                                    l_handoff_type,
                                                    'T') name_nurse_tooltip,
                               -- 3) Responsible team 
                               pk_hand_off_core.get_team_str(i_lang,
                                                             i_prof,
                                                             e.id_department,
                                                             ei.id_software,
                                                             ei.id_professional,
                                                             ei.id_first_nurse_resp,
                                                             l_handoff_type,
                                                             NULL) prof_team_tooltip,
                               0 id_group,
                               pk_alert_constant.g_no flg_group_header,
                               NULL extend_icon,
                               decode(pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule),
                                      pk_alert_constant.g_no,
                                      decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                              i_prof,
                                                                                                              ei.id_episode,
                                                                                                              i_prof_cat_type,
                                                                                                              l_handoff_type,
                                                                                                              pk_alert_constant.g_yes),
                                                                          i_prof.id),
                                             -1,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no),
                                      pk_alert_constant.g_no) prof_follow_add,
                               pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove,
                               pk_schedule_common.get_translation_alias(i_lang,
                                                                        i_prof,
                                                                        se.id_sch_event,
                                                                        se.code_sch_event) sch_event_desc
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                          LEFT JOIN epis_info ei
                            ON ei.id_schedule = s.id_schedule
                          LEFT JOIN episode e
                            ON e.id_episode = ei.id_episode
                           AND e.flg_ehr != g_flg_ehr
                          LEFT JOIN grid_task gt
                            ON gt.id_episode = ei.id_episode
                          LEFT JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                         WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                           AND sp.id_software = i_prof.software
                              -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico
                           AND sp.id_epis_type != g_epis_type_nurse
                           AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                           AND s.id_instit_requested = i_prof.institution
                           AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                           AND EXISTS (SELECT 0
                                  FROM prof_dep_clin_serv pdcs
                                 WHERE pdcs.id_professional = i_prof.id
                                   AND pdcs.flg_status = g_selected
                                   AND pdcs.id_dep_clin_serv = ei.id_dep_clin_serv)
                           AND 1 = decode(ei.id_episode,
                                          NULL,
                                          1,
                                          (SELECT COUNT(0)
                                             FROM episode epis
                                            WHERE epis.flg_status != g_epis_canc
                                              AND epis.id_episode = ei.id_episode))
                           AND se.flg_is_group = pk_alert_constant.g_no
                        UNION ALL
                        --group elements
                        SELECT sp.id_epis_type,
                               e.flg_ehr,
                               s.id_schedule,
                               sg.id_patient,
                               (SELECT cr.num_clin_record
                                  FROM clin_record cr
                                 WHERE cr.id_patient = sg.id_patient
                                   AND cr.id_institution = i_prof.institution
                                   AND rownum < 2) num_clin_record,
                               ei.id_episode,
                               CASE
                                   WHEN ei.id_episode IS NOT NULL THEN
                                    decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                           g_sched_scheduled,
                                           '',
                                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                                            e.dt_begin_tstz,
                                                                            i_prof.institution,
                                                                            i_prof.software))
                                   ELSE
                                    NULL
                               END dt_efectiv,
                               pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               pk_patient.get_pat_name_to_sort(i_lang,
                                                               i_prof,
                                                               sg.id_patient,
                                                               ei.id_episode,
                                                               s.id_schedule) name_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang)
                                  FROM patient pat
                                 WHERE sg.id_patient = pat.id_patient) gender,
                               pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               pk_date_utils.date_char_tsz(i_lang,
                                                           sp.dt_target_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_schedule_begin,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      g_sched_canc,
                                      pk_grid.get_pre_nurse_appointment(i_lang,
                                                                        i_prof,
                                                                        ei.id_dep_clin_serv,
                                                                        e.flg_ehr,
                                                                        pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                        e.flg_ehr))) flg_state,
                               sp.flg_sched,
                               decode(s.flg_status,
                                      g_sched_canc,
                                      pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS', s.flg_status, i_lang),
                                      pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                                  pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                    i_prof,
                                                                                                    ei.id_dep_clin_serv,
                                                                                                    e.flg_ehr,
                                                                                                    pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                    e.flg_ehr)),
                                                                  i_lang)) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               'N' flg_temp,
                               g_sysdate_char dt_server,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
                               
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                                   ELSE
                                    NULL
                               END desc_drug_presc,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                           i_prof,
                                                                           pk_grid.get_prioritary_task(i_lang,
                                                                                                       i_prof,
                                                                                                       gt.icnp_intervention,
                                                                                                       pk_grid.get_prioritary_task(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   gt.nurse_activity,
                                                                                                                                   pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                               i_prof,
                                                                                                                                                               pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                           i_prof,
                                                                                                                                                                                           gt.intervention,
                                                                                                                                                                                           gt.monitorization,
                                                                                                                                                                                           NULL,
                                                                                                                                                                                           g_flg_doctor),
                                                                                                                                                               gt.teach_req,
                                                                                                                                                               NULL,
                                                                                                                                                               g_flg_doctor),
                                                                                                                                   NULL,
                                                                                                                                   g_flg_doctor),
                                                                                                       NULL,
                                                                                                       g_flg_doctor))
                                   ELSE
                                    NULL
                               END desc_interv_presc,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.visit_grid_task_str(i_lang,
                                                                i_prof,
                                                                e.id_visit,
                                                                g_task_analysis,
                                                                i_prof_cat_type)
                                   ELSE
                                    NULL
                               END desc_analysis_req,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_exam, i_prof_cat_type)
                                   ELSE
                                    NULL
                               END desc_exam_req,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr), g_sched_med_disch, 2, 1) rank,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               -- Updated By Eduardo Lourenco
                               (SELECT substr(concatenate(decode(ec.id_complaint,
                                                                 NULL,
                                                                 ec.patient_complaint,
                                                                 pk_translation.get_translation(i_lang,
                                                                                                'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                ec.id_complaint)) || '; '),
                                              1,
                                              length(concatenate(decode(ec.id_complaint,
                                                                        NULL,
                                                                        ec.patient_complaint,
                                                                        pk_translation.get_translation(i_lang,
                                                                                                       'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                       ec.id_complaint) || '; '))) -
                                              length('; '))
                                  FROM epis_complaint ec
                                 WHERE ec.id_episode = ei.id_episode
                                   AND ec.flg_status = pk_alert_constant.g_active) reason,
                               CASE
                                   WHEN ei.id_episode IS NOT NULL THEN
                                    pk_date_utils.date_send_tsz(i_lang,
                                                                e.dt_begin_tstz,
                                                                i_prof.institution,
                                                                i_prof.software)
                                   ELSE
                                    NULL
                               END dt_begin,
                               decode(s.id_sch_event,
                                      g_sch_event_therap_decision,
                                      l_therap_decision_consult,
                                      decode(l_reasongrid,
                                             g_no,
                                             NULL,
                                             pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                         i_prof,
                                                                                                                         ei.id_episode,
                                                                                                                         s.id_schedule),
                                                                              4000))) visit_reason,
                               sp.dt_target_tstz dt,
                               decode(s.id_sch_event,
                                      g_sch_event_therap_decision,
                                      '(' || pk_therapeutic_decision.get_prof_name_resp(i_lang,
                                                                                        i_prof,
                                                                                        ei.id_episode,
                                                                                        s.id_schedule) || ')') therapeutic_doctor,
                               decode(s.flg_present, 'N', l_no_present_patient) patient_presence,
                               sp.dt_target_tstz,
                               NULL desc_room, --decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               -- ALERT- 256002 - Mário when i_type='C' not showing the icon added the parameters for that
                               sg.flg_contact_type,
                               
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               -- Display number of responsible PHYSICIANS for the episode, 
                               -- if institution is using the multiple hand-off mechanism,
                               -- along with the name of the main responsible for the patient.
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional,
                                                        (SELECT ps.id_professional
                                                           FROM sch_prof_outp ps
                                                          WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                            AND rownum = 1)),
                                                    l_handoff_type,
                                                    'G') name_prof,
                               -- Only display the name of the responsible nurse, for all hand-off mechanisms
                               pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                               -- Team name or Resident physician(s)
                               decode(l_show_resident_physician,
                                      pk_alert_constant.g_yes,
                                      pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                 i_prof,
                                                                                 ei.id_episode,
                                                                                 l_handoff_type,
                                                                                 pk_hand_off_core.g_resident,
                                                                                 'G'),
                                      pk_prof_teams.get_prof_current_team(i_lang,
                                                                          i_prof,
                                                                          e.id_department,
                                                                          ei.id_software,
                                                                          nvl(ei.id_professional,
                                                                              (SELECT ps.id_professional
                                                                                 FROM sch_prof_outp ps
                                                                                WHERE ps.id_schedule_outp =
                                                                                      sp.id_schedule_outp
                                                                                  AND rownum = 1)),
                                                                          ei.id_first_nurse_resp)) prof_team,
                               
                               -- Display text in tooltips
                               -- 1) Responsible physician(s)
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional,
                                                        (SELECT ps.id_professional
                                                           FROM sch_prof_outp ps
                                                          WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                            AND rownum = 1)),
                                                    l_handoff_type,
                                                    'T') name_prof_tooltip,
                               -- 2) Responsible nurse
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_nurse,
                                                    ei.id_episode,
                                                    ei.id_first_nurse_resp,
                                                    l_handoff_type,
                                                    'T') name_nurse_tooltip,
                               -- 3) Responsible team 
                               pk_hand_off_core.get_team_str(i_lang,
                                                             i_prof,
                                                             e.id_department,
                                                             ei.id_software,
                                                             ei.id_professional,
                                                             ei.id_first_nurse_resp,
                                                             l_handoff_type,
                                                             NULL) prof_team_tooltip,
                               s.id_group,
                               pk_alert_constant.g_no flg_group_header,
                               'ExtendIcon' extend_icon,
                               pk_alert_constant.g_no prof_allow_add,
                               pk_alert_constant.g_no prof_allow_remove,
                               pk_schedule_common.get_translation_alias(i_lang,
                                                                        i_prof,
                                                                        se.id_sch_event,
                                                                        se.code_sch_event) sch_event_desc
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          LEFT JOIN epis_info ei
                            ON ei.id_schedule = s.id_schedule
                          LEFT JOIN episode e
                            ON e.id_episode = ei.id_episode
                          LEFT JOIN grid_task gt
                            ON gt.id_episode = ei.id_episode
                          LEFT JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                         WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                               d.column_value
                                                FROM TABLE(l_group_ids) d)
                        UNION ALL
                        --group header
                        SELECT sp.id_epis_type,
                               e.flg_ehr,
                               NULL id_schedule, --s.id_schedule,
                               NULL id_patient, --sg.id_patient,
                               NULL num_clin_record, --(SELECT cr.num_clin_record FROM clin_record cr WHERE cr.id_patient = sg.id_patient AND cr.id_institution = i_prof.institution AND rownum < 2) num_clin_record,
                               NULL id_episode, --ei.id_episode,
                               CASE
                                   WHEN ei.id_episode IS NOT NULL THEN
                                    decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                           g_sched_scheduled,
                                           '',
                                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                                            e.dt_begin_tstz,
                                                                            i_prof.institution,
                                                                            i_prof.software))
                                   ELSE
                                    NULL
                               END dt_efectiv,
                               l_sch_t640 name, --pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                               l_sch_t640 name_to_sort, --pk_patient.get_pat_name_to_sort(i_lang,i_prof,sg.id_patient,ei.id_episode,s.id_schedule) name_to_sort,
                               NULL pat_ndo, --pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                               NULL pat_nd_icon, --pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                               NULL gender, --(SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) FROM patient pat WHERE sg.id_patient = pat.id_patient) gender,
                               NULL pat_age, --pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                               NULL photo, --pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                               NULL flg_contact, --pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                               pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                               pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                               pk_date_utils.date_char_tsz(i_lang,
                                                           sp.dt_target_tstz,
                                                           i_prof.institution,
                                                           i_prof.software) dt_schedule_begin,
                               'A' flg_state,
                               sp.flg_sched,
                               get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                               pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                               'N' flg_temp,
                               g_sysdate_char dt_server,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                      g_sched_scheduled,
                                      '',
                                      decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
                               
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                                   ELSE
                                    NULL
                               END desc_drug_presc,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                           i_prof,
                                                                           pk_grid.get_prioritary_task(i_lang,
                                                                                                       i_prof,
                                                                                                       gt.icnp_intervention,
                                                                                                       pk_grid.get_prioritary_task(i_lang,
                                                                                                                                   i_prof,
                                                                                                                                   gt.nurse_activity,
                                                                                                                                   pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                               i_prof,
                                                                                                                                                               pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                           i_prof,
                                                                                                                                                                                           gt.intervention,
                                                                                                                                                                                           gt.monitorization,
                                                                                                                                                                                           NULL,
                                                                                                                                                                                           g_flg_doctor),
                                                                                                                                                               gt.teach_req,
                                                                                                                                                               NULL,
                                                                                                                                                               g_flg_doctor),
                                                                                                                                   NULL,
                                                                                                                                   g_flg_doctor),
                                                                                                       NULL,
                                                                                                       g_flg_doctor))
                                   ELSE
                                    NULL
                               END desc_interv_presc,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.visit_grid_task_str(i_lang,
                                                                i_prof,
                                                                e.id_visit,
                                                                g_task_analysis,
                                                                i_prof_cat_type)
                                   ELSE
                                    NULL
                               END desc_analysis_req,
                               CASE
                                   WHEN gt.id_episode IS NOT NULL THEN
                                    pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_exam, i_prof_cat_type)
                                   ELSE
                                    NULL
                               END desc_exam_req,
                               decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr), g_sched_med_disch, 2, 1) rank,
                               pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                       i_prof                      => i_prof,
                                                       i_waiting_room_available    => l_waiting_room_available,
                                                       i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                       i_id_episode                => ei.id_episode,
                                                       i_flg_state                 => sp.flg_state,
                                                       i_flg_ehr                   => e.flg_ehr,
                                                       i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                               nvl((SELECT nvl(p.nick_name, p.name)
                                     FROM professional p
                                    WHERE p.id_professional = ei.id_professional),
                                   (SELECT nvl(p.nick_name, p.name)
                                      FROM sch_prof_outp ps, professional p
                                     WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                       AND p.id_professional = ps.id_professional
                                       AND rownum < 2)) doctor_name,
                               -- Updated By Eduardo Lourenco
                               (SELECT substr(concatenate(decode(ec.id_complaint,
                                                                 NULL,
                                                                 ec.patient_complaint,
                                                                 pk_translation.get_translation(i_lang,
                                                                                                'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                ec.id_complaint)) || '; '),
                                              1,
                                              length(concatenate(decode(ec.id_complaint,
                                                                        NULL,
                                                                        ec.patient_complaint,
                                                                        pk_translation.get_translation(i_lang,
                                                                                                       'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                       ec.id_complaint) || '; '))) -
                                              length('; '))
                                  FROM epis_complaint ec
                                 WHERE ec.id_episode = ei.id_episode
                                   AND ec.flg_status = pk_alert_constant.g_active) reason,
                               CASE
                                   WHEN ei.id_episode IS NOT NULL THEN
                                    pk_date_utils.date_send_tsz(i_lang,
                                                                e.dt_begin_tstz,
                                                                i_prof.institution,
                                                                i_prof.software)
                                   ELSE
                                    NULL
                               END dt_begin,
                               decode(s.id_sch_event,
                                      g_sch_event_therap_decision,
                                      l_therap_decision_consult,
                                      decode(l_reasongrid,
                                             g_no,
                                             NULL,
                                             pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                         i_prof,
                                                                                                                         ei.id_episode,
                                                                                                                         s.id_schedule),
                                                                              4000))) visit_reason,
                               sp.dt_target_tstz dt,
                               decode(s.id_sch_event,
                                      g_sch_event_therap_decision,
                                      '(' || pk_therapeutic_decision.get_prof_name_resp(i_lang,
                                                                                        i_prof,
                                                                                        ei.id_episode,
                                                                                        s.id_schedule) || ')') therapeutic_doctor,
                               decode(s.flg_present, 'N', l_no_present_patient) patient_presence,
                               sp.dt_target_tstz,
                               decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                               -- ALERT- 256002 - Mário when i_type='C' not showing the icon added the parameters for that
                               sg.flg_contact_type, --added                              
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                               pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                      i_prof,
                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                  i_prof,
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_analysis,
                                                                                                                                 i_prof_cat_type),
                                                                                                  pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 e.id_visit,
                                                                                                                                 g_task_exam,
                                                                                                                                 i_prof_cat_type),
                                                                                                  g_analysis_exam_icon_grid_rank,
                                                                                                  g_flg_doctor)) desc_ana_exam_req,
                               -- Display number of responsible PHYSICIANS for the episode, 
                               -- if institution is using the multiple hand-off mechanism,
                               -- along with the name of the main responsible for the patient.
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional,
                                                        (SELECT ps.id_professional
                                                           FROM sch_prof_outp ps
                                                          WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                            AND rownum = 1)),
                                                    l_handoff_type,
                                                    'G') name_prof,
                               -- Only display the name of the responsible nurse, for all hand-off mechanisms
                               pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                               -- Team name or Resident physician(s)
                               decode(l_show_resident_physician,
                                      pk_alert_constant.g_yes,
                                      pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                                 i_prof,
                                                                                 ei.id_episode,
                                                                                 l_handoff_type,
                                                                                 pk_hand_off_core.g_resident,
                                                                                 'G'),
                                      pk_prof_teams.get_prof_current_team(i_lang,
                                                                          i_prof,
                                                                          e.id_department,
                                                                          ei.id_software,
                                                                          nvl(ei.id_professional,
                                                                              (SELECT ps.id_professional
                                                                                 FROM sch_prof_outp ps
                                                                                WHERE ps.id_schedule_outp =
                                                                                      sp.id_schedule_outp
                                                                                  AND rownum = 1)),
                                                                          ei.id_first_nurse_resp)) prof_team,
                               
                               -- Display text in tooltips
                               -- 1) Responsible physician(s)
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_doc,
                                                    ei.id_episode,
                                                    nvl(ei.id_professional,
                                                        (SELECT ps.id_professional
                                                           FROM sch_prof_outp ps
                                                          WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                            AND rownum = 1)),
                                                    l_handoff_type,
                                                    'T') name_prof_tooltip,
                               -- 2) Responsible nurse
                               get_responsibles_str(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_cat_type_nurse,
                                                    ei.id_episode,
                                                    ei.id_first_nurse_resp,
                                                    l_handoff_type,
                                                    'T') name_nurse_tooltip,
                               -- 3) Responsible team 
                               pk_hand_off_core.get_team_str(i_lang,
                                                             i_prof,
                                                             e.id_department,
                                                             ei.id_software,
                                                             ei.id_professional,
                                                             ei.id_first_nurse_resp,
                                                             l_handoff_type,
                                                             NULL) prof_team_tooltip,
                               s.id_group,
                               pk_alert_constant.g_yes flg_group_header,
                               NULL extend_icon,
                               pk_alert_constant.g_no prof_allow_add,
                               pk_alert_constant.g_no prof_allow_remove,
                               pk_schedule_common.get_translation_alias(i_lang,
                                                                        i_prof,
                                                                        se.id_sch_event,
                                                                        se.code_sch_event) sch_event_desc
                          FROM schedule_outp sp
                          JOIN schedule s
                            ON s.id_schedule = sp.id_schedule
                          JOIN sch_group sg
                            ON sg.id_schedule = s.id_schedule
                          LEFT JOIN epis_info ei
                            ON ei.id_schedule = s.id_schedule
                          LEFT JOIN episode e
                            ON e.id_episode = ei.id_episode
                          LEFT JOIN grid_task gt
                            ON gt.id_episode = ei.id_episode
                          LEFT JOIN sch_event se
                            ON s.id_sch_event = se.id_sch_event
                         WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                                  d.column_value
                                                   FROM TABLE(l_schedule_ids) d)
                        --
                        ) t
                 WHERE (pk_grid.get_schedule_real_state(t.flg_state, t.flg_ehr) !=
                       decode(t.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                       l_show_nurse_disch = g_yes)
                   AND (l_show_med_disch = g_yes OR
                       (l_show_med_disch = g_no AND
                       pk_grid.get_schedule_real_state(t.flg_state, t.flg_ehr) != g_sched_med_disch))
                 ORDER BY t.rank, t.dt_target_tstz, t.dt_begin;
        ELSE
            pk_types.open_my_cursor(o_doc);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'DOCTOR_EFECTIV_PP',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END doctor_efectiv_pp;

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
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Grelha do médico, para ver consultas agendadas
                  e já efectivadas
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_EPIS_TYPE - Tipo de episódio (CE, URG, ...)
                 I_PROF - prof q acede
                 I_DT - data
                 I_TYPE - tipo de pesquisa: D - consultas agendadas para o médico,
                              C - consultas agendadas para os serv. clínicos do médico
                  I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                       como é retornada em PK_LOGIN.GET_PROF_PREF
                        SAIDA:   O_DOC - array
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/04/20
          ALTERAÇÃO: CRS 2006/07/20 Excluir episódios cancelados
                     LG 2007/05/30 Devolve dois novos campos, nome do médico e motivo de agendamento. Usado nas grelhas PP USA
                     RL 2007/11/23 Alterar para aparecerem os pacientes agendados para o dia para o médico, e não só os efectivados
                     Eduardo Lourenco 2007/11/23 Returns the reason notes from CONSULT_REQ or EPIS_COMPLAINT if none. 
          NOTAS: Nesta grelha visualizam-se os agendamentos do dia:
            - agendados para o médico e já efectivados, c/ ou s/ alta médica, sem
                    alta administrativa ou com alta administrativa se ainda tiverem workflow pendente.
        *********************************************************************************/
        l_waiting_room_sys_external sys_config.value%TYPE := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM',
                                                                                     i_prof);
    
        l_waiting_room_available sys_config.value%TYPE;
        l_sysdate_char_short     VARCHAR2(8);
        l_dt_min                 schedule_outp.dt_target_tstz%TYPE;
        l_dt_max                 schedule_outp.dt_target_tstz%TYPE;
        --variavel que indica de nos devemos deslocar para a area antiga quando estamos em episódios não efectivados
        l_to_old_area             VARCHAR2(1);
        l_reasongrid              VARCHAR2(1);
        l_therap_decision_consult translation.code_translation%TYPE;
        l_no_present_patient      sys_message.desc_message%TYPE;
        l_handoff_type            sys_config.value%TYPE;
        l_config_show_resident CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
        l_show_resident_physician sys_config.value%TYPE;
        l_group_ids               table_number := table_number();
        l_schedule_ids            table_number := table_number();
        l_sch_t640                sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
        l_id_category             category.id_category%TYPE;
        l_type_appoint_edition    VARCHAR2(1 CHAR);
        l_show_nurse_disch        sys_config.value%TYPE := nvl(pk_sysconfig.get_config('SHOW_NURSE_DISCHARGED_GRID',
                                                                                       i_prof),
                                                               g_no);
        l_show_med_disch          sys_config.value%TYPE := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID',
                                                                                       i_prof),
                                                               g_yes);
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        ---------------------------------
        g_error := 'CALL get_date_bounds';
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        l_sysdate_char_short := pk_date_utils.to_char_insttimezone(i_prof, g_sysdate_tstz, 'YYYYMMDD');
    
        g_error                  := 'GET configs';
        l_waiting_room_available := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
        --l_to_old_area            := pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof);
        l_reasongrid      := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID', i_prof);
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        l_no_present_patient := pk_message.get_message(i_lang, 'THERAPEUTIC_DECISION_T017');
    
        l_id_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        IF instr(pk_sysconfig.get_config('ALLOW_MY_ROOM_SPECIALITY_GRID_TYPE_APPOINT_EDITION',
                                         i_prof.institution,
                                         i_prof.software),
                 '|' || l_id_category || '|') > 0
        THEN
            l_type_appoint_edition := pk_alert_constant.g_yes;
        ELSE
            l_type_appoint_edition := pk_alert_constant.g_no;
        END IF;
        -- Consultas de decisao terapeutica 
        SELECT pk_translation.get_translation(i_lang, se.code_sch_event_abrv)
          INTO l_therap_decision_consult
          FROM sch_event se
         WHERE se.id_sch_event = g_sch_event_therap_decision;
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => i_prof);
    
        SELECT DISTINCT s.id_group
          BULK COLLECT
          INTO l_group_ids
          FROM schedule_outp sp
          JOIN schedule s
            ON s.id_schedule = sp.id_schedule
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
          LEFT JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
           AND ei.id_patient = sg.id_patient
          LEFT JOIN episode e
            ON e.id_episode = ei.id_episode
           AND e.flg_ehr != g_flg_ehr
        --LEFT JOIN sch_prof_outp spo
        --  ON spo.id_schedule_outp = sp.id_schedule_outp
         WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
           AND decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                      g_sched_adm_disch,
                      get_grid_task_count(i_lang,
                                          i_prof,
                                          ei.id_episode,
                                          e.id_visit,
                                          i_prof_cat_type,
                                          l_sysdate_char_short),
                      1) = 1
           AND sp.id_software = i_prof.software
              -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico                     
           AND sp.id_epis_type != g_epis_type_nurse
           AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, g_sched_canc)
           AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
           AND s.id_instit_requested = i_prof.institution
           AND EXISTS (SELECT 0
                  FROM prof_room pr
                 WHERE pr.id_professional = i_prof.id
                   AND ei.id_room = pr.id_room)
           AND se.flg_is_group = pk_alert_constant.g_yes
           AND s.id_group IS NOT NULL
           AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
               decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
               l_show_nurse_disch = g_yes)
           AND (l_show_med_disch = g_yes OR
               (l_show_med_disch = g_no AND
               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch));
    
        l_schedule_ids := get_schedule_ids(l_group_ids);
    
        g_error := 'OPEN o_doc - ';
        OPEN o_doc FOR
            SELECT t.id_schedule,
                   t.id_patient,
                   t.num_clin_record,
                   t.id_episode,
                   t.flg_ehr,
                   t.dt_efectiv,
                   t.name,
                   t.name_to_sort,
                   t.pat_ndo,
                   t.pat_nd_icon,
                   t.gender,
                   t.pat_age,
                   t.photo,
                   t.cons_type,
                   t.dt_target,
                   t.flg_state,
                   t.flg_sched,
                   t.img_state,
                   t.img_sched,
                   t.flg_temp,
                   t.dt_server,
                   t.desc_temp,
                   t.desc_drug_presc,
                   t.desc_interv_presc,
                   t.desc_analysis_req,
                   t.desc_exam_req,
                   t.rank,
                   wr_call(i_lang, i_prof, t.wr_call, i_dt) wr_call,
                   t.doctor_name,
                   nvl(t.reason, t.visit_reason) reason,
                   t.dt_begin,
                   t.visit_reason,
                   t.dt,
                   t.therapeutic_doctor,
                   t.patient_presence,
                   t.resp_icon,
                   t.desc_room,
                   pk_patient.get_designated_provider(i_lang, i_prof, t.id_patient, t.id_episode) designated_provider,
                   t.flg_contact_type,
                   CASE
                        WHEN t.flg_group_header = pk_alert_constant.g_yes THEN
                         get_group_presence_icon(i_lang, i_prof, t.id_group, pk_alert_constant.g_no)
                        ELSE
                         pk_sysdomain.get_img(i_lang, g_domain_sch_presence, t.flg_contact_type)
                    END icon_contact_type,
                   pk_sysdomain.get_domain(g_domain_sch_presence, t.flg_contact_type, i_lang) presence_desc,
                   t.flg_contact,
                   t.name_prof,
                   t.name_nurse,
                   t.prof_team,
                   t.name_prof_tooltip,
                   t.name_nurse_tooltip,
                   t.prof_team_tooltip,
                   t.desc_ana_exam_req,
                   t.id_group,
                   t.flg_group_header,
                   t.extend_icon,
                   t.prof_follow_add,
                   t.prof_follow_remove,
                   t.sch_event_desc,
                   l_type_appoint_edition flg_type_appoint_edition
              FROM (SELECT sp.id_epis_type,
                           s.id_schedule,
                           sg.id_patient,
                           (SELECT cr.num_clin_record
                              FROM clin_record cr
                             WHERE cr.id_patient = sg.id_patient
                               AND cr.id_institution = i_prof.institution
                               AND rownum < 2) num_clin_record,
                           ei.id_episode id_episode,
                           e.flg_ehr,
                           CASE
                                WHEN ei.id_episode IS NOT NULL THEN
                                 decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                        g_sched_scheduled,
                                        '',
                                        pk_date_utils.date_char_hour_tsz(i_lang,
                                                                         e.dt_begin_tstz,
                                                                         i_prof.institution,
                                                                         i_prof.software))
                                ELSE
                                 NULL
                            END dt_efectiv,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                              FROM patient pat
                             WHERE sg.id_patient = pat.id_patient) gender,
                           pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) flg_state,
                           sp.flg_sched,
                           pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                       pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                         i_prof,
                                                                                         ei.id_dep_clin_serv,
                                                                                         e.flg_ehr,
                                                                                         pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                         e.flg_ehr)),
                                                       i_lang) img_state,
                           pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                           'N' flg_temp,
                           g_sysdate_char dt_server,
                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_scheduled,
                                  '',
                                  decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
                           
                           CASE
                                WHEN gt.id_episode IS NOT NULL THEN
                                 pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                                ELSE
                                 NULL
                            END desc_drug_presc,
                           CASE
                                WHEN gt.id_episode IS NOT NULL THEN
                                 pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                        i_prof,
                                                                        pk_grid.get_prioritary_task(i_lang,
                                                                                                    i_prof,
                                                                                                    gt.icnp_intervention,
                                                                                                    pk_grid.get_prioritary_task(i_lang,
                                                                                                                                i_prof,
                                                                                                                                gt.nurse_activity,
                                                                                                                                pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                            i_prof,
                                                                                                                                                            pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                        i_prof,
                                                                                                                                                                                        gt.intervention,
                                                                                                                                                                                        gt.monitorization,
                                                                                                                                                                                        NULL,
                                                                                                                                                                                        g_flg_doctor),
                                                                                                                                                            gt.teach_req,
                                                                                                                                                            NULL,
                                                                                                                                                            g_flg_doctor),
                                                                                                                                NULL,
                                                                                                                                g_flg_doctor),
                                                                                                    NULL,
                                                                                                    g_flg_doctor))
                                ELSE
                                 NULL
                            END desc_interv_presc,
                           CASE
                                WHEN gt.id_episode IS NOT NULL THEN
                                 pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_analysis, i_prof_cat_type)
                                ELSE
                                 NULL
                            END desc_analysis_req,
                           CASE
                                WHEN gt.id_episode IS NOT NULL THEN
                                 pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_exam, i_prof_cat_type)
                                ELSE
                                 NULL
                            END desc_exam_req,
                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_adm_disch,
                                  3,
                                  g_sched_med_disch,
                                  2,
                                  1) rank,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => e.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           nvl((SELECT nvl(p.nick_name, p.name)
                                 FROM professional p
                                WHERE p.id_professional = ei.id_professional),
                               (SELECT nvl(p.nick_name, p.name)
                                  FROM sch_prof_outp ps, professional p
                                 WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                   AND p.id_professional = ps.id_professional
                                   AND rownum < 2)) doctor_name,
                           -- Updated By Eduardo Lourenco
                           (SELECT substr(concatenate(decode(nvl(ec.id_complaint,
                                                                 decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                             NULL,
                                                             ec.patient_complaint,
                                                             pk_translation.get_translation(i_lang,
                                                                                            'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                            nvl(ec.id_complaint,
                                                                                                decode(s2.flg_reason_type,
                                                                                                       'C',
                                                                                                       s2.id_reason,
                                                                                                       NULL)))) || '; '),
                                          1,
                                          length(concatenate(decode(nvl(ec.id_complaint,
                                                                        decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                                    NULL,
                                                                    ec.patient_complaint,
                                                                    pk_translation.get_translation(i_lang,
                                                                                                   'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                   nvl(ec.id_complaint,
                                                                                                       decode(s2.flg_reason_type,
                                                                                                              'C',
                                                                                                              s2.id_reason,
                                                                                                              NULL))) || '; '))) -
                                          length('; '))
                              FROM schedule s2
                              LEFT JOIN epis_info ei2
                                ON ei2.id_schedule = s2.id_schedule
                              LEFT JOIN epis_complaint ec
                                ON ec.id_episode = ei2.id_episode
                             WHERE s2.id_schedule = s.id_schedule
                               AND nvl(ec.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active) reason,
                           -----
                           CASE
                                WHEN ei.id_episode IS NOT NULL THEN
                                 pk_date_utils.date_send_tsz(i_lang,
                                                             decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                                    g_sched_scheduled,
                                                                    NULL,
                                                                    e.dt_begin_tstz),
                                                             i_prof.institution,
                                                             i_prof.software)
                                ELSE
                                 NULL
                            END dt_begin,
                           decode(l_reasongrid,
                                  g_yes,
                                  pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                              i_prof,
                                                                                                              ei.id_episode,
                                                                                                              s.id_schedule),
                                                                   4000)) visit_reason,
                           sp.dt_target_tstz dt,
                           NULL therapeutic_doctor,
                           decode(s.flg_present, 'N', l_no_present_patient) patient_presence,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                           decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                           sg.flg_contact_type,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat_type),
                                                                                              g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           -- Display number of responsible PHYSICIANS for the episode, 
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_doc,
                                                ei.id_episode,
                                                nvl(ei.id_professional,
                                                    (SELECT ps.id_professional
                                                       FROM sch_prof_outp ps
                                                      WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                        AND rownum = 1)),
                                                l_handoff_type,
                                                'G') name_prof,
                           -- Only display the name of the responsible nurse, for all hand-off mechanisms
                           pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                           -- Team name or Resident physician(s)
                           decode(l_show_resident_physician,
                                  pk_alert_constant.g_yes,
                                  pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                             i_prof,
                                                                             ei.id_episode,
                                                                             l_handoff_type,
                                                                             pk_hand_off_core.g_resident,
                                                                             'G'),
                                  pk_prof_teams.get_prof_current_team(i_lang,
                                                                      i_prof,
                                                                      e.id_department,
                                                                      ei.id_software,
                                                                      nvl(ei.id_professional,
                                                                          (SELECT ps.id_professional
                                                                             FROM sch_prof_outp ps
                                                                            WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                                              AND rownum = 1)),
                                                                      ei.id_first_nurse_resp)) prof_team,
                           
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_doc,
                                                ei.id_episode,
                                                nvl(ei.id_professional,
                                                    (SELECT ps.id_professional
                                                       FROM sch_prof_outp ps
                                                      WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                        AND rownum = 1)),
                                                l_handoff_type,
                                                'T') name_prof_tooltip,
                           -- 2) Responsible nurse
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_nurse,
                                                ei.id_episode,
                                                ei.id_first_nurse_resp,
                                                l_handoff_type,
                                                'T') name_nurse_tooltip,
                           -- 3) Responsible team 
                           pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         e.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_handoff_type,
                                                         NULL) prof_team_tooltip,
                           0 id_group,
                           pk_alert_constant.g_no flg_group_header,
                           NULL extend_icon,
                           decode(pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule),
                                  pk_alert_constant.g_no,
                                  decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                          i_prof,
                                                                                                          ei.id_episode,
                                                                                                          i_prof_cat_type,
                                                                                                          l_handoff_type,
                                                                                                          pk_alert_constant.g_yes),
                                                                      i_prof.id),
                                         -1,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no),
                                  pk_alert_constant.g_no) prof_follow_add,
                           pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove,
                           pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) sch_event_desc
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = s.id_schedule
                      JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                       AND ei.id_patient = sg.id_patient
                      LEFT JOIN episode e
                        ON e.id_episode = ei.id_episode
                       AND e.flg_ehr != g_flg_ehr
                    --LEFT JOIN sch_prof_outp spo
                    --  ON spo.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN grid_task gt
                        ON gt.id_episode = ei.id_episode
                      LEFT JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                     WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                       AND decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_adm_disch,
                                  get_grid_task_count(i_lang,
                                                      i_prof,
                                                      ei.id_episode,
                                                      e.id_visit,
                                                      i_prof_cat_type,
                                                      l_sysdate_char_short),
                                  1) = 1
                       AND sp.id_software = i_prof.software
                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico                     
                       AND sp.id_epis_type != g_epis_type_nurse
                       AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, g_sched_canc)
                       AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                       AND s.id_instit_requested = i_prof.institution
                       AND s.id_sch_event NOT IN (g_sch_event_therap_decision)
                       AND se.flg_is_group = pk_alert_constant.g_no
                          --AND nvl(ei.id_professional, spo.id_professional) = i_prof.id
                       AND EXISTS (SELECT 0
                              FROM prof_room pr
                             WHERE pr.id_professional = i_prof.id
                               AND ei.id_room = pr.id_room)
                    --group elements
                    UNION ALL
                    SELECT sp.id_epis_type,
                           s.id_schedule,
                           sg.id_patient,
                           (SELECT cr.num_clin_record
                              FROM clin_record cr
                             WHERE cr.id_patient = sg.id_patient
                               AND cr.id_institution = i_prof.institution
                               AND rownum < 2) num_clin_record,
                           ei.id_episode id_episode,
                           e.flg_ehr,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        e.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                              FROM patient pat
                             WHERE sg.id_patient = pat.id_patient) gender,
                           pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           decode(s.flg_status,
                                  g_sched_canc,
                                  g_sched_canc,
                                  pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                           sp.flg_sched,
                           decode(s.flg_status,
                                  g_sched_canc,
                                  pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS', s.flg_status, i_lang),
                                  pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                              pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                i_prof,
                                                                                                ei.id_dep_clin_serv,
                                                                                                e.flg_ehr,
                                                                                                pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                e.flg_ehr)),
                                                              i_lang)) img_state,
                           pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                           'N' flg_temp,
                           g_sysdate_char dt_server,
                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_scheduled,
                                  '',
                                  decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
                           
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                               ELSE
                                NULL
                           END desc_drug_presc,
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                       i_prof,
                                                                       pk_grid.get_prioritary_task(i_lang,
                                                                                                   i_prof,
                                                                                                   gt.icnp_intervention,
                                                                                                   pk_grid.get_prioritary_task(i_lang,
                                                                                                                               i_prof,
                                                                                                                               gt.nurse_activity,
                                                                                                                               pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                           i_prof,
                                                                                                                                                           pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                       i_prof,
                                                                                                                                                                                       gt.intervention,
                                                                                                                                                                                       gt.monitorization,
                                                                                                                                                                                       NULL,
                                                                                                                                                                                       g_flg_doctor),
                                                                                                                                                           gt.teach_req,
                                                                                                                                                           NULL,
                                                                                                                                                           g_flg_doctor),
                                                                                                                               NULL,
                                                                                                                               g_flg_doctor),
                                                                                                   NULL,
                                                                                                   g_flg_doctor))
                               ELSE
                                NULL
                           END desc_interv_presc,
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_analysis, i_prof_cat_type)
                               ELSE
                                NULL
                           END desc_analysis_req,
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_exam, i_prof_cat_type)
                               ELSE
                                NULL
                           END desc_exam_req,
                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_adm_disch,
                                  3,
                                  g_sched_med_disch,
                                  2,
                                  1) rank,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => e.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           nvl((SELECT nvl(p.nick_name, p.name)
                                 FROM professional p
                                WHERE p.id_professional = ei.id_professional),
                               (SELECT nvl(p.nick_name, p.name)
                                  FROM sch_prof_outp ps, professional p
                                 WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                   AND p.id_professional = ps.id_professional
                                   AND rownum < 2)) doctor_name,
                           -- Updated By Eduardo Lourenco
                           (SELECT substr(concatenate(decode(nvl(ec.id_complaint,
                                                                 decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                             NULL,
                                                             ec.patient_complaint,
                                                             pk_translation.get_translation(i_lang,
                                                                                            'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                            nvl(ec.id_complaint,
                                                                                                decode(s2.flg_reason_type,
                                                                                                       'C',
                                                                                                       s2.id_reason,
                                                                                                       NULL)))) || '; '),
                                          1,
                                          length(concatenate(decode(nvl(ec.id_complaint,
                                                                        decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                                    NULL,
                                                                    ec.patient_complaint,
                                                                    pk_translation.get_translation(i_lang,
                                                                                                   'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                   nvl(ec.id_complaint,
                                                                                                       decode(s2.flg_reason_type,
                                                                                                              'C',
                                                                                                              s2.id_reason,
                                                                                                              NULL))) || '; '))) -
                                          length('; '))
                              FROM schedule s2
                              LEFT JOIN epis_info ei2
                                ON ei2.id_schedule = s2.id_schedule
                              LEFT JOIN epis_complaint ec
                                ON ec.id_episode = ei2.id_episode
                             WHERE s2.id_schedule = s.id_schedule
                               AND nvl(ec.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active) reason,
                           -----
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                pk_date_utils.date_send_tsz(i_lang,
                                                            decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                                   g_sched_scheduled,
                                                                   NULL,
                                                                   e.dt_begin_tstz),
                                                            i_prof.institution,
                                                            i_prof.software)
                               ELSE
                                NULL
                           END dt_begin,
                           decode(l_reasongrid,
                                  g_yes,
                                  pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                              i_prof,
                                                                                                              ei.id_episode,
                                                                                                              s.id_schedule),
                                                                   4000)) visit_reason,
                           sp.dt_target_tstz dt,
                           NULL therapeutic_doctor,
                           decode(s.flg_present, 'N', l_no_present_patient) patient_presence,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                           NULL desc_room, --decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                           sg.flg_contact_type,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat_type),
                                                                                              g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           -- Display number of responsible PHYSICIANS for the episode, 
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_doc,
                                                ei.id_episode,
                                                nvl(ei.id_professional,
                                                    (SELECT ps.id_professional
                                                       FROM sch_prof_outp ps
                                                      WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                        AND rownum = 1)),
                                                l_handoff_type,
                                                'G') name_prof,
                           -- Only display the name of the responsible nurse, for all hand-off mechanisms
                           pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                           -- Team name or Resident physician(s)
                           decode(l_show_resident_physician,
                                  pk_alert_constant.g_yes,
                                  pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                             i_prof,
                                                                             ei.id_episode,
                                                                             l_handoff_type,
                                                                             pk_hand_off_core.g_resident,
                                                                             'G'),
                                  pk_prof_teams.get_prof_current_team(i_lang,
                                                                      i_prof,
                                                                      e.id_department,
                                                                      ei.id_software,
                                                                      nvl(ei.id_professional,
                                                                          (SELECT ps.id_professional
                                                                             FROM sch_prof_outp ps
                                                                            WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                                              AND rownum = 1)),
                                                                      ei.id_first_nurse_resp)) prof_team,
                           
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_doc,
                                                ei.id_episode,
                                                nvl(ei.id_professional,
                                                    (SELECT ps.id_professional
                                                       FROM sch_prof_outp ps
                                                      WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                        AND rownum = 1)),
                                                l_handoff_type,
                                                'T') name_prof_tooltip,
                           -- 2) Responsible nurse
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_nurse,
                                                ei.id_episode,
                                                ei.id_first_nurse_resp,
                                                l_handoff_type,
                                                'T') name_nurse_tooltip,
                           -- 3) Responsible team 
                           pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         e.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_handoff_type,
                                                         NULL) prof_team_tooltip,
                           s.id_group,
                           pk_alert_constant.g_no flg_group_header,
                           'ExtendIcon' extend_icon,
                           pk_alert_constant.get_no prof_follow_add,
                           pk_alert_constant.get_no prof_follow_remove,
                           pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) sch_event_desc
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = s.id_schedule
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                       AND ei.id_patient = sg.id_patient
                      LEFT JOIN episode e
                        ON e.id_episode = ei.id_episode
                    --LEFT JOIN sch_prof_outp spo
                    --  ON spo.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN grid_task gt
                        ON gt.id_episode = ei.id_episode
                      LEFT JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                     WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                           d.column_value
                                            FROM TABLE(l_group_ids) d)
                    --group header
                    UNION ALL
                    SELECT sp.id_epis_type,
                           NULL id_schedule, --s.id_schedule,
                           NULL d_patient, -- sg.id_patient,
                           NULL num_clin_record, --(SELECT cr.num_clin_record FROM clin_record cr WHERE cr.id_patient = sg.id_patient AND cr.id_institution = i_prof.institution AND rownum < 2) num_clin_record,
                           NULL id_episode, --decode(e.flg_ehr,pk_ehr_access.g_flg_ehr_normal,ei.id_episode,decode(l_to_old_area, g_yes, NULL, ei.id_episode)) id_episode,
                           e.flg_ehr,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        e.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv,
                           l_sch_t640 name, -- pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                           l_sch_t640 name_to_sort, --pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,
                           NULL pat_ndo, --  pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           NULL pat_nd_icon, --  pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           NULL gender, --(SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender  FROM patient pat WHERE sg.id_patient = pat.id_patient) gender,
                           NULL pat_age, --pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                           NULL photo, -- pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           'A' flg_state,
                           sp.flg_sched,
                           get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                           pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                           'N' flg_temp,
                           g_sysdate_char dt_server,
                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_scheduled,
                                  '',
                                  decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                               ELSE
                                NULL
                           END desc_drug_presc,
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                       i_prof,
                                                                       pk_grid.get_prioritary_task(i_lang,
                                                                                                   i_prof,
                                                                                                   gt.icnp_intervention,
                                                                                                   pk_grid.get_prioritary_task(i_lang,
                                                                                                                               i_prof,
                                                                                                                               gt.nurse_activity,
                                                                                                                               pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                           i_prof,
                                                                                                                                                           pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                       i_prof,
                                                                                                                                                                                       gt.intervention,
                                                                                                                                                                                       gt.monitorization,
                                                                                                                                                                                       NULL,
                                                                                                                                                                                       g_flg_doctor),
                                                                                                                                                           gt.teach_req,
                                                                                                                                                           NULL,
                                                                                                                                                           g_flg_doctor),
                                                                                                                               NULL,
                                                                                                                               g_flg_doctor),
                                                                                                   NULL,
                                                                                                   g_flg_doctor))
                               ELSE
                                NULL
                           END desc_interv_presc,
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_analysis, i_prof_cat_type)
                               ELSE
                                NULL
                           END desc_analysis_req,
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_exam, i_prof_cat_type)
                               ELSE
                                NULL
                           END desc_exam_req,
                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_adm_disch,
                                  3,
                                  g_sched_med_disch,
                                  2,
                                  1) rank,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => e.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           nvl((SELECT nvl(p.nick_name, p.name)
                                 FROM professional p
                                WHERE p.id_professional = ei.id_professional),
                               (SELECT nvl(p.nick_name, p.name)
                                  FROM sch_prof_outp ps, professional p
                                 WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                   AND p.id_professional = ps.id_professional
                                   AND rownum < 2)) doctor_name,
                           -- Updated By Eduardo Lourenco
                           (SELECT substr(concatenate(decode(nvl(ec.id_complaint,
                                                                 decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                             NULL,
                                                             ec.patient_complaint,
                                                             pk_translation.get_translation(i_lang,
                                                                                            'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                            nvl(ec.id_complaint,
                                                                                                decode(s2.flg_reason_type,
                                                                                                       'C',
                                                                                                       s2.id_reason,
                                                                                                       NULL)))) || '; '),
                                          1,
                                          length(concatenate(decode(nvl(ec.id_complaint,
                                                                        decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                                    NULL,
                                                                    ec.patient_complaint,
                                                                    pk_translation.get_translation(i_lang,
                                                                                                   'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                   nvl(ec.id_complaint,
                                                                                                       decode(s2.flg_reason_type,
                                                                                                              'C',
                                                                                                              s2.id_reason,
                                                                                                              NULL))) || '; '))) -
                                          length('; '))
                              FROM schedule s2
                              LEFT JOIN epis_info ei2
                                ON ei2.id_schedule = s2.id_schedule
                              LEFT JOIN epis_complaint ec
                                ON ec.id_episode = ei2.id_episode
                             WHERE s2.id_schedule = s.id_schedule
                               AND nvl(ec.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active) reason,
                           -----
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                pk_date_utils.date_send_tsz(i_lang,
                                                            decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                                   g_sched_scheduled,
                                                                   NULL,
                                                                   e.dt_begin_tstz),
                                                            i_prof.institution,
                                                            i_prof.software)
                               ELSE
                                NULL
                           END dt_begin,
                           decode(l_reasongrid,
                                  g_yes,
                                  pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                              i_prof,
                                                                                                              ei.id_episode,
                                                                                                              s.id_schedule),
                                                                   4000)) visit_reason,
                           sp.dt_target_tstz dt,
                           NULL therapeutic_doctor,
                           decode(s.flg_present, 'N', l_no_present_patient) patient_presence,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                           decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                           NULL flg_contact_type, --sg.flg_contact_type,
                           NULL flg_contact, --pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat_type),
                                                                                              g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           -- Display number of responsible PHYSICIANS for the episode, 
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_doc,
                                                ei.id_episode,
                                                nvl(ei.id_professional,
                                                    (SELECT ps.id_professional
                                                       FROM sch_prof_outp ps
                                                      WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                        AND rownum = 1)),
                                                l_handoff_type,
                                                'G') name_prof,
                           -- Only display the name of the responsible nurse, for all hand-off mechanisms
                           pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                           -- Team name or Resident physician(s)
                           decode(l_show_resident_physician,
                                  pk_alert_constant.g_yes,
                                  pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                             i_prof,
                                                                             ei.id_episode,
                                                                             l_handoff_type,
                                                                             pk_hand_off_core.g_resident,
                                                                             'G'),
                                  pk_prof_teams.get_prof_current_team(i_lang,
                                                                      i_prof,
                                                                      e.id_department,
                                                                      ei.id_software,
                                                                      nvl(ei.id_professional,
                                                                          (SELECT ps.id_professional
                                                                             FROM sch_prof_outp ps
                                                                            WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                                              AND rownum = 1)),
                                                                      ei.id_first_nurse_resp)) prof_team,
                           
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_doc,
                                                ei.id_episode,
                                                nvl(ei.id_professional,
                                                    (SELECT ps.id_professional
                                                       FROM sch_prof_outp ps
                                                      WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                        AND rownum = 1)),
                                                l_handoff_type,
                                                'T') name_prof_tooltip,
                           -- 2) Responsible nurse
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_nurse,
                                                ei.id_episode,
                                                ei.id_first_nurse_resp,
                                                l_handoff_type,
                                                'T') name_nurse_tooltip,
                           -- 3) Responsible team 
                           pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         e.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_handoff_type,
                                                         NULL) prof_team_tooltip,
                           s.id_group,
                           pk_alert_constant.g_yes flg_group_header,
                           NULL extend_icon,
                           pk_alert_constant.get_no prof_follow_add,
                           pk_alert_constant.get_no prof_follow_remove,
                           pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) sch_event_desc
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = s.id_schedule
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                       AND ei.id_patient = sg.id_patient
                      LEFT JOIN episode e
                        ON e.id_episode = ei.id_episode
                    --LEFT JOIN sch_prof_outp spo
                    --  ON spo.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN grid_task gt
                        ON gt.id_episode = ei.id_episode
                      LEFT JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                     WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                              d.column_value
                                               FROM TABLE(l_schedule_ids) d)
                    --
                    UNION ALL
                    SELECT sp.id_epis_type,
                           s.id_schedule,
                           sg.id_patient,
                           (SELECT cr.num_clin_record
                              FROM clin_record cr
                             WHERE cr.id_patient = sg.id_patient
                               AND cr.id_institution = i_prof.institution
                               AND rownum < 2) num_clin_record,
                           ei.id_episode id_episode,
                           e.flg_ehr,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        e.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                              FROM patient pat
                             WHERE sg.id_patient = pat.id_patient) gender,
                           pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                           (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                              FROM dep_clin_serv dcs, clinical_service cs
                             WHERE dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                               AND cs.id_clinical_service = dcs.id_clinical_service) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) flg_state,
                           sp.flg_sched,
                           pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                       pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                         i_prof,
                                                                                         ei.id_dep_clin_serv,
                                                                                         e.flg_ehr,
                                                                                         pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                         e.flg_ehr)),
                                                       i_lang) img_state,
                           pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang) img_sched,
                           'N' flg_temp,
                           g_sysdate_char dt_server,
                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_scheduled,
                                  '',
                                  decode('N', 'Y', pk_message.get_message(i_lang, 'COMMON_M012'), '')) desc_temp,
                           
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                               ELSE
                                NULL
                           END desc_drug_presc,
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                       i_prof,
                                                                       pk_grid.get_prioritary_task(i_lang,
                                                                                                   i_prof,
                                                                                                   gt.icnp_intervention,
                                                                                                   pk_grid.get_prioritary_task(i_lang,
                                                                                                                               i_prof,
                                                                                                                               gt.nurse_activity,
                                                                                                                               pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                           i_prof,
                                                                                                                                                           pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                                       i_prof,
                                                                                                                                                                                       gt.intervention,
                                                                                                                                                                                       gt.monitorization,
                                                                                                                                                                                       NULL,
                                                                                                                                                                                       g_flg_doctor),
                                                                                                                                                           gt.teach_req,
                                                                                                                                                           NULL,
                                                                                                                                                           g_flg_doctor),
                                                                                                                               NULL,
                                                                                                                               g_flg_doctor),
                                                                                                   NULL,
                                                                                                   g_flg_doctor))
                               ELSE
                                NULL
                           END desc_interv_presc,
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_analysis, i_prof_cat_type)
                               ELSE
                                NULL
                           END desc_analysis_req,
                           CASE
                               WHEN gt.id_episode IS NOT NULL THEN
                                pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, g_task_exam, i_prof_cat_type)
                               ELSE
                                NULL
                           END desc_exam_req,
                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_adm_disch,
                                  3,
                                  g_sched_med_disch,
                                  2,
                                  1) rank,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => e.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           nvl((SELECT nvl(p.nick_name, p.name)
                                 FROM professional p
                                WHERE p.id_professional = ei.id_professional),
                               (SELECT nvl(p.nick_name, p.name)
                                  FROM sch_prof_outp ps, professional p
                                 WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                   AND p.id_professional = ps.id_professional
                                   AND rownum < 2)) doctor_name,
                           -- Updated By Eduardo Lourenco
                           (SELECT substr(concatenate(decode(nvl(ec.id_complaint,
                                                                 decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                             NULL,
                                                             ec.patient_complaint,
                                                             pk_translation.get_translation(i_lang,
                                                                                            'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                            nvl(ec.id_complaint,
                                                                                                decode(s2.flg_reason_type,
                                                                                                       'C',
                                                                                                       s2.id_reason,
                                                                                                       NULL)))) || '; '),
                                          1,
                                          length(concatenate(decode(nvl(ec.id_complaint,
                                                                        decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                                    NULL,
                                                                    ec.patient_complaint,
                                                                    pk_translation.get_translation(i_lang,
                                                                                                   'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                   nvl(ec.id_complaint,
                                                                                                       decode(s2.flg_reason_type,
                                                                                                              'C',
                                                                                                              s2.id_reason,
                                                                                                              NULL))) || '; '))) -
                                          length('; '))
                              FROM schedule s2
                              LEFT JOIN epis_info ei2
                                ON ei2.id_schedule = s2.id_schedule
                              LEFT JOIN epis_complaint ec
                                ON ec.id_episode = ei2.id_episode
                             WHERE s2.id_schedule = s.id_schedule
                               AND nvl(ec.flg_status, pk_alert_constant.g_active) = pk_alert_constant.g_active) reason,
                           ------
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                pk_date_utils.date_send_tsz(i_lang,
                                                            decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                                   g_sched_scheduled,
                                                                   NULL,
                                                                   e.dt_begin_tstz),
                                                            i_prof.institution,
                                                            i_prof.software)
                               ELSE
                                NULL
                           END dt_begin,
                           l_therap_decision_consult visit_reason,
                           sp.dt_target_tstz dt,
                           '(' ||
                           pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) || ')' therapeutic_doctor,
                           decode(s.flg_present, 'N', l_no_present_patient) patient_presence,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                           decode(e.flg_ehr, 'S', NULL, get_room_desc(i_lang, ei.id_room)) desc_room,
                           sg.flg_contact_type,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat_type),
                                                                                              g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           -- Display number of responsible PHYSICIANS for the episode, 
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_doc,
                                                ei.id_episode,
                                                nvl(ei.id_professional,
                                                    (SELECT ps.id_professional
                                                       FROM sch_prof_outp ps
                                                      WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                        AND rownum = 1)),
                                                l_handoff_type,
                                                'G') name_prof,
                           -- Only display the name of the responsible nurse, for all hand-off mechanisms
                           pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                           -- Team name or Resident physician(s)
                           decode(l_show_resident_physician,
                                  pk_alert_constant.g_yes,
                                  pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                             i_prof,
                                                                             ei.id_episode,
                                                                             l_handoff_type,
                                                                             pk_hand_off_core.g_resident,
                                                                             'G'),
                                  pk_prof_teams.get_prof_current_team(i_lang,
                                                                      i_prof,
                                                                      e.id_department,
                                                                      ei.id_software,
                                                                      nvl(ei.id_professional,
                                                                          (SELECT ps.id_professional
                                                                             FROM sch_prof_outp ps
                                                                            WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                                              AND rownum = 1)),
                                                                      ei.id_first_nurse_resp)) prof_team,
                           
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_doc,
                                                ei.id_episode,
                                                nvl(ei.id_professional,
                                                    (SELECT ps.id_professional
                                                       FROM sch_prof_outp ps
                                                      WHERE ps.id_schedule_outp = sp.id_schedule_outp
                                                        AND rownum = 1)),
                                                l_handoff_type,
                                                'T') name_prof_tooltip,
                           -- 2) Responsible nurse
                           get_responsibles_str(i_lang,
                                                i_prof,
                                                pk_alert_constant.g_cat_type_nurse,
                                                ei.id_episode,
                                                ei.id_first_nurse_resp,
                                                l_handoff_type,
                                                'T') name_nurse_tooltip,
                           -- 3) Responsible team 
                           pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         e.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_handoff_type,
                                                         NULL) prof_team_tooltip,
                           0 id_group,
                           pk_alert_constant.g_no flg_group_header,
                           NULL extend_icon,
                           decode(pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule),
                                  pk_alert_constant.g_no,
                                  decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                          i_prof,
                                                                                                          ei.id_episode,
                                                                                                          i_prof_cat_type,
                                                                                                          l_handoff_type,
                                                                                                          pk_alert_constant.g_yes),
                                                                      i_prof.id),
                                         -1,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no),
                                  pk_alert_constant.g_no) prof_follow_add,
                           pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove,
                           pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) sch_event_desc
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = s.id_schedule
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                      LEFT JOIN episode e
                        ON e.id_episode = ei.id_episode
                       AND e.flg_ehr != g_flg_ehr
                    --LEFT JOIN sch_resource sr
                    --  ON sr.id_schedule = s.id_schedule
                      LEFT JOIN grid_task gt
                        ON gt.id_episode = ei.id_episode
                      LEFT JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                     WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                       AND decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_adm_disch,
                                  get_grid_task_count(i_lang,
                                                      i_prof,
                                                      ei.id_episode,
                                                      e.id_visit,
                                                      i_prof_cat_type,
                                                      l_sysdate_char_short),
                                  1) = 1
                       AND sp.id_software = i_prof.software
                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico                     
                       AND sp.id_epis_type != g_epis_type_nurse
                       AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                       AND s.id_instit_requested = i_prof.institution
                       AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, g_sched_canc)
                       AND s.id_sch_event = g_sch_event_therap_decision
                          --AND sr.id_professional = i_prof.id
                       AND EXISTS (SELECT 0
                              FROM prof_room pr
                             WHERE pr.id_professional = i_prof.id
                               AND ei.id_room = pr.id_room)) t
             WHERE (pk_grid.get_schedule_real_state(t.flg_state, t.flg_ehr) !=
                   decode(t.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                   l_show_nurse_disch = g_yes)
               AND (l_show_med_disch = g_yes OR
                   (l_show_med_disch = g_no AND
                   pk_grid.get_schedule_real_state(t.flg_state, t.flg_ehr) != g_sched_med_disch))
             ORDER BY t.rank, t.dt, t.dt_begin;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'DOCTOR_EFECTIV_PP_MY_ROOMS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END doctor_efectiv_pp_my_rooms;

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
    ) RETURN BOOLEAN IS
    
        l_id_sys_shortcut sys_shortcut.id_sys_shortcut%TYPE;
    
        CURSOR c_has_adm_shortcut IS
            SELECT ss.id_sys_shortcut
              FROM sys_shortcut ss
             WHERE ss.id_sys_shortcut = g_startup_sys_shortcut
               AND ss.id_software = i_prof.software;
        --AND ss.id_institution = i_prof.institution;
    
    BEGIN
    
        g_error := 'OPEN C_HAS_ADM_SHORTCUT';
        OPEN c_has_adm_shortcut;
        FETCH c_has_adm_shortcut
            INTO l_id_sys_shortcut;
        g_found := c_has_adm_shortcut%FOUND;
        CLOSE c_has_adm_shortcut;
    
        IF g_found
           AND l_id_sys_shortcut IS NOT NULL
        THEN
            o_show_viewer := 'Y';
        ELSE
            o_show_viewer := 'N';
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SHOW_ADM_STARTUP_VIEWER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END show_adm_startup_viewer;

    /**
    * Get paramedical appointments (social / dietitian).
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_dt             date
    * @param i_type           {*} 'D' Consults for this paramedical
    *                         {*} 'C' Consults for all paramedical    
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
    * @version                2.6.0.1
    * @since                  2010/01/20
    * @changed                Elisabete Bugalho
    * @ changed on            05-04-2009
    * @ depends               social_efectiv
    *                         dietitian_efectiv
    */
    FUNCTION paramedical_efectiv
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
    ) RETURN BOOLEAN IS
        l_wr_available              sys_config.value%TYPE;
        l_dt_min                    schedule_outp.dt_target_tstz%TYPE;
        l_dt_max                    schedule_outp.dt_target_tstz%TYPE;
        l_to_old_area               sys_config.value%TYPE;
        l_reasongrid                sys_config.value%TYPE;
        l_waiting_room_available    sys_config.value%TYPE := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
        l_waiting_room_sys_external sys_config.value%TYPE := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM',
                                                                                     i_prof);
        l_show_med_disch            sys_config.value%TYPE;
    BEGIN
        g_error        := 'GET G_SYSDATE';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => g_sysdate_tstz, i_prof => i_prof);
    
        ---------------------------------
        g_error := 'CALL get_date_bounds';
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        ---------------------------------
        g_error := 'GET CONFIG DEFINITIONS';
        --l_to_old_area    := pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof);
        l_reasongrid     := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID', i_prof);
        l_show_med_disch := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID', i_prof), g_yes);
        l_wr_available   := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
    
        ---------------------------------
        g_error := 'OPEN o_doc - ' || i_type;
        IF i_type = g_type_my_appointments
        THEN
            OPEN o_doc FOR
                SELECT s.id_schedule,
                       sg.id_patient,
                       (SELECT cr.num_clin_record
                          FROM clin_record cr
                         WHERE cr.id_patient = sg.id_patient
                           AND cr.id_institution = i_prof.institution
                           AND rownum < 2) num_clin_record,
                       ei.id_episode id_episode,
                       ei.id_episode id_episode_by_pat,
                       e.flg_ehr,
                       decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                              g_sched_scheduled,
                              '',
                              pk_date_utils.date_char_hour_tsz(i_lang,
                                                               e.dt_begin_tstz,
                                                               i_prof.institution,
                                                               i_prof.software)) dt_efectiv,
                       pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                       (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender
                          FROM patient pat
                         WHERE sg.id_patient = pat.id_patient) gender,
                       pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                       pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                       pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                       pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                       decode(s.flg_status,
                              g_sched_canc,
                              g_sched_canc,
                              pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                       sp.flg_sched,
                       pk_sysdomain.get_img(i_lang,
                                            g_schdl_outp_state_domain,
                                            pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) img_state,
                       g_sysdate_char dt_server,
                       CASE
                            WHEN i_dt IS NULL THEN
                             pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                     i_prof                      => i_prof,
                                                     i_waiting_room_available    => l_waiting_room_available,
                                                     i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                     i_id_episode                => ei.id_episode,
                                                     i_flg_state                 => sp.flg_state,
                                                     i_flg_ehr                   => e.flg_ehr,
                                                     i_id_dcs_requested          => s.id_dcs_requested)
                            ELSE
                             pk_alert_constant.g_no
                        END wr_call,
                       decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                              g_sched_scheduled,
                              NULL,
                              pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof)) dt_begin,
                       decode(l_reasongrid, g_yes, s.reason_notes) visit_reason,
                       pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                       decode(e.id_episode,
                              NULL,
                              '',
                              pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                      nvl(e.flg_appointment_type, g_null_appointment_type),
                                                      i_lang)) cont_type,
                       sg.flg_contact_type,
                       (SELECT pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type)
                          FROM dual) icon_contact_type,
                       pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                       pk_alert_constant.g_no prof_follow_add,
                       pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(ei.id_professional, spo.id_professional)) resp_prof_name
                  FROM schedule_outp sp,
                       schedule      s,
                       sch_group     sg,
                       epis_info     ei,
                       sch_prof_outp spo,
                       epis_type     et,
                       episode       e
                 WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                   AND ei.id_episode = e.id_episode(+)
                   AND sp.id_software = i_prof.software
                   AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, g_sched_canc)
                   AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                   AND (l_show_med_disch = g_yes OR
                       (l_show_med_disch = g_no AND
                       pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
                   AND s.id_schedule = sp.id_schedule
                   AND s.id_instit_requested = i_prof.institution
                   AND (nvl(ei.id_professional, spo.id_professional) = i_prof.id OR
                       (pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) =
                       pk_alert_constant.g_yes))
                   AND spo.id_schedule_outp(+) = sp.id_schedule_outp
                   AND sg.id_schedule = s.id_schedule
                   AND s.id_schedule = ei.id_schedule(+)
                   AND sp.id_epis_type = et.id_epis_type
                 ORDER BY decode(s.flg_status,
                                 g_sched_canc,
                                 3,
                                 decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                        g_sched_med_disch,
                                        2,
                                        1)),
                          sp.dt_target_tstz,
                          dt_begin;
        ELSIF i_type = g_type_all_appointments
        THEN
            OPEN o_doc FOR
                SELECT s.id_schedule,
                       sg.id_patient,
                       (SELECT cr.num_clin_record
                          FROM clin_record cr
                         WHERE cr.id_patient = sg.id_patient
                           AND cr.id_institution = i_prof.institution
                           AND rownum < 2) num_clin_record,
                       ei.id_episode id_episode,
                       ei.id_episode id_episode_by_pat,
                       decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                              g_sched_scheduled,
                              '',
                              pk_date_utils.date_char_hour_tsz(i_lang,
                                                               e.dt_begin_tstz,
                                                               i_prof.institution,
                                                               i_prof.software)) dt_efectiv,
                       pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                       pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,
                       pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                       pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                       (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang)
                          FROM patient pat
                         WHERE sg.id_patient = pat.id_patient) gender,
                       pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                       pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                       pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                       pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                       decode(s.flg_status,
                              g_sched_canc,
                              g_sched_canc,
                              pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                       sp.flg_sched,
                       pk_sysdomain.get_img(i_lang,
                                            g_schdl_outp_state_domain,
                                            pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) img_state,
                       g_sysdate_char dt_server,
                       CASE
                            WHEN i_dt IS NULL THEN
                             pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                     i_prof                      => i_prof,
                                                     i_waiting_room_available    => l_waiting_room_available,
                                                     i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                     i_id_episode                => ei.id_episode,
                                                     i_flg_state                 => sp.flg_state,
                                                     i_flg_ehr                   => e.flg_ehr,
                                                     i_id_dcs_requested          => s.id_dcs_requested)
                            ELSE
                             pk_alert_constant.g_no
                        END wr_call,
                       decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                              g_sched_scheduled,
                              NULL,
                              pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof)) dt_begin,
                       decode(l_reasongrid,
                              g_yes,
                              pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                          i_prof,
                                                                                                          ei.id_episode,
                                                                                                          s.id_schedule),
                                                               4000)) visit_reason,
                       pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                       decode(e.id_episode,
                              NULL,
                              '',
                              pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                      nvl(e.flg_appointment_type, g_null_appointment_type),
                                                      i_lang)) cont_type,
                       sg.flg_contact_type,
                       (SELECT pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type)
                          FROM dual) icon_contact_type,
                       pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                       decode(pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule),
                              pk_alert_constant.g_no,
                              decode(nvl(ei.id_professional, spo.id_professional),
                                     i_prof.id,
                                     pk_alert_constant.g_no,
                                     pk_alert_constant.g_yes),
                              pk_alert_constant.g_no) prof_follow_add,
                       pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(ei.id_professional, spo.id_professional)) resp_prof_name
                  FROM schedule_outp sp,
                       schedule      s,
                       sch_group     sg,
                       epis_info     ei,
                       epis_type     et,
                       episode       e,
                       sch_prof_outp spo
                 WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                   AND ei.id_episode = e.id_episode(+)
                   AND sp.id_software = i_prof.software
                   AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                   AND (l_show_med_disch = g_yes OR
                       (l_show_med_disch = g_no AND
                       pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
                   AND s.id_schedule = sp.id_schedule
                   AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, g_sched_canc)
                   AND s.id_instit_requested = i_prof.institution
                   AND EXISTS (SELECT 0
                          FROM prof_dep_clin_serv pdcs
                         WHERE pdcs.id_professional = i_prof.id
                           AND pdcs.flg_status = g_selected
                           AND pdcs.id_dep_clin_serv = ei.id_dep_clin_serv)
                   AND sg.id_schedule = s.id_schedule
                   AND ei.id_schedule(+) = s.id_schedule
                   AND sp.id_epis_type = et.id_epis_type
                   AND spo.id_schedule_outp = sp.id_schedule_outp
                 ORDER BY decode(s.flg_status,
                                 g_sched_canc,
                                 3,
                                 decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                        g_sched_med_disch,
                                        2,
                                        1)),
                          sp.dt_target_tstz,
                          dt_begin;
        
        ELSE
            pk_types.open_my_cursor(o_doc);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'PARAMEDICAL_EFECTIV',
                                              o_error    => o_error);
            RETURN FALSE;
    END paramedical_efectiv;
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
    ) RETURN BOOLEAN IS
    
        l_num_days_back    sys_config.value%TYPE;
        l_num_days_forward sys_config.value%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error            := 'GET NUM DAYS';
        l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', i_prof);
        l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
        IF l_num_days_forward <= 0
        THEN
            l_num_days_forward := 10;
        END IF;
    
        g_error := 'OPEN O_DATE';
        OPEN o_date FOR
            SELECT pk_grid_amb.get_extense_day_desc(i_lang, t.day) date_desc, DAY date_tstz, today
              FROM (SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz - LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_back
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz, 'DD') AS DAY,
                           pk_alert_constant.g_yes today
                      FROM dual
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz + LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_forward) t
             ORDER BY t.day;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'PARAMEDICAL_EFECTIV_DATES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
    END paramedical_efectiv_dates;

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
    * @version                2.6.0.1
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL paramedical_efectiv';
        IF NOT paramedical_efectiv(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_dt            => i_dt,
                                   i_type          => i_type,
                                   i_prof_cat_type => i_prof_cat_type,
                                   o_doc           => o_doc,
                                   o_flg_show      => o_flg_show,
                                   o_msg_title     => o_msg_title,
                                   o_body_title    => o_body_title,
                                   o_body_detail   => o_body_detail,
                                   o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SOCIAL_EFECTIV',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END social_efectiv;

    /**
    * Get dietitian appointments.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_dt             date
    * @param i_type           D - Consults for this dietitian
    *                         C - Consults for all dietitian        
    * @param i_prof_cat_type  logged professional category
    * @param o_doc            cursor
    * @param o_flg_show       date browser warning related data
    * @param o_msg_title      date browser warning related data
    * @param o_body_title     date browser warning related data
    * @param o_body_detail    date browser warning related data
    * @param o_error                  error
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL paramedical_efectiv';
        IF NOT paramedical_efectiv(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_dt            => i_dt,
                                   i_type          => i_type,
                                   i_prof_cat_type => i_prof_cat_type,
                                   o_doc           => o_doc,
                                   o_flg_show      => o_flg_show,
                                   o_msg_title     => o_msg_title,
                                   o_body_title    => o_body_title,
                                   o_body_detail   => o_body_detail,
                                   o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'NUTRITIONIST_EFECTIV',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END nutritionist_efectiv;

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
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_SCHED_PRESENCE';
    
    BEGIN
    
        -- check fields and values received
    
        FOR i IN 1 .. i_field_id.count
        LOOP
        
            ----------------------------------------------------------------------------------------------------------
            -- SET APPOINTMENT TYPE
            ----------------------------------------------------------------------------------------------------------
        
            g_error := 'CALL pk_progress_notes.set_appointment_type';
            IF i_field_id(i) = 'APPOINTMENT'
            THEN
            
                IF NOT pk_progress_notes.set_appointment_type(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => i_id_episode,
                                                              i_dcs     => i_field_value(i),
                                                              o_error   => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
            ----------------------------------------------------------------------------------------------------------
            -- SET PRESENCE BY GROUP OR BY PATIENT
            ----------------------------------------------------------------------------------------------------------
            g_error := 'SET_PRESENCE - SET_GRID_APPOINTMENT';
            IF i_field_id(i) = 'PRESENCE'
            THEN
                -- by group
                IF i_id_group != 0
                   AND i_id_patient IS NULL
                THEN
                
                    IF NOT set_group_status_list(i_lang             => i_lang,
                                                 i_prof             => i_prof,
                                                 i_data             => i_field_value(i),
                                                 i_id_group         => i_id_group,
                                                 i_id_cancel_reason => NULL,
                                                 i_cancel_notes     => NULL,
                                                 i_context          => 'P',
                                                 o_error            => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    --else by patient 
                ELSE
                
                    IF NOT set_sched_presence(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_patient      => i_id_patient,
                                              i_episode      => i_id_episode,
                                              i_schedule     => i_id_schedule,
                                              i_flg_enc_type => i_field_value(i),
                                              o_error        => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                END IF;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_grid_appointment;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'SET_SCHED_PRESENCE';
        l_id_trans VARCHAR2(1000 CHAR);
        l_rowids   table_varchar := table_varchar();
        l_flg_ehr  episode.flg_ehr%TYPE;
    BEGIN
        g_error    := 'CALL pk_schedule_api_upstream.begin_new_transaction';
        l_id_trans := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id => NULL, i_prof => i_prof);
    
        g_error := 'CALL ts_sch_group.upd';
        ts_sch_group.upd(flg_contact_type_in  => i_flg_enc_type,
                         flg_contact_type_nin => FALSE,
                         where_in             => 'id_schedule=' || i_schedule || ' and id_patient=' || i_patient,
                         rows_out             => l_rowids);
        g_error := 'CALL t_data_gov_mnt.process_update';
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'SCH_GROUP',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_CONTACT_TYPE'));
    
        IF i_episode IS NOT NULL
        THEN
            SELECT e.flg_ehr
              INTO l_flg_ehr
              FROM episode e
             WHERE e.id_episode = i_episode;
        END IF;
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_id_trans, i_prof => i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_id_trans, i_prof => i_prof);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_sched_presence;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PRESENCE_STATUS_LIST';
    
        l_context VARCHAR2(10 CHAR);
    BEGIN
    
        IF i_context IS NULL
        THEN
            l_context := 'P';
        END IF;
    
        -- go by group
        IF i_id_group != 0
        THEN
        
            IF NOT get_group_status_list(i_lang     => i_lang,
                                         i_prof     => i_prof,
                                         i_id_group => i_id_group,
                                         i_context  => l_context,
                                         o_list     => o_list,
                                         o_error    => o_error)
            THEN
                g_error := 'GROUP LIST ERROR';
                RAISE g_exception;
            END IF;
        
            -- go by "patient" schedule
        ELSIF i_id_group = 0
              OR i_id_group IS NULL
        THEN
        
            IF NOT get_sched_presence_domain(i_lang     => i_lang,
                                             i_patient  => i_id_patient,
                                             i_schedule => i_id_schedule,
                                             o_data     => o_list,
                                             o_error    => o_error)
            THEN
                g_error := 'GET PRESENCE DOMAIN ERROR';
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_list);
            RETURN FALSE;
    END get_presence_status_list;
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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SCHED_PRESENCE_DOMAIN';
        l_status       schedule.flg_status%TYPE;
        l_flg_enc_type sch_group.flg_contact_type%TYPE;
        l_prof         profissional := profissional(NULL, NULL, NULL);
        l_is_contact   VARCHAR2(1 CHAR);
        CURSOR c_sch_info IS
            SELECT decode(s.flg_status, g_sched_canc, g_sched_canc, nvl(sp.flg_state, s.flg_status)), sg.flg_contact_type
              FROM schedule s
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
              LEFT JOIN schedule_outp sp
                ON sp.id_schedule = s.id_schedule
             WHERE s.id_schedule = i_schedule
               AND sg.id_patient = i_patient;
    BEGIN
        g_error := 'OPEN c_sch_info';
        OPEN c_sch_info;
        FETCH c_sch_info
            INTO l_status, l_flg_enc_type;
        CLOSE c_sch_info;
    
        l_is_contact := pk_adt.is_contact(1, l_prof, i_patient);
    
        g_error := 'OPEN o_data';
        OPEN o_data FOR
            SELECT sd.desc_val label,
                   sd.val data,
                   sd.img_name icon,
                   decode(sd.val,
                          g_flg_contact_video,
                          pk_alert_constant.g_no,
                          decode(l_flg_enc_type,
                                 g_flg_contact_video,
                                 pk_alert_constant.g_no,
                                 decode(l_is_contact,
                                        pk_alert_constant.g_yes,
                                        pk_alert_constant.g_no,
                                        decode(l_status,
                                               'A',
                                               decode(l_flg_enc_type,
                                                      NULL,
                                                      pk_alert_constant.g_yes,
                                                      sd.val,
                                                      pk_alert_constant.g_no,
                                                      pk_alert_constant.g_yes),
                                               'E',
                                               decode(l_flg_enc_type,
                                                      NULL,
                                                      pk_alert_constant.g_yes,
                                                      sd.val,
                                                      pk_alert_constant.g_no,
                                                      pk_alert_constant.g_yes),
                                               pk_alert_constant.g_no)))) flg_action
              FROM sys_domain sd
             WHERE sd.code_domain = g_domain_sch_presence
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.flg_available = pk_alert_constant.g_yes
             ORDER BY sd.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_data);
            RETURN FALSE;
    END get_sched_presence_domain;

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
    ) RETURN BOOLEAN IS
        l_waiting_room_sys_external sys_config.value%TYPE := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM',
                                                                                     i_prof);
        l_cancel_sched              sys_config.value%TYPE;
        l_show_med_disch            sys_config.value%TYPE;
        l_show_nurse_disch          sys_config.value%TYPE;
        l_handoff_type              sys_config.value%TYPE;
        l_dt_min                    schedule_outp.dt_target_tstz%TYPE;
        l_dt_max                    schedule_outp.dt_target_tstz%TYPE;
        l_waiting_room_available    sys_config.value%TYPE;
        l_group_ids                 table_number := table_number();
        l_schedule_ids              table_number := table_number();
        l_sch_t640                  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
        l_can_cancel                VARCHAR2(1 CHAR);
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => g_sysdate_tstz, i_prof => i_prof);
    
        g_error := 'CALL get_date_bounds';
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_date, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        g_error            := 'SET configs';
        g_epis_type_nurse  := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => i_prof);
        l_cancel_sched     := pk_sysconfig.get_config(i_code_cf => 'FLG_CANCEL_SCHEDULE', i_prof => i_prof);
        l_show_med_disch   := nvl(pk_sysconfig.get_config(i_code_cf => 'SHOW_MEDICAL_DISCHARGED_GRID', i_prof => i_prof),
                                  g_yes);
        l_show_nurse_disch := nvl(pk_sysconfig.get_config(i_code_cf => 'SHOW_NURSE_DISCHARGED_GRID', i_prof => i_prof),
                                  g_no);
    
        l_can_cancel := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_intern_name => 'CANCEL_EPISODE');
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        l_waiting_room_available := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
    
        SELECT DISTINCT s.id_group
          BULK COLLECT
          INTO l_group_ids
          FROM schedule_outp sp
          JOIN schedule s
            ON sp.id_schedule = s.id_schedule
          JOIN sch_prof_outp ps
            ON sp.id_schedule_outp = ps.id_schedule_outp
          JOIN sch_group sg
            ON sp.id_schedule = sg.id_schedule
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
          JOIN patient pat
            ON sg.id_patient = pat.id_patient
          LEFT JOIN epis_info ei
            ON sp.id_schedule = ei.id_schedule
          LEFT JOIN episode e
            ON ei.id_episode = e.id_episode
          LEFT JOIN grid_task gt
            ON ei.id_episode = gt.id_episode
         WHERE sp.id_software = i_prof.software
           AND sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
           AND s.id_instit_requested = i_prof.institution
           AND (l_show_med_disch = g_yes OR
               (l_show_med_disch = g_no AND
               pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
           AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
               decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
               l_show_nurse_disch = g_yes)
           AND ((ps.id_professional = i_prof.id AND
               (e.id_episode IS NULL OR e.flg_ehr = pk_ehr_access.g_flg_ehr_scheduled)) OR
               (pk_utils.search_table_number(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                                   i_prof,
                                                                                   e.id_episode,
                                                                                   i_prof_cat,
                                                                                   l_handoff_type),
                                              i_prof.id) > 0 AND e.flg_ehr != pk_ehr_access.g_flg_ehr_scheduled))
           AND se.flg_is_group = pk_alert_constant.g_yes
           AND s.id_group IS NOT NULL;
    
        l_schedule_ids := get_schedule_ids(l_group_ids);
    
        g_error := 'OPEN o_grid';
        OPEN o_grid FOR
            SELECT t.id_schedule,
                   t.id_patient,
                   t.id_episode,
                   t.name,
                   t.name_to_sort,
                   t.pat_ndo,
                   t.pat_nd_icon,
                   t.gender,
                   t.pat_age,
                   t.photo,
                   t.cons_type,
                   t.cont_type,
                   t.img_sched,
                   t.dt_target,
                   t.flg_state,
                   t.flg_sched,
                   t.designated_provider,
                   t.desc_resp,
                   t.desc_room,
                   t.dt_efectiv,
                   t.dt_efectiv_compl,
                   t.img_state,
                   t.dt_server,
                   CASE
                        WHEN i_date IS NULL THEN
                         t.wr_call
                        ELSE
                         pk_alert_constant.g_no
                    END wr_call,
                   t.flg_nurse,
                   t.flg_button_ok,
                   t.flg_button_cancel,
                   t.flg_button_detail,
                   t.flg_cancel,
                   t.flg_contact_type,
                   t.icon_contact_type,
                   t.desc_drug_vaccine_req,
                   t.desc_nur_interv_monit_tea,
                   t.desc_ana_exam_req,
                   t.desc_dressings,
                   t.desc_icnp,
                   t.flg_contact,
                   t.id_group,
                   t.flg_group_header,
                   t.extend_icon,
                   t.prof_follow_add,
                   t.prof_follow_remove
              FROM (SELECT s.id_schedule,
                           pat.id_patient,
                           e.id_episode id_episode,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           decode(e.id_episode,
                                  NULL,
                                  NULL,
                                  pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                          nvl(e.flg_appointment_type, g_null_appointment_type),
                                                          i_lang)) cont_type,
                           (SELECT lpad(to_char(et.rank), 6, '0') || pk_translation.get_translation(i_lang, et.code_icon)
                              FROM epis_type et
                             WHERE et.id_epis_type = sp.id_epis_type) img_sched,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           decode(s.flg_status,
                                  g_sched_canc,
                                  g_sched_canc,
                                  pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                           sp.flg_sched,
                           pk_patient.get_designated_provider(i_lang,
                                                              i_prof,
                                                              pat.id_patient,
                                                              decode(e.flg_ehr,
                                                                     pk_ehr_access.g_flg_ehr_scheduled,
                                                                     NULL,
                                                                     e.id_episode)) designated_provider,
                           CASE
                                WHEN e.id_episode IS NULL
                                     OR e.flg_ehr = pk_ehr_access.g_flg_ehr_scheduled THEN
                                 pk_prof_utils.get_nickname(i_lang, ps.id_professional)
                                ELSE
                                 pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) ||
                                 decode(ei.id_professional,
                                        NULL,
                                        NULL,
                                        ' / ' || pk_prof_utils.get_nickname(i_lang, ei.id_professional))
                            END desc_resp,
                           get_room_desc(i_lang, decode(e.flg_ehr, pk_ehr_access.g_flg_ehr_scheduled, NULL, ei.id_room)) desc_room,
                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_scheduled,
                                  NULL,
                                  pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   e.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software)) dt_efectiv,
                           pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_efectiv_compl,
                           decode(sp.id_epis_type,
                                  g_epis_type_nurse,
                                  pk_sysdomain.get_ranked_img(g_schdl_nurse_state_domain,
                                                              decode(s.flg_status,
                                                                     g_sched_canc,
                                                                     g_sched_canc,
                                                                     pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                     e.flg_ehr)),
                                                              i_lang),
                                  pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                              pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                i_prof,
                                                                                                ei.id_dep_clin_serv,
                                                                                                e.flg_ehr,
                                                                                                pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                e.flg_ehr)),
                                                              i_lang)) img_state,
                           g_sysdate_char dt_server,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => e.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           decode(sp.id_epis_type, g_epis_type_nurse, g_yes, g_no) flg_nurse,
                           decode(sp.id_epis_type,
                                  g_epis_type_nurse,
                                  decode(s.flg_status, g_sched_canc, g_no, g_yes),
                                  g_yes) flg_button_ok,
                           decode(l_can_cancel,
                                  g_yes,
                                  decode(l_cancel_sched,
                                         g_yes,
                                         decode(sp.id_epis_type,
                                                g_epis_type_nurse,
                                                decode(decode(s.flg_status,
                                                              g_sched_canc,
                                                              g_sched_canc,
                                                              pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)),
                                                       g_nurse_scheduled,
                                                       g_yes,
                                                       g_no),
                                                g_no),
                                         g_no),
                                  g_no) flg_button_cancel,
                           decode(sp.id_epis_type,
                                  g_epis_type_nurse,
                                  decode(s.flg_status, g_sched_canc, g_yes, g_no),
                                  g_no) flg_button_detail,
                           decode(s.flg_status, g_sched_canc, g_yes, g_no) flg_cancel,
                           sg.flg_contact_type,
                           pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                           -- task columns:
                           -- drug prescriptions and requests
                           decode(pk_grid.get_prioritary_task(i_lang,
                                                              substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                                              substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                                              NULL,
                                                              g_flg_doctor),
                                  substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                  pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc),
                                  substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                  pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_req)) desc_drug_vaccine_req,
                           -- procedures, monitorizations, patient education
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          gt.intervention,
                                                                                                                          gt.monitorization,
                                                                                                                          NULL,
                                                                                                                          g_flg_doctor),
                                                                                              gt.teach_req,
                                                                                              NULL,
                                                                                              g_flg_doctor)) desc_nur_interv_monit_tea,
                           -- lab tests, exams
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat),
                                                                                              g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           -- dressings
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.nurse_activity) desc_dressings,
                           -- icnp
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.icnp_intervention) desc_icnp,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           decode(s.flg_status,
                                  g_sched_canc,
                                  3,
                                  decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                         g_sched_med_disch,
                                         2,
                                         g_sched_nurse_disch,
                                         2,
                                         1)) order_state,
                           sp.dt_target_tstz,
                           0 id_group,
                           pk_alert_constant.g_no flg_group_header,
                           NULL extend_icon,
                           pk_alert_constant.g_no prof_follow_add,
                           pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) prof_follow_remove
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON sp.id_schedule = s.id_schedule
                      JOIN sch_prof_outp ps
                        ON sp.id_schedule_outp = ps.id_schedule_outp
                      JOIN sch_group sg
                        ON sp.id_schedule = sg.id_schedule
                      JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                      JOIN patient pat
                        ON sg.id_patient = pat.id_patient
                      LEFT JOIN epis_info ei
                        ON sp.id_schedule = ei.id_schedule
                      LEFT JOIN episode e
                        ON ei.id_episode = e.id_episode
                      LEFT JOIN grid_task gt
                        ON ei.id_episode = gt.id_episode
                     WHERE sp.id_software = i_prof.software
                       AND sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                       AND s.id_instit_requested = i_prof.institution
                       AND (l_show_med_disch = g_yes OR
                           (l_show_med_disch = g_no AND
                           pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
                       AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                           decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                           l_show_nurse_disch = g_yes)
                       AND ((ps.id_professional = i_prof.id AND
                           (e.id_episode IS NULL OR e.flg_ehr = pk_ehr_access.g_flg_ehr_scheduled)) OR
                           (pk_utils.search_table_number(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                                               i_prof,
                                                                                               e.id_episode,
                                                                                               i_prof_cat,
                                                                                               l_handoff_type),
                                                          i_prof.id) > 0 AND
                           e.flg_ehr != pk_ehr_access.g_flg_ehr_scheduled) OR
                           pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) =
                           pk_alert_constant.g_yes)
                       AND se.flg_is_group = pk_alert_constant.g_no
                    --GROUP ELEMENTS
                    UNION ALL
                    SELECT s.id_schedule,
                           pat.id_patient,
                           e.id_episode id_episode,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           decode(e.id_episode,
                                  NULL,
                                  NULL,
                                  pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                          nvl(e.flg_appointment_type, g_null_appointment_type),
                                                          i_lang)) cont_type,
                           (SELECT lpad(to_char(et.rank), 6, '0') || pk_translation.get_translation(i_lang, et.code_icon)
                              FROM epis_type et
                             WHERE et.id_epis_type = sp.id_epis_type) img_sched,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           decode(s.flg_status,
                                  g_sched_canc,
                                  g_sched_canc,
                                  pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                           sp.flg_sched,
                           pk_patient.get_designated_provider(i_lang,
                                                              i_prof,
                                                              pat.id_patient,
                                                              decode(e.flg_ehr,
                                                                     pk_ehr_access.g_flg_ehr_scheduled,
                                                                     NULL,
                                                                     e.id_episode)) designated_provider,
                           CASE
                               WHEN e.id_episode IS NULL
                                    OR e.flg_ehr = pk_ehr_access.g_flg_ehr_scheduled THEN
                                pk_prof_utils.get_nickname(i_lang, ps.id_professional)
                           
                               ELSE
                                pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) ||
                                decode(ei.id_professional,
                                       NULL,
                                       NULL,
                                       ' / ' || pk_prof_utils.get_nickname(i_lang, ei.id_professional))
                           END desc_resp,
                           NULL desc_room, --get_room_desc(i_lang, decode(e.flg_ehr, pk_ehr_access.g_flg_ehr_scheduled, NULL, ei.id_room)) desc_room,
                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_scheduled,
                                  NULL,
                                  pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   e.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software)) dt_efectiv,
                           pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_efectiv_compl,
                           decode(sp.id_epis_type,
                                  g_epis_type_nurse,
                                  pk_sysdomain.get_ranked_img(g_schdl_nurse_state_domain,
                                                              decode(s.flg_status,
                                                                     g_sched_canc,
                                                                     g_sched_canc,
                                                                     pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                     e.flg_ehr)),
                                                              i_lang),
                                  decode(s.flg_status,
                                         g_sched_canc,
                                         pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS', s.flg_status, i_lang),
                                         pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                                     pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                                       i_prof,
                                                                                                       ei.id_dep_clin_serv,
                                                                                                       e.flg_ehr,
                                                                                                       pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                                       e.flg_ehr)),
                                                                     i_lang))) img_state,
                           g_sysdate_char dt_server,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => e.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           decode(sp.id_epis_type, g_epis_type_nurse, g_yes, g_no) flg_nurse,
                           decode(sp.id_epis_type,
                                  g_epis_type_nurse,
                                  decode(s.flg_status, g_sched_canc, g_no, g_yes),
                                  g_yes) flg_button_ok,
                           decode(l_can_cancel,
                                  g_yes,
                                  decode(l_cancel_sched,
                                         g_yes,
                                         decode(sp.id_epis_type,
                                                g_epis_type_nurse,
                                                decode(decode(s.flg_status,
                                                              g_sched_canc,
                                                              g_sched_canc,
                                                              pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)),
                                                       g_nurse_scheduled,
                                                       g_yes,
                                                       g_no),
                                                g_no),
                                         g_no),
                                  g_no) flg_button_cancel,
                           decode(sp.id_epis_type,
                                  g_epis_type_nurse,
                                  decode(s.flg_status, g_sched_canc, g_yes, g_no),
                                  g_no) flg_button_detail,
                           decode(s.flg_status, g_sched_canc, g_yes, g_no) flg_cancel,
                           sg.flg_contact_type,
                           pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                           -- task columns:
                           -- drug prescriptions and requests
                           decode(pk_grid.get_prioritary_task(i_lang,
                                                              substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                                              substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                                              NULL,
                                                              g_flg_doctor),
                                  substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                  pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc),
                                  substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                  pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_req)) desc_drug_vaccine_req,
                           -- procedures, monitorizations, patient education
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          gt.intervention,
                                                                                                                          gt.monitorization,
                                                                                                                          NULL,
                                                                                                                          g_flg_doctor),
                                                                                              gt.teach_req,
                                                                                              NULL,
                                                                                              g_flg_doctor)) desc_nur_interv_monit_tea,
                           -- lab tests, exams
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat),
                                                                                              g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           -- dressings
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.nurse_activity) desc_dressings,
                           -- icnp
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.icnp_intervention) desc_icnp,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           decode(s.flg_status,
                                  g_sched_canc,
                                  3,
                                  decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                         g_sched_med_disch,
                                         2,
                                         g_sched_nurse_disch,
                                         2,
                                         1)) order_state,
                           sp.dt_target_tstz,
                           s.id_group,
                           pk_alert_constant.g_no flg_group_header,
                           'ExtendIcon' extend_icon,
                           pk_alert_constant.g_no prof_follow_add,
                           pk_alert_constant.g_no prof_follow_remove
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON sp.id_schedule = s.id_schedule
                      JOIN sch_prof_outp ps
                        ON sp.id_schedule_outp = ps.id_schedule_outp
                      JOIN sch_group sg
                        ON sp.id_schedule = sg.id_schedule
                      JOIN patient pat
                        ON sg.id_patient = pat.id_patient
                      LEFT JOIN epis_info ei
                        ON sp.id_schedule = ei.id_schedule
                      LEFT JOIN episode e
                        ON ei.id_episode = e.id_episode
                      LEFT JOIN grid_task gt
                        ON ei.id_episode = gt.id_episode
                     WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                           d.column_value
                                            FROM TABLE(l_group_ids) d)
                    --GROUP HEADER
                    UNION ALL
                    SELECT NULL id_schedule, --s.id_schedule,
                           NULL id_patient, --pat.id_patient,
                           NULL id_episode, --decode(e.flg_ehr, pk_ehr_access.g_flg_ehr_scheduled, NULL, e.id_episode) id_episode,
                           l_sch_t640 name, --pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                           l_sch_t640 name_to_sort, --pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,
                           NULL pat_ndo, --pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           NULL pat_nd_icon, --pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           NULL gender, --pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang) gender,
                           NULL pat_age, --pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           NULL photo, --pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           decode(e.id_episode,
                                  NULL,
                                  NULL,
                                  pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                          nvl(e.flg_appointment_type, g_null_appointment_type),
                                                          i_lang)) cont_type,
                           (SELECT lpad(to_char(et.rank), 6, '0') || pk_translation.get_translation(i_lang, et.code_icon)
                              FROM epis_type et
                             WHERE et.id_epis_type = sp.id_epis_type) img_sched,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           'A' flg_state,
                           sp.flg_sched,
                           pk_patient.get_designated_provider(i_lang,
                                                              i_prof,
                                                              pat.id_patient,
                                                              decode(e.flg_ehr,
                                                                     pk_ehr_access.g_flg_ehr_scheduled,
                                                                     NULL,
                                                                     e.id_episode)) designated_provider,
                           CASE
                               WHEN e.id_episode IS NULL
                                    OR e.flg_ehr = pk_ehr_access.g_flg_ehr_scheduled THEN
                                pk_prof_utils.get_nickname(i_lang, ps.id_professional)
                           
                               ELSE
                                pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) ||
                                decode(ei.id_professional,
                                       NULL,
                                       NULL,
                                       ' / ' || pk_prof_utils.get_nickname(i_lang, ei.id_professional))
                           END desc_resp,
                           get_room_desc(i_lang, decode(e.flg_ehr, pk_ehr_access.g_flg_ehr_scheduled, NULL, ei.id_room)) desc_room,
                           decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                  g_sched_scheduled,
                                  NULL,
                                  pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   e.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software)) dt_efectiv,
                           pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_efectiv_compl,
                           get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                           g_sysdate_char dt_server,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => e.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           decode(sp.id_epis_type, g_epis_type_nurse, g_yes, g_no) flg_nurse,
                           g_no flg_button_ok,
                           decode(l_can_cancel,
                                  g_yes,
                                  decode(l_cancel_sched,
                                         g_yes,
                                         decode(sp.id_epis_type,
                                                g_epis_type_nurse,
                                                decode(decode(s.flg_status,
                                                              g_sched_canc,
                                                              g_sched_canc,
                                                              pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)),
                                                       g_nurse_scheduled,
                                                       g_yes,
                                                       g_no),
                                                g_no),
                                         g_no),
                                  g_no) flg_button_cancel,
                           g_no flg_button_detail,
                           decode(s.flg_status, g_sched_canc, g_yes, g_no) flg_cancel,
                           NULL flg_contact_type, --sg.flg_contact_type,
                           get_group_presence_icon(i_lang, i_prof, s.id_group, pk_alert_constant.g_no) icon_contact_type,
                           -- task columns:
                           -- drug prescriptions and requests
                           decode(pk_grid.get_prioritary_task(i_lang,
                                                              substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                                              substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                                              NULL,
                                                              g_flg_doctor),
                                  substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                  pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc),
                                  substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                  pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_req)) desc_drug_vaccine_req,
                           -- procedures, monitorizations, patient education
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          gt.intervention,
                                                                                                                          gt.monitorization,
                                                                                                                          NULL,
                                                                                                                          g_flg_doctor),
                                                                                              gt.teach_req,
                                                                                              NULL,
                                                                                              g_flg_doctor)) desc_nur_interv_monit_tea,
                           -- lab tests, exams
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             e.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat),
                                                                                              g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           -- dressings
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.nurse_activity) desc_dressings,
                           -- icnp
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.icnp_intervention) desc_icnp,
                           NULL flg_contact, --pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           decode(s.flg_status,
                                  g_sched_canc,
                                  3,
                                  decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                         g_sched_med_disch,
                                         2,
                                         g_sched_nurse_disch,
                                         2,
                                         1)) order_state,
                           sp.dt_target_tstz,
                           s.id_group,
                           pk_alert_constant.g_yes flg_group_header,
                           NULL extend_icon,
                           pk_alert_constant.g_no prof_follow_add,
                           pk_alert_constant.g_no prof_follow_remove
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON sp.id_schedule = s.id_schedule
                      JOIN sch_prof_outp ps
                        ON sp.id_schedule_outp = ps.id_schedule_outp
                      JOIN sch_group sg
                        ON sp.id_schedule = sg.id_schedule
                      JOIN patient pat
                        ON sg.id_patient = pat.id_patient
                      LEFT JOIN epis_info ei
                        ON sp.id_schedule = ei.id_schedule
                      LEFT JOIN episode e
                        ON ei.id_episode = e.id_episode
                      LEFT JOIN grid_task gt
                        ON ei.id_episode = gt.id_episode
                     WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                              d.column_value
                                               FROM TABLE(l_schedule_ids) d)
                    --
                    ) t
             ORDER BY t.order_state, t.dt_target_tstz;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_NURSE_APPOINTMENT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_nurse_appointment;

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
    ) RETURN BOOLEAN IS
    
        CURSOR c_prof IS
            SELECT *
              FROM (SELECT pk_prof_utils.get_nickname(i_lang, sr.id_professional)
                      FROM sch_resource sr
                     WHERE sr.id_schedule = i_schedule
                     ORDER BY sr.flg_leader DESC)
             WHERE rownum = 1;
    
        l_prof_name VARCHAR2(4000);
    
    BEGIN
    
        g_error := 'GET PROF NAME';
        OPEN c_prof;
        FETCH c_prof
            INTO l_prof_name;
        CLOSE c_prof;
    
        g_error := 'OPEN O_DETAIL';
        OPEN o_detail FOR
            SELECT substr(pk_adt.get_patient_name(i_lang,
                                                  i_prof,
                                                  sg.id_patient,
                                                  pk_hand_off_core.is_prof_responsible_current(i_lang,
                                                                                               i_prof,
                                                                                               ei.id_episode,
                                                                                               pk_prof_utils.get_category(8,
                                                                                                                          profissional(7020000674225,
                                                                                                                                       11111,
                                                                                                                                       1)),
                                                                                               NULL)),
                          1,
                          instr(pk_adt.get_patient_name(i_lang,
                                                        i_prof,
                                                        sg.id_patient,
                                                        pk_hand_off_core.is_prof_responsible_current(i_lang,
                                                                                                     i_prof,
                                                                                                     ei.id_episode,
                                                                                                     pk_prof_utils.get_category(8,
                                                                                                                                profissional(7020000674225,
                                                                                                                                             11111,
                                                                                                                                             1)),
                                                                                                     NULL)),
                                ' / ')) name,
                   pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                   pk_date_utils.date_char_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) dt_begin,
                   l_prof_name prof_name
              FROM schedule s
              JOIN sch_group sg
                ON s.id_schedule = sg.id_schedule
              LEFT JOIN epis_info ei
                ON s.id_schedule = ei.id_schedule
               AND sg.id_patient = ei.id_patient
             WHERE s.id_schedule = i_schedule
               AND sg.id_patient = i_patient;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCHEDULE_DETAIL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_detail);
            RETURN FALSE;
    END get_schedule_detail;

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
    ) RETURN BOOLEAN IS
        l_waiting_room_sys_external sys_config.value%TYPE := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM',
                                                                                     i_prof);
        l_cancel_sched              sys_config.value%TYPE;
        l_show_med_disch            sys_config.value%TYPE;
        l_show_nurse_disch          sys_config.value%TYPE;
        l_handoff_type              sys_config.value%TYPE;
        l_filter_by_dcs             sys_config.value%TYPE;
        l_dt_min                    schedule_outp.dt_target_tstz%TYPE;
        l_dt_max                    schedule_outp.dt_target_tstz%TYPE;
        l_episode_access            sys_config.value%TYPE;
        l_episode_registry          sys_config.value%TYPE;
        l_reasongrid                sys_config.value%TYPE;
        l_waiting_room_available    sys_config.value%TYPE;
        l_can_cancel                VARCHAR2(1 CHAR);
        l_id_category               category.id_category%TYPE;
        l_type_appoint_edition      VARCHAR2(1 CHAR);
        l_category_type             category.flg_type%TYPE;
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => g_sysdate_tstz, i_prof => i_prof);
    
        g_error := 'CALL get_date_bounds';
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_date, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        g_epis_type_nurse  := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => i_prof);
        l_cancel_sched     := pk_sysconfig.get_config(i_code_cf => 'FLG_CANCEL_SCHEDULE', i_prof => i_prof);
        l_show_med_disch   := nvl(pk_sysconfig.get_config(i_code_cf => 'SHOW_MEDICAL_DISCHARGED_GRID', i_prof => i_prof),
                                  g_yes);
        l_show_nurse_disch := nvl(pk_sysconfig.get_config(i_code_cf => 'SHOW_NURSE_DISCHARGED_GRID', i_prof => i_prof),
                                  g_no);
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        l_filter_by_dcs          := pk_sysconfig.get_config('AMB_GRID_NURSE_SHOW_BY_DCS', i_prof);
        l_episode_access         := pk_sysconfig.get_config('DOCTOR_NURSE_APPOINTMENT_ACCESS', i_prof);
        l_episode_registry       := pk_sysconfig.get_config('DOCTOR_NURSE_APPOINTMENT_REGISTRY', i_prof);
        l_reasongrid             := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID', i_prof);
        l_waiting_room_available := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
        l_can_cancel             := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                          i_prof        => i_prof,
                                                                          i_intern_name => 'CANCEL_EPISODE');
        l_id_category            := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        l_category_type := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        IF instr(pk_sysconfig.get_config('ALLOW_NURSE_GRID_TYPE_APPOINT_EDITION', i_prof.institution, i_prof.software),
                 '|' || l_id_category || '|') > 0
        THEN
            l_type_appoint_edition := pk_alert_constant.g_yes;
        ELSE
            l_type_appoint_edition := pk_alert_constant.g_no;
        END IF;
    
        IF l_cancel_sched = g_yes
        THEN
            IF l_episode_access = g_yes
               AND l_episode_registry = g_yes
            THEN
                l_cancel_sched := g_yes;
            ELSE
                l_cancel_sched := g_no;
            END IF;
        END IF;
    
        g_error := 'OPEN o_grid';
    
        OPEN o_grid FOR
            SELECT s.id_schedule,
                   pat.id_patient,
                   e.id_episode id_episode,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, e.id_episode, s.id_schedule) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, e.id_episode, s.id_schedule) name_to_sort,
                   (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang)
                      FROM dual) gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, e.id_episode, s.id_schedule) photo,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   (SELECT pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv)
                      FROM dual) cons_type,
                   pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                   sp.flg_sched,
                   pk_patient.get_designated_provider(i_lang,
                                                      i_prof,
                                                      pat.id_patient,
                                                      decode(e.flg_ehr,
                                                             pk_ehr_access.g_flg_ehr_scheduled,
                                                             NULL,
                                                             e.id_episode)) doctor_name,
                   CASE
                        WHEN e.id_episode IS NULL
                             OR e.flg_ehr = pk_ehr_access.g_flg_ehr_scheduled THEN
                         (SELECT pk_prof_utils.get_nickname(i_lang, ps.id_professional)
                            FROM dual)
                        ELSE
                         pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp)
                    END name_nurse,
                   (SELECT get_room_desc(i_lang, decode(e.flg_ehr, pk_ehr_access.g_flg_ehr_scheduled, NULL, ei.id_room))
                      FROM dual) desc_room,
                   decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                          g_sched_scheduled,
                          NULL,
                          pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software)) dt_efectiv,
                   pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof) dt_efectiv_compl,
                   CASE
                        WHEN i_prof.software = pk_alert_constant.g_soft_outpatient THEN
                         (nvl(pk_sysdomain.get_ranked_img(g_schdl_nurse_state_domain,
                                                          decode(s.flg_status,
                                                                 g_sched_canc,
                                                                 g_sched_canc,
                                                                 pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)),
                                                          i_lang),
                              pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain,
                                                          decode(s.flg_status,
                                                                 g_sched_canc,
                                                                 g_sched_canc,
                                                                 pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)),
                                                          i_lang)))
                        ELSE
                         (SELECT decode(sp.id_epis_type,
                                        g_epis_type_nurse,
                                        pk_sysdomain.get_img(i_lang,
                                                             g_schdl_nurse_state_domain,
                                                             decode(s.flg_status,
                                                                    g_sched_canc,
                                                                    g_sched_canc,
                                                                    pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr))),
                                        pk_sysdomain.get_img(i_lang,
                                                             g_schdl_outp_state_domain,
                                                             pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                               i_prof,
                                                                                               ei.id_dep_clin_serv,
                                                                                               e.flg_ehr,
                                                                                               pk_grid.get_schedule_real_state(sp.flg_state,
                                                                                                                               e.flg_ehr))))
                            FROM dual)
                    END img_state,
                   decode(s.flg_status,
                          g_sched_canc,
                          g_sched_canc,
                          pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state,
                   g_sysdate_char dt_server,
                   CASE
                        WHEN i_prof.software = pk_alert_constant.g_soft_outpatient THEN
                         pk_sysdomain.get_ranked_img(g_schdl_outp_sched_domain, sp.flg_sched, i_lang)
                        ELSE
                         (SELECT sd.img_name
                            FROM sys_domain sd
                           WHERE sd.code_domain = g_schdl_outp_sched_domain
                             AND sd.domain_owner = pk_sysdomain.k_default_schema
                             AND sd.val = (SELECT se.flg_schedule_outp_type
                                             FROM sch_event se
                                            WHERE se.id_sch_event = s.id_sch_event)
                             AND sd.id_language = i_lang)
                    END img_sched,
                   CASE
                        WHEN i_date IS NULL THEN
                         pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                 i_prof                      => i_prof,
                                                 i_waiting_room_available    => l_waiting_room_available,
                                                 i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                 i_id_episode                => ei.id_episode,
                                                 i_flg_state                 => sp.flg_state,
                                                 i_flg_ehr                   => e.flg_ehr,
                                                 i_id_dcs_requested          => s.id_dcs_requested)
                        ELSE
                         pk_alert_constant.g_no
                    END wr_call,
                   sg.flg_contact_type,
                   (SELECT pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type)
                      FROM dual) icon_contact_type,
                   pk_sysdomain.get_domain(g_domain_sch_presence, sg.flg_contact_type, i_lang) presence_desc,
                   decode(l_reasongrid,
                          g_no,
                          NULL,
                          pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                      i_prof,
                                                                                                      ei.id_episode,
                                                                                                      s.id_schedule),
                                                           4000)) visit_reason,
                   -- task columns:
                   -- drug prescriptions and requests
                   CASE
                        WHEN gt.id_episode IS NOT NULL THEN
                         pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                        ELSE
                         NULL
                    END desc_drug_presc,
                   -- procedures, monitorizations, patient education
                   pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                          i_prof,
                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                      i_prof,
                                                                                      gt.icnp_intervention,
                                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                                  i_prof,
                                                                                                                  gt.nurse_activity,
                                                                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                                                                              i_prof,
                                                                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                          i_prof,
                                                                                                                                                                          gt.intervention,
                                                                                                                                                                          gt.monitorization,
                                                                                                                                                                          NULL,
                                                                                                                                                                          l_category_type),
                                                                                                                                              gt.teach_req,
                                                                                                                                              NULL,
                                                                                                                                              l_category_type),
                                                                                                                  NULL,
                                                                                                                  l_category_type),
                                                                                      NULL,
                                                                                      l_category_type)) desc_interv_presc,
                   -- lab tests and exams          
                   pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                          i_prof,
                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                      i_prof,
                                                                                      pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                     i_prof,
                                                                                                                     e.id_visit,
                                                                                                                     g_task_analysis,
                                                                                                                     l_category_type),
                                                                                      pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                     i_prof,
                                                                                                                     e.id_visit,
                                                                                                                     g_task_exam,
                                                                                                                     l_category_type),
                                                                                      g_analysis_exam_icon_grid_rank,
                                                                                      l_category_type)) desc_ana_exam_req,
                   
                   pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                   pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) therapeutic_doctor,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) sch_event_desc,
                   l_type_appoint_edition flg_type_appoint_edition
              FROM schedule_outp sp
              JOIN schedule s
                ON sp.id_schedule = s.id_schedule
              LEFT JOIN sch_prof_outp ps
                ON sp.id_schedule_outp = ps.id_schedule_outp
              JOIN sch_group sg
                ON sp.id_schedule = sg.id_schedule
              JOIN patient pat
                ON sg.id_patient = pat.id_patient
              LEFT JOIN epis_info ei
                ON sp.id_schedule = ei.id_schedule
              LEFT JOIN episode e
                ON ei.id_episode = e.id_episode
               AND e.flg_ehr != g_flg_ehr
              LEFT JOIN grid_task gt
                ON ei.id_episode = gt.id_episode
              LEFT JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
             WHERE sp.id_software = i_prof.software
               AND sp.id_epis_type = g_epis_type_nurse
               AND sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND s.id_instit_requested = i_prof.institution
               AND (l_filter_by_dcs = g_no OR
                   (l_filter_by_dcs = g_yes AND
                   s.id_dcs_requested IN (SELECT pdcs.id_dep_clin_serv
                                              FROM prof_dep_clin_serv pdcs
                                             WHERE pdcs.id_professional = i_prof.id
                                               AND pdcs.flg_status = g_selected)))
               AND (l_show_med_disch = g_yes OR
                   (l_show_med_disch = g_no AND
                   pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
               AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                   decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                   l_show_nurse_disch = g_yes)
               AND s.flg_status <> g_sched_canc
             ORDER BY decode(s.flg_status,
                             g_sched_canc,
                             3,
                             decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                    g_sched_med_disch,
                                    2,
                                    g_sched_nurse_disch,
                                    2,
                                    1)),
                      sp.dt_target_tstz;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'NURSE_APPOINTMENT',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END nurse_appointment;

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
    ) RETURN BOOLEAN IS
    
        l_num_days_back    sys_config.value%TYPE;
        l_num_days_forward sys_config.value%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error            := 'GET NUM DAYS';
        l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', i_prof);
        l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
        IF l_num_days_forward <= 0
        THEN
            l_num_days_forward := 10;
        END IF;
    
        IF i_prof.software = pk_alert_constant.g_soft_outpatient
        THEN
        
            g_error := 'RETURN GET_DATES_FOR_AMB_GRID';
            RETURN get_dates_for_amb_grid(i_mode          => k_get_date_mode_nurs_app,
                                          i_lang          => i_lang,
                                          i_prof          => i_prof,
                                          i_prof_cat_type => NULL,
                                          o_date          => o_date,
                                          o_error         => o_error);
        ELSE
            g_error := 'OPEN O_DATE';
            OPEN o_date FOR
                SELECT pk_grid_amb.get_extense_day_desc(i_lang, t.day) date_desc, DAY date_tstz, today
                  FROM (SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz - LEVEL, 'DD') AS DAY,
                               pk_alert_constant.g_no today
                          FROM dual
                        CONNECT BY LEVEL <= l_num_days_back
                        UNION ALL
                        SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz, 'DD') AS DAY,
                               pk_alert_constant.g_yes today
                          FROM dual
                        UNION ALL
                        SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz + LEVEL, 'DD') AS DAY,
                               pk_alert_constant.g_no today
                          FROM dual
                        CONNECT BY LEVEL <= l_num_days_forward) t
                 ORDER BY t.day;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'NURSE_APPOINTMENT_DATES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
    END nurse_appointment_dates;

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
    ) RETURN BOOLEAN IS
        l_type VARCHAR2(10 CHAR);
    BEGIN
    
        IF i_type = 'D'
        THEN
            l_type := k_get_date_mode_my;
        ELSE
            l_type := k_get_date_mode_all;
        END IF;
    
        RETURN get_dates_for_amb_grid(i_mode          => l_type,
                                      i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_prof_cat_type => i_prof_cat_type,
                                      o_date          => o_date,
                                      o_error         => o_error);
        RETURN TRUE;
    
    END doctor_efectiv_pp_dates;

    FUNCTION doctor_efectiv_pp_dates_old
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_date          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_num_days_back    sys_config.value%TYPE;
        l_num_days_forward sys_config.value%TYPE;
        l_dt_current       VARCHAR2(200);
    
        l_handoff_type       sys_config.value%TYPE;
        l_sysdate_char_short VARCHAR2(8);
        l_show_nurse_disch   sys_config.value%TYPE := nvl(pk_sysconfig.get_config('SHOW_NURSE_DISCHARGED_GRID', i_prof),
                                                          g_no);
        l_show_med_disch     sys_config.value%TYPE := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID',
                                                                                  i_prof),
                                                          g_yes);
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        l_sysdate_char_short := pk_date_utils.to_char_insttimezone(i_prof, g_sysdate_tstz, 'YYYYMMDD');
        g_epis_type_nurse    := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        l_dt_current := pk_date_utils.date_send_tsz(i_lang,
                                                    pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                                    i_prof);
        ---------------------------------
        g_error            := 'GET NUM DAYS';
        l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', i_prof);
        l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', i_prof);
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
        IF l_num_days_forward <= 0
        THEN
            l_num_days_forward := 10;
        END IF;
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz - CAST(l_num_days_back AS NUMBER));
        l_dt_end   := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz + CAST(l_num_days_forward AS NUMBER));
    
        g_error := 'OPEN O_DATE';
        IF i_type = g_type_my_appointments
        THEN
            OPEN o_date FOR
                SELECT date_desc, date_tstz, decode(date_tstz, l_dt_current, 'Y', 'N') today
                  FROM ((SELECT get_extense_day_desc(i_lang, pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)) date_desc,
                                 pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof) date_tstz
                            FROM (SELECT /* + use_nl(sp s sg spo) index(ei(id_schedule)) index(e(id_episode)) index(sp(dt_target_tstz))*/
                                   pk_date_utils.trunc_insttimezone(i_prof, sp.dt_target_tstz) AS sp_date,
                                   sp.dt_target_tstz
                                    FROM schedule_outp sp
                                    JOIN schedule s
                                      ON s.id_schedule = sp.id_schedule
                                    JOIN sch_group sg
                                      ON sg.id_schedule = s.id_schedule
                                    LEFT JOIN epis_info ei
                                      ON ei.id_schedule = s.id_schedule
                                    LEFT JOIN episode e
                                      ON e.id_episode = ei.id_episode
                                     AND ei.id_patient = sg.id_patient
                                     AND e.flg_ehr != g_flg_ehr
                                    LEFT JOIN sch_prof_outp spo
                                      ON spo.id_schedule_outp = sp.id_schedule_outp
                                   WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                                     AND decode((SELECT pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)
                                                  FROM dual),
                                                g_sched_adm_disch,
                                                get_grid_task_count(i_lang,
                                                                    i_prof,
                                                                    ei.id_episode,
                                                                    e.id_visit,
                                                                    i_prof_cat_type,
                                                                    l_sysdate_char_short),
                                                1) = 1
                                     AND sp.id_software = i_prof.software
                                        -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico                     
                                     AND sp.id_epis_type != g_epis_type_nurse
                                     AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, g_sched_canc)
                                     AND (SELECT pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)
                                            FROM dual) != g_sched_adm_disch
                                     AND s.id_instit_requested = i_prof.institution
                                     AND s.id_sch_event != g_sch_event_therap_decision
                                     AND (pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                           i_prof,
                                                                                                           ei.id_episode,
                                                                                                           i_prof_cat_type,
                                                                                                           l_handoff_type,
                                                                                                           pk_alert_constant.g_yes),
                                                                       i_prof.id) != -1 OR
                                         (ei.id_professional IS NULL AND spo.id_professional = i_prof.id) OR
                                         (pk_prof_follow.get_follow_episode_by_me(i_prof, ei.id_episode, s.id_schedule) =
                                         pk_alert_constant.g_yes))
                                     AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                                         decode(sp.id_epis_type,
                                                 g_epis_type_nurse,
                                                 g_sched_nurse_disch,
                                                 g_sched_adm_disch) OR l_show_nurse_disch = g_yes)
                                     AND (l_show_med_disch = g_yes OR
                                         (l_show_med_disch = g_no AND
                                         pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
                                  UNION ALL
                                  SELECT pk_date_utils.trunc_insttimezone(i_prof, sp.dt_target_tstz) AS sp_date,
                                         sp.dt_target_tstz
                                    FROM schedule_outp sp
                                    JOIN schedule s
                                      ON s.id_schedule = sp.id_schedule
                                    JOIN sch_group sg
                                      ON sg.id_schedule = s.id_schedule
                                    LEFT JOIN epis_info ei
                                      ON ei.id_schedule = s.id_schedule
                                    LEFT JOIN episode e
                                      ON e.id_episode = ei.id_episode
                                     AND e.flg_ehr != g_flg_ehr
                                    LEFT JOIN sch_resource sr
                                      ON sr.id_schedule = s.id_schedule
                                   WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                                     AND decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                                g_sched_adm_disch,
                                                get_grid_task_count(i_lang,
                                                                    i_prof,
                                                                    ei.id_episode,
                                                                    e.id_visit,
                                                                    i_prof_cat_type,
                                                                    l_sysdate_char_short),
                                                1) = 1
                                     AND sp.id_software = i_prof.software
                                        -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico                     
                                     AND sp.id_epis_type != g_epis_type_nurse
                                     AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                                     AND s.id_instit_requested = i_prof.institution
                                     AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                                     AND s.id_sch_event = g_sch_event_therap_decision
                                     AND sr.id_professional = i_prof.id
                                     AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                                         decode(sp.id_epis_type,
                                                 g_epis_type_nurse,
                                                 g_sched_nurse_disch,
                                                 g_sched_adm_disch) OR l_show_nurse_disch = g_yes)
                                     AND (l_show_med_disch = g_yes OR
                                         (l_show_med_disch = g_no AND
                                         pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch)))
                           GROUP BY get_extense_day_desc(i_lang, pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)),
                                    pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)) --
                         UNION -- union with current date in case there's no appoitment for today
                        (SELECT get_extense_day_desc(i_lang,
                                                     pk_date_utils.date_send_tsz(i_lang,
                                                                                 pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                  g_sysdate_tstz),
                                                                                 i_prof)) date_desc,
                                pk_date_utils.date_send_tsz(i_lang,
                                                            pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                                            i_prof) date_tstz
                           FROM dual))
                 ORDER BY date_tstz;
        ELSIF i_type = g_type_all_appointments
        THEN
            OPEN o_date FOR
                SELECT date_desc, date_tstz, decode(date_tstz, l_dt_current, 'Y', 'N') today
                  FROM ((SELECT get_extense_day_desc(i_lang, pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)) date_desc,
                                 pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof) date_tstz
                            FROM (SELECT /* + use_nl(sp s sg) index(ei(id_schedule)) index(e(id_episode)) index(sp(dt_target_tstz))*/
                                   pk_date_utils.trunc_insttimezone(i_prof, sp.dt_target_tstz) AS sp_date,
                                   sp.dt_target_tstz
                                    FROM schedule_outp sp
                                    JOIN schedule s
                                      ON s.id_schedule = sp.id_schedule
                                    JOIN sch_group sg
                                      ON sg.id_schedule = s.id_schedule
                                    LEFT JOIN epis_info ei
                                      ON ei.id_schedule = s.id_schedule
                                    LEFT JOIN episode e
                                      ON e.id_episode = ei.id_episode
                                     AND e.flg_ehr != g_flg_ehr
                                    LEFT JOIN room ro
                                      ON ei.id_room = ro.id_room
                                   WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                                     AND sp.id_software = i_prof.software
                                        -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico
                                     AND sp.id_epis_type != g_epis_type_nurse
                                     AND (SELECT pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)
                                            FROM dual) != g_sched_adm_disch
                                     AND s.id_instit_requested = i_prof.institution
                                     AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                                     AND EXISTS (SELECT 0
                                            FROM prof_dep_clin_serv pdcs
                                           WHERE pdcs.id_professional = i_prof.id
                                             AND pdcs.flg_status = g_selected
                                             AND pdcs.id_dep_clin_serv = ei.id_dep_clin_serv)
                                     AND 1 = decode(ei.id_episode,
                                                    NULL,
                                                    1,
                                                    (SELECT COUNT(0)
                                                       FROM episode epis
                                                      WHERE epis.flg_status != g_epis_canc
                                                        AND epis.id_episode = ei.id_episode)))
                           GROUP BY get_extense_day_desc(i_lang, pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)),
                                    pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)) --
                         UNION -- union with current date in case there's no appoitment for today
                        (SELECT get_extense_day_desc(i_lang,
                                                     pk_date_utils.date_send_tsz(i_lang,
                                                                                 pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                  g_sysdate_tstz),
                                                                                 i_prof)) date_desc,
                                pk_date_utils.date_send_tsz(i_lang,
                                                            pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                                            i_prof) date_tstz
                           FROM dual))
                 ORDER BY date_tstz;
        ELSE
            pk_types.open_my_cursor(o_date);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DOCTOR_EFECTIV_PP_DATES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
    END doctor_efectiv_pp_dates_old;

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
    FUNCTION get_dates_for_amb_grid
    (
        i_mode          IN VARCHAR2,
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_date          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_num_days_back    NUMBER;
        l_num_days_forward NUMBER;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', i_prof);
        l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
        IF l_num_days_forward <= 0
        THEN
            l_num_days_forward := 10;
        END IF;
    
        g_error := 'OPEN O_DATE';
        OPEN o_date FOR
            SELECT pk_grid_amb.get_extense_day_desc(i_lang, t.day) date_desc, DAY date_tstz, today
              FROM (SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz - LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_back
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz, 'DD') AS DAY,
                           pk_alert_constant.g_yes today
                      FROM dual
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz + LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_forward) t
             ORDER BY t.day;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_dates_for_amb_grid',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
    END get_dates_for_amb_grid;

    FUNCTION doctor_efectiv_pp_mr_dates
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_date          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN get_dates_for_amb_grid(i_mode          => k_get_date_mode_all,
                                      i_lang          => i_lang,
                                      i_prof          => i_prof,
                                      i_prof_cat_type => i_prof_cat_type,
                                      o_date          => o_date,
                                      o_error         => o_error);
    
    END doctor_efectiv_pp_mr_dates;

    FUNCTION doctor_efectiv_pp_mr_dates_old
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_date          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_num_days_back    sys_config.value%TYPE;
        l_num_days_forward sys_config.value%TYPE;
        l_dt_current       VARCHAR2(200);
    
        l_handoff_type       sys_config.value%TYPE;
        l_sysdate_char_short VARCHAR2(8);
        l_show_nurse_disch   sys_config.value%TYPE := nvl(pk_sysconfig.get_config('SHOW_NURSE_DISCHARGED_GRID', i_prof),
                                                          g_no);
        l_show_med_disch     sys_config.value%TYPE := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID',
                                                                                  i_prof),
                                                          g_yes);
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        l_sysdate_char_short := pk_date_utils.to_char_insttimezone(i_prof, g_sysdate_tstz, 'YYYYMMDD');
        g_epis_type_nurse    := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        l_dt_current := pk_date_utils.date_send_tsz(i_lang,
                                                    pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                                    i_prof);
        ---------------------------------
        g_error            := 'GET NUM DAYS';
        l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', i_prof);
        l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', i_prof);
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
        IF l_num_days_forward <= 0
        THEN
            l_num_days_forward := 10;
        END IF;
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz - CAST(l_num_days_back AS NUMBER));
        l_dt_end   := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz + CAST(l_num_days_forward AS NUMBER));
    
        g_error := 'OPEN O_DATE';
        OPEN o_date FOR
            SELECT date_desc, date_tstz, decode(date_tstz, l_dt_current, 'Y', 'N') today
              FROM ((SELECT get_extense_day_desc(i_lang, pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)) date_desc,
                             pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof) date_tstz
                        FROM (SELECT /*+ use_nl(sp s sg) index(ei(id_schedule)) index(e(id_episode)) index(sp(dt_target_tstz))*/
                               pk_date_utils.trunc_insttimezone(i_prof, sp.dt_target_tstz) AS sp_date, sp.dt_target_tstz
                                FROM schedule_outp sp
                                JOIN schedule s
                                  ON s.id_schedule = sp.id_schedule
                                JOIN sch_group sg
                                  ON sg.id_schedule = s.id_schedule
                                LEFT JOIN epis_info ei
                                  ON ei.id_schedule = s.id_schedule
                                LEFT JOIN episode e
                                  ON e.id_episode = ei.id_episode
                                 AND ei.id_patient = sg.id_patient
                                 AND e.flg_ehr != g_flg_ehr
                              --LEFT JOIN sch_prof_outp spo
                              --  ON spo.id_schedule_outp = sp.id_schedule_outp
                               WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                                 AND decode((SELECT pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)
                                              FROM dual),
                                            g_sched_adm_disch,
                                            get_grid_task_count(i_lang,
                                                                i_prof,
                                                                ei.id_episode,
                                                                e.id_visit,
                                                                i_prof_cat_type,
                                                                l_sysdate_char_short),
                                            1) = 1
                                 AND sp.id_software = i_prof.software
                                    -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico                     
                                 AND sp.id_epis_type != g_epis_type_nurse
                                 AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, g_sched_canc)
                                 AND (SELECT pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)
                                        FROM dual) != g_sched_adm_disch
                                 AND s.id_instit_requested = i_prof.institution
                                 AND s.id_sch_event != g_sch_event_therap_decision
                                    --AND nvl(ei.id_professional, spo.id_professional) = i_prof.id
                                 AND EXISTS
                               (SELECT 0
                                        FROM prof_room pr
                                       WHERE pr.id_professional = i_prof.id
                                         AND ei.id_room = pr.id_room)
                                 AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                                     decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                                     l_show_nurse_disch = g_yes)
                                 AND (l_show_med_disch = g_yes OR
                                     (l_show_med_disch = g_no AND
                                     pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
                              UNION ALL
                              SELECT pk_date_utils.trunc_insttimezone(i_prof, sp.dt_target_tstz) AS sp_date,
                                     sp.dt_target_tstz
                                FROM schedule_outp sp
                                JOIN schedule s
                                  ON s.id_schedule = sp.id_schedule
                                JOIN sch_group sg
                                  ON sg.id_schedule = s.id_schedule
                                LEFT JOIN epis_info ei
                                  ON ei.id_schedule = s.id_schedule
                                LEFT JOIN episode e
                                  ON e.id_episode = ei.id_episode
                                 AND e.flg_ehr != g_flg_ehr
                              --LEFT JOIN sch_resource sr
                              --  ON sr.id_schedule = s.id_schedule
                                JOIN room ro
                                  ON ei.id_room = ro.id_room
                               WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                                 AND decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                                            g_sched_adm_disch,
                                            get_grid_task_count(i_lang,
                                                                i_prof,
                                                                ei.id_episode,
                                                                e.id_visit,
                                                                i_prof_cat_type,
                                                                l_sysdate_char_short),
                                            1) = 1
                                 AND sp.id_software = i_prof.software
                                    -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer de consultas de enfermagem na grelha do médico                     
                                 AND sp.id_epis_type != g_epis_type_nurse
                                 AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                                 AND s.id_instit_requested = i_prof.institution
                                 AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                                 AND s.id_sch_event = g_sch_event_therap_decision
                                    --AND sr.id_professional = i_prof.id
                                 AND EXISTS
                               (SELECT 0
                                        FROM prof_room pr
                                       WHERE pr.id_professional = i_prof.id
                                         AND ei.id_room = pr.id_room)
                                 AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                                     decode(sp.id_epis_type, g_epis_type_nurse, g_sched_nurse_disch, g_sched_adm_disch) OR
                                     l_show_nurse_disch = g_yes)
                                 AND (l_show_med_disch = g_yes OR
                                     (l_show_med_disch = g_no AND
                                     pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch)))
                       GROUP BY get_extense_day_desc(i_lang, pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)),
                                pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)) --
                     UNION -- union with current date in case there's no appoitment for today
                    (SELECT get_extense_day_desc(i_lang,
                                                 pk_date_utils.date_send_tsz(i_lang,
                                                                             pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                              g_sysdate_tstz),
                                                                             i_prof)) date_desc,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                                        i_prof) date_tstz
                       FROM dual))
             ORDER BY date_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'doctor_efectiv_pp_mr_dates',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
    END doctor_efectiv_pp_mr_dates_old;
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
    ) RETURN NUMBER IS
        l_count NUMBER(12);
    BEGIN
    
        SELECT COUNT(0)
          INTO l_count
          FROM grid_task gt
         WHERE gt.id_episode = i_id_episode
           AND (substr(pk_utils.str_token(pk_grid.visit_grid_task_str(i_lang,
                                                                      i_prof,
                                                                      i_id_visit,
                                                                      g_task_analysis,
                                                                      i_prof_cat_type),
                                          
                                          3,
                                          '|'),
                       1,
                       8) = i_sysdate_char_short OR
               
               substr(pk_utils.str_token(pk_grid.convert_grid_task_str(i_lang, i_prof, gt.clin_rec_req), 2, '|'), 1, 8) =
               i_sysdate_char_short OR
               substr(pk_utils.str_token(pk_grid.convert_grid_task_str(i_lang, i_prof, gt.clin_rec_transp), 2, '|'),
                       1,
                       8) = i_sysdate_char_short OR
               substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc), 3, '|'),
                       1,
                       8) = i_sysdate_char_short OR
               substr(pk_utils.str_token(pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_req), 2, '|'), 1, 8) =
               i_sysdate_char_short OR
               substr(pk_utils.str_token(pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_transp), 2, '|'), 1, 8) =
               i_sysdate_char_short OR
               
               substr(pk_utils.str_token(pk_grid.visit_grid_task_str(i_lang,
                                                                      i_prof,
                                                                      i_id_visit,
                                                                      g_task_exam,
                                                                      i_prof_cat_type),
                                          3,
                                          '|'),
                       1,
                       8) = i_sysdate_char_short OR
               
               substr(pk_utils.str_token(pk_grid.visit_grid_task_str(i_lang,
                                                                      i_prof,
                                                                      i_id_visit,
                                                                      g_task_harvest,
                                                                      i_prof_cat_type),
                                          3,
                                          '|'),
                       1,
                       8) = i_sysdate_char_short OR
               substr(pk_utils.str_token(pk_grid.convert_grid_task_str(i_lang, i_prof, gt.hemo_req), 2, '|'), 1, 8) =
               i_sysdate_char_short OR
               substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.intervention),
                                          3,
                                          '|'),
                       1,
                       8) = i_sysdate_char_short OR
               /*               substr(pk_utils.str_token(pk_supplies_external_api_db.get_surg_supplies_reg(i_lang,
               i_prof,
               i_id_episode,
               gt.material_req),
               3,
               '|'),
               1,
               8) = i_sysdate_char_short OR */ -- EMR-437
               substr(pk_utils.str_token(pk_supplies_external_api_db.get_surg_supplies_reg(i_lang,
                                                                                            i_prof,
                                                                                            i_id_episode,
                                                                                            gt.material_req),
                                          3,
                                          '|'),
                       1,
                       8) = i_sysdate_char_short OR
               substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.monitorization),
                                          3,
                                          '|'),
                       1,
                       8) = i_sysdate_char_short OR
               substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.movement), 3, '|'),
                       1,
                       8) = i_sysdate_char_short OR
               substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.nurse_activity),
                                          3,
                                          '|'),
                       1,
                       8) = i_sysdate_char_short OR
               substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.teach_req), 3, '|'),
                       1,
                       8) = i_sysdate_char_short);
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_grid_task_count;

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
    ) RETURN BOOLEAN IS
    
        l_num_days_back    sys_config.value%TYPE;
        l_num_days_forward sys_config.value%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error            := 'GET NUM DAYS';
        l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', i_prof);
        l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
        IF l_num_days_forward <= 0
        THEN
            l_num_days_forward := 10;
        END IF;
    
        g_error := 'OPEN O_DATE';
        OPEN o_date FOR
            SELECT pk_grid_amb.get_extense_day_desc(i_lang, t.day) date_desc, DAY date_tstz, today
              FROM (SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz - LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_back
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz, 'DD') AS DAY,
                           pk_alert_constant.g_yes today
                      FROM dual
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz + LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_forward) t
             ORDER BY t.day;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'nurse_efectiv_care_dates',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
    END nurse_efectiv_care_dates;

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
    ) RETURN BOOLEAN IS
    
        l_num_days_back    sys_config.value%TYPE;
        l_num_days_forward sys_config.value%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error            := 'GET NUM DAYS';
        l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', i_prof);
        l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
        IF l_num_days_forward <= 0
        THEN
            l_num_days_forward := 10;
        END IF;
    
        g_error := 'OPEN O_DATE';
        OPEN o_date FOR
            SELECT pk_grid_amb.get_extense_day_desc(i_lang, t.day) date_desc, DAY date_tstz, today
              FROM (SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz - LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_back
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz, 'DD') AS DAY,
                           pk_alert_constant.g_yes today
                      FROM dual
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz + LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_forward) t
             ORDER BY t.day;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DOCTOR_EFECTIV_CARE_DATES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
    END doctor_efectiv_care_dates;

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
    ) RETURN BOOLEAN IS
    
        l_num_days_back    sys_config.value%TYPE;
        l_num_days_forward sys_config.value%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error            := 'GET NUM DAYS';
        l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', i_prof);
        l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
        IF l_num_days_forward <= 0
        THEN
            l_num_days_forward := 10;
        END IF;
    
        g_error := 'OPEN O_DATE';
        OPEN o_date FOR
            SELECT pk_grid_amb.get_extense_day_desc(i_lang, t.day) date_desc, DAY date_tstz, today
              FROM (SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz - LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_back
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz, 'DD') AS DAY,
                           pk_alert_constant.g_yes today
                      FROM dual
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz + LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_forward) t
             ORDER BY t.day;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NURSE_APPOINTMENT_DATES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
    END get_nurse_appointment_dates;

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
    ) RETURN BOOLEAN IS
        l_handoff_type sys_config.value%TYPE;
        l_label_normal VARCHAR2(1 CHAR) := pk_hand_off.g_handoff_normal;
        l_label_doctor VARCHAR2(2 CHAR) := 'MD';
        l_config_show_resident CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
        l_show_resident_physician sys_config.value%TYPE;
        l_label_team              VARCHAR2(2 CHAR) := 'MT';
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        IF l_handoff_type = pk_hand_off.g_handoff_normal
        THEN
        
            o_label_resp := l_label_normal;
        ELSE
            l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => i_prof);
            IF l_show_resident_physician = pk_alert_constant.g_yes
            THEN
                o_label_resp := l_label_doctor;
            ELSE
                o_label_resp := l_label_team;
            END IF;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_GRID_CONFIG',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_grid_config;

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
    ) RETURN VARCHAR2 IS
    
        l_responsibles VARCHAR2(4000 CHAR) := NULL;
    
        l_show_only_epis_resp sys_config.value%TYPE := pk_sysconfig.get_config('GRID_ONLY_SHOW_EPISODE_RESPONSIBLE',
                                                                               i_prof);
    
        l_error t_error_out;
    
    BEGIN
    
        l_responsibles := pk_hand_off_core.get_responsibles_str(i_lang                => i_lang,
                                                                i_prof                => i_prof,
                                                                i_prof_cat            => i_prof_cat,
                                                                i_id_episode          => i_id_episode,
                                                                i_id_professional     => i_id_professional,
                                                                i_hand_off_type       => i_hand_off_type,
                                                                i_format              => i_format,
                                                                i_only_show_epis_resp => l_show_only_epis_resp);
    
        --  não existem responsáveis mas existe profissional do agendamento                                                                                                                               
        IF l_responsibles IS NULL
           AND i_id_professional IS NOT NULL
        THEN
            g_error := 'FORMAT RESPONSIBLE TEXT (PRODESSIONAL SCHEDULED)';
            pk_alertlog.log_debug(g_error);
        
            l_responsibles := pk_prof_utils.get_nickname(i_lang, i_id_professional);
        
        END IF;
    
        RETURN l_responsibles;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_RESPONSIBLES_STR',
                                              l_error);
            RETURN NULL;
        
    END get_responsibles_str;
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
    ) RETURN VARCHAR2 IS
        l_val                    table_varchar := table_varchar();
        l_icon                   sys_domain.img_name%TYPE;
        l_checkicon              NUMBER(12) := 0;
        l_waitingicon            NUMBER(12) := 0;
        l_patientnotarrivedicon  NUMBER(12) := 0;
        l_patientnotarrivedicon2 NUMBER(12) := 0;
        l_appointmentmissedicon  NUMBER(12) := 0;
    BEGIN
    
        g_error := 'get vals';
        SELECT decode(s.flg_status,
                      g_sched_canc,
                      g_sched_canc,
                      pk_grid.get_pre_nurse_appointment(i_lang,
                                                        i_prof,
                                                        ei.id_dep_clin_serv,
                                                        e.flg_ehr,
                                                        pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr))) flg_state
        
          BULK COLLECT
          INTO l_val
          FROM schedule s
          JOIN schedule_outp sp
            ON s.id_schedule = sp.id_schedule
          LEFT JOIN epis_info ei
            ON s.id_schedule = ei.id_schedule
          LEFT JOIN episode e
            ON e.id_episode = ei.id_episode
         WHERE s.id_group = i_id_group;
    
        g_error := 'loop vals';
        FOR i IN 1 .. l_val.count
        LOOP
        
            IF l_val(i) IN ('D', 'U', 'M')
            THEN
                --Finalizado, Todos os pacientes com alta (ou faltaram)
                l_checkicon := l_checkicon + 1;
            END IF;
            IF l_val(i) IN ('A', 'B', 'C')
            THEN
                --Pendente,  Nenhum paciente foi efectivado
                l_waitingicon := l_waitingicon + 1;
            END IF;
            IF l_val(i) IN ('B')
            THEN
                --Não realizada (apenas 2.6),  Todos os pacientes faltaram à consulta
                l_patientnotarrivedicon := l_patientnotarrivedicon + 1;
            END IF;
            IF l_val(i) IN ('C')
            THEN
                --Cancelado agendamento
                l_appointmentmissedicon := l_appointmentmissedicon + 1;
            END IF;
            IF l_val(i) IN ('B', 'C')
            THEN
                --Não realizada (apenas 2.6),  Todos os pacientes faltaram à consulta
                l_patientnotarrivedicon2 := l_patientnotarrivedicon2 + 1;
            END IF;
        END LOOP;
    
        --Em curso por defeito, Pelo menos um paciente efectivado ou em consulta
        l_icon := 'WorkflowIcon';
        --Finalizado, Todos os pacientes com alta (ou faltaram)
        IF l_checkicon = l_val.count
        THEN
            l_icon := 'CheckIcon';
        END IF;
        --Pendente,  Nenhum paciente foi efectivado
        IF l_waitingicon = l_val.count
        THEN
            l_icon := 'WaitingIcon';
        END IF;
        --Não realizada (apenas 2.6),  Todos os pacientes faltaram à consulta
        IF l_patientnotarrivedicon = l_val.count
        THEN
            l_icon := 'AppointmentMissedIcon';
        END IF;
        --Não realizada (apenas 2.6),  Todos os pacientes faltaram à consulta
        IF l_patientnotarrivedicon2 = l_val.count
        THEN
            l_icon := 'AppointmentMissedIcon';
        END IF;
        --Cancelado agendamento
        IF l_appointmentmissedicon = l_val.count
        THEN
            l_icon := 'AppointmentMissedIcon';
        END IF;
        --
    
        IF i_rank = pk_alert_constant.g_yes
        THEN
            RETURN '000010' || l_icon;
        ELSE
            RETURN l_icon;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_group_state_icon;
    /********************************************************************************************
    * get_pat_status_list
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
    FUNCTION get_group_status_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_group IN schedule.id_group%TYPE,
        i_context  IN VARCHAR2,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_status       pk_types.cursor_type;
        l_schedule_ids table_number;
        l_patient_ids  table_number;
        l_tab          t_tab_status_list := t_tab_status_list();
        l_rec          rec_status_list;
        l_first        NUMBER(2) := 0;
    BEGIN
        SELECT s.id_schedule, sg.id_patient
          BULK COLLECT
          INTO l_schedule_ids, l_patient_ids
          FROM schedule s
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
         WHERE s.id_group = i_id_group;
    
        FOR i IN 1 .. l_schedule_ids.count
        LOOP
            g_error := 'call get_status_list for each i_id_schedule';
            IF NOT get_status_list(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_id_schedule => l_schedule_ids(i),
                                   i_id_patient  => l_patient_ids(i),
                                   i_context     => i_context,
                                   o_status      => l_status,
                                   o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'loop results';
            LOOP
                FETCH l_status
                    INTO l_rec;
                EXIT WHEN l_status%NOTFOUND;
            
                IF l_first = 0
                THEN
                    -- the first initializes the collection
                    l_tab.extend;
                    l_tab(l_tab.count) := t_rec_status_list(l_rec.label, l_rec.data, l_rec.icon, l_rec.flg_action);
                ELSE
                    -- the others merge results
                    FOR j IN 1 .. l_tab.count
                    LOOP
                        IF l_rec.data = l_tab(j).data
                        THEN
                            IF l_rec.flg_action = pk_alert_constant.g_yes
                               AND l_tab(j).flg_action <> pk_alert_constant.g_yes
                            THEN
                                l_tab(j).flg_action := l_rec.flg_action;
                                IF l_rec.data = 'A'
                                THEN
                                    l_tab(j).label := l_rec.label;
                                END IF;
                            END IF;
                            EXIT;
                        END IF;
                    END LOOP;
                END IF;
            
            END LOOP;
            CLOSE l_status;
            l_first := 1;
        END LOOP;
    
        OPEN o_list FOR
            SELECT *
              FROM TABLE(l_tab);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_GROUP_STATUS_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_group_status_list;
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
    ) RETURN BOOLEAN IS
        l_flg_state   table_varchar;
        l_id_patient  table_number;
        l_id_schedule table_number;
        l_id_episode  table_number;
        l_episode     episode.id_episode%TYPE;
        l_permissions VARCHAR2(1char);
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT sg.id_patient,
               s.id_schedule,
               ei.id_episode,
               decode(s.flg_status,
                      g_sched_canc,
                      g_sched_canc,
                      pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state
          BULK COLLECT
          INTO l_id_patient, l_id_schedule, l_id_episode, l_flg_state
          FROM schedule s
          JOIN schedule_outp sp
            ON s.id_schedule = sp.id_schedule
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
          LEFT JOIN epis_info ei
            ON s.id_schedule = ei.id_schedule
          LEFT JOIN episode e
            ON e.id_episode = ei.id_episode
         WHERE s.id_group = i_id_group;
    
        FOR i IN 1 .. l_flg_state.count
        LOOP
            l_permissions := has_permissions(i_lang        => i_lang,
                                             i_prof        => i_prof,
                                             i_id_schedule => l_id_schedule(i),
                                             i_id_patient  => l_id_patient(i),
                                             i_context     => i_context,
                                             i_data        => i_data);
        
            --PRESENCA
            IF i_context = 'P'
               AND l_id_patient(i) IS NOT NULL
               AND l_id_schedule(i) IS NOT NULL
               AND l_permissions = pk_alert_constant.g_yes
            THEN
                g_error := 'PK_VISIT.CALL_CREATE_VISIT';
                IF NOT set_sched_presence(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_patient      => l_id_patient(i),
                                          i_episode      => l_id_episode(i),
                                          i_schedule     => l_id_schedule(i),
                                          i_flg_enc_type => i_data,
                                          o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
                --Efectivado
            ELSIF l_flg_state(i) = 'A'
                  AND i_data = 'E'
                  AND l_id_patient(i) IS NOT NULL
                  AND l_id_schedule(i) IS NOT NULL
                  AND l_permissions = pk_alert_constant.g_yes
            THEN
                g_error := 'PK_VISIT.CALL_CREATE_VISIT';
                IF NOT pk_visit.call_create_visit(i_lang                 => i_lang,
                                                  i_id_pat               => l_id_patient(i),
                                                  i_id_institution       => i_prof.institution,
                                                  i_id_sched             => l_id_schedule(i),
                                                  i_id_professional      => i_prof,
                                                  i_id_episode           => NULL,
                                                  i_external_cause       => NULL,
                                                  i_health_plan          => NULL,
                                                  i_epis_type            => NULL,
                                                  i_dep_clin_serv        => NULL,
                                                  i_origin               => NULL,
                                                  i_flg_ehr              => 'N',
                                                  i_dt_begin             => g_sysdate_tstz,
                                                  i_flg_appointment_type => NULL,
                                                  o_episode              => l_episode,
                                                  o_error                => o_error)
                THEN
                    RAISE g_exception;
                END IF;
                --Cancelar efectivação
            ELSIF l_flg_state(i) = 'E'
                  AND i_data = 'A'
                  AND l_id_episode(i) IS NOT NULL
                  AND l_permissions = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL TO PK_VISIT.CALL_CANCEL_EPISODE';
                IF NOT pk_visit.call_cancel_episode(i_lang          => i_lang,
                                                    i_id_episode    => l_id_episode(i),
                                                    i_prof          => i_prof,
                                                    i_cancel_reason => NULL,
                                                    i_cancel_type   => NULL,
                                                    o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
                --Cancelar agendamento
            ELSIF i_data = 'C'
                 --AND l_flg_state(i) = 'A'
                  AND l_id_schedule(i) IS NOT NULL
                  AND l_permissions = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL TO PK_VISIT.CALL_CANCEL_EPISODE';
                IF NOT pk_schedule.cancel_schedule(i_lang             => i_lang,
                                                   i_prof             => i_prof,
                                                   i_id_schedule      => l_id_schedule(i),
                                                   i_id_cancel_reason => i_id_cancel_reason,
                                                   i_cancel_notes     => i_cancel_notes,
                                                   o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
                --SET_PATIENT_NO_SHOW
            ELSIF i_data = 'B'
                 --AND l_flg_state(i) = 'A'
                  AND l_id_schedule(i) IS NOT NULL
                  AND l_id_patient(i) IS NOT NULL
                  AND l_permissions = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL TO pk_schedule_api_ui.set_patient_no_show';
                IF NOT pk_schedule_api_ui.set_patient_no_show(i_lang             => i_lang,
                                                              i_prof             => i_prof,
                                                              i_id_schedule      => l_id_schedule(i),
                                                              i_id_patient       => l_id_patient(i),
                                                              i_id_cancel_reason => i_id_cancel_reason,
                                                              i_notes            => i_cancel_notes,
                                                              o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                --state change
            ELSIF l_id_patient(i) IS NOT NULL
                  AND l_id_schedule(i) IS NOT NULL
                  AND l_id_episode(i) IS NOT NULL
                  AND l_permissions = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL TO pk_grid.set_state_change_nc';
                IF NOT pk_grid.set_state_change_nc(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_epis        => l_id_episode(i),
                                                   i_pat         => l_id_patient(i),
                                                   i_id_schedule => l_id_schedule(i),
                                                   i_from_state  => l_flg_state(i),
                                                   i_to_state    => i_data,
                                                   o_error       => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        END LOOP;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_GROUP_STATUS_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_group_status_list;

    /********************************************************************************************
    * set_group_note
    *
    * @param    i_lang              Língua registada como preferência do profissional
    * @param    i_prof              profissional identifier
    * @param    i_note              data value from popup get_group_status_list
    * @param    i_id_group          group identifier schedule
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
    FUNCTION set_group_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_group      IN schedule.id_group%TYPE,
        i_note          IN group_note.notes%TYPE,
        i_flg_create    IN VARCHAR2,
        o_id_group_note OUT group_note.id_group_note%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows_out   table_varchar := table_varchar();
        v_group_note group_note%ROWTYPE;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_flg_create = pk_alert_constant.get_no
        THEN
            -- update
            BEGIN
                SELECT gn.id_group_note, gn.id_prof_last_update, gn.dt_last_update, gn.notes
                  INTO v_group_note.id_group_note,
                       v_group_note.id_prof_last_update,
                       v_group_note.dt_last_update,
                       v_group_note.notes
                  FROM group_note gn
                 WHERE gn.id_group = i_id_group;
            EXCEPTION
                WHEN no_data_found THEN
                    v_group_note := NULL;
            END;
        
            g_error := 'call send_group_note_to_hist';
            IF NOT send_group_note_to_hist(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_group_note => v_group_note,
                                           o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'call ts_group_note.upd';
            ts_group_note.upd(id_group_note_in       => v_group_note.id_group_note,
                              id_prof_last_update_in => i_prof.id,
                              dt_last_update_in      => g_sysdate_tstz,
                              notes_in               => i_note,
                              notes_nin              => FALSE,
                              rows_out               => l_rows_out);
        
            g_error := 't_data_gov_mnt.process_update ts_group_note';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'GROUP_NOTE',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'call set_pat_group_note_nc';
            IF NOT set_pat_group_note_nc(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_id_group      => i_id_group,
                                         i_id_group_note => v_group_note.id_group_note,
                                         i_flg_action    => 'U',
                                         i_note          => i_note,
                                         o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE
            -- insert
            g_error                    := 'call ts_group_note.ins';
            v_group_note.id_group_note := ts_group_note.next_key;
            ts_group_note.ins(id_group_note_in       => v_group_note.id_group_note,
                              id_group_in            => i_id_group,
                              id_prof_last_update_in => i_prof.id,
                              dt_last_update_in      => g_sysdate_tstz,
                              notes_in               => i_note,
                              rows_out               => l_rows_out);
        
            g_error := 't_data_gov_mnt.process_insert ts_group_note';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'GROUP_NOTE',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'call set_pat_group_note_nc';
            IF NOT set_pat_group_note_nc(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_id_group      => i_id_group,
                                         i_id_group_note => v_group_note.id_group_note,
                                         i_flg_action    => 'I',
                                         i_note          => i_note,
                                         o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        o_id_group_note := v_group_note.id_group_note;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_GROUP_NOTE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_group_note;
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
        i_note          IN group_note.notes%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count      NUMBER(12) := 0;
        l_flg_state  table_varchar := table_varchar();
        l_id_patient table_number := table_number();
        l_id_episode table_number := table_number();
        l_rows_out   table_varchar := table_varchar();
        l_cons_type  group_note.notes%TYPE;
    BEGIN
        g_error := 'get l_id_patient, l_id_episode, l_flg_state';
        SELECT sg.id_patient,
               ei.id_episode,
               pk_grid.get_pre_nurse_appointment(i_lang,
                                                 i_prof,
                                                 ei.id_dep_clin_serv,
                                                 e.flg_ehr,
                                                 pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state
          BULK COLLECT
          INTO l_id_patient, l_id_episode, l_flg_state
          FROM schedule s
          JOIN schedule_outp sp
            ON s.id_schedule = sp.id_schedule
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
          LEFT JOIN epis_info ei
            ON s.id_schedule = ei.id_schedule
          LEFT JOIN episode e
            ON e.id_episode = ei.id_episode
         WHERE s.id_group = i_id_group;
    
        IF i_flg_action = 'U'
        THEN
            -- update ts_pat_group_note not used because where_in clause not available
            g_error := 'UPDATE pat_group_note pgn';
            UPDATE pat_group_note pgn
               SET pgn.flg_active = pk_alert_constant.g_no
             WHERE pgn.id_group_note = i_id_group_note;
        
            g_error := 't_data_gov_mnt.process_update ts_pat_group_note';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_GROUP_NOTE',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        END IF;
    
        FOR i IN 1 .. l_flg_state.count
        LOOP
            IF l_flg_state(i) NOT IN ('I', 'A', 'B')
               AND l_id_patient(i) IS NOT NULL
               AND l_id_episode(i) IS NOT NULL
            THEN
                IF i_flg_action = 'U'
                THEN
                    g_error := 'COUNT INTO l_count';
                    SELECT COUNT(1)
                      INTO l_count
                      FROM pat_group_note pgn
                     WHERE pgn.id_group_note = i_id_group_note
                       AND pgn.id_patient = l_id_patient(i)
                       AND pgn.id_episode = l_id_episode(i);
                END IF;
            
                IF l_count > 0
                THEN
                    --update
                    g_error := 'call ts_pat_group_note.ins';
                    ts_pat_group_note.upd(id_group_note_in => i_id_group_note,
                                          id_patient_in    => l_id_patient(i),
                                          id_episode_in    => l_id_episode(i),
                                          flg_active_in    => pk_alert_constant.g_yes,
                                          rows_out         => l_rows_out);
                
                    g_error := 't_data_gov_mnt.process_update ts_pat_group_note';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_GROUP_NOTE',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                ELSE
                    --insert
                    g_error := 'call ts_pat_group_note.ins';
                    ts_pat_group_note.ins(id_group_note_in => i_id_group_note,
                                          id_patient_in    => l_id_patient(i),
                                          id_episode_in    => l_id_episode(i),
                                          flg_active_in    => pk_alert_constant.g_yes,
                                          rows_out         => l_rows_out);
                
                    g_error := 't_data_gov_mnt.process_insert ts_pat_group_note';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'PAT_GROUP_NOTE',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                END IF;
            
                IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                              i_id_episode          => l_id_episode(i),
                                              i_pat                 => l_id_patient(i),
                                              i_prof                => i_prof,
                                              i_prof_cat_type       => NULL,
                                              i_dt_last_interaction => g_sysdate_tstz,
                                              i_dt_first_obs        => g_sysdate_tstz,
                                              o_error               => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        END LOOP;
    
        --Create a group notes note
        IF i_prof.software IN (pk_alert_constant.g_soft_outpatient, pk_alert_constant.g_soft_primary_care)
        THEN
            BEGIN
                SELECT pk_message.get_message(i_lang, 'SCH_T640') || ': ' ||
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) || chr(13)
                  INTO l_cons_type
                  FROM epis_info ei
                  JOIN dep_clin_serv dcs
                    ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                  JOIN clinical_service cs
                    ON cs.id_clinical_service = dcs.id_clinical_service
                 WHERE ei.id_episode = l_id_episode(1);
            EXCEPTION
                WHEN no_data_found THEN
                    l_cons_type := NULL;
            END;
        
            IF NOT pk_prog_notes_out.set_pn_group_notes(i_lang    => i_lang,
                                                        i_prof    => i_prof,
                                                        i_episode => l_id_episode,
                                                        i_notes   => l_cons_type || i_note,
                                                        o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'set_pat_group_note_nc',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_pat_group_note_nc;
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
    ) RETURN BOOLEAN IS
        l_func_name          VARCHAR2(60 CHAR) := 'SEND_GROUP_NOTE_TO_HIST';
        l_rows_out           table_varchar;
        l_id_group_note_hist group_note_hist.id_group_note_hist%TYPE;
    
        CURSOR c_pgn IS
            SELECT pgn.id_patient, pgn.id_episode
              FROM pat_group_note pgn
             WHERE pgn.id_group_note = i_group_note.id_group_note;
    
    BEGIN
    
        g_error              := 'call ts_group_note_hist.ins';
        l_id_group_note_hist := ts_group_note_hist.next_key;
        ts_group_note_hist.ins(id_group_note_hist_in  => l_id_group_note_hist,
                               id_group_note_in       => i_group_note.id_group_note,
                               id_prof_last_update_in => i_group_note.id_prof_last_update,
                               dt_last_update_in      => i_group_note.dt_last_update,
                               notes_in               => i_group_note.notes,
                               rows_out               => l_rows_out);
    
        g_error := 'call  t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'GROUP_NOTE_HIST',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        g_error := 'loop cursor';
        FOR i IN c_pgn
        LOOP
            g_error := 'call ts_pat_group_note.ins';
            ts_pat_group_note_hist.ins(id_group_note_hist_in => l_id_group_note_hist,
                                       id_patient_in         => i.id_patient,
                                       id_episode_in         => i.id_episode,
                                       rows_out              => l_rows_out);
        
            g_error := 't_data_gov_mnt.process_insert ts_pat_group_note';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'PAT_GROUP_NOTE_HIST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END send_group_note_to_hist;
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
    ) RETURN BOOLEAN IS
        l_add_note      sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'GROUP_NOTE_T001');
        l_count         NUMBER(12) := 0;
        l_id_group_note group_note.id_group_note%TYPE;
        l_notes         group_note.notes%TYPE;
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT pk_grid.get_pre_nurse_appointment(i_lang,
                                                         i_prof,
                                                         ei.id_dep_clin_serv,
                                                         e.flg_ehr,
                                                         pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) flg_state
                  FROM schedule s
                  JOIN schedule_outp sp
                    ON s.id_schedule = sp.id_schedule
                  JOIN sch_group sg
                    ON sg.id_schedule = s.id_schedule
                  LEFT JOIN epis_info ei
                    ON s.id_schedule = ei.id_schedule
                  LEFT JOIN episode e
                    ON e.id_episode = ei.id_episode
                 WHERE s.id_group = i_id_group)
         WHERE flg_state NOT IN ('I', 'A', 'B');
    
        BEGIN
            SELECT gn.id_group_note, gn.notes
              INTO l_id_group_note, l_notes
              FROM group_note gn
             WHERE gn.id_group = i_id_group;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_group_note := NULL;
                l_notes         := NULL;
        END;
    
        OPEN o_list FOR
            SELECT l_add_note descr,
                   CASE
                        WHEN l_count > 0 THEN
                         pk_alert_constant.g_active
                        ELSE
                         pk_alert_constant.g_inactive
                    END flg_active,
                   l_notes group_note,
                   decode(l_id_group_note, NULL, pk_alert_constant.get_yes, pk_alert_constant.get_no) flg_create
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_GROUP_ACTIONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_group_actions;

    /********************************************************************************************
    * get_schedule_ids
    *
    * @param    I_group_ids           TABLE_NUMBER group_ids 
    *
    * @return  TABLE_NUMBER schedule_ids
    * @author  Paulo Teixeira
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION get_schedule_ids(i_group_ids IN table_number) RETURN table_number IS
        l_schedule_ids table_number := table_number();
    BEGIN
    
        IF i_group_ids.count > 0
        THEN
            SELECT id_schedule
              BULK COLLECT
              INTO l_schedule_ids
              FROM (SELECT s.id_schedule, row_number() over(PARTITION BY id_group ORDER BY s.dt_begin_tstz) linenumber
                      FROM schedule s
                     WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                           d.column_value
                                            FROM TABLE(i_group_ids) d))
             WHERE linenumber = 1;
        END IF;
    
        RETURN l_schedule_ids;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number();
    END get_schedule_ids;

    FUNCTION get_schedule_by_group_ids
    (
        i_prof IN profissional,
        i_dt01 IN schedule_outp.dt_target_tstz%TYPE,
        i_dt09 IN schedule_outp.dt_target_tstz%TYPE
    ) RETURN table_number IS
        l_group_ids    table_number := table_number();
        l_schedule_ids table_number := table_number();
    BEGIN
    
        l_group_ids := get_group_ids(i_prof, i_dt01, i_dt09);
    
        IF l_group_ids.count > 0
        THEN
            l_schedule_ids := get_schedule_ids(l_group_ids);
        END IF;
    
        RETURN l_schedule_ids;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number();
    END get_schedule_by_group_ids;

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
    ) RETURN VARCHAR2 IS
        l_status pk_types.cursor_type;
        l_rec    rec_status_list;
        t_error  t_error_out;
        l_return VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
    
        g_error := 'call get_status_list for each i_id_schedule';
        IF NOT get_status_list(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_id_schedule => i_id_schedule,
                               i_id_patient  => i_id_patient,
                               i_context     => i_context,
                               o_status      => l_status,
                               o_error       => t_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'loop results';
        LOOP
            FETCH l_status
                INTO l_rec;
            EXIT WHEN l_status%NOTFOUND;
        
            IF l_rec.data = i_data
            THEN
                l_return := l_rec.flg_action;
                EXIT;
            END IF;
        
        END LOOP;
        CLOSE l_status;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END has_permissions;
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
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_context = 'D'
        THEN
            g_error := 'call pk_grid.get_pat_status_list for each i_id_schedule';
            IF NOT pk_grid.get_pat_status_list(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_flg_status  => NULL,
                                               i_id_schedule => i_id_schedule,
                                               i_id_patient  => i_id_patient,
                                               o_status      => o_status,
                                               o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_context = 'N'
        THEN
            g_error := 'call pk_grid.get_pat_nurse_status_list for each i_id_schedule';
            IF NOT pk_grid.get_pat_nurse_status_list(i_lang        => i_lang,
                                                     i_prof        => i_prof,
                                                     i_flg_status  => NULL,
                                                     i_id_schedule => i_id_schedule,
                                                     o_status      => o_status,
                                                     o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_context = 'A'
        THEN
            g_error := 'call pk_grid.get_reg_sched_state_list for each i_id_schedule';
            IF NOT pk_grid.get_reg_sched_state_list(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_flg_status  => NULL,
                                                    i_id_schedule => i_id_schedule,
                                                    o_status      => o_status,
                                                    o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSIF i_context = 'P'
        THEN
            g_error := 'call pk_grid.get_reg_sched_state_list for each i_id_schedule';
            IF NOT get_sched_presence_domain(i_lang     => i_lang,
                                             i_patient  => i_id_patient,
                                             i_schedule => i_id_schedule,
                                             o_data     => o_status,
                                             o_error    => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_status);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_STATUS_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END get_status_list;
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN o_data';
        OPEN o_data FOR
            SELECT t.id_group_note,
                   t.id_group_note_hist,
                   t.flg_status,
                   t.notes,
                   t.id_professional,
                   t.prof_desc,
                   t.dt_record_serial,
                   t.dt_record_desc
              FROM (SELECT gn.id_group_note,
                           NULL id_group_note_hist,
                           pk_alert_constant.g_active flg_status,
                           gn.notes,
                           gn.id_prof_last_update id_professional,
                           pk_tools.get_prof_description(i_lang,
                                                         i_prof,
                                                         gn.id_prof_last_update,
                                                         gn.dt_last_update,
                                                         i_episode) prof_desc,
                           pk_date_utils.date_send_tsz(i_lang, gn.dt_last_update, i_prof) dt_record_serial,
                           pk_date_utils.date_char_tsz(i_lang, gn.dt_last_update, i_prof.institution, i_prof.software) dt_record_desc
                      FROM pat_group_note pgn
                      JOIN group_note gn
                        ON gn.id_group_note = pgn.id_group_note
                     WHERE pgn.id_episode = i_episode
                       AND pgn.flg_active = pk_alert_constant.g_yes
                    UNION ALL
                    SELECT gnh.id_group_note,
                           gnh.id_group_note_hist,
                           pk_alert_constant.g_outdated flg_status,
                           gnh.notes,
                           gnh.id_prof_last_update id_professional,
                           pk_tools.get_prof_description(i_lang,
                                                         i_prof,
                                                         gnh.id_prof_last_update,
                                                         gnh.dt_last_update,
                                                         i_episode) prof_desc,
                           pk_date_utils.date_send_tsz(i_lang, gnh.dt_last_update, i_prof) dt_record_serial,
                           pk_date_utils.date_char_tsz(i_lang, gnh.dt_last_update, i_prof.institution, i_prof.software) dt_record_desc
                      FROM pat_group_note_hist pgnh
                      JOIN group_note_hist gnh
                        ON gnh.id_group_note_hist = pgnh.id_group_note_hist
                     WHERE pgnh.id_episode = i_episode) t
             ORDER BY dt_record_serial DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_group_notes_det',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_group_notes_det;

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
    FUNCTION get_prof_team_det(i_prof IN profissional) RETURN table_number IS
        l_professional_ids table_number := table_number();
    BEGIN
    
        SELECT ptd.id_professional
          BULK COLLECT
          INTO l_professional_ids
          FROM prof_team_det ptd
          JOIN prof_team_det ptda
         USING (id_prof_team)
          JOIN prof_team pt
         USING (id_prof_team)
         WHERE ptd.flg_available = g_yes
           AND ptd.flg_status = pk_alert_constant.g_active
           AND ptda.flg_available = g_yes
           AND ptda.flg_status = pk_alert_constant.g_active
           AND ptda.id_professional = i_prof.id
           AND pt.flg_available = g_yes
           AND pt.flg_status = pk_alert_constant.g_active
           AND pt.id_institution = i_prof.institution
           AND pt.flg_type = g_team_type_care;
    
        RETURN l_professional_ids;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number();
    END get_prof_team_det;

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
    ) RETURN NUMBER IS
    
    BEGIN
    
        IF substr(pk_utils.str_token(pk_grid.visit_grid_task_str(i_lang,
                                                                 i_prof,
                                                                 i_id_visit,
                                                                 pk_grid.g_task_analysis,
                                                                 i_prof_cat_type),
                                     3,
                                     '|'),
                  1,
                  8) = i_sysdate_char_short
           OR substr(pk_utils.str_token(pk_grid.convert_grid_task_str(i_lang, i_prof, i_clin_rec_req), 2, '|'), 1, 8) =
           i_sysdate_char_short
           OR substr(pk_utils.str_token(pk_grid.convert_grid_task_str(i_lang, i_prof, i_clin_rec_transp), 2, '|'), 1, 8) =
           i_sysdate_char_short
           OR substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, i_drug_presc), 3, '|'),
                     1,
                     8) = i_sysdate_char_short
           OR substr(pk_utils.str_token(pk_grid.convert_grid_task_str(i_lang, i_prof, i_drug_req), 2, '|'), 1, 8) =
           i_sysdate_char_short
           OR substr(pk_utils.str_token(pk_grid.convert_grid_task_str(i_lang, i_prof, i_drug_transp), 2, '|'), 1, 8) =
           i_sysdate_char_short
           OR substr(pk_utils.str_token(pk_grid.visit_grid_task_str(i_lang,
                                                                    i_prof,
                                                                    i_id_visit,
                                                                    pk_grid.g_task_exam,
                                                                    i_prof_cat_type),
                                        3,
                                        '|'),
                     1,
                     8) = i_sysdate_char_short
           OR substr(pk_utils.str_token(pk_grid.visit_grid_task_str(i_lang,
                                                                    i_prof,
                                                                    i_id_visit,
                                                                    pk_grid.g_task_harvest,
                                                                    i_prof_cat_type),
                                        3,
                                        '|'),
                     1,
                     8) = i_sysdate_char_short
           OR substr(pk_utils.str_token(pk_grid.convert_grid_task_str(i_lang, i_prof, i_hemo_req), 2, '|'), 1, 8) =
           i_sysdate_char_short
           OR substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, i_intervention), 3, '|'),
                     1,
                     8) = i_sysdate_char_short
           OR substr(pk_utils.str_token(pk_grid.convert_grid_task_str(i_lang, i_prof, i_material_req), 2, '|'), 1, 8) =
           i_sysdate_char_short
           OR
           substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, i_monitorization), 3, '|'),
                  1,
                  8) = i_sysdate_char_short
           OR
           substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, i_movement), 3, '|'), 1, 8) =
           i_sysdate_char_short
           OR
           substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, i_nurse_activity), 3, '|'),
                  1,
                  8) = i_sysdate_char_short
           OR
           substr(pk_utils.str_token(pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, i_teach_req), 3, '|'), 1, 8) =
           i_sysdate_char_short
        THEN
            RETURN 1;
        ELSE
            RETURN 0;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END get_grid_task_if;
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
    ) RETURN VARCHAR2 IS
        l_val         table_varchar := table_varchar();
        l_valor       sys_domain.val%TYPE;
        l_presencenot NUMBER(12) := 0;
        l_presence    NUMBER(12) := 0;
    BEGIN
    
        g_error := 'get vals';
        SELECT sg.flg_contact_type
          BULK COLLECT
          INTO l_val
          FROM schedule s
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
         WHERE s.id_group = i_id_group;
    
        g_error := 'loop vals';
        FOR i IN 1 .. l_val.count
        LOOP
        
            IF l_val(i) IN ('I')
            THEN
                --not present
                l_presencenot := l_presencenot + 1;
            END IF;
            IF l_val(i) IN ('D')
            THEN
                --present
                l_presence := l_presence + 1;
            END IF;
        END LOOP;
    
        --not present
        IF l_presencenot = l_val.count
        THEN
            l_valor := 'I';
        END IF;
        --present
        IF l_presence = l_val.count
        THEN
            l_valor := 'D';
        END IF;
    
        RETURN l_valor;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_group_presence_val;

    FUNCTION get_group_presence_icon
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_group IN schedule.id_group%TYPE,
        i_rank     IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2 IS
        l_val         table_varchar := table_varchar();
        l_icon        sys_domain.img_name%TYPE;
        l_presencenot NUMBER(12) := 0;
        l_presence    NUMBER(12) := 0;
    BEGIN
    
        g_error := 'get vals';
        SELECT sg.flg_contact_type
          BULK COLLECT
          INTO l_val
          FROM schedule s
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
         WHERE s.id_group = i_id_group;
    
        g_error := 'loop vals';
        FOR i IN 1 .. l_val.count
        LOOP
        
            IF l_val(i) IN ('I')
            THEN
                --not present
                l_presencenot := l_presencenot + 1;
            END IF;
            IF l_val(i) IN ('D')
            THEN
                --present
                l_presence := l_presence + 1;
            END IF;
        END LOOP;
    
        --not present
        IF l_presencenot = l_val.count
        THEN
            IF i_rank = pk_alert_constant.g_yes
            THEN
                l_icon := pk_sysdomain.get_ranked_img(i_lang, g_domain_sch_presence, 'I');
            ELSE
                l_icon := pk_sysdomain.get_img(i_lang, g_domain_sch_presence, 'I');
            END IF;
        END IF;
        --present
        IF l_presence = l_val.count
        THEN
            IF i_rank = pk_alert_constant.g_yes
            THEN
                l_icon := pk_sysdomain.get_ranked_img(i_lang, g_domain_sch_presence, 'D');
            ELSE
                l_icon := pk_sysdomain.get_img(i_lang, g_domain_sch_presence, 'D');
            END IF;
        END IF;
    
        RETURN l_icon;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_group_presence_icon;
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
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
    
        IF i_id_schedule IS NULL
        THEN
            SELECT pk_alert_constant.g_yes
              INTO l_return
              FROM epis_info ei
              JOIN schedule s
                ON s.id_schedule = ei.id_schedule
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
             WHERE ei.id_episode = i_id_episode
               AND se.flg_is_group = pk_alert_constant.g_yes;
        ELSE
            SELECT pk_alert_constant.g_yes
              INTO l_return
              FROM schedule s
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
             WHERE s.id_schedule = i_id_schedule
               AND se.flg_is_group = pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_return;
    END is_group_app;

    PROCEDURE initialize_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        k_lang             CONSTANT NUMBER(24) := 1;
        k_prof_id          CONSTANT NUMBER(24) := 2;
        k_prof_institution CONSTANT NUMBER(24) := 3;
        k_prof_software    CONSTANT NUMBER(24) := 4;
        k_episode          CONSTANT NUMBER(24) := 5;
        k_patient          CONSTANT NUMBER(24) := 6;
    
        g_yes                    CONSTANT VARCHAR2(1 CHAR) := 'Y';
        g_no                     CONSTANT VARCHAR2(1 CHAR) := 'N';
        g_doctor                 CONSTANT VARCHAR2(1 CHAR) := 'D';
        g_nurse                  CONSTANT VARCHAR2(1 CHAR) := 'N';
        g_epis_flg_status_active CONSTANT VARCHAR2(1 CHAR) := 'A';
        g_selected               CONSTANT VARCHAR2(1 CHAR) := 'S';
        g_schedule               CONSTANT VARCHAR2(1 CHAR) := 'S';
    
        l_prof    CONSTANT profissional := profissional(i_context_ids(k_prof_id),
                                                        i_context_ids(k_prof_institution),
                                                        i_context_ids(k_prof_software));
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(k_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(k_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(k_episode);
    
        l_epis_type_nurse_care NUMBER(24) := -1;
    
    BEGIN
    
        IF (l_prof.software <> 3)
        THEN
            l_epis_type_nurse_care := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', l_prof);
        END IF;
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'l_prof_cat' THEN
                o_vc2 := pk_edis_list.get_prof_cat(l_prof);
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, o_vc2);
            WHEN 'g_yes' THEN
                o_vc2 := g_yes;
            WHEN 'l_reasongrid' THEN
                o_vc2 := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID', l_prof);
            WHEN 'g_epis_flg_status_active' THEN
                o_vc2 := g_epis_flg_status_active;
            WHEN 'g_selected' THEN
                o_vc2 := g_selected;
            WHEN 'l_epis_type_nurse' THEN
                o_id := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', l_prof);
            WHEN 'l_epis_type_nurse_care' THEN
                o_id := l_epis_type_nurse_care;
            WHEN 'l_doc_nurse_appointment_access' THEN
                o_vc2 := pk_sysconfig.get_config('DOCTOR_NURSE_APPOINTMENT_ACCESS', l_prof);
            WHEN 'g_no' THEN
                o_vc2 := g_no;
            WHEN 'g_doctor' THEN
                o_vc2 := g_doctor;
            WHEN 'g_nurse' THEN
                o_vc2 := g_nurse;
            WHEN 'g_schedule' THEN
                o_vc2 := g_schedule;
        END CASE;
    END initialize_params;

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
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(8 CHAR) := pk_alert_constant.g_no;
    BEGIN
    
        l_return := CASE
                        WHEN (i_dt IS NULL OR lpad(i_dt, g_yyyymmdd) = lpad(g_sysdate_char, g_yyyymmdd)) THEN
                         i_wr_call
                        ELSE
                         pk_alert_constant.g_no
                    END;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_return;
    END wr_call;
    /********************************************************************************************
    * change_grid_info
    * @version 2.5.2
    * @since  2012/06/05
    **********************************************************************************************/
    FUNCTION get_change_grid_info
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_group             IN sch_group.id_group%TYPE,
        i_type_appoint_edition IN VARCHAR2 DEFAULT 'Y',
        o_info                 OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHANGE_GRID_INFO';
        l_t_rec_fields t_coll_fields := t_coll_fields();
    
        l_presence_desc         sys_domain.desc_val%TYPE;
        l_presence_value        sch_group.flg_contact_type%TYPE;
        l_id_dep_clin_serv      dep_clin_serv.id_dep_clin_serv%TYPE;
        l_clinical_service_desc translation.desc_lang_1%TYPE;
        l_sch_event_desc        translation.desc_lang_1%TYPE;
        l_dt_target_tstz        schedule_outp.dt_target_tstz%TYPE;
    
        l_dt_min schedule_outp.dt_target_tstz%TYPE;
        l_dt_max schedule_outp.dt_target_tstz%TYPE;
    
        l_id_sch_event sch_event.id_sch_event%TYPE;
    
        -- FLGS FOR THE FIELDS
        l_event_mandatory VARCHAR2(10 CHAR) := pk_alert_constant.g_no;
        l_event_active    VARCHAR2(10 CHAR) := pk_alert_constant.g_no; -- by the fault is N
    
        l_appointment_mandatory VARCHAR2(10 CHAR) := pk_alert_constant.g_yes;
        l_appointment_active    VARCHAR2(10 CHAR) := pk_alert_constant.g_yes;
    
        l_presence_mandatory VARCHAR2(10 CHAR) := pk_alert_constant.g_no;
        l_presence_active    VARCHAR2(10 CHAR) := pk_alert_constant.g_yes;
    
        l_check_first_obs VARCHAR2(10);
    
        l_edit_app_type sys_config.value%TYPE;
    BEGIN
    
        -- check if type of appointment is editable
        g_error         := 'CALL pk_sysconfig.get_config';
        l_edit_app_type := pk_sysconfig.get_config(i_code_cf => pk_progress_notes.g_config_edit_app_type,
                                                   i_prof    => i_prof);
    
        -- VERSAO 2 DO HENRIQUE
        -- NO SOAP se for uma consulta de grupo não pode deixar alterar o tipo appointment.
    
        -- aqui so podemos deixar alterar se for no grupo, se for de grupo mas alterar individual nao pode
        -- coincidencia de estados presente.
        -------------------------------------------------------------------------------------------------------------------------
        -- GET DATA BY SCHEDULE
        -------------------------------------------------------------------------------------------------------------------------
        g_error := 'FAIL TO OBTAIN INFO';
        IF i_id_schedule IS NOT NULL
        THEN
            -- Check if theres data already associated on this episode/schedule
            l_check_first_obs := pk_visit.check_first_obs(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_id_episode  => NULL,
                                                          i_id_schedule => i_id_schedule);
        
            SELECT pk_sysdomain.get_domain(g_domain_sch_presence, sg.flg_contact_type, i_lang) presence_desc,
                   sg.flg_contact_type presence_value,
                   ei.id_dep_clin_serv,
                   (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                      FROM dep_clin_serv dcs, clinical_service cs
                     WHERE dcs.id_dep_clin_serv = nvl(ei.id_dep_clin_serv, s.id_dcs_requests)
                       AND cs.id_clinical_service = dcs.id_clinical_service) clinical_service_desc,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) sch_event_desc,
                   s.id_sch_event,
                   sp.dt_target_tstz
              INTO l_presence_desc,
                   l_presence_value,
                   l_id_dep_clin_serv,
                   l_clinical_service_desc,
                   l_sch_event_desc,
                   l_id_sch_event,
                   l_dt_target_tstz
              FROM schedule_outp sp
              JOIN schedule s
                ON s.id_schedule = sp.id_schedule
              JOIN sch_group sg
                ON sg.id_schedule = s.id_schedule
              JOIN epis_type et
                ON sp.id_epis_type = et.id_epis_type
              LEFT JOIN epis_info ei
                ON s.id_schedule = ei.id_schedule
               AND ei.id_patient = sg.id_patient
              LEFT JOIN episode e
                ON ei.id_episode = e.id_episode
               AND e.id_patient = ei.id_patient
            --LEFT JOIN sch_prof_outp spo
            --ON spo.id_schedule_outp = sp.id_schedule_outp
              LEFT JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
             WHERE s.id_schedule = i_id_schedule;
        
        ELSIF i_id_group != 0
              OR i_id_group IS NOT NULL
              AND i_id_schedule IS NULL
        THEN
            -- Always NO cant change group appointments
            l_check_first_obs := pk_alert_constant.g_no;
        
            -- CANT CHANGE GROUP PATIENTS INDIVIDUALLY 
            -- GET 1 registry data from group to show
            SELECT ei.id_dep_clin_serv,
                   (SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                      FROM dep_clin_serv dcs, clinical_service cs
                     WHERE dcs.id_dep_clin_serv = nvl(ei.id_dep_clin_serv, s.id_dcs_requests)
                       AND cs.id_clinical_service = dcs.id_clinical_service) clinical_service_desc,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) sch_event_desc,
                   s.id_sch_event,
                   sp.dt_target_tstz
              INTO l_id_dep_clin_serv, l_clinical_service_desc, l_sch_event_desc, l_id_sch_event, l_dt_target_tstz
              FROM schedule_outp sp
              JOIN schedule s
                ON s.id_schedule = sp.id_schedule
              JOIN sch_group sg
                ON sg.id_schedule = s.id_schedule
              JOIN epis_type et
                ON sp.id_epis_type = et.id_epis_type
              LEFT JOIN epis_info ei
                ON s.id_schedule = ei.id_schedule
               AND ei.id_patient = sg.id_patient
              LEFT JOIN episode e
                ON ei.id_episode = e.id_episode
               AND e.id_patient = ei.id_patient
            --LEFT JOIN sch_prof_outp spo
            --  ON spo.id_schedule_outp = sp.id_schedule_outp
              LEFT JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
             WHERE s.id_group = i_id_group
               AND rownum = 1;
        
            -- GET GROUP PRESENCE 
            l_presence_value := pk_grid_amb.get_group_presence_val(i_lang, i_prof, i_id_group);
            l_presence_desc  := pk_sysdomain.get_domain(g_domain_sch_presence, l_presence_value, i_lang);
        
        END IF;
    
        -------------------------------------------------------------------------------------------------------------------------
        -- VALIDATIONS
        -------------------------------------------------------------------------------------------------------------------------
    
        /* DECIDIDO NÃO COLOCAR A VALIDAÇÃO DO DIA
        g_error := 'CALL get_date_bounds';
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => g_sysdate_tstz, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
                
        -- CHECK SAME DAY
        IF l_dt_target_tstz not between l_dt_min and l_dt_max THEN
            l_appointment_active := pk_alert_constant.g_no;
            l_event_active       := pk_alert_constant.g_no;
        END IF;*/
    
        -- cant change patients in a group, have to change the whole group.
        IF i_id_group != 0
           AND i_id_schedule IS NOT NULL
        THEN
            l_appointment_active := pk_alert_constant.g_no;
            l_event_active       := pk_alert_constant.g_no;
        END IF;
    
        -- if theres data associated or schedule is null cant change appointment or event                                                                           
        IF l_check_first_obs = pk_alert_constant.g_yes
           OR i_id_schedule IS NULL
        THEN
            l_appointment_active := pk_alert_constant.g_no;
            l_event_active       := pk_alert_constant.g_no;
        END IF;
    
        IF l_edit_app_type = pk_alert_constant.g_no
        THEN
            l_appointment_active := pk_alert_constant.g_no;
            l_event_active       := pk_alert_constant.g_no;
        END IF;
    
        IF i_type_appoint_edition = pk_alert_constant.g_no
        THEN
            l_appointment_active := pk_alert_constant.g_no;
        END IF;
    
        g_error := 'FAIL TO EXTEND INFO';
        l_t_rec_fields.extend;
        l_t_rec_fields(1) := t_rec_fields(field_id          => 'EVENT',
                                          field_title       => pk_message.get_message(i_lang      => i_lang,
                                                                                      i_code_mess => 'SCH_T741'),
                                          field_mandatory   => l_event_mandatory,
                                          field_active      => l_event_active,
                                          field_description => l_sch_event_desc,
                                          field_value       => l_id_sch_event,
                                          field_info        => pk_alert_constant.g_yes,
                                          rank              => 10);
        l_t_rec_fields.extend;
        l_t_rec_fields(2) := t_rec_fields(field_id          => 'APPOINTMENT',
                                          field_title       => pk_message.get_message(i_lang      => i_lang,
                                                                                      i_code_mess => 'FUTURE_EVENTS_T113'),
                                          field_mandatory   => l_appointment_mandatory,
                                          field_active      => l_appointment_active,
                                          field_description => l_clinical_service_desc,
                                          field_value       => l_id_dep_clin_serv,
                                          field_info        => pk_alert_constant.g_no,
                                          rank              => 20);
        l_t_rec_fields.extend;
        l_t_rec_fields(3) := t_rec_fields(field_id          => 'PRESENCE',
                                          field_title       => pk_message.get_message(i_lang      => i_lang,
                                                                                      i_code_mess => 'COMMON_M137'),
                                          field_mandatory   => l_presence_mandatory,
                                          field_active      => l_presence_active,
                                          field_description => l_presence_desc,
                                          field_value       => l_presence_value,
                                          field_info        => pk_alert_constant.g_no,
                                          rank              => 30);
    
        OPEN o_info FOR
            SELECT t.*
              FROM TABLE(l_t_rec_fields) t
             ORDER BY t.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => l_func_name,
                                                     o_error    => o_error);
        
    END get_change_grid_info;
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
    ) RETURN VARCHAR2 IS
        l_ret sys_config.value%TYPE;
    BEGIN
        SELECT decode(i_waiting_room_available,
                      pk_alert_constant.g_yes,
                      pk_wlcore.get_available_for_call(i_lang, i_prof, i_id_episode, i_flg_state, i_flg_ehr),
                      decode(i_waiting_room_sys_external,
                             pk_alert_constant.g_yes,
                             pk_wlcore.get_episode_efective(i_lang,
                                                            i_prof,
                                                            i_id_episode,
                                                            pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                              i_prof,
                                                                                              i_id_dcs_requested,
                                                                                              i_flg_ehr,
                                                                                              pk_grid.get_schedule_real_state(i_flg_state,
                                                                                                                              i_flg_ehr))),
                             pk_alert_constant.g_no))
          INTO l_ret
          FROM dual;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_wr_call;

    /**********************************************************************************************
    * Get Id lock.
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
    ) RETURN NUMBER IS
        l_id_lock table_number;
    BEGIN
    
        l_id_lock := pk_lock.get_lock_prints(i_func => table_varchar(i_tab_name), i_ids => table_number(i_id));
    
        RETURN l_id_lock(1);
    END get_grid_lock;

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
    ) RETURN BOOLEAN IS
        l_wr_available              sys_config.value%TYPE;
        l_dt_min                    schedule_outp.dt_target_tstz%TYPE;
        l_dt_max                    schedule_outp.dt_target_tstz%TYPE;
        l_to_old_area               sys_config.value%TYPE;
        l_reasongrid                sys_config.value%TYPE;
        l_waiting_room_available    sys_config.value%TYPE := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
        l_waiting_room_sys_external sys_config.value%TYPE := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM',
                                                                                     i_prof);
        l_show_med_disch            sys_config.value%TYPE;
        l_session_without_schedule  sys_message.desc_message%TYPE;
    BEGIN
        g_error        := 'GET G_SYSDATE';
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => g_sysdate_tstz, i_prof => i_prof);
    
        ---------------------------------
        g_error := 'CALL get_date_bounds';
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        ---------------------------------
        g_error := 'GET CONFIG DEFINITIONS';
        --l_to_old_area    := pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof);
        l_reasongrid               := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID', i_prof);
        l_show_med_disch           := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID', i_prof), g_yes);
        l_wr_available             := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
        l_session_without_schedule := pk_message.get_message(i_lang, i_prof, 'REHAB_T147');
        ---------------------------------
        g_error := 'OPENo_grid';
        OPEN o_grid FOR
            SELECT s.id_schedule,
                   sg.id_patient,
                   (SELECT cr.num_clin_record
                      FROM clin_record cr
                     WHERE cr.id_patient = sg.id_patient
                       AND cr.id_institution = i_prof.institution
                       AND rownum < 2) num_clin_record,
                   decode(e.id_epis_type,
                          pk_alert_constant.g_epis_type_rehab_appointment,
                          re.id_episode_rehab,
                          ei.id_episode) id_episode,
                   ei.id_episode id_episode_origin,
                   e.id_epis_type,
                   decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                          g_sched_scheduled,
                          '',
                          pk_date_utils.date_char_hour_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software)) dt_efectiv,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   (SELECT pk_sysdomain.get_domain(g_domain_pat_gender_abbr, pat.gender, i_lang)
                      FROM patient pat
                     WHERE sg.id_patient = pat.id_patient) gender,
                   pk_patient.get_pat_age(i_lang, sg.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, s.id_schedule) photo,
                   pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                   pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(ei.id_professional, spo.id_professional)) name_prof,
                   
                   pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                   (SELECT get_room_desc(i_lang, decode(e.flg_ehr, pk_ehr_access.g_flg_ehr_scheduled, NULL, ei.id_room))
                      FROM dual) desc_room,
                   decode(s.flg_status,
                          g_sched_canc,
                          g_sched_canc,
                          decode(e.id_epis_type,
                                 pk_alert_constant.g_epis_type_rehab_appointment,
                                 pk_rehab.get_rehab_app_status(i_lang, i_prof, e.id_patient, re.flg_status),
                                 pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr))) flg_state,
                   decode(sp.flg_sched, g_flg_sched_w, g_flg_sched_a, sp.flg_sched) flg_type, --for rehab appointment it's necessary to return as A for consider this as an acheduled appointment
                   /*  pk_sysdomain.get_img(i_lang,
                   g_schdl_outp_state_domain,
                   pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr)) img_state,*/
                   decode(e.id_epis_type,
                          pk_alert_constant.g_epis_type_rehab_appointment,
                          pk_sysdomain.get_ranked_img('REHAB_EPIS_ENCOUNTER.FLG_STATUS',
                                                      nvl(re.flg_status, pk_rehab.g_rehab_epis_enc_status_a),
                                                      i_lang),
                          pk_sysdomain.get_ranked_img(g_schdl_outp_state_domain, sp.flg_state, i_lang)) img_state,
                   g_sysdate_char dt_server,
                   CASE
                        WHEN i_dt IS NULL THEN
                         pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                 i_prof                      => i_prof,
                                                 i_waiting_room_available    => l_waiting_room_available,
                                                 i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                 i_id_episode                => ei.id_episode,
                                                 i_flg_state                 => sp.flg_state,
                                                 i_flg_ehr                   => e.flg_ehr,
                                                 i_id_dcs_requested          => s.id_dcs_requested)
                        ELSE
                         pk_alert_constant.g_no
                    END wr_call,
                   decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                          g_sched_scheduled,
                          NULL,
                          pk_date_utils.date_send_tsz(i_lang, e.dt_begin_tstz, i_prof)) dt_begin,
                   decode(l_reasongrid,
                          g_yes,
                          pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                      i_prof,
                                                                                                      ei.id_episode,
                                                                                                      s.id_schedule),
                                                           4000)) visit_reason,
                   --     pk_sysdomain.get_domain(pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy, i_lang) desc_sched,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, s.id_sch_event, se.code_sch_event) sch_event_desc,
                   decode(e.id_episode,
                          NULL,
                          '',
                          pk_sysdomain.get_domain(g_epis_flg_appointment_type,
                                                  nvl(e.flg_appointment_type, g_null_appointment_type),
                                                  i_lang)) cont_type,
                   pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                   sg.flg_contact_type,
                   
                   (SELECT pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type)
                      FROM dual) icon_contact_type,
                   pk_sysdomain.get_domain(g_domain_sch_presence, sg.flg_contact_type, i_lang) presence_desc,
                   -- drug prescriptions and requests
                   CASE
                        WHEN gt.id_episode IS NOT NULL THEN
                         pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc)
                        ELSE
                         NULL
                    END desc_drug_presc,
                   -- procedures, monitorizations, patient education
                   pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                          i_prof,
                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                      i_prof,
                                                                                      gt.icnp_intervention,
                                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                                  i_prof,
                                                                                                                  gt.nurse_activity,
                                                                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                                                                              i_prof,
                                                                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                                                                          i_prof,
                                                                                                                                                                          gt.intervention,
                                                                                                                                                                          gt.monitorization,
                                                                                                                                                                          NULL,
                                                                                                                                                                          pk_alert_constant.g_cat_type_nurse),
                                                                                                                                              gt.teach_req,
                                                                                                                                              NULL,
                                                                                                                                              pk_alert_constant.g_cat_type_nurse),
                                                                                                                  NULL,
                                                                                                                  pk_alert_constant.g_cat_type_nurse),
                                                                                      NULL,
                                                                                      pk_alert_constant.g_cat_type_nurse)) desc_interv_presc,
                   -- lab tests and exams          
                   pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                          i_prof,
                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                      i_prof,
                                                                                      pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                     i_prof,
                                                                                                                     e.id_visit,
                                                                                                                     g_task_analysis,
                                                                                                                     pk_alert_constant.g_cat_type_nurse),
                                                                                      pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                     i_prof,
                                                                                                                     e.id_visit,
                                                                                                                     g_task_exam,
                                                                                                                     pk_alert_constant.g_cat_type_nurse),
                                                                                      g_analysis_exam_icon_grid_rank,
                                                                                      pk_alert_constant.g_cat_type_nurse)) desc_ana_exam_req, --,
                   --                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(ei.id_professional, spo.id_professional)) resp_prof_name
                   pk_alert_constant.g_no flg_type_appoint_edition,
                   e.flg_ehr,
                   pk_alert_constant.g_yes flg_cons_type_edit,
                   re.id_rehab_epis_encounter id_rehab_grid,
                   s.id_schedule id_lock_uq_value,
                   'REHAB_GRID_SCHED' lock_func,
                   get_grid_lock(i_lang, i_prof, 'REHAB_GRID_SCHED', s.id_schedule) id_lock
              FROM schedule_outp sp
              JOIN schedule s
                ON (s.id_schedule = sp.id_schedule AND
                   s.flg_status NOT IN
                   (pk_schedule.g_sched_status_cache, g_sched_canc, pk_schedule.g_sched_status_temporary))
              JOIN sch_group sg
                ON sg.id_schedule = s.id_schedule
              LEFT JOIN epis_info ei
                ON ei.id_schedule = s.id_schedule
              JOIN epis_type et
                ON sp.id_epis_type = et.id_epis_type
              JOIN episode e
                ON ei.id_episode = e.id_episode
              JOIN sch_prof_outp spo
                ON spo.id_schedule_outp = sp.id_schedule_outp
              LEFT JOIN grid_task gt
                ON gt.id_episode = e.id_episode
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              LEFT JOIN rehab_epis_encounter re
                ON re.id_episode_origin = e.id_episode
             WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
               AND (l_show_med_disch = g_yes OR
                   (l_show_med_disch = g_no AND
                   pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_med_disch))
               AND s.id_instit_requested = i_prof.institution
               AND EXISTS (SELECT 0
                      FROM prof_dep_clin_serv pdcs
                     WHERE pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                       AND pdcs.id_dep_clin_serv = ei.id_dep_clin_serv)
               AND e.id_epis_type IN (pk_alert_constant.g_epis_type_social,
                                      pk_alert_constant.g_epis_type_dietitian,
                                      pk_alert_constant.g_epis_type_rehab_appointment)
            /*           UNION ALL
                        SELECT id_schedule,
                               id_patient,
                               num_clin_record,
                               id_episode,
                               id_episode_origin,
                               15                     id_epis_type,
                               dt_efectiv,
                               name,
                               name_to_sort,
                               pat_ndo,
                               pat_nd_icon,
                               gender,
                               pat_age,
                               photo,
                               desc_schedule_type     cons_type,
                               dt_target,
                               nick_name              name_prof,
                               NULL                   name_nurse,
                               desc_room,
                               flg_status,
                               flg_type,
                               new_icon_name,
                               dt_server,
                               NULL,
                               dt_efectiv,
                               NULL                   visit_reason,
                               desc_session_type,
                               NULL                   cont_type,
                               NULL                   flg_contact,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               NULL,
                               pk_alert_constant.g_no flg_type_appoint_edition,
                               NULL                   flg_ehr,
                               pk_alert_constant.g_no flg_cons_type_edit
                          FROM (SELECT DISTINCT NULL id_schedule,
                                                (SELECT cr.num_clin_record
                                                   FROM clin_record cr
                                                  WHERE cr.id_patient = rbp.id_patient
                                                    AND cr.id_institution = i_prof.institution
                                                    AND rownum < 2) num_clin_record,
                                                e.id_patient,
                                                e.id_episode id_episode_origin,
                                                re.id_episode_rehab id_episode,
                                                e.id_visit,
                                                pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode, NULL) name,
                                                pk_patient.get_pat_name_to_sort(i_lang, i_prof, e.id_patient, e.id_episode, NULL) name_to_sort,
                                                pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                                                pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon,
                                                pk_patient.get_pat_age(i_lang, e.id_patient, i_prof) pat_age,
                                                pk_patient.get_pat_gender(e.id_patient) AS gender,
                                                pk_patphoto.get_pat_photo(i_lang, i_prof, e.id_patient, e.id_episode, NULL) photo,
                                                pk_rehab.get_rehab_sch_need_resp(i_lang,
                                                                                 rsn.id_resp_professional,
                                                                                 rsn.id_resp_rehab_group) nick_name,
                                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                 re.dt_creation,
                                                                                 i_prof.institution,
                                                                                 i_prof.software) dt_efectiv,
                                                pk_date_utils.dt_chr_hour_tsz(i_lang, NULL, i_prof.institution, i_prof.software) dt_target,
                                                g_sysdate_char dt_server,
                                                pk_sysdomain.get_ranked_img(pk_rehab.g_rehab_epis_enc_flg_status,
                                                                            nvl(re.flg_status, pk_rehab.g_rehab_epis_enc_status_e),
                                                                            i_lang) new_icon_name,
                                                \*                                    pk_rehab.get_grid_workflow_icon(i_lang,
                                                i_prof,
                                                pk_rehab.g_workflow_type_w,
                                                nvl(re.flg_status, pk_rehab.g_rehab_epis_enc_status_e)) new_icon_name,*\
                                                -1 shortcut,
                                                pk_date_utils.date_send_tsz(i_lang, NULL, i_prof) AS dt_exec,
                                                nvl(re.flg_status, pk_rehab.g_rehab_epis_enc_status_e) AS flg_status,
                                                pk_rehab.g_workflow_type_w AS flg_type,
                                                1 AS id_schedule_type,
                                                l_session_without_schedule AS desc_schedule_type,
                                                pk_translation.get_translation(i_lang, rst.code_rehab_session_type) AS desc_session_type,
                                                decode(bd.code_bed,
                                                       NULL,
                                                       NULL,
                                                       nvl(pk_translation.get_translation(i_lang, dpt.abbreviation),
                                                           pk_translation.get_translation(i_lang, dpt.code_department))) desc_service,
                                                nvl(nvl(ro.desc_room_abbreviation,
                                                        pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                                                    nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                                                nvl(bd.desc_bed, pk_translation.get_translation(i_lang, bd.code_bed)) desc_bed,
                                                re.id_rehab_epis_encounter id_rehab_grid,
                                                rsn.id_rehab_sch_need id_rehab_presc,
                                                NULL id_rehab_schedule,
                                                pk_sysdomain.get_domain('EPIS_EXT_SYS.EPIS_INFO_SOFT_DESC', ei.id_software, i_lang) origin,
                                                pk_adt.is_contact(i_lang, i_prof, e.id_patient) flg_contact,
                                                pk_sysdomain.get_rank(i_lang,
                                                                      pk_rehab.g_rehab_epis_enc_flg_status,
                                                                      nvl(re.flg_status, pk_rehab.g_rehab_epis_enc_status_e)) status_rank,
                                                rank() over(PARTITION BY e.id_patient, rst.id_rehab_session_type ORDER BY rp.id_rehab_presc DESC) precedence_level
                                  FROM rehab_presc rp
                                  JOIN rehab_sch_need rsn
                                    ON rsn.id_rehab_sch_need = rp.id_rehab_sch_need
                                  JOIN rehab_session_type rst
                                    ON rst.id_rehab_session_type = rsn.id_rehab_session_type
                                  JOIN rehab_plan rbp
                                    ON rbp.id_episode_origin = rsn.id_episode_origin
                                  JOIN episode e
                                    ON e.id_episode = rsn.id_episode_origin -- falta este episódio
                                  JOIN rehab_environment r
                                    ON r.id_epis_type = e.id_epis_type
                                   AND r.id_institution = i_prof.institution
                                \*                       AND r.id_rehab_environment IN (SELECT rep.id_rehab_environment
                                 FROM rehab_environment_prof rep
                                WHERE rep.id_professional = i_prof.id)*\
                                  LEFT JOIN epis_info ei
                                    ON ei.id_episode = e.id_episode
                                  LEFT JOIN rehab_epis_encounter re
                                    ON (re.id_episode_origin = e.id_episode AND re.dt_creation BETWEEN l_dt_min AND l_dt_max AND
                                       re.id_rehab_sch_need = rsn.id_rehab_sch_need)
                                  LEFT JOIN bed bd
                                    ON bd.id_bed = ei.id_bed
                                  LEFT JOIN room ro
                                    ON ro.id_room = bd.id_room
                                  LEFT JOIN department dpt
                                    ON dpt.id_department = ro.id_department
                                 WHERE rsn.flg_status = pk_rehab.g_rehab_sch_need_no_sched
                                   AND rp.flg_status NOT IN (pk_rehab.g_rehab_presc_referral, pk_rehab.g_rehab_presc_not_order_reas)
                                      --epis_origin activo
                                   AND e.flg_status = pk_alert_constant.g_active
                                   AND rp.id_institution = i_prof.institution
                                   AND (rsn.dt_begin IS NULL OR
                                       (pk_date_utils.get_timestamp_diff(current_timestamp, rsn.dt_begin) >= 0 OR
                                       (pk_date_utils.get_timestamp_diff(current_timestamp, rsn.dt_begin) >= -1 AND
                                       extract(DAY FROM(current_timestamp)) >= extract(DAY FROM(rsn.dt_begin)))))) t
                         WHERE t.precedence_level = 1
            */
             ORDER BY --status_rank,
                      dt_target,
                      dt_begin,
                      name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'PARAMEDICAL_APPOINTMENT',
                                              o_error    => o_error);
            RETURN FALSE;
    END paramedical_appointment;

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
    ) RETURN BOOLEAN IS
    
        l_num_days_back    sys_config.value%TYPE;
        l_num_days_forward sys_config.value%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error            := 'GET NUM DAYS';
        l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', i_prof);
        l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
        IF l_num_days_forward <= 0
        THEN
            l_num_days_forward := 10;
        END IF;
    
        g_error := 'OPEN O_DATE';
        OPEN o_date FOR
            SELECT pk_grid_amb.get_extense_day_desc(i_lang, t.day) date_desc, DAY date_tstz, today
              FROM (SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz - LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_back
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz, 'DD') AS DAY,
                           pk_alert_constant.g_yes today
                      FROM dual
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz + LEVEL, 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_forward) t
             ORDER BY t.day;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'paramedical_appointment_dates',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
    END paramedical_appointment_dates;

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
    FUNCTION get_param_status_list_int
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_epis_type   IN episode.id_epis_type%TYPE,
        i_flg_status     IN VARCHAR2,
        i_flg_type       IN VARCHAR2,
        i_enable_actions IN VARCHAR2,
        o_status         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_exists_discharge IS
            SELECT d.dt_med_tstz
              FROM discharge d
             WHERE d.id_episode = (SELECT id_episode
                                     FROM epis_info ei
                                    WHERE ei.id_schedule = i_id_schedule)
               AND d.flg_status = pk_grid.g_discharge_active;
        r_exists_discharge c_exists_discharge%ROWTYPE;
    
        l_episode_registry sys_config.value%TYPE;
        l_schd_outp_state  schedule_outp.flg_state%TYPE := NULL;
        l_exists_discharge VARCHAR2(1) := 'N';
    
        l_config_software sys_config.value%TYPE;
    
        l_show_sign_off sys_config.value%TYPE;
    
        l_epis_type        schedule_outp.id_epis_type%TYPE;
        l_is_contact       VARCHAR2(1 CHAR);
        l_episode_software software.id_software%TYPE;
        l_can_cancel       VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET SYS_CONFIG DOCTOR_EPISODE_REGISTRY';
    
        l_episode_registry := pk_sysconfig.get_config('NURSE_CAN_REGISTER', i_prof); -- CONSULTAS MÉDICAS
    
        l_show_sign_off := nvl(pk_sysconfig.get_config('SHOW_SIGNOFF', i_prof), pk_alert_constant.g_no);
    
        l_is_contact := pk_adt.is_contact(i_lang, i_prof, i_id_patient);
        IF i_id_episode IS NOT NULL
        THEN
            l_episode_software := pk_episode.get_episode_software(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_episode => i_id_episode);
        END IF;
    
        l_can_cancel := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_intern_name => 'CANCEL_EPISODE');
    
        g_error := 'CALC EPISODE CURRENT STATUS';
        IF i_id_schedule IS NOT NULL
        THEN
            SELECT decode(s.flg_status, 'C', 'C', pk_grid.get_schedule_real_state(so.flg_state, e.flg_ehr)),
                   so.id_epis_type
              INTO l_schd_outp_state, l_epis_type
              FROM schedule s
              JOIN schedule_outp so
                ON so.id_schedule = s.id_schedule
              LEFT JOIN epis_info ei
                ON s.id_schedule = ei.id_schedule
              LEFT JOIN episode e
                ON ei.id_episode = e.id_episode
             WHERE s.id_schedule = i_id_schedule;
        END IF;
    
        OPEN c_exists_discharge;
        FETCH c_exists_discharge
            INTO r_exists_discharge;
        IF c_exists_discharge%FOUND
        THEN
            l_exists_discharge := 'Y';
        END IF;
        CLOSE c_exists_discharge;
    
        l_config_software := pk_sysconfig.get_config('SOFTWARE_ID_NUTRI', i_prof);
        --Obtem os estados possíveis de um paciente
        IF l_epis_type = pk_alert_constant.g_epis_type_dietitian -- nutrition appointment
        THEN
            g_error := 'GET PAT STATUS CURSOR';
            OPEN o_status FOR
            
                SELECT /*+opt_estimate(table,sd,scale_rows=0.0001)*/
                 decode(l_episode_registry,
                        'Y',
                        decode(sd.val,
                               g_sched_scheduled,
                               decode(l_schd_outp_state,
                                      g_sched_efectiv,
                                      pk_sysdomain.get_domain(g_schdl_outp_state_act_domain, sd.val, i_lang),
                                      sd.desc_val),
                               g_sched_efectiv,
                               decode(l_schd_outp_state,
                                      g_sched_scheduled,
                                      pk_sysdomain.get_domain(g_schdl_outp_state_act_domain, sd.val, i_lang),
                                      sd.desc_val),
                               sd.desc_val),
                        sd.desc_val) label,
                 sd.val data,
                 sd.img_name icon,
                 decode(i_enable_actions,
                        pk_alert_constant.g_no,
                        pk_alert_constant.g_no,
                        decode(l_episode_registry,
                               pk_alert_constant.g_yes,
                               decode(sd.val,
                                      g_sched_scheduled,
                                      
                                      decode(l_schd_outp_state,
                                             g_sched_efectiv,
                                             pk_alert_constant.g_yes,
                                             pk_grid.g_sched_ortopt,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no),
                                      g_sched_efectiv,
                                      decode(l_is_contact,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no,
                                             decode(l_schd_outp_state,
                                                    g_sched_scheduled,
                                                    pk_alert_constant.g_yes,
                                                    pk_alert_constant.g_no)),
                                      g_sched_canc,
                                      decode(l_can_cancel,
                                             pk_alert_constant.g_yes,
                                             decode(l_schd_outp_state,
                                                    g_sched_scheduled,
                                                    pk_alert_constant.g_yes,
                                                    pk_alert_constant.g_no),
                                             pk_alert_constant.g_no),
                                      pk_grid.g_flg_no_show,
                                      decode(l_schd_outp_state,
                                             g_sched_scheduled,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no),
                                      pk_alert_constant.g_no),
                               pk_alert_constant.g_no)) flg_action,
                 NULL action
                  FROM sys_domain sd
                 WHERE sd.code_domain = g_schdl_outp_state_act_domain
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND sd.id_language = i_lang
                 ORDER BY rank;
        ELSIF l_epis_type = pk_alert_constant.g_epis_type_social -- social appointment
        THEN
            g_error := 'OPEN o_status - SOCIAL';
            OPEN o_status FOR
                SELECT /*+opt_estimate(table,sd,scale_rows=0.0001)*/
                 decode(l_episode_registry,
                        'Y',
                        decode(sd.val,
                               g_sched_scheduled,
                               decode(l_schd_outp_state,
                                      g_sched_efectiv,
                                      pk_sysdomain.get_domain(g_schdl_outp_state_act_domain, sd.val, i_lang),
                                      sd.desc_val),
                               g_sched_efectiv,
                               decode(l_schd_outp_state,
                                      g_sched_scheduled,
                                      pk_sysdomain.get_domain(g_schdl_outp_state_act_domain, sd.val, i_lang),
                                      sd.desc_val),
                               sd.desc_val),
                        sd.desc_val) label,
                 sd.val data,
                 sd.img_name icon,
                 decode(sd.val,
                        g_sched_cons,
                        'N',
                        pk_grid.g_shed_discharge_med,
                        decode(l_schd_outp_state, g_sched_cons, decode(l_exists_discharge, 'Y', 'Y', 'N'), 'N'),
                        decode(l_episode_registry,
                               'Y',
                               decode(sd.val,
                                      pk_grid.g_sched_scheduled,
                                      decode(l_schd_outp_state, g_sched_efectiv, 'Y', 'N'),
                                      pk_grid.g_sched_efectiv,
                                      decode(l_is_contact,
                                             pk_alert_constant.g_yes,
                                             pk_alert_constant.g_no,
                                             decode(l_schd_outp_state, g_sched_scheduled, 'Y', 'N')),
                                      'N'),
                               'N')) flg_action,
                 NULL action
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang,
                                                                      profissional(i_prof.id,
                                                                                   i_prof.institution,
                                                                                   pk_alert_constant.g_soft_social),
                                                                      g_schdl_outp_state_domain,
                                                                      0)) sd
                 WHERE sd.val IN
                       (g_sched_scheduled, g_sched_efectiv, g_sched_cons, g_sched_med_disch, g_sched_adm_disch)
                    OR (sd.val = pk_sign_off.g_sched_signoff_s AND l_show_sign_off = pk_alert_constant.g_yes)
                 ORDER BY rank;
        ELSIF i_id_epis_type = pk_alert_constant.g_epis_type_rehab_appointment -- Rehab appointment
        THEN
            OPEN o_status FOR
                SELECT /*+opt_estimate(table,act,scale_rows=0.0001)*/
                 desc_action label,
                 to_state data,
                 icon,
                 decode(flg_active, pk_alert_constant.g_inactive, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_action,
                 action
                  FROM TABLE(pk_action.tf_get_actions_with_exceptions(i_lang,
                                                                      i_prof,
                                                                      'REHAB_WORKFLOW_APPOINTMENT',
                                                                      i_flg_status)) act;
        ELSE
            OPEN o_status FOR
                SELECT /*+opt_estimate(table,act,scale_rows=0.0001)*/
                 desc_action label,
                 to_state data,
                 icon,
                 decode(flg_active, pk_alert_constant.g_inactive, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_action,
                 action
                  FROM TABLE(pk_action.tf_get_actions_with_exceptions(i_lang,
                                                                      i_prof,
                                                                      'REHAB_WORKFLOW_W_SCHEDULE',
                                                                      i_flg_status)) act;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PARAM_STATUS_LIST_INT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
        
    END get_param_status_list_int;

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
    ) RETURN BOOLEAN IS
        l_check_functionality VARCHAR2(1 CHAR);
    BEGIN
        l_check_functionality := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                       i_prof        => i_prof,
                                                                       i_intern_name => pk_access.g_view_only_profile);
    
        RETURN get_param_status_list_int(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_id_schedule    => i_id_schedule,
                                         i_id_patient     => i_id_patient,
                                         i_id_episode     => i_id_episode,
                                         i_id_epis_type   => i_id_epis_type,
                                         i_flg_status     => i_flg_status,
                                         i_flg_type       => i_flg_type,
                                         i_enable_actions => CASE
                                                                 WHEN l_check_functionality = pk_alert_constant.g_yes THEN
                                                                  pk_alert_constant.g_no
                                                                 ELSE
                                                                  pk_alert_constant.g_yes
                                                             END,
                                         o_status         => o_status,
                                         o_error          => o_error);
    END get_param_status_list;

    /*EMR-437*/
    FUNCTION getsql RETURN VARCHAR2 IS
    BEGIN
        RETURN g_sql;
    END getsql;

    /*EMR-437*/
    FUNCTION get_reason
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2 IS
        l_reason VARCHAR2(3000);
    BEGIN
        SELECT substr(concatenate(decode(nvl(ec.id_complaint, decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                         NULL,
                                         ec.patient_complaint,
                                         pk_translation.get_translation(i_lang,
                                                                        'COMPLAINT.CODE_COMPLAINT.' ||
                                                                        nvl(ec.id_complaint,
                                                                            decode(s2.flg_reason_type,
                                                                                   'C',
                                                                                   s2.id_reason,
                                                                                   NULL)))) || '; '),
                      1,
                      length(concatenate(decode(nvl(ec.id_complaint, decode(s2.flg_reason_type, 'C', s2.id_reason, NULL)),
                                                NULL,
                                                ec.patient_complaint,
                                                pk_translation.get_translation(i_lang,
                                                                               'COMPLAINT.CODE_COMPLAINT.' ||
                                                                               nvl(ec.id_complaint,
                                                                                   decode(s2.flg_reason_type,
                                                                                          'C',
                                                                                          s2.id_reason,
                                                                                          NULL))) || '; '))) -
                      length('; '))
          INTO l_reason
          FROM schedule s2
          LEFT JOIN epis_info ei2
            ON ei2.id_schedule = s2.id_schedule
          LEFT JOIN epis_complaint ec
            ON ec.id_episode = ei2.id_episode
         WHERE s2.id_schedule = i_id_schedule
           AND nvl(ec.flg_status, pk_gridfilter.get_strings('g_active')) = pk_gridfilter.get_strings('g_active');
    
        RETURN l_reason;
    
    END;

    /*EMR-437*/
    PROCEDURE setsql(i_sql IN VARCHAR2) IS
    BEGIN
        g_sql := i_sql;
    END;

    /*EMR-437*/
    FUNCTION get_sch_ids
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_type_appointments IN VARCHAR2
    ) RETURN table_number IS
        l_group_ids        table_number;
        l_schedule_ids     table_number;
        g_sysdate_tstz     TIMESTAMP := current_timestamp;
        l_show_med_disch   sys_config.value%TYPE := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID', i_prof),
                                                        pk_alert_constant.g_yes);
        l_show_nurse_disch sys_config.value%TYPE := nvl(pk_sysconfig.get_config('SHOW_NURSE_DISCHARGED_GRID', i_prof),
                                                        pk_alert_constant.g_no);
        l_filter_by_dcs    sys_config.value%TYPE := pk_sysconfig.get_config('AMB_GRID_NURSE_SHOW_BY_DCS', i_prof);
    BEGIN
        IF i_type_appointments = 'D'
        THEN
            -- Doctor Appointments
            SELECT DISTINCT s.id_group
              BULK COLLECT
              INTO l_group_ids
              FROM schedule_outp sp
              JOIN schedule s
                ON s.id_schedule = sp.id_schedule
              JOIN sch_group sg
                ON sg.id_schedule = s.id_schedule
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              LEFT JOIN epis_info ei
                ON ei.id_schedule = s.id_schedule
               AND ei.id_patient = sg.id_patient
              LEFT JOIN episode e
                ON e.id_episode = ei.id_episode
               AND e.flg_ehr != pk_gridfilter.get_strings('g_flg_ehr')
              LEFT JOIN sch_prof_outp spo
                ON spo.id_schedule_outp = sp.id_schedule_outp
             WHERE sp.dt_target_tstz BETWEEN pk_gridfilter.get_strings('l_dt_min') AND
                   pk_gridfilter.get_strings('l_dt_max')
               AND decode(pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr),
                          pk_gridfilter.get_strings('g_sched_adm_disch'),
                          pk_grid_amb.get_grid_task_count(i_lang,
                                                          i_prof,
                                                          ei.id_episode,
                                                          e.id_visit,
                                                          pk_gridfilter.get_strings('i_prof_cat_type'),
                                                          pk_date_utils.to_char_insttimezone(i_prof,
                                                                                             g_sysdate_tstz,
                                                                                             'YYYYMMDD')),
                          1) = 1
               AND sp.id_software = i_prof.software
                  -- Condition to nurse filter
               AND ((pk_edis_list.get_prof_cat(i_prof) != 'N' AND
                   sp.id_epis_type != pk_gridfilter.get_strings('g_epis_type_nurse', i_lang, i_prof)) OR
                   (sp.id_epis_type = pk_gridfilter.get_strings('g_epis_type_nurse', i_lang, i_prof) AND
                   (l_filter_by_dcs = pk_alert_constant.get_no() OR
                   (l_filter_by_dcs = pk_alert_constant.get_yes() AND
                   s.id_dcs_requested IN
                   (SELECT pdcs.id_dep_clin_serv
                          FROM prof_dep_clin_serv pdcs
                         WHERE pdcs.id_professional = i_prof.id
                           AND pdcs.flg_status = pk_gridfilter.get_strings('g_selected'))))))
               AND s.flg_status NOT IN (pk_schedule.g_sched_status_cache, pk_gridfilter.get_strings('g_sched_canc'))
               AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                   pk_gridfilter.get_strings('g_sched_adm_disch')
               AND s.id_instit_requested = i_prof.institution
               AND (pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                     i_prof,
                                                                                     ei.id_episode,
                                                                                     pk_gridfilter.get_strings('i_prof_cat_type'),
                                                                                     pk_gridfilter.get_strings('l_handoff_type'),
                                                                                     pk_alert_constant.g_yes),
                                                 i_prof.id) != -1 OR
                   (ei.id_professional IS NULL AND spo.id_professional = i_prof.id))
               AND se.flg_is_group = pk_alert_constant.g_yes
               AND s.id_group IS NOT NULL
               AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                   decode(sp.id_epis_type,
                           pk_gridfilter.get_strings('g_epis_type_nurse'),
                           pk_gridfilter.get_strings('g_sched_nurse_disch'),
                           pk_gridfilter.get_strings('g_sched_adm_disch')) OR
                   l_show_nurse_disch = pk_alert_constant.g_yes)
               AND (l_show_med_disch = pk_alert_constant.g_yes OR
                   (l_show_med_disch = pk_alert_constant.g_no AND
                   pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                   pk_gridfilter.get_strings('g_sched_med_disch')));
        
            l_schedule_ids := pk_grid_amb.get_schedule_ids(l_group_ids);
        
        ELSE
            -- All Appointments
        
            SELECT DISTINCT s.id_group
              BULK COLLECT
              INTO l_group_ids
              FROM schedule_outp sp
              JOIN schedule s
                ON s.id_schedule = sp.id_schedule
              JOIN sch_group sg
                ON sg.id_schedule = s.id_schedule
              JOIN sch_event se
                ON s.id_sch_event = se.id_sch_event
              LEFT JOIN epis_info ei
                ON ei.id_schedule = s.id_schedule
              LEFT JOIN episode e
                ON e.id_episode = ei.id_episode
               AND e.flg_ehr != pk_gridfilter.get_strings('g_flg_ehr')
              LEFT JOIN grid_task gt
                ON gt.id_episode = ei.id_episode
             WHERE sp.dt_target_tstz BETWEEN pk_gridfilter.get_tstz('l_dt_min', i_lang, i_prof) AND
                   pk_gridfilter.get_tstz('l_dt_max', i_lang, i_prof)
               AND sp.id_software = i_prof.software
                  -- Condition to nurse filter
               AND ((pk_edis_list.get_prof_cat(i_prof) != 'N' AND
                   sp.id_epis_type != pk_gridfilter.get_strings('g_epis_type_nurse', i_lang, i_prof)) OR
                   (sp.id_epis_type = pk_gridfilter.get_strings('g_epis_type_nurse', i_lang, i_prof) AND
                   (l_filter_by_dcs = pk_alert_constant.get_no() OR
                   (l_filter_by_dcs = pk_alert_constant.get_yes() AND
                   s.id_dcs_requested IN
                   (SELECT pdcs.id_dep_clin_serv
                          FROM prof_dep_clin_serv pdcs
                         WHERE pdcs.id_professional = i_prof.id
                           AND pdcs.flg_status = pk_gridfilter.get_strings('g_selected'))))))
                  
               AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                   pk_gridfilter.get_strings('g_sched_adm_disch')
               AND s.id_instit_requested = i_prof.institution
               AND s.flg_status NOT IN (pk_gridfilter.get_strings('g_sched_canc'), pk_schedule.g_sched_status_cache)
               AND EXISTS (SELECT 0
                      FROM prof_dep_clin_serv pdcs
                     WHERE pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = pk_gridfilter.get_strings('g_selected')
                       AND pdcs.id_dep_clin_serv = ei.id_dep_clin_serv)
               AND 1 = decode(ei.id_episode,
                              NULL,
                              1,
                              (SELECT COUNT(0)
                                 FROM episode epis
                                WHERE epis.flg_status != pk_gridfilter.get_strings('g_epis_canc')
                                  AND epis.id_episode = ei.id_episode))
               AND se.flg_is_group = pk_alert_constant.g_yes
               AND s.id_group IS NOT NULL
               AND (pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                   decode(sp.id_epis_type,
                           pk_gridfilter.get_strings('g_epis_type_nurse'),
                           pk_gridfilter.get_strings('g_sched_nurse_disch'),
                           pk_gridfilter.get_strings('g_sched_adm_disch')) OR
                   l_show_nurse_disch = pk_alert_constant.g_yes)
               AND (l_show_med_disch = pk_alert_constant.g_yes OR
                   (l_show_med_disch = pk_alert_constant.g_no AND
                   pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) !=
                   pk_gridfilter.get_strings('g_sched_med_disch')));
        
            l_schedule_ids := pk_grid_amb.get_schedule_ids(l_group_ids);
        END IF;
    
        RETURN l_schedule_ids;
    
    END;

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
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        --FILTER_BIND
        l_prof_cat                     category.flg_type%TYPE;
        l_hand_off_type                sys_config.value%TYPE;
        g_task_analysis                VARCHAR2(1) := 'A';
        g_task_exam                    VARCHAR2(1) := 'E';
        g_analysis_exam_icon_grid_rank sys_domain.code_domain%TYPE := 'ANALYSIS_EXAM_ICON_GRID_RANK';
        g_pat_status_pend              VARCHAR2(1) := 'A';
    
        g_active           VARCHAR2(1) := 'A';
        l_str_date         VARCHAR2(50);
        l_type_appointment VARCHAR2(2);
        l_prof_cat_type    VARCHAR2(2);
        o_error            t_error_out;
    
        g_sysdate_tstz            TIMESTAMP WITH TIME ZONE;
        l_num_days_back           sys_config.value%TYPE;
        l_num_days_forward        sys_config.value%TYPE;
        l_category                category.flg_type%TYPE;
        g_epis_type               sys_config.value%TYPE;
        l_sch_complaint_origin    sys_config.value%TYPE;
        l_epis_type_nurse         epis_type.id_epis_type%TYPE;
        l_epis_type_nutri         epis_type.id_epis_type%TYPE;
        l_therap_decision_consult translation.code_translation%TYPE;
        l_id_profile_template     profile_template.id_profile_template%TYPE;
        l_id_category             category.id_category%TYPE;
        l_dt                      TIMESTAMP WITH LOCAL TIME ZONE;
        l_date_lesser_limit       TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
        g_error := 'Get context';
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_institution', l_prof.institution);
        pk_context_api.set_parameter('i_software', l_prof.software);
        pk_context_api.set_parameter('l_category', l_category);
    
        g_epis_type := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => l_prof);
        pk_context_api.set_parameter('g_epis_type', g_epis_type);
    
        l_sch_complaint_origin := nvl(pk_sysconfig.get_config('SCH_COMPLAINT_ORIGIN', l_prof), 'C');
        l_epis_type_nurse      := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', l_prof);
    
        l_epis_type_nutri := pk_sysconfig.get_config('ID_EPIS_TYPE_NUTRITIONIST', l_prof);
    
        -- Consultas de decisao terapeutica
        BEGIN
            SELECT pk_translation.get_translation(l_lang, se.code_sch_event_abrv)
              INTO l_therap_decision_consult
              FROM sch_event se
             WHERE se.id_sch_event = 20;
        EXCEPTION
            WHEN OTHERS THEN
                l_therap_decision_consult := NULL;
        END;
    
        IF i_context_keys IS NOT NULL
           AND i_context_keys.count > 0
        THEN
            -- There is data to use as filter
            BEGIN
                g_error    := 'Context definition fail';
                l_str_date := i_context_keys(1);
            
                pk_context_api.set_parameter('i_dt', l_str_date);
            
                l_type_appointment := i_context_keys(2);
                pk_context_api.set_parameter('i_type_appointment', l_type_appointment);
            
                IF i_context_keys.count = 3
                THEN
                    l_prof_cat_type := i_context_keys(3);
                ELSE
                    l_prof_cat_type := NULL;
                END IF;
                pk_context_api.set_parameter('i_prof_cat_type', l_prof_cat_type);
            
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alert_exceptions.process_error(l_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      'ALERT',
                                                      'PK_GRID_AMB',
                                                      'INIT_PARAMS_PATIENTS_GRID',
                                                      o_error);
            END;
        
        END IF;
    
        g_error := 'Case for ' || i_name;
        CASE i_name
            WHEN 'g_flg_ehr' THEN
                o_vc2 := g_flg_ehr;
            
            WHEN 'g_task_harvest' THEN
                o_vc2 := g_task_harvest;
            
            WHEN 'g_cf_pat_gender_abbr' THEN
                o_vc2 := g_cf_pat_gender_abbr;
            
            WHEN 'g_selected' THEN
                o_vc2 := pk_grid_amb.g_selected;
            WHEN 'g_epis_type' THEN
                o_vc2 := g_epis_type;
            WHEN 'g_epis_type_nurse' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE', i_prof => l_prof);
            WHEN 'l_filter_by_dcs' THEN
                o_vc2 := pk_sysconfig.get_config('AMB_GRID_NURSE_SHOW_BY_DCS', l_prof);
            WHEN 'i_prof_cat_type' THEN
                o_vc2 := l_prof_cat;
            WHEN 'l_handoff_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
                o_vc2 := l_hand_off_type;
            WHEN 'flg_nurse_categ' THEN
                o_vc2 := pk_alert_constant.g_cat_type_nurse;
            WHEN 'followed_by_me' THEN
                o_vc2 := pk_alert_constant.get_yes();
            WHEN 'flg_epis_status' THEN
                o_vc2 := pk_alert_constant.g_epis_status_active;
            WHEN 'flg_epis_disch' THEN
                o_vc2 := pk_alert_constant.g_epis_status_inactive; -- Episode flag status 'I', identify administrative discharge
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'l_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'i_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_software' THEN
                o_vc2 := to_char(l_prof.software);
            WHEN 'i_software' THEN
                o_vc2 := to_char(l_prof.software);
            WHEN 'l_prof_id' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'g_prof_dep_status' THEN
                o_vc2 := 'S';
            WHEN 'dish_status' THEN
                o_vc2 := 'A';
            WHEN 'g_active' THEN
                o_vc2 := g_active;
            WHEN 'g_analysis_exam_icon_grid_rank' THEN
                o_vc2 := g_analysis_exam_icon_grid_rank;
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := pk_alert_constant.g_cat_type_doc;
            WHEN 'g_pat_status_pend' THEN
                o_vc2 := g_pat_status_pend;
            WHEN 'g_task_analysis' THEN
                o_vc2 := g_task_analysis;
            WHEN 'g_task_exam' THEN
                o_vc2 := g_task_exam;
            WHEN 'l_hand_off_type' THEN
                o_vc2 := l_hand_off_type;
            WHEN 'l_prof_cat' THEN
                l_prof_cat := pk_edis_list.get_prof_cat(l_prof);
                o_vc2      := l_prof_cat;
            WHEN 'l_dt_min_task' THEN
            
                g_sysdate_tstz     := current_timestamp;
                l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', l_prof);
                l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', l_prof);
            
                IF l_num_days_back <= 0
                THEN
                    l_num_days_back := 10;
                END IF;
                IF l_num_days_forward <= 0
                THEN
                    l_num_days_forward := 10;
                END IF;
            
                o_tstz := pk_date_utils.trunc_insttimezone(l_prof, g_sysdate_tstz - CAST(l_num_days_back AS NUMBER));
            
            WHEN 'l_dt_max_task' THEN
            
                --g_sysdate_tstz     := current_timestamp;
                l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', l_prof);
                l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', l_prof);
            
                IF l_num_days_back <= 0
                THEN
                    l_num_days_back := 10;
                END IF;
                IF l_num_days_forward <= 0
                THEN
                    l_num_days_forward := 10;
                END IF;
            
                --o_tstz := pk_date_utils.trunc_insttimezone(l_prof, g_sysdate_tstz + CAST(l_num_days_forward AS NUMBER));
                o_tstz := pk_date_utils.add_days(i_lang   => l_lang,
                                                 i_prof   => l_prof,
                                                 i_date   => current_timestamp,
                                                 i_amount => to_number(l_num_days_forward));
            
            WHEN 'l_dt_min' THEN
                /* Using the system date instead of the client date */
                --o_tstz := CAST(trunc(to_date(l_str_date, 'yyyymmddHH24miss'), 'DD') AS TIMESTAMP);
                l_dt   := pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                        i_prof      => l_prof,
                                                        i_timestamp => i_context_keys(1),
                                                        i_timezone  => '',
                                                        i_mask      => pk_date_utils.g_dateformat);
                o_tstz := l_dt;
                --dbms_output.put_line(to_char('DT_MIN:' || to_char(l_dt)));
        
            WHEN 'l_dt_max' THEN
                /*
                o_tstz := pk_date_utils.add_to_ltstz(i_timestamp => CAST(trunc(to_date(l_str_date, 'yyyymmddHH24miss'),
                                                                               'DD') AS TIMESTAMP),
                                                     i_amount    => 86399,
                                                     i_unit      => 'second');
                                                     */
                l_dt := pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                      i_prof      => l_prof,
                                                      i_timestamp => i_context_keys(1),
                                                      i_timezone  => '',
                                                      i_mask      => pk_date_utils.g_dateformat);
                l_dt := pk_date_utils.add_days(i_lang => l_lang, i_prof => l_prof, i_date => l_dt, i_amount => 1);
                l_dt := pk_date_utils.add_to_ltstz(i_timestamp => l_dt, i_amount => -1, i_unit => 'SECOND');
            
                o_tstz := l_dt;
                --dbms_output.put_line(to_char('DT_MAX:' || to_char(l_dt)));
            WHEN 'l_category' THEN
                l_category := pk_prof_utils.get_category(l_lang, l_prof);
                o_vc2      := l_category;
            WHEN 'l_sch_complaint_origin' THEN
                o_vc2 := l_sch_complaint_origin;
            WHEN 'l_epis_type_nurse' THEN
                o_vc2 := l_epis_type_nurse;
            WHEN 'l_epis_type_nutri' THEN
                o_vc2 := l_epis_type_nutri;
            WHEN 'l_therap_decision_consult' THEN
                o_vc2 := l_therap_decision_consult;
            WHEN 'l_id_profile_template' THEN
                l_id_profile_template := pk_tools.get_prof_profile_template(l_prof);
                o_vc2                 := to_char(l_id_profile_template);
            WHEN 'l_id_category' THEN
                l_id_category := pk_prof_utils.get_id_category(i_lang => l_lang, i_prof => l_prof);
                o_vc2         := to_char(l_id_category);
            WHEN 'l_date_lesser_limit' THEN
                l_date_lesser_limit := pk_date_utils.trunc_insttimezone(l_prof, current_timestamp, 'DD');
                o_tstz              := l_date_lesser_limit;
            
        END CASE;
    EXCEPTION
        WHEN case_not_found THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_GRID_AMB',
                                              i_function => 'INIT_PARAMS_PATIENTS_GRIDS',
                                              o_error    => o_error);
            RAISE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_GRID_AMB',
                                              i_function => 'INIT_PARAMS_PATIENTS_GRIDS',
                                              o_error    => o_error);
            RAISE;
    END;

    -- **********************************************
    FUNCTION get_prof_dcs(i_prof_id IN NUMBER) RETURN table_number IS
        l_return table_number;
    BEGIN
    
        SELECT pdcs.id_dep_clin_serv
          BULK COLLECT
          INTO l_return
          FROM prof_dep_clin_serv pdcs
         WHERE pdcs.id_professional = i_prof_id
           AND pdcs.flg_status = g_selected;
    
        RETURN l_return;
    
    END get_prof_dcs;

    -- **********************************************
    FUNCTION get_group_ids
    (
        i_prof IN profissional,
        i_dt01 IN schedule_outp.dt_target_tstz%TYPE,
        i_dt09 IN schedule_outp.dt_target_tstz%TYPE
    ) RETURN table_number IS
        l_return           table_number;
        l_id_dcs           table_number;
        l_show_nurse_disch VARCHAR2(1000 CHAR);
        l_show_med_disch   VARCHAR2(1000 CHAR);
        l_epis_type_nurse  VARCHAR2(1000 CHAR);
        l_dt_min           schedule_outp.dt_target_tstz%TYPE;
        l_dt_max           schedule_outp.dt_target_tstz%TYPE;
    BEGIN
    
        l_dt_min := i_dt01;
        l_dt_max := i_dt09;
    
        l_id_dcs           := get_prof_dcs(i_prof_id => i_prof.id);
        l_show_nurse_disch := nvl(pk_sysconfig.get_config('SHOW_NURSE_DISCHARGED_GRID', i_prof), g_no);
        l_show_med_disch   := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID', i_prof), g_yes);
    
        SELECT DISTINCT id_group
          BULK COLLECT
          INTO l_return
          FROM (SELECT s.id_group,
                       pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) g_real_state,
                       CASE
                            WHEN sp.id_epis_type = g_epis_type_nurse THEN
                             g_sched_nurse_disch
                            ELSE
                             g_sched_adm_disch
                        END g_stuff_disch
                
                  FROM schedule_outp sp
                  JOIN schedule s
                    ON s.id_schedule = sp.id_schedule
                  JOIN sch_group sg
                    ON sg.id_schedule = s.id_schedule
                  JOIN sch_event se
                    ON s.id_sch_event = se.id_sch_event
                  LEFT JOIN epis_info ei
                    ON ei.id_schedule = s.id_schedule
                  LEFT JOIN episode e
                    ON e.id_episode = ei.id_episode
                   AND e.flg_ehr != g_flg_ehr
                   AND e.flg_status != g_epis_canc
                  LEFT JOIN grid_task gt
                    ON gt.id_episode = ei.id_episode
                  JOIN (SELECT /*+ OPT_ESTIMATE(TABLE x01 ROWS=1) */
                        column_value id_dep_clin_serv
                         FROM TABLE(l_id_dcs) x01) pdcs
                    ON pdcs.id_dep_clin_serv = ei.id_dep_clin_serv
                 WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                   AND sp.id_software = i_prof.software
                   AND sp.id_epis_type != g_epis_type_nurse
                   AND pk_grid.get_schedule_real_state(sp.flg_state, e.flg_ehr) != g_sched_adm_disch
                   AND s.id_instit_requested = i_prof.institution
                   AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                   AND se.flg_is_group = pk_alert_constant.g_yes
                   AND s.id_group IS NOT NULL) xsql01
         WHERE (g_real_state != g_stuff_disch OR l_show_nurse_disch = g_yes)
           AND (l_show_med_disch = g_yes OR (l_show_med_disch = g_no AND g_real_state != g_sched_med_disch));
    
        RETURN l_return;
    
    END get_group_ids;

    /**
    * Get psychologist appointments.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_dt             date
    * @param i_type           D - Consults for this dietitian
    *                         C - Consults for all dietitian        
    * @param i_prof_cat_type  logged professional category
    * @param o_doc            cursor
    * @param o_flg_show       date browser warning related data
    * @param o_msg_title      date browser warning related data
    * @param o_body_title     date browser warning related data
    * @param o_body_detail    date browser warning related data
    * @param o_error                  error
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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL paramedical_efectiv';
        IF NOT paramedical_efectiv(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_dt            => i_dt,
                                   i_type          => i_type,
                                   i_prof_cat_type => i_prof_cat_type,
                                   o_doc           => o_doc,
                                   o_flg_show      => o_flg_show,
                                   o_msg_title     => o_msg_title,
                                   o_body_title    => o_body_title,
                                   o_body_detail   => o_body_detail,
                                   o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'PSYCHOLOGIST_EFECTIV',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END psychologist_efectiv;

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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL paramedical_efectiv';
        IF NOT paramedical_efectiv(i_lang          => i_lang,
                                   i_prof          => i_prof,
                                   i_dt            => i_dt,
                                   i_type          => i_type,
                                   i_prof_cat_type => i_prof_cat_type,
                                   o_doc           => o_doc,
                                   o_flg_show      => o_flg_show,
                                   o_msg_title     => o_msg_title,
                                   o_body_title    => o_body_title,
                                   o_body_detail   => o_body_detail,
                                   o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'RT_EFECTIV',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_doc);
            RETURN FALSE;
    END rt_efectiv;

BEGIN
    -- Log initialization
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);

    pk_alertlog.log_init(object_name => g_package_name);
    g_sysdate_tstz := current_timestamp;

    -- Initialization
    g_owner   := 'ALERT';
    g_package := 'pk_outp_grid';

    g_software_intern_name     := 'OUTP';
    g_epis_flg_status_active   := 'A';
    g_epis_flg_status_inactive := 'I';
    g_epis_flg_status_temp     := 'T';
    g_epis_flg_status_canceled := 'C';
    g_active                   := 'A';

    -- Log initialization.
    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(g_package);

END pk_grid_amb;
/
