/*-- Last Change Revision: $Rev: 1982348 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2021-03-10 14:30:54 +0000 (qua, 10 mar 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_discharge_amb IS

    g_error         VARCHAR2(4000);
    g_package_owner VARCHAR2(32);
    g_package_name  VARCHAR2(32);
    g_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
    g_exception EXCEPTION;

    g_def_disch_reas_sc CONSTANT sys_config.id_sys_config%TYPE := 'DEFAULT_DISCHARGE_REASON';
    g_disch_type_f      CONSTANT discharge.flg_type%TYPE := 'F';
    g_doctor            CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_code_type_closure CONSTANT sys_domain.code_domain%TYPE := 'DISCHARGE_DETAIL.FLG_TYPE_CLOSURE';

    /*
    * Format i_srt to be presented as a title (add bold tags and colon).
    *
    * @param i_srt            title string to format
    * @param i_is_report      show on reports?
    * @param i_is_mandatory   mandatory field?
    *
    * @return                 formatted title.
    *
    * @author                 Orlando Antunes
    * @version                 2.6.0.1
    * @since                  2010/03/05
    */
    FUNCTION get_title
    (
        i_srt          IN VARCHAR2,
        i_is_report    IN VARCHAR2 DEFAULT 'N',
        i_is_mandatory IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN pk_paramedical_prof_core.format_str_header_w_colon(i_srt          => i_srt,
                                                                  i_is_report    => i_is_report,
                                                                  i_is_mandatory => i_is_mandatory);
    END get_title;

    /*
    * Get discharge_detail identifier.
    *
    * @param i_discharge      discharge identifier
    *
    * @return                 discharge_detail identifier.
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/15
    */
    FUNCTION id_discharge_detail(i_discharge IN discharge.id_discharge%TYPE)
        RETURN discharge_detail.id_discharge_detail%TYPE IS
        l_disch_detail discharge_detail.id_discharge_detail%TYPE;
    BEGIN
        g_error := 'SELECT id_discharge_detail';
        SELECT dd.id_discharge_detail
          INTO l_disch_detail
          FROM discharge_detail dd
         WHERE dd.id_discharge = i_discharge;
    
        RETURN l_disch_detail;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END id_discharge_detail;

    /*
    * Get list of discharge destinies.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param o_list           discharge destinies list
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    PROCEDURE get_discharge_dest_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        o_list OUT pk_types.cursor_type
    ) IS
        l_disch_reason disch_reas_dest.id_discharge_reason%TYPE;
    BEGIN
        g_error        := 'CALL pk_sysconfig.get_config';
        l_disch_reason := pk_sysconfig.get_config(i_code_cf => g_def_disch_reas_sc, i_prof => i_prof);
    
        g_error := 'OPEN o_list';
        OPEN o_list FOR
            SELECT DISTINCT drd.id_disch_reas_dest data,
                            pk_translation.get_translation(i_lang, dd.code_discharge_dest) label,
                            dd.rank,
                            NULL icon
              FROM disch_reas_dest drd
              JOIN discharge_dest dd
                ON drd.id_discharge_dest = dd.id_discharge_dest
             WHERE drd.id_discharge_reason = l_disch_reason
               AND drd.id_instit_param = i_prof.institution
               AND drd.id_software_param = i_prof.software
               AND drd.flg_active = pk_alert_constant.g_active
               AND dd.flg_available = pk_alert_constant.g_yes
             ORDER BY dd.rank;
    END get_discharge_dest_list;

    /*
    * Get an episode's discharges list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info 
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/05
    */
    PROCEDURE get_discharge_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type
    ) IS
        l_reopen_msg     sys_message.desc_message%TYPE;
        l_cancel_msg     sys_message.desc_message%TYPE;
        l_epis_type      epis_type.id_epis_type%TYPE := NULL;
        l_view_discharge VARCHAR2(0001 CHAR) := pk_alert_constant.g_no;
    BEGIN
        l_reopen_msg := pk_message.get_message(i_lang, i_prof, 'COMMON_M037');
        l_cancel_msg := pk_message.get_message(i_lang, i_prof, 'COMMON_M028');
    
        IF i_episode IS NOT NULL
        THEN
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
        END IF;
    
        IF ((l_epis_type = pk_alert_constant.g_epis_type_social AND i_prof.software = pk_alert_constant.g_soft_social) OR
           (l_epis_type = pk_alert_constant.g_epis_type_dietitian AND
           i_prof.software = pk_alert_constant.g_soft_nutritionist) OR
           (l_epis_type = pk_alert_constant.g_epis_type_psychologist AND
           i_prof.software = pk_alert_constant.g_soft_psychologist) OR
           (l_epis_type = pk_alert_constant.g_epis_type_home_health_care AND
           i_prof.software IN (pk_alert_constant.g_soft_social,
                                 pk_alert_constant.g_soft_psychologist,
                                 pk_alert_constant.g_soft_nutritionist)) OR
           i_prof.software NOT IN (pk_alert_constant.g_soft_social,
                                    pk_alert_constant.g_soft_nutritionist,
                                    pk_alert_constant.g_soft_psychologist))
        THEN
            l_view_discharge := pk_alert_constant.g_yes;
        END IF;
    
        g_error := 'OPEN o_discharge';
        OPEN o_discharge FOR
            SELECT d.id_discharge id,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(d.id_prof_med, d.id_prof_admin)) desc_prof,
                   nvl(pk_paramedical_prof_core.get_format_time_spent(i_lang, dt.total_time_spent, dt.id_unit_measure),
                       pk_paramedical_prof_core.c_dashes) desc_total_time_spent,
                   pk_translation.get_translation(i_lang, dd.code_discharge_dest) desc_destiny,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    nvl(d.dt_med_tstz, d.dt_admin_tstz),
                                                    i_prof.institution,
                                                    i_prof.software) desc_end_hour,
                   pk_date_utils.dt_chr_tsz(i_lang,
                                            nvl(d.dt_med_tstz, d.dt_admin_tstz),
                                            i_prof.institution,
                                            i_prof.software) desc_end_date,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_admin_tstz), i_prof) dt,
                   decode(d.flg_status,
                          pk_discharge.g_disch_flg_status_reopen,
                          l_reopen_msg,
                          pk_discharge.g_disch_flg_cancel,
                          l_cancel_msg,
                          '') desc_status,
                   nvl((SELECT pk_sysdomain.get_domain(i_code_dom => g_code_type_closure,
                                                      i_val      => dt.flg_type_closure,
                                                      i_lang     => i_lang)
                         FROM dual),
                       pk_paramedical_prof_core.c_dashes) desc_type_closure
              FROM discharge d
              JOIN disch_reas_dest drd
                ON d.id_disch_reas_dest = drd.id_disch_reas_dest
              LEFT JOIN discharge_dest dd
                ON drd.id_discharge_dest = dd.id_discharge_dest
              LEFT JOIN discharge_detail dt
                ON d.id_discharge = dt.id_discharge
             WHERE d.id_episode = i_episode
               AND l_view_discharge = pk_alert_constant.g_yes
               AND (d.flg_status IN (pk_alert_constant.g_active, pk_discharge.g_disch_flg_status_reopen) OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND d.flg_status = pk_alert_constant.g_cancelled))
             ORDER BY decode(d.flg_status, pk_alert_constant.g_cancelled, 2, 1), d.dt_med_tstz DESC;
    
        g_error := 'OPEN o_discharge_prof';
        OPEN o_discharge_prof FOR
            SELECT d.id_discharge id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, d.dt_disch_tstz, i_prof) dt,
                   (SELECT pk_tools.get_prof_description(i_lang, i_prof, d.id_prof_med, d.dt_disch_tstz, d.id_episode)
                      FROM dual) prof_sign,
                   d.flg_status,
                   NULL desc_status,
                   decode(d.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_alert_constant.g_no,
                          pk_discharge.g_disch_flg_status_reopen,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_cancel,
                   decode(d.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_alert_constant.g_no,
                          pk_discharge.g_disch_flg_status_reopen,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_action
              FROM (SELECT d.id_discharge,
                           d.id_episode,
                           d.flg_status,
                           d.id_prof_med,
                           d.dt_med_tstz,
                           nvl((SELECT MAX(dh.dt_created_hist)
                                 FROM discharge_hist dh
                                WHERE dh.id_discharge = d.id_discharge),
                               d.dt_med_tstz) dt_disch_tstz
                      FROM discharge d) d
             WHERE d.id_episode = i_episode
               AND (d.flg_status IN (pk_alert_constant.g_active, pk_discharge.g_disch_flg_status_reopen) OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND d.flg_status = pk_alert_constant.g_cancelled))
               AND l_view_discharge = pk_alert_constant.g_yes
             ORDER BY decode(d.flg_status, pk_alert_constant.g_cancelled, 2, 1), d.dt_med_tstz DESC;
    END get_discharge_list;

    /*
    * Get a discharge record history.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info 
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/05
    */
    PROCEDURE get_discharge_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_show_destiny   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type
    ) IS
        l_disch_reason       discharge_reason.id_discharge_reason%TYPE;
        l_msg_oper_add       sys_message.desc_message%TYPE;
        l_msg_oper_edit      sys_message.desc_message%TYPE;
        l_msg_oper_canc      sys_message.desc_message%TYPE;
        l_end_dt_title       sys_message.desc_message%TYPE;
        l_enc_cnt_title      sys_message.desc_message%TYPE;
        l_tot_time_title     sys_message.desc_message%TYPE;
        l_reason_title       sys_message.desc_message%TYPE;
        l_dest_title         sys_message.desc_message%TYPE;
        l_notes_title        sys_message.desc_message%TYPE;
        l_canc_rea_title     sys_message.desc_message%TYPE;
        l_canc_not_title     sys_message.desc_message%TYPE;
        l_type_closure_title sys_message.desc_message%TYPE;
    BEGIN
        g_error              := 'GET config/message';
        l_disch_reason       := pk_sysconfig.get_config(i_code_cf => g_def_disch_reas_sc, i_prof => i_prof);
        l_msg_oper_add       := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T107');
        l_msg_oper_edit      := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T108');
        l_msg_oper_canc      := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T109');
        l_end_dt_title       := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T125'));
        l_tot_time_title     := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T138'));
        l_enc_cnt_title      := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T139'));
        l_reason_title       := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T141'));
        l_dest_title         := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T140'));
        l_notes_title        := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T082'));
        l_canc_rea_title     := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'COMMON_M072'));
        l_canc_not_title     := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'COMMON_M073'));
        l_type_closure_title := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T164'));
    
        g_error := 'OPEN o_discharge';
        OPEN o_discharge FOR
            SELECT dh.id_discharge_hist id,
                   l_end_dt_title ||
                   pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) desc_end_date,
                   l_tot_time_title || nvl((SELECT pk_paramedical_prof_core.get_format_time_spent(i_lang,
                                                                                                 dth.total_time_spent,
                                                                                                 dth.id_unit_measure)
                                             FROM dual),
                                           pk_paramedical_prof_core.c_dashes) desc_total_time_spent,
                   decode(l_enc_cnt_title, NULL, NULL, l_enc_cnt_title || dth.followup_count) desc_enc_count,
                   decode(dr.id_discharge_reason,
                          l_disch_reason,
                          NULL,
                          l_reason_title || pk_translation.get_translation(i_lang, dr.code_discharge_reason)) desc_reason,
                   decode(i_show_destiny,
                          pk_alert_constant.g_yes,
                          l_dest_title || pk_translation.get_translation(i_lang, dd.code_discharge_dest),
                          NULL) desc_destiny,
                   decode(dth.flg_type_closure,
                          NULL,
                          NULL,
                          l_type_closure_title || (SELECT pk_sysdomain.get_domain(i_code_dom => g_code_type_closure,
                                                                                  i_val      => dth.flg_type_closure,
                                                                                  i_lang     => i_lang)
                                                     FROM dual)) desc_type_closure,
                   decode(dh.notes_med, NULL, NULL, l_notes_title || dh.notes_med) desc_notes,
                   decode(dh.flg_status,
                          pk_alert_constant.g_cancelled,
                          l_canc_rea_title || pk_translation.get_translation(i_lang, cr.code_cancel_reason)) desc_cancel_reason,
                   decode(dh.flg_status, pk_alert_constant.g_cancelled, l_canc_not_title || dh.notes_cancel) desc_cancel_notes
              FROM discharge_hist dh
              LEFT JOIN discharge_detail_hist dth
                ON dh.id_discharge_hist = dth.id_discharge_hist
              JOIN disch_reas_dest drd
                ON dh.id_disch_reas_dest = drd.id_disch_reas_dest
              LEFT JOIN discharge_dest dd
                ON drd.id_discharge_dest = dd.id_discharge_dest
              JOIN discharge_reason dr
                ON drd.id_discharge_reason = dr.id_discharge_reason
              JOIN discharge d
                ON dh.id_discharge = d.id_discharge
              LEFT JOIN cancel_reason cr
                ON d.id_cancel_reason = cr.id_cancel_reason
             WHERE dh.id_discharge = i_discharge;
    
        g_error := 'OPEN o_discharge_prof';
        OPEN o_discharge_prof FOR
            SELECT dh.id_discharge_hist id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dh.dt_created_hist, i_prof) dt,
                   (SELECT pk_tools.get_prof_description(i_lang,
                                                         i_prof,
                                                         dh.id_prof_created_hist,
                                                         dh.dt_created_hist,
                                                         dh.id_episode)
                      FROM dual) prof_sign,
                   dh.flg_status,
                   decode(rownum,
                          1,
                          l_msg_oper_add,
                          decode(dh.flg_status, pk_alert_constant.g_cancelled, l_msg_oper_canc, l_msg_oper_edit)) desc_status,
                   decode(dh.flg_status, pk_alert_constant.g_cancelled, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_cancel,
                   decode(dh.flg_status, pk_alert_constant.g_cancelled, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_action
              FROM (SELECT dh.id_discharge_hist,
                           dh.id_discharge,
                           dh.id_episode,
                           dh.dt_created_hist,
                           dh.id_prof_created_hist,
                           dh.flg_status
                      FROM discharge_hist dh
                     WHERE dh.id_discharge = i_discharge
                     ORDER BY dh.dt_created_hist) dh
             ORDER BY dh.dt_created_hist DESC;
    END get_discharge_hist;

    /*
    * Get an episode's discharges list. Specify the discharge
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info 
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/05
    */
    FUNCTION get_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_discharge IS NULL
        THEN
            g_error := 'CALL get_discharge_list';
            get_discharge_list(i_lang           => i_lang,
                               i_prof           => i_prof,
                               i_episode        => i_episode,
                               i_show_cancelled => i_show_cancelled,
                               o_discharge      => o_discharge,
                               o_discharge_prof => o_discharge_prof);
        ELSE
            g_error := 'CALL get_discharge_hist: ' || i_discharge;
            get_discharge_hist(i_lang           => i_lang,
                               i_prof           => i_prof,
                               i_discharge      => i_discharge,
                               o_discharge      => o_discharge,
                               o_discharge_prof => o_discharge_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_DISCHARGE',
                                                     o_error    => o_error);
    END get_discharge;

    /*
    * Get an episode's discharges list. Specify the discharge
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info 
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  29-Jun-2010
    */
    FUNCTION get_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_show_cancelled IN VARCHAR2,
        i_show_destiny   IN VARCHAR2,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_discharge IS NULL
        THEN
            g_error := 'CALL get_discharge_list';
            get_discharge_list(i_lang           => i_lang,
                               i_prof           => i_prof,
                               i_episode        => i_episode,
                               i_show_cancelled => i_show_cancelled,
                               o_discharge      => o_discharge,
                               o_discharge_prof => o_discharge_prof);
        ELSE
            g_error := 'CALL get_discharge_hist';
            get_discharge_hist(i_lang           => i_lang,
                               i_prof           => i_prof,
                               i_discharge      => i_discharge,
                               i_show_destiny   => i_show_destiny,
                               o_discharge      => o_discharge,
                               o_discharge_prof => o_discharge_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_DISCHARGE',
                                                     o_error    => o_error);
    END get_discharge;

    /**
    * Get an episode's discharge record history, for reports layer usage.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      actual episode identifier
    * @param o_discharge    discharges
    * @param o_discharge_prof discharges records info
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/03/09
    */
    FUNCTION get_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_DISCHARGE';
        l_disch_reason       discharge_reason.id_discharge_reason%TYPE;
        l_msg_oper_add       sys_message.desc_message%TYPE;
        l_msg_oper_edit      sys_message.desc_message%TYPE;
        l_end_dt_title       sys_message.desc_message%TYPE;
        l_tot_time_title     sys_message.desc_message%TYPE;
        l_reason_title       sys_message.desc_message%TYPE;
        l_dest_title         sys_message.desc_message%TYPE;
        l_notes_title        sys_message.desc_message%TYPE;
        l_type_closure_title sys_message.desc_message%TYPE;
    BEGIN
        g_error              := 'GET config/message';
        l_disch_reason       := pk_sysconfig.get_config(i_code_cf => g_def_disch_reas_sc, i_prof => i_prof);
        l_msg_oper_add       := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T107');
        l_msg_oper_edit      := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T108');
        l_end_dt_title       := get_title(i_srt       => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T125'),
                                          i_is_report => pk_alert_constant.g_yes);
        l_tot_time_title     := get_title(i_srt       => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T138'),
                                          i_is_report => pk_alert_constant.g_yes);
        l_reason_title       := get_title(i_srt       => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T141'),
                                          i_is_report => pk_alert_constant.g_yes);
        l_dest_title         := get_title(i_srt       => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T140'),
                                          i_is_report => pk_alert_constant.g_yes);
        l_notes_title        := get_title(i_srt       => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T082'),
                                          i_is_report => pk_alert_constant.g_yes);
        l_type_closure_title := get_title(i_srt       => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T164'),
                                          i_is_report => pk_alert_constant.g_yes);
    
        g_error := 'OPEN o_discharge';
        OPEN o_discharge FOR
            SELECT d.id_discharge id,
                   l_end_dt_title lbl_end_date,
                   pk_date_utils.date_char_tsz(i_lang, d.dt_med_tstz, i_prof.institution, i_prof.software) desc_end_date,
                   l_tot_time_title lbl_total_time_spent,
                   nvl(pk_paramedical_prof_core.get_time_spent_desc(i_lang, dt.total_time_spent, dt.id_unit_measure),
                       pk_paramedical_prof_core.c_dashes) desc_total_time_spent,
                   decode(dr.id_discharge_reason, l_disch_reason, pk_alert_constant.g_no, pk_alert_constant.g_yes) reason_enable,
                   l_reason_title lbl_reason,
                   decode(dr.id_discharge_reason,
                          l_disch_reason,
                          NULL,
                          pk_translation.get_translation(i_lang, dr.code_discharge_reason)) desc_reason,
                   l_dest_title lbl_destiny,
                   pk_translation.get_translation(i_lang, dd.code_discharge_dest) desc_destiny,
                   l_notes_title lbl_notes,
                   d.notes_med desc_notes,
                   l_type_closure_title lbl_type_closure,
                   (SELECT pk_sysdomain.get_domain(i_code_dom => g_code_type_closure,
                                                   i_val      => dt.flg_type_closure,
                                                   i_lang     => i_lang)
                      FROM dual) desc_type_closure
              FROM discharge d
              JOIN disch_reas_dest drd
                ON d.id_disch_reas_dest = drd.id_disch_reas_dest
              JOIN discharge_reason dr
                ON drd.id_discharge_reason = dr.id_discharge_reason
              LEFT JOIN discharge_dest dd
                ON drd.id_discharge_dest = dd.id_discharge_dest
              JOIN discharge_detail dt
                ON d.id_discharge = dt.id_discharge
             WHERE d.id_episode = i_episode
               AND d.flg_status IN (pk_alert_constant.g_active, pk_discharge.g_disch_flg_status_reopen);
    
        g_error := 'OPEN o_discharge_prof';
        OPEN o_discharge_prof FOR
            SELECT d.id_discharge id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, d.dt_disch_tstz, i_prof) dt,
                   pk_date_utils.date_send_tsz(i_lang, d.dt_disch_tstz, i_prof) dt_serial,
                   (SELECT pk_tools.get_prof_description(i_lang, i_prof, d.id_prof_med, d.dt_disch_tstz, d.id_episode)
                      FROM dual) prof_sign,
                   d.flg_status,
                   decode((SELECT COUNT(*)
                            FROM discharge_hist dh
                           WHERE dh.id_discharge = d.id_discharge),
                          1,
                          l_msg_oper_add,
                          l_msg_oper_edit) desc_status
              FROM (SELECT d.id_discharge,
                           d.id_episode,
                           d.flg_status,
                           d.id_prof_med,
                           d.dt_med_tstz,
                           nvl((SELECT MAX(dh.dt_created_hist)
                                 FROM discharge_hist dh
                                WHERE dh.id_discharge = d.id_discharge),
                               d.dt_med_tstz) dt_disch_tstz
                      FROM discharge d) d
             WHERE d.id_episode = i_episode
               AND d.flg_status IN (pk_alert_constant.g_active, pk_discharge.g_disch_flg_status_reopen)
             ORDER BY d.dt_disch_tstz DESC;
    
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
    END get_discharge;

    /*
    * Get discharge data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharge
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_discharge_edit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_discharge OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_time_spent                   discharge_detail.total_time_spent%TYPE;
        l_time_unit                    discharge_detail.id_unit_measure%TYPE;
        l_end_dt_title                 sys_message.desc_message%TYPE;
        l_tot_time_title               sys_message.desc_message%TYPE;
        l_dest_title                   sys_message.desc_message%TYPE;
        l_notes_title                  sys_message.desc_message%TYPE;
        l_type_closure_title           sys_message.desc_message%TYPE;
        l_paramedical_disch_time_spent sys_config.value%TYPE;
        l_epis_type                    epis_type.id_epis_type%TYPE := NULL;
    BEGIN
    
        IF i_episode IS NOT NULL
        THEN
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
        END IF;
    
        g_sysdate_tstz := current_timestamp;
    
        l_paramedical_disch_time_spent := pk_sysconfig.get_config('PARAMEDICAL_DISCHARGE_TIME_SPENT_MANDATORY', i_prof);
    
        -- field titles
        l_end_dt_title   := get_title(i_srt          => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T125'),
                                      i_is_report    => 'Y',
                                      i_is_mandatory => 'Y');
        l_tot_time_title := get_title(i_srt          => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T138'),
                                      i_is_report    => 'Y',
                                      i_is_mandatory => CASE
                                                            WHEN l_epis_type IN
                                                                 (pk_alert_constant.g_epis_type_dietitian, pk_alert_constant.g_epis_type_social) THEN
                                                             CASE
                                                                 WHEN l_paramedical_disch_time_spent = pk_alert_constant.g_yes THEN
                                                                  pk_alert_constant.g_yes
                                                                 ELSE
                                                                  pk_alert_constant.g_no
                                                             END
                                                            ELSE
                                                             pk_alert_constant.g_yes
                                                        END);
        l_dest_title     := get_title(i_srt          => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T140'),
                                      i_is_report    => 'Y',
                                      i_is_mandatory => 'Y');
        l_notes_title    := get_title(i_srt       => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T082'),
                                      i_is_report => 'Y');
    
        l_type_closure_title := get_title(i_srt          => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T164'),
                                          i_is_report    => 'Y',
                                          i_is_mandatory => 'Y');
        IF i_discharge IS NULL
        THEN
            -- if no discharge id is provided,
            -- we are creating a new record...
            g_error := 'CALL pk_paramedical_prof_core.time_spent';
        
            pk_paramedical_prof_core.time_spent(i_prof => i_prof, i_episode => i_episode, o_time_spent => l_time_spent);
        
            g_error := 'OPEN o_discharge I';
            OPEN o_discharge FOR
                SELECT l_end_dt_title title_end_date,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, g_sysdate_tstz, i_prof) desc_end_date,
                       pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof) flg_end_date,
                       l_tot_time_title title_time_spent,
                       decode(l_paramedical_disch_time_spent,
                              pk_alert_constant.g_yes,
                              pk_paramedical_prof_core.get_format_time_spent(i_lang,
                                                                             pk_paramedical_prof_core.time_spent_convert(i_prof,
                                                                                                                         i_episode))) desc_time_spent,
                       l_time_spent * 60 time_spent_min,
                       l_time_spent flg_time_spent,
                       l_time_unit measure_time_spent,
                       l_dest_title title_destiny,
                       NULL desc_destiny,
                       NULL flg_destiny,
                       l_notes_title title_notes,
                       NULL desc_notes,
                       l_type_closure_title title_type_closure,
                       NULL flg_type_closure,
                       NULL desc_type_closure
                  FROM dual;
        ELSE
            -- ... otherwise, we are editing a previous record
            g_error := 'OPEN o_discharge II';
            OPEN o_discharge FOR
                SELECT l_end_dt_title title_end_date,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_admin_tstz), i_prof) desc_end_date,
                       pk_date_utils.date_send_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_admin_tstz), i_prof) flg_end_date,
                       l_tot_time_title title_time_spent,
                       pk_paramedical_prof_core.get_format_time_spent(i_lang, dt.total_time_spent, dt.id_unit_measure) desc_time_spent,
                       dt.total_time_spent flg_time_spent,
                       dt.id_unit_measure measure_time_spent,
                       l_dest_title title_destiny,
                       pk_translation.get_translation(i_lang, dd.code_discharge_dest) desc_destiny,
                       d.id_disch_reas_dest flg_destiny,
                       l_notes_title title_notes,
                       d.notes_med desc_notes,
                       l_type_closure_title title_type_closure,
                       dt.flg_type_closure flg_type_closure,
                       (SELECT pk_sysdomain.get_domain(i_code_dom => g_code_type_closure,
                                                       i_val      => dt.flg_type_closure,
                                                       i_lang     => i_lang)
                          FROM dual) desc_type_closure
                  FROM discharge d
                  JOIN disch_reas_dest drd
                    ON d.id_disch_reas_dest = drd.id_disch_reas_dest
                  LEFT JOIN discharge_dest dd
                    ON drd.id_discharge_dest = dd.id_discharge_dest
                  LEFT JOIN discharge_detail dt
                    ON d.id_discharge = dt.id_discharge
                 WHERE d.id_discharge = i_discharge;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_DISCHARGE_EDIT',
                                                     o_error    => o_error);
    END get_discharge_edit;

    /*
    * Check if the CREATE button must be enabled
    * in the discharge screen.
    *
    * @param i_lang           language identifier
    * @param i_episode        episode identifier
    * @param o_create         'Y' to enable create, 'N' otherwise
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_discharge_create
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_count PLS_INTEGER;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM discharge d
         WHERE d.id_episode = i_episode
           AND d.flg_status = pk_alert_constant.g_active
           AND d.id_prof_med IS NOT NULL;
    
        IF l_count = 0
        THEN
            o_create := pk_alert_constant.g_yes;
        ELSE
            o_create := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_DISCHARGE_CREATE',
                                                     o_error    => o_error);
    END get_discharge_create;

    /*
    * Get necessary domains for discharge registration.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param o_destiny        discharge destinies
    * @param o_time_unit      time units
    * @param o_type_closure   type of closure
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_domains
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_destiny      OUT pk_types.cursor_type,
        o_time_unit    OUT pk_types.cursor_type,
        o_type_closure OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_discharge_dest_list';
        get_discharge_dest_list(i_lang => i_lang, i_prof => i_prof, o_list => o_destiny);
    
        g_error := 'CALL pk_paramedical_prof_core.get_followup_time_units';
        pk_paramedical_prof_core.get_followup_time_units(i_prof => i_prof, o_time_units => o_time_unit);
    
        g_error := 'CALL get_disch_type_closure_list';
        get_disch_type_closure_list(i_lang => i_lang, i_prof => i_prof, o_list => o_type_closure);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_DOMAINS',
                                                     o_error    => o_error);
    END get_domains;

    /*
    * Set discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_prof_cat       logged professional category
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_dt_end         discharge date
    * @param i_disch_dest     discharge reason destiny identifier
    * @param i_notes          discharge notes_med
    * @param i_print_report   print report?
    * @param i_transaction    scheduler transaction identifier
    * @param o_reports_pat    report to print
    * @param o_flg_show       warm
    * @param o_msg_title      warn
    * @param o_msg_text       warn
    * @param o_button         warn
    * @param o_id_episode     created episode identifier
    * @param o_discharge      created discharge identifier
    * @param o_disch_detail   created discharge_detail identifier
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error message
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION set_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_cat         IN category.flg_type%TYPE,
        i_discharge        IN discharge.id_discharge%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_dt_end           IN VARCHAR2,
        i_disch_dest       IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_notes            IN discharge.notes_med%TYPE,
        i_time_spent       IN discharge_detail.total_time_spent%TYPE,
        i_unit_measure     IN discharge_detail.id_unit_measure%TYPE,
        i_print_report     IN discharge_detail.flg_print_report%TYPE,
        i_transaction      IN VARCHAR2 := NULL,
        i_flg_type_closure IN discharge_detail.flg_type_closure%TYPE,
        o_reports_pat      OUT reports.id_reports%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_discharge        OUT discharge.id_discharge%TYPE,
        o_disch_detail     OUT discharge_detail.id_discharge_detail%TYPE,
        o_disch_hist       OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist   OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_end           discharge.dt_med_tstz%TYPE;
        l_shortcut         sys_shortcut.id_sys_shortcut%TYPE;
        l_discharge        discharge.id_discharge%TYPE;
        l_disch_detail     discharge_detail.id_discharge_detail%TYPE;
        l_disch_detail_aux discharge_detail.id_discharge_detail%TYPE;
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL pk_schedule_api_upstream.begin_new_transaction';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction, i_prof);
    
        l_discharge := i_discharge;
        l_dt_end    := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_timestamp => i_dt_end,
                                                     i_timezone  => NULL);
    
        IF l_discharge IS NULL
        THEN
            -- register new discharge 
            g_error := 'CALL pk_discharge.set_discharge_no_commit';
            IF NOT pk_discharge.set_discharge_no_commit(i_lang             => i_lang,
                                                        i_episode          => i_episode,
                                                        i_prof             => i_prof,
                                                        i_reas_dest        => i_disch_dest,
                                                        i_disch_type       => g_disch_type_f,
                                                        i_flg_type         => g_doctor,
                                                        i_notes            => i_notes,
                                                        i_transp           => NULL,
                                                        i_justify          => NULL,
                                                        i_prof_cat_type    => i_prof_cat,
                                                        i_price            => NULL,
                                                        i_currency         => NULL,
                                                        i_flg_payment      => NULL,
                                                        i_flg_surgery      => NULL,
                                                        i_dt_surgery       => NULL,
                                                        i_clin_serv        => NULL,
                                                        i_department       => NULL,
                                                        i_transaction_id   => l_transaction_id,
                                                        i_flg_bill_type    => NULL,
                                                        i_flg_print_report => i_print_report,
                                                        i_flg_letter       => NULL,
                                                        i_flg_task         => NULL,
                                                        i_flg_hist         => pk_alert_constant.g_no,
                                                        i_dt_med           => i_dt_end,
                                                        i_flg_type_closure => i_flg_type_closure,
                                                        o_reports_pat      => o_reports_pat,
                                                        o_flg_show         => o_flg_show,
                                                        o_msg_title        => o_msg_title,
                                                        o_msg_text         => o_msg_text,
                                                        o_button           => o_button,
                                                        o_id_episode       => o_id_episode,
                                                        o_id_shortcut      => l_shortcut,
                                                        o_discharge        => l_discharge,
                                                        o_discharge_detail => l_disch_detail,
                                                        o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'UPDATE discharge_detail: ' || l_disch_detail;
            UPDATE discharge_detail dd
               SET dd.total_time_spent = i_time_spent, dd.id_unit_measure = i_unit_measure
             WHERE dd.id_discharge_detail = l_disch_detail;
        ELSE
            -- updating an existing discharge record
            g_error := 'UPDATE discharge: ' || l_discharge;
            UPDATE discharge d
               SET d.id_disch_reas_dest = i_disch_dest,
                   d.id_prof_med        = i_prof.id,
                   d.dt_med_tstz        = l_dt_end,
                   d.notes_med          = i_notes
             WHERE d.id_discharge = l_discharge;
        
            -- retrieve id_discharge_detail
            g_error        := 'CALL id_discharge_detail';
            l_disch_detail := id_discharge_detail(i_discharge => i_discharge);
        
            IF l_disch_detail IS NOT NULL
            THEN
                g_error := 'UPDATE discharge_detail: ' || l_disch_detail;
                UPDATE discharge_detail dd
                   SET dd.total_time_spent = i_time_spent,
                       dd.id_unit_measure  = i_unit_measure,
                       dd.flg_type_closure = i_flg_type_closure
                 WHERE dd.id_discharge_detail = l_disch_detail;
            
            ELSE
                l_disch_detail_aux := seq_discharge_detail.nextval;
            
                INSERT INTO discharge_detail
                    (id_discharge_detail, id_discharge, total_time_spent, id_unit_measure, flg_type_closure)
                VALUES
                    (l_disch_detail_aux, l_discharge, i_time_spent, i_unit_measure, i_flg_type_closure);
            END IF;
        END IF;
    
        -- set history records
        g_error := 'CALL set_discharge_hist';
        pk_discharge_core.set_discharge_hist(i_prof       => i_prof,
                                             i_discharge  => l_discharge,
                                             o_disch_hist => o_disch_hist);
        IF l_disch_detail IS NOT NULL
        THEN
            g_error := 'CALL set_discharge_detail_hist';
            pk_discharge_core.set_discharge_detail_hist(i_prof           => i_prof,
                                                        i_disch_detail   => l_disch_detail,
                                                        i_disch_hist     => o_disch_hist,
                                                        o_disch_det_hist => o_disch_det_hist);
        END IF;
    
        o_discharge    := l_discharge;
        o_disch_detail := nvl(l_disch_detail, l_disch_detail_aux);
    
        IF i_transaction IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            -- ADT uses this service so this commit cant be made
            --COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_DISCHARGE',
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_discharge;

    /*
    * Cancel discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param i_cancel_reason  cancel reason identifier
    * @param i_cancel_notes   cancel notes
    * @param i_transaction    scheduler transaction identifier
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error message
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    FUNCTION set_discharge_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_cancel_reason  IN discharge.id_cancel_reason%TYPE,
        i_cancel_notes   IN discharge.notes_cancel%TYPE,
        i_transaction    IN VARCHAR2 := NULL,
        o_disch_hist     OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_disch_detail discharge_detail.id_discharge_detail%TYPE;
        --Scheduler 3.0 variables
        l_transaction_id VARCHAR2(4000);
    BEGIN
        IF i_discharge IS NULL
        THEN
            g_error := 'Received discharge identifier is NULL!';
            RAISE g_exception;
        END IF;
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL pk_schedule_api_upstream.begin_new_transaction';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction, i_prof);
    
        -- cancel discharge
        g_error := 'CALL pk_discharge.cancel_discharge';
        IF NOT pk_discharge.cancel_discharge(i_lang             => i_lang,
                                             i_id_discharge     => i_discharge,
                                             i_prof             => i_prof,
                                             i_notes_cancel     => i_cancel_notes,
                                             i_id_cancel_reason => i_cancel_reason,
                                             i_transaction_id   => l_transaction_id,
                                             o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- retrieve id_discharge_detail
        g_error        := 'CALL id_discharge_detail';
        l_disch_detail := id_discharge_detail(i_discharge => i_discharge);
        -- set history records
        g_error := 'CALL set_discharge_hist';
        pk_discharge_core.set_discharge_hist(i_prof       => i_prof,
                                             i_discharge  => i_discharge,
                                             o_disch_hist => o_disch_hist);
        g_error := 'CALL set_discharge_detail_hist';
        pk_discharge_core.set_discharge_detail_hist(i_prof           => i_prof,
                                                    i_disch_detail   => l_disch_detail,
                                                    i_disch_hist     => o_disch_hist,
                                                    o_disch_det_hist => o_disch_det_hist);
    
        IF i_transaction IS NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            COMMIT;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_DISCHARGE_CANCEL',
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_discharge_cancel;
    /*
    * Get an episode's discharges list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info 
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/05
    */
    PROCEDURE get_discharge_list_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type
    ) IS
        l_reopen_msg sys_message.desc_message%TYPE;
        l_cancel_msg sys_message.desc_message%TYPE;
    BEGIN
        l_reopen_msg := pk_message.get_message(i_lang, i_prof, 'COMMON_M037');
        l_cancel_msg := pk_message.get_message(i_lang, i_prof, 'COMMON_M028');
    
    
        g_error := 'OPEN o_discharge';
        OPEN o_discharge FOR
            SELECT d.id_discharge id,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, d.id_prof_med) desc_prof,
                   nvl(pk_paramedical_prof_core.get_format_time_spent(i_lang, dt.total_time_spent, dt.id_unit_measure),
                       pk_paramedical_prof_core.c_dashes) desc_total_time_spent,
                   pk_translation.get_translation(i_lang, dd.code_discharge_dest) desc_destiny,
                   pk_date_utils.date_char_hour_tsz(i_lang, d.dt_med_tstz, i_prof.institution, i_prof.software) desc_end_hour,
                   pk_date_utils.dt_chr_tsz(i_lang, d.dt_med_tstz, i_prof.institution, i_prof.software) desc_end_date,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, d.dt_med_tstz, i_prof) dt,
                   decode(d.flg_status,
                          pk_discharge.g_disch_flg_status_reopen,
                          l_reopen_msg,
                          pk_discharge.g_disch_flg_cancel,
                          l_cancel_msg,
                          '') desc_status,
                   pk_sysdomain.get_domain(i_code_dom => g_code_type_closure,
                                           i_val      => dt.flg_type_closure,
                                           i_lang     => i_lang) desc_type_closure,
                   pk_date_utils.date_send_tsz(i_lang, d.dt_med_tstz, i_prof) dt_send,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, d.id_prof_med, d.dt_med_tstz, NULL) prof_spec_sign
              FROM discharge d
              JOIN disch_reas_dest drd
                ON d.id_disch_reas_dest = drd.id_disch_reas_dest
              LEFT JOIN discharge_dest dd
                ON drd.id_discharge_dest = dd.id_discharge_dest
              JOIN discharge_detail dt
                ON d.id_discharge = dt.id_discharge
             WHERE d.id_episode = i_episode
               AND (d.flg_status IN (pk_alert_constant.g_active, pk_discharge.g_disch_flg_status_reopen) OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND d.flg_status = pk_alert_constant.g_cancelled))
             ORDER BY decode(d.flg_status, pk_alert_constant.g_cancelled, 2, 1), d.dt_med_tstz DESC;
    
        g_error := 'OPEN o_discharge_prof';
        OPEN o_discharge_prof FOR
            SELECT d.id_discharge id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, d.dt_disch_tstz, i_prof) dt,
                   (SELECT pk_tools.get_prof_description(i_lang, i_prof, d.id_prof_med, d.dt_disch_tstz, d.id_episode)
                      FROM dual) prof_sign,
                   d.flg_status,
                   NULL desc_status,
                   decode(d.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_alert_constant.g_no,
                          pk_discharge.g_disch_flg_status_reopen,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_cancel,
                   decode(d.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_alert_constant.g_no,
                          pk_discharge.g_disch_flg_status_reopen,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_yes) flg_action,
                   pk_date_utils.date_send_tsz(i_lang, d.dt_disch_tstz, i_prof) dt_send,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, d.id_prof_med) prof_name_sign,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, d.id_prof_med, d.dt_disch_tstz, d.id_episode) prof_spec_sign
              FROM (SELECT d.id_discharge,
                           d.id_episode,
                           d.flg_status,
                           d.id_prof_med,
                           d.dt_med_tstz,
                           nvl((SELECT MAX(dh.dt_created_hist)
                                 FROM discharge_hist dh
                                WHERE dh.id_discharge = d.id_discharge),
                               d.dt_med_tstz) dt_disch_tstz
                      FROM discharge d) d
             WHERE d.id_episode = i_episode
               AND (d.flg_status IN (pk_alert_constant.g_active, pk_discharge.g_disch_flg_status_reopen) OR
                   (i_show_cancelled = pk_alert_constant.g_yes AND d.flg_status = pk_alert_constant.g_cancelled))
             ORDER BY decode(d.flg_status, pk_alert_constant.g_cancelled, 2, 1), d.dt_med_tstz DESC;
    END get_discharge_list_report;

    /*
    * Get a discharge record history.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info 
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/05
    */
    PROCEDURE get_discharge_hist_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_show_destiny   IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type
    ) IS
        l_disch_reason       discharge_reason.id_discharge_reason%TYPE;
        l_msg_oper_add       sys_message.desc_message%TYPE;
        l_msg_oper_edit      sys_message.desc_message%TYPE;
        l_msg_oper_canc      sys_message.desc_message%TYPE;
        l_end_dt_title       sys_message.desc_message%TYPE;
        l_tot_time_title     sys_message.desc_message%TYPE;
        l_reason_title       sys_message.desc_message%TYPE;
        l_dest_title         sys_message.desc_message%TYPE;
        l_notes_title        sys_message.desc_message%TYPE;
        l_canc_rea_title     sys_message.desc_message%TYPE;
        l_canc_not_title     sys_message.desc_message%TYPE;
        l_type_closure_title sys_message.desc_message%TYPE;
    BEGIN
        g_error              := 'GET config/message';
        l_disch_reason       := pk_sysconfig.get_config(i_code_cf => g_def_disch_reas_sc, i_prof => i_prof);
        l_msg_oper_add       := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T107');
        l_msg_oper_edit      := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T108');
        l_msg_oper_canc      := pk_message.get_message(i_lang, i_prof, 'SOCIAL_T109');
        l_end_dt_title       := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T125'));
        l_tot_time_title     := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T138'));
        l_reason_title       := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T141'));
        l_dest_title         := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T140'));
        l_notes_title        := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T082'));
        l_canc_rea_title     := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'COMMON_M072'));
        l_canc_not_title     := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'COMMON_M073'));
        l_type_closure_title := get_title(i_srt => pk_message.get_message(i_lang, i_prof, 'SOCIAL_T164'));
    
        g_error := 'OPEN o_discharge';
        OPEN o_discharge FOR
            SELECT dh.id_discharge_hist id,
                   l_end_dt_title ||
                   pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) desc_end_date,
                   l_tot_time_title ||
                   nvl(pk_paramedical_prof_core.get_format_time_spent(i_lang, dth.total_time_spent, dth.id_unit_measure),
                       pk_paramedical_prof_core.c_dashes) desc_total_time_spent,
                   decode(dr.id_discharge_reason,
                          l_disch_reason,
                          NULL,
                          l_reason_title || pk_translation.get_translation(i_lang, dr.code_discharge_reason)) desc_reason,
                   decode(i_show_destiny,
                          pk_alert_constant.g_yes,
                          l_dest_title || pk_translation.get_translation(i_lang, dd.code_discharge_dest),
                          NULL) desc_destiny,
                   l_notes_title || dh.notes_med desc_notes,
                   decode(dh.flg_status,
                          pk_alert_constant.g_cancelled,
                          l_canc_rea_title || pk_translation.get_translation(i_lang, cr.code_cancel_reason)) desc_cancel_reason,
                   decode(dh.flg_status, pk_alert_constant.g_cancelled, l_canc_not_title || dh.notes_cancel) desc_cancel_notes,
                   
                   pk_message.get_message(i_lang, i_prof, 'SOCIAL_T125') label_end_date,
                   pk_date_utils.date_char_tsz(i_lang, dh.dt_med_tstz, i_prof.institution, i_prof.software) info_end_date,
                   pk_message.get_message(i_lang, i_prof, 'SOCIAL_T138') label_total_time_spent,
                   pk_paramedical_prof_core.get_format_time_spent(i_lang, dth.total_time_spent, dth.id_unit_measure) info_total_time_spent,
                   pk_message.get_message(i_lang, i_prof, 'SOCIAL_T139') label_enc_count,
                   dth.followup_count info_enc_count,
                   decode(dr.id_discharge_reason,
                          l_disch_reason,
                          NULL,
                          pk_message.get_message(i_lang, i_prof, 'SOCIAL_T141')) label_reason,
                   decode(dr.id_discharge_reason,
                          l_disch_reason,
                          NULL,
                          pk_translation.get_translation(i_lang, dr.code_discharge_reason)) info_reason,
                   decode(i_show_destiny,
                          pk_alert_constant.g_yes,
                          pk_message.get_message(i_lang, i_prof, 'SOCIAL_T140'),
                          NULL) label_destiny,
                   decode(i_show_destiny,
                          pk_alert_constant.g_yes,
                          pk_translation.get_translation(i_lang, dd.code_discharge_dest),
                          NULL) info_destiny,
                   pk_message.get_message(i_lang, i_prof, 'SOCIAL_T082') label_notes,
                   dh.notes_med info_notes,
                   decode(dh.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_message.get_message(i_lang, i_prof, 'COMMON_M072')) label_cancel_reason,
                   decode(dh.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_translation.get_translation(i_lang, cr.code_cancel_reason)) info_cancel_reason,
                   decode(dh.flg_status,
                          pk_alert_constant.g_cancelled,
                          pk_message.get_message(i_lang, i_prof, 'COMMON_M073')) label_cancel_notes,
                   decode(dh.flg_status, pk_alert_constant.g_cancelled, dh.notes_cancel) info_cancel_notes,
                   l_type_closure_title label_type_closure,
                   (SELECT pk_sysdomain.get_domain(i_code_dom => g_code_type_closure,
                                                   i_val      => dth.flg_type_closure,
                                                   i_lang     => i_lang)
                      FROM dual) info_type_closure
              FROM discharge_hist dh
              LEFT JOIN discharge_detail_hist dth
                ON dh.id_discharge_hist = dth.id_discharge_hist
              JOIN disch_reas_dest drd
                ON dh.id_disch_reas_dest = drd.id_disch_reas_dest
              LEFT JOIN discharge_dest dd
                ON drd.id_discharge_dest = dd.id_discharge_dest
              JOIN discharge_reason dr
                ON drd.id_discharge_reason = dr.id_discharge_reason
              JOIN discharge d
                ON dh.id_discharge = d.id_discharge
              LEFT JOIN cancel_reason cr
                ON d.id_cancel_reason = cr.id_cancel_reason
             WHERE dh.id_discharge = i_discharge;
    
        g_error := 'OPEN o_discharge_prof';
        OPEN o_discharge_prof FOR
            SELECT dh.id_discharge_hist id,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, dh.dt_created_hist, i_prof) dt,
                   (SELECT pk_tools.get_prof_description(i_lang,
                                                         i_prof,
                                                         dh.id_prof_created_hist,
                                                         dh.dt_created_hist,
                                                         dh.id_episode)
                      FROM dual) prof_sign,
                   dh.flg_status,
                   decode(rownum,
                          1,
                          l_msg_oper_add,
                          decode(dh.flg_status, pk_alert_constant.g_cancelled, l_msg_oper_canc, l_msg_oper_edit)) desc_status,
                   decode(dh.flg_status, pk_alert_constant.g_cancelled, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_cancel,
                   decode(dh.flg_status, pk_alert_constant.g_cancelled, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_action,
                   pk_date_utils.date_send_tsz(i_lang, dh.dt_created_hist, i_prof) dt_send,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, dh.id_prof_created_hist) prof_name_sign,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    dh.id_prof_created_hist,
                                                    dh.dt_created_hist,
                                                    dh.id_episode) prof_spec_sign
              FROM (SELECT dh.id_discharge_hist,
                           dh.id_discharge,
                           dh.id_episode,
                           dh.dt_created_hist,
                           dh.id_prof_created_hist,
                           dh.flg_status
                      FROM discharge_hist dh
                     WHERE dh.id_discharge = i_discharge
                     ORDER BY dh.dt_created_hist) dh
             ORDER BY dh.dt_created_hist DESC;
    END get_discharge_hist_report;
    /*
    * Get an episode's discharges list. Specify the discharge
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info 
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/05
    */
    FUNCTION get_discharge_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_discharge IS NULL
        THEN
            g_error := 'CALL get_discharge_list_report';
            get_discharge_list_report(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_episode        => i_episode,
                                      i_show_cancelled => i_show_cancelled,
                                      o_discharge      => o_discharge,
                                      o_discharge_prof => o_discharge_prof);
        ELSE
            g_error := 'CALL get_discharge_hist_report';
            get_discharge_hist_report(i_lang           => i_lang,
                                      i_prof           => i_prof,
                                      i_discharge      => i_discharge,
                                      o_discharge      => o_discharge,
                                      o_discharge_prof => o_discharge_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'GET_DISCHARGE_REPORT',
                                                     o_error    => o_error);
    END get_discharge_report;

    PROCEDURE get_disch_type_closure_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        o_list OUT pk_types.cursor_type
    ) IS
    BEGIN
        OPEN o_list FOR
            SELECT t.desc_val label, t.val data, t.img_name icon, t.rank
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, g_code_type_closure, NULL)) t;
    END get_disch_type_closure_list;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_discharge_amb;
/
