/*-- Last Change Revision: $Rev: 2027173 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:22 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_grid IS


    g_domain_sch_presence CONSTANT sys_domain.code_domain%TYPE := 'SCH_GROUP.FLG_CONTACT_TYPE';

    /**********************************************************************************************
    * Returns 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_dep_clin_serv       id_dep_clin_serv
    *
    * @return                         'Y' - pre_nurse appointment
    *                                 'N' - if not
    * @author                         Rita Lopes
    * @version                        1.0 
    * @since                          2009/02/04
    * @alteration                     
    **********************************************************************************************/
    FUNCTION get_pre_nurse_appointment
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_flg_status       IN schedule_outp.flg_state%TYPE,
        i_epis_type        IN epis_type.id_epis_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_flg_state  schedule_outp.flg_state%TYPE;
        l_has_1nurse VARCHAR2(1 CHAR);
    BEGIN
        IF i_flg_ehr = pk_visit.g_flg_ehr_s
        THEN
            RETURN i_flg_status;
        ELSE
            g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
            l_has_1nurse      := check_has_nurse_vs_status(i_lang, i_prof);
            IF l_has_1nurse = pk_alert_constant.g_yes
               AND g_epis_type_nurse = i_epis_type
            THEN
                l_has_1nurse := pk_alert_constant.g_no;
            END IF;
        
            SELECT decode(i_flg_status,
                          'E',
                          decode(dcs.flg_nurse_pre,
                                 g_flg_nurse_pre_y,
                                 decode(l_has_1nurse, pk_alert_constant.g_yes, g_sched_wait_1nurse, g_sched_nurse_prev),
                                 i_flg_status),
                          i_flg_status)
              INTO l_flg_state
              FROM dep_clin_serv dcs
             WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
        
            RETURN l_flg_state;
        END IF;
    END;

    FUNCTION get_daily_schedule
    (
        i_lang      IN language.id_language%TYPE,
        i_dt        IN VARCHAR2,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_sched     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de agendamentos do dia indicado (Grelha do administrativo)
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                       I_DT - data
                                 I_INSTIT - ID da instituição. se ñ for preenchido,
                                            considera-se o valor em SYS_CONFIG (opcional)
                                 I_EPIS_TYPE - Tipo de episódio (CE, URG, ...)
                     I_PROF - prof q acede
                  SAIDA:   O_SCHED - array de agendamentos
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/04/07
          ALTERAÇÃO: CRS 2006/07/20 Excluir episódios cancelados
               ASM 2007/01/05 Na coluna de estado, mostrar o tempo de espera para alta administrativa
        
          NOTAS: Nesta grelha visualizam-se os agendamentos do dia :
                 - não efectivados
               - efectivados mas ainda ñ atendidos clinicamente (médico ou enfª)
               - atendidos clinicamente c/ alta médica para internamento, mas s/ alta administrativa
        *********************************************************************************/
        l_dt_begin                TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end                  TIMESTAMP WITH LOCAL TIME ZONE;
        l_reasongrid              VARCHAR2(1);
        l_therap_decision_consult translation.code_translation%TYPE;
        l_no_present_patient      sys_message.desc_message%TYPE;
        l_show_med_disch          sys_config.value%TYPE;
        l_adm_show_reason         sys_config.value%TYPE;
        l_handoff_type            sys_config.value%TYPE;
        l_group_ids_1             table_number := table_number();
        l_schedule_ids_1          table_number := table_number();
        l_group_ids_2             table_number := table_number();
        l_schedule_ids_2          table_number := table_number();
        l_sch_t640                sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SCH_T640');
        l_can_cancel              VARCHAR2(1 CHAR);
    BEGIN
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz := current_timestamp;
    
        -- JS, 2007-09-11 - Timezone
        -- g_sysdate_char := pk_date_utils.date_send(i_lang, SYSDATE, i_prof);
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof,
                                                       nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                           g_sysdate_tstz));
        l_dt_end   := pk_date_utils.add_days_to_tstz(l_dt_begin, 1);
    
        l_reasongrid      := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID', i_prof);
        l_show_med_disch  := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID', i_prof), g_yes);
        l_adm_show_reason := nvl(pk_sysconfig.get_config('REGISTRAR_SHOW_REASON_FOR_VISIT', i_prof), g_yes);
    
        SELECT pk_translation.get_translation(i_lang, se.code_sch_event_abrv)
          INTO l_therap_decision_consult
          FROM sch_event se
         WHERE se.id_sch_event = g_sch_event_therap_decision;
    
        l_no_present_patient := pk_message.get_message(i_lang, 'THERAPEUTIC_DECISION_T017');
    
        l_can_cancel := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_intern_name => 'CANCEL_EPISODE');
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        SELECT DISTINCT s.id_group
          BULK COLLECT
          INTO l_group_ids_1
          FROM schedule_outp sp
          JOIN schedule s
            ON s.id_schedule = sp.id_schedule
          JOIN sch_group sg
            ON sg.id_schedule = sp.id_schedule
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
          LEFT JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
          JOIN prof_dep_clin_serv pdcs
            ON pdcs.id_dep_clin_serv = ei.id_dep_clin_serv
           AND pdcs.id_professional = i_prof.id
           AND pdcs.flg_status = g_selected
          LEFT JOIN episode epis
            ON epis.id_episode = ei.id_episode
           AND epis.id_patient = sg.id_patient
         WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
           AND sp.flg_state NOT IN (g_sched_med_disch, g_sched_adm_disch)
           AND sp.id_software IN (i_prof.software, g_nutri_software, g_psycho_software, g_rehab_software)
           AND sp.id_epis_type NOT IN
               (g_flg_epis_type_nurse_care, g_flg_epis_type_nurse_outp, g_flg_epis_type_nurse_pp, g_epis_type_rehab)
           AND nvl(ei.flg_sch_status, 'A') != g_sched_canc
           AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
           AND s.id_instit_requested = i_prof.institution
           AND (epis.id_episode IS NULL OR epis.flg_status != g_epis_canc)
           AND (epis.id_episode IS NULL OR epis.flg_ehr != g_flg_ehr)
           AND (nvl(ei.id_schedule, 0) = 0 OR
               (epis.dt_end_tstz IS NULL AND ei.dt_first_obs_tstz IS NULL AND ei.dt_first_nurse_obs_tstz IS NULL))
           AND se.flg_is_group = pk_alert_constant.g_yes
           AND s.id_group IS NOT NULL;
    
        SELECT DISTINCT s.id_group
          BULK COLLECT
          INTO l_group_ids_2
          FROM schedule s
          JOIN schedule_outp sp
            ON s.id_schedule = sp.id_schedule
          JOIN sch_group sg
            ON sg.id_schedule = sp.id_schedule
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
          JOIN epis_info ei
            ON ei.id_schedule = sp.id_schedule
           AND ei.flg_sch_status != g_sched_canc
           AND ei.id_instit_requested = i_prof.institution
          JOIN episode epis
            ON epis.id_episode = ei.id_episode
           AND epis.flg_status != g_epis_canc
           AND epis.flg_ehr != g_flg_ehr
           AND epis.id_patient = sg.id_patient
          JOIN discharge d
            ON d.id_episode = ei.id_episode
           AND d.flg_status NOT IN (pk_discharge_core.g_disch_status_cancel, pk_discharge_core.g_disch_status_reopen)
              --  AND pk_discharge_core.check_admin_discharge(i_lang, i_prof, NULL, d.flg_status_adm) = pk_alert_constant.g_no
              --  AND DECODE(NVL(d.flg_status_adm,PK_ALERT_CONSTANT.G_NO),pk_alert_constant.g_active,PK_ALERT_CONSTANT.G_YES,PK_ALERT_CONSTANT.G_NO) = pk_alert_constant.g_no
           AND nvl(d.flg_status_adm, pk_alert_constant.g_no) <> pk_alert_constant.g_active
          JOIN disch_reas_dest drt
            ON drt.id_disch_reas_dest = d.id_disch_reas_dest
          JOIN prof_dep_clin_serv pdcs
            ON pdcs.id_dep_clin_serv = ei.id_dcs_requested
           AND pdcs.id_professional = i_prof.id
           AND pdcs.flg_status = g_selected
         WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
           AND sp.id_software IN (i_prof.software, g_nutri_software, g_psycho_software, g_rehab_software)
           AND sp.id_epis_type NOT IN
               (g_flg_epis_type_nurse_care, g_flg_epis_type_nurse_outp, g_flg_epis_type_nurse_pp, g_epis_type_rehab)
           AND (l_show_med_disch = g_yes OR
               (l_show_med_disch = g_no AND get_schedule_real_state(sp.flg_state, epis.flg_ehr) != g_sched_med_disch))
           AND s.flg_status != g_sched_canc
           AND se.flg_is_group = pk_alert_constant.g_yes
           AND s.id_group IS NOT NULL;
    
        l_group_ids_1 := l_group_ids_1 MULTISET except l_group_ids_2;
    
        l_schedule_ids_1 := pk_grid_amb.get_schedule_ids(l_group_ids_1);
        l_schedule_ids_2 := pk_grid_amb.get_schedule_ids(l_group_ids_2);
    
        g_error := 'GET CURSOR ';
        OPEN o_sched FOR
            SELECT t.id_schedule,
                   t.id_patient,
                   t.id_episode,
                   t.dt_efectiv,
                   t.dt_efectiv_compl,
                   t.name,
                   t.name_to_sort,
                   t.pat_ndo,
                   t.pat_nd_icon,
                   t.gender,
                   t.pat_age,
                   t.cons_type,
                   t.dt_target,
                   t.dt_schedule_begin,
                   t.nick_name,
                   t.num_clin_record,
                   t.id_pat_identifier,
                   t.id_clin_record,
                   t.flg_sched,
                   t.dt_order,
                   t.img_sched,
                   t.photo,
                   t.dt_server,
                   t.internment,
                   t.img_state,
                   t.flg_state,
                   t.can_canc,
                   t.visit_reason,
                   t.patient_presence,
                   t.resp_icon,
                   t.flg_contact_type,
                   CASE
                        WHEN t.flg_group_header = pk_alert_constant.g_yes THEN
                         pk_grid_amb.get_group_presence_icon(i_lang, i_prof, t.id_group, pk_alert_constant.g_no)
                        ELSE
                         pk_sysdomain.get_img(i_lang, g_domain_sch_presence, t.flg_contact_type)
                    END icon_contact_type,
                   t.flg_contact,
                   t.id_group,
                   t.flg_group_header,
                   t.extend_icon,
                   t.flg_button_ok
              FROM (SELECT s.id_schedule,
                           sg.id_patient,
                           epis.id_episode,
                           CASE
                                WHEN ei.id_episode IS NOT NULL THEN
                                 decode(pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                        g_sched_scheduled,
                                        '',
                                        pk_date_utils.date_char_hour_tsz(i_lang,
                                                                         epis.dt_begin_tstz,
                                                                         i_prof.institution,
                                                                         i_prof.software))
                                ELSE
                                 NULL
                            END dt_efectiv,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                           decode(i.flg_type,
                                  g_instit_c,
                                  g_sch_subs,
                                  g_instit_h,
                                  nvl(sp.flg_type,
                                      pk_episode.get_first_subseq(i_lang,
                                                                  pat.id_patient,
                                                                  cs.id_clinical_service,
                                                                  ei.id_instit_requested,
                                                                  sp.id_epis_type))) flg_type,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           pk_date_utils.date_char_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_schedule_begin,
                           nvl(p1.nick_name, p.nick_name) nick_name,
                           (SELECT cr.num_clin_record
                              FROM clin_record cr
                             WHERE cr.id_patient = sg.id_patient
                               AND cr.id_institution = i_prof.institution
                               AND rownum < 2) num_clin_record,
                           (SELECT id_pat_identifier
                              FROM pat_identifier pi
                             WHERE pi.id_institution = i_prof.institution
                               AND pi.id_patient = sg.id_patient
                               AND rownum < 2) id_pat_identifier,
                           (SELECT id_clin_record
                              FROM pat_identifier pi
                             WHERE pi.id_institution = i_prof.institution
                               AND pi.id_patient = sg.id_patient
                               AND rownum < 2) id_clin_record,
                           sp.flg_sched,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           g_sysdate_char dt_server,
                           '' internment,
                           '0|' ||
                           --
                            CASE
                                WHEN pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr) IN ('A', 'B') THEN
                                 'I|||' ||
                                 pk_sysdomain.get_img(i_lang,
                                                      'SCHEDULE_OUTP.FLG_STATE',
                                                      pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr))
                                WHEN pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr) IN ('E', 'G') THEN
                                 'D|' || pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) || '||' ||
                                 pk_sysdomain.get_img(i_lang,
                                                      'SCHEDULE_OUTP.FLG_STATE',
                                                      pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr))
                                ELSE
                                 'I|||' ||
                                 pk_sysdomain.get_img(i_lang,
                                                      'SCHEDULE_OUTP.FLG_STATE',
                                                      pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr))
                            END
                           --
                            || '|||||' || g_sysdate_char || '|' img_state,
                           pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr) flg_state,
                           decode(l_can_cancel,
                                  pk_alert_constant.g_yes,
                                  decode(pk_sysconfig.get_config('FLG_CANCEL_SCHEDULE', i_prof),
                                         'Y',
                                         decode(epis.flg_ehr,
                                                pk_ehr_access.g_flg_ehr_normal,
                                                pk_alert_constant.g_no,
                                                pk_alert_constant.g_yes),
                                         'N'),
                                  pk_alert_constant.g_no) can_canc,
                           decode(s.id_sch_event,
                                  g_sch_event_therap_decision,
                                  l_therap_decision_consult,
                                  decode(l_reasongrid,
                                         g_no,
                                         NULL,
                                         decode(l_adm_show_reason,
                                                g_yes,
                                                pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                            i_prof,
                                                                                                                            ei.id_episode,
                                                                                                                            sp.id_schedule),
                                                                                 4000)))) visit_reason,
                           decode(s.flg_present, 'N', l_no_present_patient, NULL) patient_presence,
                           decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, epis.id_episode) designated_provider,
                           sg.flg_contact_type,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_handoff_type) resp_icon,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           0 id_group,
                           pk_alert_constant.g_no flg_group_header,
                           NULL extend_icon,
                           decode(s.flg_status, g_sched_canc, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_button_ok
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      LEFT JOIN professional p
                        ON p.id_professional = ps.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                      JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                      JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                       AND epis.id_patient = sg.id_patient
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = s.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      LEFT JOIN professional p1
                        ON p1.id_professional = ei.id_professional
                      JOIN institution i
                        ON s.id_instit_requested = i.id_institution
                     WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                       AND pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr) NOT IN
                           (g_sched_med_disch, g_sched_adm_disch)
                       AND sp.id_software IN (i_prof.software, g_nutri_software, g_psycho_software, g_rehab_software)
                       AND sp.id_epis_type NOT IN (g_flg_epis_type_nurse_care,
                                                   g_flg_epis_type_nurse_outp,
                                                   g_flg_epis_type_nurse_pp,
                                                   g_epis_type_rehab)
                       AND nvl(ei.flg_sch_status, 'A') != g_sched_canc
                       AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                       AND s.id_instit_requested = i_prof.institution
                       AND (epis.id_episode IS NULL OR epis.flg_status != g_epis_canc)
                       AND (epis.id_episode IS NULL OR epis.flg_ehr != g_flg_ehr)
                       AND (nvl(ei.id_schedule, 0) = 0 OR
                           (epis.dt_end_tstz IS NULL AND
                           ((ei.dt_first_obs_tstz IS NULL AND ei.dt_first_nurse_obs_tstz IS NULL) OR
                           (pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr) = g_sched_scheduled))))
                       AND se.flg_is_group = pk_alert_constant.g_no
                    --group elements
                    UNION ALL
                    SELECT s.id_schedule,
                           sg.id_patient,
                           epis.id_episode,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        epis.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                           decode(i.flg_type,
                                  g_instit_c,
                                  g_sch_subs,
                                  g_instit_h,
                                  nvl(sp.flg_type,
                                      pk_episode.get_first_subseq(i_lang,
                                                                  pat.id_patient,
                                                                  cs.id_clinical_service,
                                                                  ei.id_instit_requested,
                                                                  sp.id_epis_type))) flg_type,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           pk_date_utils.date_char_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_schedule_begin,
                           nvl(p1.nick_name, p.nick_name) nick_name,
                           (SELECT cr.num_clin_record
                              FROM clin_record cr
                             WHERE cr.id_patient = sg.id_patient
                               AND cr.id_institution = i_prof.institution
                               AND rownum < 2) num_clin_record,
                           (SELECT id_pat_identifier
                              FROM pat_identifier pi
                             WHERE pi.id_institution = i_prof.institution
                               AND pi.id_patient = sg.id_patient
                               AND rownum < 2) id_pat_identifier,
                           (SELECT id_clin_record
                              FROM pat_identifier pi
                             WHERE pi.id_institution = i_prof.institution
                               AND pi.id_patient = sg.id_patient
                               AND rownum < 2) id_clin_record,
                           sp.flg_sched,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           g_sysdate_char dt_server,
                           '' internment,
                           '0|' ||
                           --
                            CASE
                                WHEN s.flg_status = g_sched_canc THEN
                                 'I|||' || pk_sysdomain.get_img(i_lang, 'SCHEDULE.FLG_STATUS', s.flg_status)
                                WHEN sp.flg_state IN ('A', 'B') THEN
                                 'I|||' || pk_sysdomain.get_img(i_lang, 'SCHEDULE_OUTP.FLG_STATE', sp.flg_state)
                                WHEN sp.flg_state IN ('E', 'G') THEN
                                 'D|' || pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) || '||' ||
                                 pk_sysdomain.get_img(i_lang, 'SCHEDULE_OUTP.FLG_STATE', sp.flg_state)
                                ELSE
                                 'I|||' || pk_sysdomain.get_img(i_lang, 'SCHEDULE_OUTP.FLG_STATE', sp.flg_state)
                            END
                           --
                            || '|||||' || g_sysdate_char || '|' img_state,
                           decode(s.flg_status, g_sched_canc, g_sched_canc, sp.flg_state) flg_state,
                           decode(l_can_cancel,
                                  pk_alert_constant.g_yes,
                                  decode(pk_sysconfig.get_config('FLG_CANCEL_SCHEDULE', i_prof),
                                         'Y',
                                         decode(epis.id_episode, NULL, 'Y', 'N'),
                                         'N'),
                                  pk_alert_constant.g_no) can_canc,
                           decode(s.id_sch_event,
                                  g_sch_event_therap_decision,
                                  l_therap_decision_consult,
                                  decode(l_reasongrid,
                                         g_no,
                                         NULL,
                                         decode(l_adm_show_reason,
                                                g_yes,
                                                pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                            i_prof,
                                                                                                                            ei.id_episode,
                                                                                                                            sp.id_schedule),
                                                                                 4000)))) visit_reason,
                           decode(s.flg_present, 'N', l_no_present_patient, NULL) patient_presence,
                           NULL desc_room,
                           pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, epis.id_episode) designated_provider,
                           sg.flg_contact_type,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_handoff_type) resp_icon,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           s.id_group,
                           pk_alert_constant.g_no flg_group_header,
                           'ExtendIcon' extend_icon,
                           decode(s.flg_status, g_sched_canc, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_button_ok
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      LEFT JOIN professional p
                        ON p.id_professional = ps.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                      JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                      JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                       AND epis.id_patient = sg.id_patient
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = s.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      LEFT JOIN professional p1
                        ON p1.id_professional = ei.id_professional
                      JOIN institution i
                        ON s.id_instit_requested = i.id_institution
                     WHERE s.id_group IN (SELECT /*+ opt_estimate (table d rows=1) */
                                           d.column_value
                                            FROM TABLE(l_group_ids_1) d)
                    --group header
                    UNION ALL
                    SELECT NULL id_schedule,
                           NULL id_patient,
                           NULL id_episode,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            epis.dt_begin_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) dt_efectiv,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                           decode(i.flg_type,
                                  g_instit_c,
                                  g_sch_subs,
                                  g_instit_h,
                                  nvl(sp.flg_type,
                                      pk_episode.get_first_subseq(i_lang,
                                                                  pat.id_patient,
                                                                  cs.id_clinical_service,
                                                                  ei.id_instit_requested,
                                                                  sp.id_epis_type))) flg_type,
                           l_sch_t640 name,
                           l_sch_t640 name_to_sort,
                           NULL pat_ndo,
                           NULL pat_nd_icon,
                           NULL pat_nd_icon,
                           NULL pat_age,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           pk_date_utils.date_char_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_schedule_begin,
                           nvl(p1.nick_name, p.nick_name) nick_name,
                           NULL num_clin_record,
                           (SELECT id_pat_identifier
                              FROM pat_identifier pi
                             WHERE pi.id_institution = i_prof.institution
                               AND pi.id_patient = sg.id_patient
                               AND rownum < 2) id_pat_identifier,
                           (SELECT id_clin_record
                              FROM pat_identifier pi
                             WHERE pi.id_institution = i_prof.institution
                               AND pi.id_patient = sg.id_patient
                               AND rownum < 2) id_clin_record,
                           sp.flg_sched,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                           NULL photo,
                           g_sysdate_char dt_server,
                           '' internment,
                           '0|I|||' ||
                            pk_grid_amb.get_group_state_icon(i_lang, i_prof, s.id_group, pk_alert_constant.g_no)
                           --
                            || '|||||' || g_sysdate_char || '|' img_state,
                           'A' flg_state,
                           decode(pk_sysconfig.get_config('FLG_CANCEL_SCHEDULE', i_prof),
                                  'Y',
                                  decode(epis.id_episode, NULL, 'Y', 'N'),
                                  'N') can_canc,
                           decode(s.id_sch_event,
                                  g_sch_event_therap_decision,
                                  l_therap_decision_consult,
                                  decode(l_reasongrid,
                                         g_no,
                                         NULL,
                                         decode(l_adm_show_reason,
                                                g_yes,
                                                pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                            i_prof,
                                                                                                                            ei.id_episode,
                                                                                                                            sp.id_schedule),
                                                                                 4000)))) visit_reason,
                           decode(s.flg_present, 'N', l_no_present_patient, NULL) patient_presence,
                           decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, epis.id_episode) designated_provider,
                           NULL flg_contact_type,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_handoff_type) resp_icon,
                           NULL flg_contact,
                           s.id_group,
                           pk_alert_constant.g_yes flg_group_header,
                           NULL extend_icon,
                           pk_alert_constant.g_no flg_button_ok
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      LEFT JOIN professional p
                        ON p.id_professional = ps.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                      JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                      JOIN clinical_service cs
                        ON cs.id_clinical_service = dcs.id_clinical_service
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                       AND epis.id_patient = sg.id_patient
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = s.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      LEFT JOIN professional p1
                        ON p1.id_professional = ei.id_professional
                      JOIN institution i
                        ON s.id_instit_requested = i.id_institution
                     WHERE s.id_schedule IN (SELECT /*+ opt_estimate (table d rows=1) */
                                              d.column_value
                                               FROM TABLE(l_schedule_ids_1) d)
                    UNION ALL
                    SELECT ei.id_schedule,
                           sg.id_patient,
                           epis.id_episode,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        epis.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                           decode(i.flg_type,
                                  g_instit_c,
                                  g_sch_subs,
                                  g_instit_h,
                                  nvl(sp.flg_type,
                                      pk_episode.get_first_subseq(i_lang,
                                                                  pat.id_patient,
                                                                  cs.id_clinical_service,
                                                                  ei.id_instit_requested,
                                                                  sp.id_epis_type))) flg_type,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           pk_date_utils.date_char_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_schedule_begin,
                           nvl(p1.nick_name, p.nick_name) nick_name,
                           (SELECT cr.num_clin_record
                              FROM clin_record cr
                             WHERE cr.id_patient = sg.id_patient
                               AND cr.id_institution = i_prof.institution
                               AND rownum < 2) num_clin_record,
                           (SELECT id_pat_identifier
                              FROM pat_identifier pi
                             WHERE pi.id_institution = i_prof.institution
                               AND pi.id_patient = sg.id_patient
                               AND rownum < 2) id_pat_identifier,
                           (SELECT id_clin_record
                              FROM pat_identifier pi
                             WHERE pi.id_institution = i_prof.institution
                               AND pi.id_patient = sg.id_patient
                               AND rownum < 2) id_clin_record,
                           sp.flg_sched,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           g_sysdate_char dt_server,
                           CASE
                               WHEN drt.id_discharge_reason = pk_sysconfig.get_config('ID_DISCHARGE_INTERNMENT', i_prof) THEN
                                pk_message.get_message(i_lang, 'GRID_ADMIN_M001') || ' ' ||
                                pk_translation.get_translation(i_lang, cs1.code_clinical_service)
                               WHEN drt.id_discharge_reason = pk_sysconfig.get_config('ID_DISCHARGE_CE', i_prof) THEN
                                pk_message.get_message(i_lang, 'GRID_ADMIN_M002') || ' ' ||
                                pk_translation.get_translation(i_lang, cs1.code_clinical_service)
                               WHEN drt.id_discharge_reason IN
                                    (pk_sysconfig.get_config('ID_DISCHARGE_INSTIT', i_prof),
                                     pk_sysconfig.get_config('ID_DISCHARGE_CS', i_prof)) THEN
                                pk_translation.get_translation(i_lang, i.code_institution)
                               ELSE
                                pk_translation.get_translation(i_lang, drn.code_discharge_reason)
                           END internment,
                           '0|' || CASE
                               WHEN sp.flg_state IN ('D', 'U') THEN
                                pk_date_utils.to_char_insttimezone(i_prof, d.dt_med_tstz, 'YYYYMMDDHH24MISS') || '|I|X|' ||
                                pk_sysdomain.get_img(i_lang, g_schdl_outp_state_domain, sp.flg_state)
                               ELSE
                                NULL
                           END img_state,
                           sp.flg_state flg_state,
                           decode(pk_sysconfig.get_config('FLG_CANCEL_SCHEDULE', i_prof),
                                  'Y',
                                  decode(epis.id_episode, NULL, 'Y', 'N'),
                                  'N') can_canc,
                           decode(l_reasongrid,
                                  g_no,
                                  NULL,
                                  decode(l_adm_show_reason,
                                         g_yes,
                                         pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                     i_prof,
                                                                                                                     ei.id_episode,
                                                                                                                     sp.id_schedule),
                                                                          4000))) visit_reason,
                           decode(s.flg_present, 'N', l_no_present_patient, NULL) patient_presence,
                           decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, epis.id_episode) designated_provider,
                           sg.flg_contact_type,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_handoff_type) resp_icon,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           0 id_group,
                           pk_alert_constant.g_no flg_group_header,
                           NULL extend_icon,
                           decode(s.flg_status, g_sched_canc, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_button_ok
                      FROM schedule s
                      JOIN schedule_outp sp
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      JOIN epis_info ei
                        ON ei.id_schedule = sp.id_schedule
                       AND ei.flg_sch_status != g_sched_canc
                       AND ei.id_instit_requested = i_prof.institution
                      JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                       AND epis.flg_status != g_epis_canc
                       AND epis.flg_ehr != g_flg_ehr
                       AND epis.id_patient = sg.id_patient
                      JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      JOIN discharge d
                        ON d.id_episode = ei.id_episode
                       AND d.flg_status NOT IN
                           (pk_discharge_core.g_disch_status_cancel, pk_discharge_core.g_disch_status_reopen)
                       AND nvl(d.flg_status_adm, pk_alert_constant.g_no) <> pk_alert_constant.g_active
                      JOIN disch_reas_dest drt
                        ON drt.id_disch_reas_dest = d.id_disch_reas_dest
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = ei.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      LEFT JOIN professional p
                        ON p.id_professional = ei.sch_prof_outp_id_prof
                      LEFT JOIN dep_clin_serv dcs1
                        ON dcs1.id_dep_clin_serv = drt.id_dep_clin_serv
                      LEFT JOIN discharge_reason drn
                        ON drn.id_discharge_reason = drt.id_discharge_reason
                      LEFT JOIN clinical_service cs1
                        ON cs1.id_clinical_service = dcs1.id_clinical_service
                      LEFT JOIN institution i
                        ON i.id_institution = drt.id_institution
                      LEFT JOIN professional p1
                        ON p1.id_professional = ei.id_professional
                     WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                       AND sp.id_software IN (i_prof.software, g_nutri_software, g_psycho_software, g_rehab_software)
                       AND sp.id_epis_type NOT IN (g_flg_epis_type_nurse_care,
                                                   g_flg_epis_type_nurse_outp,
                                                   g_flg_epis_type_nurse_pp,
                                                   g_epis_type_rehab)
                       AND (l_show_med_disch = g_yes OR
                           (l_show_med_disch = g_no AND
                           get_schedule_real_state(sp.flg_state, epis.flg_ehr) != g_sched_med_disch))
                       AND s.flg_status != g_sched_canc
                       AND se.flg_is_group = pk_alert_constant.g_no
                    --group elements
                    UNION ALL
                    SELECT /*+ use_nl(pdcs ei) */
                     ei.id_schedule,
                     sg.id_patient,
                     epis.id_episode,
                     CASE
                         WHEN ei.id_episode IS NOT NULL THEN
                          decode(pk_grid.get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                 g_sched_scheduled,
                                 '',
                                 pk_date_utils.date_char_hour_tsz(i_lang,
                                                                  epis.dt_begin_tstz,
                                                                  i_prof.institution,
                                                                  i_prof.software))
                         ELSE
                          NULL
                     END dt_efectiv,
                     pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                     decode(i.flg_type,
                            g_instit_c,
                            g_sch_subs,
                            g_instit_h,
                            nvl(sp.flg_type,
                                pk_episode.get_first_subseq(i_lang,
                                                            pat.id_patient,
                                                            cs.id_clinical_service,
                                                            ei.id_instit_requested,
                                                            sp.id_epis_type))) flg_type,
                     pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                     pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                     pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                     pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                     pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender,
                     pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                     pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                     pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                     pk_date_utils.date_char_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_schedule_begin,
                     nvl(p1.nick_name, p.nick_name) nick_name,
                     (SELECT cr.num_clin_record
                        FROM clin_record cr
                       WHERE cr.id_patient = sg.id_patient
                         AND cr.id_institution = i_prof.institution
                         AND rownum < 2) num_clin_record,
                     (SELECT id_pat_identifier
                        FROM pat_identifier pi
                       WHERE pi.id_institution = i_prof.institution
                         AND pi.id_patient = sg.id_patient
                         AND rownum < 2) id_pat_identifier,
                     (SELECT id_clin_record
                        FROM pat_identifier pi
                       WHERE pi.id_institution = i_prof.institution
                         AND pi.id_patient = sg.id_patient
                         AND rownum < 2) id_clin_record,
                     sp.flg_sched,
                     pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                     pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                     pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                     g_sysdate_char dt_server,
                     CASE
                         WHEN drt.id_discharge_reason = pk_sysconfig.get_config('ID_DISCHARGE_INTERNMENT', i_prof) THEN
                          pk_message.get_message(i_lang, 'GRID_ADMIN_M001') || ' ' ||
                          pk_translation.get_translation(i_lang, cs1.code_clinical_service)
                         WHEN drt.id_discharge_reason = pk_sysconfig.get_config('ID_DISCHARGE_CE', i_prof) THEN
                          pk_message.get_message(i_lang, 'GRID_ADMIN_M002') || ' ' ||
                          pk_translation.get_translation(i_lang, cs1.code_clinical_service)
                         WHEN drt.id_discharge_reason IN
                              (pk_sysconfig.get_config('ID_DISCHARGE_INSTIT', i_prof),
                               pk_sysconfig.get_config('ID_DISCHARGE_CS', i_prof)) THEN
                          pk_translation.get_translation(i_lang, i.code_institution)
                         ELSE
                          pk_translation.get_translation(i_lang, drn.code_discharge_reason)
                     END internment,
                     '0|' || CASE
                         WHEN s.flg_status = g_sched_canc THEN
                          pk_sysdomain.get_img(i_lang, 'SCHEDULE.FLG_STATUS', s.flg_status)
                         ELSE
                          pk_date_utils.to_char_insttimezone(i_prof, d.dt_med_tstz, 'YYYYMMDDHH24MISS') || '|I|X|' ||
                          pk_sysdomain.get_img(i_lang, g_schdl_outp_state_domain, sp.flg_state)
                     END img_state,
                     decode(s.flg_status, g_sched_canc, g_sched_canc, sp.flg_state) flg_state,
                     decode(pk_sysconfig.get_config('FLG_CANCEL_SCHEDULE', i_prof),
                            'Y',
                            decode(epis.id_episode, NULL, 'Y', 'N'),
                            'N') can_canc,
                     decode(l_reasongrid,
                            g_no,
                            NULL,
                            decode(l_adm_show_reason,
                                   g_yes,
                                   pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                               i_prof,
                                                                                                               ei.id_episode,
                                                                                                               sp.id_schedule),
                                                                    4000))) visit_reason,
                     decode(s.flg_present, 'N', l_no_present_patient, NULL) patient_presence,
                     NULL desc_room,
                     pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, epis.id_episode) designated_provider,
                     sg.flg_contact_type,
                     pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_handoff_type) resp_icon,
                     pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                     s.id_group,
                     pk_alert_constant.g_no flg_group_header,
                     'ExtendIcon' extend_icon,
                     decode(s.flg_status, g_sched_canc, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_button_ok
                      FROM schedule s
                      JOIN schedule_outp sp
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = sp.id_schedule
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                      JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      LEFT JOIN discharge d
                        ON d.id_episode = ei.id_episode
                       AND d.flg_status NOT IN
                           (pk_discharge_core.g_disch_status_cancel, pk_discharge_core.g_disch_status_reopen)
                       AND nvl(d.flg_status_adm, pk_alert_constant.g_no) <> pk_alert_constant.g_active
                      LEFT JOIN disch_reas_dest drt
                        ON drt.id_disch_reas_dest = d.id_disch_reas_dest
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = ei.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      LEFT JOIN professional p
                        ON p.id_professional = ei.sch_prof_outp_id_prof
                      LEFT JOIN dep_clin_serv dcs1
                        ON dcs1.id_dep_clin_serv = drt.id_dep_clin_serv
                      LEFT JOIN discharge_reason drn
                        ON drn.id_discharge_reason = drt.id_discharge_reason
                      LEFT JOIN clinical_service cs1
                        ON cs1.id_clinical_service = dcs1.id_clinical_service
                      LEFT JOIN institution i
                        ON i.id_institution = drt.id_institution
                      LEFT JOIN professional p1
                        ON p1.id_professional = ei.id_professional
                     WHERE s.id_group IN (SELECT /*+ opt_estimate (table d rows=1) */
                                           d.column_value
                                            FROM TABLE(l_group_ids_2) d)
                    --group header
                    UNION ALL
                    SELECT NULL id_schedule,
                           NULL id_patient,
                           NULL id_episode,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            epis.dt_begin_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) dt_efectiv,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                           decode(i.flg_type,
                                  g_instit_c,
                                  g_sch_subs,
                                  g_instit_h,
                                  nvl(sp.flg_type,
                                      pk_episode.get_first_subseq(i_lang,
                                                                  pat.id_patient,
                                                                  cs.id_clinical_service,
                                                                  ei.id_instit_requested,
                                                                  sp.id_epis_type))) flg_type,
                           l_sch_t640 name,
                           l_sch_t640 name_to_sort,
                           NULL pat_ndo,
                           NULL pat_nd_icon,
                           NULL gender,
                           NULL pat_age,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           pk_date_utils.date_char_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_schedule_begin,
                           nvl(p1.nick_name, p.nick_name) nick_name,
                           NULL num_clin_record,
                           (SELECT id_pat_identifier
                              FROM pat_identifier pi
                             WHERE pi.id_institution = i_prof.institution
                               AND pi.id_patient = sg.id_patient
                               AND rownum < 2) id_pat_identifier,
                           (SELECT id_clin_record
                              FROM pat_identifier pi
                             WHERE pi.id_institution = i_prof.institution
                               AND pi.id_patient = sg.id_patient
                               AND rownum < 2) id_clin_record,
                           sp.flg_sched,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                           NULL photo,
                           g_sysdate_char dt_server,
                           '' internment,
                           '0|' || pk_grid_amb.get_group_state_icon(i_lang, i_prof, s.id_group, pk_alert_constant.g_no) img_state,
                           'A' flg_state,
                           decode(pk_sysconfig.get_config('FLG_CANCEL_SCHEDULE', i_prof),
                                  'Y',
                                  decode(epis.id_episode, NULL, 'Y', 'N'),
                                  'N') can_canc,
                           decode(l_reasongrid,
                                  g_no,
                                  NULL,
                                  decode(l_adm_show_reason,
                                         g_yes,
                                         pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                                     i_prof,
                                                                                                                     ei.id_episode,
                                                                                                                     sp.id_schedule),
                                                                          4000))) visit_reason,
                           decode(s.flg_present, 'N', l_no_present_patient, NULL) patient_presence,
                           decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, epis.id_episode) designated_provider,
                           NULL flg_contact_type,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_handoff_type) resp_icon,
                           NULL flg_contact,
                           s.id_group,
                           pk_alert_constant.g_yes flg_group_header,
                           NULL extend_icon,
                           pk_alert_constant.g_no flg_button_ok
                      FROM schedule s
                      JOIN schedule_outp sp
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = sp.id_schedule
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                      JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      LEFT JOIN discharge d
                        ON d.id_episode = ei.id_episode
                       AND d.flg_status NOT IN
                           (pk_discharge_core.g_disch_status_cancel, pk_discharge_core.g_disch_status_reopen)
                       AND nvl(d.flg_status_adm, pk_alert_constant.g_no) <> pk_alert_constant.g_active
                      LEFT JOIN disch_reas_dest drt
                        ON drt.id_disch_reas_dest = d.id_disch_reas_dest
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = ei.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      LEFT JOIN professional p
                        ON p.id_professional = ei.sch_prof_outp_id_prof
                      LEFT JOIN dep_clin_serv dcs1
                        ON dcs1.id_dep_clin_serv = drt.id_dep_clin_serv
                      LEFT JOIN discharge_reason drn
                        ON drn.id_discharge_reason = drt.id_discharge_reason
                      LEFT JOIN clinical_service cs1
                        ON cs1.id_clinical_service = dcs1.id_clinical_service
                      LEFT JOIN institution i
                        ON i.id_institution = drt.id_institution
                      LEFT JOIN professional p1
                        ON p1.id_professional = ei.id_professional
                     WHERE s.id_schedule IN (SELECT /*+ opt_estimate (table d rows=1) */
                                              d.column_value
                                               FROM TABLE(l_schedule_ids_2) d)) t
             ORDER BY dt_order;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'GET_DAILY_SCHEDULE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_sched);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_admin_schedule
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dt    IN VARCHAR2,
        o_sched OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de agendamentos do dia indicado (Grelha do administrativo)
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                     I_PROF - prof q acede
                       I_DT - data
                  SAIDA:   O_SCHED - array de agendamentos
                                 O_ERROR - erro
        
          CRIAÇÃO: LG 2007/fev/06
          NOTAS: Nesta grelha visualizam-se os agendamentos do dia :
                 - não efectivados
               - efectivados mas ainda ñ atendidos clinicamente (médico ou enfª)
        *********************************************************************************/
        l_group_ids    table_number := table_number();
        l_schedule_ids table_number := table_number();
        l_sch_t640     sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
        l_can_cancel   VARCHAR2(1 CHAR);
    BEGIN
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz := current_timestamp;
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        SELECT DISTINCT s.id_group
          BULK COLLECT
          INTO l_group_ids
          FROM schedule s
          JOIN schedule_outp sp
            ON s.id_schedule = sp.id_schedule
          JOIN sch_group sg
            ON sg.id_schedule = sp.id_schedule
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
          JOIN patient pat
            ON pat.id_patient = sg.id_patient
          JOIN clin_record cr
            ON cr.id_patient = pat.id_patient
           AND cr.id_institution = i_prof.institution
          JOIN prof_dep_clin_serv pdcs
            ON pdcs.id_dep_clin_serv = s.id_dcs_requested
           AND pdcs.id_professional = i_prof.id
           AND pdcs.flg_status = g_selected
          LEFT JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
          LEFT JOIN episode epis
            ON epis.id_episode = ei.id_episode
           AND epis.flg_status != g_epis_canc
           AND epis.flg_ehr != g_flg_ehr
         WHERE sp.dt_target_tstz BETWEEN
               CAST(pk_date_utils.trunc_insttimezone(i_prof,
                                                     nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                         g_sysdate_tstz)) AS TIMESTAMP WITH LOCAL TIME ZONE) AND
               CAST(pk_date_utils.trunc_insttimezone(i_prof,
                                                     nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                         g_sysdate_tstz)) AS TIMESTAMP WITH LOCAL TIME ZONE) + INTERVAL '1'
         DAY
           AND sp.flg_state NOT IN (g_sched_med_disch, g_sched_adm_disch) --SS 2006/08/09: os pacientes com alta apareciam repetidos pq tb eram "apanhados" neste SELECT
           AND sp.id_epis_type NOT IN
               (g_flg_epis_type_nurse_care, g_flg_epis_type_nurse_outp, g_flg_epis_type_nurse_pp)
           AND sp.id_software = i_prof.software
           AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
           AND s.id_instit_requested = i_prof.institution
           AND (s.id_schedule NOT IN (SELECT nvl(id_schedule, 0)
                                        FROM epis_info) -- agendamentos s/ episódio = ñ efectivados
               OR s.id_schedule IN (SELECT nvl(ei2.id_schedule, 0)
                                       FROM epis_info ei2, episode e2
                                      WHERE ei2.id_episode = e2.id_episode
                                        AND e2.dt_end_tstz IS NULL
                                        AND ei2.dt_first_obs_tstz IS NULL
                                        AND ei2.dt_first_nurse_obs_tstz IS NULL)) -- agendamentos efectivados s/ atendimento clínico
           AND se.flg_is_group = pk_alert_constant.g_no
           AND s.id_group IS NOT NULL;
    
        l_schedule_ids := pk_grid_amb.get_schedule_ids(l_group_ids);
    
        l_can_cancel := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_intern_name => 'CANCEL_EPISODE');
        g_error      := 'GET CURSOR ';
        OPEN o_sched FOR
            SELECT t.id_schedule,
                   t.id_patient,
                   t.id_episode,
                   t.dt_efectiv,
                   t.dt_efectiv_compl,
                   t.name,
                   t.name_to_sort,
                   t.pat_ndo,
                   t.pat_nd_icon,
                   t.gender,
                   t.pat_age,
                   t.cons_type,
                   t.dt_target,
                   t.nick_name,
                   t.num_clin_record,
                   t.flg_sched,
                   t.dt_order,
                   t.img_sched,
                   t.photo,
                   t.dt_server,
                   t.internment,
                   t.img_state,
                   t.flg_state,
                   t.can_canc,
                   t.desc_room,
                   t.designated_provider,
                   t.flg_contact_type,
                   t.icon_contact_type,
                   t.flg_contact,
                   t.id_group,
                   t.flg_group_header,
                   t.extend_icon
              FROM (SELECT s.id_schedule,
                           sg.id_patient,
                           epis.id_episode,
                           decode(epis.flg_ehr,
                                  'S',
                                  NULL,
                                  pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   epis.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software)) dt_efectiv,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                           decode(i.flg_type,
                                  g_instit_c,
                                  g_sch_subs,
                                  g_instit_h,
                                  nvl(sp.flg_type,
                                      pk_episode.get_first_subseq(i_lang,
                                                                  pat.id_patient,
                                                                  cs.id_clinical_service,
                                                                  s.id_instit_requested,
                                                                  sp.id_epis_type))) flg_type,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           pat.gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           nvl(p1.nick_name, p.nick_name) nick_name,
                           cr.num_clin_record,
                           sp.flg_sched,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                           lpad(to_char(sd.rank), 6, '0') || sd.img_name img_sched,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           g_sysdate_char dt_server,
                           '' internment,
                           '0|' || decode(decode(epis.flg_ehr, 'S', decode(sp.flg_state, 'B', 'B', 'A'), sp.flg_state),
                                          'A',
                                          'I|||' || decode(epis.flg_ehr, 'S', 'PatientNotArrivedIcon', sd2.img_name),
                                          'B',
                                          'I|||' || sd2.img_name,
                                          'E',
                                          'D|' || pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) || '||' ||
                                          sd2.img_name,
                                          'G',
                                          'D|' || pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) || '||' ||
                                          sd2.img_name,
                                          NULL) || '|||||' || g_sysdate_char || '|' img_state, -- ASM 2007/01/05                    
                           decode(epis.flg_ehr, 'S', decode(sp.flg_state, 'B', 'B', 'A'), sp.flg_state) flg_state, -- LG 2006-09-19 INCLUDE FLG_STATE
                           decode(pk_sysconfig.get_config('FLG_CANCEL_SCHEDULE', i_prof),
                                  pk_alert_constant.g_yes,
                                  decode(l_can_cancel,
                                         pk_alert_constant.g_yes,
                                         decode(epis.id_episode,
                                                NULL,
                                                pk_alert_constant.g_yes,
                                                decode(epis.flg_ehr,
                                                       pk_ehr_access.g_flg_ehr_scheduled,
                                                       decode(sp.flg_state,
                                                              'B',
                                                              pk_alert_constant.g_no,
                                                              pk_alert_constant.g_yes),
                                                       pk_alert_constant.g_no)),
                                         pk_alert_constant.g_no),
                                  pk_alert_constant.g_no) can_canc, -- tco 15/05/2008
                           decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, epis.id_episode) designated_provider,
                           sg.flg_contact_type,
                           pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           0 id_group,
                           pk_alert_constant.g_no flg_group_header,
                           NULL extend_icon
                      FROM schedule s
                      JOIN schedule_outp sp
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      JOIN clin_record cr
                        ON cr.id_patient = pat.id_patient
                       AND cr.id_institution = i_prof.institution
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = s.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      JOIN institution i
                        ON i.id_institution = s.id_instit_requested
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN professional p
                        ON p.id_professional = ps.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                       AND epis.flg_status != g_epis_canc
                       AND epis.flg_ehr != g_flg_ehr
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      LEFT JOIN sys_domain sd
                        ON sd.code_domain = 'SCHEDULE_OUTP.FLG_SCHED'
                       AND sd.val = sp.flg_sched
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                      LEFT JOIN professional p1
                        ON p1.id_professional = ei.id_professional
                      LEFT JOIN sys_domain sd2
                        ON sd2.code_domain = g_schdl_outp_state_domain
                       AND sd2.domain_owner = pk_sysdomain.k_default_schema
                       AND sd2.val = sp.flg_state
                       AND sd2.id_language = i_lang
                     WHERE sp.dt_target_tstz BETWEEN
                           CAST(pk_date_utils.trunc_insttimezone(i_prof,
                                                                 nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   i_dt,
                                                                                                   NULL),
                                                                     g_sysdate_tstz)) AS TIMESTAMP WITH LOCAL TIME ZONE) AND
                           CAST(pk_date_utils.trunc_insttimezone(i_prof,
                                                                 nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   i_dt,
                                                                                                   NULL),
                                                                     g_sysdate_tstz)) AS TIMESTAMP WITH LOCAL TIME ZONE) +
                           INTERVAL '1'
                     DAY
                       AND sp.flg_state NOT IN (g_sched_med_disch, g_sched_adm_disch) --SS 2006/08/09: os pacientes com alta apareciam repetidos pq tb eram "apanhados" neste SELECT
                       AND sp.id_epis_type NOT IN
                           (g_flg_epis_type_nurse_care, g_flg_epis_type_nurse_outp, g_flg_epis_type_nurse_pp)
                       AND sp.id_software = i_prof.software
                       AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                       AND s.id_instit_requested = i_prof.institution
                       AND (s.id_schedule NOT IN (SELECT nvl(id_schedule, 0)
                                                    FROM epis_info) -- agendamentos s/ episódio = ñ efectivados
                           OR s.id_schedule IN (SELECT nvl(ei2.id_schedule, 0)
                                                   FROM epis_info ei2, episode e2
                                                  WHERE ei2.id_episode = e2.id_episode
                                                    AND e2.dt_end_tstz IS NULL
                                                    AND ei2.dt_first_obs_tstz IS NULL
                                                    AND ei2.dt_first_nurse_obs_tstz IS NULL)) -- agendamentos efectivados s/ atendimento clínico
                       AND se.flg_is_group = pk_alert_constant.g_no
                    --group elements
                    UNION ALL
                    SELECT s.id_schedule,
                           sg.id_patient,
                           epis.id_episode,
                           decode(epis.flg_ehr,
                                  'S',
                                  NULL,
                                  pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   epis.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software)) dt_efectiv,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                           decode(i.flg_type,
                                  g_instit_c,
                                  g_sch_subs,
                                  g_instit_h,
                                  nvl(sp.flg_type,
                                      pk_episode.get_first_subseq(i_lang,
                                                                  pat.id_patient,
                                                                  cs.id_clinical_service,
                                                                  s.id_instit_requested,
                                                                  sp.id_epis_type))) flg_type,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           pat.gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           nvl(p1.nick_name, p.nick_name) nick_name,
                           cr.num_clin_record,
                           sp.flg_sched,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                           lpad(to_char(sd.rank), 6, '0') || sd.img_name img_sched,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           g_sysdate_char dt_server,
                           '' internment,
                           '0|' || decode(decode(s.flg_status,
                                                 g_sched_canc,
                                                 g_sched_canc,
                                                 decode(epis.flg_ehr, 'S', 'A', sp.flg_state)),
                                          g_sched_canc,
                                          'I|||' || pk_sysdomain.get_img(i_lang, 'SCHEDULE.FLG_STATUS', s.flg_status),
                                          'A',
                                          'I|||' || decode(epis.flg_ehr, 'S', 'PatientNotArrivedIcon', sd2.img_name),
                                          'B',
                                          'I|||' || sd2.img_name,
                                          'E',
                                          'D|' || pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) || '||' ||
                                          sd2.img_name,
                                          'G',
                                          'D|' || pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) || '||' ||
                                          sd2.img_name,
                                          NULL) || '|||||' || g_sysdate_char || '|' img_state, -- ASM 2007/01/05                    
                           decode(s.flg_status, g_sched_canc, g_sched_canc, decode(epis.flg_ehr, 'S', 'A', sp.flg_state)) flg_state, -- LG 2006-09-19 INCLUDE FLG_STATE
                           decode(pk_sysconfig.get_config('FLG_CANCEL_SCHEDULE', i_prof),
                                  'Y',
                                  decode(epis.id_episode,
                                         NULL,
                                         'Y',
                                         decode(epis.flg_ehr,
                                                pk_ehr_access.g_flg_ehr_scheduled,
                                                pk_alert_constant.g_yes,
                                                pk_alert_constant.g_no)),
                                  'N') can_canc, -- tco 15/05/2008
                           NULL desc_room, --decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, epis.id_episode) designated_provider,
                           sg.flg_contact_type,
                           pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           s.id_group,
                           pk_alert_constant.g_no flg_group_header,
                           'ExtendIcon' extend_icon
                      FROM schedule s
                      JOIN schedule_outp sp
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      JOIN clin_record cr
                        ON cr.id_patient = pat.id_patient
                       AND cr.id_institution = i_prof.institution
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = s.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      JOIN institution i
                        ON i.id_institution = s.id_instit_requested
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN professional p
                        ON p.id_professional = ps.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      LEFT JOIN sys_domain sd
                        ON sd.code_domain = 'SCHEDULE_OUTP.FLG_SCHED'
                       AND sd.val = sp.flg_sched
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                      LEFT JOIN professional p1
                        ON p1.id_professional = ei.id_professional
                      LEFT JOIN sys_domain sd2
                        ON sd2.code_domain = g_schdl_outp_state_domain
                       AND sd2.domain_owner = pk_sysdomain.k_default_schema
                       AND sd2.val = sp.flg_state
                       AND sd2.id_language = i_lang
                     WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE k ROWS=0.00000000001)*/
                                           k.column_value
                                            FROM TABLE(l_group_ids) k)
                    --group header
                    UNION ALL
                    SELECT NULL id_schedule, --s.id_schedule,
                           NULL id_patient, --sg.id_patient,
                           NULL id_episode, -- epis.id_episode,
                           decode(epis.flg_ehr,
                                  'S',
                                  NULL,
                                  pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   epis.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software)) dt_efectiv,
                           pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                           decode(i.flg_type,
                                  g_instit_c,
                                  g_sch_subs,
                                  g_instit_h,
                                  nvl(sp.flg_type,
                                      pk_episode.get_first_subseq(i_lang,
                                                                  pat.id_patient,
                                                                  cs.id_clinical_service,
                                                                  s.id_instit_requested,
                                                                  sp.id_epis_type))) flg_type,
                           l_sch_t640 name, --  pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           l_sch_t640 name_to_sort, --  pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           NULL pat_ndo, --  pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           NULL pat_nd_icon, --  pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           NULL gender, --   pat.gender,
                           NULL pat_age, --  pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           nvl(p1.nick_name, p.nick_name) nick_name,
                           cr.num_clin_record,
                           sp.flg_sched,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                           lpad(to_char(sd.rank), 6, '0') || sd.img_name img_sched,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           g_sysdate_char dt_server,
                           '' internment,
                           pk_grid_amb.get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                           'A' flg_state, -- LG 2006-09-19 INCLUDE FLG_STATE
                           decode(pk_sysconfig.get_config('FLG_CANCEL_SCHEDULE', i_prof),
                                  'Y',
                                  decode(epis.id_episode,
                                         NULL,
                                         'Y',
                                         decode(epis.flg_ehr,
                                                pk_ehr_access.g_flg_ehr_scheduled,
                                                pk_alert_constant.g_yes,
                                                pk_alert_constant.g_no)),
                                  'N') can_canc, -- tco 15/05/2008
                           decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, epis.id_episode) designated_provider,
                           NULL flg_contact_type, -- sg.flg_contact_type,
                           pk_grid_amb.get_group_presence_icon(i_lang, i_prof, s.id_group, pk_alert_constant.g_no) icon_contact_type,
                           NULL flg_contact, --pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           s.id_group,
                           pk_alert_constant.g_yes flg_group_header,
                           NULL extend_icon
                      FROM schedule s
                      JOIN schedule_outp sp
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      JOIN clin_record cr
                        ON cr.id_patient = pat.id_patient
                       AND cr.id_institution = i_prof.institution
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = s.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      JOIN institution i
                        ON i.id_institution = s.id_instit_requested
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN professional p
                        ON p.id_professional = ps.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      LEFT JOIN sys_domain sd
                        ON sd.code_domain = 'SCHEDULE_OUTP.FLG_SCHED'
                       AND sd.val = sp.flg_sched
                       AND sd.domain_owner = pk_sysdomain.k_default_schema
                       AND sd.id_language = i_lang
                      LEFT JOIN professional p1
                        ON p1.id_professional = ei.id_professional
                     WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE d ROWS=0.00000000001)*/
                                              d.column_value
                                               FROM TABLE(l_schedule_ids) d)) t
             ORDER BY t.dt_order;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'GET_ADMIN_SCHEDULE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_sched);
                RETURN FALSE;
            
            END;
        
    END;

    FUNCTION admin_exam_req
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /*
        * List of lab tests and exams that where requested between episodes and are still to be scheduled
        *
        * @param      i_lang   Preferred language ID for this professional
        * @param      i_prof   Object (professional ID, institution ID, software ID)
        * @param      o_grid   Cursor
        * @param      o_error  Error
        *
        * @return     boolean type, "False" on error or "True" if success
        * @author     Ana Matos
        * @version    0.1
        * @since      2008/02/11
        */
        l_rank_sup NUMBER(12) := 999;
    
    BEGIN
    
        -- ASM: Esta query foi feita assim por motivos de performance (2008/06/04)
        g_error := 'GET O_GRID';
        OPEN o_grid FOR
            SELECT to_number(rank) rank,
                   acuity,
                   to_number(decode(id_software, g_edis_software, rank, l_rank_sup)) rank_acuity,
                   pk_message.get_message(i_lang,
                                          profissional(i_prof.id, i_prof.institution, id_software),
                                          'IMAGE_T009') epis_type,
                   NULL id_schedule,
                   id_episode,
                   'A' flg_type,
                   id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, id_patient, id_episode, NULL) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, id_patient, id_episode, NULL) name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, id_patient) pat_nd_icon,
                   pk_patient.get_gender(i_lang, gender) gender,
                   to_char(pat_age) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, id_patient, id_episode, NULL) photo,
                   num_clin_record,
                   nick_name,
                   pk_translation.get_translation(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || id_speciality) desc_speciality,
                   id_analysis id_exam,
                   pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                             i_prof,
                                                             'A',
                                                             'ANALYSIS.CODE_ANALYSIS.' || id_analysis,
                                                             'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || id_sample_type,
                                                             NULL) desc_exam,
                   pk_date_utils.dt_chr_tsz(i_lang, dt_req_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, dt_req_tstz, i_prof.institution, i_prof.software) hour_target,
                   id_analysis_req id_exam_req,
                   pk_date_utils.to_char_insttimezone(i_prof, dt_req_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                   id_analysis_req_det id_exam_req_det,
                   pk_translation.get_translation(i_lang, 'DEPT.CODE_DEPT.' || id_dept) || ' - ' ||
                   pk_translation.get_translation(i_lang,
                                                  'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' || id_clinical_service) dept,
                   decode(coalesce(notes, notes_cancel, notes_tech, notes_justify),
                          '',
                          '',
                          pk_message.get_message(i_lang, 'ANALYSIS_M093')) title_notes
              FROM (SELECT DISTINCT gtl.rank_acuity rank,
                                    gtl.acuity,
                                    gtl.id_software,
                                    gtl.id_episode,
                                    gtl.id_patient,
                                    gtl.gender,
                                    gtl.pat_age,
                                    gtl.num_clin_record,
                                    p.nick_name,
                                    p.id_speciality,
                                    ard.id_analysis,
                                    ard.id_sample_type,
                                    gtl.dt_req_tstz,
                                    gtl.id_analysis_req,
                                    gtl.id_analysis_req_det,
                                    gtl.id_dept,
                                    gtl.id_clinical_service,
                                    ard.notes,
                                    ard.notes_cancel,
                                    ard.notes_tech,
                                    ard.notes_justify
                      FROM grid_task_lab gtl, analysis_req_det ard, exam_cat_dcs ecdcs, professional p
                     WHERE gtl.dt_target_tstz IS NULL
                       AND gtl.id_institution = i_prof.institution
                       AND gtl.flg_time_harvest IN (g_flg_time_b, g_flg_time_d)
                       AND (gtl.flg_status_ard NOT IN (g_analy_req_res, g_analy_req_canc, g_analy_req_ext) OR
                           (gtl.flg_status_ard = g_analy_req_ext AND ard.flg_col_inst = g_yes))
                       AND gtl.id_professional = p.id_professional
                       AND gtl.id_analysis_req_det = ard.id_analysis_req_det
                       AND ard.id_exam_cat = ecdcs.id_exam_cat
                       AND EXISTS (SELECT 1
                              FROM prof_dep_clin_serv pdcs
                             WHERE pdcs.id_professional = i_prof.id
                               AND pdcs.flg_status = g_selected
                               AND pdcs.id_institution = i_prof.institution
                               AND pdcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv))
             ORDER BY date_target, hour_target;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'ADMIN_EXAM_REQ');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_grid);
                RETURN FALSE;
            
            END;
            /*            o_error := pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) || 'PK_GRID.ADMIN_EXAM_REQ / ' ||
                                   g_error || ' / ' || SQLERRM;
                        pk_types.open_my_cursor(o_grid);
                        RETURN FALSE;
            */
    END;

    PROCEDURE get_scheduled_tests_parameters
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
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
    
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
        g_dt CONSTANT VARCHAR2(1) := 1;
    
        l_dt CONSTANT VARCHAR2(100 CHAR) := i_context_vals(g_dt);
    
        value_config sys_config.desc_sys_config%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
    
        pk_context_api.set_parameter('i_patient', l_patient);
        pk_context_api.set_parameter('i_episode', l_episode);
    
        value_config := pk_sysconfig.get_config(i_code_cf => 'REM_FUNC_SCHEDULED_TESTS', i_prof => l_prof);
        pk_context_api.set_parameter('i_sys_config', value_config);
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_sys_config' THEN
                o_id := value_config;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'i_dt_min' THEN
                o_tstz := CASE
                              WHEN l_dt IS NULL THEN
                               pk_date_utils.trunc_insttimezone(l_prof, current_timestamp)
                              ELSE
                               pk_date_utils.get_string_tstz(l_lang, l_prof, l_dt, NULL)
                          END;
            WHEN 'i_dt_max' THEN
                o_tstz := CASE
                              WHEN l_dt IS NULL THEN
                               pk_date_utils.trunc_insttimezone(l_prof, current_timestamp) + INTERVAL '1' DAY
                              ELSE
                               pk_date_utils.get_string_tstz(l_lang, l_prof, l_dt, NULL) + INTERVAL '1' DAY
                          END;
            WHEN 'l_prof_cat' THEN
                o_vc2 := pk_prof_utils.get_category(l_lang, l_prof);
            WHEN 'g_sched_scheduled' THEN
                o_vc2 := 'A';
            WHEN 'wr_call' THEN
                o_vc2 := i_name;
            WHEN 'l_waiting_room_available' THEN
                o_vc2 := pk_sysconfig.get_config('WL_WAITING_ROOM_AVAILABLE', l_prof);
            WHEN 'l_waiting_room_sys_external' THEN
                o_vc2 := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM', l_prof);
        END CASE;
    
    END get_scheduled_tests_parameters;

    PROCEDURE get_tests_list_parameters
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
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
    
        l_lang CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
    
        l_collect_pending sys_config.id_sys_config%TYPE := pk_sysconfig.get_config('HARVEST_PENDING_REQ', l_prof);
    
        l_prof_cat category.flg_type%TYPE;
    
        l_epis_type epis_type.id_epis_type%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
        pk_context_api.set_parameter('l_collect_pending', l_collect_pending);
    
        l_prof_cat := pk_prof_utils.get_category(l_lang, l_prof);
    
        pk_context_api.set_parameter('i_prof_cat_type', l_prof_cat);
    
        IF i_context_vals.exists(2)
        THEN
            IF i_context_vals(2) = 0
            THEN
                l_epis_type := NULL;
            ELSE
                l_epis_type := to_number(i_context_vals(2));
            END IF;
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
            WHEN 'l_prof_cat' THEN
                o_vc2 := pk_prof_utils.get_category(l_lang, l_prof);
            WHEN 'l_epis_type' THEN
                o_vc2 := l_epis_type;
        END CASE;
    END get_tests_list_parameters;

    FUNCTION get_scheduled_tests_dates
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_num_days_back    sys_config.value%TYPE := pk_sysconfig.get_config('NUM_DAYS_SCHEDULED_TESTS_GRID_NAVIGATION_BACK',
                                                                            i_prof);
        l_num_days_forward sys_config.value%TYPE := pk_sysconfig.get_config('NUM_DAYS_SCHEDULED_TESTS_GRID_NAVIGATION_FORWARD',
                                                                            i_prof);
    
        l_dt_current VARCHAR2(200);
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        l_dt_current := pk_date_utils.trunc_insttimezone_str(i_prof, g_sysdate_tstz, 'DD');
    
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
    
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('i_prof_id', i_prof.id);
        pk_context_api.set_parameter('i_prof_institution', i_prof.institution);
        pk_context_api.set_parameter('i_prof_software', i_prof.software);
    
        g_error := 'GET O_LIST';
        OPEN o_list FOR
            SELECT date_desc,
                   date_tstz,
                   decode(date_tstz, l_dt_current, pk_alert_constant.g_yes, pk_alert_constant.g_no) today
              FROM (SELECT pk_grid_amb.get_extense_day_desc(i_lang,
                                                             pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof)) date_desc,
                            pk_date_utils.trunc_insttimezone_str(i_prof, dt_begin_tstz, 'DD') date_tstz
                       FROM (SELECT e.dt_begin_tstz
                               FROM v_exam_scheduled e
                              WHERE e.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end
                             UNION ALL
                             SELECT a.dt_begin_tstz
                               FROM v_lab_test_scheduled a
                              WHERE a.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end
                             UNION ALL
                             SELECT i.dt_begin_tstz
                               FROM v_interv_scheduled i
                              WHERE i.dt_begin_tstz BETWEEN l_dt_begin AND l_dt_end)
                     UNION -- union with current date in case there's no appoitment for today
                    SELECT pk_grid_amb.get_extense_day_desc(i_lang,
                                                            pk_date_utils.date_send_tsz(i_lang,
                                                                                        pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                         g_sysdate_tstz),
                                                                                        i_prof)) date_desc,
                           pk_date_utils.date_send_tsz(i_lang,
                                                       pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                                       i_prof) date_tstz
                      FROM dual)
             ORDER BY date_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_GRID',
                                              'GET_SCHEDULED_TESTS_DATES',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_scheduled_tests_dates;

    FUNCTION get_scheduled_tests
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_grid    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET O_GRID';
        OPEN o_grid FOR
            SELECT 'E' flg_type,
                   e.id_patient,
                   e.id_episode,
                   eea.id_exam_req id_req,
                   eea.id_exam_req_det id_req_det,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, eea.id_prof_req) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, eea.id_prof_req, eea.dt_req, eea.id_episode) prof_spec,
                   pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_exam,
                   pk_date_utils.dt_chr_tsz(i_lang, eea.dt_req, i_prof) dt_req,
                   pk_date_utils.date_char_hour_tsz(i_lang, eea.dt_req, i_prof.institution, i_prof.software) hr_req,
                   pk_date_utils.dt_chr_tsz(i_lang, eea.dt_begin, i_prof) dt_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, eea.dt_begin, i_prof.institution, i_prof.software) hr_begin
              FROM exams_ea eea, exam_cat_dcs ecdcs, episode e
             WHERE eea.id_patient = i_patient
               AND eea.flg_time IN (pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
               AND eea.flg_status_det IN
                   (pk_exam_constant.g_exam_tosched, pk_exam_constant.g_exam_sched, pk_exam_constant.g_exam_pending)
               AND eea.id_exam_cat = ecdcs.id_exam_cat
               AND EXISTS (SELECT 1
                      FROM prof_dep_clin_serv pdcs
                     WHERE pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                       AND pdcs.id_institution = i_prof.institution
                       AND pdcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv)
               AND (eea.id_episode = e.id_episode OR eea.id_episode_origin = e.id_episode)
               AND e.id_institution = i_prof.institution
               AND e.flg_status != pk_alert_constant.g_epis_status_cancel
            UNION
            -- CRS 2006/02/01 Contemplar as análises de Patologia Clínica para marcação pelas administrativas
            SELECT 'A' flg_type,
                   e.id_patient,
                   e.id_episode,
                   lte.id_analysis_req id_req,
                   lte.id_analysis_req_det id_req_det,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lte.id_prof_writes) prof_name,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, lte.id_prof_writes, lte.dt_req, lte.id_episode) prof_spec,
                   pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                             i_prof,
                                                             'A',
                                                             'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                             'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lte.id_sample_type,
                                                             NULL) desc_exam,
                   pk_date_utils.dt_chr_tsz(i_lang, lte.dt_req, i_prof) dt_req,
                   pk_date_utils.date_char_hour_tsz(i_lang, lte.dt_req, i_prof.institution, i_prof.software) hr_req,
                   pk_date_utils.dt_chr_tsz(i_lang, lte.dt_target, i_prof) dt_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, lte.dt_target, i_prof.institution, i_prof.software) hr_begin
              FROM lab_tests_ea lte, exam_cat_dcs ecdcs, episode e
             WHERE lte.id_patient = i_patient
               AND lte.flg_time_harvest IN (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d)
               AND lte.flg_status_det IN (pk_lab_tests_constant.g_analysis_tosched,
                                          pk_lab_tests_constant.g_analysis_sched,
                                          pk_lab_tests_constant.g_analysis_pending)
               AND lte.id_exam_cat = ecdcs.id_exam_cat
               AND EXISTS (SELECT 1
                      FROM prof_dep_clin_serv pdcs
                     WHERE pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                       AND pdcs.id_institution = i_prof.institution
                       AND pdcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv)
               AND (lte.id_episode = e.id_episode OR lte.id_episode_origin = e.id_episode)
               AND e.id_institution = i_prof.institution
               AND e.flg_status != pk_alert_constant.g_epis_status_cancel
             ORDER BY dt_begin, hr_begin;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_GRID',
                                              'GET_SCHEDULED_TESTS',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_scheduled_tests;

    FUNCTION get_tests_to_schedule
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req      IN NUMBER,
        i_flg_type IN VARCHAR2,
        o_exam     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET O_EXAM';
        IF i_flg_type = 'A'
        THEN
            OPEN o_exam FOR
                SELECT listagg(lte.id_analysis_req_det, ';') within GROUP(ORDER BY lte.id_analysis_req_det) id_req_det,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, lte.id_prof_writes) prof_name,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, lte.id_prof_writes, lte.dt_req, lte.id_episode) prof_spec,
                       listagg(pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                         i_prof,
                                                                         pk_lab_tests_constant.g_analysis_alias,
                                                                         'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                         'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                         lte.id_sample_type,
                                                                         NULL),
                               '; ') within GROUP(ORDER BY lte.id_analysis_req_det) desc_exam,
                       pk_sysdomain.get_domain(i_lang, i_prof, 'ANALYSIS_REQ.FLG_STATUS', lte.flg_status_req, NULL) desc_status,
                       pk_date_utils.dt_chr_tsz(i_lang, lte.dt_req, i_prof) dt_req,
                       pk_date_utils.date_char_hour_tsz(i_lang, lte.dt_req, i_prof.institution, i_prof.software) hr_req,
                       pk_date_utils.to_char_insttimezone(i_prof, lte.dt_target, 'YYYYMMDDHH24MISS') dt_begin,
                       lte.notes_scheduler notes
                  FROM lab_tests_ea lte, episode e
                 WHERE lte.id_analysis_req = i_req -- for lab tests, it must be scheduled the order
                   AND (lte.id_episode = e.id_episode OR lte.id_episode_origin = e.id_episode)
                 GROUP BY lte.id_analysis_req,
                          lte.id_prof_writes,
                          lte.dt_req,
                          lte.dt_target,
                          lte.id_episode,
                          lte.flg_status_req,
                          lte.notes_scheduler;
        ELSE
            OPEN o_exam FOR
                SELECT eea.id_exam_req_det id_req_det,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, eea.id_prof_req) prof_name,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, eea.id_prof_req, eea.dt_req, eea.id_episode) prof_spec,
                       pk_exams_api_db.get_alias_translation(i_lang, i_prof, 'EXAM.CODE_EXAM.' || eea.id_exam, NULL) desc_exam,
                       pk_sysdomain.get_domain(i_lang, i_prof, 'EXAM_REQ_DET.FLG_STATUS', eea.flg_status_det, NULL) desc_status,
                       pk_date_utils.dt_chr_tsz(i_lang, eea.dt_req, i_prof) dt_req,
                       pk_date_utils.date_char_hour_tsz(i_lang, eea.dt_req, i_prof.institution, i_prof.software) hr_req,
                       pk_date_utils.to_char_insttimezone(i_prof, eea.dt_begin, 'YYYYMMDDHH24MISS') dt_begin,
                       eea.notes_scheduler notes
                  FROM exams_ea eea, episode e
                 WHERE eea.id_exam_req = i_req
                   AND (eea.id_episode = e.id_episode OR eea.id_episode_origin = e.id_episode);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_GRID',
                                              'GET_TESTS_TO_SCHEDULE',
                                              o_error);
            pk_types.open_my_cursor(o_exam);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_tests_to_schedule;

    FUNCTION technician_by_patient
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_dt         IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET O_GRID';
        OPEN o_grid FOR
        /*<DENORM 2008-10-13 Sérgio Monteiro>*/
            SELECT DISTINCT ei.id_schedule,
                            epis.id_episode,
                            epis.id_patient,
                            cr.num_clin_record,
                            pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                            pk_date_utils.dt_chr_tsz(i_lang, eea.dt_begin, i_prof) dt_begin_date,
                            pk_date_utils.date_char_hour_tsz(i_lang, eea.dt_begin, i_prof.institution, i_prof.software) dt_begin_hour,
                            eea.id_exam,
                            pk_exams_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  'EXAM.CODE_EXAM.' || eea.id_exam,
                                                                  NULL) desc_exam,
                            decode(eea.id_exam_result, NULL, 'N', 'Y') flg_result,
                            eea.id_exam_req,
                            pk_translation.get_translation(i_lang, 'DEPT.CODE_DEPT.' || epis.id_dept) || ' - ' ||
                            pk_translation.get_translation(i_lang,
                                                           'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                           epis.id_clinical_service) dept
              FROM clin_record cr, episode epis, epis_info ei, exam_cat ec, exam_cat_dcs ecdcs, exams_ea eea
             WHERE eea.flg_status_det != g_exam_req_canc
               AND ec.id_exam_cat = eea.id_exam_cat
               AND ecdcs.id_exam_cat = ec.id_exam_cat
               AND EXISTS (SELECT 1
                      FROM prof_dep_clin_serv pdcs
                     WHERE pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                       AND pdcs.id_institution = i_prof.institution
                       AND pdcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv)
               AND epis.id_episode = eea.id_episode
               AND epis.flg_status != g_epis_canc -- CRS 2006/07/20
               AND ei.id_episode = epis.id_episode
               AND epis.id_institution = i_prof.institution -- CRS 2006/06/29
               AND cr.id_patient = epis.id_patient
               AND cr.id_institution = i_prof.institution
               AND epis.id_patient = i_id_patient
            /*<DENORM 2008-10-13 Sérgio Monteiro>*/
            UNION ALL
            -- CRS 2006/02/21 Contemplar os análises para marcação pelas administrativas
            -- < DENORM LMAIA 17-10-2008 >
            SELECT DISTINCT ei.id_schedule,
                            epis.id_episode,
                            epis.id_patient,
                            cr.num_clin_record,
                            pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                            pk_date_utils.dt_chr_tsz(i_lang, lte.dt_target, i_prof) dt_begin_date, -- Validada troca pelo Gustavo em 20-10-2008
                            pk_date_utils.date_char_hour_tsz(i_lang, lte.dt_target, i_prof.institution, i_prof.software) dt_begin_hour,
                            lte.id_analysis,
                            pk_lab_tests_api_db.get_alias_translation(i_lang,
                                                                      i_prof,
                                                                      'A',
                                                                      'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                      lte.id_sample_type,
                                                                      NULL) desc_exam,
                            decode(id_analysis_result, NULL, 'N', 'Y') flg_result,
                            lte.id_analysis_req,
                            pk_translation.get_translation(i_lang, 'DEPT.CODE_DEPT.' || epis.id_dept) || ' - ' ||
                            pk_translation.get_translation(i_lang,
                                                           'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                           epis.id_clinical_service) dept
              FROM clin_record cr, episode epis, epis_info ei, exam_cat_dcs ecdcs, lab_tests_ea lte
             WHERE lte.flg_status_det != g_analy_req_canc
               AND lte.id_exam_cat = ecdcs.id_exam_cat
               AND EXISTS (SELECT 1
                      FROM prof_dep_clin_serv pdcs
                     WHERE pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                       AND pdcs.id_institution = i_prof.institution
                       AND pdcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv)
               AND epis.id_episode = lte.id_episode
               AND epis.flg_status != g_epis_canc -- CRS 2006/07/20
               AND ei.id_episode = epis.id_episode
               AND epis.id_institution = i_prof.institution -- CRS 2006/06/29
               AND cr.id_patient = epis.id_patient
               AND cr.id_institution = i_prof.institution
               AND epis.id_patient = i_id_patient
             ORDER BY flg_result, dt_begin_date, dt_begin_hour;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'TECHNICIAN_BY_PATIENT');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_grid);
                RETURN FALSE;
            
            END;
    END technician_by_patient;

    FUNCTION get_admin_discharge
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dt    IN VARCHAR2,
        o_sched OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Obter lista de agendamentos do dia indicado (Grelha do administrativo)
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                     I_PROF - prof q acede
                       I_DT - data
                  SAIDA:   O_SCHED - array de agendamentos
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/04/07
          ALTERAÇÃO: CRS 2006/07/20 Excluir episódios cancelados
               ASM 2007/01/05 Na coluna de estado, mostrar o tempo de espera para alta administrativa
        
          NOTAS: Nesta grelha visualizam-se os agendamentos do dia :
               - atendidos clinicamente c/ alta médica, mas s/ alta administrativa
                   LG 2007-Fev-07 - adicionada coluna para anexos
                   LG 2007-Fev-09 - Considerou-se a possibilidade de o administrativo poder dar alta sem que o médico o faça.
        *********************************************************************************/
        l_disch_mandatory VARCHAR2(0050);
        l_payment_req     isencao.id_isencao%TYPE;
        l_dt_min          schedule_outp.dt_target_tstz%TYPE;
        l_dt_max          schedule_outp.dt_target_tstz%TYPE;
    BEGIN
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz := current_timestamp;
    
        -- set date bounds
        l_dt_min := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                     i_timestamp => nvl(pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                      i_prof      => i_prof,
                                                                                                      i_timestamp => i_dt,
                                                                                                      i_timezone  => NULL),
                                                                        g_sysdate_tstz));
        l_dt_max := pk_date_utils.add_days_to_tstz(i_timestamp => l_dt_min, i_days => 1);
    
        g_error           := 'GET DISCHARGE MANDATORY';
        l_disch_mandatory := pk_sysconfig.get_config('DOCTOR_DISCH_MANDATORY', i_prof);
        l_payment_req     := pk_sysconfig.get_config('PAYMENT_REQUIRED_EXEMPTION_ID', i_prof);
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        g_error := 'GET SYSDATE CHAR';
        -- JS, 2007-09-11 - Timezone
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        IF (l_disch_mandatory = 'Y')
        THEN
            g_error := 'GET CURSOR ONLY DISCHARGE';
            OPEN o_sched FOR
                SELECT DISTINCT ei.id_schedule,
                                sg.id_patient,
                                epis.id_episode,
                                -- JS, 2007-09-11 - Timezone
                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                 epis.dt_begin_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software) dt_efectiv,
                                pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                                decode(i.flg_type,
                                       g_instit_c,
                                       g_sch_subs,
                                       g_instit_h,
                                       nvl(sp.flg_type,
                                           pk_episode.get_first_subseq(i_lang,
                                                                       pat.id_patient,
                                                                       cs.id_clinical_service,
                                                                       ei.id_instit_requested,
                                                                       sp.id_epis_type))) flg_type,
                                pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) name,
                                pk_patient.get_pat_name_to_sort(i_lang,
                                                                i_prof,
                                                                sg.id_patient,
                                                                epis.id_episode,
                                                                ei.id_schedule) name_to_sort,
                                pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                                pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                                pat.gender,
                                pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                                --                                pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                                pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                                -- JS, 2007-09-11 - Timezone
                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                 sp.dt_target_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software) dt_target,
                                nvl(p1.nick_name, p.nick_name) nick_name,
                                cr.num_clin_record,
                                sp.flg_sched,
                                -- JS, 2007-09-11 - Timezone
                                pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                                pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                                pk_patphoto.get_pat_photo(i_lang,
                                                          i_prof,
                                                          sg.id_patient,
                                                          epis.id_episode,
                                                          ei.id_schedule) photo,
                                g_sysdate_char dt_server,
                                decode(drt.id_discharge_reason,
                                       pk_sysconfig.get_config('ID_DISCHARGE_INTERNMENT', i_prof),
                                       pk_message.get_message(i_lang, 'GRID_ADMIN_M001') || ' ' ||
                                       pk_translation.get_translation(i_lang, cs1.code_clinical_service),
                                       pk_sysconfig.get_config('ID_DISCHARGE_CE', i_prof),
                                       pk_message.get_message(i_lang, 'GRID_ADMIN_M002') || ' ' ||
                                       pk_translation.get_translation(i_lang, cs1.code_clinical_service),
                                       pk_sysconfig.get_config('ID_DISCHARGE_INSTIT', i_prof),
                                       pk_translation.get_translation(i_lang, i.code_institution),
                                       pk_sysconfig.get_config('ID_DISCHARGE_CS', i_prof),
                                       pk_translation.get_translation(i_lang, i.code_institution),
                                       pk_translation.get_translation(i_lang, drn.code_discharge_reason)) internment,
                                '0|' ||
                                decode(sp.flg_state,
                                       'D',
                                       -- JS, 2007-09-11 - Timezone
                                       pk_date_utils.to_char_insttimezone(i_prof, ei.dt_med_tstz, 'YYYYMMDDHH24MISS') ||
                                       '|DI|X|' || pk_sysdomain.get_img(i_lang, g_schdl_outp_state_domain, sp.flg_state),
                                       'xxxxxxxxxxxxxx|I|X|' ||
                                       pk_sysdomain.get_img(i_lang, g_schdl_outp_state_domain, sp.flg_state)) img_state,
                                sp.flg_state flg_state, -- LG 2006-09-19 INCLUDE FLG_STATE
                                pk_doc.get_num_episode_images(epis.id_episode, epis.id_patient) attaches,
                                decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                                pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, epis.id_episode) designated_provider,
                                sg.flg_contact_type,
                                (SELECT pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type)
                                   FROM dual) icon_contact_type
                  FROM schedule_outp      sp,
                       sch_group          sg,
                       patient            pat,
                       pat_soc_attributes psa,
                       clinical_service   cs,
                       professional       p,
                       clin_record        cr,
                       epis_info          ei,
                       episode            epis,
                       disch_reas_dest    drt,
                       dep_clin_serv      dcs1,
                       discharge_reason   drn,
                       clinical_service   cs1,
                       prof_dep_clin_serv pdcs,
                       institution        i,
                       professional       p1
                -- JS, 2007-09-11 - Timezone
                 WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                   AND sp.id_software = i_prof.software
                   AND nvl(ei.flg_sch_status, 'A') != g_sched_canc
                   AND ei.id_schedule = sp.id_schedule
                   AND ei.id_instit_requested = i_prof.institution
                   AND pdcs.id_dep_clin_serv = ei.id_dcs_requested
                   AND pdcs.id_professional = i_prof.id
                   AND pdcs.flg_status = g_selected
                   AND p.id_professional(+) = ei.sch_prof_outp_id_prof
                   AND sg.id_schedule = sp.id_schedule
                   AND pat.id_patient = sg.id_patient
                   AND pat.id_patient = psa.id_patient(+)
                   AND (psa.id_isencao = l_payment_req OR psa.id_isencao IS NULL)
                   AND cs.id_clinical_service = epis.id_cs_requested
                   AND cr.id_patient = pat.id_patient
                   AND cr.id_institution = i_prof.institution
                   AND p1.id_professional(+) = ei.id_professional -- CRS 2006/07/11
                   AND epis.id_episode = ei.id_episode
                   AND epis.flg_status != g_epis_canc -- CRS 2006/07/20
                      -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
                   AND epis.flg_ehr != g_flg_ehr
                      -- JS, 2007-09-11 - Timezone
                   AND ei.flg_dsch_status NOT IN
                       (pk_discharge_core.g_disch_status_cancel, pk_discharge_core.g_disch_status_reopen)
                   AND ei.dt_admin_tstz IS NULL -- s/ alta administrativa
                   AND drt.id_disch_reas_dest = ei.id_disch_reas_dest
                   AND dcs1.id_dep_clin_serv(+) = drt.id_dep_clin_serv -- alta para dep. dentro da instituição
                   AND cs1.id_clinical_service(+) = dcs1.id_clinical_service
                   AND drn.id_discharge_reason(+) = drt.id_discharge_reason
                   AND i.id_institution(+) = drt.id_institution
                   AND epis.id_epis_type != g_epis_type_nurse
                 ORDER BY dt_order;
        ELSE
            g_error := 'GET CURSOR DISCHARGE AND NOT DISCHARGE';
            OPEN o_sched FOR
                SELECT DISTINCT ei.id_schedule,
                                sg.id_patient,
                                epis.id_episode,
                                -- JS, 2007-09-11 - Timezone
                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                 epis.dt_begin_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software) dt_efectiv,
                                pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                                decode(i.flg_type,
                                       g_instit_c,
                                       g_sch_subs,
                                       g_instit_h,
                                       nvl(sp.flg_type,
                                           pk_episode.get_first_subseq(i_lang,
                                                                       pat.id_patient,
                                                                       cs.id_clinical_service,
                                                                       ei.id_instit_requested,
                                                                       sp.id_epis_type))) flg_type,
                                pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) name,
                                pk_patient.get_pat_name_to_sort(i_lang,
                                                                i_prof,
                                                                sg.id_patient,
                                                                epis.id_episode,
                                                                ei.id_schedule) name_to_sort,
                                pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                                pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                                pat.gender,
                                pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                                --                                pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                                pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                                -- JS, 2007-09-11 - Timezone
                                pk_date_utils.date_char_hour_tsz(i_lang,
                                                                 sp.dt_target_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software) dt_target,
                                nvl(p1.nick_name, p.nick_name) nick_name,
                                cr.num_clin_record,
                                sp.flg_sched,
                                -- JS, 2007-09-11 - Timezone
                                pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                                pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                                pk_patphoto.get_pat_photo(i_lang,
                                                          i_prof,
                                                          sg.id_patient,
                                                          epis.id_episode,
                                                          ei.id_schedule) photo,
                                g_sysdate_char dt_server,
                                decode(drt.id_discharge_reason,
                                       NULL,
                                       NULL,
                                       pk_sysconfig.get_config('ID_DISCHARGE_INTERNMENT', i_prof),
                                       pk_message.get_message(i_lang, 'GRID_ADMIN_M001') || ' ' ||
                                       pk_translation.get_translation(i_lang, cs1.code_clinical_service),
                                       pk_sysconfig.get_config('ID_DISCHARGE_CE', i_prof),
                                       pk_message.get_message(i_lang, 'GRID_ADMIN_M002') || ' ' ||
                                       pk_translation.get_translation(i_lang, cs1.code_clinical_service),
                                       pk_sysconfig.get_config('ID_DISCHARGE_INSTIT', i_prof),
                                       pk_translation.get_translation(i_lang, i.code_institution),
                                       pk_sysconfig.get_config('ID_DISCHARGE_CS', i_prof),
                                       pk_translation.get_translation(i_lang, i.code_institution),
                                       pk_translation.get_translation(i_lang, drn.code_discharge_reason)) internment,
                                '0|' ||
                                decode(sp.flg_state,
                                       'D',
                                       -- JS, 2007-09-11 - Timezone
                                       pk_date_utils.to_char_insttimezone(i_prof, ei.dt_med_tstz, 'YYYYMMDDHH24MISS') ||
                                       '|DI|X|',
                                       'xxxxxxxxxxxxxx|I|X|') ||
                                pk_sysdomain.get_img(i_lang, g_schdl_outp_state_domain, sp.flg_state) img_state,
                                sp.flg_state flg_state, -- LG 2006-09-19 INCLUDE FLG_STATE
                                pk_doc.get_num_episode_images(epis.id_episode, epis.id_patient) attaches,
                                decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                                pk_patient.get_designated_provider(i_lang, i_prof, sg.id_patient, epis.id_episode) designated_provider,
                                sg.flg_contact_type,
                                (SELECT pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type)
                                   FROM dual) icon_contact_type
                  FROM schedule_outp      sp,
                       sch_group          sg,
                       patient            pat,
                       pat_soc_attributes psa,
                       clinical_service   cs,
                       professional       p,
                       clin_record        cr,
                       epis_info          ei,
                       episode            epis,
                       disch_reas_dest    drt,
                       dep_clin_serv      dcs1,
                       discharge_reason   drn,
                       clinical_service   cs1,
                       prof_dep_clin_serv pdcs,
                       institution        i,
                       professional       p1
                -- JS, 2007-09-11 - Timezone
                 WHERE sp.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
                   AND sp.id_software = i_prof.software
                   AND ei.flg_sch_status != g_sched_canc
                   AND ei.id_schedule = sp.id_schedule
                   AND ei.id_instit_requested = i_prof.institution
                   AND pdcs.id_dep_clin_serv = ei.id_dcs_requested
                   AND pdcs.id_professional = i_prof.id
                   AND pdcs.flg_status = g_selected
                   AND p.id_professional(+) = ei.sch_prof_outp_id_prof
                   AND sg.id_schedule = sp.id_schedule
                   AND pat.id_patient = sg.id_patient
                   AND pat.id_patient = psa.id_patient(+)
                      -- lg 2007 Abr 02 qual o sentido? AND (psa.id_isencao = 1 OR psa.id_isencao IS NULL)
                   AND cs.id_clinical_service = epis.id_cs_requested
                   AND cr.id_patient = pat.id_patient
                   AND cr.id_institution = i_prof.institution
                   AND p1.id_professional(+) = ei.id_professional -- CRS 2006/07/11
                   AND epis.id_episode = ei.id_episode
                   AND epis.flg_status != g_epis_canc -- CRS 2006/07/20
                      -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
                   AND epis.flg_ehr != g_flg_ehr
                      -- JS, 2007-09-11 - Timezone
                   AND nvl(ei.flg_dsch_status, 'A') NOT IN
                       (pk_discharge_core.g_disch_status_cancel, pk_discharge_core.g_disch_status_reopen)
                   AND ei.dt_admin_tstz IS NULL -- s/ alta administrativa                  
                   AND drt.id_disch_reas_dest(+) = ei.id_disch_reas_dest
                   AND dcs1.id_dep_clin_serv(+) = drt.id_dep_clin_serv -- alta para dep. dentro da instituição
                   AND cs1.id_clinical_service(+) = dcs1.id_clinical_service
                   AND drn.id_discharge_reason(+) = drt.id_discharge_reason
                   AND i.id_institution(+) = drt.id_institution
                   AND epis.id_epis_type != g_epis_type_nurse
                 ORDER BY dt_order;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'GET_ADMIN_DISCHARGE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_sched);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_aux_schedule
    (
        i_lang      IN language.id_language%TYPE,
        i_dt        IN VARCHAR2,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_sched     OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_handoff_type sys_config.value%TYPE;
    
        l_prof_cat category.flg_type%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
    
        g_error    := 'GET PROF_CAT';
        l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
    
        g_error := 'GET CURSOR';
        OPEN o_sched FOR
            SELECT ei.id_schedule,
                   sg.id_patient,
                   ei.id_episode,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, ei.id_episode, ei.id_schedule) photo,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, ei.id_episode, ei.id_schedule) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, ei.id_episode, ei.id_schedule) name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                   pk_date_utils.date_char_hour_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_target,
                   pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                   pk_prof_utils.get_nickname(i_lang, ei.sch_prof_outp_id_prof) nick_name,
                   sp.flg_sched,
                   (SELECT pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang)
                      FROM dual) img_sched,
                   gt.drug_transp desc_drug_req,
                   (SELECT pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, 'H', l_prof_cat)
                      FROM dual) desc_harvest, --gt.harvest
                   (SELECT pk_grid.visit_grid_task_str(i_lang, i_prof, e.id_visit, 'T', l_prof_cat)
                      FROM dual) desc_mov, --gt.movement
                   gt.clin_rec_transp desc_cli_rec_req,
                   gt.supplies desc_supplies,
                   (SELECT pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, l_handoff_type)
                      FROM dual) resp_icon,
                   g_sysdate_char dt_server,
                   gt.hemo_req
              FROM episode            e,
                   epis_info          ei,
                   schedule_outp      sp,
                   sch_group          sg,
                   patient            pat,
                   clinical_service   cs,
                   prof_dep_clin_serv pdcs,
                   grid_task          gt
             WHERE e.id_institution = i_prof.institution
               AND e.flg_ehr != g_flg_ehr
               AND e.flg_status != g_epis_canc
               AND e.id_episode = ei.id_episode
               AND ei.flg_sch_status != g_sched_canc
               AND ei.id_schedule = sp.id_schedule
               AND sp.id_software = i_prof.software
               AND ei.id_dep_clin_serv = pdcs.id_dep_clin_serv
               AND pdcs.id_professional = i_prof.id
               AND pdcs.flg_status = g_selected
               AND sp.id_schedule = sg.id_schedule
               AND sg.id_patient = pat.id_patient
               AND e.id_clinical_service = cs.id_clinical_service
               AND e.id_episode = gt.id_episode
               AND e.flg_status <> g_epis_inactive
             ORDER BY sp.dt_target_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'GET_AUX_SCHEDULE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_sched);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION information_active
    (
        i_lang      IN language.id_language%TYPE,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_active    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Grelha do informativo, para episódios activos
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_INSTIT - ID da instituição. se ñ for preenchido,
                                            considera-se o valor em SYS_CONFIG (opcional)
                                 I_EPIS_TYPE - Tipo de episódio (CE, URG, ...)
                     I_PROF - prof q acede
                        SAIDA:   O_ACTIVE - array de epis. activos
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/04/07
          ALTERAÇÃO: CRS 2006/07/20 Excluir episódios cancelados
                     ASM 2007-03-26 Adicionado um campo de saída no cursor: "Departamento - Especialidade"
        
          NOTAS: Nesta grelha visualizam-se os agendamentos do dia:
                 - agendados ou efectivados, s/ alta administrativa
        *********************************************************************************/
    BEGIN
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz := current_timestamp;
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'GET CURSOR';
        OPEN o_active FOR
            SELECT ei.id_schedule,
                   sg.id_patient,
                   cr.num_clin_record,
                   epis.id_episode,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) photo,
                   --                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                   -- JS, 2007-09-11 - Timezone
                   pk_date_utils.date_char_hour_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_target,
                   nvl(p1.nick_name, p.nick_name) nick_name,
                   sp.flg_state,
                   -- JS, 2007-09-11 - Timezone
                   pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_order,
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_sched,
                   -- JS, 2007-09-11 - Timezone
                   g_sysdate_char dt_server,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_translation.get_translation(i_lang, dept.code_dept) || ' - ' ||
                   pk_translation.get_translation(i_lang, d.code_department) || ' - ' ||
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) dept
              FROM schedule_outp sp,
                   sch_group sg,
                   patient pat,
                   clinical_service cs,
                   dept dept,
                   department d,
                   professional p,
                   clin_record cr,
                   epis_info ei,
                   (SELECT *
                      FROM episode
                     WHERE flg_status = g_epis_active) epis,
                   professional p1,
                   sys_domain sd
            -- JS, 2007-09-11 - Timezone
             WHERE sp.dt_target_tstz BETWEEN pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz) AND
                   pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz) + INTERVAL '1'
             DAY
               AND sp.flg_state != g_sched_adm_disch
               AND p.id_professional(+) = ei.sch_prof_outp_id_prof
               AND ei.flg_sch_status != g_sched_canc
               AND ei.id_schedule = sp.id_schedule
               AND ei.id_instit_requested = i_prof.institution
               AND sg.id_schedule = sp.id_schedule
               AND pat.id_patient = sg.id_patient
               AND cs.id_clinical_service = epis.id_cs_requested
               AND d.id_department = epis.id_department_requested
               AND d.id_dept = dept.id_dept
               AND cr.id_patient = pat.id_patient
               AND cr.id_institution = i_prof.institution
               AND p1.id_professional(+) = ei.id_professional
               AND epis.id_episode(+) = ei.id_episode
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr != g_flg_ehr
               AND sd.code_domain(+) = 'SCHEDULE_OUTP.FLG_SCHED'
               AND sd.val(+) = sp.flg_sched
               AND sd.domain_owner(+) = pk_sysdomain.k_default_schema
               AND sd.id_language(+) = i_lang
            UNION --episódios sem agendamento (para visualizar episódios de urgência, internamento, etc) --SS 2007/04/26
            SELECT NULL id_schedule,
                   v.id_patient,
                   NULL num_clin_record,
                   epis.id_episode,
                   pk_patient.get_pat_name(i_lang, i_prof, v.id_patient, epis.id_episode, NULL) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, v.id_patient, epis.id_episode, NULL) name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, v.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, v.id_patient) pat_nd_icon,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, v.id_patient, epis.id_episode, NULL) photo,
                   --                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                   -- JS, 2007-09-11 - Timezone
                   pk_date_utils.date_char_hour_tsz(i_lang, v.dt_begin_tstz, i_prof.institution, i_prof.software) dt_target,
                   p1.nick_name,
                   NULL flg_state,
                   -- JS, 2007-09-11 - Timezone
                   pk_date_utils.date_send_tsz(i_lang, v.dt_begin_tstz, i_prof) dt_order,
                   NULL img_sched,
                   -- JS, 2007-09-11 - Timezone
                   g_sysdate_char dt_server,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_translation.get_translation(i_lang, dept.code_dept) || ' - ' ||
                   pk_translation.get_translation(i_lang, d.code_department) || ' - ' ||
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) dept
              FROM patient pat,
                   clinical_service cs,
                   dept dept,
                   department d,
                   epis_info ei,
                   visit v,
                   (SELECT *
                      FROM episode
                     WHERE flg_status = g_epis_active) epis,
                   professional p1
             WHERE v.id_institution = i_prof.institution
               AND v.id_visit = epis.id_visit
               AND pat.id_patient = v.id_patient
               AND epis.id_episode = ei.id_episode
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr != g_flg_ehr
               AND ei.id_schedule IS NULL
               AND cs.id_clinical_service = epis.id_clinical_service
               AND epis.id_department = d.id_department
               AND d.id_dept = dept.id_dept(+)
               AND p1.id_professional = ei.id_professional
             ORDER BY dt_order;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'INFORMATION_ACTIVE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_active);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION information_active_det
    (
        i_lang   IN language.id_language%TYPE,
        i_epis   IN episode.id_episode%TYPE,
        i_pat    IN patient.id_patient%TYPE,
        i_prof   IN profissional,
        o_active OUT pk_types.cursor_type,
        o_titles OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Info do episódio seleccionado
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                   I_EPIS - ID do episódio
                 I_PROF - prof q acede
                        SAIDA:   O_ACTIVE - info
                                 O_ERROR - erro
        
          CRIAÇÃO: SS 2005/12/26
          NOTAS:
        *********************************************************************************/
        CURSOR c_epis IS
            SELECT id_episode
              FROM episode e
             WHERE e.id_patient = i_pat
               AND e.flg_status = g_epis_active;
    
        CURSOR c_sched(l_epis IN episode.id_episode%TYPE) IS
            SELECT 'Y'
              FROM epis_info
             WHERE id_episode = l_epis
               AND id_schedule IS NOT NULL;
    
        l_epis       episode.id_episode%TYPE;
        l_exist_sch  VARCHAR2(1);
        l_id_episode episode.id_episode%TYPE;
    BEGIN
    
        OPEN c_epis;
        FETCH c_epis
            INTO l_epis;
        CLOSE c_epis;
    
        l_id_episode := nvl(i_epis, l_epis);
    
        g_error := 'OPEN C_SCHED';
        OPEN c_sched(l_id_episode);
        FETCH c_sched
            INTO l_exist_sch;
        g_found := c_sched%FOUND;
        CLOSE c_sched;
    
        IF g_found
        THEN
            g_error := 'GET CURSOR O_TITLES';
            OPEN o_titles FOR
                SELECT pk_message.get_message(i_lang, 'GRID_INFO_T010') t_dt_target,
                       pk_message.get_message(i_lang, 'GRID_INFO_T011') t_nick_name,
                       pk_message.get_message(i_lang, 'GRID_INFO_T012') t_cons_type,
                       pk_message.get_message(i_lang, 'GRID_INFO_T013') t_dt_efectiv,
                       pk_message.get_message(i_lang, 'GRID_INFO_T014') t_desc_room,
                       pk_message.get_message(i_lang, 'GRID_INFO_T015') t_flg_state,
                       pk_message.get_message(i_lang, 'GRID_INFO_T017') t_analysis,
                       pk_message.get_message(i_lang, 'GRID_INFO_T016') t_exam,
                       pk_message.get_message(i_lang, 'GRID_INFO_T018') t_drug
                  FROM dual;
        
            g_error := 'GET CURSOR O_ACTIVE; EXIST SCHEDULE';
            OPEN o_active FOR
            -- JS, 2007-09-11 - Timezone
            -- SELECT pk_date_utils.date_char(i_lang, sp.dt_target, i_prof.institution, i_prof.software) dt_target,
                SELECT pk_date_utils.date_char_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_target,
                       p.nick_name,
                       --                       pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                       pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                       -- JS, 2007-09-11 - Timezone
                       -- pk_date_utils.date_char(i_lang, e.dt_begin, i_prof.institution, i_prof.software) dt_efectiv,
                       pk_date_utils.date_char_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                       pk_sysdomain.get_domain('SCHEDULE_OUTP.FLG_STATE', sp.flg_state, i_lang) flg_state,
                       decode(ar.id_episode,
                              NULL,
                              pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                              pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) analysis,
                       decode(er.id_episode,
                              NULL,
                              pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                              pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) exam,
                       pk_sysdomain.get_domain('YES_NO',
                                               pk_api_pfh_in.check_epis_presc(i_lang, i_prof, i_pat, e.id_episode),
                                               i_lang) drug
                  FROM schedule_outp sp,
                       professional p,
                       episode e,
                       epis_info ei,
                       clinical_service cs,
                       room r,
                       (SELECT DISTINCT id_episode
                          FROM analysis_req
                         WHERE id_episode = l_id_episode
                           AND flg_time = g_flg_time_e
                           AND flg_status NOT IN (g_analy_req_res, g_analy_req_canc)) ar,
                       (SELECT DISTINCT id_episode
                          FROM exam_req
                         WHERE id_episode = l_id_episode
                           AND flg_time = g_flg_time_e
                           AND flg_status NOT IN (g_exam_req_resu, g_exam_req_canc)) er
                 WHERE e.id_episode = l_id_episode
                   AND e.flg_status = g_epis_active
                   AND ei.id_episode = e.id_episode
                   AND ei.flg_sch_status != g_sched_canc
                   AND sp.id_schedule = ei.id_schedule
                   AND p.id_professional(+) = ei.sch_prof_outp_id_prof
                   AND cs.id_clinical_service = e.id_clinical_service
                   AND r.id_room = ei.id_room
                   AND ar.id_episode(+) = e.id_episode
                   AND er.id_episode(+) = e.id_episode;
        ELSE
            g_error := 'GET CURSOR O_TITLES';
            OPEN o_titles FOR
                SELECT pk_message.get_message(i_lang, 'GRID_INFO_T010') t_dt_target,
                       pk_message.get_message(i_lang, 'GRID_INFO_T011') t_nick_name,
                       pk_message.get_message(i_lang, 'GRID_INFO_T021') t_cons_type,
                       pk_message.get_message(i_lang, 'GRID_INFO_T022') t_dt_efectiv,
                       pk_message.get_message(i_lang, 'GRID_INFO_T014') t_desc_room,
                       pk_message.get_message(i_lang, 'GRID_INFO_T015') t_flg_state,
                       pk_message.get_message(i_lang, 'GRID_INFO_T017') t_analysis,
                       pk_message.get_message(i_lang, 'GRID_INFO_T016') t_exam,
                       pk_message.get_message(i_lang, 'GRID_INFO_T018') t_drug
                  FROM dual;
        
            g_error := 'GET CURSOR O_ACTIVE; NO SCHEDULE';
            OPEN o_active FOR
                SELECT pk_message.get_message(i_lang, 'COMMON_M018') dt_target,
                       p.nick_name,
                       --                       pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                       pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                       -- JS, 2007-09-11 - Timezone
                       -- pk_date_utils.date_char(i_lang, e.dt_begin, i_prof.institution, i_prof.software) dt_efectiv,
                       pk_date_utils.date_char_tsz(i_lang, e.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                       nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                       pk_message.get_message(i_lang, 'COMMON_M018') flg_state,
                       decode(ar.id_episode,
                              NULL,
                              pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                              pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) analysis,
                       decode(er.id_episode,
                              NULL,
                              pk_sysdomain.get_domain('YES_NO', g_no, i_lang),
                              pk_sysdomain.get_domain('YES_NO', g_yes, i_lang)) exam,
                       pk_sysdomain.get_domain('YES_NO',
                                               pk_api_pfh_in.check_epis_presc(i_lang, i_prof, i_pat, e.id_episode),
                                               i_lang) drug
                  FROM professional p,
                       episode e,
                       epis_info ei,
                       clinical_service cs,
                       room r,
                       (SELECT DISTINCT id_episode
                          FROM analysis_req
                         WHERE id_episode = l_id_episode
                           AND flg_time = g_flg_time_e
                           AND flg_status NOT IN (g_analy_req_res, g_analy_req_canc)) ar,
                       (SELECT DISTINCT id_episode
                          FROM exam_req
                         WHERE id_episode = l_id_episode
                           AND flg_time = g_flg_time_e
                           AND flg_status NOT IN (g_exam_req_resu, g_exam_req_canc)) er
                 WHERE e.id_episode = l_id_episode
                   AND e.flg_status = g_epis_active
                   AND ei.id_professional = p.id_professional
                   AND ei.id_episode = e.id_episode
                   AND cs.id_clinical_service = e.id_clinical_service
                   AND r.id_room = ei.id_room
                   AND ar.id_episode(+) = e.id_episode
                   AND er.id_episode(+) = e.id_episode;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'INFORMATION_ACTIVE_DET');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_active);
                pk_types.open_my_cursor(o_titles);
                RETURN FALSE;
            
            END;
        
    END;

    FUNCTION information_inactive
    (
        i_lang      IN language.id_language%TYPE,
        i_dt        IN VARCHAR2,
        i_instit    IN schedule.id_instit_requested%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        o_inactive  OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Grelha do informativo, para episódios inactivos (fechados na
                  data indicada)
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                   I_DT - data
                                 I_INSTIT - ID da instituição. se ñ for preenchido,
                                            considera-se o valor em SYS_CONFIG (opcional)
                                 I_EPIS_TYPE - Tipo de episódio (CE, URG, ...)
                 I_PROF - prof q acede
                        SAIDA:   O_INACTIVE - array de epis. inactivos
                                 O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/04/07
          ALTERAÇÃO: ASM 2007-03-26 Adicionado um campo de saída no cursor: "Departamento - Especialidade"
        
          NOTAS: Nesta grelha visualizam-se os agendamentos do dia:
               - c/ alta médica e administrativa
        *********************************************************************************/
    BEGIN
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz := current_timestamp;
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'GET CURSOR';
        OPEN o_inactive FOR
            SELECT ei.id_schedule,
                   sg.id_patient,
                   cr.num_clin_record,
                   p.nick_name,
                   epis.id_episode,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) photo,
                   --                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                   -- JS, 2007-09-11 - Timezone
                   pk_date_utils.dt_chr_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target_day,
                   pk_date_utils.date_char_hour_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_target_hour,
                   pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_ord1,
                   g_sysdate_char dt_server,
                   decode(instr(dep1.flg_type, 'I'),
                          '',
                          '',
                          pk_translation.get_translation(i_lang, cs1.code_clinical_service)) internment, --SS 2006/11/24
                   pk_translation.get_translation(i_lang, drn.code_discharge_reason) || ': ' ||
                   decode(drt.id_discharge_dest,
                          '',
                          decode(drt.id_dep_clin_serv,
                                 '',
                                 decode(drt.id_institution,
                                        '',
                                        '',
                                        pk_translation.get_translation(i_lang, inst.code_institution)),
                                 pk_translation.get_translation(i_lang, dep1.code_department) || ' - ' ||
                                 pk_translation.get_translation(i_lang, cs1.code_clinical_service)),
                          pk_translation.get_translation(i_lang, ddn.code_discharge_dest)) disch_reason,
                   pk_translation.get_translation(i_lang, dept.code_dept) || ' - ' ||
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) dept
              FROM schedule_outp    sp,
                   sch_group        sg,
                   patient          pat,
                   clinical_service cs,
                   professional     p,
                   clin_record      cr,
                   epis_info        ei,
                   disch_reas_dest  drt,
                   dep_clin_serv    dcs1,
                   department       dep1,
                   dept             dept,
                   clinical_service cs1,
                   episode          epis,
                   discharge_reason drn,
                   discharge_dest   ddn,
                   institution      inst
            -- JS, 2007-09-11 - Timezone
             WHERE sp.dt_target_tstz BETWEEN
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                    nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                        g_sysdate_tstz)) AND
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                    nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                        g_sysdate_tstz)) + INTERVAL '1'
             DAY
               AND ei.id_schedule = sp.id_schedule
               AND ei.id_instit_requested = i_prof.institution
               AND ei.flg_sch_status != g_sched_canc
               AND sg.id_schedule = sp.id_schedule
               AND pat.id_patient = sg.id_patient
               AND cs.id_clinical_service = epis.id_cs_requested
               AND dept.id_dept = epis.id_dept_requested
               AND cr.id_patient = pat.id_patient
               AND cr.id_institution = i_prof.institution
               AND p.id_professional(+) = ei.id_professional
                  -- JS, 2007-09-11 - Timezone
               AND nvl(ei.flg_dsch_status, g_flg_status_a) != g_flg_status_c
               AND drt.id_disch_reas_dest = ei.id_disch_reas_dest
               AND dcs1.id_dep_clin_serv(+) = drt.id_dep_clin_serv
               AND cs1.id_clinical_service(+) = dcs1.id_clinical_service
               AND dep1.id_department(+) = dcs1.id_department
               AND epis.id_episode = ei.id_episode
               AND epis.flg_status = g_epis_inactive
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr != g_flg_ehr
               AND drn.id_discharge_reason = drt.id_discharge_reason
               AND ddn.id_discharge_dest(+) = drt.id_discharge_dest
               AND inst.id_institution(+) = drt.id_institution
            UNION
            SELECT NULL id_schedule,
                   v.id_patient,
                   cr.num_clin_record,
                   p.nick_name,
                   epis.id_episode,
                   pk_patient.get_pat_name(i_lang, i_prof, v.id_patient, epis.id_episode, NULL) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, v.id_patient, epis.id_episode, NULL) name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, v.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, v.id_patient) pat_nd_icon,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, v.id_patient, epis.id_episode, NULL) photo,
                   --                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                   -- JS, 2007-09-11 - Timezone
                   pk_date_utils.dt_chr_tsz(i_lang, v.dt_begin_tstz, i_prof) dt_target_day,
                   pk_date_utils.date_char_hour_tsz(i_lang, v.dt_begin_tstz, i_prof.institution, i_prof.software) dt_target_hour,
                   pk_date_utils.date_send_tsz(i_lang, v.dt_begin_tstz, i_prof) dt_ord1,
                   g_sysdate_char dt_server,
                   decode(instr(dep1.flg_type, 'I'),
                          '',
                          '',
                          pk_translation.get_translation(i_lang, cs1.code_clinical_service)) internment, --SS 2006/11/24
                   
                   pk_translation.get_translation(i_lang, drn.code_discharge_reason) || ': ' ||
                   decode(drt.id_discharge_dest,
                          '',
                          decode(drt.id_dep_clin_serv,
                                 '',
                                 decode(drt.id_institution,
                                        '',
                                        '',
                                        pk_translation.get_translation(i_lang, inst.code_institution)),
                                 pk_translation.get_translation(i_lang, dep1.code_department) || ' - ' ||
                                 pk_translation.get_translation(i_lang, cs1.code_clinical_service)),
                          pk_translation.get_translation(i_lang, ddn.code_discharge_dest)) disch_reason,
                   
                   pk_translation.get_translation(i_lang, dept.code_dept) || ' - ' ||
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) dept
              FROM patient          pat,
                   clinical_service cs,
                   professional     p,
                   clin_record      cr,
                   epis_info        ei,
                   disch_reas_dest  drt,
                   dep_clin_serv    dcs1,
                   department       dep1,
                   dept             dept,
                   clinical_service cs1,
                   episode          epis,
                   visit            v,
                   discharge_reason drn,
                   discharge_dest   ddn,
                   institution      inst
             WHERE v.id_institution = i_prof.institution
               AND pat.id_patient = v.id_patient
               AND epis.id_visit = v.id_visit
               AND cs.id_clinical_service = epis.id_clinical_service
                  --AND epis.id_department = dep.id_department
               AND dept.id_dept = epis.id_dept
               AND cr.id_patient = pat.id_patient
               AND cr.id_institution = i_prof.institution
               AND ei.id_schedule IS NULL
               AND p.id_professional(+) = ei.id_professional
               AND ei.flg_dsch_status = g_flg_status_a
               AND drt.id_disch_reas_dest = ei.id_disch_reas_dest
               AND dcs1.id_dep_clin_serv(+) = drt.id_dep_clin_serv
               AND cs1.id_clinical_service(+) = dcs1.id_clinical_service
               AND dep1.id_department(+) = dcs1.id_department
               AND epis.id_episode = ei.id_episode
               AND epis.flg_status = g_epis_inactive
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr != g_flg_ehr
               AND drn.id_discharge_reason = drt.id_discharge_reason
               AND ddn.id_discharge_dest(+) = drt.id_discharge_dest
               AND inst.id_institution(+) = drt.id_institution
             ORDER BY dt_ord1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'INFORMATION_INACTIVE');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_inactive);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION information_inactive_det
    (
        i_lang     IN language.id_language%TYPE,
        i_pat      IN patient.id_patient%TYPE,
        i_prof     IN profissional,
        o_inactive OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Episódios inactivos do paciente seleccionado
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                   I_PATIENT - ID do paciente
                 I_PROF - prof q acede
                        SAIDA:   O_INACTIVE - array de epis. inactivos
                                 O_ERROR - erro
        
          CRIAÇÃO: SS 2005/12/26
          NOTAS:
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR';
        OPEN o_inactive FOR
            SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_translation.get_translation(i_lang, drn.code_discharge_reason) || ': ' ||
                   decode(drt.id_discharge_dest,
                          '',
                          decode(drt.id_dep_clin_serv,
                                 '',
                                 decode(drt.id_institution,
                                        '',
                                        '',
                                        pk_translation.get_translation(i_lang, inst.code_institution)),
                                 pk_translation.get_translation(i_lang, dep.code_department) || ' - ' ||
                                 pk_translation.get_translation(i_lang, cs2.code_clinical_service)),
                          pk_translation.get_translation(i_lang, ddn.code_discharge_dest)) disch_reason,
                   -- JS, 2007-09-11 - Timezone
                   pk_date_utils.dt_chr_tsz(i_lang, d.dt_med_tstz, i_prof) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, d.dt_med_tstz, i_prof.institution, i_prof.software) hour_target,
                   pk_date_utils.dt_chr_tsz(i_lang,
                                            pk_discharge_core.get_dt_admin(i_lang,
                                                                           i_prof,
                                                                           NULL,
                                                                           d.flg_status_adm,
                                                                           d.dt_admin_tstz),
                                            i_prof) dt_target,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    pk_discharge_core.get_dt_admin(i_lang,
                                                                                   i_prof,
                                                                                   NULL,
                                                                                   d.flg_status_adm,
                                                                                   d.dt_admin_tstz),
                                                    i_prof.institution,
                                                    i_prof.software) hr_target,
                   pk_date_utils.date_send_tsz(i_lang, d.dt_med_tstz, i_prof) dt_ord1,
                   pk_date_utils.date_send_tsz(i_lang,
                                               pk_discharge_core.get_dt_admin(i_lang,
                                                                              i_prof,
                                                                              NULL,
                                                                              d.flg_status_adm,
                                                                              d.dt_admin_tstz),
                                               i_prof) dt_ord2
              FROM episode          e,
                   clinical_service cs,
                   clinical_service cs2,
                   discharge        d,
                   disch_reas_dest  drt,
                   discharge_reason drn,
                   discharge_dest   ddn,
                   department       dep,
                   institution      inst,
                   dep_clin_serv    dcs2
             WHERE e.id_patient = i_pat
               AND e.flg_status = g_epis_inactive
               AND cs.id_clinical_service = e.id_clinical_service
               AND d.id_episode = e.id_episode
                  -- JS, 2007-09-11 - Timezone
               AND d.dt_cancel_tstz IS NULL
               AND drt.id_disch_reas_dest = d.id_disch_reas_dest
               AND drn.id_discharge_reason = drt.id_discharge_reason
               AND ddn.id_discharge_dest(+) = drt.id_discharge_dest
               AND dcs2.id_dep_clin_serv(+) = drt.id_dep_clin_serv
               AND dep.id_department(+) = dcs2.id_department
               AND cs2.id_clinical_service(+) = dcs2.id_clinical_service
               AND inst.id_institution(+) = drt.id_institution;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'INFORMATION_INACTIVE_DET');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_inactive);
                RETURN FALSE;
            
            END;
    END;

    /************************************************************************************************************ 
    *  Obtem a lista de estados possíveis de um paciente nas consultas de enfermagem    
    *
    * @param      i_lang           language
    * @param      i_prof           professional
    * @param      i_id_schedule    Id do agendamento
    *    
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/05/26
    ***********************************************************************************************************/

    FUNCTION get_pat_nurse_status_list_int
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_enable_actions IN VARCHAR2,
        o_status         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cat              category.flg_type%TYPE;
        l_episode_registry sys_config.value%TYPE;
        l_schd_outp_state  schedule_outp.flg_state%TYPE := NULL;
        l_nurse_register   sys_config.value%TYPE;
        l_epis_type        schedule_outp.id_epis_type%TYPE;
        l_episode_read     sys_config.value%TYPE;
        l_is_contact       VARCHAR2(1 CHAR);
        l_id_patient       patient.id_patient%TYPE;
        l_can_cancel       VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'CALL pk_prof_utils.get_category';
        l_cat   := pk_prof_utils.get_category(i_lang, i_prof);
    
        g_error := 'GET SYS_CONFIG NURSE_EPISODE_REGISTRY';
        IF l_cat = g_flg_nurse
        THEN
            l_episode_registry := pk_sysconfig.get_config('NURSE_EPISODE_REGISTRY', i_prof);
            l_nurse_register   := pk_sysconfig.get_config('NURSE_CAN_REGISTER', i_prof);
        ELSIF l_cat = g_flg_doctor
        THEN
            l_episode_registry := pk_sysconfig.get_config('DOCTOR_NURSE_APPOINTMENT_REGISTRY', i_prof);
        
        ELSE
            l_episode_registry := pk_sysconfig.get_config('ADMIN_NURSE_EPISODE_REGISTRY', i_prof);
        END IF;
        l_can_cancel      := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                   i_prof        => i_prof,
                                                                   i_intern_name => 'CANCEL_EPISODE');
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        g_error := 'CALC EPISODE CURRENT STATUS';
        SELECT decode(s.flg_status, 'C', 'C', get_schedule_real_state(so.flg_state, e.flg_ehr)), so.id_epis_type
          INTO l_schd_outp_state, l_epis_type
          FROM schedule s
          JOIN schedule_outp so
            ON so.id_schedule = s.id_schedule
          LEFT JOIN epis_info ei
            ON s.id_schedule = ei.id_schedule
          LEFT JOIN episode e
            ON ei.id_episode = e.id_episode
         WHERE s.id_schedule = i_id_schedule;
    
        IF l_cat = g_flg_nurse
        THEN
            IF l_epis_type = g_epis_type_nurse
               AND l_episode_registry = pk_alert_constant.g_yes
            THEN
                l_episode_registry := pk_alert_constant.g_yes;
            ELSIF l_epis_type <> g_epis_type_nurse
                  AND l_nurse_register = pk_alert_constant.g_yes
            THEN
                l_episode_registry := pk_alert_constant.g_yes;
            ELSE
                l_episode_registry := pk_alert_constant.g_no;
            END IF;
        ELSIF l_cat = g_flg_doctor
        THEN
            l_episode_read := pk_sysconfig.get_config('DOCTOR_NURSE_APPOINTMENT_ACCESS', i_prof);
            IF l_episode_read = pk_alert_constant.g_no
            THEN
                l_episode_registry := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        BEGIN
            SELECT sg.id_patient
              INTO l_id_patient
              FROM sch_group sg
             WHERE sg.id_schedule = i_id_schedule;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_id_patient := -1;
        END;
        l_is_contact := pk_adt.is_contact(i_lang => i_lang, i_prof => i_prof, i_patient => l_id_patient);
        --Obtem os estados possíveis de um paciente
        g_error := 'GET PAT STATUS CURSOR';
        OPEN o_status FOR
            SELECT decode(l_episode_registry,
                          pk_alert_constant.g_yes,
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
                   --lg conjuga estado com a realização/cancelamento de efectivação sd.desc_val LABEL,
                   sd.val      data,
                   sd.img_name icon,
                   -- lg flg_action tells if an action shoud be available in the current state.
                   decode(i_enable_actions,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_no,
                          decode(l_episode_registry,
                                 pk_alert_constant.g_yes,
                                 decode(sd.val,
                                        g_flg_no_show,
                                        decode(l_schd_outp_state,
                                               g_sched_scheduled,
                                               pk_alert_constant.g_yes,
                                               pk_alert_constant.g_no),
                                        g_sched_scheduled,
                                        decode(l_schd_outp_state,
                                               g_sched_efectiv,
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
                                        g_sched_cons,
                                        decode(l_schd_outp_state,
                                               g_sched_scheduled,
                                               pk_alert_constant.g_yes,
                                               pk_alert_constant.g_no),
                                        g_sched_canc,
                                        decode(l_can_cancel,
                                               pk_alert_constant.g_yes,
                                               decode(l_schd_outp_state,
                                                      g_sched_scheduled,
                                                      pk_alert_constant.g_yes,
                                                      pk_alert_constant.g_no),
                                               pk_alert_constant.g_no),
                                        pk_alert_constant.g_no),
                                 pk_alert_constant.g_no)) flg_action
              FROM sys_domain sd
             WHERE sd.code_domain = g_schdl_nurse_state_domain
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
            --               AND sd.val IN (g_sched_scheduled, g_sched_efectiv, g_sched_cons, g_sched_med_disch, g_sched_adm_disch,
            --                  g_sched_nurse)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PAT_NURSE_STATUS_LIST_INT',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_status);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pat_nurse_status_list_int;

    FUNCTION get_pat_status_list_int
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_schedule    IN schedule.id_schedule%TYPE,
        i_enable_actions IN VARCHAR2,
        i_id_patient     IN patient.id_patient%TYPE,
        o_status         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Obtem a lista de estados possíveis de um paciente
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_FLG_STATUS - Estado actual do paciente
                                 i_id_schedule - Id do agendamento
                         SAIDA:  O_STATUS - Lista de salas
                                 O_ERROR - erro
        
          CRIAÇÃO: ASM 2007/01/09
        
          NOTAS: LG 2007 Mar 28 Conjuga os estados com a acção de realização/cancelamento da efectivação para o private practice
        *********************************************************************************/
    
        CURSOR c_exists_discharge IS
            SELECT d.dt_med_tstz
              FROM discharge d
             WHERE d.id_episode = (SELECT id_episode
                                     FROM epis_info ei
                                    WHERE ei.id_schedule = i_id_schedule)
               AND d.flg_status = g_discharge_active;
        r_exists_discharge c_exists_discharge%ROWTYPE;
    
        l_episode_registry sys_config.value%TYPE;
        l_schd_outp_state  schedule_outp.flg_state%TYPE := NULL;
        l_schd_pre_nurse   schedule_outp.flg_state%TYPE := NULL;
        l_exists_discharge VARCHAR2(1) := 'N';
    
        l_config_software sys_config.value%TYPE;
        l_sw_id_care      sys_config.value%TYPE;
    
        l_flg_cat category.flg_type%TYPE;
    
        l_show_sign_off sys_config.value%TYPE;
    
        l_nurse_register     sys_config.value%TYPE;
        l_epis_type          schedule_outp.id_epis_type%TYPE;
        l_is_contact         VARCHAR2(1 CHAR);
        l_flg_status         episode.flg_status%TYPE;
        l_flg_ehr            episode.flg_ehr%TYPE;
        l_inactivate_options episode.flg_status%TYPE := pk_alert_constant.g_no;
    BEGIN
        g_error := 'GET SYS_CONFIG DOCTOR_EPISODE_REGISTRY';
    
        l_flg_cat := pk_prof_utils.get_category(i_lang, i_prof);
        IF l_flg_cat = g_flg_nurse
        THEN
            l_episode_registry := pk_sysconfig.get_config('NURSE_CAN_REGISTER', i_prof); -- CONSULTAS MÉDICAS
            l_nurse_register   := pk_sysconfig.get_config('NURSE_EPISODE_REGISTRY', i_prof); -- CONSULTAS DE ENFERMAGEM
        ELSE
            l_episode_registry := pk_sysconfig.get_config('DOCTOR_EPISODE_REGISTRY', i_prof);
        END IF;
    
        l_show_sign_off := nvl(pk_sysconfig.get_config('SHOW_SIGNOFF', i_prof), pk_alert_constant.g_no);
    
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        l_is_contact := pk_adt.is_contact(i_lang, i_prof, i_id_patient);
    
        g_error := 'CALC EPISODE CURRENT STATUS';
        SELECT decode(s.flg_status, g_sched_canc, g_sched_canc, get_schedule_real_state(so.flg_state, e.flg_ehr)),
               pk_grid.get_pre_nurse_appointment(i_lang,
                                                 i_prof,
                                                 ei.id_dep_clin_serv,
                                                 e.flg_ehr,
                                                 get_schedule_real_state(so.flg_state, e.flg_ehr),
                                                 so.id_epis_type),
               so.id_epis_type,
               e.flg_status,
               e.flg_ehr
          INTO l_schd_outp_state, l_schd_pre_nurse, l_epis_type, l_flg_status, l_flg_ehr
          FROM schedule_outp so
          LEFT JOIN epis_info ei
            ON so.id_schedule = ei.id_schedule
          LEFT JOIN schedule s
            ON so.id_schedule = s.id_schedule
          JOIN sch_group sg
            ON sg.id_schedule = s.id_schedule
          LEFT JOIN episode e
            ON (ei.id_episode = e.id_episode AND ei.id_patient = sg.id_patient)
         WHERE so.id_schedule = i_id_schedule
              
           AND sg.id_patient = i_id_patient;
        IF l_flg_cat = g_flg_nurse
        THEN
            IF l_epis_type = g_epis_type_nurse
               AND l_nurse_register = 'Y'
            THEN
                l_episode_registry := 'Y';
            ELSIF l_epis_type <> g_epis_type_nurse
                  AND l_episode_registry = 'Y'
            THEN
                l_episode_registry := 'Y';
            ELSE
                l_episode_registry := 'N';
            END IF;
        END IF;
    
        IF l_flg_status = pk_alert_constant.g_inactive
           AND l_flg_ehr = pk_visit.g_flg_ehr_s
        THEN
            l_inactivate_options := pk_alert_constant.g_yes;
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
        IF l_config_software = i_prof.software
           OR i_prof.software = pk_alert_constant.g_soft_psychologist
           OR i_prof.software = pk_alert_constant.g_soft_resptherap
           OR (i_prof.software = pk_alert_constant.g_soft_rehab AND
           l_epis_type = pk_alert_constant.g_epis_type_cdc_appointment)
           OR i_prof.software = pk_alert_constant.g_soft_home_care
        THEN
            g_error := 'GET PAT STATUS CURSOR';
            OPEN o_status FOR
                SELECT decode(l_episode_registry,
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
                              decode(l_epis_type,
                                     pk_alert_constant.g_epis_type_resp_therapist,
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
                                     sd.desc_val)) label,
                       --lg conjuga estado com a realização/cancelamento de efectivação sd.desc_val LABEL,
                       sd.val      data,
                       sd.img_name icon,
                       -- lg flg_action tells if an action shoud be available in the current state.
                       decode(l_inactivate_options,
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_no,
                              decode(i_enable_actions,
                                     pk_alert_constant.g_no,
                                     pk_alert_constant.g_no,
                                     decode(sd.val,
                                            g_flg_no_show,
                                            decode(l_schd_outp_state, g_sched_scheduled, 'Y', 'N'),
                                            g_sched_nurse_end,
                                            decode(l_schd_outp_state, g_sched_nurse, 'Y', g_sched_nurse_prev, 'Y', 'N'),
                                            g_sched_nurse_prev,
                                            decode(l_schd_outp_state, g_sched_cons, 'Y', 'N'),
                                            pk_exam_constant.g_end_technician,
                                            decode(l_schd_outp_state,
                                                   pk_exam_constant.g_in_technician,
                                                   'Y',
                                                   pk_exam_constant.g_waiting_technician,
                                                   'Y',
                                                   'N'),
                                            pk_exam_constant.g_waiting_technician,
                                            decode(l_schd_outp_state, g_sched_cons, 'Y', 'N'),
                                            g_sched_cons,
                                            decode(l_schd_outp_state,
                                                   pk_exam_constant.g_end_technician,
                                                   pk_alert_constant.g_yes,
                                                   g_sched_efectiv,
                                                   decode(l_epis_type,
                                                          pk_alert_constant.g_epis_type_psychologist,
                                                          pk_alert_constant.g_yes,
                                                          pk_alert_constant.g_epis_type_resp_therapist,
                                                          pk_alert_constant.g_yes,
                                                          pk_alert_constant.g_epis_type_cdc_appointment,
                                                          pk_alert_constant.g_yes,
                                                          pk_alert_constant.g_epis_type_dietitian,
                                                          pk_alert_constant.g_yes,
                                                          pk_alert_constant.g_no),
                                                   pk_alert_constant.g_no),
                                            g_shed_discharge_med,
                                            decode(l_schd_outp_state,
                                                   g_sched_cons,
                                                   decode(l_exists_discharge, 'Y', 'Y', 'N'),
                                                   'N'),
                                            g_sched_rt_disch,
                                            decode(l_schd_outp_state,
                                                   g_sched_cons,
                                                   decode(l_exists_discharge, 'Y', 'Y', 'N'),
                                                   'N'),
                                            decode(l_episode_registry,
                                                   'Y',
                                                   decode(sd.val,
                                                          g_sched_scheduled,
                                                          decode(l_schd_outp_state, g_sched_efectiv, 'Y', 'N'),
                                                          g_sched_efectiv,
                                                          decode(l_is_contact,
                                                                 pk_alert_constant.g_yes,
                                                                 pk_alert_constant.g_no,
                                                                 decode(l_schd_outp_state, g_sched_scheduled, 'Y', 'N')),
                                                          'N'),
                                                   decode(l_epis_type,
                                                          pk_alert_constant.g_epis_type_resp_therapist,
                                                          decode(sd.val,
                                                                 g_sched_scheduled,
                                                                 decode(l_schd_outp_state, g_sched_efectiv, 'Y', 'N'),
                                                                 g_sched_efectiv,
                                                                 decode(l_is_contact,
                                                                        pk_alert_constant.g_yes,
                                                                        pk_alert_constant.g_no,
                                                                        decode(l_schd_outp_state, g_sched_scheduled, 'Y', 'N')),
                                                                 'N')))))) flg_action
                  FROM sys_domain sd
                 WHERE sd.code_domain = g_schdl_outp_state_domain
                   AND sd.domain_owner = pk_sysdomain.k_default_schema
                   AND sd.id_language = i_lang
                   AND ((i_prof.software = pk_alert_constant.g_soft_psychologist AND
                       sd.val IN (g_sched_scheduled,
                                    g_sched_efectiv,
                                    g_sched_cons,
                                    'PY',
                                    g_sched_adm_disch,
                                    g_flg_no_show,
                                    g_sched_psycho_disch) AND
                       l_epis_type <> pk_alert_constant.g_epis_type_home_health_care) OR
                       (l_config_software = i_prof.software AND
                       sd.val IN (g_sched_scheduled,
                                    g_sched_efectiv,
                                    g_sched_cons,
                                    g_sched_nutri_disch,
                                    g_sched_adm_disch,
                                    g_flg_no_show) AND l_epis_type <> pk_alert_constant.g_epis_type_home_health_care) OR
                       (i_prof.software = pk_alert_constant.g_soft_resptherap AND
                       sd.val IN (g_sched_scheduled,
                                    g_sched_efectiv,
                                    g_sched_cons,
                                    g_sched_rt_disch,
                                    g_sched_adm_disch,
                                    g_flg_no_show) AND l_epis_type <> pk_alert_constant.g_epis_type_home_health_care) OR
                       (i_prof.software = pk_alert_constant.g_soft_rehab AND
                       l_epis_type = pk_alert_constant.g_epis_type_cdc_appointment AND
                       sd.val IN (g_sched_scheduled,
                                    g_sched_efectiv,
                                    g_sched_cons,
                                    g_sched_cdc_disch,
                                    g_sched_adm_disch,
                                    g_flg_no_show)) OR
                       (l_epis_type = pk_alert_constant.g_epis_type_home_health_care AND
                       sd.val IN (g_sched_scheduled, g_flg_no_show, g_sched_cons, g_sched_cdc_disch))
                       
                       )
                 ORDER BY rank;
        
        ELSIF i_prof.software = pk_alert_constant.g_soft_social
        THEN
            g_error := 'OPEN o_status - SOCIAL';
            OPEN o_status FOR
                SELECT decode(l_episode_registry,
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
                       decode(l_inactivate_options,
                              pk_alert_constant.g_yes,
                              pk_alert_constant.g_no,
                              decode(sd.val,
                                     g_sched_cons,
                                     'N',
                                     g_shed_discharge_med,
                                     decode(l_schd_outp_state,
                                            g_sched_cons,
                                            decode(l_exists_discharge, 'Y', 'Y', 'N'),
                                            'N'),
                                     g_flg_no_show,
                                     decode(l_schd_outp_state, g_sched_scheduled, 'Y', 'N'),
                                     decode(l_episode_registry,
                                            'Y',
                                            decode(sd.val,
                                                   g_sched_scheduled,
                                                   decode(l_schd_outp_state, g_sched_efectiv, 'Y', 'N'),
                                                   g_sched_efectiv,
                                                   decode(l_is_contact,
                                                          pk_alert_constant.g_yes,
                                                          pk_alert_constant.g_no,
                                                          decode(l_schd_outp_state, g_sched_scheduled, 'Y', 'N')),
                                                   'N'),
                                            'N'))) flg_action
                  FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_schdl_outp_state_domain, 0)) sd
                 WHERE ((sd.val IN
                       (g_sched_scheduled, g_sched_efectiv, g_sched_cons, g_sched_med_disch, g_sched_adm_disch) OR
                       (sd.val = pk_sign_off.g_sched_signoff_s AND l_show_sign_off = pk_alert_constant.g_yes)) AND
                       l_epis_type <> pk_alert_constant.g_epis_type_home_health_care)
                    OR (l_epis_type = pk_alert_constant.g_epis_type_home_health_care AND
                       sd.val IN (g_sched_scheduled, g_flg_no_show, g_sched_cons, g_sched_med_disch))
                 ORDER BY rank;
        ELSE
            l_sw_id_care := pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof);
            IF l_epis_type = g_epis_type_nurse
            THEN
                RETURN get_pat_nurse_status_list_int(i_lang           => i_lang,
                                                     i_prof           => i_prof,
                                                     i_id_schedule    => i_id_schedule,
                                                     i_enable_actions => pk_alert_constant.g_yes,
                                                     o_status         => o_status,
                                                     o_error          => o_error);
                NULL;
            ELSE
                g_error := 'GET PAT STATUS CURSOR';
                OPEN o_status FOR
                    SELECT decode(l_episode_registry,
                                  'Y',
                                  decode(sd.val,
                                         g_sched_scheduled,
                                         decode(l_schd_outp_state,
                                                g_sched_efectiv,
                                                decode(i_prof.software,
                                                       l_sw_id_care,
                                                       sd.desc_val,
                                                       pk_sysdomain.get_domain(g_schdl_outp_state_act_domain,
                                                                               sd.val,
                                                                               i_lang)),
                                                sd.desc_val),
                                         g_sched_efectiv,
                                         decode(l_schd_outp_state,
                                                g_sched_scheduled,
                                                pk_sysdomain.get_domain(g_schdl_outp_state_act_domain, sd.val, i_lang),
                                                sd.desc_val),
                                         sd.desc_val),
                                  sd.desc_val) label,
                           --lg conjuga estado com a realização/cancelamento de efectivação sd.desc_val LABEL,
                           sd.val      data,
                           sd.img_name icon,
                           -- lg flg_action tells if an action shoud be available in the current state.
                           decode(l_inactivate_options,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no,
                                  decode(i_enable_actions,
                                         pk_alert_constant.g_no,
                                         pk_alert_constant.g_no,
                                         decode(sd.val,
                                                g_flg_no_show,
                                                decode(l_schd_outp_state, g_sched_scheduled, 'Y', 'N'),
                                                g_sched_nurse_end,
                                                decode(l_schd_outp_state,
                                                       g_sched_nurse,
                                                       'Y',
                                                       g_sched_nurse_prev,
                                                       'Y',
                                                       g_sched_efectiv,
                                                       decode(l_schd_pre_nurse,
                                                              g_sched_nurse_prev,
                                                              'Y',
                                                              g_sched_wait_1nurse,
                                                              'Y',
                                                              'N'),
                                                       g_sched_in_1nurse,
                                                       'Y',
                                                       'N'),
                                                g_sched_nurse_prev,
                                                decode(l_schd_outp_state,
                                                       g_sched_cons,
                                                       'Y',
                                                       g_sched_efectiv,
                                                       decode(l_schd_pre_nurse,
                                                              g_sched_nurse_prev,
                                                              'N',
                                                              g_sched_wait_1nurse,
                                                              'Y',
                                                              'Y'),
                                                       g_sched_wait_1nurse,
                                                       'Y',
                                                       g_sched_in_1nurse,
                                                       'Y',
                                                       'N'),
                                                pk_exam_constant.g_end_technician,
                                                decode(l_schd_outp_state,
                                                       pk_exam_constant.g_in_technician,
                                                       'Y',
                                                       pk_exam_constant.g_waiting_technician,
                                                       'Y',
                                                       g_sched_cons,
                                                       'Y',
                                                       'N'),
                                                pk_exam_constant.g_waiting_technician,
                                                decode(l_schd_outp_state, g_sched_cons, 'Y', 'N'),
                                                
                                                -- 2010-01-19                             
                                                g_sched_nurse,
                                                decode(l_flg_cat,
                                                       'N',
                                                       decode(l_schd_pre_nurse, g_sched_nurse_prev, 'Y', 'N'),
                                                       'N'),
                                                
                                                --                              
                                                
                                                g_sched_cons,
                                                decode(l_schd_outp_state,
                                                       pk_exam_constant.g_end_technician,
                                                       'Y',
                                                       --2010-01-19                                     
                                                       g_sched_efectiv,
                                                       decode(l_schd_pre_nurse,
                                                              g_sched_nurse_prev,
                                                              'N',
                                                              g_sched_wait_1nurse,
                                                              'N',
                                                              decode(l_flg_cat, g_flg_doctor, 'Y', 'N')),
                                                       g_sched_nurse_end,
                                                       decode(l_flg_cat, g_flg_doctor, 'Y', 'N'),
                                                       'N'),
                                                --                                                        
                                                g_shed_discharge_med,
                                                decode(l_schd_outp_state,
                                                       g_sched_cons,
                                                       decode(l_exists_discharge, 'Y', 'Y', 'N'),
                                                       g_sched_nurse,
                                                       decode(l_exists_discharge, 'Y', 'Y', 'N'),
                                                       g_sched_nurse_prev,
                                                       decode(l_exists_discharge, 'Y', 'Y', 'N'),
                                                       pk_exam_constant.g_in_technician,
                                                       decode(l_exists_discharge, 'Y', 'Y', 'N'),
                                                       pk_exam_constant.g_waiting_technician,
                                                       decode(l_exists_discharge, 'Y', 'Y', 'N'),
                                                       'N'),
                                                g_sched_in_1nurse,
                                                decode(l_schd_outp_state,
                                                       g_sched_in_1nurse,
                                                       'N',
                                                       g_sched_wait_1nurse,
                                                       'Y',
                                                       g_sched_efectiv,
                                                       decode(l_schd_pre_nurse, g_sched_wait_1nurse, 'Y', 'N'),
                                                       'N'),
                                                g_sched_wait_1nurse,
                                                decode(l_schd_outp_state,
                                                       g_sched_cons,
                                                       'Y',
                                                       g_sched_efectiv,
                                                       decode(l_schd_pre_nurse, g_sched_wait_1nurse, 'N', 'Y'),
                                                       'N'),
                                                decode(l_episode_registry,
                                                       'Y',
                                                       decode(sd.val,
                                                              g_sched_scheduled,
                                                              decode(l_schd_outp_state,
                                                                     g_sched_efectiv,
                                                                     decode(i_prof.software, l_sw_id_care, 'N', 'Y'),
                                                                     'N'),
                                                              g_sched_efectiv,
                                                              decode(l_is_contact,
                                                                     pk_alert_constant.g_yes,
                                                                     pk_alert_constant.g_no,
                                                                     decode(l_schd_outp_state, g_sched_scheduled, 'Y', 'N')),
                                                              'N'),
                                                       'N')))) flg_action
                      FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_schdl_outp_state_domain, 0)) sd
                     WHERE sd.val IN (g_sched_scheduled,
                                      g_sched_efectiv,
                                      g_sched_cons,
                                      g_sched_med_disch,
                                      g_sched_adm_disch,
                                      g_sched_nurse_prev,
                                      g_sched_nurse,
                                      g_sched_nurse_end,
                                      pk_exam_constant.g_waiting_technician,
                                      pk_exam_constant.g_in_technician,
                                      pk_exam_constant.g_end_technician,
                                      g_flg_no_show,
                                      g_sched_wait_1nurse,
                                      g_sched_in_1nurse)
                        OR (sd.val = pk_sign_off.g_sched_signoff_s AND l_show_sign_off = pk_alert_constant.g_yes)
                     ORDER BY rank;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'GET_PAT_STATUS_LIST_INT');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_status);
                RETURN FALSE;
            
            END;
    END get_pat_status_list_int;

    FUNCTION get_pat_status_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN VARCHAR2,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_check_functionality VARCHAR2(1 CHAR);
    BEGIN
    
        l_check_functionality := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                       i_prof        => i_prof,
                                                                       i_intern_name => pk_access.g_view_only_profile);
    
        RETURN get_pat_status_list_int(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_id_schedule    => i_id_schedule,
                                       i_enable_actions => CASE
                                                               WHEN l_check_functionality = pk_alert_constant.g_yes THEN
                                                                pk_alert_constant.g_no
                                                               ELSE
                                                                pk_alert_constant.g_yes
                                                           END,
                                       i_id_patient     => i_id_patient,
                                       o_status         => o_status,
                                       o_error          => o_error);
    END get_pat_status_list;

    /**
    * Get data for multichoice on patient grids.
    * No option is selectable.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_schedule  schedule identifier
    * @param o_status       cursor 
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.7.8
    * @since                2010/04/19
    */
    FUNCTION get_pat_status_list_na
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patient  IN patient.id_patient%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_pat_status_list_int(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_id_schedule    => i_id_schedule,
                                       i_enable_actions => pk_alert_constant.g_no,
                                       i_id_patient     => i_id_patient,
                                       o_status         => o_status,
                                       o_error          => o_error);
    END get_pat_status_list_na;

    FUNCTION nurse_efectiv
    (
        i_lang          IN language.id_language%TYPE,
        i_epis_type     IN schedule_outp.id_epis_type%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Grelha do enfermeiro, para ver consultas agendadas já efectivadas
                  das especialidades a que está alocado
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_EPIS_TYPE - Tipo de episódio (CE, URG, ...)
                 I_PROF - prof q acede
                   I_DT - data
                 I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                       como é retornada em PK_LOGIN.GET_PROF_PREF
                        SAIDA:   O_DOC - array
                                 O_ERROR - erro
        
          CRIAÇÃO: RB 2005/05/06
          ALTERAÇÃO: CRS 2006/07/20 Excluir episódios cancelados
        
          NOTAS: Nesta grelha visualizam-se os agendamentos do dia:
               - agendados e já efectivados para o serv. clínico a q está associado
                 o profissional, c/ ou s/ alta médica, sem alta administrativa ou
                           com alta administrativa se ainda têm workflow pendente.
        *********************************************************************************/
        l_waiting_room_available    VARCHAR2(10);
        l_waiting_room_sys_external sys_config.value%TYPE := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM',
                                                                                     i_prof);
        -- JS, 2007-09-11 - Timezone
        l_sysdate_char_short VARCHAR2(8);
        l_dt_begin           TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end             TIMESTAMP WITH LOCAL TIME ZONE;
    
        --variavel que indica de nos devemos deslocar para a area antiga quando estamos em episódios não efectivados
        l_to_old_area VARCHAR2(1);
    
        -- Parametrizar se se filtra por salas a query, ou nao
        -- Desenvolvimento fix 2.4.3.23 para o brasil
        l_sys_config sys_config.value%TYPE := 'N';
    
        l_sch_event_therap_decision pk_translation.t_desc_translation;
    
        l_handoff_type sys_config.value%TYPE;
        l_config_show_resident CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
        l_show_resident_physician sys_config.value%TYPE;
        l_group_ids               table_number := table_number();
        l_schedule_ids            table_number := table_number();
        l_sch_t640                sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
    BEGIN
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz       := current_timestamp;
        l_sysdate_char_short := pk_date_utils.to_char_insttimezone(i_prof, g_sysdate_tstz, 'YYYYMMDD');
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error                  := 'IS WAITING ROOM AVAILABLE';
        l_waiting_room_available := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
        l_dt_begin               := pk_date_utils.trunc_insttimezone(i_prof,
                                                                     nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                       i_prof,
                                                                                                       i_dt,
                                                                                                       NULL),
                                                                         g_sysdate_tstz));
        l_dt_end                 := pk_date_utils.add_days_to_tstz(l_dt_begin, 1);
    
        l_to_old_area := pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof);
    
        l_sys_config := pk_sysconfig.get_config('GRID_NURSE_BY_ROOM', i_prof);
    
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => i_prof);
    
        g_error := 'GET SCH_EVENT TRANSLATION';
        SELECT pk_translation.get_translation(i_lang, se.code_sch_event_abrv)
          INTO l_sch_event_therap_decision
          FROM sch_event se
         WHERE se.id_sch_event = g_sch_event_therap_decision;
    
        SELECT DISTINCT s.id_group
          BULK COLLECT
          INTO l_group_ids
          FROM schedule_outp sp
          JOIN schedule s
            ON s.id_schedule = sp.id_schedule
           AND s.id_instit_requested = i_prof.institution
           AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
          JOIN prof_dep_clin_serv pdcs
            ON pdcs.id_dep_clin_serv = s.id_dcs_requested
           AND pdcs.id_professional = i_prof.id
           AND pdcs.flg_status = g_selected
          JOIN sch_group sg
            ON sg.id_schedule = sp.id_schedule
          JOIN patient pat
            ON pat.id_patient = sg.id_patient
          LEFT JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
           AND ei.id_patient = sg.id_patient
          LEFT JOIN episode epis
            ON epis.id_episode = ei.id_episode
           AND epis.id_patient = ei.id_patient
           AND epis.flg_status != g_epis_canc -- CRS 2006/07/20
           AND epis.dt_cancel_tstz IS NULL
           AND epis.flg_ehr != g_flg_ehr
          LEFT JOIN grid_task gt
            ON gt.id_episode = epis.id_episode
        -- JS, 2007-09-11 - Timezone
         WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
           AND sp.id_software = i_prof.software
           AND sp.id_epis_type != g_epis_type_nurse
           AND get_schedule_real_state(sp.flg_state, epis.flg_ehr) != g_sched_adm_disch
           AND ((sp.flg_state = g_sched_adm_disch AND
               -- JS, 2007-09-11 - Timezone
               (pk_grid_amb.get_grid_task_if(i_lang,
                                               i_prof,
                                               i_prof_cat_type,
                                               l_sysdate_char_short,
                                               epis.id_visit,
                                               gt.clin_rec_req,
                                               gt.clin_rec_transp,
                                               gt.drug_presc,
                                               gt.drug_req,
                                               gt.drug_transp,
                                               gt.hemo_req,
                                               gt.intervention,
                                               gt.material_req,
                                               gt.monitorization,
                                               gt.movement,
                                               gt.nurse_activity,
                                               gt.teach_req) = 1)) OR (sp.flg_state != g_sched_adm_disch))
           AND ((l_sys_config = 'Y' AND EXISTS (SELECT 0
                                                  FROM prof_room pr
                                                 WHERE pr.id_professional = i_prof.id
                                                   AND ei.id_room = pr.id_room)) OR l_sys_config = 'N')
           AND se.flg_is_group = pk_alert_constant.g_yes
           AND s.id_group IS NOT NULL;
    
        l_schedule_ids := pk_grid_amb.get_schedule_ids(l_group_ids);
    
        g_error := 'GET CURSOR';
        OPEN o_doc FOR
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
                   t.dt_target,
                   t.flg_state,
                   t.flg_sched,
                   t.prof_name,
                   t.dt_efectiv,
                   t.dt_efectiv_compl,
                   t.img_state,
                   t.img_sched,
                   t.desc_drug_vaccine_req,
                   t.desc_nurse_interv_monit,
                   t.desc_mov,
                   t.desc_nurse_teach,
                   t.dt_server,
                   t.internment,
                   t.rank,
                   CASE
                        WHEN i_dt IS NULL THEN
                         t.wr_call
                        ELSE
                         pk_alert_constant.g_no
                    END wr_call,
                   t.therapeutic_doctor,
                   t.resp_icon,
                   t.desc_room,
                   t.designated_provider,
                   t.flg_contact_type,
                   t.icon_contact_type,
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
                   t.extend_icon
              FROM (SELECT s.id_schedule,
                           sg.id_patient,
                           epis.id_episode id_episode,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           --                           pk_translation.get_translation(i_lang, cs.code_clinical_service) ||
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) ||
                           decode(s.id_sch_event,
                                  g_sch_event_therap_decision,
                                  ' - ' || l_sch_event_therap_decision,
                                  NULL) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           get_schedule_real_state(sp.flg_state, epis.flg_ehr) flg_state,
                           sp.flg_sched,
                           p.nick_name prof_name,
                           CASE
                                WHEN ei.id_episode IS NOT NULL THEN
                                 decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                        g_sched_scheduled,
                                        '',
                                        pk_date_utils.date_char_hour_tsz(i_lang,
                                                                         epis.dt_begin_tstz,
                                                                         i_prof.institution,
                                                                         i_prof.software))
                                ELSE
                                 NULL
                            END dt_efectiv,
                           CASE
                                WHEN ei.id_episode IS NOT NULL THEN
                                 decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                        g_sched_scheduled,
                                        '',
                                        pk_date_utils.date_send_tsz(i_lang,
                                                                    epis.dt_begin_tstz,
                                                                    i_prof.institution,
                                                                    i_prof.software))
                                ELSE
                                 NULL
                            END dt_efectiv_compl,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_STATE',
                                                       pk_grid.get_pre_nurse_appointment(i_lang,
                                                                                         i_prof,
                                                                                         ei.id_dep_clin_serv,
                                                                                         epis.flg_ehr,
                                                                                         get_schedule_real_state(sp.flg_state,
                                                                                                                 epis.flg_ehr)),
                                                       i_lang) img_state,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                           decode(pk_grid.get_prioritary_task(i_lang,
                                                              substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                                              substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                                              NULL,
                                                              g_flg_doctor),
                                  substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                  pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc),
                                  substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                  pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_req)) desc_drug_vaccine_req,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              gt.nurse_activity,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          gt.intervention,
                                                                                                                          gt.monitorization,
                                                                                                                          NULL,
                                                                                                                          'D'),
                                                                                              NULL,
                                                                                              'D')) desc_nurse_interv_monit,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.movement) desc_mov,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.teach_req) desc_nurse_teach,
                           -- JS, 2007-09-11 - Timezone - Fim alteração
                           g_sysdate_char dt_server,
                           decode(instr(dep1.flg_type, 'I'),
                                  0,
                                  '',
                                  '',
                                  '',
                                  pk_message.get_message(i_lang, 'GRID_NURSE_M001') || ' ' ||
                                  pk_translation.get_translation(i_lang, cs1.code_clinical_service)) internment, --SS 2006/11/24
                           decode(sp.flg_state, g_sched_adm_disch, 3, g_sched_med_disch, 2, 1) rank,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => epis.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           decode(s.id_sch_event,
                                  g_sch_event_therap_decision,
                                  '(' ||
                                  pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) || ')',
                                  NULL) therapeutic_doctor,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                           decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang,
                                                              i_prof,
                                                              sg.id_patient,
                                                              decode(epis.flg_ehr,
                                                                     pk_ehr_access.g_flg_ehr_normal,
                                                                     epis.id_episode,
                                                                     decode(l_to_old_area, g_yes, NULL, epis.id_episode))) designated_provider,
                           sg.flg_contact_type,
                           pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           -- Display number of responsible PHYSICIANS for the episode, 
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
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
                                                                      epis.id_department,
                                                                      ei.id_software,
                                                                      nvl(ei.id_professional, ps.id_professional),
                                                                      ei.id_first_nurse_resp)) prof_team,
                           
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
                                                            l_handoff_type,
                                                            'T') name_prof_tooltip,
                           -- 2) Responsible nurse
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_nurse,
                                                            ei.id_episode,
                                                            ei.id_first_nurse_resp,
                                                            l_handoff_type,
                                                            'T') name_nurse_tooltip,
                           -- 3) Responsible team 
                           pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         epis.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_handoff_type,
                                                         NULL) prof_team_tooltip,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid_amb.g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           sp.dt_target_tstz,
                           0 id_group,
                           pk_alert_constant.g_no flg_group_header,
                           NULL extend_icon
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                       AND s.id_instit_requested = i_prof.institution
                       AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = s.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN professional p
                        ON ps.id_professional = p.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                       AND ei.id_patient = sg.id_patient
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                       AND epis.id_patient = ei.id_patient
                       AND epis.flg_status != g_epis_canc -- CRS 2006/07/20
                       AND epis.dt_cancel_tstz IS NULL
                       AND epis.flg_ehr != g_flg_ehr
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      LEFT JOIN discharge d
                        ON d.id_episode = epis.id_episode
                       AND d.dt_cancel_tstz IS NULL
                      LEFT JOIN disch_reas_dest drt
                        ON drt.id_disch_reas_dest = d.id_disch_reas_dest
                      LEFT JOIN dep_clin_serv dcs1
                        ON dcs1.id_dep_clin_serv = drt.id_dep_clin_serv
                      LEFT JOIN department dep1
                        ON dep1.id_department = dcs1.id_department
                      LEFT JOIN clinical_service cs1
                        ON cs1.id_clinical_service = dcs1.id_clinical_service
                      LEFT JOIN grid_task gt
                        ON gt.id_episode = epis.id_episode
                    -- JS, 2007-09-11 - Timezone
                     WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                       AND sp.id_software = i_prof.software
                       AND sp.id_epis_type != g_epis_type_nurse
                       AND get_schedule_real_state(sp.flg_state, epis.flg_ehr) != g_sched_adm_disch
                       AND ((sp.flg_state = g_sched_adm_disch AND
                           -- JS, 2007-09-11 - Timezone
                           (pk_grid_amb.get_grid_task_if(i_lang,
                                                           i_prof,
                                                           i_prof_cat_type,
                                                           l_sysdate_char_short,
                                                           epis.id_visit,
                                                           gt.clin_rec_req,
                                                           gt.clin_rec_transp,
                                                           gt.drug_presc,
                                                           gt.drug_req,
                                                           gt.drug_transp,
                                                           gt.hemo_req,
                                                           gt.intervention,
                                                           gt.material_req,
                                                           gt.monitorization,
                                                           gt.movement,
                                                           gt.nurse_activity,
                                                           gt.teach_req) = 1)) OR (sp.flg_state != g_sched_adm_disch))
                       AND ((l_sys_config = 'Y' AND EXISTS
                            (SELECT 0
                                FROM prof_room pr
                               WHERE pr.id_professional = i_prof.id
                                 AND ei.id_room = pr.id_room)) OR l_sys_config = 'N')
                       AND se.flg_is_group = pk_alert_constant.g_no
                    --group elements
                    UNION ALL
                    SELECT s.id_schedule,
                           sg.id_patient,
                           epis.id_episode id_episode,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) ||
                           --                           pk_translation.get_translation(i_lang, cs.code_clinical_service) ||
                            decode(s.id_sch_event,
                                   g_sch_event_therap_decision,
                                   ' - ' || l_sch_event_therap_decision,
                                   NULL) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           decode(s.flg_status,
                                  g_sched_canc,
                                  g_sched_canc,
                                  get_schedule_real_state(sp.flg_state, epis.flg_ehr)) flg_state,
                           sp.flg_sched,
                           p.nick_name prof_name,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        epis.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_send_tsz(i_lang,
                                                                   epis.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv_compl,
                           decode(s.flg_status,
                                  g_sched_canc,
                                  pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS', s.flg_status, i_lang),
                                  pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_STATE',
                                                              get_pre_nurse_appointment(i_lang,
                                                                                        i_prof,
                                                                                        ei.id_dep_clin_serv,
                                                                                        epis.flg_ehr,
                                                                                        get_schedule_real_state(sp.flg_state,
                                                                                                                epis.flg_ehr)),
                                                              i_lang)) img_state,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                           decode(pk_grid.get_prioritary_task(i_lang,
                                                              substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                                              substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                                              NULL,
                                                              g_flg_doctor),
                                  substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                  pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc),
                                  substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                  pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_req)) desc_drug_vaccine_req,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              gt.nurse_activity,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          gt.intervention,
                                                                                                                          gt.monitorization,
                                                                                                                          NULL,
                                                                                                                          'D'),
                                                                                              NULL,
                                                                                              'D')) desc_nurse_interv_monit,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.movement) desc_mov,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.teach_req) desc_nurse_teach,
                           -- JS, 2007-09-11 - Timezone - Fim alteração
                           g_sysdate_char dt_server,
                           decode(instr(dep1.flg_type, 'I'),
                                  0,
                                  '',
                                  '',
                                  '',
                                  pk_message.get_message(i_lang, 'GRID_NURSE_M001') || ' ' ||
                                  pk_translation.get_translation(i_lang, cs1.code_clinical_service)) internment, --SS 2006/11/24
                           decode(sp.flg_state, g_sched_adm_disch, 3, g_sched_med_disch, 2, 1) rank,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => epis.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           decode(s.id_sch_event,
                                  g_sch_event_therap_decision,
                                  '(' ||
                                  pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) || ')',
                                  NULL) therapeutic_doctor,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                           NULL desc_room, --decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang,
                                                              i_prof,
                                                              sg.id_patient,
                                                              decode(epis.flg_ehr,
                                                                     pk_ehr_access.g_flg_ehr_normal,
                                                                     epis.id_episode,
                                                                     decode(l_to_old_area, g_yes, NULL, epis.id_episode))) designated_provider,
                           sg.flg_contact_type,
                           pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           -- Display number of responsible PHYSICIANS for the episode, 
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
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
                                                                      epis.id_department,
                                                                      ei.id_software,
                                                                      nvl(ei.id_professional, ps.id_professional),
                                                                      ei.id_first_nurse_resp)) prof_team,
                           
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
                                                            l_handoff_type,
                                                            'T') name_prof_tooltip,
                           -- 2) Responsible nurse
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_nurse,
                                                            ei.id_episode,
                                                            ei.id_first_nurse_resp,
                                                            l_handoff_type,
                                                            'T') name_nurse_tooltip,
                           -- 3) Responsible team 
                           pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         epis.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_handoff_type,
                                                         NULL) prof_team_tooltip,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid_amb.g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           sp.dt_target_tstz,
                           s.id_group,
                           pk_alert_constant.g_no flg_group_header,
                           'ExtendIcon' extend_icon
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = s.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN professional p
                        ON ps.id_professional = p.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                       AND ei.id_patient = sg.id_patient
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      LEFT JOIN discharge d
                        ON d.id_episode = epis.id_episode
                       AND d.dt_cancel_tstz IS NULL
                      LEFT JOIN disch_reas_dest drt
                        ON drt.id_disch_reas_dest = d.id_disch_reas_dest
                      LEFT JOIN dep_clin_serv dcs1
                        ON dcs1.id_dep_clin_serv = drt.id_dep_clin_serv
                      LEFT JOIN department dep1
                        ON dep1.id_department = dcs1.id_department
                      LEFT JOIN clinical_service cs1
                        ON cs1.id_clinical_service = dcs1.id_clinical_service
                      LEFT JOIN grid_task gt
                        ON gt.id_episode = epis.id_episode
                     WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE k ROWS=0.00000000001)*/
                                           k.column_value
                                            FROM TABLE(l_group_ids) k)
                    --group header
                    UNION ALL
                    SELECT NULL id_schedule, --s.id_schedule,
                           NULL id_patient, --sg.id_patient,
                           NULL id_episode, --decode(epis.flg_ehr,pk_ehr_access.g_flg_ehr_normal,epis.id_episode,decode(l_to_old_area, g_yes, NULL, epis.id_episode)) id_episode,
                           l_sch_t640 name, --pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           l_sch_t640 name_to_sort, --pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           NULL pat_ndo, -- pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           NULL pat_nd_icon, --  pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           NULL gender, -- pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender,
                           NULL pat_age, -- pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           NULL photo, -- pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) ||
                           --                           pk_translation.get_translation(i_lang, cs.code_clinical_service) ||
                            decode(s.id_sch_event,
                                   g_sch_event_therap_decision,
                                   ' - ' || l_sch_event_therap_decision,
                                   NULL) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           'A' flg_state,
                           sp.flg_sched,
                           p.nick_name prof_name,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        epis.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_send_tsz(i_lang,
                                                                   epis.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv_compl,
                           pk_grid_amb.get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                           decode(pk_grid.get_prioritary_task(i_lang,
                                                              substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                                              substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                                              NULL,
                                                              g_flg_doctor),
                                  substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                  pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc),
                                  substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                  pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_req)) desc_drug_vaccine_req,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              gt.nurse_activity,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          gt.intervention,
                                                                                                                          gt.monitorization,
                                                                                                                          NULL,
                                                                                                                          'D'),
                                                                                              NULL,
                                                                                              'D')) desc_nurse_interv_monit,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.movement) desc_mov,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.teach_req) desc_nurse_teach,
                           -- JS, 2007-09-11 - Timezone - Fim alteração
                           g_sysdate_char dt_server,
                           decode(instr(dep1.flg_type, 'I'),
                                  0,
                                  '',
                                  '',
                                  '',
                                  pk_message.get_message(i_lang, 'GRID_NURSE_M001') || ' ' ||
                                  pk_translation.get_translation(i_lang, cs1.code_clinical_service)) internment, --SS 2006/11/24
                           decode(sp.flg_state, g_sched_adm_disch, 3, g_sched_med_disch, 2, 1) rank,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => epis.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           decode(s.id_sch_event,
                                  g_sch_event_therap_decision,
                                  '(' ||
                                  pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) || ')',
                                  NULL) therapeutic_doctor,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                           NULL desc_room, --decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang,
                                                              i_prof,
                                                              sg.id_patient,
                                                              decode(epis.flg_ehr,
                                                                     pk_ehr_access.g_flg_ehr_normal,
                                                                     epis.id_episode,
                                                                     decode(l_to_old_area, g_yes, NULL, epis.id_episode))) designated_provider,
                           NULL flg_contact_type, -- sg.flg_contact_type,
                           pk_grid_amb.get_group_presence_icon(i_lang, i_prof, s.id_group, pk_alert_constant.g_no) icon_contact_type,
                           NULL flg_contact, -- pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           -- Display number of responsible PHYSICIANS for the episode, 
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
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
                                                                      epis.id_department,
                                                                      ei.id_software,
                                                                      nvl(ei.id_professional, ps.id_professional),
                                                                      ei.id_first_nurse_resp)) prof_team,
                           
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
                                                            l_handoff_type,
                                                            'T') name_prof_tooltip,
                           -- 2) Responsible nurse
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_nurse,
                                                            ei.id_episode,
                                                            ei.id_first_nurse_resp,
                                                            l_handoff_type,
                                                            'T') name_nurse_tooltip,
                           -- 3) Responsible team 
                           pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         epis.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_handoff_type,
                                                         NULL) prof_team_tooltip,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid_amb.g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           sp.dt_target_tstz,
                           s.id_group,
                           pk_alert_constant.g_yes flg_group_header,
                           NULL extend_icon
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN prof_dep_clin_serv pdcs
                        ON pdcs.id_dep_clin_serv = s.id_dcs_requested
                       AND pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = g_selected
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN professional p
                        ON ps.id_professional = p.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                       AND ei.id_patient = sg.id_patient
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      LEFT JOIN discharge d
                        ON d.id_episode = epis.id_episode
                       AND d.dt_cancel_tstz IS NULL
                      LEFT JOIN disch_reas_dest drt
                        ON drt.id_disch_reas_dest = d.id_disch_reas_dest
                      LEFT JOIN dep_clin_serv dcs1
                        ON dcs1.id_dep_clin_serv = drt.id_dep_clin_serv
                      LEFT JOIN department dep1
                        ON dep1.id_department = dcs1.id_department
                      LEFT JOIN clinical_service cs1
                        ON cs1.id_clinical_service = dcs1.id_clinical_service
                      LEFT JOIN grid_task gt
                        ON gt.id_episode = epis.id_episode
                     WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE k ROWS=0.00000000001)*/
                                              k.column_value
                                               FROM TABLE(l_schedule_ids) k)
                    --
                    ) t
             ORDER BY t.rank, t.dt_target_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'NURSE_EFECTIV');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_doc);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION nurse_efectiv_my_rooms
    (
        i_lang          IN language.id_language%TYPE,
        i_epis_type     IN schedule_outp.id_epis_type%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Grelha do enfermeiro, para ver consultas agendadas já efectivadas
                  das especialidades a que está alocado
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_EPIS_TYPE - Tipo de episódio (CE, URG, ...)
                 I_PROF - prof q acede
                   I_DT - data
                 I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                       como é retornada em PK_LOGIN.GET_PROF_PREF
                        SAIDA:   O_DOC - array
                                 O_ERROR - erro
        
          CRIAÇÃO: RB 2005/05/06
          ALTERAÇÃO: CRS 2006/07/20 Excluir episódios cancelados
        
          NOTAS: Nesta grelha visualizam-se os agendamentos do dia:
               - agendados e já efectivados para o serv. clínico a q está associado
                 o profissional, c/ ou s/ alta médica, sem alta administrativa ou
                           com alta administrativa se ainda têm workflow pendente.
        *********************************************************************************/
        l_waiting_room_sys_external sys_config.value%TYPE := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM',
                                                                                     i_prof);
        l_waiting_room_available    VARCHAR2(10);
        -- JS, 2007-09-11 - Timezone
        l_sysdate_char_short VARCHAR2(8);
        l_dt_begin           TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end             TIMESTAMP WITH LOCAL TIME ZONE;
    
        --variavel que indica de nos devemos deslocar para a area antiga quando estamos em episódios não efectivados
        l_to_old_area VARCHAR2(1);
    
        l_sch_event_therap_decision pk_translation.t_desc_translation;
    
        l_handoff_type sys_config.value%TYPE;
        l_config_show_resident CONSTANT sys_config.id_sys_config%TYPE := 'GRIDS_SHOW_RESIDENT';
        l_show_resident_physician sys_config.value%TYPE;
        l_group_ids               table_number := table_number();
        l_schedule_ids            table_number := table_number();
        l_sch_t640                sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
    BEGIN
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz       := current_timestamp;
        l_sysdate_char_short := pk_date_utils.to_char_insttimezone(i_prof, g_sysdate_tstz, 'YYYYMMDD');
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error                  := 'IS WAITING ROOM AVAILABLE';
        l_waiting_room_available := pk_sysconfig.get_config(g_sys_config_wr, i_prof);
        l_dt_begin               := pk_date_utils.trunc_insttimezone(i_prof,
                                                                     nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                       i_prof,
                                                                                                       i_dt,
                                                                                                       NULL),
                                                                         g_sysdate_tstz));
        l_dt_end                 := pk_date_utils.add_days_to_tstz(l_dt_begin, 1);
    
        l_to_old_area := pk_sysconfig.get_config('EHR_ACCESS_SC_OLD_AREA', i_prof);
    
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        l_show_resident_physician := pk_sysconfig.get_config(i_code_cf => l_config_show_resident, i_prof => i_prof);
    
        g_error := 'GET SCH_EVENT TRANSLATION';
        SELECT pk_translation.get_translation(i_lang, se.code_sch_event_abrv)
          INTO l_sch_event_therap_decision
          FROM sch_event se
         WHERE se.id_sch_event = g_sch_event_therap_decision;
    
        SELECT DISTINCT s.id_group
          BULK COLLECT
          INTO l_group_ids
          FROM schedule_outp sp
          JOIN schedule s
            ON s.id_schedule = sp.id_schedule
           AND s.id_instit_requested = i_prof.institution
           AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
          JOIN sch_group sg
            ON sg.id_schedule = sp.id_schedule
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
          JOIN patient pat
            ON pat.id_patient = sg.id_patient
          LEFT JOIN epis_info ei
            ON ei.id_schedule = s.id_schedule
           AND ei.id_patient = sg.id_patient
          LEFT JOIN episode epis
            ON epis.id_episode = ei.id_episode
           AND epis.id_patient = ei.id_patient
           AND epis.flg_status != g_epis_canc -- CRS 2006/07/20
           AND epis.dt_cancel_tstz IS NULL
           AND epis.flg_ehr != g_flg_ehr
          LEFT JOIN grid_task gt
            ON gt.id_episode = epis.id_episode
        -- JS, 2007-09-11 - Timezone
         WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
           AND sp.id_software = i_prof.software
           AND sp.id_epis_type != g_epis_type_nurse
           AND get_schedule_real_state(sp.flg_state, epis.flg_ehr) != g_sched_adm_disch
           AND ((sp.flg_state = g_sched_adm_disch AND
               -- JS, 2007-09-11 - Timezone
               (pk_grid_amb.get_grid_task_if(i_lang,
                                               i_prof,
                                               i_prof_cat_type,
                                               l_sysdate_char_short,
                                               epis.id_visit,
                                               gt.clin_rec_req,
                                               gt.clin_rec_transp,
                                               gt.drug_presc,
                                               gt.drug_req,
                                               gt.drug_transp,
                                               gt.hemo_req,
                                               gt.intervention,
                                               gt.material_req,
                                               gt.monitorization,
                                               gt.movement,
                                               gt.nurse_activity,
                                               gt.teach_req) = 1)) OR (sp.flg_state != g_sched_adm_disch))
           AND EXISTS (SELECT 0
                  FROM prof_room pr
                 WHERE pr.id_professional = i_prof.id
                   AND ei.id_room = pr.id_room)
           AND se.flg_is_group = pk_alert_constant.g_yes
           AND s.id_group IS NOT NULL;
    
        l_schedule_ids := pk_grid_amb.get_schedule_ids(l_group_ids);
    
        g_error := 'GET CURSOR';
        OPEN o_doc FOR
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
                   t.dt_target,
                   t.flg_state,
                   t.flg_sched,
                   t.prof_name,
                   t.dt_efectiv,
                   t.dt_efectiv_compl,
                   t.img_state,
                   t.img_sched,
                   t.desc_drug_vaccine_req,
                   t.desc_nurse_interv_monit,
                   t.desc_mov,
                   t.desc_nurse_teach,
                   t.dt_server,
                   t.internment,
                   t.rank,
                   CASE
                        WHEN i_dt IS NULL THEN
                         t.wr_call
                        ELSE
                         pk_alert_constant.g_no
                    END wr_call,
                   t.therapeutic_doctor,
                   t.resp_icon,
                   t.desc_room,
                   t.designated_provider,
                   t.flg_contact_type,
                   t.icon_contact_type,
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
                   t.extend_icon
              FROM (SELECT s.id_schedule,
                           sg.id_patient,
                           epis.id_episode id_episode,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) ||
                           --                           pk_translation.get_translation(i_lang, cs.code_clinical_service) ||
                            decode(s.id_sch_event,
                                   g_sch_event_therap_decision,
                                   ' - ' || l_sch_event_therap_decision,
                                   NULL) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           get_schedule_real_state(sp.flg_state, epis.flg_ehr) flg_state,
                           sp.flg_sched,
                           p.nick_name prof_name,
                           CASE
                                WHEN ei.id_episode IS NOT NULL THEN
                                 decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                        g_sched_scheduled,
                                        '',
                                        pk_date_utils.date_char_hour_tsz(i_lang,
                                                                         epis.dt_begin_tstz,
                                                                         i_prof.institution,
                                                                         i_prof.software))
                                ELSE
                                 NULL
                            END dt_efectiv,
                           CASE
                                WHEN ei.id_episode IS NOT NULL THEN
                                 decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                        g_sched_scheduled,
                                        '',
                                        pk_date_utils.date_send_tsz(i_lang,
                                                                    epis.dt_begin_tstz,
                                                                    i_prof.institution,
                                                                    i_prof.software))
                                ELSE
                                 NULL
                            END dt_efectiv_compl,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_STATE',
                                                       get_pre_nurse_appointment(i_lang,
                                                                                 i_prof,
                                                                                 ei.id_dep_clin_serv,
                                                                                 epis.flg_ehr,
                                                                                 get_schedule_real_state(sp.flg_state,
                                                                                                         epis.flg_ehr)),
                                                       i_lang) img_state,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                           decode(pk_grid.get_prioritary_task(i_lang,
                                                              substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                                              substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                                              NULL,
                                                              g_flg_doctor),
                                  substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                  pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc),
                                  substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                  pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_req)) desc_drug_vaccine_req,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              gt.nurse_activity,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          gt.intervention,
                                                                                                                          gt.monitorization,
                                                                                                                          NULL,
                                                                                                                          'D'),
                                                                                              NULL,
                                                                                              'D')) desc_nurse_interv_monit,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.movement) desc_mov,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.teach_req) desc_nurse_teach,
                           -- JS, 2007-09-11 - Timezone - Fim alteração
                           g_sysdate_char dt_server,
                           decode(instr(dep1.flg_type, 'I'),
                                  0,
                                  '',
                                  '',
                                  '',
                                  pk_message.get_message(i_lang, 'GRID_NURSE_M001') || ' ' ||
                                  pk_translation.get_translation(i_lang, cs1.code_clinical_service)) internment, --SS 2006/11/24
                           decode(sp.flg_state, g_sched_adm_disch, 3, g_sched_med_disch, 2, 1) rank,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => epis.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           decode(s.id_sch_event,
                                  g_sch_event_therap_decision,
                                  '(' ||
                                  pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) || ')',
                                  NULL) therapeutic_doctor,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                           decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang,
                                                              i_prof,
                                                              sg.id_patient,
                                                              decode(epis.flg_ehr,
                                                                     pk_ehr_access.g_flg_ehr_normal,
                                                                     epis.id_episode,
                                                                     decode(l_to_old_area, g_yes, NULL, epis.id_episode))) designated_provider,
                           sg.flg_contact_type,
                           pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           -- Display number of responsible PHYSICIANS for the episode, 
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
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
                                                                      epis.id_department,
                                                                      ei.id_software,
                                                                      nvl(ei.id_professional, ps.id_professional),
                                                                      ei.id_first_nurse_resp)) prof_team,
                           
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
                                                            l_handoff_type,
                                                            'T') name_prof_tooltip,
                           -- 2) Responsible nurse
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_nurse,
                                                            ei.id_episode,
                                                            ei.id_first_nurse_resp,
                                                            l_handoff_type,
                                                            'T') name_nurse_tooltip,
                           -- 3) Responsible team 
                           pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         epis.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_handoff_type,
                                                         NULL) prof_team_tooltip,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid_amb.g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           sp.dt_target_tstz,
                           0 id_group,
                           pk_alert_constant.g_no flg_group_header,
                           NULL extend_icon
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                       AND s.id_instit_requested = i_prof.institution
                       AND s.flg_status NOT IN (g_sched_canc, pk_schedule.g_sched_status_cache)
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN sch_event se
                        ON s.id_sch_event = se.id_sch_event
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN professional p
                        ON ps.id_professional = p.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                       AND ei.id_patient = sg.id_patient
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                       AND epis.id_patient = ei.id_patient
                       AND epis.flg_status != g_epis_canc -- CRS 2006/07/20
                       AND epis.dt_cancel_tstz IS NULL
                       AND epis.flg_ehr != g_flg_ehr
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      LEFT JOIN discharge d
                        ON d.id_episode = epis.id_episode
                       AND d.dt_cancel_tstz IS NULL
                      LEFT JOIN disch_reas_dest drt
                        ON drt.id_disch_reas_dest = d.id_disch_reas_dest
                      LEFT JOIN dep_clin_serv dcs1
                        ON dcs1.id_dep_clin_serv = drt.id_dep_clin_serv
                      LEFT JOIN department dep1
                        ON dep1.id_department = dcs1.id_department
                      LEFT JOIN clinical_service cs1
                        ON cs1.id_clinical_service = dcs1.id_clinical_service
                      LEFT JOIN grid_task gt
                        ON gt.id_episode = epis.id_episode
                    -- JS, 2007-09-11 - Timezone
                     WHERE sp.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                       AND sp.id_software = i_prof.software
                       AND sp.id_epis_type != g_epis_type_nurse
                       AND get_schedule_real_state(sp.flg_state, epis.flg_ehr) != g_sched_adm_disch
                       AND ((sp.flg_state = g_sched_adm_disch AND
                           -- JS, 2007-09-11 - Timezone
                           (pk_grid_amb.get_grid_task_if(i_lang,
                                                           i_prof,
                                                           i_prof_cat_type,
                                                           l_sysdate_char_short,
                                                           epis.id_visit,
                                                           gt.clin_rec_req,
                                                           gt.clin_rec_transp,
                                                           gt.drug_presc,
                                                           gt.drug_req,
                                                           gt.drug_transp,
                                                           gt.hemo_req,
                                                           gt.intervention,
                                                           gt.material_req,
                                                           gt.monitorization,
                                                           gt.movement,
                                                           gt.nurse_activity,
                                                           gt.teach_req) = 1)) OR (sp.flg_state != g_sched_adm_disch))
                       AND EXISTS (SELECT 0
                              FROM prof_room pr
                             WHERE pr.id_professional = i_prof.id
                               AND ei.id_room = pr.id_room)
                       AND se.flg_is_group = pk_alert_constant.g_no
                    --group elements
                    UNION ALL
                    SELECT s.id_schedule,
                           sg.id_patient,
                           epis.id_episode id_episode,
                           pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender,
                           pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) ||
                           --                           pk_translation.get_translation(i_lang, cs.code_clinical_service) ||
                            decode(s.id_sch_event,
                                   g_sch_event_therap_decision,
                                   ' - ' || l_sch_event_therap_decision,
                                   NULL) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           decode(s.flg_status,
                                  g_sched_canc,
                                  g_sched_canc,
                                  get_schedule_real_state(sp.flg_state, epis.flg_ehr)) flg_state,
                           sp.flg_sched,
                           p.nick_name prof_name,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        epis.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_send_tsz(i_lang,
                                                                   epis.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv_compl,
                           decode(s.flg_status,
                                  g_sched_canc,
                                  pk_sysdomain.get_ranked_img('SCHEDULE.FLG_STATUS', s.flg_status, i_lang),
                                  pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_STATE',
                                                              get_pre_nurse_appointment(i_lang,
                                                                                        i_prof,
                                                                                        ei.id_dep_clin_serv,
                                                                                        epis.flg_ehr,
                                                                                        get_schedule_real_state(sp.flg_state,
                                                                                                                epis.flg_ehr)),
                                                              i_lang)) img_state,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                           decode(pk_grid.get_prioritary_task(i_lang,
                                                              substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                                              substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                                              NULL,
                                                              g_flg_doctor),
                                  substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                  pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc),
                                  substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                  pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_req)) desc_drug_vaccine_req,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              gt.nurse_activity,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          gt.intervention,
                                                                                                                          gt.monitorization,
                                                                                                                          NULL,
                                                                                                                          'D'),
                                                                                              NULL,
                                                                                              'D')) desc_nurse_interv_monit,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.movement) desc_mov,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.teach_req) desc_nurse_teach,
                           -- JS, 2007-09-11 - Timezone - Fim alteração
                           g_sysdate_char dt_server,
                           decode(instr(dep1.flg_type, 'I'),
                                  0,
                                  '',
                                  '',
                                  '',
                                  pk_message.get_message(i_lang, 'GRID_NURSE_M001') || ' ' ||
                                  pk_translation.get_translation(i_lang, cs1.code_clinical_service)) internment, --SS 2006/11/24
                           decode(sp.flg_state, g_sched_adm_disch, 3, g_sched_med_disch, 2, 1) rank,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => epis.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           decode(s.id_sch_event,
                                  g_sch_event_therap_decision,
                                  '(' ||
                                  pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) || ')',
                                  NULL) therapeutic_doctor,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                           NULL desc_room, --decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang,
                                                              i_prof,
                                                              sg.id_patient,
                                                              decode(epis.flg_ehr,
                                                                     pk_ehr_access.g_flg_ehr_normal,
                                                                     epis.id_episode,
                                                                     decode(l_to_old_area, g_yes, NULL, epis.id_episode))) designated_provider,
                           sg.flg_contact_type,
                           pk_sysdomain.get_img(i_lang, g_domain_sch_presence, sg.flg_contact_type) icon_contact_type,
                           pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           -- Display number of responsible PHYSICIANS for the episode, 
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
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
                                                                      epis.id_department,
                                                                      ei.id_software,
                                                                      nvl(ei.id_professional, ps.id_professional),
                                                                      ei.id_first_nurse_resp)) prof_team,
                           
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
                                                            l_handoff_type,
                                                            'T') name_prof_tooltip,
                           -- 2) Responsible nurse
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_nurse,
                                                            ei.id_episode,
                                                            ei.id_first_nurse_resp,
                                                            l_handoff_type,
                                                            'T') name_nurse_tooltip,
                           -- 3) Responsible team 
                           pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         epis.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_handoff_type,
                                                         NULL) prof_team_tooltip,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid_amb.g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           sp.dt_target_tstz,
                           s.id_group,
                           pk_alert_constant.g_no flg_group_header,
                           'ExtendIcon' extend_icon
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN professional p
                        ON ps.id_professional = p.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                       AND ei.id_patient = sg.id_patient
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      LEFT JOIN discharge d
                        ON d.id_episode = epis.id_episode
                       AND d.dt_cancel_tstz IS NULL
                      LEFT JOIN disch_reas_dest drt
                        ON drt.id_disch_reas_dest = d.id_disch_reas_dest
                      LEFT JOIN dep_clin_serv dcs1
                        ON dcs1.id_dep_clin_serv = drt.id_dep_clin_serv
                      LEFT JOIN department dep1
                        ON dep1.id_department = dcs1.id_department
                      LEFT JOIN clinical_service cs1
                        ON cs1.id_clinical_service = dcs1.id_clinical_service
                      LEFT JOIN grid_task gt
                        ON gt.id_episode = epis.id_episode
                    -- JS, 2007-09-11 - Timezone
                     WHERE s.id_group IN (SELECT /*+OPT_ESTIMATE (TABLE k ROWS=0.00000000001)*/
                                           k.column_value
                                            FROM TABLE(l_group_ids) k)
                    --group header
                    UNION ALL
                    SELECT NULL       id_schedule, --s.id_schedule,
                           NULL       id_patient, --sg.id_patient,
                           NULL       id_episode, --decode(epis.flg_ehr,pk_ehr_access.g_flg_ehr_normal,epis.id_episode,decode(l_to_old_area, g_yes, NULL, epis.id_episode)) id_episode,
                           l_sch_t640 name, --  pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name,
                           l_sch_t640 name_to_sort, --  pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) name_to_sort,
                           NULL       pat_ndo, -- pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                           NULL       pat_nd_icon, --   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                           NULL       gender, --  pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender,
                           NULL       pat_age, --  pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                           NULL       photo, --  pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, s.id_schedule) photo,
                           --                           pk_translation.get_translation(i_lang, cs.code_clinical_service) ||
                           pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) ||
                           decode(s.id_sch_event,
                                  g_sch_event_therap_decision,
                                  ' - ' || l_sch_event_therap_decision,
                                  NULL) cons_type,
                           pk_date_utils.date_send_tsz(i_lang, sp.dt_target_tstz, i_prof) dt_target,
                           'A' flg_state,
                           sp.flg_sched,
                           p.nick_name prof_name,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        epis.dt_begin_tstz,
                                                                        i_prof.institution,
                                                                        i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv,
                           CASE
                               WHEN ei.id_episode IS NOT NULL THEN
                                decode(get_schedule_real_state(sp.flg_state, epis.flg_ehr),
                                       g_sched_scheduled,
                                       '',
                                       pk_date_utils.date_send_tsz(i_lang,
                                                                   epis.dt_begin_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software))
                               ELSE
                                NULL
                           END dt_efectiv_compl,
                           pk_grid_amb.get_group_state_icon(i_lang, i_prof, s.id_group) img_state,
                           pk_sysdomain.get_ranked_img('SCHEDULE_OUTP.FLG_SCHED', sp.flg_sched, i_lang) img_sched,
                           decode(pk_grid.get_prioritary_task(i_lang,
                                                              substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                                              substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                                              NULL,
                                                              g_flg_doctor),
                                  substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                  pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc),
                                  substr(gt.drug_req, instr(gt.drug_req, '|') + 1),
                                  pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_req)) desc_drug_vaccine_req,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              gt.nurse_activity,
                                                                                              pk_grid.get_prioritary_task(i_lang,
                                                                                                                          i_prof,
                                                                                                                          gt.intervention,
                                                                                                                          gt.monitorization,
                                                                                                                          NULL,
                                                                                                                          'D'),
                                                                                              NULL,
                                                                                              'D')) desc_nurse_interv_monit,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.movement) desc_mov,
                           pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.teach_req) desc_nurse_teach,
                           -- JS, 2007-09-11 - Timezone - Fim alteração
                           g_sysdate_char dt_server,
                           decode(instr(dep1.flg_type, 'I'),
                                  0,
                                  '',
                                  '',
                                  '',
                                  pk_message.get_message(i_lang, 'GRID_NURSE_M001') || ' ' ||
                                  pk_translation.get_translation(i_lang, cs1.code_clinical_service)) internment, --SS 2006/11/24
                           decode(sp.flg_state, g_sched_adm_disch, 3, g_sched_med_disch, 2, 1) rank,
                           pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                                   i_prof                      => i_prof,
                                                   i_waiting_room_available    => l_waiting_room_available,
                                                   i_waiting_room_sys_external => l_waiting_room_sys_external,
                                                   i_id_episode                => ei.id_episode,
                                                   i_flg_state                 => sp.flg_state,
                                                   i_flg_ehr                   => epis.flg_ehr,
                                                   i_id_dcs_requested          => s.id_dcs_requested) wr_call,
                           decode(s.id_sch_event,
                                  g_sch_event_therap_decision,
                                  '(' ||
                                  pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, ei.id_episode, s.id_schedule) || ')',
                                  NULL) therapeutic_doctor,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, ei.id_episode, l_handoff_type) resp_icon,
                           decode(epis.flg_ehr, 'S', NULL, pk_grid_amb.get_room_desc(i_lang, ei.id_room)) desc_room,
                           pk_patient.get_designated_provider(i_lang,
                                                              i_prof,
                                                              sg.id_patient,
                                                              decode(epis.flg_ehr,
                                                                     pk_ehr_access.g_flg_ehr_normal,
                                                                     epis.id_episode,
                                                                     decode(l_to_old_area, g_yes, NULL, epis.id_episode))) designated_provider,
                           NULL flg_contact_type, --sg.flg_contact_type,
                           pk_grid_amb.get_group_presence_icon(i_lang, i_prof, s.id_group, pk_alert_constant.g_no) icon_contact_type,
                           NULL flg_contact, --pk_adt.is_contact(i_lang, i_prof, sg.id_patient) flg_contact,
                           -- Display number of responsible PHYSICIANS for the episode, 
                           -- if institution is using the multiple hand-off mechanism,
                           -- along with the name of the main responsible for the patient.
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
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
                                                                      epis.id_department,
                                                                      ei.id_software,
                                                                      nvl(ei.id_professional, ps.id_professional),
                                                                      ei.id_first_nurse_resp)) prof_team,
                           
                           -- Display text in tooltips
                           -- 1) Responsible physician(s)
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_doc,
                                                            ei.id_episode,
                                                            nvl(ei.id_professional, ps.id_professional),
                                                            l_handoff_type,
                                                            'T') name_prof_tooltip,
                           -- 2) Responsible nurse
                           pk_grid_amb.get_responsibles_str(i_lang,
                                                            i_prof,
                                                            pk_alert_constant.g_cat_type_nurse,
                                                            ei.id_episode,
                                                            ei.id_first_nurse_resp,
                                                            l_handoff_type,
                                                            'T') name_nurse_tooltip,
                           -- 3) Responsible team 
                           pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         epis.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_handoff_type,
                                                         NULL) prof_team_tooltip,
                           pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                  i_prof,
                                                                  pk_grid.get_prioritary_task(i_lang,
                                                                                              i_prof,
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_analysis,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                             i_prof,
                                                                                                                             epis.id_visit,
                                                                                                                             g_task_exam,
                                                                                                                             i_prof_cat_type),
                                                                                              pk_grid_amb.g_analysis_exam_icon_grid_rank,
                                                                                              g_flg_doctor)) desc_ana_exam_req,
                           sp.dt_target_tstz,
                           s.id_group,
                           pk_alert_constant.g_yes flg_group_header,
                           NULL extend_icon
                      FROM schedule_outp sp
                      JOIN schedule s
                        ON s.id_schedule = sp.id_schedule
                      JOIN sch_group sg
                        ON sg.id_schedule = sp.id_schedule
                      JOIN patient pat
                        ON pat.id_patient = sg.id_patient
                      LEFT JOIN sch_prof_outp ps
                        ON ps.id_schedule_outp = sp.id_schedule_outp
                      LEFT JOIN professional p
                        ON ps.id_professional = p.id_professional
                      LEFT JOIN epis_info ei
                        ON ei.id_schedule = s.id_schedule
                       AND ei.id_patient = sg.id_patient
                      LEFT JOIN episode epis
                        ON epis.id_episode = ei.id_episode
                      LEFT JOIN clinical_service cs
                        ON cs.id_clinical_service = epis.id_cs_requested
                      LEFT JOIN discharge d
                        ON d.id_episode = epis.id_episode
                       AND d.dt_cancel_tstz IS NULL
                      LEFT JOIN disch_reas_dest drt
                        ON drt.id_disch_reas_dest = d.id_disch_reas_dest
                      LEFT JOIN dep_clin_serv dcs1
                        ON dcs1.id_dep_clin_serv = drt.id_dep_clin_serv
                      LEFT JOIN department dep1
                        ON dep1.id_department = dcs1.id_department
                      LEFT JOIN clinical_service cs1
                        ON cs1.id_clinical_service = dcs1.id_clinical_service
                      LEFT JOIN grid_task gt
                        ON gt.id_episode = epis.id_episode
                     WHERE s.id_schedule IN (SELECT /*+OPT_ESTIMATE (TABLE k ROWS=0.00000000001)*/
                                              k.column_value
                                               FROM TABLE(l_schedule_ids) k)
                    --
                    ) t
             ORDER BY t.rank, t.dt_target_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'NURSE_EFECTIV_MY_ROOMS');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_doc);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION exist_prescription
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_flg     IN VARCHAR2
    ) RETURN NUMBER IS
        /******************************************************************************
           OBJECTIVO: Saber se o episódio tem (Y) ou não (N) prescrições "até à próxima consulta" para hoje.
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                 I_PROF - prof q acede
                 I_EPISODE - ID do episódio
                 I_FLG - tarefa
                        SAIDA:   O_ERROR - erro
        
          CRIAÇÃO: SS 2006/02/08
          NOTAS:
        *********************************************************************************/
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        CURSOR c_interv_presc IS --Prescrição de procedimentos
            SELECT DISTINCT ss.id_sys_shortcut, ss.id_institution, ipp.dt_plan_tstz
              FROM procedures_ea pea, interv_presc_plan ipp, sys_shortcut ss
             WHERE pea.flg_time = g_flg_time_b
               AND (pea.id_episode = i_episode OR pea.id_episode_origin = i_episode)
               AND pea.flg_status_req != g_interv_canc
               AND pea.flg_status_det != g_interv_canc
               AND ipp.id_interv_presc_det = pea.id_interv_presc_det
               AND ipp.flg_status IN (g_interv_plan_pend, g_interv_plan_req)
               AND ipp.dt_plan_tstz BETWEEN l_dt_begin AND l_dt_end
               AND ss.intern_name = 'GRID_PROC'
               AND ss.id_software = i_prof.software
               AND ss.id_institution IN (0, i_prof.institution)
               AND rownum = 1
             ORDER BY ss.id_institution DESC, ipp.dt_plan_tstz ASC;
    
        -- Monitorizations
        CURSOR c_monit IS
            SELECT DISTINCT ss.id_sys_shortcut, ss.id_institution
              FROM monitorizations_ea mea, sys_shortcut ss
             WHERE mea.flg_time = g_flg_time_b
               AND mea.id_episode = i_episode
               AND mea.flg_status != g_monit_canc
               AND mea.flg_status_det != g_monit_canc
               AND mea.flg_status_plan IN (g_monit_plan_pend, g_monit_plan_inco)
               AND mea.dt_plan BETWEEN l_dt_begin AND l_dt_end
               AND ss.intern_name = 'GRID_MONITOR'
               AND ss.id_software = i_prof.software
               AND ss.id_institution IN (0, i_prof.institution)
             ORDER BY ss.id_institution DESC;
    
        CURSOR c_vaccine IS --Prescrição de vacinas
            SELECT DISTINCT ss.id_sys_shortcut, ss.id_institution
              FROM vaccine_prescription vp, vaccine_presc_det vpd, vaccine_presc_plan vpp, sys_shortcut ss
             WHERE vp.flg_time = g_flg_time_b
               AND vp.id_episode = i_episode
               AND vpd.id_vaccine_prescription = vp.id_vaccine_prescription
               AND vpp.id_vaccine_presc_det = vpd.id_vaccine_presc_det
               AND vpp.dt_plan_tstz BETWEEN l_dt_begin AND l_dt_end
               AND ss.intern_name = 'GRID_VACCINE'
               AND ss.id_software = i_prof.software
               AND ss.id_institution IN (0, i_prof.institution)
             ORDER BY ss.id_institution DESC;
    
        l_shortcut sys_shortcut.id_sys_shortcut%TYPE;
        l_inst     sys_shortcut.id_institution%TYPE;
        l_date     interv_presc_plan.dt_plan_tstz%TYPE;
    BEGIN
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp);
        l_dt_end   := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp + INTERVAL '1' DAY);
    
        IF i_flg = 'D'
        THEN
            -- from 2.6.1.2 onwards, medication does not support
            -- the concept of tasks between episodes
            l_shortcut := NULL;
        ELSIF i_flg = 'I'
        THEN
            OPEN c_interv_presc;
            FETCH c_interv_presc
                INTO l_shortcut, l_inst, l_date;
            CLOSE c_interv_presc;
        ELSIF i_flg = 'M'
        THEN
            OPEN c_monit;
            FETCH c_monit
                INTO l_shortcut, l_inst;
            CLOSE c_monit;
        ELSIF i_flg = 'V'
        THEN
            OPEN c_vaccine;
            FETCH c_vaccine
                INTO l_shortcut, l_inst;
            CLOSE c_vaccine;
        ELSIF i_flg = 'P'
        THEN
            l_shortcut := NULL;
        END IF;
    
        RETURN l_shortcut;
    END exist_prescription;

    FUNCTION exist_prescription
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_flg     IN VARCHAR2,
        i_dt      IN VARCHAR2
    ) RETURN NUMBER IS
        /******************************************************************************
           OBJECTIVO: Saber se o episódio tem (Y) ou não (N) prescrições "até à próxima consulta" para hoje.
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                 I_PROF - prof q acede
                 I_EPISODE - ID do episódio
                 I_FLG - tarefa
                        SAIDA:   O_ERROR - erro
        
          CRIAÇÃO: SS 2006/02/08
          NOTAS:
        *********************************************************************************/
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        CURSOR c_interv_presc IS --Prescrição de procedimentos
            SELECT DISTINCT ss.id_sys_shortcut, ss.id_institution, ipp.dt_plan_tstz
              FROM procedures_ea pea, interv_presc_plan ipp, sys_shortcut ss
             WHERE pea.flg_time = g_flg_time_b
               AND (pea.id_episode = i_episode OR pea.id_episode_origin = i_episode)
               AND pea.flg_status_req != g_interv_canc
               AND pea.flg_status_det != g_interv_canc
               AND ipp.id_interv_presc_det = pea.id_interv_presc_det
               AND ipp.flg_status IN (g_interv_plan_pend, g_interv_plan_req)
               AND ipp.dt_plan_tstz BETWEEN l_dt_begin AND l_dt_end
               AND ss.intern_name = 'GRID_PROC'
               AND ss.id_software = i_prof.software
               AND ss.id_institution IN (0, i_prof.institution)
               AND rownum = 1
             ORDER BY ss.id_institution DESC, ipp.dt_plan_tstz ASC;
    
        -- Monitorizations
        CURSOR c_monit IS
            SELECT DISTINCT ss.id_sys_shortcut, ss.id_institution
              FROM monitorizations_ea mea, sys_shortcut ss
             WHERE mea.flg_time = g_flg_time_b
               AND mea.id_episode = i_episode
               AND mea.flg_status != g_monit_canc
               AND mea.flg_status_det != g_monit_canc
               AND mea.flg_status_plan IN (g_monit_plan_pend, g_monit_plan_inco)
               AND mea.dt_plan BETWEEN l_dt_begin AND l_dt_end
               AND ss.intern_name = 'GRID_MONITOR'
               AND ss.id_software = i_prof.software
               AND ss.id_institution IN (0, i_prof.institution)
             ORDER BY ss.id_institution DESC;
    
        CURSOR c_vaccine IS --Prescrição de vacinas
            SELECT DISTINCT ss.id_sys_shortcut, ss.id_institution
              FROM vaccine_prescription vp, vaccine_presc_det vpd, vaccine_presc_plan vpp, sys_shortcut ss
             WHERE vp.flg_time = g_flg_time_b
               AND vp.id_episode = i_episode
               AND vpd.id_vaccine_prescription = vp.id_vaccine_prescription
               AND vpp.id_vaccine_presc_det = vpd.id_vaccine_presc_det
               AND vpp.dt_plan_tstz BETWEEN l_dt_begin AND l_dt_end
               AND ss.intern_name = 'GRID_VACCINE'
               AND ss.id_software = i_prof.software
               AND ss.id_institution IN (0, i_prof.institution)
             ORDER BY ss.id_institution DESC;
    
        l_shortcut sys_shortcut.id_sys_shortcut%TYPE;
        l_inst     sys_shortcut.id_institution%TYPE;
        l_date     interv_presc_plan.dt_plan_tstz%TYPE;
    BEGIN
        /*l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp);
        l_dt_end   := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp + INTERVAL '1' DAY);*/
        g_sysdate_tstz := current_timestamp;
        l_dt_begin     := pk_date_utils.trunc_insttimezone(i_prof,
                                                           nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                               g_sysdate_tstz));
        l_dt_end       := pk_date_utils.add_days_to_tstz(l_dt_begin, 1);
    
        IF i_flg = 'D'
        THEN
            -- from 2.6.1.2 onwards, medication does not support
            -- the concept of tasks between episodes
            l_shortcut := NULL;
        ELSIF i_flg = 'I'
        THEN
            OPEN c_interv_presc;
            FETCH c_interv_presc
                INTO l_shortcut, l_inst, l_date;
            CLOSE c_interv_presc;
        ELSIF i_flg = 'M'
        THEN
            OPEN c_monit;
            FETCH c_monit
                INTO l_shortcut, l_inst;
            CLOSE c_monit;
        ELSIF i_flg = 'V'
        THEN
            OPEN c_vaccine;
            FETCH c_vaccine
                INTO l_shortcut, l_inst;
            CLOSE c_vaccine;
        ELSIF i_flg = 'P'
        THEN
            l_shortcut := NULL;
        END IF;
    
        RETURN l_shortcut;
    END exist_prescription;

    FUNCTION min_dt_treatment
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN TIMESTAMP IS
        /******************************************************************************
           OBJECTIVO: Encontrar a 1ª data de tratamento p/ a 2ª grelha d eenfermagem
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                 I_PROF - prof q acede
                 I_EPISODE - ID do episódio
                        SAIDA:   O_ERROR - erro
        
          CRIAÇÃO: CRS 2006/07/20
          NOTAS:
        *********************************************************************************/
        l_dt DATE;
    
        CURSOR c_date IS
            SELECT MIN(dt_plan_tstz)
              FROM (SELECT DISTINCT ss.id_institution, ipp.dt_plan_tstz
                      FROM procedures_ea pea, interv_presc_plan ipp, sys_shortcut ss
                     WHERE pea.flg_time = g_flg_time_b
                       AND pea.id_episode = i_episode
                       AND pea.flg_status_req != g_interv_canc
                       AND pea.flg_status_det != g_interv_canc
                       AND ipp.id_interv_presc_det = pea.id_interv_presc_det
                       AND ipp.flg_status IN (g_interv_plan_pend, g_interv_plan_req)
                       AND pk_date_utils.trunc_insttimezone(i_prof, ipp.dt_plan_tstz) =
                           pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz)
                       AND ss.intern_name = 'GRID_PROC'
                       AND ss.id_software = i_prof.software
                       AND ss.id_institution IN (0, i_prof.institution)
                    
                    UNION
                    
                    -- Monitorizations
                    SELECT DISTINCT ss.id_institution, mea.dt_plan
                      FROM monitorizations_ea mea, sys_shortcut ss
                     WHERE mea.flg_time = g_flg_time_b
                       AND mea.id_episode = i_episode
                       AND mea.flg_status != g_monit_canc
                       AND mea.flg_status_det != g_monit_canc
                       AND mea.flg_status_plan IN (g_monit_plan_pend, g_monit_plan_inco)
                       AND pk_date_utils.trunc_insttimezone(i_prof, mea.dt_plan) =
                           pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz)
                       AND ss.intern_name = 'GRID_MONITOR'
                       AND ss.id_software = i_prof.software
                       AND ss.id_institution IN (0, i_prof.institution)
                    
                    UNION
                    
                    SELECT DISTINCT ss.id_institution, vpp.dt_plan_tstz
                      FROM vaccine_prescription vp, vaccine_presc_det vpd, vaccine_presc_plan vpp, sys_shortcut ss
                     WHERE vp.flg_time = g_flg_time_b
                       AND vp.id_episode = i_episode
                       AND vpd.id_vaccine_prescription = vp.id_vaccine_prescription
                       AND vpp.id_vaccine_presc_det = vpd.id_vaccine_presc_det
                       AND pk_date_utils.trunc_insttimezone(i_prof, vpp.dt_plan_tstz) =
                           pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz)
                       AND ss.intern_name = 'GRID_VACCINE'
                       AND ss.id_software = i_prof.software
                       AND ss.id_institution IN (0, i_prof.institution));
    
    BEGIN
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN C_DATE';
        OPEN c_date;
        FETCH c_date
            INTO l_dt;
        CLOSE c_date;
    
        RETURN l_dt;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION technician_req
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:  Grelha dos técnicos de cardiopneumologia, audiologia, ortótica.
                   Lista de exames requisitados (para o serviço do utilizador) e ainda não agendados
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                 I_PROF - prof q acede
                        SAIDA:   O_DOC - array
                                 O_ERROR - erro
        
          CRIAÇÃO: SS 2005/11/21
          ALTERAÇÃO: CRS 2006/07/20 Excluir episódios cancelados
                     ASM 2007-03-26 Adicionado um campo de saída no cursor: "Departamento - Especialidade"
          NOTAS:
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'GET O_GRID';
        OPEN o_grid FOR
            SELECT DISTINCT gtoe.rank,
                            gtoe.acuity,
                            gtoe.rank_acuity,
                            pk_message.get_message(i_lang,
                                                   profissional(i_prof.id, i_prof.institution, gtoe.id_software),
                                                   'IMAGE_T009') epis_type,
                            gtoe.id_schedule,
                            gtoe.id_episode,
                            'E' flg_type,
                            gtoe.id_patient,
                            pk_patient.get_pat_name(i_lang, i_prof, gtoe.id_patient, gtoe.id_episode, gtoe.id_schedule) name,
                            pk_patient.get_pat_name_to_sort(i_lang,
                                                            i_prof,
                                                            gtoe.id_patient,
                                                            gtoe.id_episode,
                                                            gtoe.id_schedule) name_to_sort,
                            pk_adt.get_pat_non_disc_options(i_lang, i_prof, gtoe.id_patient) pat_ndo,
                            pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, gtoe.id_patient) pat_nd_icon,
                            pk_patient.get_gender(i_lang, gtoe.gender) gender,
                            gtoe.pat_age,
                            pk_patphoto.get_pat_photo(i_lang,
                                                      i_prof,
                                                      gtoe.id_patient,
                                                      gtoe.id_episode,
                                                      gtoe.id_schedule) photo,
                            gtoe.num_clin_record,
                            gtoe.nick_name,
                            pk_translation.get_translation(i_lang, 'SPECIALITY.CODE_SPECIALITY.' || p.id_speciality) desc_speciality,
                            gtoe.id_exam,
                            pk_exams_api_db.get_alias_translation(i_lang,
                                                                  i_prof,
                                                                  'EXAM.CODE_EXAM.' || gtoe.id_exam,
                                                                  NULL) desc_exam,
                            pk_date_utils.dt_chr_tsz(i_lang, gtoe.dt_req_tstz, i_prof) date_target,
                            pk_date_utils.date_char_hour_tsz(i_lang,
                                                             gtoe.dt_req_tstz,
                                                             i_prof.institution,
                                                             i_prof.software) hour_target,
                            gtoe.id_exam_req,
                            pk_date_utils.to_char_insttimezone(i_prof, gtoe.dt_req_tstz, 'YYYYMMDDHH24MISS') dt_ord1,
                            gtoe.id_exam_req_det,
                            pk_translation.get_translation(i_lang, 'DEPT.CODE_DEPT.' || gtoe.id_dept) || ' - ' ||
                            pk_translation.get_translation(i_lang,
                                                           'CLINICAL_SERVICE.CODE_CLINICAL_SERVICE.' ||
                                                           gtoe.id_clinical_service) dept
              FROM grid_task_oth_exm gtoe, exam_cat_dcs ecdcs, professional p
             WHERE gtoe.dt_begin_tstz IS NULL
               AND gtoe.id_institution = i_prof.institution
               AND gtoe.flg_time IN (g_flg_time_b, pk_exam_constant.g_flg_time_d)
               AND gtoe.id_professional = p.id_professional
               AND gtoe.id_exam_cat = ecdcs.id_exam_cat
               AND EXISTS (SELECT 1
                      FROM prof_dep_clin_serv pdcs
                     WHERE pdcs.id_professional = i_prof.id
                       AND pdcs.flg_status = pk_exam_constant.g_selected
                       AND pdcs.id_institution = i_prof.institution
                       AND pdcs.id_dep_clin_serv = ecdcs.id_dep_clin_serv)
             ORDER BY date_target, hour_target;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'TECHNICIAN_REQ');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_grid);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION coord_efectiv
    (
        i_lang          IN language.id_language%TYPE,
        i_epis_type     IN schedule_outp.id_epis_type%TYPE,
        i_prof          IN profissional,
        i_dt            IN VARCHAR2,
        i_type          IN VARCHAR2,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_doc           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Grelha do coordenador, para ver consultas agendadas já efectivadas
                  das especialidades a que está alocado
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_EPIS_TYPE - Tipo de episódio (CE, URG, ...)
                 I_PROF - prof q acede
                   I_DT - data
                 I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                       como é retornada em PK_LOGIN.GET_PROF_PREF
                        SAIDA:   O_DOC - array
                                 O_ERROR - erro
        
          CRIAÇÃO: RB 2005/05/06
          NOTAS: SS - Igual à grelha do enfermeiro
        *********************************************************************************/
    BEGIN
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz := current_timestamp;
    
        -- JS, 2007-09-10 - Timezone
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'GET CURSOR';
        OPEN o_doc FOR
            SELECT ei.id_schedule,
                   sg.id_patient,
                   epis.id_episode,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) photo,
                   --                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                   pk_date_utils.date_char_hour_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_target,
                   sp.flg_state,
                   sp.flg_sched,
                   p.nick_name prof_name,
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                   lpad(to_char(sd1.rank), 6, '0') || sd1.img_name img_state,
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_sched,
                   pk_grid.convert_grid_task_str(i_lang, i_prof, gt.clin_rec_req) desc_cli_rec_req,
                   pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_req) desc_drug_req,
                   decode(pk_grid.get_prioritary_task(i_lang,
                                                      /*I_MESS1 => */
                                                      substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                                                      /*I_MESS2 => */
                                                      substr(gt.vaccine, instr(gt.vaccine, '|') + 1),
                                                      /*I_DOMAIN => */
                                                      NULL,
                                                      /*I_CAT_TYPE => */
                                                      g_flg_doctor),
                          substr(gt.drug_presc, instr(gt.drug_presc, '|') + 1),
                          pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_presc),
                          pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.vaccine)) desc_drug_vaccine_req,
                   pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                          i_prof,
                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                      i_prof,
                                                                                      gt.nurse_activity,
                                                                                      pk_grid.get_prioritary_task(i_lang,
                                                                                                                  i_prof,
                                                                                                                  gt.intervention,
                                                                                                                  gt.monitorization,
                                                                                                                  NULL,
                                                                                                                  'D'),
                                                                                      NULL,
                                                                                      'D')) desc_nurse_interv_monit,
                   pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_analysis, i_prof_cat_type) desc_analysis_req,
                   pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_exam, i_prof_cat_type) desc_exam_req,
                   pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.movement) desc_mov,
                   pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.teach_req) desc_nurse_teach,
                   -- JS, 2007-09-10 - Timezone  - Fim de alteração
                   g_sysdate_char dt_server,
                   decode(instr(dep1.flg_type, 'I'),
                          '',
                          '',
                          pk_message.get_message(i_lang, 'GRID_NURSE_M001') || ' ' ||
                          pk_translation.get_translation(i_lang, cs1.code_clinical_service)) internment --SS 2006/11/24
              FROM schedule_outp      sp,
                   sch_group          sg,
                   professional       p,
                   patient            pat,
                   clinical_service   cs,
                   epis_info          ei,
                   episode            epis,
                   prof_dep_clin_serv pdcs,
                   clin_record        cr,
                   department         dep1,
                   disch_reas_dest    drt,
                   dep_clin_serv      dcs1,
                   clinical_service   cs1,
                   grid_task          gt,
                   sys_domain         sd,
                   sys_domain         sd1
            -- JS, 2007-09-11 - Timezone
             WHERE sp.dt_target_tstz BETWEEN
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                    nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                        g_sysdate_tstz)) AND
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                    nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                        g_sysdate_tstz)) + INTERVAL '1'
             DAY
               AND sp.id_software = i_prof.software
               AND sp.flg_state != g_sched_adm_disch
               AND ei.id_schedule = sp.id_schedule
                  -- Sílvia Freitas 28-05-2008
               AND epis.flg_ehr != g_flg_ehr
               AND ei.id_instit_requested = i_prof.institution
               AND ei.flg_sch_status != g_sched_canc
               AND ei.sch_prof_outp_id_prof = p.id_professional(+)
               AND cs.id_clinical_service = epis.id_cs_requested
               AND sg.id_schedule = sp.id_schedule
               AND pat.id_patient = sg.id_patient
               AND epis.id_episode = ei.id_episode
               AND gt.id_episode(+) = epis.id_episode
               AND pdcs.id_dep_clin_serv = ei.id_dcs_requested
               AND pdcs.id_professional = i_prof.id
               AND pdcs.flg_status = g_selected
               AND cr.id_patient = pat.id_patient
               AND cr.id_institution = i_prof.institution
               AND nvl(ei.flg_dsch_status, 'A') NOT IN
                   (pk_discharge_core.g_disch_status_cancel, pk_discharge_core.g_disch_status_reopen)
               AND ei.dt_admin_tstz IS NULL -- s/ alta administrativa
               AND drt.id_disch_reas_dest(+) = ei.id_disch_reas_dest
               AND dcs1.id_dep_clin_serv(+) = drt.id_dep_clin_serv -- alta para dep. dentro da instituição
               AND cs1.id_clinical_service(+) = dcs1.id_clinical_service
               AND dep1.id_department(+) = dcs1.id_department
               AND sd.code_domain(+) = 'SCHEDULE_OUTP.FLG_SCHED'
               AND sd.val(+) = sp.flg_sched
               AND sd.id_language(+) = i_lang
               AND sd.domain_owner(+) = pk_sysdomain.k_default_schema
               AND sd1.code_domain = 'SCHEDULE_OUTP.FLG_STATE'
               AND sd1.val = sp.flg_state
               AND sd1.domain_owner = pk_sysdomain.k_default_schema
               AND sd1.id_language = i_lang
            -- JS, 2007-09-10 - Timezone
             ORDER BY sp.dt_target_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'COORD_EFECTIV');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_doc);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION coord_efectiv_location
    (
        i_lang      IN language.id_language%TYPE,
        i_epis_type IN schedule_outp.id_epis_type%TYPE,
        i_prof      IN profissional,
        i_dt        IN VARCHAR2,
        i_type      IN VARCHAR2,
        o_doc       OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Grelha do coordenador
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_EPIS_TYPE - Tipo de episódio (CE, URG, ...)
                 I_PROF - prof q acede
                   I_DT - data
                        SAIDA:   O_DOC - array
                                 O_ERROR - erro
        
          CRIAÇÃO: SS 2005/12/30
          NOTAS: Igual à grelha do enfermeiro mas em vez de ter tempos associados a tarefas
                 tem a localização física dos pacientes
        *********************************************************************************/
    BEGIN
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz := current_timestamp;
    
        -- JS, 2007-09-10 - Timezone
        g_sysdate_char := pk_date_utils.date_send(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'GET CURSOR';
        OPEN o_doc FOR
            SELECT ei.id_schedule,
                   sg.id_patient,
                   epis.id_episode,
                   pk_patient.get_pat_name(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) name_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, sg.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sg.id_patient) pat_nd_icon,
                   pat.gender,
                   pk_patient.get_pat_age(i_lang, pat.id_patient, i_prof) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, sg.id_patient, epis.id_episode, ei.id_schedule) photo,
                   --                   pk_translation.get_translation(i_lang, cs.code_clinical_service) cons_type,
                   pk_hea_prv_aux.get_clin_service(i_lang, i_prof, ei.id_dep_clin_serv) cons_type,
                   -- JS, 2007-09-10 - Timezone
                   pk_date_utils.date_char_hour_tsz(i_lang, sp.dt_target_tstz, i_prof.institution, i_prof.software) dt_target,
                   sp.flg_state,
                   sp.flg_sched,
                   p.nick_name prof_name,
                   -- JS, 2007-09-10 - Timezone
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_efectiv_compl,
                   lpad(to_char(sd.rank), 6, '0') || sd.img_name img_sched,
                   g_sysdate_char dt_server,
                   decode(get_sched_time(i_lang, ei.id_schedule, g_sched_scheduled),
                          NULL,
                          NULL,
                          pk_sysdomain.get_img(i_lang, 'SCHEDULE_OUTP.FLG_STATE', g_sched_scheduled)) time_not_arrived,
                   get_sched_time(i_lang, ei.id_schedule, g_sched_efectiv) time_waiting_room,
                   get_sched_time(i_lang, ei.id_schedule, g_sched_wait) time_waiting_corridor,
                   get_sched_time(i_lang, ei.id_schedule, g_sched_nurse) time_nurse,
                   get_sched_time(i_lang, ei.id_schedule, g_flg_state_p) time_disch_nurse,
                   get_sched_time(i_lang, ei.id_schedule, g_sched_cons) time_doctor,
                   get_sched_time(i_lang, ei.id_schedule, g_sched_med_disch) time_disch_doctor,
                   get_sched_time(i_lang, ei.id_schedule, g_sched_adm_disch) time_admin
              FROM schedule_outp      sp,
                   sch_group          sg,
                   professional       p,
                   patient            pat,
                   clinical_service   cs,
                   epis_info          ei,
                   episode            epis,
                   prof_dep_clin_serv pdcs,
                   clin_record        cr,
                   disch_reas_dest    drt,
                   dep_clin_serv      dcs1,
                   clinical_service   cs1,
                   sys_domain         sd
            -- JS, 2007-09-11 - Timezone
             WHERE sp.dt_target_tstz BETWEEN
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                    nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                        g_sysdate_tstz)) AND
                   pk_date_utils.trunc_insttimezone(i_prof,
                                                    nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                        g_sysdate_tstz)) + INTERVAL '1'
             DAY
               AND sp.flg_state != g_sched_adm_disch
               AND sp.id_software = i_prof.software
               AND ei.id_schedule = sp.id_schedule
               AND ei.id_instit_requested = i_prof.institution
               AND ei.flg_sch_status != g_sched_canc
               AND ei.sch_prof_outp_id_prof = p.id_professional(+)
               AND cs.id_clinical_service = epis.id_cs_requested
               AND sg.id_schedule = sp.id_schedule
               AND pat.id_patient = sg.id_patient
               AND epis.id_episode = ei.id_episode
                  -- Sílvia Freitas 28-05-2008
               AND epis.flg_ehr != g_flg_ehr
               AND pdcs.id_dep_clin_serv = ei.id_dcs_requested
               AND pdcs.id_professional = i_prof.id
               AND pdcs.flg_status = g_selected
               AND cr.id_patient = pat.id_patient
               AND cr.id_institution = i_prof.institution
                  -- JS, 2007-09-11 - Timezone
               AND nvl(ei.flg_dsch_status, 'A') NOT IN
                   (pk_discharge_core.g_disch_status_cancel, pk_discharge_core.g_disch_status_reopen)
               AND ei.dt_admin_tstz IS NULL -- s/ alta administrativa              
               AND drt.id_disch_reas_dest(+) = ei.id_disch_reas_dest
               AND dcs1.id_dep_clin_serv(+) = drt.id_dep_clin_serv -- alta para dep. dentro da instituição
               AND cs1.id_clinical_service(+) = dcs1.id_clinical_service
               AND sd.code_domain(+) = 'SCHEDULE_OUTP.FLG_SCHED'
               AND sd.val(+) = sp.flg_sched
               AND sd.domain_owner(+) = pk_sysdomain.k_default_schema
               AND sd.id_language(+) = i_lang
            -- JS, 2007-09-11 - Timezone
             ORDER BY sp.dt_target_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'COORD_EFECTIV_LOCATION');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_doc);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_sched_time
    (
        i_lang     IN language.id_language%TYPE,
        i_schedule IN schedule.id_schedule%TYPE,
        i_state    IN schedule_outp.flg_state%TYPE
    ) RETURN VARCHAR2 IS
        /***************************************************************************************
           OBJECTIVO:   Obter info sobre há quanto tempo o paciente está num determinado "local"
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                 I_PROF - prof q acede
                   I_SCHEDULE - data
                 I_STATE - flag da localização:
                             A - ainda não chegou nem efectivou
                       E - sala de espera
                       C - corredor
                       N - consulta de enfermagem
                       P - alta de enfermagem
                       T - consulta médica
                       D - alta médica
                       M - atendimento administrativo pós-alta
        
          CRIAÇÃO: SS 2005/12/30
          NOTAS:
        *****************************************************************************************/
        CURSOR c_time IS
        -- JS, 2007-09-10 - Timezone
        -- SELECT pk_date_utils.get_elapsed(i_lang, g_sysdate, dt_target)
            SELECT pk_date_utils.get_elapsed_tsz(i_lang, g_sysdate_tstz, dt_target_tstz)
              FROM schedule_outp
             WHERE id_schedule = i_schedule
               AND flg_state = i_state;
    
        l_time VARCHAR2(10);
    
    BEGIN
    
        -- JS, 2007-09-10 - Timezone
        -- g_sysdate := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_time;
        FETCH c_time
            INTO l_time;
        CLOSE c_time;
    
        RETURN l_time;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION set_doc_call
    (
        i_lang          IN language.id_language%TYPE,
        i_epis          IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Avisar o coordenador da chamada do médico
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_EPIS - ID do episódio
                     I_PROF - prof q faz a chamada
                 I_PROF - prof q acede
                 I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                       como é retornada em PK_LOGIN.GET_PROF_PREF
                        SAIDA:   O_ERROR - erro
        
          CRIAÇÃO: CRS 2005/04/26
          NOTAS:
        *********************************************************************************/
        l_error t_error_out;
    
    BEGIN
    
        -- JS, 2007-09-10 - Timezone
        -- g_sysdate := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        -- JS, 2007-09-10 - Timezone
        g_sysdate_char := pk_date_utils.date_send(i_lang, g_sysdate_tstz, i_prof);
    
        g_error := 'UPDATE SCHEDULE_OUTP';
        UPDATE schedule_outp
           SET flg_state = g_sched_wait
         WHERE id_schedule = (SELECT id_schedule
                                FROM epis_info
                               WHERE id_episode = i_epis);
    
        g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang          => i_lang,
                                      i_id_episode    => i_epis,
                                      i_pat           => NULL,
                                      i_prof          => i_prof,
                                      i_prof_cat_type => i_prof_cat_type,
                                      -- JS, 2007-09-10 - Timezone
                                      -- i_dt_last_interaction => g_sysdate,
                                      -- i_dt_first_obs        => g_sysdate,
                                      i_dt_last_interaction => g_sysdate_char,
                                      i_dt_first_obs        => g_sysdate_char,
                                      o_error               => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'SET_DOC_CALL');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_last_vaccine_presc
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        i_id_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Obter dados das últimas prescrições de vacinas
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_ID_PAT - Id do doente
                  Saida:   O_MESSAGE - Cadeia de caracteres em que:
                                1ª posição indica o atalho: X - s/ atalho
                                            D - prescrição de medicamentos
                                      V - prescrição de vacinas
                                      G - req de imagem
                                      F - req de prova funcional
                                      I - req de procedimentos
                                      N - req de pensos
                                      M - monitorização
                                      T - ensino de enfermagem
                                      H - colheitas
                                      A - requisição / resultados de análises
                        2ª posição indica se é uma M-mensagem ou um I-icon
                        3ª posição indica a cor (só tem relevância se se tratar de uma mensagem
                        4ª posição indica se é um texto ou uma duração em horas
                        a partir da 4ª posição é a mensagem ou o nome do icon a mostrar
                     O_ERROR - erro
          CRIAÇÃO: RB 2005/05/04
          NOTAS:
        *********************************************************************************/
        l_error t_error_out;
        l_mess1 VARCHAR2(200);
        l_mess2 VARCHAR2(200);
    
        -- Requisições ñ canceladas do epis. actual
        CURSOR c_vaccine IS
            SELECT epis.flg_status epis_status,
                   dp.flg_time,
                   dp.flg_status,
                   -- JS, 2007-09-10 - Timezone
                   dp.dt_begin_tstz,
                   dp.dt_vaccine_prescription_tstz dt_req,
                   epis.dt_begin_tstz epis_dt_begin,
                   pk_sysdomain.get_img(i_lang, 'VACCINE_PRESCRIPTION.FLG_STATUS', dp.flg_status) img_name
              FROM vaccine_prescription dp, episode epis
             WHERE dp.id_episode = i_id_epis
               AND dp.flg_status IN (g_vaccine_pend, g_vaccine_req)
               AND epis.id_episode = dp.id_episode
             ORDER BY decode(dp.flg_time, g_flg_time_e, 1, g_flg_time_b, 2, g_flg_time_n, 3), dt_req;
    
    BEGIN
        -- Corre todas as prescrições encontradas.
        -- Para cada, obtem a cadeia de caracteres. Nas instâncias consecutivas do loop
        -- compara-se cada string com a anterior e determina-se a prioridade
        FOR cur IN c_vaccine
        LOOP
            l_mess2 := get_presc_req_icon_time(i_lang,
                                               i_id_pat,
                                               cur.epis_status,
                                               cur.flg_time,
                                               cur.flg_status,
                                               -- JS, 2007-09-10 - Timezone
                                               cur.dt_begin_tstz,
                                               cur.dt_req,
                                               cur.img_name,
                                               l_error);
        
            IF l_error.log_id IS NOT NULL
            THEN
                RETURN NULL;
            END IF;
        
            IF l_mess1 IS NOT NULL
            THEN
                l_mess1 := pk_grid.get_first_prec_icon(l_mess1,
                                                       l_mess2,
                                                       'VACCINE_PRESCRIPTION.FLG_STATUS',
                                                       g_flg_doctor);
            END IF;
        
            l_mess1 := nvl(l_mess1, l_mess2);
        END LOOP;
    
        RETURN l_mess1;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_last_monitorization
    (
        i_lang    IN language.id_language%TYPE,
        i_id_pat  IN patient.id_patient%TYPE,
        i_id_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Obter dados das últimas leituras
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_ID_PAT - Id do doente
                  Saida:   O_MESSAGE - Cadeia de caracteres em que:
                                1ª posição indica o atalho: X - s/ atalho
                                            D - prescrição de medicamentos
                                      V - prescrição de vacinas
                                      G - req de imagem
                                      F - req de prova funcional
                                      I - req de procedimentos
                                      N - req de pensos
                                      M - monitorização
                                      T - ensino de enfermagem
                                      H - colheitas
                                      A - requisição / resultados de análises
                        2ª posição indica se é uma M-mensagem ou um I-icon
                        3ª posição indica a cor (só tem relevância se se tratar de uma mensagem
                        4ª posição indica se é um texto ou uma duração em horas
                        a partir da 4ª posição é a mensagem ou o nome do icon a mostrar
                     O_ERROR - erro
          CRIAÇÃO: RB 2005/05/04
          NOTAS:
        *********************************************************************************/
        l_error t_error_out;
        l_mess1 VARCHAR2(200);
        l_mess2 VARCHAR2(200);
    
        -- Requisições ñ canceladas do epis. actual
        CURSOR c_monit IS
            SELECT epis.flg_status epis_status,
                   mea.flg_time,
                   mea.flg_status_plan,
                   decode(nvl(mea.id_episode_origin, 0), 0, mea.dt_plan, mea.dt_begin) dt_begin,
                   mea.dt_monitorization dt_req,
                   epis.dt_begin_tstz epis_dt_begin,
                   pk_sysdomain.get_img(1, 'MONITORIZATION.FLG_STATUS', mea.flg_status) img_name
              FROM monitorizations_ea mea, episode epis
             WHERE mea.id_episode = i_id_epis
               AND mea.flg_status_plan IN (g_monit_pend, g_monit_exe)
               AND epis.id_episode = mea.id_episode
             ORDER BY decode(mea.flg_time, g_flg_time_e, 1, g_flg_time_b, 2, g_flg_time_n, 3), dt_req;
    
    BEGIN
        FOR cur IN c_monit
        LOOP
        
            --Obtem valor 2 para comparar
            l_mess2 := get_presc_req_icon_time(i_lang,
                                               i_id_pat,
                                               cur.epis_status,
                                               cur.flg_time,
                                               cur.flg_status_plan,
                                               cur.dt_begin,
                                               cur.dt_req,
                                               cur.img_name,
                                               l_error);
        
            IF l_error.log_id IS NOT NULL
            THEN
                RETURN NULL;
            END IF;
        
            IF l_mess1 IS NOT NULL
            THEN
                --O valor com maior precedência fica sempre em l_mess1
                l_mess1 := pk_grid.get_first_prec_icon(l_mess1, l_mess2, 'MONITORIZATION.FLG_STATUS', g_flg_doctor);
            END IF;
        
            --se o valor 1 estiver vazio é porque apenas havia um registo
            l_mess1 := nvl(l_mess1, l_mess2);
        
        END LOOP;
    
        RETURN l_mess1;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_mov_desc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Obter dados das requisições de movimentos do episódio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_EPIS - Id do episódio
                  Saida:   Cadeia de caracteres em que:
                                1ª posição indica o atalho: X - s/ atalho
                                            D - prescrição de medicamentos
                                      V - prescrição de vacinas
                                      G - req de imagem
                                      F - req de prova funcional
                                      I - req de procedimentos
                                      N - req de pensos
                                      M - monitorização
                                      T - ensino de enfermagem
                                      H - colheitas
                                      A - requisição / resultados de análises
                        2ª posição indica se é uma M-mensagem ou um I-icon
                        3ª posição indica a cor (só tem relevância se se tratar de uma mensagem
                        4ª posição indica se é um texto ou uma duração em horas
                        a partir da 4ª posição é a mensagem ou o nome do icon a mostrar
                     O_ERROR - erro
          CRIAÇÃO: CRS 2005/06/03
          NOTAS:
        *********************************************************************************/
        CURSOR c_mov IS
        -- JS, 2007-09-10 - Timezone
        -- SELECT s.rank, mov.dt_req, mov.flg_status, nvl(mov.dt_begin, mov.dt_req) dt_begin
            SELECT s.rank, mov.dt_req_tstz, mov.flg_status, nvl(mov.dt_begin_tstz, mov.dt_req_tstz) dt_begin_tstz
              FROM movement mov, sys_domain s
             WHERE mov.id_episode = i_epis
               AND mov.flg_status NOT IN (g_mov_status_cancel, g_mov_status_finish, g_mov_status_interr)
               AND mov.flg_status = s.val
               AND s.code_domain = 'MOVEMENT.FLG_STATUS'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
            -- JS, 2007-09-10 - Timezone
            -- ORDER BY dt_begin DESC;
             ORDER BY dt_begin_tstz DESC;
    
        l_rank sys_domain.rank%TYPE;
        -- JS, 2007-09-10 - Timezone
        -- l_dt_req       movement.dt_req%TYPE;
        -- l_dt_begin     movement.dt_begin%TYPE;
        l_dt_req       movement.dt_req_tstz%TYPE;
        l_dt_begin     movement.dt_begin_tstz%TYPE;
        l_status       movement.flg_status%TYPE;
        l_out          VARCHAR2(100);
        l_elapsed_time VARCHAR2(100);
    BEGIN
        -- JS, 2007-09-10 - Timezone
        -- g_sysdate := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_found        := FALSE;
    
        g_error := 'LOOP';
        -- Vamos percorrer todos os mov. "em transporte", "requisitado", ou "pendente" do epis.
        -- e escolher aquele cujo Rank do estado é mais prioritário
        FOR r_mov IN c_mov
        LOOP
            g_found := TRUE;
            IF nvl(l_rank, r_mov.rank) >= r_mov.rank
            THEN
                l_rank := r_mov.rank;
                -- JS, 2007-09-10 - Timezone
                -- l_dt_req   := r_mov.dt_req;
                -- l_dt_begin := r_mov.dt_begin;
                l_dt_req   := r_mov.dt_req_tstz;
                l_dt_begin := r_mov.dt_begin_tstz;
                l_status   := r_mov.flg_status;
            END IF;
        END LOOP;
    
        IF g_found
        THEN
            IF l_status = g_mov_status_transp
            THEN
                l_out := g_icon || g_color_red || g_text || 'xxxxxxxxxxxxxx' ||
                         pk_sysdomain.get_img(i_lang, 'MOVEMENT.FLG_STATUS', g_mov_status_transp);
            
            ELSE
                -- JS, 2007-09-10 - Timezone
                -- l_elapsed_time := pk_date_utils.get_elapsed(i_lang => i_lang, i_date1 => g_sysdate, i_date2 => l_dt_req);
                -- IF l_dt_begin < g_sysdate
                l_elapsed_time := pk_date_utils.get_elapsed_tsz(i_lang  => i_lang,
                                                                i_date1 => g_sysdate_tstz,
                                                                i_date2 => l_dt_req);
                IF l_dt_begin < g_sysdate_tstz
                THEN
                    --    IF L_STATUS = G_MOV_STATUS_REQ THEN
                    -- JS, 2007-09-10 - Timezone
                    -- l_out := g_message || g_color_red || g_date || to_char(l_dt_req, 'YYYYMMDDHH24MISS') ||
                    l_out := g_message || g_color_red || g_date ||
                             pk_date_utils.to_char_insttimezone(i_prof, l_dt_req, 'YYYYMMDDHH24MISS') || l_elapsed_time;
                
                ELSE
                    --    ELSIF L_STATUS = G_MOV_STATUS_PEND THEN
                    -- JS, 2007-09-10 - Timezone
                    -- l_out := g_message || g_color_green || g_date || to_char(l_dt_req, 'YYYYMMDDHH24MISS') ||
                    l_out := g_message || g_color_green || g_date ||
                             pk_date_utils.to_char_insttimezone(i_prof, l_dt_req, 'YYYYMMDDHH24MISS') || l_elapsed_time;
                END IF;
            END IF;
        END IF;
    
        IF l_out IS NOT NULL
        THEN
            l_out := 'X' || l_out;
        ELSE
            l_out := NULL;
        END IF;
    
        RETURN l_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_cli_rec_total
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Obter dados das requisições de proc. clínico do episódio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_EPIS - Id do episódio
                  Saida:   Cadeia de caracteres em que:
                                1ª posição indica o atalho: X - s/ atalho
                                            D - prescrição de medicamentos
                                      V - prescrição de vacinas
                                      G - req de imagem
                                      F - req de prova funcional
                                      I - req de procedimentos
                                      N - req de pensos
                                      M - monitorização
                                      T - ensino de enfermagem
                                      H - colheitas
                                      A - requisição / resultados de análises
                        2ª posição indica se é uma M-mensagem ou um I-icon
                        3ª posição indica a cor (só tem relevância se se tratar de uma mensagem
                        4ª posição indica se é um texto ou uma duração em horas
                        a partir da 4ª posição é a mensagem ou o nome do icon a mostrar
                     O_ERROR - erro
          CRIAÇÃO: CRS 2005/06/03
          NOTAS:
        *********************************************************************************/
        CURSOR c_req IS
            SELECT s.rank,
                   -- JS, 2007-09-10 - Timezone
                   -- c.dt_cli_rec_req,
                   c.dt_cli_rec_req_tstz,
                   c.flg_status,
                   (SELECT cm.flg_status
                      FROM cli_rec_req_mov cm
                     WHERE cm.id_cli_rec_req_det = cd.id_cli_rec_req_det) mov_stat, --CM.FLG_STATUS MOV_STAT,
                   -- JS, 2007-09-10 - Timezone
                   -- nvl(c.dt_begin, c.dt_cli_rec_req) dt_begin
                   nvl(c.dt_begin_tstz, c.dt_cli_rec_req_tstz) dt_begin_tstz
              FROM cli_rec_req c, sys_domain s, cli_rec_req_det cd --, CLI_REC_REQ_MOV CM
             WHERE c.id_episode = i_epis
               AND c.flg_status NOT IN (g_cli_rec_cancel, g_cli_rec_finish)
               AND c.flg_status = s.val
               AND s.code_domain = 'CLI_REC_REQ.FLG_STATUS'
               AND s.id_language = i_lang
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND cd.id_cli_rec_req = c.id_cli_rec_req;
        --  AND CM.ID_CLI_REC_REQ_DET(+) = CD.ID_CLI_REC_REQ_DET;
    
        l_rank sys_domain.rank%TYPE;
        -- JS, 2007-09-10 - Timezone
        -- l_dt_req       cli_rec_req.dt_cli_rec_req%TYPE;
        -- l_dt_begin     cli_rec_req.dt_begin%TYPE;
        l_dt_req       cli_rec_req.dt_cli_rec_req_tstz%TYPE;
        l_dt_begin     cli_rec_req.dt_begin_tstz%TYPE;
        l_status       cli_rec_req.flg_status%TYPE;
        l_mov_stat     cli_rec_req_mov.flg_status%TYPE;
        l_out          VARCHAR2(100);
        l_elapsed_time VARCHAR2(100);
    BEGIN
        -- JS, 2007-09-10 - Timezone
        -- g_sysdate := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_found        := FALSE;
    
        g_error := 'LOOP';
        -- Vamos percorrer todos as requisições "em execução", "requisitado", ou "pendente" do epis.
        -- e escolher aquele cujo Rank do estado é mais prioritário
        FOR r_req IN c_req
        LOOP
            g_found := TRUE;
            IF nvl(l_rank, r_req.rank) >= r_req.rank
            THEN
                l_rank := r_req.rank;
                -- JS, 2007-09-10 - Timezone
                -- l_dt_req   := r_req.dt_cli_rec_req;
                -- l_dt_begin := r_req.dt_begin;
                l_dt_req   := r_req.dt_cli_rec_req_tstz;
                l_dt_begin := r_req.dt_begin_tstz;
                l_status   := r_req.flg_status;
                l_mov_stat := r_req.mov_stat;
            END IF;
        END LOOP;
    
        IF g_found
        THEN
            IF l_status = g_cli_rec_exec
            THEN
                l_out := g_icon || g_color_red || g_text || 'xxxxxxxxxxxxxx' ||
                         pk_sysdomain.get_img(i_lang, 'CLI_REC_REQ_MOV.FLG_STATUS', l_mov_stat);
            
            ELSE
                -- JS, 2007-09-10 - Timezone
                -- l_elapsed_time := pk_date_utils.get_elapsed(i_lang => i_lang, i_date1 => g_sysdate, i_date2 => l_dt_req);
                -- IF l_dt_begin < g_sysdate
                l_elapsed_time := pk_date_utils.get_elapsed_tsz(i_lang  => i_lang,
                                                                i_date1 => g_sysdate_tstz,
                                                                i_date2 => l_dt_req);
                IF l_dt_begin < g_sysdate_tstz
                THEN
                    --    IF L_STATUS = G_CLI_REC_REQ THEN
                    -- JS, 2007-09-10 - Timezone
                    -- l_out := g_message || g_color_red || g_date || to_char(l_dt_req, 'YYYYMMDDHH24MISS') ||
                    l_out := g_message || g_color_red || g_date ||
                             pk_date_utils.to_char_insttimezone(i_prof, l_dt_req, 'YYYYMMDDHH24MISS') || l_elapsed_time;
                
                ELSE
                    --    ELSIF L_STATUS = G_CLI_REC_PEND THEN
                    -- JS, 2007-09-10 - Timezone
                    -- l_out := g_message || g_color_green || g_date || to_char(l_dt_req, 'YYYYMMDDHH24MISS') ||
                    l_out := g_message || g_color_green || g_date ||
                             pk_date_utils.to_char_insttimezone(i_prof, l_dt_req, 'YYYYMMDDHH24MISS') || l_elapsed_time;
                END IF;
            END IF;
        END IF;
    
        IF l_out IS NOT NULL
        THEN
            l_out := 'X' || l_out;
        ELSE
            l_out := NULL;
        END IF;
    
        RETURN l_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_cli_rec_trans
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Obter dados das requisições de proc. clínico do episódio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_EPIS - Id do episódio
                  Saida:   Cadeia de caracteres em que:
                                1ª posição indica o atalho: X - s/ atalho
                                            D - prescrição de medicamentos
                                      V - prescrição de vacinas
                                      G - req de imagem
                                      F - req de prova funcional
                                      I - req de procedimentos
                                      N - req de pensos
                                      M - monitorização
                                      T - ensino de enfermagem
                                      H - colheitas
                                      A - requisição / resultados de análises
                        2ª posição indica se é uma M-mensagem ou um I-icon
                        3ª posição indica a cor (só tem relevância se se tratar de uma mensagem
                        4ª posição indica se é um texto ou uma duração em horas
                        a partir da 4ª posição é a mensagem ou o nome do icon a mostrar
                     O_ERROR - erro
          CRIAÇÃO: CRS 2005/06/03
          NOTAS:
        *********************************************************************************/
        CURSOR c_req IS
        -- JS, 2007-09-08 - Timezone
        -- SELECT s.rank, cm.dt_req_transp, cm.flg_status mov_stat
            SELECT s.rank, cm.dt_req_transp_tstz, cm.flg_status mov_stat
              FROM cli_rec_req c, sys_domain s, cli_rec_req_det cd, cli_rec_req_mov cm
             WHERE c.id_episode = i_epis
               AND c.flg_status NOT IN (g_cli_rec_cancel, g_cli_rec_finish)
               AND cd.id_cli_rec_req = c.id_cli_rec_req
               AND cm.id_cli_rec_req_det = cd.id_cli_rec_req_det
               AND cm.flg_status IN (g_cli_rec_mov_o, g_cli_rec_mov_t)
               AND cm.flg_status = s.val
               AND s.id_language = i_lang
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.code_domain = 'CLI_REC_REQ_MOV.FLG_STATUS';
    
        l_rank sys_domain.rank%TYPE;
        -- JS, 2007-09-08 - Timezone
        -- l_dt_req       cli_rec_req.dt_cli_rec_req%TYPE;
        l_dt_req       cli_rec_req.dt_cli_rec_req_tstz%TYPE;
        l_mov_stat     cli_rec_req_mov.flg_status%TYPE;
        l_out          VARCHAR2(100);
        l_elapsed_time VARCHAR2(100);
    BEGIN
    
        -- JS, 2007-09-08 - Timezone
        -- g_sysdate := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_found        := FALSE;
    
        g_error := 'LOOP';
        -- Vamos percorrer todos as requisições "em execução", "requisitado", ou "pendente" do epis.
        -- e escolher aquele cujo Rank do estado é mais prioritário
        FOR r_req IN c_req
        LOOP
            g_found := TRUE;
            IF nvl(l_rank, r_req.rank) >= r_req.rank
            THEN
                l_rank := r_req.rank;
                -- JS, 2007-09-08 - Timezone
                -- l_dt_req   := r_req.dt_req_transp;
                l_dt_req   := r_req.dt_req_transp_tstz;
                l_mov_stat := r_req.mov_stat;
            END IF;
        END LOOP;
    
        IF g_found
        THEN
            IF l_mov_stat = g_cli_rec_mov_o
            THEN
                -- JS, 2007-09-08 - Timezone
                -- l_elapsed_time := pk_date_utils.get_elapsed(i_lang => i_lang, i_date1 => g_sysdate, i_date2 => l_dt_req);
                -- l_out          := g_message || g_color_red || g_date || to_char(l_dt_req, 'YYYYMMDDHH24MISS') ||
                l_elapsed_time := pk_date_utils.get_elapsed(i_lang  => i_lang,
                                                            i_date1 => g_sysdate_tstz,
                                                            i_date2 => l_dt_req);
                l_out          := g_message || g_color_red || g_date ||
                                  pk_date_utils.to_char_insttimezone(i_prof, l_dt_req, 'YYYYMMDDHH24MISS') ||
                                 
                                  l_elapsed_time;
            
            ELSIF l_mov_stat = g_cli_rec_mov_t
            THEN
                l_out := g_icon || g_color_red || g_text || 'xxxxxxxxxxxxxx' ||
                         pk_sysdomain.get_img(i_lang, 'CLI_REC_REQ_MOV.FLG_STATUS', l_mov_stat);
            END IF;
        END IF;
    
        RETURN l_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_first_prec_icon
    (
        i_mess1    IN VARCHAR2,
        i_mess2    IN VARCHAR2,
        i_domain   IN VARCHAR2,
        i_cat_type IN category.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Dadas duas mensagens, através de ordens de precedências pré-definidas,
                  obtem a mensagem mais importante a mostrar nas grids.
           PARAMETROS:  Entrada: I_MESS1 - Mensagem 1
                       I_MESS2 - mensagem 2
                         Saida:
          CRIAÇÃO: RB 2005/05/04
          CORRECÇÕES: CRS 2005/06/22
          NOTAS: A função retorna I_MESS1 ou I_MESS1 conforme o que for mais importante
        
              JÁ NÃO ESTÁ A SER USADA!!!!
        
        *********************************************************************************/
        l_mess_out VARCHAR2(200);
        l_img      VARCHAR2(200);
    
        CURSOR c_icon IS
            SELECT DISTINCT img_name
              FROM sys_domain
             WHERE img_name IN (substr(i_mess2, 18), substr(i_mess1, 18))
               AND code_domain = i_domain
               AND domain_owner = pk_sysdomain.k_default_schema
                  --    AND ID_LANGUAGE = I_LANG
               AND rank = (SELECT MAX(rank)
                             FROM sys_domain
                            WHERE img_name IN (substr(i_mess2, 18), substr(i_mess1, 18))
                              AND domain_owner = pk_sysdomain.k_default_schema
                              AND code_domain = i_domain);
    BEGIN
        l_mess_out := NULL;
        IF i_mess1 IS NULL
           AND i_mess2 IS NOT NULL
        THEN
            l_mess_out := i_mess2;
        ELSIF (i_mess1 IS NOT NULL AND i_mess2 IS NULL)
              OR (i_mess1 IS NULL AND i_mess2 IS NULL)
        THEN
            l_mess_out := i_mess1;
        ELSE
            IF substr(i_mess1, 1, 1) = g_icon
            THEN
                -- 1º string é ícone
                IF substr(i_mess2, 1, 1) = g_icon
                THEN
                    -- 2º string é ícone
                    OPEN c_icon;
                    FETCH c_icon
                        INTO l_img;
                    CLOSE c_icon;
                    IF l_img = substr(i_mess2, 4)
                    THEN
                        l_mess_out := i_mess2;
                    ELSE
                        l_mess_out := i_mess1;
                    END IF;
                ELSIF substr(i_mess2, 3, 1) = g_text
                      AND substr(i_mess2, 2, 1) = g_color_green
                THEN
                    -- 2º string é texto (agendado para o futuro)
                    --l_mess_out := i_mess1;
                    IF i_cat_type = 'D'
                    THEN
                        l_mess_out := i_mess1;
                    ELSE
                        l_mess_out := i_mess2;
                    END IF;
                ELSIF substr(i_mess2, 3, 1) = g_date
                      AND substr(i_mess2, 2, 1) = g_color_green
                THEN
                    -- 2º string é data pendente
                    l_mess_out := i_mess1;
                ELSE
                    -- 2º string é data em atraso ou texto (agendado)
                    l_mess_out := i_mess2;
                END IF;
            
            ELSIF substr(i_mess1, 3, 1) = g_date
            THEN
                -- 1º string data
                IF substr(i_mess1, 2, 1) = g_color_red
                THEN
                    -- em atraso
                    IF substr(i_mess2, 3, 1) = g_date
                    THEN
                        -- o 2º string tb é data
                        IF substr(i_mess2, 2, 1) = g_color_red
                        THEN
                            -- o 2º string tb está em atraso
                            l_mess_out := least(i_mess1, i_mess2); -- o + atrasado
                        ELSE
                            -- o 2º string (data) está pendente
                            l_mess_out := i_mess1;
                        END IF;
                    ELSE
                        -- o 2º string é texto (agendado) ou ícone
                        l_mess_out := i_mess1;
                    END IF;
                
                ELSE
                    -- 1º string (data) está pendente
                    IF substr(i_mess2, 3, 1) = g_date
                       AND substr(i_mess2, 2, 1) = g_color_green
                    THEN
                        -- 2º string tb é data e tb está pendente
                        l_mess_out := least(i_mess1, i_mess2); -- o q falta menos tempo
                    ELSIF substr(i_mess2, 3, 1) = g_text
                          AND substr(i_mess2, 2, 1) = g_color_green
                    THEN
                        -- 2º string é texto (agendado para o futuro)
                        l_mess_out := i_mess1;
                    ELSE
                        -- 2º string é data em atraso ou ícone
                        l_mess_out := i_mess2;
                    END IF;
                END IF;
            
            ELSIF substr(i_mess1, 3, 1) = g_text
            THEN
                -- 1º string texto (agendado)
                IF substr(i_mess1, 2, 1) = g_color_red
                THEN
                    -- agendado no passado para agora
                    IF substr(i_mess2, 1, 1) = g_icon
                    THEN
                        l_mess_out := i_mess1;
                    ELSIF substr(i_mess2, 3, 1) = g_text
                          AND substr(i_mess2, 2, 1) = g_color_red
                    THEN
                        -- 2º string tb é texto agendado no passado para agora
                        l_mess_out := i_mess2;
                    ELSIF substr(i_mess2, 3, 1) = g_date
                          AND substr(i_mess2, 2, 1) = g_color_red
                    THEN
                        l_mess_out := i_mess2;
                    ELSE
                        l_mess_out := i_mess1;
                    END IF;
                ELSE
                    -- l_mess_out := i_mess2;
                    IF i_cat_type = 'D'
                    THEN
                        l_mess_out := i_mess2;
                    ELSE
                        l_mess_out := i_mess1;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN l_mess_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_presc_req_icon_time
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_epis_status IN episode.flg_status%TYPE,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP,
        i_dt_req      IN TIMESTAMP,
        i_icon_name   IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Obter a string constituída por:
                  1ª posição indica se é uma M-mensagem ou um I-icon
                2ª posição indica a cor (só tem relevância se se tratar de uma mensagem)
                3ª posição indica se é um texto ou uma duração em horas
                a partir da 4ª posição é a mensagem ou o nome do icon a mostrar
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_ID_PAT - Id do doente
                     I_EPIS_STATUS - estado do episódio
                     I_FLG_TIME - Realização: E - neste episódio; N - próximo episódio; B - entre episódios
                     I_FLG_STATUS - estado da requisição
                     I_DT_BEGIN - Data pretendida para início da execução do exame (ie, ñ imediata)
                     I_DT_REQ - data / hora de requisição
                     I_ICON_NAME - nome da imagem do estado da requisição
                  Saida:   O_ERROR - erro
        
          CRIAÇÃO:  RB 2005/04/30
          NOTAS: Esta função é para ser utilizada para tabelas que contemplem a
                possibilidade de marcar requisições/prescrições para episódios futuros.
             COMO AS REQ. DO EPIS ANTERIOR PASSAM PARA O ACTUAL, AS VERIFICAÇÕES DESTA
             FUNÇÃO SÃO RESPEITANTES SOMENTE AO EPIS. ACTUAL
        *********************************************************************************/
        v_elapsed_time VARCHAR2(20);
        v_out          VARCHAR2(200);
        l_agendado     VARCHAR2(20);
    BEGIN
        -- JS, 2007-09-08 - Timezone
        -- g_sysdate := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error    := 'GET MESSAGE';
        l_agendado := pk_message.get_message(i_lang, 'ICON_T056'); --'agendado'
    
        g_error := 'GET OUT STRING';
        IF i_epis_status = g_epis_inactive
        THEN
            -- O episódio está fechado
            IF i_flg_time != g_flg_time_e
            THEN
                -- Requisição / prescrição foi pedida para o próximo episódio ou até ao próximo episódio
                v_out := g_message || g_color_green || g_text || 'xxxxxxxxxxxxxx' || l_agendado;
            END IF;
        
        ELSE
            -- O episódio está activo.
            IF i_flg_time = g_flg_time_e
            THEN
                -- Requisição / prescrição foi pedida para o próprio episódio
            
                IF i_flg_status IN (g_flg_status_f, g_flg_status_p, g_flg_status_e)
                THEN
                    -- Tem resultados ou em execução
                    v_out := g_icon || g_color_red || g_text || 'xxxxxxxxxxxxxx' || i_icon_name;
                
                ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_a)
                THEN
                    -- requisitado
                    -- JS, 2007-09-08 - Timezone
                    -- IF NOT pk_date_utils.get_elapsed(i_lang, g_sysdate, i_dt_req, v_elapsed_time, o_error)
                    IF NOT pk_date_utils.get_elapsed_tsz(i_lang, g_sysdate_tstz, i_dt_req, v_elapsed_time, o_error)
                    THEN
                        RETURN NULL;
                    END IF;
                    -- JS, 2007-09-08 - Timezone
                    -- v_out := g_message || g_color_red || g_date || to_char(i_dt_req, 'YYYYMMDDHH24MISS') ||
                    v_out := g_message || g_color_red || g_date || i_dt_req || v_elapsed_time;
                
                ELSIF i_flg_status = g_flg_status_d
                THEN
                    -- pendente
                    IF i_dt_begin IS NULL
                    THEN
                        -- req é proveniente de outro epis. (foi pedida num epis. anterior, p/ ser executado no seguinte)
                        v_out := g_message || g_color_red || g_text || 'xxxxxxxxxxxxxx' || l_agendado;
                    
                        -- JS, 2007-09-08 - Timezone
                        -- ELSIF i_dt_begin >= g_sysdate
                    ELSIF i_dt_begin >= g_sysdate_tstz
                    THEN
                        -- pedida para + tarde
                        -- JS, 2007-09-08 - Timezone
                        -- IF NOT pk_date_utils.get_elapsed(i_lang, g_sysdate, i_dt_begin, v_elapsed_time, o_error)
                        IF NOT
                            pk_date_utils.get_elapsed_tsz(i_lang, g_sysdate_tstz, i_dt_begin, v_elapsed_time, o_error)
                        THEN
                            RETURN NULL;
                        END IF;
                        -- JS, 2007-09-08 - Timezone
                        -- v_out := g_message || g_color_green || g_date || to_char(i_dt_begin, 'YYYYMMDDHH24MISS') ||
                        v_out := g_message || g_color_green || g_date || i_dt_begin || v_elapsed_time;
                    
                        -- JS, 2007-09-08 - Timezone
                        -- ELSIF i_dt_begin < g_sysdate
                    ELSIF i_dt_begin < g_sysdate_tstz
                    THEN
                        -- já passou a hora p/ a qual foi pedida
                        -- JS, 2007-09-08 - Timezone
                        -- IF NOT pk_date_utils.get_elapsed(i_lang, g_sysdate, i_dt_begin, v_elapsed_time, o_error)
                        IF NOT
                            pk_date_utils.get_elapsed_tsz(i_lang, g_sysdate_tstz, i_dt_begin, v_elapsed_time, o_error)
                        THEN
                            RETURN NULL;
                        END IF;
                        -- JS, 2007-09-08 - Timezone
                        -- v_out := g_message || g_color_red || g_date || to_char(i_dt_begin, 'YYYYMMDDHH24MISS') ||
                        v_out := g_message || g_color_red || g_date || i_dt_begin || v_elapsed_time;
                    END IF;
                
                ELSIF i_flg_status = g_read
                THEN
                    -- lido
                    v_out := NULL;
                END IF; -- I_FLG_STATUS
            
            ELSIF i_flg_time = g_flg_time_n
            THEN
                -- Requisição / prescrição foi pedida para o próximo episódio
                IF i_flg_status = g_flg_status_d
                THEN
                    -- pendente
                    v_out := g_message || g_color_green || g_text || 'xxxxxxxxxxxxxx' || l_agendado;
                END IF;
            
            ELSIF i_flg_time IN (g_flg_time_b, g_flg_time_d)
            THEN
                -- Requisição / prescrição foi pedida até ao próximo episódio
                IF i_flg_status = g_flg_status_d
                THEN
                    -- pendente
                    -- JS, 2007-09-08 - Timezone
                    -- IF i_dt_begin < g_sysdate
                    IF i_dt_begin < g_sysdate_tstz
                    THEN
                        -- já passou a hora p/ a qual foi pedida
                        v_out := g_message || g_color_red || g_text || 'xxxxxxxxxxxxxx' || l_agendado;
                    ELSE
                        v_out := g_message || g_color_green || g_text || 'xxxxxxxxxxxxxx' || l_agendado;
                    END IF;
                ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_a)
                THEN
                    -- requisição
                    -- JS, 2007-09-08 - Timezone
                    -- IF NOT pk_date_utils.get_elapsed(i_lang, g_sysdate, i_dt_req, v_elapsed_time, o_error)
                    IF NOT pk_date_utils.get_elapsed_tsz(i_lang, g_sysdate_tstz, i_dt_req, v_elapsed_time, o_error)
                    THEN
                        RETURN NULL;
                    END IF;
                    -- JS, 2007-09-08 - Timezone
                    -- v_out := g_message || g_color_red || g_date || to_char(i_dt_req, 'YYYYMMDDHH24MISS') ||
                    v_out := g_message || g_color_red || g_date || i_dt_req || v_elapsed_time;
                END IF;
            END IF; -- I_FLG_TIME
        END IF; -- I_EPIS_STATUS
    
        RETURN v_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'GET_PRESC_REQ_ICON_TIME');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN NULL;
            
            END;
        
    END;

    FUNCTION get_aux
    (
        i_lang        IN language.id_language%TYPE,
        i_id_pat      IN patient.id_patient%TYPE,
        i_epis_status IN episode.flg_status%TYPE,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP,
        i_dt_req      IN TIMESTAMP,
        i_icon_name   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Obter a string constituída por:
                  1ª posição indica se é uma M-mensagem ou um I-icon
                2ª posição indica a cor (só tem relevância se se tratar de uma mensagem)
                3ª posição indica se é um texto ou uma duração em horas
                a partir da 4ª posição é a mensagem ou o nome do icon a mostrar
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_ID_PAT - Id do doente
                     I_EPIS_STATUS - estado do episódio
                     I_FLG_TIME - Realização: E - neste episódio; N - próximo episódio; B - entre episódios
                     I_FLG_STATUS - estado da requisição
                     I_DT_BEGIN - Data pretendida para início da execução do exame (ie, ñ imediata)
                     I_DT_REQ - data / hora de requisição
                     I_ICON_NAME - nome da imagem do estado da requisição
                  Saida:
        
          CRIAÇÃO:  RB 2005/04/30
          NOTAS:  Esta função é para ser utilizada para tabelas que contemplem a
                possibilidade de marcar requisições/prescrições para episódios futuros.
        
              ESTA FUNÇÃO É CÓPIA DA GET_PRESC_REQ_ICON_TIME ORIGINAL, EM Q SE PENSAVA
              QUE NAS GRELHAS TB SE VISUALIZAVAM AGENDAMENTOS SEM EPISÓDIO.
              NÃO É ASSIM, PQ AS GRELHAS ONDE SE VISUALIZAM REQ. SÃO AS DO MÉDICO E
              ENF., Q SÓ VÊEM CONSULTAS EFECTIVADAS
        *********************************************************************************/
        v_elapsed_time VARCHAR2(20);
        v_out          VARCHAR2(200);
        l_agendado     VARCHAR2(20);
        l_error        t_error_out;
    BEGIN
        -- JS, 2007-09-08 - Timezone
        -- g_sysdate := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error    := 'GET MESSAGE';
        l_agendado := pk_message.get_message(i_lang, 'ICON_T056'); --'agendado'
    
        g_error := 'GET OUT STRING';
        IF i_epis_status = g_epis_inactive
        THEN
            -- O último episódio está inactivo.
            IF i_flg_time = g_flg_time_e
            THEN
                -- Requisição / prescrição foi pedida para o próprio episódio
                IF i_flg_status IN (g_flg_status_f, g_flg_status_p, g_flg_status_e)
                THEN
                    -- Tem resultados ou em execução
                    v_out := g_icon || g_color_red || g_text || i_icon_name;
                END IF;
            
            ELSIF i_flg_time = g_flg_time_n
            THEN
                -- Requisição / prescrição foi pedida para o próximo episódio
                IF i_flg_status = g_flg_status_d
                THEN
                    -- pendente
                    v_out := g_message || g_color_red || g_text || l_agendado;
                END IF;
            
            ELSIF i_flg_time IN (g_flg_time_b, g_flg_time_d)
            THEN
                -- Requisição / prescrição foi pedida até ao próximo episódio
                IF i_flg_status IN (g_flg_status_f, g_flg_status_p, g_flg_status_e)
                THEN
                    v_out := g_icon || g_color_red || g_text || i_icon_name;
                ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_d)
                THEN
                    v_out := g_message || g_color_red || g_text || l_agendado;
                END IF;
            END IF;
        
        ELSE
            -- O último episódio está activo.
            IF i_flg_time = g_flg_time_e
            THEN
                -- Requisição / prescrição foi pedida para o próprio episódio
            
                IF i_flg_status IN (g_flg_status_f, g_flg_status_p, g_flg_status_e)
                THEN
                    -- Tem resultados ou em execução
                    v_out := g_icon || g_color_red || g_text || i_icon_name;
                
                ELSIF i_flg_status = g_flg_status_r
                THEN
                    -- requisitado
                    -- JS, 2007-09-08 - Timezone
                    -- IF NOT pk_date_utils.get_elapsed(i_lang, g_sysdate, i_dt_req, v_elapsed_time, l_error)
                    IF NOT pk_date_utils.get_elapsed(i_lang, g_sysdate_tstz, i_dt_req, v_elapsed_time, l_error)
                    THEN
                        RETURN NULL;
                    END IF;
                    v_out := g_message || g_color_red || g_date || v_elapsed_time;
                
                ELSIF i_flg_status = g_flg_status_d
                THEN
                    -- pendente
                    --    if I_DT_REQ = I_DT_BEGIN then
                    IF i_dt_begin IS NULL
                    THEN
                        -- req é proveniente de outro epis. (foi pedida num epis. anterior, p/ ser executado no seguinte)
                        v_out := g_message || g_color_red || g_text || l_agendado;
                    
                        -- JS, 2007-09-10 - Timezone
                        -- ELSIF i_dt_begin >= g_sysdate
                    ELSIF i_dt_begin >= g_sysdate_tstz
                    THEN
                        -- pedida para + tarde
                        -- JS, 2007-09-08 - Timezone
                        -- IF NOT pk_date_utils.get_elapsed(i_lang, g_sysdate, i_dt_begin, v_elapsed_time, l_error)
                        IF NOT
                            pk_date_utils.get_elapsed_tsz(i_lang, g_sysdate_tstz, i_dt_begin, v_elapsed_time, l_error)
                        THEN
                            RETURN NULL;
                        END IF;
                        v_out := g_message || g_color_green || g_date || v_elapsed_time;
                    
                        -- JS, 2007-09-08 - Timezone
                        -- ELSIF i_dt_begin < g_sysdate
                    ELSIF i_dt_begin < g_sysdate_tstz
                    THEN
                        -- já passou a hora p/ a qual foi pedida
                        -- JS, 2007-09-08 - Timezone
                        -- IF NOT pk_date_utils.get_elapsed(i_lang, g_sysdate, i_dt_begin, v_elapsed_time, l_error)
                        IF NOT
                            pk_date_utils.get_elapsed_tsz(i_lang, g_sysdate_tstz, i_dt_begin, v_elapsed_time, l_error)
                        THEN
                            RETURN NULL;
                        END IF;
                        v_out := g_message || g_color_red || g_date || v_elapsed_time;
                    END IF;
                END IF; -- I_FLG_STATUS
            
            ELSIF i_flg_time = g_flg_time_n
            THEN
                -- Requisição / prescrição foi pedida para o próximo episódio
                IF i_flg_status = g_flg_status_d
                THEN
                    -- pendente
                    v_out := g_message || g_color_green || g_text || l_agendado;
                END IF;
            
            ELSIF i_flg_time IN (g_flg_time_b, g_flg_time_d)
            THEN
                -- Requisição / prescrição foi pedida até ao próximo episódio
                IF i_flg_status = g_flg_status_d
                THEN
                    -- pendente
                    v_out := g_message || g_color_green || g_text || l_agendado;
                END IF;
            END IF; -- I_FLG_TIME
        END IF; -- I_EPIS_STATUS
    
        RETURN v_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_nurse_teach
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Obter dados das requisições de medicamentos à farmácia, no episódio
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                       I_EPIS - Id do episódio
                  Saida:   Cadeia de caracteres em que:
                                1ª posição indica o atalho: X - s/ atalho
                                            D - prescrição de medicamentos
                                      V - prescrição de vacinas
                                      G - req de imagem
                                      F - req de prova funcional
                                      I - req de procedimentos
                                      N - req de pensos
                                      M - monitorização
                                      T - ensino de enfermagem
                                      H - colheitas
                                      A - requisição / resultados de análises
                        2ª posição indica se é uma M-mensagem ou um I-icon
                        3ª posição indica a cor (só tem relevância se se tratar de uma mensagem
                        4ª posição indica se é um texto ou uma duração em horas
                        a partir da 4ª posição é a mensagem ou o nome do icon a mostrar
                     O_ERROR - erro
          CRIAÇÃO: CRS 2005/09/16
          NOTAS:
        *********************************************************************************/
        CURSOR c_req IS
        -- JS, 2007-09-11 - Timezone
        -- SELECT s.rank, n.dt_nurse_tea_req, n.flg_status, nvl(n.dt_begin, n.dt_nurse_tea_req) dt_begin
            SELECT s.rank,
                   n.dt_nurse_tea_req_tstz,
                   n.flg_status,
                   nvl(n.dt_begin_tstz, n.dt_nurse_tea_req_tstz) dt_begin_tstz
              FROM nurse_tea_req n, sys_domain s
             WHERE n.id_episode = i_epis
               AND n.flg_status IN (g_nurse_tea_pend, g_nurse_tea_act)
               AND n.flg_status = s.val
               AND s.code_domain = 'NURSE_TEA_REQ.FLG_STATUS'
               AND s.domain_owner = pk_sysdomain.k_default_schema
               AND s.id_language = i_lang
            -- JS, 2007-09-10 - Timezone
            -- ORDER BY n.dt_nurse_tea_req;
             ORDER BY n.dt_nurse_tea_req_tstz;
    
        l_rank sys_domain.rank%TYPE;
        -- JS, 2007-09-11 - Timezone
        l_dt_req       nurse_tea_req.dt_nurse_tea_req_tstz%TYPE;
        l_dt_begin     nurse_tea_req.dt_begin_tstz%TYPE;
        l_status       nurse_tea_req.flg_status%TYPE;
        l_out          VARCHAR2(100);
        l_elapsed_time VARCHAR2(100);
    BEGIN
        -- JS, 2007-09-08 - Timezone
        -- g_sysdate := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_found        := FALSE;
    
        g_error := 'LOOP';
        -- Vamos percorrer todos as requisições "pendentes", "activas",
        -- e escolher aquele cujo Rank do estado é mais prioritário
        FOR r_req IN c_req
        LOOP
            g_found := TRUE;
            IF nvl(l_rank, r_req.rank) >= r_req.rank
            THEN
                l_rank := r_req.rank;
                -- JS, 2007-09-11 - Timezone
                -- l_dt_req   := r_req.dt_nurse_tea_req;
                -- l_dt_begin := r_req.dt_begin;
                l_dt_req   := r_req.dt_nurse_tea_req_tstz;
                l_dt_begin := r_req.dt_begin_tstz;
                l_status   := r_req.flg_status;
            END IF;
        END LOOP;
    
        IF g_found
        THEN
            -- JS, 2007-09-11 - Timezone
            -- l_elapsed_time := pk_date_utils.get_elapsed(i_lang => i_lang, i_date1 => g_sysdate, i_date2 => l_dt_begin);
            -- IF l_dt_begin < g_sysdate
            l_elapsed_time := pk_date_utils.get_elapsed_tsz(i_lang  => i_lang,
                                                            i_date1 => g_sysdate_tstz,
                                                            i_date2 => l_dt_begin);
            IF l_dt_begin < g_sysdate_tstz
            THEN
                -- JS, 2007-09-11 - Timezone
                -- l_out := g_message || g_color_red || g_date || to_char(l_dt_begin, 'YYYYMMDDHH24MISS') ||
                l_out := g_message || g_color_red || g_date ||
                         pk_date_utils.to_char_insttimezone(i_prof, l_dt_begin, 'YYYYMMDDHH24MISS') || l_elapsed_time;
            
            ELSE
                -- JS, 2007-09-11 - Timezone
                -- l_out := g_message || g_color_green || g_date || to_char(l_dt_begin, 'YYYYMMDDHH24MISS') ||
                l_out := g_message || g_color_green || g_date ||
                         pk_date_utils.to_char_insttimezone(i_prof, l_dt_begin, 'YYYYMMDDHH24MISS') || l_elapsed_time;
            END IF;
        END IF;
    
        IF l_out IS NOT NULL
        THEN
            l_out := 'T' || l_out;
        END IF;
    
        RETURN l_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_string_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE DEFAULT NULL,
        i_epis_status IN episode.flg_status%TYPE,
        i_flg_time    IN VARCHAR2,
        i_flg_status  IN VARCHAR2,
        i_dt_begin    IN TIMESTAMP,
        i_dt_req      IN TIMESTAMP,
        i_icon_name   IN VARCHAR2,
        i_rank        IN sys_domain.rank%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Obter a string constituída por:
                  1ª posição indica qual o ID do atalho
                2ª posição:
                                           D - é para fazer cálculos e apresentar tempo.
                                           T - é para apresentar a mensagem AGENDADO e fazer cálculos caso a data esteja preenchida.
                                           I - é para apresentar o ícone dos resultados.
                3ª posição:
                                           se a 2ª posição é D - data
                                           se a 2ª posição é T - AGENDADO
                                           se a 2ª posição é I - nome do ícone
        
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                 I_ID_PAT - Id do doente
                 I_EPIS_STATUS - estado do episódio
                 I_FLG_TIME - Realização: E - neste episódio; N - próximo episódio; B - entre episódios
                 I_FLG_STATUS - estado da requisição
                 I_DT_BEGIN - Data pretendida para início da execução do exame (ie, ñ imediata)
                 I_DT_REQ - data / hora de requisição
                 I_ICON_NAME - nome da imagem do estado da requisição
                  Saida: O_ERROR - erro
        
          CRIAÇÃO:  SS 2006/01/19
          NOTAS:
        *********************************************************************************/
        v_out      VARCHAR2(200);
        l_agendado VARCHAR2(20);
        l_dt_begin VARCHAR2(200);
    BEGIN
        -- JS, 2007-09-08 - Timezone
        -- g_sysdate := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error    := 'GET MESSAGE';
        l_agendado := pk_message.get_message(i_lang, 'ICON_T056'); --'AGENDADO'
    
        l_dt_begin := pk_date_utils.to_char_insttimezone(i_prof, i_dt_begin, 'YYYYMMDDHH24MISS TZR');
    
        g_error := 'GET V_OUT STRING';
        IF i_flg_time = g_flg_time_e
        THEN
            -- Requisição / prescrição foi pedida para o próprio episódio
            IF i_flg_status IN (g_flg_status_f, g_flg_status_p, g_flg_status_e)
            THEN
                -- Tem resultados ou em execução
                v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
            
            ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_cc, g_flg_status_a, g_flg_status_x)
            THEN
                -- requisitado
                IF i_dt_begin IS NULL
                THEN
                    -- req é proveniente de outro epis. (foi pedida num epis. anterior, p/ ser executado no seguinte)
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_red || '|' || l_agendado;
                ELSE
                    v_out := l_dt_begin || '|' || g_date || '|' || g_no_color;
                END IF;
            
            ELSIF i_flg_status = g_flg_status_d
            THEN
                -- pendente
                IF i_dt_begin IS NULL
                THEN
                    -- req é proveniente de outro epis. (foi pedida num epis. anterior, p/ ser executado no seguinte)
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_red || '|' || l_agendado;
                ELSE
                    v_out := l_dt_begin || '|' || g_date || '|' || g_no_color;
                END IF;
            
            ELSIF i_flg_status = g_read
            THEN
                -- lido
                v_out := NULL;
            END IF; -- I_FLG_STATUS
        
        ELSIF i_flg_time = g_flg_time_n
        THEN
            -- Requisição / prescrição foi pedida para o próximo episódio
            IF i_episode IS NULL
            THEN
                IF i_epis_status = g_epis_inactive
                THEN
                    IF i_dt_begin IS NULL
                    THEN
                        -- requisitado num epis. anterior, p/ ser executado no seguinte
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_green || '|' || l_agendado; --  CRS 2007-06-20 Alterada cor vermelha para verde
                    ELSE
                        v_out := l_dt_begin || '|' || g_date || '|' || g_no_color;
                    END IF;
                ELSE
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_green || '|' || l_agendado;
                END IF;
            ELSE
                IF i_flg_status IN (g_flg_status_f, g_flg_status_p, g_flg_status_e)
                THEN
                    -- Tem resultados ou em execução
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
                
                ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_cc, g_flg_status_a, g_flg_status_x)
                THEN
                    -- requisitado
                    IF i_dt_begin IS NULL
                    THEN
                        -- req é proveniente de outro epis. (foi pedida num epis. anterior, p/ ser executado no seguinte)
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_red || '|' || l_agendado;
                    ELSE
                        v_out := l_dt_begin || '|' || g_date || '|' || g_no_color;
                    END IF;
                
                ELSIF i_flg_status = g_flg_status_d
                THEN
                    -- pendente
                    IF i_dt_begin IS NULL
                    THEN
                        -- req é proveniente de outro epis. (foi pedida num epis. anterior, p/ ser executado no seguinte)
                        v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_red || '|' || l_agendado;
                    ELSE
                        v_out := l_dt_begin || '|' || g_date || '|' || g_no_color;
                    END IF;
                ELSIF i_flg_status IS NULL
                THEN
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_green || '|' || l_agendado;
                ELSIF i_flg_status = g_read
                THEN
                    -- lido
                    v_out := NULL;
                END IF; -- I_FLG_STATUS
            END IF;
        
        ELSIF i_flg_time IN (g_flg_time_b, g_flg_time_d)
        THEN
        
            -- Requisição / prescrição foi pedida até ao próximo episódio
            IF i_flg_status = g_flg_status_d
            THEN
                -- pendente
                IF i_dt_begin IS NULL
                THEN
                    -- exames e análises (se FLG_TIME=B então DT_BEGIN=NULL=não aplicável)
                    v_out := 'xxxxxxxxxxxxxx' || '|' || g_text || '|' || g_color_green || '|' || l_agendado;
                ELSE
                    v_out := l_dt_begin || '|' || g_date || '|' || g_no_color;
                END IF;
            
            ELSIF i_flg_status IN (g_flg_status_r, g_flg_status_a, g_flg_status_x)
            THEN
                -- requisição
                v_out := l_dt_begin || '|' || g_date || '|' || g_no_color;
            
            ELSIF i_flg_status = g_flg_status_pa
            THEN
                -- por agendar
                v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
            
            ELSIF i_flg_status = g_flg_status_g
            THEN
                -- agendado
                v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_color_green || '|' || i_icon_name;
            
            ELSIF i_flg_status IN (g_flg_status_f)
            THEN
                -- com resultado
                v_out := 'xxxxxxxxxxxxxx' || '|' || g_icon || '|' || g_no_color || '|' || i_icon_name;
            END IF;
        END IF; -- I_FLG_TIME
    
        IF i_rank IS NOT NULL
        THEN
            v_out := v_out || '|' || i_rank;
        ELSE
            v_out := v_out || '|';
        END IF;
    
        RETURN v_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'GET_STRING_TASK');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN NULL;
            
            END;
    END;

    FUNCTION get_prioritary_task
    (
        i_lang     IN language.id_language%TYPE,
        i_mess1    IN VARCHAR2,
        i_mess2    IN VARCHAR2,
        i_domain   IN VARCHAR2,
        i_cat_type IN category.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Dadas duas mensagens, através de ordens de precedências pré-definidas,
                  obtem a mensagem mais importante a mostrar nas grids.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                 I_MESS1 - Mensagem 1
                 I_MESS2 - Mensagem 2
        
          CRIAÇÃO: SS 2006/01/19
          NOTAS: formato status string nova de I_MESS1 e I_MESS2:
                 displayType|date|text|iconName|backgroundColor|messageStyle|messageColor|iconColor|dateServer|rank
                 displayType:
                         T - Text
                         I - Icon
                         D - Date
                         DI - Date e Icon (presente no novo formato, o comportamento é semelhante ao D)
        *********************************************************************************/
        l_mess_out      pk_types.t_med_char;
        l_img           pk_types.t_med_char;
        l_status        VARCHAR2(2);
        l_pos_type      NUMBER := 1;
        l_pos_date      NUMBER := 2;
        l_pos_text      NUMBER := 3;
        l_pos_iconname  NUMBER := 4;
        l_pos_iconcolor NUMBER := 8;
    
        CURSOR c_icon IS
            SELECT img_name, val
              FROM sys_domain
             WHERE img_name IN
                   (pk_utils.str_token(i_mess2, l_pos_iconname, '|'), pk_utils.str_token(i_mess1, l_pos_iconname, '|'))
               AND code_domain = i_domain
               AND domain_owner = pk_sysdomain.k_default_schema
               AND id_language = i_lang
               AND rank = (SELECT MAX(rank)
                             FROM sys_domain
                            WHERE img_name IN (pk_utils.str_token(i_mess2, l_pos_iconname, '|'),
                                               pk_utils.str_token(i_mess1, l_pos_iconname, '|'))
                              AND code_domain = i_domain
                              AND domain_owner = pk_sysdomain.k_default_schema
                              AND id_language = i_lang)
               AND rownum = 1;
    
    BEGIN
        l_mess_out     := NULL;
        g_sysdate_tstz := current_timestamp;
    
        IF i_mess1 IS NULL
           AND i_mess2 IS NOT NULL
        THEN
            l_mess_out := i_mess2;
        ELSIF (i_mess1 IS NOT NULL AND i_mess2 IS NULL)
              OR (i_mess1 IS NULL AND i_mess2 IS NULL)
        THEN
            l_mess_out := i_mess1;
        ELSE
            IF pk_utils.str_token(i_mess1, l_pos_type, '|') = g_icon
            THEN
                -- 1º string é ÍCONE
                OPEN c_icon;
                FETCH c_icon
                    INTO l_img, l_status;
                CLOSE c_icon;
            
                IF pk_utils.str_token(i_mess2, l_pos_type, '|') = g_icon
                THEN
                    -- 2º string é ÍCONE
                    -- devolve o ícone com max(RANK)
                    IF l_img = pk_utils.str_token(i_mess2, l_pos_iconname, '|')
                    THEN
                        l_mess_out := i_mess2;
                    ELSE
                        l_mess_out := i_mess1;
                    END IF;
                ELSIF pk_utils.str_token(i_mess2, l_pos_type, '|') = g_text
                THEN
                    -- 2º string é texto (AGENDADO)
                    IF pk_utils.str_token(i_mess2, l_pos_iconcolor, '|') = g_color_green
                    THEN
                        -- AGENDADO (verde)
                        IF i_cat_type = g_flg_doctor
                        THEN
                            IF l_status = pk_alert_constant.g_flg_status_f
                            THEN
                                l_mess_out := i_mess1; --devolve o ícone para os médicos
                            ELSE
                                l_mess_out := i_mess2;
                            END IF;
                        ELSE
                            l_mess_out := i_mess2; -- devolve AGENDADO para os outros profissionais
                        END IF;
                    ELSE
                        -- AGENDADO (vermelho)
                        l_mess_out := i_mess2; -- devolve AGENDADO
                    END IF;
                
                ELSE
                    --O médico só vê o icon se tiver resultado
                    IF i_cat_type = g_flg_doctor
                    THEN
                        IF l_status = pk_alert_constant.g_flg_status_f
                        THEN
                            l_mess_out := i_mess1; --devolve o ícone para os médicos
                        ELSE
                            l_mess_out := i_mess2;
                        END IF;
                    ELSE
                        l_mess_out := i_mess2; -- devolve a DATA para os outros profissionais
                    END IF;
                END IF;
            
            ELSIF pk_utils.str_token(i_mess1, l_pos_type, '|') IN (g_date, g_dateicon)
            THEN
                -- 1º string DATA          
                IF pk_utils.str_token(i_mess2, l_pos_type, '|') IN (g_date, g_dateicon)
                THEN
                    -- 2º string tb é DATA
                    l_mess_out := least(i_mess1, i_mess2); -- devolve a + atrasada
                
                ELSIF pk_utils.str_token(i_mess2, l_pos_type, '|') = g_icon
                THEN
                    --2ª string é um ícone
                    OPEN c_icon;
                    FETCH c_icon
                        INTO l_img, l_status;
                    CLOSE c_icon;
                
                    --O médico só vê o icon se tiver resultado
                    IF i_cat_type = g_flg_doctor
                    THEN
                        IF l_status = pk_alert_constant.g_flg_status_f
                        THEN
                            l_mess_out := i_mess2; --devolve o ícone para os médicos
                        ELSE
                            l_mess_out := i_mess1;
                        END IF;
                    ELSE
                        l_mess_out := i_mess1; -- devolve a DATA para os outros profissionais
                    END IF;
                
                ELSE
                    --  2º string é texto (AGENDADO)
                    l_mess_out := i_mess1; -- devolve a DATA
                END IF;
            
            ELSIF pk_utils.str_token(i_mess1, l_pos_type, '|') = g_text
            THEN
                -- 1º string texto (AGENDADO)           
                IF pk_utils.str_token(i_mess1, l_pos_iconcolor, '|') = g_color_green
                THEN
                    -- AGENDADO (verde)
                    IF pk_utils.str_token(i_mess2, l_pos_type, '|') = g_icon
                    THEN
                        -- 2º string é ÍCONE
                        OPEN c_icon;
                        FETCH c_icon
                            INTO l_img, l_status;
                        CLOSE c_icon;
                    
                        --O médico só vê o icon se tiver resultado
                        IF i_cat_type = g_flg_doctor
                        THEN
                            IF l_status = pk_alert_constant.g_flg_status_f
                            THEN
                                l_mess_out := i_mess2; -- devolve o ícone para os médicos
                            ELSE
                                l_mess_out := i_mess1;
                            END IF;
                        ELSE
                            l_mess_out := i_mess1; -- devolve AGENDADO para os outros profissionais
                        END IF;
                    ELSIF pk_utils.str_token(i_mess2, l_pos_type, '|') IN (g_date, g_dateicon)
                    THEN
                        l_mess_out := i_mess2;
                    ELSE
                        l_mess_out := i_mess1; -- devolve AGENDADO
                    END IF;
                ELSE
                    -- AGENDADO (vermelho)
                    IF pk_utils.str_token(i_mess2, l_pos_type, '|') IN (g_date, g_dateicon)
                    THEN
                        -- 2º string é DATA
                        l_mess_out := i_mess2; -- devolve a DATA
                    ELSE
                        -- AGENDADO ou ÍCONE
                        l_mess_out := i_mess1; -- devolve AGENDADO
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN l_mess_out;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /**********************************************************************************************
    * Compares timestamps embedded in messages i_mess1 and i_mess2 and returns the message with 
    * the most oldest timestamp.
    *
    * This is a simpler version of get_prioritary_task(i_lang, i_mess1, i_mess2, i_domain, i_cat_type).
    *
    * @param i_lang                   the id language
    * @param i_mess1                  message 1
    * @param i_mess1                  message 2       
    *
    * @return                         the message with the most oldest timestamp
    *                        
    * @author                         Rui Baeta
    * @version                        1.0 
    * @since                          2008/01/08
    *
    * @author                         José Silva
    * @version                        2.0 
    * @since                          2008/03/26    
    **********************************************************************************************/
    FUNCTION get_prioritary_task
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_mess1    IN VARCHAR2,
        i_mess2    IN VARCHAR2,
        i_domain   IN VARCHAR2,
        i_prof_cat IN category.flg_type%TYPE,
        i_test     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_aux_mess_ini1 pk_types.t_med_char;
        l_aux_mess_ini2 pk_types.t_med_char;
    
        l_aux_mess_end1 pk_types.t_med_char;
        l_aux_mess_end2 pk_types.t_med_char;
        l_gt_field      pk_types.t_med_char;
    
    BEGIN
        -- if one message is null return the other one (even if the other one is null)
        IF i_mess1 IS NULL
        THEN
            RETURN i_mess2;
        END IF;
        IF i_mess2 IS NULL
        THEN
            RETURN i_mess1;
        END IF;
    
        l_aux_mess_ini1 := substr(i_mess1, 1, instr(i_mess1, '|'));
        l_aux_mess_ini2 := substr(i_mess2, 1, instr(i_mess2, '|'));
    
        l_aux_mess_end1 := substr(i_mess1, instr(i_mess1, '|') + 1);
        l_aux_mess_end2 := substr(i_mess2, instr(i_mess2, '|') + 1);
    
        l_gt_field := pk_grid.get_prioritary_task(i_lang, l_aux_mess_end1, l_aux_mess_end2, i_domain, i_prof_cat);
    
        IF l_gt_field = l_aux_mess_end1
        THEN
            IF i_test = pk_alert_constant.g_yes
            THEN
                RETURN i_mess1;
            ELSE
                RETURN l_aux_mess_ini1 || l_gt_field;
            END IF;
        ELSIF l_gt_field = l_aux_mess_end2
        THEN
            IF i_test = pk_alert_constant.g_yes
            THEN
                RETURN i_mess2;
            ELSE
                RETURN l_aux_mess_ini2 || l_gt_field;
            END IF;
        END IF;
    
        RETURN NULL;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_prioritary_task;

    FUNCTION delete_epis_grid_task
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Apagar o episódio da tabela GRID_TASK se já não houver tarefas
                  por realizar nesse episódio.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_EPISODE - ID do episódio
                  Saida: O_ERROR - erro
          CRIAÇÃO: SS 2006/01/23
          NOTAS:
        *********************************************************************************/
    
        -- Ver se existe algum registo em GRID_TASK para o episódio sem tarefas por realizar
        CURSOR c_epis IS
            SELECT 'X'
              FROM grid_task
             WHERE id_episode = i_episode
               AND analysis_d IS NULL
               AND analysis_n IS NULL
               AND harvest IS NULL
               AND exam_d IS NULL
               AND exam_n IS NULL
               AND drug_presc IS NULL
               AND drug_req IS NULL
               AND drug_transp IS NULL
               AND intervention IS NULL
               AND monitorization IS NULL
               AND nurse_activity IS NULL
               AND teach_req IS NULL
               AND movement IS NULL
               AND clin_rec_req IS NULL
               AND clin_rec_transp IS NULL
               AND vaccine IS NULL
               AND hemo_req IS NULL
               AND material_req IS NULL
               AND icnp_intervention IS NULL
               AND positioning IS NULL
               AND hidrics_reg IS NULL
               AND scale_value IS NULL
               AND prescription_n IS NULL
               AND prescription_p IS NULL
               AND discharge_pend IS NULL
               AND supplies IS NULL
               AND noc_outcome IS NULL
               AND noc_indicator IS NULL
               AND nic_activity IS NULL
               AND opinion_state IS NULL
               AND oth_exam_d IS NULL
               AND oth_exam_n IS NULL
               AND img_exam_d IS NULL
               AND img_exam_n IS NULL;
    
        l_task  VARCHAR2(1);
        l_error t_error_out;
    
    BEGIN
        g_sysdate := SYSDATE;
        --dbms_output.put_line('I_EPISODE: ' || i_episode);
        alertlog.pk_alertlog.log_debug('I_EPISODE: ' || i_episode);
        --
        OPEN c_epis;
        FETCH c_epis
            INTO l_task;
        g_found := c_epis%FOUND;
        CLOSE c_epis;
    
        g_error := 'DELETE GRID_TASK';
        IF g_found
        THEN
            --dbms_output.put_line(g_error);
            alertlog.pk_alertlog.log_debug(g_error);
            DELETE grid_task
             WHERE id_episode = i_episode;
        END IF;
    
        g_error := 'CALL TO PK_GRID.DELETE_EPIS_GRID_TASK';
        --dbms_output.put_line(g_error);
        alertlog.pk_alertlog.log_debug(g_error);
        IF NOT pk_grid.delete_nurse_task(i_lang => i_lang, i_episode => i_episode, o_error => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            ROLLBACK;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'DELETE_EPIS_GRID_TASK');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    FUNCTION update_grid_task
    (
        i_lang      IN language.id_language%TYPE,
        i_grid_task IN grid_task%ROWTYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Insere/Actualiza registo na tabela GRID_TASK.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_GRID_TASK - Rowtype da tabela GRID_TASK
                  Saida: O_ERROR - erro
          CRIAÇÃO: RB 2006/01/26
          NOTAS:
        *********************************************************************************/
        num_reg PLS_INTEGER;
    
    BEGIN
    
        --Verifica se já existe registo para o episódio em causa
        SELECT COUNT(*)
          INTO num_reg
          FROM grid_task
         WHERE id_episode = i_grid_task.id_episode;
    
        IF num_reg = 0
        THEN
            --o registo ainda não existe e vai ser inserido
            g_error := 'INSERT INTO GRID_TASK';
            INSERT INTO grid_task
                (id_grid_task,
                 id_episode,
                 analysis_d,
                 analysis_n,
                 harvest,
                 exam_d,
                 exam_n,
                 drug_presc,
                 drug_req,
                 drug_transp,
                 intervention,
                 monitorization,
                 nurse_activity,
                 teach_req,
                 movement,
                 clin_rec_req,
                 clin_rec_transp,
                 vaccine,
                 hemo_req,
                 material_req,
                 icnp_intervention,
                 positioning,
                 hidrics_reg,
                 scale_value,
                 discharge_pend,
                 supplies,
                 oth_exam_d,
                 oth_exam_n,
                 img_exam_d,
                 img_exam_n,
                 opinion_state,
                 disp_task,
                 disp_ivroom)
            VALUES
                (seq_grid_task.nextval,
                 i_grid_task.id_episode,
                 i_grid_task.analysis_d,
                 i_grid_task.analysis_n,
                 i_grid_task.harvest,
                 i_grid_task.exam_d,
                 i_grid_task.exam_n,
                 i_grid_task.drug_presc,
                 i_grid_task.drug_req,
                 i_grid_task.drug_transp,
                 i_grid_task.intervention,
                 i_grid_task.monitorization,
                 i_grid_task.nurse_activity,
                 i_grid_task.teach_req,
                 i_grid_task.movement,
                 i_grid_task.clin_rec_req,
                 i_grid_task.clin_rec_transp,
                 i_grid_task.vaccine,
                 i_grid_task.hemo_req,
                 i_grid_task.material_req,
                 i_grid_task.icnp_intervention,
                 i_grid_task.positioning,
                 i_grid_task.hidrics_reg,
                 i_grid_task.scale_value,
                 i_grid_task.discharge_pend,
                 i_grid_task.supplies,
                 i_grid_task.oth_exam_d,
                 i_grid_task.oth_exam_n,
                 i_grid_task.img_exam_d,
                 i_grid_task.img_exam_n,
                 i_grid_task.opinion_state,
                 i_grid_task.disp_task,
                 i_grid_task.disp_ivroom);
        ELSE
            --O registo já existe e vai ser actualizado nos campos preenchidos na variável recebida por parâmetro
            g_error := 'UPDATE GRID_TASK';
            UPDATE grid_task
               SET analysis_d        = nvl(i_grid_task.analysis_d, analysis_d),
                   analysis_n        = nvl(i_grid_task.analysis_n, analysis_n),
                   harvest           = nvl(i_grid_task.harvest, harvest),
                   exam_d            = nvl(i_grid_task.exam_d, exam_d),
                   exam_n            = nvl(i_grid_task.exam_n, exam_n),
                   drug_presc        = nvl(i_grid_task.drug_presc, drug_presc),
                   drug_req          = nvl(i_grid_task.drug_req, drug_req),
                   drug_transp       = nvl(i_grid_task.drug_transp, drug_transp),
                   intervention      = nvl(i_grid_task.intervention, intervention),
                   monitorization    = nvl(i_grid_task.monitorization, monitorization),
                   nurse_activity    = nvl(i_grid_task.nurse_activity, nurse_activity),
                   teach_req         = nvl(i_grid_task.teach_req, teach_req),
                   movement          = nvl(i_grid_task.movement, movement),
                   clin_rec_req      = nvl(i_grid_task.clin_rec_req, clin_rec_req),
                   clin_rec_transp   = nvl(i_grid_task.clin_rec_transp, clin_rec_transp),
                   vaccine           = nvl(i_grid_task.vaccine, vaccine),
                   hemo_req          = nvl(i_grid_task.hemo_req, hemo_req),
                   material_req      = nvl(i_grid_task.material_req, material_req),
                   icnp_intervention = nvl(i_grid_task.icnp_intervention, icnp_intervention),
                   positioning       = nvl(i_grid_task.positioning, positioning),
                   hidrics_reg       = nvl(i_grid_task.hidrics_reg, hidrics_reg),
                   scale_value       = nvl(i_grid_task.scale_value, scale_value),
                   discharge_pend    = nvl(i_grid_task.discharge_pend, discharge_pend),
                   supplies          = nvl(i_grid_task.supplies, supplies),
                   oth_exam_d        = nvl(i_grid_task.oth_exam_d, oth_exam_d),
                   oth_exam_n        = nvl(i_grid_task.oth_exam_n, oth_exam_n),
                   img_exam_d        = nvl(i_grid_task.img_exam_d, img_exam_d),
                   img_exam_n        = nvl(i_grid_task.img_exam_n, img_exam_n),
                   opinion_state     = nvl(i_grid_task.opinion_state, opinion_state),
                   disp_task         = nvl(i_grid_task.disp_task, disp_task),
                   disp_ivroom       = nvl(i_grid_task.disp_ivroom, disp_ivroom)
             WHERE id_episode = i_grid_task.id_episode;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'UPDATE_GRID_TASK');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                -- Nao usei porque a funcao anterior tb n fazia commit nem rollback
                --                pk_utils.undo_changes; 
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    FUNCTION update_grid_task
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_episode             IN episode.id_episode%TYPE,
        analysis_d_in         IN grid_task.analysis_d%TYPE DEFAULT NULL,
        analysis_d_nin        IN BOOLEAN := TRUE,
        analysis_n_in         IN grid_task.analysis_n%TYPE DEFAULT NULL,
        analysis_n_nin        IN BOOLEAN := TRUE,
        harvest_in            IN grid_task.harvest%TYPE DEFAULT NULL,
        harvest_nin           IN BOOLEAN := TRUE,
        exam_d_in             IN grid_task.exam_d%TYPE DEFAULT NULL,
        exam_d_nin            IN BOOLEAN := TRUE,
        exam_n_in             IN grid_task.exam_n%TYPE DEFAULT NULL,
        exam_n_nin            IN BOOLEAN := TRUE,
        drug_presc_in         IN grid_task.drug_presc%TYPE DEFAULT NULL,
        drug_presc_nin        IN BOOLEAN := TRUE,
        drug_req_in           IN grid_task.drug_req%TYPE DEFAULT NULL,
        drug_req_nin          IN BOOLEAN := TRUE,
        drug_transp_in        IN grid_task.drug_transp%TYPE DEFAULT NULL,
        drug_transp_nin       IN BOOLEAN := TRUE,
        intervention_in       IN grid_task.intervention%TYPE DEFAULT NULL,
        intervention_nin      IN BOOLEAN := TRUE,
        monitorization_in     IN grid_task.monitorization%TYPE DEFAULT NULL,
        monitorization_nin    IN BOOLEAN := TRUE,
        nurse_activity_in     IN grid_task.nurse_activity%TYPE DEFAULT NULL,
        nurse_activity_nin    IN BOOLEAN := TRUE,
        teach_req_in          IN grid_task.teach_req%TYPE DEFAULT NULL,
        teach_req_nin         IN BOOLEAN := TRUE,
        movement_in           IN grid_task.movement%TYPE DEFAULT NULL,
        movement_nin          IN BOOLEAN := TRUE,
        clin_rec_req_in       IN grid_task.clin_rec_req%TYPE DEFAULT NULL,
        clin_rec_req_nin      IN BOOLEAN := TRUE,
        clin_rec_transp_in    IN grid_task.clin_rec_transp%TYPE DEFAULT NULL,
        clin_rec_transp_nin   IN BOOLEAN := TRUE,
        vaccine_in            IN grid_task.vaccine%TYPE DEFAULT NULL,
        vaccine_nin           IN BOOLEAN := TRUE,
        hemo_req_in           IN grid_task.hemo_req%TYPE DEFAULT NULL,
        hemo_req_nin          IN BOOLEAN := TRUE,
        material_req_in       IN grid_task.material_req%TYPE DEFAULT NULL,
        material_req_nin      IN BOOLEAN := TRUE,
        icnp_intervention_in  IN grid_task.icnp_intervention%TYPE DEFAULT NULL,
        icnp_intervention_nin IN BOOLEAN := TRUE,
        positioning_in        IN grid_task.positioning%TYPE DEFAULT NULL,
        positioning_nin       IN BOOLEAN := TRUE,
        hidrics_reg_in        IN grid_task.hidrics_reg%TYPE DEFAULT NULL,
        hidrics_reg_nin       IN BOOLEAN := TRUE,
        scale_value_in        IN grid_task.scale_value%TYPE DEFAULT NULL,
        scale_value_nin       IN BOOLEAN := TRUE,
        prescription_n_in     IN grid_task.prescription_n%TYPE DEFAULT NULL,
        prescription_n_nin    IN BOOLEAN := TRUE,
        prescription_p_in     IN grid_task.prescription_p%TYPE DEFAULT NULL,
        prescription_p_nin    IN BOOLEAN := TRUE,
        discharge_pend_in     IN grid_task.discharge_pend%TYPE DEFAULT NULL,
        discharge_pend_nin    IN BOOLEAN := TRUE,
        supplies_in           IN grid_task.supplies%TYPE DEFAULT NULL,
        supplies_nin          IN BOOLEAN := TRUE,
        noc_outcome_in        IN grid_task.noc_outcome%TYPE DEFAULT NULL,
        noc_outcome_nin       IN BOOLEAN := TRUE,
        noc_indicator_in      IN grid_task.noc_indicator%TYPE DEFAULT NULL,
        noc_indicator_nin     IN BOOLEAN := TRUE,
        nic_activity_in       IN grid_task.nic_activity%TYPE DEFAULT NULL,
        nic_activity_nin      IN BOOLEAN := TRUE,
        opinion_state_in      IN grid_task.opinion_state%TYPE DEFAULT NULL,
        opinion_state_nin     IN BOOLEAN := TRUE,
        oth_exam_d_in         IN grid_task.oth_exam_d%TYPE DEFAULT NULL,
        oth_exam_d_nin        IN BOOLEAN := TRUE,
        oth_exam_n_in         IN grid_task.oth_exam_n%TYPE DEFAULT NULL,
        oth_exam_n_nin        IN BOOLEAN := TRUE,
        img_exam_d_in         IN grid_task.img_exam_d%TYPE DEFAULT NULL,
        img_exam_d_nin        IN BOOLEAN := TRUE,
        img_exam_n_in         IN grid_task.img_exam_n%TYPE DEFAULT NULL,
        img_exam_n_nin        IN BOOLEAN := TRUE,
        disp_task_in          IN grid_task.disp_task%TYPE DEFAULT NULL,
        disp_task_nin         IN BOOLEAN := TRUE,
        disp_ivroom_in        IN grid_task.disp_ivroom%TYPE DEFAULT NULL,
        disp_ivroom_nin       IN BOOLEAN := TRUE,
        common_order_in       IN grid_task.common_order%TYPE DEFAULT NULL,
        common_order_nin      IN BOOLEAN := TRUE,
        medical_order_in      IN grid_task.medical_order%TYPE DEFAULT NULL,
        medical_order_nin     IN BOOLEAN := TRUE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_grid_task grid_task.id_grid_task%TYPE;
    
    BEGIN
    
        BEGIN
            SELECT gt.id_grid_task
              INTO l_grid_task
              FROM grid_task gt
             WHERE gt.id_episode = i_episode;
        
            g_error := 'TS_GRID_TASK.UPD';
            ts_grid_task.upd(id_grid_task_in       => l_grid_task,
                             analysis_d_in         => analysis_d_in,
                             analysis_d_nin        => analysis_d_nin,
                             analysis_n_in         => analysis_n_in,
                             analysis_n_nin        => analysis_n_nin,
                             harvest_in            => harvest_in,
                             harvest_nin           => harvest_nin,
                             exam_d_in             => exam_d_in,
                             exam_d_nin            => exam_d_nin,
                             exam_n_in             => exam_n_in,
                             exam_n_nin            => exam_n_nin,
                             drug_presc_in         => drug_presc_in,
                             drug_presc_nin        => drug_presc_nin,
                             drug_req_in           => drug_req_in,
                             drug_req_nin          => drug_req_nin,
                             drug_transp_in        => drug_transp_in,
                             drug_transp_nin       => drug_transp_nin,
                             intervention_in       => intervention_in,
                             intervention_nin      => intervention_nin,
                             monitorization_in     => monitorization_in,
                             monitorization_nin    => monitorization_nin,
                             nurse_activity_in     => nurse_activity_in,
                             nurse_activity_nin    => nurse_activity_nin,
                             teach_req_in          => teach_req_in,
                             teach_req_nin         => teach_req_nin,
                             movement_in           => movement_in,
                             movement_nin          => movement_nin,
                             clin_rec_req_in       => clin_rec_req_in,
                             clin_rec_req_nin      => clin_rec_req_nin,
                             clin_rec_transp_in    => clin_rec_transp_in,
                             clin_rec_transp_nin   => clin_rec_transp_nin,
                             vaccine_in            => vaccine_in,
                             vaccine_nin           => vaccine_nin,
                             hemo_req_in           => hemo_req_in,
                             hemo_req_nin          => hemo_req_nin,
                             material_req_in       => material_req_in,
                             material_req_nin      => material_req_nin,
                             icnp_intervention_in  => icnp_intervention_in,
                             icnp_intervention_nin => icnp_intervention_nin,
                             positioning_in        => positioning_in,
                             positioning_nin       => positioning_nin,
                             hidrics_reg_in        => hidrics_reg_in,
                             hidrics_reg_nin       => hidrics_reg_nin,
                             scale_value_in        => scale_value_in,
                             scale_value_nin       => scale_value_nin,
                             prescription_n_in     => prescription_n_in,
                             prescription_n_nin    => prescription_n_nin,
                             prescription_p_in     => prescription_p_in,
                             prescription_p_nin    => prescription_p_nin,
                             discharge_pend_in     => discharge_pend_in,
                             discharge_pend_nin    => discharge_pend_nin,
                             supplies_in           => supplies_in,
                             supplies_nin          => supplies_nin,
                             noc_outcome_in        => noc_outcome_in,
                             noc_outcome_nin       => noc_outcome_nin,
                             noc_indicator_in      => noc_indicator_in,
                             noc_indicator_nin     => noc_indicator_nin,
                             nic_activity_in       => nic_activity_in,
                             nic_activity_nin      => nic_activity_nin,
                             opinion_state_in      => opinion_state_in,
                             opinion_state_nin     => opinion_state_nin,
                             oth_exam_d_in         => oth_exam_d_in,
                             oth_exam_d_nin        => oth_exam_d_nin,
                             oth_exam_n_in         => oth_exam_n_in,
                             oth_exam_n_nin        => oth_exam_n_nin,
                             img_exam_d_in         => img_exam_d_in,
                             img_exam_d_nin        => img_exam_d_nin,
                             img_exam_n_in         => img_exam_n_in,
                             img_exam_n_nin        => img_exam_n_nin,
                             disp_task_in          => disp_task_in,
                             disp_task_nin         => disp_task_nin,
                             disp_ivroom_in        => disp_ivroom_in,
                             disp_ivroom_nin       => disp_ivroom_nin,
                             common_order_in       => common_order_in,
                             common_order_nin      => common_order_nin,
                             medical_order_in      => medical_order_in,
                             medical_order_nin     => medical_order_nin);
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'TS_GRID_TASK.INS';
                ts_grid_task.ins(id_episode_in        => i_episode,
                                 analysis_d_in        => analysis_d_in,
                                 analysis_n_in        => analysis_n_in,
                                 harvest_in           => harvest_in,
                                 exam_d_in            => exam_d_in,
                                 exam_n_in            => exam_n_in,
                                 drug_presc_in        => drug_presc_in,
                                 drug_req_in          => drug_req_in,
                                 drug_transp_in       => drug_transp_in,
                                 intervention_in      => intervention_in,
                                 monitorization_in    => monitorization_in,
                                 nurse_activity_in    => nurse_activity_in,
                                 teach_req_in         => teach_req_in,
                                 movement_in          => movement_in,
                                 clin_rec_req_in      => clin_rec_req_in,
                                 clin_rec_transp_in   => clin_rec_transp_in,
                                 vaccine_in           => vaccine_in,
                                 hemo_req_in          => hemo_req_in,
                                 material_req_in      => material_req_in,
                                 icnp_intervention_in => icnp_intervention_in,
                                 positioning_in       => positioning_in,
                                 hidrics_reg_in       => hidrics_reg_in,
                                 scale_value_in       => scale_value_in,
                                 prescription_n_in    => prescription_n_in,
                                 prescription_p_in    => prescription_p_in,
                                 discharge_pend_in    => discharge_pend_in,
                                 supplies_in          => supplies_in,
                                 noc_outcome_in       => noc_outcome_in,
                                 noc_indicator_in     => noc_indicator_in,
                                 nic_activity_in      => nic_activity_in,
                                 opinion_state_in     => opinion_state_in,
                                 oth_exam_d_in        => oth_exam_d_in,
                                 oth_exam_n_in        => oth_exam_n_in,
                                 img_exam_d_in        => img_exam_d_in,
                                 img_exam_n_in        => img_exam_n_in,
                                 disp_task_in         => disp_task_in,
                                 disp_ivroom_in       => disp_ivroom_in,
                                 common_order_in      => common_order_in,
                                 medical_order_in     => medical_order_in);
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'UPDATE_GRID_TASK',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_grid_task;

    FUNCTION update_nurse_task
    (
        i_lang      IN language.id_language%TYPE,
        i_grid_task IN grid_task_between%ROWTYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Insere/Actualiza registo na tabela GRID_TASK_BETWEEN.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_GRID_TASK - Rowtype da tabela GRID_TASK_BETWEEN
                  Saida: O_ERROR - erro
          CRIAÇÃO: SS 2006/05/02
          NOTAS:
        *********************************************************************************/
        num_reg PLS_INTEGER;
    
    BEGIN
    
        --Verifica se já existe registo para o episódio em causa
        SELECT COUNT(*)
          INTO num_reg
          FROM grid_task_between
         WHERE id_episode = i_grid_task.id_episode;
    
        IF num_reg = 0
        THEN
            --O registo ainda não existe e vai ser inserido
            g_error := 'INSERT INTO GRID_TASK_BETWEEN';
            INSERT INTO grid_task_between
                (id_grid_task_between,
                 id_episode,
                 flg_drug,
                 flg_interv,
                 flg_monitor,
                 flg_nurse_act,
                 flg_pharm,
                 flg_vaccine,
                 flg_icnp_interv)
            VALUES
                (seq_grid_task_between.nextval,
                 i_grid_task.id_episode,
                 i_grid_task.flg_drug,
                 i_grid_task.flg_interv,
                 i_grid_task.flg_monitor,
                 i_grid_task.flg_nurse_act,
                 i_grid_task.flg_pharm,
                 i_grid_task.flg_vaccine,
                 i_grid_task.flg_icnp_interv);
        ELSE
            --O registo já existe e vai ser actualizado nos campos preenchidos na variável recebida por parâmetro
            g_error := 'UPDATE GRID_TASK_BETWEEN';
            UPDATE grid_task_between
               SET flg_drug        = nvl(i_grid_task.flg_drug, flg_drug),
                   flg_interv      = nvl(i_grid_task.flg_interv, flg_interv),
                   flg_monitor     = nvl(i_grid_task.flg_monitor, flg_monitor),
                   flg_nurse_act   = nvl(i_grid_task.flg_nurse_act, flg_nurse_act),
                   flg_pharm       = nvl(i_grid_task.flg_pharm, flg_pharm),
                   flg_vaccine     = nvl(i_grid_task.flg_vaccine, flg_vaccine),
                   flg_icnp_interv = nvl(i_grid_task.flg_icnp_interv, flg_icnp_interv)
             WHERE id_episode = i_grid_task.id_episode;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'UPDATE_NURSE_TASK');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                -- Nao usei porque a funcao anterior tb n fazia commit nem rollback
                --                pk_utils.undo_changes; 
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    FUNCTION delete_nurse_task
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO:   Apagar o episódio da tabela GRID_TASK se já não houver tarefas
                  por realizar nesse episódio.
           PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
                   I_EPISODE - ID do episódio
                  Saida: O_ERROR - erro
          CRIAÇÃO: SS 2006/05/03
          NOTAS:
        *********************************************************************************/
    
        -- Ver se existe algum registo em GRID_TASK para o episódio sem tarefas por realizar
        CURSOR c_epis IS
            SELECT 'X'
              FROM grid_task_between
             WHERE id_episode = i_episode
               AND flg_drug IS NULL
               AND flg_interv IS NULL
               AND flg_monitor IS NULL
               AND flg_nurse_act IS NULL
               AND flg_pharm IS NULL
               AND flg_vaccine IS NULL
               AND flg_icnp_interv IS NULL;
    
        l_task VARCHAR2(1);
    
    BEGIN
        g_sysdate := SYSDATE;
    
        OPEN c_epis;
        FETCH c_epis
            INTO l_task;
        g_found := c_epis%FOUND;
        CLOSE c_epis;
    
        IF g_found
        THEN
            DELETE grid_task_between
             WHERE id_episode = i_episode;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'DELETE_NURSE_TASK');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                -- Nao usei porque a funcao anterior tb n fazia commit nem rollback
                --                pk_utils.undo_changes; 
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    /******************************************************************************
       OBJECTIVO:   Obter lista de episódios que ainda estejam activos ou que pertencem ao dia indicado em I_DT e ainda não tenham sido pagos(Grelha do administrativo).
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                   I_DT - data, caso venha a nulo considerar a data do dia
                 I_PROF - prof q acede
              SAIDA:   O_EPIS - array de episódios
                             O_ERROR - erro
    
      CRIAÇÃO: LG 2007/jan/29
    
      NOTA 1: Nesta grelha visualizam-se os episódios:
             - efectivados sem pagamento,
             - activos sem pagamento,
           - inactivos do dia indicado por I_DT sem pagamento.
      NOTA 1: Nesta grelha não se visualizam:
               - agendamentos,
                   - episódios cancelados.
    
    *********************************************************************************/
    FUNCTION set_up_img
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_flg_state         IN VARCHAR2,
        i_flg_status_adm    IN VARCHAR2,
        i_dt_begin_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_first_obs_tstz IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_med_tstz       IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_admin_tstz     IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_sd2_img_name      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        l_date   TIMESTAMP WITH LOCAL TIME ZONE;
        k_fmt CONSTANT VARCHAR2(0050 CHAR) := 'YYYYMMDDHH24MISS';
        l_sfx VARCHAR2(0010 CHAR);
    BEGIN
    
        CASE i_flg_state
            WHEN g_sched_efectiv THEN
                l_date := i_dt_begin_tstz;
                l_sfx  := '|D|X|';
            
            WHEN g_sched_cons THEN
                l_date := i_dt_first_obs_tstz;
                l_sfx  := '|DI|X|';
            
            WHEN g_sched_med_disch THEN
                l_date := i_dt_med_tstz;
                l_sfx  := '|DI|X|';
            
            WHEN g_sched_adm_disch THEN
                l_date := pk_discharge_core.get_dt_admin(i_lang, i_prof, NULL, i_flg_status_adm, i_dt_admin_tstz);
                l_sfx  := '|DI|X|';
            ELSE
                l_date := NULL;
                l_sfx  := NULL;
        END CASE;
    
        IF l_sfx IS NOT NULL
        THEN
            l_return := pk_date_utils.to_char_insttimezone(i_prof, l_date, k_fmt) || l_sfx;
        ELSE
            l_return := 'xxxxxxxxxxxxxx' || '|I|X|';
        END IF;
    
        l_return := '0|' || l_return || i_sd2_img_name;
    
        RETURN l_return;
    
    END set_up_img;

    FUNCTION get_daily_active_unpayed
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        o_epis  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt1 TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt9 TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_tstz := current_timestamp;
    
        -- JS, 2007-09-11 - Timezone
        g_sysdate_char := pk_date_utils.date_send(i_lang, g_sysdate_tstz, i_prof);
    
        l_dt1 := pk_date_utils.trunc_insttimezone(i_prof,
                                                  nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                      g_sysdate_tstz));
        l_dt9 := pk_date_utils.trunc_insttimezone(i_prof,
                                                  nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                      g_sysdate_tstz)) + INTERVAL '1' DAY;
    
        g_error := 'GET CURSOR ';
    
        OPEN o_epis FOR
            SELECT
            --**************************
             pk_patphoto.get_pat_photo(i_lang, i_prof, id_patient, id_episode, sp_id_schedule) photo,
             gender,
             pk_patient.get_pat_age(i_lang, id_patient, i_prof) pat_age,
             id_patient,
             id_episode,
             pk_patient.get_pat_name(i_lang, i_prof, id_patient, id_episode, sp_id_schedule) name,
             pk_patient.get_pat_name_to_sort(i_lang, i_prof, id_patient, id_episode, sp_id_schedule) name_to_sort,
             pk_adt.get_pat_non_disc_options(i_lang, i_prof, id_patient) pat_ndo,
             pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, id_patient) pat_nd_icon,
             pk_date_utils.date_char_tsz(i_lang, dt_target_tstz, i_prof.institution, i_prof.software) dt_schedule,
             pk_hea_prv_aux.get_clin_service(i_lang, i_prof, id_dep_clin_serv) cons_type,
             coalesce(p1_nick_name, p_nick_name) prof_nick_name,
             coalesce(p1_name, p_name) prof_name,
             lpad(to_char(sd_rank), 6, '0') || sd_img_name img_sched,
             pk_grid.set_up_img(i_lang,
                                i_prof,
                                flg_state,
                                flg_status_adm,
                                dt_begin_tstz,
                                dt_first_obs_tstz,
                                dt_med_tstz,
                                dt_admin_tstz,
                                sd2_img_name) img_state,
             price,
             currency,
             decode(flg_state,
                    g_sched_med_disch,
                    coalesce(flg_payment, g_no),
                    g_sched_adm_disch,
                    coalesce(flg_payment, g_no),
                    NULL) flg_payment,
             g_sysdate_char dt_server,
             ei_id_schedule,
             id_schedule_outp,
             id_discharge,
             pk_date_utils.date_send_tsz(i_lang, dt_target_tstz, i_prof) dt_order,
             flg_contact_type,
             (SELECT pk_sysdomain.get_img(i_lang, g_domain_sch_presence, flg_contact_type)
                FROM dual) icon_contact_type
            --**************************
              FROM (SELECT xsql.*,
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => 'SCHEDULE_OUTP.FLG_SCHED',
                                                i_val      => xsql.flg_sched) sd_img_name,
                           pk_sysdomain.get_rank(i_lang     => i_lang,
                                                 i_code_dom => 'SCHEDULE_OUTP.FLG_SCHED',
                                                 i_val      => xsql.flg_sched) sd_rank,
                           pk_sysdomain.get_img(i_lang     => i_lang,
                                                i_code_dom => g_schdl_outp_state_domain,
                                                i_val      => xsql.flg_state) sd2_img_name
                    --,pk_sysdomain.get_rank(i_lang => i_lang, i_code_dom => g_schdl_outp_state_domain, i_val => xsql.flg_state) sd2_rank
                      FROM (SELECT
                            --*****************************
                             d.currency,
                             d.dt_admin_tstz,
                             d.dt_med_tstz,
                             d.flg_payment,
                             d.flg_status_adm,
                             d.id_discharge,
                             d.price,
                             e.dt_begin_tstz,
                             e.id_episode,
                             ei.dt_first_obs_tstz,
                             ei.id_dep_clin_serv,
                             ei.id_schedule       ei_id_schedule,
                             p.name               p_name,
                             p.nick_name          p_nick_name,
                             p1.name              p1_name,
                             p1.nick_name         p1_nick_name,
                             pat.id_patient,
                             pat.gender,
                             sg.flg_contact_type,
                             sp.dt_target_tstz,
                             sp.flg_sched,
                             sp.flg_state,
                             sp.id_schedule       sp_id_schedule,
                             sp.id_schedule_outp
                            --*****************************
                              FROM schedule_outp sp
                              JOIN sch_group sg
                                ON sg.id_schedule = sp.id_schedule
                              JOIN epis_info ei
                                ON ei.id_schedule = sp.id_schedule
                              JOIN prof_dep_clin_serv pdcs
                                ON pdcs.id_dep_clin_serv = ei.id_dcs_requested
                              LEFT JOIN professional p
                                ON p.id_professional = ei.sch_prof_outp_id_prof
                              LEFT JOIN professional p1
                                ON p1.id_professional = ei.id_professional
                              JOIN episode e
                                ON e.id_episode = ei.id_episode
                              JOIN clinical_service cs
                                ON cs.id_clinical_service = e.id_cs_requested
                              JOIN patient pat
                                ON ei.id_patient = pat.id_patient
                              LEFT JOIN discharge d
                                ON d.id_episode = e.id_episode
                             WHERE e.flg_status <> g_epis_canc -- elimina os episódios cancelados
                               AND sp.dt_target_tstz BETWEEN l_dt1 AND l_dt9 -- JS, 2007-09-11 - Timezone
                               AND sp.id_software = i_prof.software
                               AND ei.id_instit_requested = i_prof.institution -- retorna apenas os registos associados à instituição que faz o pedido
                               AND pdcs.id_professional = i_prof.id -- retorna apenas os registos associados a dep_clin_serv associados ao profissional que faz o pedido
                               AND pdcs.flg_status = g_selected
                                  -- JS, 2007-09-10 - Timezone
                               AND d.dt_cancel_tstz IS NULL -- considera apenas a alta ñ cancelada
                            UNION
                            SELECT
                            --*****************************
                             d.currency,
                             d.dt_admin_tstz,
                             d.dt_med_tstz,
                             d.flg_payment,
                             d.flg_status_adm,
                             d.id_discharge,
                             d.price,
                             e.dt_begin_tstz,
                             e.id_episode,
                             ei.dt_first_obs_tstz,
                             ei.id_dep_clin_serv,
                             ei.id_schedule,
                             p.name,
                             p.nick_name,
                             p1.name,
                             p1.nick_name,
                             pat.id_patient,
                             pat.gender,
                             sg.flg_contact_type,
                             sp.dt_target_tstz,
                             sp.flg_sched,
                             sp.flg_state,
                             sp.id_schedule,
                             sp.id_schedule_outp
                            --*****************************
                              FROM schedule_outp sp
                              JOIN sch_group sg
                                ON sg.id_schedule = sp.id_schedule
                              JOIN epis_info ei
                                ON ei.id_schedule = sp.id_schedule
                              JOIN prof_dep_clin_serv pdcs
                                ON pdcs.id_dep_clin_serv = ei.id_dcs_requested
                              LEFT JOIN professional p
                                ON p.id_professional = ei.sch_prof_outp_id_prof
                              LEFT JOIN professional p1
                                ON p1.id_professional = ei.id_professional
                              JOIN episode e
                                ON e.id_episode = ei.id_episode
                              JOIN clinical_service cs
                                ON cs.id_clinical_service = e.id_cs_requested
                              JOIN patient pat
                                ON ei.id_patient = pat.id_patient
                              LEFT JOIN discharge d
                                ON d.id_episode = e.id_episode
                             WHERE e.flg_status <> g_epis_canc -- elimina os episódios cancelados
                               AND (e.flg_status = g_epis_inactive AND d.flg_payment <> g_yes) -- considera os inactivos sem pagamento
                               AND sp.id_software = i_prof.software
                               AND ei.id_instit_requested = i_prof.institution -- retorna apenas os registos associados à instituição que faz o pedido
                               AND pdcs.id_professional = i_prof.id -- retorna apenas os registos associados a dep_clin_serv associados ao profissional que faz o pedido
                               AND pdcs.flg_status = g_selected
                                  -- JS, 2007-09-10 - Timezone
                               AND d.dt_cancel_tstz IS NULL -- considera apenas a alta ñ cancelada
                            ) xsql) xmain
             ORDER BY xmain.dt_target_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'GET_DAILY_ACTIVE_UNPAYED');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_epis);
                RETURN FALSE;
            
            END;
    END get_daily_active_unpayed;

    /**
    * Return grid_task fields to professional timezone.
    *
    * @param      I_LANG              língua registada como preferência do profissional.
    * @param      I_PROF              object (ID do profissional, ID da instituição, ID do software).
    * @param      I_STR               Texto de GRID_TASK
    * @param      I_POSITION          Position of the date field
    * @param      O_ERROR             erro
    *
    * @return     varchar2
    * @author     Rui Spratley/João Sá
    * @version    0.1
    * @since      2007/09/10
    * @notes
    */
    FUNCTION convert_grid_task_str
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_str      IN VARCHAR2,
        i_position IN NUMBER DEFAULT 2
    ) RETURN VARCHAR2 IS
    
        l_aux1 VARCHAR2(200);
        l_aux2 VARCHAR2(14);
    
    BEGIN
    
        l_aux1 := pk_utils.str_token(i_str, i_position, '|');
    
        IF l_aux1 != 'xxxxxxxxxxxxxx'
        THEN
            l_aux2 := pk_date_utils.date_send_tsz(i_lang, to_timestamp_tz(l_aux1, 'YYYYMMDDHH24MISS TZR'), i_prof);
        ELSE
            RETURN i_str;
        END IF;
    
        RETURN REPLACE(i_str, l_aux1, l_aux2);
    
    EXCEPTION
        WHEN OTHERS THEN
            alertlog.pk_alertlog.log_error('convert_grid_task_str - i_lang:' || i_lang || '|i_prof.id:' || i_prof.id ||
                                           '|i_prof.institution:' || i_prof.institution || '|i_prof.software:' ||
                                           i_prof.software || '|i_str:' || i_str || '|i_position:' || i_position ||
                                           '| SQLERRM:' || SQLERRM);
            RETURN NULL;
    END convert_grid_task_str;

    /**
    * Returns grid_task analysis or exam fields for a given visit.
    *
    * @param      I_LANG              language ID
    * @param      I_PROF              object (professional ID, institution ID, software ID).
    * @param      I_VISIT             visit ID
    * @param      I_TYPE              field type: A - analysis; E - exam; H - harvest
    * @param      O_ERROR             error message
    *
    * @return     varchar2
    * @author     José Silva
    * @version    1.0
    * @since      2008/01/16
    */
    FUNCTION visit_grid_task_str
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_type     IN VARCHAR2,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_gt_field pk_types.t_med_char;
    
        l_analysis          CONSTANT VARCHAR2(2) := 'A';
        l_exam              CONSTANT VARCHAR2(2) := 'E';
        l_harvest           CONSTANT VARCHAR2(2) := 'H';
        l_monitoring        CONSTANT VARCHAR2(2) := 'M';
        l_interv            CONSTANT VARCHAR2(2) := 'I';
        l_movement          CONSTANT VARCHAR2(2) := 'T';
        l_patient_education CONSTANT VARCHAR2(2) := pk_inp_grid.g_task_edu;
    
        l_mess2        pk_types.t_med_char;
        l_aux_mess_ini pk_types.t_low_char;
        l_aux_mess_end pk_types.t_med_char;
        l_shortcut     pk_types.t_low_char;
    
        CURSOR c_task_field IS
            SELECT decode(i_type,
                          l_analysis,
                          decode(i_prof_cat, g_flg_nurse, gt.analysis_n, gt.analysis_d),
                          l_harvest,
                          gt.harvest,
                          l_exam,
                          decode(i_prof_cat,
                                 g_flg_nurse,
                                 pk_grid.get_prioritary_task(i_lang,
                                                             i_prof,
                                                             gt.oth_exam_n,
                                                             gt.img_exam_n,
                                                             NULL,
                                                             g_flg_nurse),
                                 pk_grid.get_prioritary_task(i_lang,
                                                             i_prof,
                                                             gt.oth_exam_d,
                                                             gt.img_exam_d,
                                                             NULL,
                                                             g_flg_doctor)),
                          l_interv,
                          gt.intervention,
                          l_monitoring,
                          gt.monitorization,
                          l_patient_education,
                          gt.teach_req,
                          l_movement,
                          gt.movement,
                          'CO',
                          nvl(gt.common_order, gt.medical_order)) field_mcdt
              FROM grid_task gt, episode e
             WHERE gt.id_episode = e.id_episode
               AND e.id_visit = i_visit;
    
        TYPE t_c IS TABLE OF c_task_field%ROWTYPE;
        l_c t_c;
    
    BEGIN
        g_error := 'CASE';
        l_mess2 := CASE i_type
                       WHEN l_analysis THEN
                        'ANALYSIS_REQ.FLG_STATUS'
                       WHEN l_harvest THEN
                        'HARVEST.FLG_STATUS'
                       WHEN l_exam THEN
                        'EXAM_REQ.FLG_STATUS'
                       WHEN l_interv THEN
                        'INTERV_PRESCRIPTION.FLG_STATUS'
                       WHEN l_monitoring THEN
                        'MONITORIZATION_VS.FLG_STATUS'
                       WHEN l_patient_education THEN
                        'NURSE_TEA_REQ.FLG_STATUS'
                       WHEN l_movement THEN
                        'MOVEMENT.FLG_STATUS'
                       WHEN 'CO' THEN
                        'COMM_ORDER_REQ.ID_STATUS'
                   END;
    
        g_error := 'CURSOR';
        OPEN c_task_field;
        FETCH c_task_field BULK COLLECT
            INTO l_c;
        CLOSE c_task_field;
        IF l_c IS NOT NULL
           AND l_c.count > 0
        THEN
            FOR i IN 1 .. l_c.count
            LOOP
                --Get priority task function does not have the shortcut parameter (10|)
                l_aux_mess_ini := substr(l_c(i).field_mcdt, 1, instr(l_c(i).field_mcdt, '|'));
                l_aux_mess_end := substr(l_c(i).field_mcdt, instr(l_c(i).field_mcdt, '|') + 1);
            
                l_gt_field := pk_grid.get_prioritary_task(i_lang,
                                                          l_gt_field,
                                                          l_aux_mess_end, --r_task_field.field_mcdt,
                                                          l_mess2, --'EXAM_REQ.FLG_STATUS',
                                                          i_prof_cat);
            
                IF l_gt_field = l_aux_mess_end
                THEN
                    l_shortcut := l_aux_mess_ini;
                END IF;
            END LOOP;
        END IF;
    
        RETURN pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_shortcut || l_gt_field);
    
    EXCEPTION
        WHEN OTHERS THEN
            alertlog.pk_alertlog.log_error(SQLERRM);
            RETURN NULL;
    END visit_grid_task_str;

    /**********************************************************************************************
    * VISIT_GRID_TASK_STR No Convert. Similar to VISIT_GRID_TASK_STR, yet no call to CONVERT_GRID_TASK_STR
    * is made in the end. Check NURSE_EFECTIV_CARE for usage example.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_visit                  visit identifier
    * @param i_type                   field type
    * @param i_prof_cat               professional category type
    *
    * @value i_type                   {*} 'A' Analysis {*} 'E' Exams {*} 'H' Harvests {*} 'M' Monitorizations {*} 'I' Intervention prescriptions
    *
    * @return                         varchar
    *
    * @raises
    *
    * @author                         Pedro Carneiro
    * @version                         1.0
    * @since                          2009/04/07
    **********************************************************************************************/
    FUNCTION visit_grid_task_str_nc
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_visit    IN visit.id_visit%TYPE,
        i_type     IN VARCHAR2,
        i_prof_cat IN category.flg_type%TYPE
    ) RETURN VARCHAR2 IS
    
        l_gt_field pk_types.t_med_char;
    
        l_field_analysis CONSTANT VARCHAR2(2) := 'A';
        l_field_exam     CONSTANT VARCHAR2(2) := 'E';
        l_field_harvest  CONSTANT VARCHAR2(2) := 'H';
        l_field_monitor  CONSTANT VARCHAR2(2) := 'M';
        l_interv_presc   CONSTANT VARCHAR2(2) := 'I';
    
        l_mess2        pk_types.t_med_char;
        l_aux_mess_ini pk_types.t_low_char;
        l_aux_mess_end pk_types.t_med_char;
        l_shortcut     pk_types.t_low_char;
    
        CURSOR c_task_field IS
            SELECT decode(i_type,
                          l_field_analysis,
                          decode(i_prof_cat, g_flg_nurse, gt.analysis_n, gt.analysis_d),
                          l_field_exam,
                          decode(i_prof_cat,
                                 g_flg_nurse,
                                 pk_grid.get_prioritary_task(i_lang,
                                                             i_prof,
                                                             gt.oth_exam_n,
                                                             gt.img_exam_n,
                                                             NULL,
                                                             g_flg_nurse),
                                 pk_grid.get_prioritary_task(i_lang,
                                                             i_prof,
                                                             gt.oth_exam_d,
                                                             gt.img_exam_d,
                                                             NULL,
                                                             g_flg_doctor)),
                          l_field_harvest,
                          gt.harvest,
                          l_field_monitor,
                          gt.monitorization,
                          l_interv_presc,
                          gt.intervention) field_mcdt
              FROM grid_task gt, episode e
             WHERE gt.id_episode = e.id_episode
               AND e.id_visit = i_visit;
    
        TYPE t_c IS TABLE OF c_task_field%ROWTYPE;
        l_c t_c;
    
    BEGIN
        g_error := 'CASE';
        l_mess2 := CASE i_type
                       WHEN l_field_analysis THEN
                        'ANALYSIS_REQ.FLG_STATUS'
                       WHEN l_field_exam THEN
                        'EXAM_REQ.FLG_STATUS'
                       WHEN l_field_harvest THEN
                        'HARVEST.FLG_STATUS'
                       WHEN l_field_monitor THEN
                        'MONITORIZATION_VS.FLG_STATUS'
                       WHEN l_interv_presc THEN
                        'INTERV_PRESCRIPTION.FLG_STATUS'
                   END;
    
        g_error := 'CURSOR';
        OPEN c_task_field;
        FETCH c_task_field BULK COLLECT
            INTO l_c;
        CLOSE c_task_field;
        IF l_c IS NOT NULL
           AND l_c.count > 0
        THEN
            FOR i IN 1 .. l_c.count
            LOOP
                --Get priority task function does not have the shortcut parameter (10|)
                l_aux_mess_ini := substr(l_c(i).field_mcdt, 1, instr(l_c(i).field_mcdt, '|'));
                l_aux_mess_end := substr(l_c(i).field_mcdt, instr(l_c(i).field_mcdt, '|') + 1);
            
                l_gt_field := get_prioritary_task(i_lang,
                                                  l_gt_field,
                                                  l_aux_mess_end, --r_task_field.field_mcdt,
                                                  l_mess2, --'EXAM_REQ.FLG_STATUS',
                                                  i_prof_cat);
            
                IF l_gt_field = l_aux_mess_end
                THEN
                    l_shortcut := l_aux_mess_ini;
                END IF;
            END LOOP;
        END IF;
    
        RETURN l_shortcut || l_gt_field;
    
    EXCEPTION
        WHEN OTHERS THEN
            alertlog.pk_alertlog.log_error(SQLERRM);
            RETURN NULL;
    END visit_grid_task_str_nc;

    FUNCTION get_pat_status_list_session
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN VARCHAR2,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        /******************************************************************************
           OBJECTIVO:   Obtem a lista de estados possíveis de um paciente
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                 I_PROF - ID do profissional, software e instituição
                                 I_FLG_STATUS - Estado actual do paciente
                                 i_id_schedule - Id do agendamento
                         SAIDA:  O_STATUS - Lista de salas
                                 O_ERROR - erro
        
          CRIAÇÃO: ASM 2007/01/09
        
          NOTAS: LG 2007 Mar 28 Conjuga os estados com a acção de realização/cancelamento da efectivação para o private practice
        *********************************************************************************/
    
        l_episode_registry  sys_config.value%TYPE;
        l_schd_interv_state schedule_intervention.flg_state%TYPE := NULL;
    
    BEGIN
        g_error            := 'GET SYS_CONFIG DOCTOR_EPISODE_REGISTRY';
        l_episode_registry := pk_sysconfig.get_config('FISIO_EPISODE_REGISTRY', i_prof);
        IF (l_episode_registry = 'Y')
        THEN
            g_error := 'CALC EPISODE CURRENT STATUS';
            SELECT DISTINCT so.flg_state
              INTO l_schd_interv_state
              FROM schedule s
              JOIN schedule_intervention so
                ON so.id_schedule = s.id_schedule
             WHERE s.id_schedule = i_id_schedule;
        END IF;
        --Obtem os estados possíveis de um paciente
        g_error := 'GET PAT STATUS CURSOR';
        OPEN o_status FOR
            SELECT decode(l_episode_registry,
                          'Y',
                          decode(sd.val,
                                 g_sched_scheduled,
                                 decode(l_schd_interv_state,
                                        g_sched_efectiv,
                                        pk_sysdomain.get_domain(g_schdl_outp_state_act_domain, sd.val, i_lang),
                                        sd.desc_val),
                                 g_sched_efectiv,
                                 decode(l_schd_interv_state,
                                        g_sched_scheduled,
                                        pk_sysdomain.get_domain(g_schdl_outp_state_act_domain, sd.val, i_lang),
                                        sd.desc_val),
                                 sd.desc_val),
                          sd.desc_val) label,
                   --lg conjuga estado com a realização/cancelamento de efectivação sd.desc_val LABEL,
                   sd.val      data,
                   sd.img_name icon,
                   -- lg flg_action tells if an action shoud be available in the current state.
                   decode(l_episode_registry,
                          'Y',
                          decode(sd.val,
                                 g_sched_scheduled,
                                 decode(l_schd_interv_state, g_sched_efectiv, 'Y', 'N'),
                                 g_sched_efectiv,
                                 decode(l_schd_interv_state, g_sched_scheduled, 'Y', 'N'),
                                 'N'),
                          'N') flg_action
              FROM sys_domain sd
             WHERE sd.code_domain = g_schdl_interv_state_domain
               AND sd.id_language = i_lang
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.val IN (g_sched_scheduled, g_sched_efectiv, g_sched_cons, g_sched_adm_disch)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_owner,
                                   g_package,
                                   'GET_PAT_STATUS_LIST_SESSION');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_status);
                RETURN FALSE;
            
            END;
    END;

    FUNCTION get_schedule_real_state
    (
        flg_state IN schedule_outp.flg_state%TYPE,
        flg_ehr   IN episode.flg_ehr%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        IF flg_ehr = pk_visit.g_flg_ehr_s
           AND flg_state <> g_flg_no_show
        --OR flg_ehr IS NULL revert change done in ALERT-92963
        THEN
            RETURN g_sched_scheduled;
        ELSE
            RETURN flg_state;
        END IF;
    END;

    FUNCTION get_pat_nurse_status_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN VARCHAR2,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_pat_nurse_status_list_int(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_id_schedule    => i_id_schedule,
                                             i_enable_actions => pk_alert_constant.g_yes,
                                             o_status         => o_status,
                                             o_error          => o_error);
    END get_pat_nurse_status_list;

    /**
    * Get data for multichoice on patient grids.
    * No option is selectable.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_schedule  schedule identifier
    * @param o_status       cursor 
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.0.7.8
    * @since                2010/04/19
    */
    FUNCTION get_pat_nurse_status_list_na
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN get_pat_nurse_status_list_int(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_id_schedule    => i_id_schedule,
                                             i_enable_actions => pk_alert_constant.g_no,
                                             o_status         => o_status,
                                             o_error          => o_error);
    END get_pat_nurse_status_list_na;

    /**
     * This function is supposed to be used to show the detail of a 
     * notification.
     *
     * @param      i_lang
     * @param      i_prof
     * @param      i_dt
     * @param      i_interv_presc_det
     * @param      i_id_rep_mfr_notification
     * @param      i_flg_type
     * @param      o_visit_name
     * @param      o_date_target
     * @param      o_hour_target
     * @param      o_nick_name
     * @param      o_screen_title
     * @param      o_notification
     * @param      o_notification_labels
     * @param      o_notification_session
     * @param      o_not_session_labels
     *    
     * @author     Thiago Brito
     * @version    1.0
     * @since      2008-Sep-02
    */
    FUNCTION get_notification_mfr_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_dt               IN VARCHAR2,
        i_interv_presc_det IN interv_presc_det.id_interv_presc_det%TYPE,
        --i_id_rep_mfr_notification IN rep_mfr_notification.id_rep_mfr_notification%TYPE,
        i_flg_type             IN VARCHAR2,
        o_visit_name           OUT VARCHAR2,
        o_date_target          OUT VARCHAR2,
        o_hour_target          OUT VARCHAR2,
        o_nick_name            OUT professional.nick_name%TYPE,
        o_screen_title         OUT pk_translation.t_desc_translation,
        o_notification         OUT pk_types.cursor_type,
        o_notification_labels  OUT pk_types.cursor_type,
        o_notification_session OUT pk_types.cursor_type,
        o_not_session_labels   OUT pk_types.cursor_type
    ) RETURN BOOLEAN IS
    
        -- internal variables
        iv_id_episode       episode.id_episode%TYPE;
        iv_id_prof_assigned professional.id_professional%TYPE;
        iv_dt_begin_tstz    schedule.dt_begin_tstz%TYPE;
        iv_dt_begin         TIMESTAMP WITH LOCAL TIME ZONE;
        iv_dt_end           TIMESTAMP WITH LOCAL TIME ZONE;
        dt_rep_notification table_varchar;
        ret                 VARCHAR2(4000);
    
        i_total_notified_sessions VARCHAR2(2000);
        i_dt_begin                VARCHAR2(2000);
        i_notified_sessions       VARCHAR2(2000);
        i_notification            VARCHAR2(2000);
        i_nick_name               VARCHAR2(2000);
    
    BEGIN
        g_error := 'step 1';
    
        g_sysdate_tstz := current_timestamp;
    
        iv_dt_begin := pk_date_utils.trunc_insttimezone(i_prof,
                                                        nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                            g_sysdate_tstz));
    
        iv_dt_end := pk_date_utils.add_days_to_tstz(iv_dt_begin, 1);
    
        o_screen_title := pk_message.get_message(1, 'PROCEDURES_MFR_T160');
    
        -- We are going to get the id_episode
        g_error := 'step 2';
        BEGIN
        
            SELECT s.id_episode, s.dt_begin_tstz
              INTO iv_id_episode, iv_dt_begin_tstz
              FROM schedule s
             WHERE s.id_schedule = (SELECT id_schedule
                                      FROM schedule_intervention
                                     WHERE id_schedule_intervention =
                                           (SELECT MAX(id_schedule_intervention) id_schedule_intervention
                                              FROM schedule_intervention si
                                             WHERE si.flg_state NOT IN ('C', 'F')
                                               AND id_interv_presc_det = i_interv_presc_det));
        
        EXCEPTION
        
            WHEN OTHERS THEN
                iv_id_episode    := NULL;
                iv_dt_begin_tstz := NULL;
                dbms_output.put_line(SQLERRM);
            
        END;
    
        g_error := 'step 3';
        SELECT dt, hr
          INTO o_date_target, o_hour_target
          FROM (SELECT pk_date_utils.dt_chr_tsz(i_lang, rep.dt_rep_mfr_notification, i_prof) dt,
                       pk_date_utils.dt_chr_hour_tsz(i_lang, rep.dt_rep_mfr_notification, i_prof) hr
                  FROM rep_mfr_notification rep
                 WHERE rep.id_interv_presc_det = i_interv_presc_det
                 ORDER BY rep.dt_rep_mfr_notification)
         WHERE rownum < 2;
    
        -- We are going to get the type of the visit
        o_visit_name := pk_ehr_common.get_visit_name_by_epis(i_lang, i_prof, iv_id_episode);
        -- dbms_output.put_line('o_visit_name := ' || o_visit_name);
    
        -- We are going to get the name of the professional
        g_error := 'step 4';
        BEGIN
        
            SELECT id_prof_assigned
              INTO iv_id_prof_assigned
              FROM schedule_intervention
             WHERE id_schedule_intervention =
                   (SELECT MAX(id_schedule_intervention) id_schedule_intervention
                      FROM schedule_intervention si
                     WHERE id_interv_presc_det = i_interv_presc_det);
        
        EXCEPTION
        
            WHEN OTHERS THEN
                dbms_output.put_line(SQLERRM);
                iv_id_prof_assigned := NULL;
            
        END;
    
        o_nick_name := pk_prof_utils.get_nickname(i_lang, iv_id_prof_assigned);
        -- dbms_output.put_line('o_nick_name := ' || o_nick_name);
    
        g_error := 'g_error := o_notification';
        OPEN o_notification FOR
            SELECT DISTINCT pk_procedures_api_db.get_alias_translation(i_lang,
                                                                       i_prof,
                                                                       'INTERVENTION.CODE_INTERVENTION.' ||
                                                                       ipd.id_intervention,
                                                                       NULL) "PROCEDURE",
                            pk_interv_mfr.get_physiatry_area(i_lang, ipd.id_intervention) area,
                            decode(ipd.num_freq,
                                   NULL,
                                   NULL,
                                   ipd.num_freq || ' ' ||
                                   decode(ipd.num_freq,
                                          1,
                                          pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_M060'),
                                          pk_message.get_message(i_lang, i_prof, 'PROCEDURES_MFR_M061')) || ' ' ||
                                   pk_sysdomain.get_domain('INTERV_PRESC_DET.FLG_FREQ', ipd.flg_freq, i_lang) || ', ') frequence,
                            decode(ipd.num_take,
                                   NULL,
                                   NULL,
                                   ipd.num_take || ' ' ||
                                   decode(ipd.num_take,
                                          1,
                                          pk_message.get_message(i_lang, 'PROCEDURES_MFR_T065'),
                                          pk_message.get_message(i_lang, 'PROCEDURES_MFR_T066'))) session_number,
                            pk_prof_utils.get_nickname(i_lang, si.id_prof_assigned) nick_name
              FROM interv_presc_det ipd, interv_dep_clin_serv idcs, schedule s, schedule_intervention si
             WHERE si.id_interv_presc_det = ipd.id_interv_presc_det
               AND si.id_schedule_intervention =
                   (SELECT MAX(id_schedule_intervention)
                      FROM schedule_intervention si1
                     WHERE si1.id_interv_presc_det = ipd.id_interv_presc_det)
               AND si.id_schedule = s.id_schedule
               AND (s.flg_notification IS NULL OR s.flg_notification = g_flg_notification_p OR
                   (s.flg_notification = g_flg_notification_n AND s.dt_notification_tstz BETWEEN iv_dt_begin AND
                   iv_dt_end))
               AND (si.id_prof_assigned = i_prof.id OR
                   (si.id_prof_assigned != i_prof.id AND i_flg_type IN (g_cat_type_a, g_cat_type_c)))
               AND s.flg_status != g_sched_canc
               AND idcs.id_dep_clin_serv IN (SELECT pdcs.id_dep_clin_serv
                                               FROM prof_dep_clin_serv pdcs
                                              WHERE pdcs.id_professional = i_prof.id
                                                AND pdcs.flg_status = g_selected
                                                AND pdcs.id_institution = i_prof.institution)
               AND idcs.id_intervention = ipd.id_intervention
               AND ipd.id_interv_presc_det = i_interv_presc_det;
    
        g_error := 'g_error := o_notification_labels';
        OPEN o_notification_labels FOR
            SELECT sm.code_message code, sm.desc_message label
              FROM sys_message sm
             WHERE sm.id_language = i_lang
               AND sm.code_message IN ('PROCEDURES_MFR_M050',
                                       'PROCEDURES_MFR_M051',
                                       'PROCEDURES_MFR_M052',
                                       'PROCEDURES_MFR_M053',
                                       'PROCEDURES_MFR_M054')
             ORDER BY sm.code_message;
    
        -- We are going to get the number of notified session
        g_error := 'g_error := i_total_notified_sessions';
        SELECT COUNT(1)
          INTO i_total_notified_sessions
          FROM rep_mfr_notification rmn, interv_presc_det ipd, schedule_intervention si, schedule s
         WHERE ipd.id_interv_presc_det = rmn.id_interv_presc_det
           AND ipd.id_interv_presc_det = si.id_interv_presc_det
           AND s.id_schedule = si.id_schedule
           AND s.flg_status NOT IN ('T', 'C', 'D')
           AND s.flg_notification IN ('N', 'C')
           AND ipd.id_interv_presc_det = i_interv_presc_det;
    
        -- We are going to get the start date
        g_error := 'g_error := i_dt_begin';
        BEGIN
            SELECT MIN(pk_date_utils.dt_chr_date_hour_tsz(i_lang, s.dt_begin_tstz, i_prof)) total_notified_sessions
              INTO i_dt_begin
              FROM schedule s,
                   schedule_intervention si,
                   interv_presc_det ipd,
                   (SELECT si.id_schedule_intervention
                      FROM schedule_intervention si, schedule s
                     WHERE s.id_schedule = si.id_schedule
                       AND si.id_interv_presc_det = i_interv_presc_det) lsi
             WHERE ipd.id_interv_presc_det = si.id_interv_presc_det
               AND s.id_schedule = si.id_schedule
               AND si.id_schedule_intervention = CAST(lsi.id_schedule_intervention AS NUMBER);
        EXCEPTION
            WHEN OTHERS THEN
                alertlog.pk_alertlog.log_warn(pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                              'PK_GRID.GET_NOTIFICATION_MFR_DETAIL / ' || '/' || g_error || ' / ' ||
                                              SQLERRM);
        END;
    
        -- We are going to get the dates of all notifications
        g_error := 'g_error := dt_rep_notification';
        BEGIN
            SELECT s.dt_begin_tstz
              BULK COLLECT
              INTO dt_rep_notification
              FROM schedule s,
                   schedule_intervention si,
                   interv_presc_det ipd,
                   (SELECT si.id_schedule_intervention
                      FROM schedule_intervention si, schedule s
                     WHERE s.id_schedule = si.id_schedule
                       AND si.id_interv_presc_det = i_interv_presc_det) lsi
             WHERE ipd.id_interv_presc_det = si.id_interv_presc_det
               AND s.id_schedule = si.id_schedule
               AND s.flg_notification IN ('N', 'C')
               AND s.flg_status != 'T'
               AND si.id_schedule_intervention = lsi.id_schedule_intervention;
        
            g_error := 'g_error := before for';
            IF (dt_rep_notification.count > 0)
            THEN
                ret                 := '';
                i_notified_sessions := '';
            
                FOR i IN dt_rep_notification.first .. dt_rep_notification.last
                LOOP
                    ret := ret || '; ' || pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_rep_notification(i), i_prof);
                END LOOP;
            
                IF (length(ret) > 0)
                THEN
                    i_notified_sessions := ltrim(ret, '; ');
                END IF;
            
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                alertlog.pk_alertlog.log_warn(pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                              'PK_GRID.GET_NOTIFICATION_MFR_DETAIL / ' || '/' || g_error || ' / ' ||
                                              SQLERRM);
        END;
    
        -- We are going to get the type of the notification
        g_error := 'g_error := i_notification';
        BEGIN
            SELECT desc_val
              INTO i_notification
              FROM sys_domain sd
             WHERE sd.code_domain = 'REP_MFR_NOTIFICATION.FLG_NOTIFICATION_VIA'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.val = (SELECT rmn.flg_notification_via
                               FROM rep_mfr_notification rmn
                              WHERE rmn.id_interv_presc_det = i_interv_presc_det
                                AND rmn.flg_notification_via IS NOT NULL
                                AND rownum = 1)
               AND sd.id_language = i_lang;
        EXCEPTION
            WHEN OTHERS THEN
                alertlog.pk_alertlog.log_warn(pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                              'PK_GRID.GET_NOTIFICATION_MFR_DETAIL / ' || '/' || g_error || ' / ' ||
                                              SQLERRM);
        END;
    
        -- We are going to get the name of the professinal responsible for the notification
        g_error := 'g_error := i_nick_name';
        BEGIN
            SELECT rtrim(pk_prof_utils.get_nickname(i_lang, s.id_prof_schedules), ', ') || '; ' ||
                   pk_date_utils.dt_chr_hour_tsz(i_lang,
                                                 (SELECT MAX(rmn.dt_rep_mfr_notification)
                                                    FROM rep_mfr_notification rmn
                                                   WHERE rmn.id_interv_presc_det = i_interv_presc_det),
                                                 i_prof) || ' / ' ||
                   pk_date_utils.dt_chr_tsz(i_lang,
                                            (SELECT MAX(rmn.dt_rep_mfr_notification)
                                               FROM rep_mfr_notification rmn
                                              WHERE rmn.id_interv_presc_det = i_interv_presc_det),
                                            i_prof) nick_name
              INTO i_nick_name
              FROM schedule s,
                   schedule_intervention si,
                   interv_presc_det ipd,
                   (SELECT si.id_schedule_intervention
                      FROM schedule_intervention si, schedule s
                     WHERE s.id_schedule = si.id_schedule
                       AND si.id_interv_presc_det = i_interv_presc_det) lsi
             WHERE ipd.id_interv_presc_det = si.id_interv_presc_det
               AND s.id_schedule = si.id_schedule
               AND si.id_schedule_intervention = CAST(lsi.id_schedule_intervention AS NUMBER)
               AND rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                alertlog.pk_alertlog.log_warn(pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                              'PK_GRID.GET_NOTIFICATION_MFR_DETAIL / ' || '/' || g_error || ' / ' ||
                                              SQLERRM);
        END;
    
        g_error := 'g_error := o_notification_session';
        OPEN o_notification_session FOR
            SELECT i_total_notified_sessions AS total_notified_sessions,
                   i_dt_begin                AS dt_begin,
                   i_notified_sessions       AS notified_sessions,
                   i_notification            AS notification,
                   i_nick_name               AS nick_name
              FROM dual;
    
        g_error := 'g_error := o_not_session_labels';
        OPEN o_not_session_labels FOR
            SELECT sm.code_message code, sm.desc_message label
              FROM sys_message sm
             WHERE sm.id_language = i_lang
               AND sm.code_message IN ('PROCEDURES_MFR_M055',
                                       'PROCEDURES_MFR_M056',
                                       'PROCEDURES_MFR_M057',
                                       'PROCEDURES_MFR_M058',
                                       'PROCEDURES_MFR_M059')
             ORDER BY sm.code_message;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
            -- dbms_output.put_line(SQLERRM);
            alertlog.pk_alertlog.log_warn(pk_message.get_message(i_lang, 'COMMON_M001') || chr(10) ||
                                          'PK_GRID.GET_NOTIFICATION_MFR_DETAIL / ' || '/' || g_error || ' / ' ||
                                          SQLERRM);
            pk_types.open_my_cursor(o_notification);
            pk_types.open_my_cursor(o_notification_labels);
            pk_types.open_my_cursor(o_notification_session);
            pk_types.open_my_cursor(o_not_session_labels);
            RETURN FALSE;
        
    END;

    /************************************************************************************************************ 
    * Grelha do enfermeiro detalhe dos cancelamentos das consultas de enfermagem    
    *
    * @param      i_lang           language
    * @param      i_prof           professional
    * @param      i_schedule       id do agendamento
    *    
    * @author     Teresa Coutinho
    * @version    0.1
    * @since      2008/12/21
    ***********************************************************************************************************/

    FUNCTION nurse_appointment_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_schedule      IN schedule.id_schedule%TYPE,
        o_cancel        OUT pk_types.cursor_type,
        o_cancel_detail OUT pk_types.cursor_type,
        o_det_title     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- title
        o_det_title := pk_message.get_message(i_lang, 'GRID_NURSE_T011');
    
        OPEN o_cancel FOR
            SELECT pk_message.get_message(i_lang, 'GRID_NURSE_T012') label_canc,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_cancel_tstz, i_prof.institution, i_prof.software) || '; ' ||
                   pk_date_utils.dt_chr_tsz(i_lang, s.dt_cancel_tstz, i_prof.institution, i_prof.software) hour_date,
                   p.nick_name name
              FROM schedule s, professional p
             WHERE s.id_schedule = i_schedule
               AND s.id_prof_cancel = p.id_professional;
    
        OPEN o_cancel_detail FOR
            SELECT pk_message.get_message(i_lang, 'GRID_NURSE_T013') || ': ' label_name,
                   pk_patient.get_pat_name(i_lang, i_prof, pat.id_patient, NULL, s.id_schedule) || ';' ||
                   (SELECT DISTINCT cr.num_clin_record
                      FROM clin_record cr
                     WHERE cr.id_patient = pat.id_patient
                       AND rownum = 1) name,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, pat.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, pat.id_patient) pat_nd_icon,
                   pk_message.get_message(i_lang, 'GRID_NURSE_T014') || ': ' label_nick_name,
                   p.nick_name nick_name,
                   pk_message.get_message(i_lang, 'GRID_NURSE_T015') || ': ' label_event_type,
                   pk_schedule_common.get_translation_alias(i_lang, i_prof, se.id_sch_event, se.code_sch_event) event_type,
                   pk_message.get_message(i_lang, 'GRID_NURSE_T016') || ': ' label_dt_begin,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_cancel_tstz, i_prof.institution, i_prof.software) dt_begin,
                   pk_message.get_message(i_lang, 'GRID_NURSE_T017') || ': ' label_status,
                   sd.desc_val status,
                   pk_message.get_message(i_lang, 'GRID_NURSE_T018') || ': ' label_cancel_notes,
                   pk_translation.get_translation(i_lang, scr.code_cancel_reason) ||
                   decode(s.schedule_cancel_notes, NULL, ' ', '; ' || s.schedule_cancel_notes) cancel_notes
              FROM schedule          s,
                   sch_group         sg,
                   professional      p,
                   patient           pat,
                   sys_domain        sd,
                   sch_event         se,
                   sch_cancel_reason scr
             WHERE s.id_prof_cancel = p.id_professional
               AND s.id_schedule = sg.id_schedule
               AND sg.id_patient = pat.id_patient
               AND se.id_sch_event = s.id_sch_event
               AND s.id_cancel_reason = scr.id_sch_cancel_reason
               AND s.flg_status = sd.val
               AND sd.code_domain(+) = 'SCHEDULE.FLG_STATUS'
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
               AND s.id_schedule = i_schedule
               AND s.flg_status != pk_schedule.g_sched_status_cache; -- agendamentos temporários (SCH 3.0)
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, g_owner, g_package, 'NURSE_APPOINTMENT_DET');
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                pk_types.open_my_cursor(o_cancel);
                pk_types.open_my_cursor(o_cancel_detail);
                RETURN FALSE;
            
            END;
        
    END;

    /**********************************************************************************************
    * Change the schedule_outp flg_state 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_from_state             Original state
    * @param i_to_state               Final state
    *
    * @return                         True
    *
    * @author                         Rita Lopes
    * @version                        1.0 
    * @since                          2009/02/05
    * @alteration                     
    **********************************************************************************************/
    FUNCTION set_state_change
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis        IN episode.id_episode%TYPE,
        i_pat         IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_from_state  IN schedule_outp.flg_state%TYPE,
        i_to_state    IN schedule_outp.flg_state%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'CALL set_state_change_nc';
        IF NOT set_state_change_nc(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_epis        => i_epis,
                                   i_pat         => i_pat,
                                   i_id_schedule => i_id_schedule,
                                   i_from_state  => i_from_state,
                                   i_to_state    => i_to_state,
                                   o_error       => o_error)
        THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_GRID', 'SET_STATE_SCHANGE');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;
    /**********************************************************************************************
    * Change the schedule_outp flg_state 
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_from_state             Original state
    * @param i_to_state               Final state
    *
    * @return                         True
    *
    * @author                         Rita Lopes
    * @version                        1.0 
    * @since                          2009/02/05
    * @alteration                     
    **********************************************************************************************/
    FUNCTION set_state_change_nc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_epis        IN episode.id_episode%TYPE,
        i_pat         IN patient.id_patient%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_from_state  IN schedule_outp.flg_state%TYPE,
        i_to_state    IN schedule_outp.flg_state%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_bool BOOLEAN;
    
    BEGIN
    
        g_error := 'UPDATE SCHEDULE_OUTP';
        UPDATE schedule_outp
           SET flg_state = i_to_state
         WHERE id_schedule = i_id_schedule;
    
        l_bool := i_from_state = 'E' AND i_to_state = 'A';
        IF l_bool
        THEN
            UPDATE episode x
               SET x.flg_ehr = 'S'
             WHERE id_episode = i_epis;
        
            -- Limpar sala?
            UPDATE epis_info
               SET id_room = NULL, id_bed = NULL
             WHERE id_episode = i_epis;
        
            pk_ia_event_common.episode_register_cancel(i_id_institution => i_prof.institution, i_id_episode => i_epis);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
            
                l_ret BOOLEAN;
            BEGIN
            
                -- setting package information into object 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_GRID', 'SET_STATE_SCHANGE_NC');
            
                -- undo changes quando aplicável-> só faz ROLLBACK 
                pk_utils.undo_changes;
            
                -- execute error processing 
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
                RETURN FALSE;
            
            END;
    END;

    /**
    * Gets outpatient schedule flg_state info.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_FLG_STATUS  schedule status
    * @param   I_ID_SCHEDULE id schedule
    * @param   O_STATUS the cursur with the domains info
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Rita Lopes
    * @version 1.0
    * @since   16-12-2009
    */
    FUNCTION get_reg_sched_state_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN VARCHAR2,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_status      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_exists_discharge IS
            SELECT d.dt_med_tstz
              FROM discharge d
             WHERE d.id_episode = (SELECT id_episode
                                     FROM epis_info ei
                                    WHERE ei.id_schedule = i_id_schedule)
               AND d.flg_status = g_discharge_active;
        r_exists_discharge c_exists_discharge%ROWTYPE;
    
        l_episode_registry   sys_config.value%TYPE;
        l_schd_outp_state    episode.flg_status%TYPE;
        l_exists_discharge   VARCHAR2(1);
        l_is_contact         VARCHAR2(1 CHAR);
        l_id_patient         patient.id_patient%TYPE;
        l_can_cancel         VARCHAR2(1 CHAR);
        l_epis_status        episode.flg_status%TYPE;
        l_flg_ehr            episode.flg_ehr%TYPE;
        l_inactivate_options episode.flg_status%TYPE := pk_alert_constant.g_no;
    BEGIN
    
        g_error            := 'GET SYS_CONFIG DOCTOR_EPISODE_REGISTRY';
        l_episode_registry := pk_sysconfig.get_config('REGISTER_EPISODE_REGISTRY', i_prof);
        l_can_cancel       := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                                    i_prof        => i_prof,
                                                                    i_intern_name => 'CANCEL_EPISODE');
    
        g_error := 'CALC EPISODE CURRENT STATUS';
        SELECT decode(s.flg_status, g_sched_canc, g_sched_canc, get_schedule_real_state(so.flg_state, e.flg_ehr)),
               e.flg_status,
               e.flg_ehr
          INTO l_schd_outp_state, l_epis_status, l_flg_ehr
          FROM schedule_outp so
          LEFT JOIN epis_info ei
            ON so.id_schedule = ei.id_schedule
          LEFT JOIN episode e
            ON ei.id_episode = e.id_episode
          LEFT JOIN schedule s
            ON s.id_schedule = so.id_schedule
         WHERE so.id_schedule = i_id_schedule;
    
        IF l_epis_status = pk_alert_constant.g_inactive
           AND l_flg_ehr = pk_visit.g_flg_ehr_s
        THEN
            l_inactivate_options := pk_alert_constant.g_yes;
        END IF;
    
        OPEN c_exists_discharge;
        FETCH c_exists_discharge
            INTO r_exists_discharge;
        IF c_exists_discharge%FOUND
        THEN
            l_exists_discharge := 'Y';
        END IF;
        CLOSE c_exists_discharge;
        BEGIN
            SELECT sg.id_patient
              INTO l_id_patient
              FROM sch_group sg
             WHERE sg.id_schedule = i_id_schedule;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_id_patient := -1;
        END;
    
        l_is_contact := pk_adt.is_contact(i_lang => i_lang, i_prof => i_prof, i_patient => l_id_patient);
        OPEN o_status FOR
            SELECT decode(l_schd_outp_state,
                          g_sched_canc,
                          pk_sysdomain.get_domain('SCHEDULE.FLG_STATUS', sd.val, i_lang),
                          sd.desc_val) label,
                   sd.val data,
                   sd.img_name icon,
                   decode(l_inactivate_options,
                          pk_alert_constant.g_yes,
                          pk_alert_constant.g_no,
                          decode(l_episode_registry,
                                 pk_alert_constant.g_yes,
                                 decode(sd.val,
                                        g_sched_scheduled,
                                        
                                        decode(l_schd_outp_state,
                                               g_sched_efectiv,
                                               pk_alert_constant.g_yes,
                                               g_sched_ortopt,
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
                                        g_flg_no_show,
                                        decode(l_schd_outp_state,
                                               g_sched_scheduled,
                                               pk_alert_constant.g_yes,
                                               pk_alert_constant.g_no),
                                        pk_alert_constant.g_no),
                                 pk_alert_constant.g_no)) flg_action
              FROM sys_domain sd
             WHERE sd.code_domain = g_schdl_outp_state_act_domain
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_REG_SCHED_STATE_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
        
    END get_reg_sched_state_list;

    /**********************************************************************************************
    * GET_GRID_PAT_CONFIRM            Returns the patients grid for a given date [and professional, according to flg_prof]
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             table_number of Episode identifier
    * @param o_grid                   Grid information for confirmation screen
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         Luís Maia
    * @version                        2.6.0.3
    * @since                          2010/06/04
    * @alteration                     
    **********************************************************************************************/
    FUNCTION get_grid_pat_confirm
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN table_number,
        o_grid       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_GRID';
        OPEN o_grid FOR
            SELECT gea.id_episode,
                   gea.id_visit,
                   gea.id_patient,
                   gea.id_epis_type,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, gea.id_patient, gea.id_episode, NULL) photo,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', pat.gender, i_lang) gender,
                   pk_patient.get_pat_age(i_lang, gea.id_patient, i_prof) pat_age,
                   pk_patient.get_pat_name(i_lang, i_prof, gea.id_patient, gea.id_episode) name_pat,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, gea.id_patient, gea.id_episode) name_pat_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, gea.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, gea.id_patient) pat_nd_icon,
                   b.id_bed,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) code_bed,
                   r.id_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) code_room,
                   dep.id_department,
                   pk_translation.get_translation(i_lang, dep.code_department) code_deartment
              FROM grids_ea gea
             INNER JOIN patient pat
                ON (pat.id_patient = gea.id_patient)
              LEFT JOIN bed b
                ON (b.id_bed = gea.id_bed)
              LEFT JOIN room r
                ON (r.id_room = b.id_room)
              LEFT JOIN department dep
                ON (dep.id_department = r.id_department)
             WHERE gea.id_episode IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                       t.column_value
                                        FROM TABLE(i_id_episode) t);
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_GRID_PAT_CONFIRM',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_grid_pat_confirm;
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
        l_dt_begin         TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end           TIMESTAMP WITH LOCAL TIME ZONE;
        l_num_days_back    sys_config.value%TYPE;
        l_num_days_forward sys_config.value%TYPE;
        l_dt_current       VARCHAR2(200);
        l_show_nurse_disch sys_config.value%TYPE := nvl(pk_sysconfig.get_config('SHOW_NURSE_DISCHARGED_GRID', i_prof),
                                                        g_no);
    
    BEGIN
        g_sysdate_tstz    := current_timestamp;
        l_dt_current      := pk_date_utils.date_send_tsz(i_lang,
                                                         pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                                         i_prof);
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
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
              FROM ((SELECT pk_grid_amb.get_extense_day_desc(i_lang,
                                                              pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)) date_desc,
                             pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof) date_tstz
                        FROM (SELECT pk_date_utils.trunc_insttimezone(i_prof, na.dt_target_tstz) AS sp_date,
                                     na.dt_target_tstz
                                FROM (SELECT sp.dt_target_tstz,
                                             decode(gtb.flg_drug,
                                                    'Y',
                                                    pk_grid.exist_prescription(i_lang, i_prof, epis.id_episode, 'D'),
                                                    NULL) drug_presc_gtb,
                                             decode(gtb.flg_interv,
                                                    'Y',
                                                    pk_grid.exist_prescription(i_lang, i_prof, epis.id_episode, 'I'),
                                                    NULL) interv_presc_gtb,
                                             decode(gtb.flg_monitor,
                                                    'Y',
                                                    pk_grid.exist_prescription(i_lang, i_prof, epis.id_episode, 'M'),
                                                    NULL) monit_gtb,
                                             decode(gtb.flg_nurse_act,
                                                    'Y',
                                                    pk_grid.exist_prescription(i_lang, i_prof, epis.id_episode, 'N'),
                                                    NULL) nurse_act_gtb,
                                             decode(gtb.flg_pharm,
                                                    'Y',
                                                    pk_grid.exist_prescription(i_lang, i_prof, epis.id_episode, 'P'),
                                                    NULL) drug_req_gtb,
                                             decode(gtb.flg_vaccine,
                                                    'Y',
                                                    pk_grid.exist_prescription(i_lang, i_prof, epis.id_episode, 'V'),
                                                    NULL) vaccine_presc_gtb
                                        FROM schedule_outp sp
                                        JOIN schedule s
                                          ON s.id_schedule = sp.id_schedule
                                        LEFT JOIN sch_prof_outp ps
                                          ON ps.id_schedule_outp = sp.id_schedule_outp
                                        LEFT JOIN professional p
                                          ON ps.id_professional = p.id_professional
                                        JOIN sch_group sg
                                          ON sg.id_schedule = sp.id_schedule
                                        JOIN patient pat
                                          ON pat.id_patient = sg.id_patient
                                        LEFT JOIN epis_info ei
                                          ON ei.id_schedule = s.id_schedule
                                        LEFT JOIN professional p1
                                          ON ei.id_first_nurse_resp = p1.id_professional
                                        LEFT JOIN episode epis
                                          ON epis.id_episode = ei.id_episode
                                        JOIN prof_dep_clin_serv pdcs
                                          ON pdcs.id_dep_clin_serv = s.id_dcs_requested
                                        LEFT JOIN discharge d
                                          ON d.id_episode = epis.id_episode -- episódios c/ alta
                                        LEFT JOIN grid_task gt
                                          ON gt.id_episode = epis.id_episode
                                        LEFT JOIN grid_task_between gtb
                                          ON gtb.id_episode = epis.id_episode
                                        LEFT JOIN room ro
                                          ON ro.id_room = ei.id_room
                                       WHERE sp.id_software = i_prof.software
                                         AND sp.id_epis_type = g_epis_type_nurse
                                            -- fim de contacto de enfermagem
                                         AND (get_schedule_real_state(sp.flg_state, epis.flg_ehr) != g_sched_nurse_disch OR
                                             l_show_nurse_disch = g_yes)
                                            -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
                                         AND (epis.flg_ehr IS NULL OR epis.flg_ehr != g_flg_ehr)
                                         AND s.id_instit_requested = i_prof.institution
                                         AND (epis.flg_status IS NULL OR epis.flg_status != g_epis_canc)
                                         AND pdcs.id_professional = i_prof.id
                                         AND pdcs.flg_status = g_selected
                                         AND d.dt_cancel_tstz IS NULL -- alta ñ cancelada
                                         AND (s.dt_cancel_tstz IS NULL OR s.dt_cancel_tstz BETWEEN l_dt_begin AND l_dt_end)) na
                               WHERE na.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                                  OR ((na.drug_presc_gtb IS NOT NULL OR na.interv_presc_gtb IS NOT NULL OR
                                     na.monit_gtb IS NOT NULL OR na.nurse_act_gtb IS NOT NULL OR
                                     na.drug_req_gtb IS NOT NULL OR na.vaccine_presc_gtb IS NOT NULL)))
                       GROUP BY pk_grid_amb.get_extense_day_desc(i_lang,
                                                                 pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)),
                                pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)) --
                     UNION -- union with current date in case there's no appoitment for today
                    (SELECT pk_grid_amb.get_extense_day_desc(i_lang,
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
                                              g_owner,
                                              g_package,
                                              'NURSE_APPOINTMENT_DATES',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
    END nurse_appointment_dates;

    /**********************************************************************************************
    * DELETE_DRUG_PRESC_FIELD         Forces the deletion of DRUG_PRESC field from GRID_TASK
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             table_number of Episode identifier
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author                         Pedro Teixeira
    * @version                        2.6.2
    * @since                          15/02/2012
    * @alteration                     
    **********************************************************************************************/
    FUNCTION delete_drug_presc_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'UPDATE GRID_TASK DRUG_PRESC';
        UPDATE grid_task gt
           SET gt.drug_presc = NULL
         WHERE gt.id_episode = i_id_episode;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'DELETE_DRUG_PRESC_FIELD',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END delete_drug_presc_field;

    /********************************************************************************************
    * Converts the status string dates timezone
    *
    * @param  I_LANG                                  IN        NUMBER(22,6)
    * @param  I_PROF                                  IN        PROFISSIONAL
    * @param  I_STR                                   IN        VARCHAR2
    *
    * @return  VARCHAR2
    *
    * @author      Alexis Nascimento
    * @version     v2.6.4.2.2
    * @since       05/11/2014
    *
    ********************************************************************************************/

    FUNCTION convert_grid_task_dates_to_str
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_str  IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_string_status VARCHAR2(1000 CHAR);
        l_str_date1     VARCHAR2(1000 CHAR);
        l_str_date2     VARCHAR2(1000 CHAR);
        l_array         table_varchar := table_varchar();
        l_max           NUMBER(24) := 2;
    
    BEGIN
    
        l_array := pk_utils.str_split_l(i_str, '|');
    
        -- Validating if position exists. Value can be null
        IF l_array.exists(g_gt_date_pos(1))
        THEN
            l_str_date1 := l_array(g_gt_date_pos(1));
        END IF;
    
        -- Validating if position exists. Value can be null
        IF l_array.exists(g_gt_date_pos(2))
        THEN
            l_str_date2 := l_array(g_gt_date_pos(2));
        END IF;
    
        IF l_str_date1 = l_str_date2
        THEN
            l_max := 1;
        END IF;
    
        l_string_status := i_str;
    
        FOR i IN 1 .. l_max
        LOOP
            l_string_status := convert_grid_task_str(i_lang     => i_lang,
                                                     i_prof     => i_prof,
                                                     i_str      => l_string_status,
                                                     i_position => g_gt_date_pos(i));
        END LOOP;
    
        RETURN l_string_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_sql VARCHAR2(4000);
            BEGIN
                l_sql := 'DT1:' || l_str_date1 || ' - DT2:' || l_str_date2 || ' - ' || SQLERRM;
                pk_alertlog.log_error(l_sql);
            END;
            RETURN NULL;
    END convert_grid_task_dates_to_str;

    /**********************************************************************************************
    * DELETE_DRUG_REQ_FIELD         Forces the deletion of DRUG_REQ field from GRID_TASK
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             table_number of Episode identifier
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author          Pedro Teixeira
    * @since           05/01/2018
    **********************************************************************************************/
    FUNCTION delete_drug_req_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'UPDATE GRID_TASK DRUG_PRESC';
        UPDATE grid_task gt
           SET gt.drug_req = NULL
         WHERE gt.id_episode = i_id_episode;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'DELETE_DRUG_REQ_FIELD',
                                              o_error);
            RETURN FALSE;
    END delete_drug_req_field;

    /**********************************************************************************************
    * UPDATE_DRUG_REQ_FIELD
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             table_number of Episode identifier
    * @param o_error                  Error message
    *
    * @return                         True on success, false otherwise
    *                        
    * @author          Pedro Teixeira
    * @since           05/01/2018
    **********************************************************************************************/
    FUNCTION update_drug_req_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_drug_req   IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_grid.update_grid_task(i_lang      => i_lang,
                                        i_prof      => i_prof,
                                        i_episode   => i_id_episode,
                                        drug_req_in => i_drug_req,
                                        o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'UPDATE_DRUG_REQ_FIELD',
                                              o_error);
            RETURN FALSE;
    END update_drug_req_field;

    FUNCTION check_has_nurse_vs_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_val sys_domain.val%TYPE;
    BEGIN
    
        SELECT sd.val
          INTO l_val
          FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_schdl_outp_state_domain, 0)) sd
         WHERE sd.val = g_sched_wait_1nurse;
        RETURN pk_alert_constant.g_yes;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END check_has_nurse_vs_status;

    FUNCTION update_disp_ivroom_field
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_disp_ivroom IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_grid.update_grid_task(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_episode      => i_id_episode,
                                        disp_ivroom_in => i_disp_ivroom,
                                        o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'UPDATE_DISP_IVROOM_FIELD',
                                              o_error);
            RETURN FALSE;
    END update_disp_ivroom_field;

    FUNCTION update_disp_task_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_disp_task  IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT pk_grid.update_grid_task(i_lang       => i_lang,
                                        i_prof       => i_prof,
                                        i_episode    => i_id_episode,
                                        disp_task_in => i_disp_task,
                                        o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'UPDATE_DISP_TASK_FIELD',
                                              o_error);
            RETURN FALSE;
    END update_disp_task_field;

    FUNCTION delete_disp_ivroom_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'UPDATE GRID_TASK DISP_IVROOM';
        UPDATE grid_task gt
           SET gt.disp_ivroom = NULL
         WHERE gt.id_episode = i_id_episode;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'DELETE_DISP_IVROOM_FIELD',
                                              o_error);
            RETURN FALSE;
    END delete_disp_ivroom_field;

    FUNCTION delete_disp_task_field
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'UPDATE GRID_TASK DISP_TASK';
        UPDATE grid_task gt
           SET gt.disp_task = NULL
         WHERE gt.id_episode = i_id_episode;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'DELETE_DISP_TASK_FIELD',
                                              o_error);
            RETURN FALSE;
    END delete_disp_task_field;

    FUNCTION get_dates_admin_grid
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_date  OUT pk_types.cursor_type,
        o_error OUT t_error_out
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
              FROM (SELECT pk_date_utils.trunc_insttimezone_str(i_prof, (g_sysdate_tstz) - numtodsinterval(LEVEL, 'DAY'), 'DD') AS DAY,
                           pk_alert_constant.g_no today
                      FROM dual
                    CONNECT BY LEVEL <= l_num_days_back
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, (g_sysdate_tstz), 'DD') AS DAY,
                           pk_alert_constant.g_yes today
                      FROM dual
                    UNION ALL
                    SELECT pk_date_utils.trunc_insttimezone_str(i_prof, (g_sysdate_tstz) + numtodsinterval(LEVEL, 'DAY'), 'DD') AS DAY,
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
                                              g_owner,
                                              g_package,
                                              'get_dates_admin_grid',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
    END get_dates_admin_grid;

    FUNCTION get_pat_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_status   IN VARCHAR2,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_group    IN VARCHAR2 DEFAULT 'N',
        i_id_group     IN schedule.id_group%TYPE,
        i_context      IN VARCHAR2,
        o_status       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --OUTP 
        IF i_id_epis_type IN (pk_alert_constant.g_epis_type_nurse_outp,
                              pk_alert_constant.g_epis_type_outpatient,
                              pk_alert_constant.g_epis_type_resp_therapist)
        THEN
            --Single episode   
            IF i_flg_group = pk_alert_constant.get_no
            THEN
                RETURN get_reg_sched_state_list(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_flg_status  => i_flg_status,
                                                i_id_schedule => i_id_schedule,
                                                o_status      => o_status,
                                                o_error       => o_error);
                --GROUP episode
            ELSIF i_flg_group = pk_alert_constant.get_yes
            THEN
                RETURN pk_grid_amb.get_group_status_list(i_lang     => i_lang,
                                                         i_prof     => i_prof,
                                                         i_id_group => i_id_group,
                                                         i_context  => i_context,
                                                         o_list     => o_status,
                                                         o_error    => o_error);
            ELSE
                pk_types.open_my_cursor(o_status);
            END IF;
            --ADT SOFTWARE
        ELSIF i_prof.software = pk_alert_constant.g_soft_adt
        THEN
            IF i_id_epis_type = pk_alert_constant.g_epis_type_rehab_appointment
            THEN
                RETURN pk_rehab_ux.get_grid_workflow_status(i_lang   => i_lang,
                                                            i_prof   => i_prof,
                                                            i_type   => pk_alert_constant.g_type_appointment,
                                                            i_status => i_flg_status,
                                                            o_status => o_status,
                                                            o_error  => o_error);
            ELSE
                RETURN get_reg_sched_state_list(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_flg_status  => i_flg_status,
                                                i_id_schedule => i_id_schedule,
                                                o_status      => o_status,
                                                o_error       => o_error);
            END IF;
        
        ELSIF i_id_epis_type = pk_alert_constant.g_epis_type_home_health_care
        THEN
            RETURN get_pat_status_list(i_lang        => i_lang,
                                       i_prof        => i_prof,
                                       i_flg_status  => i_flg_status,
                                       i_id_schedule => i_id_schedule,
                                       i_id_patient  => i_id_patient,
                                       o_status      => o_status,
                                       o_error       => o_error);
        ELSE
            pk_types.open_my_cursor(o_status);
        END IF;
        RETURN TRUE;
    END get_pat_status;
    /**********************************************************************************************
    * Saber se o episódio tem (Y) ou não (N) prescrições "até à próxima consulta" para hoje.
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional details
    * @param i_id_episode             table_number of Episode identifier
    * @param o_error                  Error message
    *
    * @return                         Y/N
    *                        
    * @author          Elisabete Bugalho
    * @since           14/02/2022
    **********************************************************************************************/
    FUNCTION exist_prescription_between
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        CURSOR c_presc IS
            SELECT COUNT(1)
              FROM (SELECT ipp.dt_plan_tstz
                      FROM procedures_ea pea, interv_presc_plan ipp
                     WHERE pea.flg_time = g_flg_time_b
                       AND (pea.id_episode = i_episode OR pea.id_episode_origin = i_episode)
                       AND pea.flg_status_req != g_interv_canc
                       AND pea.flg_status_det != g_interv_canc
                       AND ipp.id_interv_presc_det = pea.id_interv_presc_det
                       AND ipp.flg_status IN (g_interv_plan_pend, g_interv_plan_req)
                       AND ipp.dt_plan_tstz BETWEEN l_dt_begin AND l_dt_end
                    UNION ALL
                    SELECT mea.dt_plan
                      FROM monitorizations_ea mea
                     WHERE mea.flg_time = g_flg_time_b
                       AND mea.id_episode = i_episode
                       AND mea.flg_status != g_monit_canc
                       AND mea.flg_status_det != g_monit_canc
                       AND mea.flg_status_plan IN (g_monit_plan_pend, g_monit_plan_inco)
                       AND mea.dt_plan BETWEEN l_dt_begin AND l_dt_end
                    UNION ALL
                    SELECT vpp.dt_plan_tstz
                      FROM vaccine_prescription vp, vaccine_presc_det vpd, vaccine_presc_plan vpp
                     WHERE vp.flg_time = g_flg_time_b
                       AND vp.id_episode = i_episode
                       AND vpd.id_vaccine_prescription = vp.id_vaccine_prescription
                       AND vpp.id_vaccine_presc_det = vpd.id_vaccine_presc_det
                       AND vpp.dt_plan_tstz BETWEEN l_dt_begin AND l_dt_end
                    UNION ALL
                    SELECT l_dt_begin
                      FROM grid_task_between g
                     WHERE g.id_episode = i_episode
                       AND g.flg_drug = pk_alert_constant.g_yes);
    
        l_date  interv_presc_plan.dt_plan_tstz%TYPE;
        l_count NUMBER;
    BEGIN
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp);
        l_dt_end   := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp + INTERVAL '1' DAY);
    
        OPEN c_presc;
        FETCH c_presc
            INTO l_count;
        CLOSE c_presc;
        IF l_count > 0
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    END exist_prescription_between;

BEGIN

    -- Log initialization
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    alertlog.pk_alertlog.log_init(object_name => g_package);

    g_flg_patient_status_active   := 'A';
    g_flg_visit_status_active     := 'A';
    g_flg_episode_status_active   := 'A';
    g_flg_episode_type_outpatient := 'C';
    g_month_sign                  := 'M';
    g_day_sign                    := 'D';

    g_flg_doctor     := pk_alert_constant.g_flg_doctor;
    g_flg_nurse      := pk_alert_constant.g_flg_nurse;
    g_flg_pharmacist := pk_alert_constant.g_flg_pharmacist;
    g_flg_aux        := pk_alert_constant.g_flg_aux;
    g_flg_admin      := pk_alert_constant.g_flg_admin;
    g_flg_tech       := pk_alert_constant.g_flg_tech;

    g_analy_req_pend := 'D';
    g_analy_req_req  := 'R';
    g_analy_req_exec := 'E';
    g_analy_req_res  := 'F';
    g_analy_req_canc := 'C';
    g_analy_req_part := 'P';
    g_analy_req_tran := 'T';
    g_analy_req_harv := 'H';
    g_analy_req_ext  := 'X';

    g_exam_req_tosched := 'PA';
    g_exam_req_sched   := 'A';
    g_exam_req_efectiv := 'EF';
    g_exam_req_pend    := 'D';
    g_exam_req_req     := 'R';
    g_exam_req_exec    := 'E';
    g_exam_req_part    := 'P';
    g_exam_req_resu    := 'F';
    g_exam_req_canc    := 'C';
    g_exam_req_nr      := 'NR';
    g_exam_req_read    := 'L';

    g_interv_pend := 'D';
    g_interv_req  := 'R';
    g_interv_fin  := 'F';
    g_interv_canc := 'C';
    g_interv_part := 'P';
    g_interv_exe  := 'E';
    g_interv_intr := 'I';

    g_interv_plan_admin := 'A';
    g_interv_plan_req   := 'R';
    g_interv_plan_pend  := 'D';
    g_interv_plan_canc  := 'C';

    g_epis_active   := 'A';
    g_epis_inactive := 'I';
    g_epis_canc     := 'C';
    g_epis_temp     := 'T';

    g_flg_time_e := 'E';
    g_flg_time_n := 'N';
    g_flg_time_b := 'B';
    g_flg_time_d := 'D';

    g_flg_status_f := 'F';
    g_flg_status_p := 'P';
    g_flg_status_r := 'R';
    g_flg_status_a := 'A';
    g_flg_status_c := 'C';
    g_flg_status_e := 'E';
    g_flg_status_d := 'D';
    g_flg_status_i := 'I';
    g_flg_status_x := 'X';

    g_icon        := 'I';
    g_message     := 'M';
    g_color_red   := 'R';
    g_color_green := 'G';
    g_no_color    := 'X';

    g_text         := 'T';
    g_date         := 'D';
    g_dateicon     := 'DI';
    g_vaccine_pend := 'D';
    g_vaccine_req  := 'R';
    g_vaccine_res  := 'F';
    g_vaccine_canc := 'C';
    g_vaccine_part := 'P';
    g_vaccine_exe  := 'E';

    g_sched_scheduled    := 'A';
    g_sched_efectiv      := 'E';
    g_sched_med_disch    := 'D';
    g_sched_adm_disch    := 'M';
    g_sched_wait         := 'C';
    g_sched_nurse_prev   := 'W';
    g_sched_nurse        := 'N';
    g_sched_nurse_end    := 'P';
    g_sched_cons         := 'T';
    g_flg_state_p        := 'P';
    g_sched_wait_1nurse  := 'H';
    g_sched_in_1nurse    := 'V';
    g_sched_psycho_disch := 'J';
    g_sched_rt_disch     := 'L';
    g_sched_cdc_disch    := 'X';

    g_sched_canc := 'C';
    g_sched_temp := 'T';

    g_mov_status_req    := 'R';
    g_mov_status_transp := 'T';
    g_mov_status_pend   := 'P';
    g_mov_status_finish := 'F';
    g_mov_status_interr := 'S';
    g_mov_status_cancel := 'C';

    g_cli_rec_pend    := 'D';
    g_cli_rec_exec    := 'E';
    g_cli_rec_cancel  := 'C';
    g_cli_rec_req     := 'R';
    g_cli_rec_partial := 'P';
    g_cli_rec_finish  := 'F';

    g_cli_rec_mov_o := 'O';
    g_cli_rec_mov_t := 'T';

    g_harvest_cancel := 'C';
    g_harvest_finish := 'F';
    g_harvest_trans  := 'T';
    g_harvest_harv   := 'H';

    g_monit_pend := 'D';
    g_monit_exe  := 'A';
    g_monit_fin  := 'F';
    g_monit_canc := 'C';

    g_exam_image := 'I';
    g_exam_func  := 'F';
    g_exam_audio := 'A';
    g_exam_gastr := 'G';
    g_exam_ortho := 'O';

    g_nurse_tea_pend := 'D';
    g_nurse_tea_act  := 'A';
    g_nurse_tea_fin  := 'F';
    g_nurse_tea_can  := 'C';

    g_read := 'L';

    g_yes := 'Y';
    g_no  := 'N';

    g_flg_area_e := 'E';
    g_flg_area_t := 'T';
    g_flg_area_c := 'C';
    g_flg_area_h := 'H';
    g_flg_area_o := 'O';
    g_flg_area_f := 'F';

    g_flg_grid   := 'G';
    g_flg_search := 'S';

    g_flg_sos := 'S';

    g_monit_plan_pend := 'D';
    g_monit_plan_inco := 'A';

    g_nactv_det_pend := 'D';
    g_nactv_det_req  := 'R';
    g_nactv_det_exec := 'E';

    g_schdl_outp_state_domain     := 'SCHEDULE_OUTP.FLG_STATE';
    g_schdl_outp_state_act_domain := 'SCHEDULE_OUTP.FLG_STATE_ACTION';
    g_schdl_nurse_state_domain    := 'SCHEDULE_OUTP.FLG_NURSE_ACTION'; -- tco 26/05/2008

    -- RL 2008/05/16    
    g_schdl_interv_state_domain := 'SCHEDULE_INTERVENTION.FLG_STATE';

    g_sch_subs := 'S';
    g_instit_h := 'H';
    g_instit_c := 'C';

    g_wr_available_y := 'Y';
    g_sys_config_wr  := 'WL_WAITING_ROOM_AVAILABLE';

    g_selected := 'S';
    g_isencao  := 1;

    g_currency_unit_format_db := 'CURRENCY_UNIT_FORMAT_DB';
    g_exam_can_req            := 'P';

    g_edis_software   := 8;
    g_nutri_software  := 43;
    g_psycho_software := 310;
    g_rehab_software  := 36;

    g_cat_type_f := 'F';
    g_cat_type_a := 'A';
    g_cat_type_c := 'C';

    g_flg_epis_type_nurse_care := 14;
    g_flg_epis_type_nurse_outp := 16;
    g_flg_epis_type_nurse_pp   := 17;
    g_epis_type_rehab          := 25;

    g_flg_status              := 'INTERV_PRESC_DET.FLG_STATUS_MFR';
    g_flg_status_schedulepend := 'P';

    g_alloc_y := 'Y';
    g_alloc_n := 'N';

    g_sched_nurse_disch := 'P';
END pk_grid;
/
